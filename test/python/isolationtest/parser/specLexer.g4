lexer grammar specLexer;

SETUP: 'setup';
TEARDOWN: 'teardown';
SESSION: 'session';
STEP: 'step';
PERMUTATION: 'permutation';
SQLBLOCK: OPEN_PAR .*? CLOSE_PAR;
OPEN_PAR: '{';
CLOSE_PAR: '}';
OPEN_BRKT:'(';
CLOSE_BRKT:')';
AST:'*';
COMMA:',';
ID:[_a-zA-Z][a-zA-Z0-9_]*;
COMMENT : '#' ~[\r\n]* '\r'? '\n' -> skip ;
WS:[ \t\r\f\n]+ -> skip;