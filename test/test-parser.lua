local luaunit = require("luaunit")
local luacs = require("luacs")

TestParser = {}

function parse(selectors_group)
  local events = {}
  local listener = {}
  listener.on_start_selectors_group = function(self)
    table.insert(events, "start_selectors_group")
  end
  listener.on_end_selectors_group = function(self)
    table.insert(events, "end_selectors_group")
  end
  listener.on_start_selector = function(self)
    table.insert(events, "start_selector")
  end
  listener.on_end_selector = function(self)
    table.insert(events, "end_selector")
  end
  listener.on_start_simple_selector_sequence = function(self)
    table.insert(events, "start_simple_selector_sequence")
  end
  listener.on_end_simple_selector_sequence = function(self)
    table.insert(events, "end_simple_selector_sequence")
  end
  listener.on_type_selector = function(self, namespace_prefix, element_name)
    table.insert(events, {
                   event = "type_selector",
                   namespace_prefix = namespace_prefix,
                   element_name = element_name,
    })
  end
  listener.on_universal = function(self, namespace_prefix)
    table.insert(events, {
                   event = "universal",
                   namespace_prefix = namespace_prefix,
    })
  end
  listener.on_hash = function(self, name)
    table.insert(events, {
                   event = "hash",
                   name = name,
    })
  end
  listener.on_class = function(self, name)
    table.insert(events, {
                   event = "class",
                   name = name,
    })
  end
  listener.on_attribute = function(self, namespace_prefix, name, operator, value)
    table.insert(events, {
                   event = "attribute",
                   namespace_prefix = namespace_prefix,
                   name = name,
                   operator = operator,
                   value = value,
    })
  end
  listener.on_pseudo_element = function(self, name)
    table.insert(events, {
                   event = "pseudo_element",
                   name = name,
    })
  end
  listener.on_pseudo_class = function(self, name)
    table.insert(events, {
                   event = "pseudo_class",
                   name = name,
    })
  end
  listener.on_functional_pseudo = function(self, name, expression)
    table.insert(events, {
                   event = "functional_pseudo",
                   name = name,
                   expression = expression,
    })
  end
  listener.on_start_negation = function(self, name, expression)
    table.insert(events, "start_negation")
  end
  listener.on_end_negation = function(self, name, expression)
    table.insert(events, "end_negation")
  end
  listener.on_combinator = function(self, combinator)
    table.insert(events, {
                   event = "combinator",
                   combinator = combinator,
    })
  end
  local parser = luacs.Parser.new(selectors_group, listener)
  local successed = parser:parse()
  return {successed, events}
end

