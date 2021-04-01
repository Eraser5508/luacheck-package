local stage = {}

local tconcat = table.concat
local tinsert = table.insert
local tgetn = table.getn

local slen = string.len
local sfind = string.find
local ssub = string.sub
local smatch = string.match

stage.warnings = {
   ["813"] = {message_format = "'{variable_name}' is a constant variable, try to use its value directly?",
      fields = {"variable_name"}},
   ["814"] = {message_format = "multiple same 'GetTable' operation '{variable_name}'",
      fields = {"variable_name"}},
   ["815"] = {message_format = "C++ objects creation '{variable_name}' in 'Tick' function",
      fields = {"variable_name"}}
}

local variables_set = {}
local variables_get = {}

local function warn_set_table(chstate)
   for _, value_set in ipairs(variables_set) do
      if value_set.is_const == true and value_set.function_name == "unknown" then
         local is_get = false
         for _, value_function in ipairs (variables_get) do
            for _, value_variable in ipairs(value_function.variables_info) do
               if value_variable.name == value_set.name then
                  for _, value_node in ipairs(value_variable.nodes) do
                     if value_node.offset ~= value_set.node.offset then
                        is_get = true
                        chstate:warn_range("813", value_node, {
                           variable_name = value_variable.name
                        })
                     end
                  end
                  break
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

local function warn_same_get_table_operation(chstate, function_info)
   for _, value_variable in ipairs(function_info.variables_info) do
      if tgetn(value_variable.nodes) > 1 and value_variable.depth > 1 then
         local is_set = false
         for _, value_set in ipairs(variables_set) do
            if value_set.name == value_variable.name and value_set.function_name == function_info.function_name then
               is_set = true
               break
            end
         end
         if is_set == false then
            for _, node in ipairs(value_variable.nodes) do
               chstate:warn_range("814", node, {
                  variable_name = value_variable.name
               })
            end
         end
      end
   end
end

local function warn_object_creation_in_tick(chstate, function_info)
   local temp_name = function_info.function_name
   local _, index = sfind(temp_name, "%.", 1)
   if index then
      index = index + 1
      temp_name = ssub(temp_name, index)
      if temp_name == "Tick" then
         for _, value_variable in ipairs(function_info.variables_info) do
            if value_variable.name == "UE4.FVector2D" then
               for _, node in ipairs(value_variable.nodes) do
                  chstate:warn_range("815", node, {
                     variable_name = value_variable.name
                  })
               end
            end
         end
      end
   end
end

local function warn_get_table(chstate)
   for _, value_function in ipairs(variables_get) do
      warn_same_get_table_operation(chstate, value_function)
      warn_object_creation_in_tick(chstate, value_function)
   end
end

local function save_variable_set(function_name, name, node, is_number, depth)
   local is_new = true
   local is_const = is_number
   for _, value in ipairs(variables_set) do
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
      local new_variable = {}
      new_variable.function_name = function_name
      new_variable.name = name
      new_variable.is_const = is_const
      new_variable.node = node
      new_variable.depth = depth
      tinsert(variables_set, new_variable)
   end
end

local function save_variable_get(function_name, name, node, depth)
   local is_new_function = true
   local is_new_name = true
   local is_new_node = true

   local new_variable = {}
   new_variable.name = name
   new_variable.depth = depth
   new_variable.nodes = {node}

   for _, value_function in ipairs(variables_get) do
      if value_function.function_name == function_name then
         for _, value_variable in ipairs(value_function.variables_info) do
            if value_variable.name == name then
               for _, value_node in ipairs(value_variable.nodes) do
                  if value_node.offset == node.offset then
                     is_new_node = false
                     break
                  end
               end
               if is_new_node then
                  tinsert(value_variable.nodes, node)
               end
               is_new_name = false
               break
            end
         end
         if is_new_name then
            tinsert(value_function.variables_info, new_variable)
         end
         is_new_function = false
         break
      end
   end
   if is_new_function == true then
      local new_function = {
         function_name = function_name,
         variables_info = {new_variable}
      }
      tinsert(variables_get, new_function)
   end
end

local function combline_variable_name(node, depth)
   local node_1 = node[1]
   local node_2 = node[2]
   if node_1 and node_2 then
      if node_2[1] and type(node_2[1]) == "string" then
         if node_1[1] and type(node_1[1]) == "string" then
            if slen(node_1[1]) > 1 and slen(node_2[1]) > 1 then
               return tconcat({node_1[1], ".", node_2[1]}), depth + 1
            end
         end
         local name, new_depth = combline_variable_name(node_1, depth)
         if name then
            if slen(node_2[1]) > 1 then
               return tconcat({name, ".", node_2[1]}), new_depth + 1
            end
         end
      end
   end
   return nil, 0
end

local function search_variable_set(node, is_number, function_name)
   local name, depth = combline_variable_name(node, 0)
   if name then
      save_variable_set(function_name, name, node, is_number, depth)
   end
end

local function search_variable_get(node, function_name)
   local tag = node.tag
   if tag == "Index" then
      local name, depth = combline_variable_name(node, 0)
      if name then
         save_variable_get(function_name, name, node, depth)
      end
   elseif tag == "Set" then
      local lhs = node[1]
      local rhs = node[2]
      search_variable_set(lhs[1], rhs[1].tag == "Number", function_name)
   elseif type(node) == "table" then
      for _, next_node in ipairs(node) do
         search_variable_get(next_node, function_name)
      end
   end
end

local function detect_get_set_table(line)
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
               search_variable_get(rhs[1], function_name)
            end
         end
      elseif item.tag == "Set" then
         if rhs and rhs[1] and lhs and lhs[1] then
            search_variable_set(lhs[1], rhs[1].tag == "Number", function_name)
         end
      end
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_get_set_table(line)
   end
   warn_set_table(chstate)
   warn_get_table(chstate)
end

return stage
