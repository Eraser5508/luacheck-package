local core_utils = require "luacheck.core_utils"
local utils = require "luacheck.utils"

-- The main part of analysis is connecting assignments to locals or upvalues
-- with accesses that may use the assigned value.
-- Accesses and assignments are split into two groups based on whether they happen
-- in the closure that defines subject local variable (main assignment, main access)
-- or in some nested closure (closure assignment, closure access).
-- To avoid false positives, it's assumed that a closure may be called at any point
-- starting from expression that creates it.
-- Additionally, all operations on upvalues are considered in bulk, as in,
-- when a closure is called, it's assumed that any subset of its upvalue assignments
-- and accesses may happen, in any order.

-- Assignments and accesses are connected based on whether they can reach each other.
-- A main assignment is connected with a main access when the assignment can reach the access.
-- A main assignment is connected with a closure access when the assignment can reach the closure creation
-- or the closure creation can reach the assignment.
-- A closure assignment is connected with a main access when the closure creation can reach the access.
-- A closure assignment is connected with a closure access when either closure creation can reach the other one.

-- To determine what flow graph nodes an assignment or a closure creation can reach,
-- they are independently propagated along the graph.
-- Closure creation propagation is not bounded.
-- Main assignment propagation is bounded by entrance and exit conditions for each reached flow graph node.
-- Entrance condition checks that target local variable is still in scope. If entrance condition fails,
-- nothing in the node can refer to the variable, and the scope can't be reentered later.
-- So, in this case, assignment does not reach the node, and propagation does not continue.
-- Exit condition checks that target local variable is not overwritten by an assignment in the node.
-- If it fails, the assignment still reaches the node (because all accesses in a node are evaluated before any
-- assignments take effect), but propagation does not continue.

local function register_value(values_per_var, var, value)
   if not values_per_var[var] then
      values_per_var[var] = {}
   end

   table.insert(values_per_var[var], value)
end

-- Called when assignment of `value` is connected to an access.
-- `item` contains the access, and `line` contains the item.
local function add_resolution(line, item, var, value, is_mutation)
   register_value(item.used_values, var, value)
   value[is_mutation and "mutated" or "used"] = true
   value.using_lines[line] = true

   if value.secondaries then
      value.secondaries.used = true
   end
end

-- Connects accesses in given items array with an assignment of `value`.
-- `items` may be `nil` instead of empty.
local function add_resolutions(line, items, var, value, is_mutation)
   if not items then
      return
   end

   for _, item in ipairs(items) do
      add_resolution(line, item, var, value, is_mutation)
   end
end

-- Connects all accesses (and mutations) in `access_line` with corresponding
-- assignments in `set_line`.
local function cross_resolve_closures(access_line, set_line)
   for var, setting_items in pairs(set_line.set_upvalues) do
      for _, setting_item in ipairs(setting_items) do
         add_resolutions(access_line, access_line.accessed_upvalues[var],
            var, setting_item.set_variables[var])
         add_resolutions(access_line, access_line.mutated_upvalues[var],
            var, setting_item.set_variables[var], true)
      end
   end
end

local function in_scope(var, index)
   return (var.scope_start <= index) and (index <= var.scope_end)
end

-- Called when main assignment propagation reaches a line item.
local function main_assignment_propagation_callback(line, index, item, var, value)
   -- Check entrance condition.
   if not in_scope(var, index) then
      -- Assignment reaches the end of variable scope, so it can't be dominated by any assignment.
      value.overwriting_item = false
      return true
   end

   -- Assignment reaches this item, apply its effect.

   -- Accesses (and mutations) of the variable can resolve to reaching assignment.
   if item.accesses and item.accesses[var] then
      add_resolution(line, item, var, value)
   end

   if item.mutations and item.mutations[var] then
      add_resolution(line, item, var, value, true)
   end

   -- Accesses (and mutations) of the variable inside closures created in this item
   -- can resolve to reaching assignment.
   if item.lines then
      for _, created_line in ipairs(item.lines) do
         add_resolutions(created_line, created_line.accessed_upvalues[var], var, value)
         add_resolutions(created_line, created_line.mutated_upvalues[var], var, value, true)
      end
   end

   -- Check exit condition.
   if item.set_variables and item.set_variables[var] then
      if value.overwriting_item ~= false then
         if value.overwriting_item and value.overwriting_item ~= item then
            value.overwriting_item = false
         else
            value.overwriting_item = item
         end
      end

      return true
   end
end

-- Connects main assignments with main accesses and closure accesses in reachable closures.
-- Additionally, sets `overwriting_item` field of values to an item with an assignment overwriting
-- the value, but only if the overwriting is not avoidable (i.e. it's impossible to reach end of function
-- from the first assignment without going through the second one). Otherwise value of the field may be
-- `false` or `nil`.
local function propagate_main_assignments(line)
   for i, item in ipairs(line.items) do
      if item.set_variables then
         for var, value in pairs(item.set_variables) do
            if var.line == line then
               -- Assignments are not live at their own item, because assignments take effect only after all accesses
               -- are evaluated. Items with assignments can't be jumps, so they have a single following item
               -- with incremented index.
               core_utils.walk_line(line, {}, i + 1, main_assignment_propagation_callback, var, value)
            end
         end
      end
   end
end