function TestParser.test_selectors_group()
  luaunit.assertEquals(parse("ul, ol"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "ul",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "ol",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_selector_combinator_plus()
  luaunit.assertEquals(parse("body + p"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "body"
                           },
                           "end_simple_selector_sequence",
                           {
                             event = "combinator",
                             combinator = "+",
                           },
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p"
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_selector_combinator_greater()
  luaunit.assertEquals(parse("body > p"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "body"
                           },
                           "end_simple_selector_sequence",
                           {
                             event = "combinator",
                             combinator = ">",
                           },
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p"
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_selector_combinator_tilde()
  luaunit.assertEquals(parse("body ~ p"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "body"
                           },
                           "end_simple_selector_sequence",
                           {
                             event = "combinator",
                             combinator = "~",
                           },
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p"
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_selector_combinator_whitespace()
  luaunit.assertEquals(parse("body   p"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "body"
                           },
                           "end_simple_selector_sequence",
                           {
                             event = "combinator",
                             combinator = " ",
                           },
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p"
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector()
  luaunit.assertEquals(parse("html"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "html",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_namespace_prefix_star()
  luaunit.assertEquals(parse("*|html"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = "*",
                             element_name = "html",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_namespace_prefix_name()
  luaunit.assertEquals(parse("xhtml|html"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = "xhtml",
                             element_name = "html",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_namespace_prefix_none()
  luaunit.assertEquals(parse("|html"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = "",
                             element_name = "html",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_hash()
  luaunit.assertEquals(parse("p#content"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "hash",
                             name = "content",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_class()
  luaunit.assertEquals(parse("p.content"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "class",
                             name = "content",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute()
  luaunit.assertEquals(parse("p[ id ]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "id",
                             operator = nil,
                             value = nil,
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute_namespace_prefix()
  luaunit.assertEquals(parse("p[ xml|lang ]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = "xml",
                             name = "lang",
                             operator = nil,
                             value = nil,
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute_prefix_match()
  luaunit.assertEquals(parse("a[href ^= \"https://\"]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "a",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "href",
                             operator = "^=",
                             value = "https://",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute_suffix_match()
  luaunit.assertEquals(parse("a[href $= html]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "a",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "href",
                             operator = "$=",
                             value = "html",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute_substring_match()
  luaunit.assertEquals(parse("a[href *= secret]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "a",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "href",
                             operator = "*=",
                             value = "secret",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute_equal()
  luaunit.assertEquals(parse("a[id = content]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "a",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "id",
                             operator = "=",
                             value = "content",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute_includes()
  luaunit.assertEquals(parse("a[class ~= menu]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "a",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "class",
                             operator = "~=",
                             value = "menu",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_attribute_dash_match()
  luaunit.assertEquals(parse("a[lang |= ja]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "a",
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "lang",
                             operator = "|=",
                             value = "ja",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_pseudo_element()
  luaunit.assertEquals(parse("p::before"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "pseudo_element",
                             name = "before",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_pseudo_class()
  luaunit.assertEquals(parse("a:visited"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "a",
                           },
                           {
                             event = "pseudo_class",
                             name = "visited",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_functional_pseudo_plus()
  luaunit.assertEquals(parse("p:nth-child(+1)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"plus"},
                               {"number", 1},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_functional_pseudo_minus()
  luaunit.assertEquals(parse("p:nth-child(-1)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"minus"},
                               {"number", 1},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_functional_pseudo_dimension()
  luaunit.assertEquals(parse("p:nth-child(2n)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"dimension", "2n"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_functional_pseudo_number()
  luaunit.assertEquals(parse("p:nth-child(1)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"number", 1},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_functional_pseudo_string_double_quote()
  -- TODO: Invalid nth-child
  luaunit.assertEquals(parse("p:nth-child(\"a\")"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"string", "a"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_functional_pseudo_string_single_quote()
  -- TODO: Invalid nth-child
  luaunit.assertEquals(parse("p:nth-child('a')"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"string", "a"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_functional_pseudo_ident()
  luaunit.assertEquals(parse("p:lang(ja)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           {
                             event = "functional_pseudo",
                             name = "lang",
                             expression = {
                               {"name", "ja"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_negation_type_selector()
  luaunit.assertEquals(parse("p:not( span )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           "start_negation",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "span",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_negation_universal()
  luaunit.assertEquals(parse("p:not( * )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           "start_negation",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_negation_hash()
  luaunit.assertEquals(parse("p:not( #content )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           "start_negation",
                           {
                             event = "hash",
                             name = "content",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_negation_class()
  luaunit.assertEquals(parse("p:not( .content )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p",
                           },
                           "start_negation",
                           {
                             event = "class",
                             name = "content",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_negation_attribute()
  luaunit.assertEquals(parse("p:not( [|class] )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p"
                           },
                           "start_negation",
                           {
                             event = "attribute",
                             namespace_prefix = "",
                             name = "class",
                             operator = nil,
                             value = nil,
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_type_selector_negation_pseudo()
  luaunit.assertEquals(parse("p:not( :checked )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "p"
                           },
                           "start_negation",
                           {
                             event = "pseudo_class",
                             name = "checked",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal()
  luaunit.assertEquals(parse("*"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_namespace_prefix_star()
  luaunit.assertEquals(parse("*|*"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = "*",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_namespace_prefix_name()
  luaunit.assertEquals(parse("xhtml|*"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = "xhtml",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_namespace_prefix_none()
  luaunit.assertEquals(parse("|*"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = "",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_hash()
  luaunit.assertEquals(parse("*#content"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "hash",
                             name = "content",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_class()
  luaunit.assertEquals(parse("*.content"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "class",
                             name = "content",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute()
  luaunit.assertEquals(parse("*[id]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "id",
                             operator = nil,
                             value = nil,
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute_namespace_prefix()
  luaunit.assertEquals(parse("*[xml|lang]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = "xml",
                             name = "lang",
                             operator = nil,
                             value = nil,
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_pseudo_element()
  luaunit.assertEquals(parse("*::before"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "pseudo_element",
                             name = "before",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_pseudo_class()
  luaunit.assertEquals(parse("*:visited"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "pseudo_class",
                             name = "visited",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_functional_pseudo_plus()
  luaunit.assertEquals(parse("*:nth-child(+1)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"plus"},
                               {"number", 1},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_functional_pseudo_minus()
  luaunit.assertEquals(parse("*:nth-child(-1)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"minus"},
                               {"number", 1},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_functional_pseudo_dimension()
  luaunit.assertEquals(parse("*:nth-child(2n)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"dimension", "2n"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_functional_pseudo_number()
  luaunit.assertEquals(parse("*:nth-child(1)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"number", 1},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_functional_pseudo_string_double_quote()
  -- TODO: Invalid nth-child
  luaunit.assertEquals(parse("*:nth-child(\"a\")"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"string", "a"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_functional_pseudo_string_single_quote()
  -- TODO: Invalid nth-child
  luaunit.assertEquals(parse("*:nth-child('a')"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "functional_pseudo",
                             name = "nth-child",
                             expression = {
                               {"string", "a"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_functional_pseudo_ident()
  luaunit.assertEquals(parse("*:lang(ja)"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "functional_pseudo",
                             name = "lang",
                             expression = {
                               {"name", "ja"},
                             },
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_negation_type_selector()
  luaunit.assertEquals(parse("*:not( span )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "start_negation",
                           {
                             event = "type_selector",
                             namespace_prefix = nil,
                             element_name = "span",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_negation_universal()
  luaunit.assertEquals(parse("*:not( * )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "start_negation",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_negation_hash()
  luaunit.assertEquals(parse("*:not( #content )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "start_negation",
                           {
                             event = "hash",
                             name = "content",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_negation_class()
  luaunit.assertEquals(parse("*:not( .content )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "start_negation",
                           {
                             event = "class",
                             name = "content",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_negation_attribute()
  luaunit.assertEquals(parse("*:not( [|class] )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "start_negation",
                           {
                             event = "attribute",
                             namespace_prefix = "",
                             name = "class",
                             operator = nil,
                             value = nil,
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_negation_pseudo()
  luaunit.assertEquals(parse("*:not( :checked )"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           "start_negation",
                           {
                             event = "pseudo_class",
                             name = "checked",
                           },
                           "end_negation",
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute_prefix_match()
  luaunit.assertEquals(parse("*[href ^= \"https://\"]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "href",
                             operator = "^=",
                             value = "https://",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute_suffix_match()
  luaunit.assertEquals(parse("*[href $= html]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "href",
                             operator = "$=",
                             value = "html",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute_substring_match()
  luaunit.assertEquals(parse("*[href *= secret]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "href",
                             operator = "*=",
                             value = "secret",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute_equal()
  luaunit.assertEquals(parse("*[id = content]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "id",
                             operator = "=",
                             value = "content",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute_includes()
  luaunit.assertEquals(parse("*[class ~= menu]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "class",
                             operator = "~=",
                             value = "menu",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end

function TestParser.test_universal_attribute_dash_match()
  luaunit.assertEquals(parse("*[lang |= ja]"),
                       {
                         true,
                         {
                           "start_selectors_group",
                           "start_selector",
                           "start_simple_selector_sequence",
                           {
                             event = "universal",
                             namespace_prefix = nil,
                           },
                           {
                             event = "attribute",
                             namespace_prefix = nil,
                             name = "lang",
                             operator = "|=",
                             value = "ja",
                           },
                           "end_simple_selector_sequence",
                           "end_selector",
                           "end_selectors_group",
                         },
                       }
  )
end
