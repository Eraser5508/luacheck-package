local stage = {}

local ipairs = ipairs
local type = type

stage.warnings = {
   ["812"] = {message_format = "recommend to concat string by 'table.concat()' instead of '..'",
      fields = {}}
}

local saved_nodes = {}

local function warn_string_concat(chstate, node)
   chstate:warn_range("812", node)
end

local function search_concat(chstate, node)
   if node[1] == "concat" and node.tag == "Op" then
      if saved_nodes[node.offset] == nil then
         saved_nodes[node.offset] = node
         warn_string_concat(chstate, node)
      end
   elseif type(node[1]) == "table" then
      for _, next_node in ipairs(node) do
         search_concat(chstate, next_node)
      end
   end
end

local function detect_string_concat(chstate, line)
   for _, item in ipairs(line.items) do
      local rhs = item.rhs
      if rhs then
         for _, node in ipairs(rhs) do
            search_concat(chstate, node)
         end
      end
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_string_concat(chstate, line)
   end
end

return stage