-- Called when closure creation propagation reaches a line item.
local function closure_creation_propagation_callback(line, _, item, propagated_line)
   if not item then
      return true
   end

   -- Closure creation reaches this item, apply its effects.

   -- Accesses (and mutations) of upvalues in the propagated closure
   -- can resolve to assignments in the item.
   if item.set_variables then
      for var, value in pairs(item.set_variables) do
         add_resolutions(propagated_line, propagated_line.accessed_upvalues[var], var, value)
         add_resolutions(propagated_line, propagated_line.mutated_upvalues[var], var, value, true)
      end
   end

   if item.lines then
      for _, created_line in ipairs(item.lines) do
         -- Accesses (and mutations) of upvalues in the propagated closure
         -- can resolve to assignments in closures created in the item.
         cross_resolve_closures(propagated_line, created_line)

         -- Accesses (and mutations) of upvalues in closures created in the item
         -- can resolve to assignments in the propagated closure.
         cross_resolve_closures(created_line, propagated_line)
      end
   end

   -- Accesses (and mutations) of locals in the item can resolve
   -- to assignments in the propagated closure.
   for var, setting_items in pairs(propagated_line.set_upvalues) do
      if item.accesses and item.accesses[var] then
         for _, setting_item in ipairs(setting_items) do
            add_resolution(line, item, var, setting_item.set_variables[var])
         end
      end

      if item.mutations and item.mutations[var] then
         for _, setting_item in ipairs(setting_items) do
            add_resolution(line, item, var, setting_item.set_variables[var], true)
         end
      end
   end
end

-- Connects main assignments with closure accesses in reaching closures.
-- Connects closure assignments with main accesses and with closure accesses in reachable closures.
-- Connects closure accesses with closure assignments in reachable closures.
local function propagate_closure_creations(line)
   for i, item in ipairs(line.items) do
      if item.lines then
         for _, created_line in ipairs(item.lines) do
            -- Closures are live at the item they are created, as they can be called immediately.
            core_utils.walk_line(line, {}, i, closure_creation_propagation_callback, created_line)
         end
      end
   end
end

local function analyze_line(line)
   propagate_main_assignments(line)
   propagate_closure_creations(line)
end

local externally_accessible_tags = utils.array_to_set({"Id", "Index", "Call", "Invoke", "Op", "Paren", "Dots"})

local function externally_accessible(value)
   return value.type ~= "var" or (value.node and externally_accessible_tags[value.node.tag])
end

local function find_overwriting_lhs_node(item, value)
   for _, node in ipairs(item.lhs) do
      if node.var == value.var then
         return node
      end
   end
end

local function get_overwriting_node_in_dup_assignment(item, value)
   local after_value_node

   for _, node in ipairs(item.lhs) do
      if node.var == value.var then
         if after_value_node then
            return node
         elseif node.location == value.location then
            after_value_node = true
         end
      end
   end
end

-- Emits warnings for variable.
local function check_var(chstate, var)
   if core_utils.is_function_var(var) then
      local value = var.values[2] or var.values[1]

      if not value.used then
         chstate:warn_unused_variable(value)
      end
   elseif #var.values == 1 then
      if not var.values[1].used then
         if var.values[1].mutated then
            if not externally_accessible(var.values[1]) then
               chstate:warn_unaccessed(var, true)
            end
         else
            chstate:warn_unused_variable(var.values[1], nil, nil, var.values[1].empty)
         end
      elseif var.values[1].empty then
         var.empty = true
         chstate:warn_unset(var)
      end
   elseif not var.accessed and not var.mutated then
      chstate:warn_unaccessed(var)
   else
      local no_values_externally_accessible = true

      for _, value in ipairs(var.values) do
         if externally_accessible(value) then
            no_values_externally_accessible = false
         end
      end

      if not var.accessed and no_values_externally_accessible then
         chstate:warn_unaccessed(var, true)
      end

      for _, value in ipairs(var.values) do
         if not value.empty then
            if not value.used and not value.mutated then
               local overwriting_node

               if value.overwriting_item then
                  overwriting_node = find_overwriting_lhs_node(value.overwriting_item, value)

                  if overwriting_node == value.node then
                     overwriting_node = nil
                  end
               else
                  overwriting_node = get_overwriting_node_in_dup_assignment(value.item, value)
               end

               chstate:warn_unused_value(value, false, overwriting_node)
            elseif not value.used and not externally_accessible(value) then
               if var.accessed or not no_values_externally_accessible then
                  chstate:warn_unused_value(value, true)
               end
            end
         end
      end
   end
end

-- Emits warnings for unused variables and values and unset variables in line.
local function check_for_warnings(chstate, line)
   for _, item in ipairs(line.items) do
      if item.tag == "Local" then
         for var in pairs(item.set_variables) do
            -- Do not check implicit top level vararg.
            if var.location then

               check_var(chstate, var)
            end
         end
      end
   end
end

-- Finds reaching assignments for all variable accesses.
-- Emits warnings: unused variable, unused value, unset variable.
local function analyze(chstate, line)
   analyze_line(line)

   for _, nested_line in ipairs(line.lines) do
      analyze_line(nested_line)
   end

   check_for_warnings(chstate, line)

   for _, nested_line in ipairs(line.lines) do
      check_for_warnings(chstate, nested_line)
   end
end

return analyze
