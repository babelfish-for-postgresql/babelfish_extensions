parser grammar specParser;
options {tokenVocab=specLexer;}

parse: testspec EOF;

testspec :	setup* teardown? session+ permutation*;

setup: SETUP SQLBLOCK;

teardown: TEARDOWN SQLBLOCK;

session: SESSION ID setup? step+ teardown?;

step: STEP ID SQLBLOCK;

pstep: ID (OPEN_BRKT blockers CLOSE_BRKT)?;

blockers: (AST | ID) (COMMA (AST | ID))*;

permutation: PERMUTATION pstep+;
