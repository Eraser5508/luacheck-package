local utils = require "luacheck.utils"

local stage = {}

local pairs = pairs
local ipairs = ipairs
local type = type

local tconcat = table.concat
local tinsert = table.insert

local slen = string.len
local sfind = string.find
local ssub = string.sub

stage.warnings = {
   ["813"] = {message_format = "'{variable_name}' is a constant variable, try to use its value directly?",
      fields = {"variable_name"}},
   ["814"] = {message_format = "multiple same 'GetTable' instruction '{variable_name}'",
      fields = {"variable_name"}},
   ["815"] = {message_format = "C++ objects creation '{variable_name}' in 'Tick' function",
      fields = {"variable_name"}}
}

local TableDetector = utils.class()

function TableDetector:get_table_length(table)
   local length = 0
   for _, _ in pairs(table) do
      length = length + 1
   end
   return length
end

function TableDetector:get_function_name(function_name)
   if function_name then
      local temp_name = function_name
      local _, index = sfind(temp_name, "%.", 1)
      if index then
         index = index + 1
         temp_name = ssub(temp_name, index)
         return temp_name
      end
   end
   return nil
end

function TableDetector:find_function_in_get(function_name)
   for _, value in ipairs(self.variables_get) do
      if value.function_name == function_name then
         return value
      end
   end
   return nil
end

function TableDetector:find_variable_in_get(variables_info, varibale_name)
   for _, value in ipairs(variables_info) do
      if value.name == varibale_name then
         return value
      end
   end
   return nil
end

function TableDetector:find_variable_in_set(function_name, variable_name)
   for _, value in ipairs(self.variables_set) do
      if value.name == variable_name and value.function_name == function_name then
         return value
      end
   end
   return nil
end

function TableDetector:find_function_in_tick(function_name)
   for _, value in ipairs(self.functions_in_tick) do
      if value == self:get_function_name(function_name) then
         return value
      end
   end
   return nil
end

function TableDetector:warn_set_table(chstate)
   for _, value_set in ipairs(self.variables_set) do
      if value_set.is_const == true and value_set.function_name == "unknown" then
         local is_get = false
         for _, value_function in ipairs (self.variables_get) do
            local variable_info = self:find_variable_in_get(value_function.variables_info, value_set.name)
            if variable_info then
               for _, value_node in ipairs(variable_info.nodes) do
                  if value_node.offset ~= value_set.node.offset then
                     is_get = true
                     chstate:warn_range("813", value_node, {
                        variable_name = variable_info.name
                     })
                  end
               end
            end
         end
         if is_get == true then
            chstate:warn_range("813", value_set.node, {
               variable_name = value_set.name
            })
         end
      end
   end
end

function TableDetector:warn_same_get_table_instruction(chstate, function_info)
   for _, value_variable in ipairs(function_info.variables_info) do
      if self:get_table_length(value_variable.nodes) > 1 and value_variable.depth > 1 then
         if not self:find_variable_in_set(function_info.function_name, value_variable.name) then
            for _, node in ipairs(value_variable.nodes) do
               chstate:warn_range("814", node, {
                  variable_name = value_variable.name
               })
            end
         end
      end
   end
end

function TableDetector:warn_object_creation_in_tick(chstate, function_info)
   if self:find_function_in_tick(function_info.function_name) then
      for _, value in ipairs(function_info.variables_info) do
         if ssub(value.name, 1, 5) == "UE4.F" then
            for _, node in ipairs(value.nodes) do
               chstate:warn_range("815", node, {
                  variable_name = value.name
               })
            end
         end
      end
   end
end

function TableDetector:warn_get_table(chstate)
   for _, value_function in ipairs(self.variables_get) do
      self:warn_same_get_table_instruction(chstate, value_function)
      -- self:warn_object_creation_in_tick(chstate, value_function)
   end
end

