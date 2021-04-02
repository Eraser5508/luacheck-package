local stage = {}

local sfind = string.find
local sbyte = string.byte
local sub = string.sub

stage.warnings = {
   ["811"] = {message_format = "name of function '{function_name}' should start with an uppercase letter",
      fields = {"function_name"}}
}

local function warn_function_name(chstate, node)
   chstate:warn_range("811", node, {
      function_name = node.name
   })
end

local function detect_function_name(chstate,line)
   local node = line.node
   if node.tag == "Function" then
      if node.name then
         local _, index = sfind(node.name, "%.", 1)
         if index == nil then
            index = 0
         end
         local num = sbyte(node.name, index + 1)
         if num < 65 or num > 91 then
            warn_function_name(chstate, node)
         end
      end
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_function_name(chstate, line)
   end
end

return stage
