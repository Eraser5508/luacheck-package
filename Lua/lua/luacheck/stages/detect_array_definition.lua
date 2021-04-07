local stage = {}

local ipairs = ipairs

stage.warnings = {
   ["913"] = {message_format = "specify the array subscript from '0' explicitly is forbidden",
      fields = {}}
}

local function warn_array_definition(chstate, node)
   chstate:warn_range("913", node)
end

local function search_array_construct(chstate, node)
   if node.tag == "Table" then
      for _, value in ipairs(node) do
         if value.tag == "Pair" then
            local array_key = value[1]
            local array_value = value[2]
            if array_key and array_key.tag == "Number" and array_key[1] == "0" then
               warn_array_definition(chstate, value)
            end
            if array_value and array_value.tag == "Table" then
               search_array_construct(chstate, array_value)
            end
         end
      end
   end
end

local function search_array_set(chstate, node)
   if node.tag == "Index" then
      for _, value in ipairs(node) do
         if value.tag == "Number" and value[1] == "0" then
            warn_array_definition(chstate, value)
         end
      end
   end
end

local function detect_array_definition(chstate, line)
   for _, item in ipairs(line.items) do
      local rhs = item.rhs
      local lhs = item.lhs
      if rhs and rhs[1] then
         search_array_construct(chstate, rhs[1])
      end
      if lhs and lhs[1] then
         search_array_set(chstate, lhs[1])
      end
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_array_definition(chstate, line)
   end
end

return stage
