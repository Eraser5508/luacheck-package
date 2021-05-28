local stage = {}

local parser = require "luacheck.parser"

local pairs = pairs
local ipairs = ipairs
local type = type

local tinsert = table.insert

stage.warnings = {
   ["915"] = {message_format = "you need to add space on both sides of operator '{operator}'",
      fields = {"operator"}},
}

local binary_operators = parser.get_binary_operators()

local function get_operator_symbol(operator_name)
   for symbol, name in pairs(binary_operators) do
      if name == operator_name then
         return symbol
      end
   end
end

local saved_nodes = {}

local function is_new_node(node)
   if saved_nodes[node.offset] then
      return false
   end
   return true
end

local function warn_operator_add_space(chstate, node, symbol)
      chstate:warn_range("915", node, {
         operator = symbol
      })
end

local function save_operator(chstate, node, symbol)
   if symbol and symbol ~= "pow" then
      local lhs = node[2]
      local rhs = node[3]
      if lhs and rhs and lhs.line == rhs.line then
         local distance = rhs.offset - lhs.end_offset - 1
         local expected_distance = #symbol + 2
         if distance < expected_distance then
            if is_new_node(node) == true then
               tinsert(saved_nodes, node.offset, node)
               warn_operator_add_space(chstate, node, symbol)
            end
         end
      end
   end
end

local function search_operator(chstate, nodes)
   for _, node in ipairs(nodes) do
      if node and type(node) == "table" then
         if node.tag == "Op" then
            local operator_name = node[1]
            save_operator(chstate, node, get_operator_symbol(operator_name))
         end
         search_operator(chstate, node)
      end
   end
end

local function detect_operator(chstate, line)
   for _, item in ipairs(line.items) do
      if item.node and type(item.node) == "table" then
         search_operator(chstate, item.node)
      end
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_operator(chstate, line)
   end
end

return stage
