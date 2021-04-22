local stage = {}

local ipairs = ipairs

local sfind = string.find
local sbyte = string.byte
local ssub = string.sub
local slen = string.len

stage.warnings = {
   ["811"] = {message_format = "nonstandard function name '{function_name}'",
      fields = {"function_name"}},
   ["911"] = {message_format = "'arg' is not allowed as a parameter name",
      fields = {}},
}

local function_name_whitelist = {
   "ctor",
   "new"
}

local function is_closure_function(node_parent)
   if node_parent then
      if node_parent[1] == "self" and node_parent.tag == "Id" then
         return false
      end
   end
   return true
end

local function is_in_whitelist(function_name)
   for _, name in ipairs(function_name_whitelist) do
      if function_name == name then
         return true
      end
   end
   return false
end

local function warn_function_name(chstate, node)
   local temp_table = node[1]
   if temp_table then
      if is_closure_function(temp_table[1]) == false then
         local full_name = node.name
         if full_name then
            local _, index = sfind(full_name, "%.", 1)
            if not index then
               index = 0
            end
            local name = ssub(full_name, index + 1)
            if is_in_whitelist(name) == false then
               local num_byte = sbyte(name, 1)
               local num_len = slen(name)
               if num_byte < 65 or num_byte > 91 or num_len <= 1 then
                  chstate:warn_range("811", node, {
                     function_name = node.name
                  })
               end
            end
         end
      end
   end
end

local function warn_function_para(chstate, node)
   local para = node[1]
   if para then
      for _, node_para in ipairs(para) do
         if node_para[1] == "arg" then
            chstate:warn_range("911", node_para)
         end
      end
   end
end

local function detect_function_definition(chstate,line)
   local node = line.node
   if node.tag == "Function" then
      warn_function_name(chstate, node)
      warn_function_para(chstate, node)
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_function_definition(chstate, line)
   end
end

return stage