function TableDetector:save_variable_set(function_name, name, node, is_number, depth)
   local is_new = true
   local is_const = is_number
   for _, value in ipairs(self.variables_set) do
      if value.name == name then
         is_const = false
         value.is_const = false
         if value.function_name == function_name then
            is_new = false
            break
         end
      end
   end
   if is_new == true then
      local new_variable = {
         function_name = function_name,
         name = name,
         is_const = is_const,
         node = node,
         depth = depth
      }
      tinsert(self.variables_set, new_variable)
   end
end

function TableDetector:save_variable_get(function_name, name, node, depth)
   local new_variable = {
      name = name,
      depth = depth,
      nodes = {node}
   }

   local function_info = self:find_function_in_get(function_name)
   if function_info then
      local variable_info = self:find_variable_in_get(function_info.variables_info, name)
      if variable_info then
         local is_new_node = true
         for _, value in ipairs(variable_info.nodes) do
            if value.offset == node.offset then
               is_new_node = false
               break
            end
         end
         if is_new_node == true then
            tinsert(variable_info.nodes, node)
         end
      else
         tinsert(function_info.variables_info, new_variable)
      end
   else
      local new_function = {
         function_name = function_name,
         variables_info = {new_variable}
      }
      tinsert(self.variables_get, new_function)
   end
end

function TableDetector:save_function_in_tick(function_name)
   local is_new_function = true
   for _, value in ipairs(self.functions_in_tick) do
      if value == function_name then
         is_new_function = false
         break
      end
   end
   if is_new_function == true then
      tinsert(self.functions_in_tick, function_name)
   end
end

function TableDetector:combline_variable_name(node, depth)
   local node_1 = node[1]
   local node_2 = node[2]
   if node_1 and node_2 then
      if node_2[1] and type(node_2[1]) == "string" then
         if node_1[1] and type(node_1[1]) == "string" then
            if slen(node_1[1]) > 1 and slen(node_2[1]) > 1 then
               return tconcat({node_1[1], ".", node_2[1]}), depth + 1
            end
         end
         local name, new_depth = self:combline_variable_name(node_1, depth)
         if name then
            if slen(node_2[1]) > 1 then
               return tconcat({name, ".", node_2[1]}), new_depth + 1
            end
         end
      end
   end
   return nil, 0
end

function TableDetector:search_variable_set(node, is_number, function_name)
   local name, depth = self:combline_variable_name(node, 0)
   if name then
      self:save_variable_set(function_name, name, node, is_number, depth)
   end
end

function TableDetector:search_variable_get(node, function_name)
   local tag = node.tag
   local lhs = node[1]
   local rhs = node[2]
   if tag == "Invoke" then
      if self:get_function_name(function_name) == "Tick" and lhs[1] == "self" and lhs.tag == "Id" then
         self:save_function_in_tick(rhs[1])
      end
   end
   if tag == "Index" then
      local name, depth = self:combline_variable_name(node, 0)
      if name then
         self:save_variable_get(function_name, name, node, depth)
      end
   elseif tag == "Set" then
      self:search_variable_set(lhs[1], rhs[1].tag == "Number", function_name)
      self:search_variable_get(rhs[1], function_name)
   elseif type(node) == "table" then
      for _, next_node in ipairs(node) do
         self:search_variable_get(next_node, function_name)
      end
   end
end

function TableDetector:detect_get_set_table(line)
   for _, item in ipairs(line.items) do
      local function_name = "unknown"
      local rhs = item.rhs
      local lhs = item.lhs
      local lines = item.lines
      if lines and lines[1] then
         local node = lines[1].node
         if node.tag == "Function" then
            function_name = node.name
            if rhs and rhs[1] then
               self:search_variable_get(rhs[1], function_name)
            end
         end
      elseif item.tag == "Set" then
         if rhs and rhs[1] and lhs and lhs[1] then
            self:search_variable_set(lhs[1], rhs[1].tag == "Number", function_name)
         end
      end
   end
end

function stage.run(chstate)
   local detector = TableDetector()
   detector.variables_set = {}
   detector.variables_get = {}
   detector.functions_in_tick = {"Tick"}

   for _, line in ipairs(chstate.lines) do
      detector:detect_get_set_table(line)
   end
   detector:warn_set_table(chstate)
   detector:warn_get_table(chstate)
end

return stage
