local stage = {}

local tinsert = table.insert

stage.warnings = {
   ["812"] = {message_format = "recommend to concat string by 'table.concat()' instead of '..'",
      fields = {}}
}

local saved_nodes = {}

local function warn_string_concat(chstate)
   for _, saved_node in ipairs(saved_nodes) do
      chstate:warn_range("812", saved_node)
   end
end

local function search_concat(node)
   if node[1] == "concat" and node.tag == "Op" then
      local new_node = true
      for _, saved_node in ipairs(saved_nodes) do
         if node.offset == saved_node.offset then
            new_node = false
         end
      end
      if new_node == true then
         tinsert(saved_nodes, node)
      end
   elseif type(node[1]) == "table" then
      for _, next_node in ipairs(node) do
         search_concat(next_node)
      end
   end
end

local function detect_string_concat(line)
   for _, item in ipairs(line.items) do
      local rhs = item.rhs
      if rhs then
         for _, node in ipairs(rhs) do
            search_concat(node)
         end
      end
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_string_concat(line)
   end
   warn_string_concat(chstate)
end

return stage
