local XPathConverter = {}

local methods = {}

local function string_value(raw_value)
  local escaped_value, n_escaped =
    raw_value:gsub("(['\\])",
                   function(special_character)
                     return "\\" .. special_character
                   end)
  return "'" .. raw_value .. "'"
end

local function decompose_dimension(dimension)
  local start, last = dimension:find("^%d+")
  return {tonumber(dimension:sub(start, last)), dimension:sub(last + 1)}
end

local metatable = {}
function metatable.__index(parser, key)
  return methods[key]
end

function methods.on_start_selector(self)
  table.insert(self.xpaths, "")
  self.combinator = " "
end

function methods.on_combinator(self, combinator)
  self.combinator = combinator
end

function methods.on_type_selector(self, namespace_prefix, element_name)
  local xpath = self.xpaths[#self.xpaths]

  local prefix
  if self.combinator == "+" then
    prefix = "/following-sibling::*[position()=1]"
  elseif self.combinator == ">" then
    prefix = "/"
  elseif self.combinator == "~" then
    prefix = "/following-sibling::"
  elseif self.combinator == " " then
    prefix = "/descendant-or-self::"
  end

  if namespace_prefix == nil or namespace_prefix == "*" then
    if prefix:sub(#prefix) ~= "]" then
      prefix = prefix .. "*"
    end
    self.node_predicate = "[local-name()=" .. string_value(element_name) .. "]"
    xpath = xpath .. prefix .. self.node_predicate
  elseif namespace_prefix == "" then
    self.node_predicate = "[name()=" .. string_value(element_name) .. "]"
    if prefix:sub(#prefix) == "]" then
      xpath = xpath .. prefix .. self.node_predicate
    else
      xpath = xpath .. prefix .. element_name
    end
  else
    local name = namespace_prefix .. ":" .. element_name
    self.node_predicate = "[name()=" .. string_value(element_name) .. "]"
    if prefix:sub(#prefix) == "]" then
      xpath = xpath .. prefix .. self.node_predicate
    else
      xpath = xpath .. prefix .. name
    end
  end

  self.xpaths[#self.xpaths] = xpath
end

function methods.on_universal(self, namespace_prefix, element_name)
  local xpath = self.xpaths[#self.xpaths]

  local prefix
  if self.combinator == "+" then
    prefix = "/following-sibling::*[position()=1]"
  elseif self.combinator == ">" then
    prefix = "/*"
  elseif self.combinator == "~" then
    prefix = "/following-sibling::*"
  elseif self.combinator == " " then
    prefix = "/descendant-or-self::*"
  end

  if namespace_prefix == nil or namespace_prefix == "*" then
    self.node_predicate = ""
    xpath = xpath .. prefix
  elseif namespace_prefix == "" then
    self.node_predicate = "[namespace-uri()='']"
    xpath = xpath .. prefix .. self.node_predicate
  else
    self.node_predicate =
      "[starts-with(name(), " .. string_value(namespace_prefix) .. ")]"
    xpath = xpath .. prefix .. self.node_predicate
  end

  self.xpaths[#self.xpaths] = xpath
end

function methods.on_hash(self, name)
  local xpath = self.xpaths[#self.xpaths]
  xpath = xpath ..
    "[@id=" .. string_value(name) .. " or " ..
    "@name=" .. string_value(name) .. "]"
  self.xpaths[#self.xpaths] = xpath
end

local function attribute_include(xpath, name, value)
  return xpath ..
    "[contains(" ..
    "concat(' ', normalize-space(@" .. name .. "), ' '), " ..
    string_value(" " .. value .. " ") .. ")]"
end

function methods.on_class(self, name)
  local xpath = self.xpaths[#self.xpaths]
  xpath = attribute_include(xpath .. "[@class]", "class", name)
  self.xpaths[#self.xpaths] = xpath
end

function methods.on_attribute(self,
                              namespace_prefix,
                              attribute_name,
                              operator,
                              value)
  local xpath = self.xpaths[#self.xpaths]

  local name
  if namespace_prefix then
    name = namespace_prefix .. ":" .. attribute_name
  else
    name = attribute_name
  end

  xpath = xpath .. "[@" .. name .. "]"
  if operator == "^=" then
    xpath = xpath ..
      "[starts-with(@" .. name .. ", " ..
      string_value(value) .. ")]"
  elseif operator == "$=" then
    xpath = xpath ..
      "[substring(@" .. name .. ", " ..
      "string-length(@" .. name .. ") - " .. #value .. ")" ..
      "=" .. string_value(value) .. "]"
  elseif operator == "*=" then
    xpath = xpath .. "[contains(@" .. name .. ", " .. string_value(value) .. ")]"
  elseif operator == "=" then
    xpath = xpath .. "[@" .. name .. "=" .. string_value(value) .. "]"
  elseif operator == "~=" then
    xpath = attribute_include(xpath, name, value)
  elseif operator == "|=" then
    xpath = xpath ..
      "[@" .. name .. "=" .. string_value(value) .. " or " ..
      "starts-with(@" .. name .. ", " .. string_value(value .. "-") .. ")]"
  end

  self.xpaths[#self.xpaths] = xpath
end

function methods.on_pseudo_element(self, name)
  error("Failed to convert to XPath: " ..
          "pseudo-element isn't supported: <" .. name .. ">")
end

function methods.on_pseudo_class_root(self, name)
  local xpath = self.xpaths[#self.xpaths]
  xpath = xpath .. "[not(parent::*)]"
  self.xpaths[#self.xpaths] = xpath
end

function methods.on_pseudo_class_first_child(self, name)
  local xpath = self.xpaths[#self.xpaths]
  xpath = xpath .. "[count(preceding-sibling::*) = 0]"
  self.xpaths[#self.xpaths] = xpath
end

function methods.on_pseudo_class_last_child(self, name)
  local xpath = self.xpaths[#self.xpaths]
  xpath = xpath .. "[count(following-sibling::*) = 0]"
  self.xpaths[#self.xpaths] = xpath
end

function methods.on_pseudo_class(self, name)
  local callback = methods["on_pseudo_class_" .. name:gsub("-", "_")]
  if callback then
    callback(self, name)
  else
    error("Failed to convert to XPath: " ..
            "unsupported pseudo-class: <" .. name .. ">")
  end
end

function methods.on_functional_pseudo_lang(self, name, expression)
  local xpath = self.xpaths[#self.xpaths]

  if #expression ~= 1 then
    error("Failed to convert to XPath: " .. name .. ": " ..
            "wrong number of arguments: " ..
            "(given " .. #expression .. ", expected 1)")
  end
  if expression[1][1] ~= "name" then
    error("Failed to convert to XPath: " .. name .. ": " ..
            "1st argument must be name: " ..
            "<" .. expression[1][2] .. ">(" .. expression[1][1] .. ")")
  end
  xpath = xpath .. "[lang(" .. string_value(expression[1][2]) .. ")]"

  self.xpaths[#self.xpaths] = xpath
end

local function normalize_expression(expression)
  local normalized_expression = ""
  for _, component in ipairs(expression) do
    if #component == 1 then
      if component[1] == "plus" then
        normalized_expression = normalized_expression .. "+"
      elseif component[1] == "minus" then
        normalized_expression = normalized_expression .. "-"
      else
        normalized_expression = normalized_expression .. component[1]
      end
    else
      normalized_expression = normalized_expression .. component[2]
    end
  end
  return normalized_expression
end

-- aN + b
local function parse_nth_expression(name, expression)
  local normalized_expression = normalize_expression(expression)

  if normalized_expression == "odd" then
    return 2, 1
  end

  if normalized_expression == "even" then
    return 2, 0
  end

  local start, last, a_sign, a, b_sign, b

  start, last, a_sign, a_raw, b_sign, b_raw =
    normalized_expression:find("^([+-])(%d+)n([+-])(%d+)$")
  if start then
    a = tonumber(a_raw)
    if a_sign == "-" then
      a = -a
    end
    b = tonumber(b_raw)
    if b_sign == "-" then
      b = -b
    end
    return a, b
  end

  start, last, a_sign, a_raw =
    normalized_expression:find("^([+-])(%d+)n$")
  if start then
    a = tonumber(a_raw)
    if a_sign == "-" then
      a = -a
    end
    return a, 0
  end

  start, last, a_raw =
    normalized_expression:find("^(%d+)n$")
  if start then
    return tonumber(a_raw), 0
  end

  start, last, a_sign =
    normalized_expression:find("^([+-])n$")
  if start then
    if a_sign == "-" then
      a = -1
    else
      a = 1
    end
    return a, 0
  end

  start, last, a_raw, b_sign, b_raw =
    normalized_expression:find("^(%d+)n([+-])(%d+)$")
  if start then
    a = tonumber(a_raw)
    b = tonumber(b_raw)
    if b_sign == "-" then
      b = -b
    end
    return a, b
  end

  start, last, a_sign, b_sign, b_raw =
    normalized_expression:find("^([+-])n([+-])(%d+)$")
  if start then
    if a_sign == "-" then
      a = -1
    else
      a = 1
    end
    b = tonumber(b_raw)
    if b_sign == "-" then
      b = -b
    end
    return a, b
  end

  start, last, b_sign, b_raw =
    normalized_expression:find("^n([+-])(%d+)$")
  if start then
    b = tonumber(b_raw)
    if b_sign == "-" then
      b = -b
    end
    return 1, b
  end

  start, last, b_sign, b_raw =
    normalized_expression:find("^([+-])(%d+)$")
  if start then
    b = tonumber(b_raw)
    if b_sign == "-" then
      b = -b
    end
    return 0, b
  end

  start, last, b_raw =
    normalized_expression:find("^(%d+)$")
  if start then
    return 0, tonumber(b_raw)
  end

  error("Failed to convert to XPath: " .. name .. ": " ..
          "invalid N: <" .. normalized_expression .. ">")
end

local function build_nth_xpath(xpath, a, b, axis, node_predicate)
  local n_siblings = "count(" .. axis .. "::*" .. node_predicate .. ")"
  if a == 0 then
    xpath = xpath .. "[" .. n_siblings .. " = " .. (b - 1) .. "]"
  elseif a < 0 then
    if b > 1 then
      xpath = xpath .. "[" .. n_siblings .. " <= " .. (b - 1) .. "]"
      if a < -1 then
        local mod = (b - 1) % a
        xpath = xpath .. "[" .. n_siblings .. " mod " .. a .. " = " .. mod .. "]"
      end
    else
      -- never match
      xpath = xpath .. "[0]"
    end
  else
    if b > 1 then
      xpath = xpath .. "[" .. n_siblings .. " >= " .. (b - 1) .. "]"
    end
    if a > 1 then
      local mod = (b - 1) % a
      xpath = xpath .. "[" .. n_siblings .. " mod " .. a .. " = " .. mod .. "]"
    end
  end

  return xpath
end

function methods.on_functional_pseudo_nth_child(self, name, expression)
  local xpath = self.xpaths[#self.xpaths]

  local a, b = parse_nth_expression(name, expression)
  xpath = build_nth_xpath(xpath, a, b, "preceding-sibling", "")

  self.xpaths[#self.xpaths] = xpath
end

function methods.on_functional_pseudo_nth_last_child(self, name, expression)
  local xpath = self.xpaths[#self.xpaths]

  local a, b = parse_nth_expression(name, expression)
  xpath = build_nth_xpath(xpath, a, b, "following-sibling", "")

  self.xpaths[#self.xpaths] = xpath
end

function methods.on_functional_pseudo_nth_of_type(self, name, expression)
  local xpath = self.xpaths[#self.xpaths]

  local a, b = parse_nth_expression(name, expression)
  xpath = build_nth_xpath(xpath, a, b, "preceding-sibling", self.node_predicate)

  self.xpaths[#self.xpaths] = xpath
end

function methods.on_functional_pseudo_nth_last_of_type(self, name, expression)
  local xpath = self.xpaths[#self.xpaths]

  local a, b = parse_nth_expression(name, expression)
  xpath = build_nth_xpath(xpath, a, b, "following-sibling", self.node_predicate)

  self.xpaths[#self.xpaths] = xpath
end

function methods.on_functional_pseudo(self, name, expression)
  local callback = methods["on_functional_pseudo_" .. name:gsub("-", "_")]
  if callback then
    callback(self, name, expression)
  else
    error("Failed to convert to XPath: " ..
            "unsupported functional-pseudo: <" .. name .. ">")
  end
end

function XPathConverter.new()
  local converter = {
    xpaths = {},
  }
  setmetatable(converter, metatable)
  return converter
end

return XPathConverter
