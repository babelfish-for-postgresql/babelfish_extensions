file(REMOVE_RECURSE
  "../../demo/generated/TLexer.cpp"
  "../../demo/generated/TParser.cpp"
  "../../demo/generated/TParserBaseListener.cpp"
  "../../demo/generated/TParserBaseVisitor.cpp"
  "../../demo/generated/TParserListener.cpp"
  "../../demo/generated/TParserVisitor.cpp"
  "CMakeFiles/GenerateParser"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/GenerateParser.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
