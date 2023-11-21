%{
#include "postgres.h"
#include <ctype.h>
#include "fts_data.h"

/* All grammar constructs return strings */
#define FTS_YYSTYPE char *

/*
 * Bison doesn't allocate anything that needs to live across parser calls,
 * so we can easily have it use palloc instead of palloc.  This prevents
 * memory leaks if we error out during parsing.  Note this only works with
 * bison >= 2.0.  However, in bison 1.875 the default is to use alloca()
 * if possible, so there's not really much problem anyhow, at least if
 * you're building with gcc.
 */
#define YYpALLOC palloc
#define YYFREE   pfree

static char *scanbuf;
static int	scanbuflen;

static char* translate_simple_term(const char* s);
static char *trim(char *s);
static char *trimInsideQuotes(char *s);

%}

%token WORD_TOKEN WS_TOKEN TEXT_TOKEN PREFIX_TERM_TOKEN GENERATION_TERM_TOKEN AND_TOKEN AND_NOT_TOKEN OR_TOKEN INFLECTIONAL_TOKEN THESAURUS_TOKEN FORMSOF_TOKEN O_PAREN_TOKEN C_PAREN_TOKEN COMMA_TOKEN
%left OR_TOKEN
%left AND_TOKEN
%left AND_NOT_TOKEN

%start contains_search_condition
%define api.prefix {fts_yy}
%parse-param {char** result}
%expect 0

/* Grammar follows */
%%

contains_search_condition:
    simple_term
    | prefix_term
    | generation_term
    ;

simple_term:
    WORD_TOKEN  {
        *result = translate_simple_term($1);
    }
    | TEXT_TOKEN {
        *result = translate_simple_term($1);
    }
    | WS_TOKEN WORD_TOKEN {
        *result = translate_simple_term($2);
    }
    | WORD_TOKEN WS_TOKEN {
        *result = translate_simple_term($1);
    }
    | WS_TOKEN WORD_TOKEN WS_TOKEN {
        *result = translate_simple_term($2);
    }
    | WS_TOKEN TEXT_TOKEN {
        *result = translate_simple_term($2);
    }
    | TEXT_TOKEN WS_TOKEN {
        *result = translate_simple_term($1);
    }
    | WS_TOKEN TEXT_TOKEN WS_TOKEN {
        *result = translate_simple_term($2);
    }
    ;

prefix_term:
    PREFIX_TERM_TOKEN {
        fts_yyerror(NULL, "Prefix term is not currently supported in Babelfish");
    }
    ;

generation_term:
    FORMSOF_TOKEN O_PAREN_TOKEN generation_type COMMA_TOKEN simple_term_list C_PAREN_TOKEN {
        fts_yyerror(NULL, "Generation term is not currently supported in Babelfish");
    }
    ;

generation_type:
    INFLECTIONAL_TOKEN {
        $$ = $1;
    }
    | THESAURUS_TOKEN {
        $$ = $1;
    }
    ;

simple_term_list:
    simple_term {
        $$ = $1;
    }
    | simple_term_list COMMA_TOKEN simple_term {
        $$ = $1;
    }
    ;

%%

/* Helper function that takes in a word or phrase and returns the same word/phrase in Postgres format
 * Example: 'word' is rewritten into 'word'; '"word1 word2 word3"' is rewritten into 'word1<->word2<->word3'
 * Case 1: 'word' = 'word'
 * Case 2: '"word1 word2 word3"' = 'word1<->word2<->word3'
 * Case 3: '  word' = 'word' || 'word ' = 'word' || ' word ' = 'word'
 * Case 4: '" word1 word2"' = 'word1<->word2' || '"word1 word2 "' = 'word1<->word2' || '" word1 word2 "' = 'word1<->word2'
 * Trivial Case: spaces before and after double quotes, Example - '   "word1 word2" ' = 'word1<->word2'
 */
static
char* translate_simple_term(const char* inputStr) {
    int inputLength;
    int outputSize;
    char* output;
    const char* inputPtr;
    char* outputPtr;
    char* trimmedInputStr;

    // Check for empty input
    if (inputStr == NULL) {
        return NULL;
    }

    trimmedInputStr = pstrdup(inputStr);

    // removing trailing and leading spaces
    trim(trimmedInputStr);
    inputLength = strlen(trimmedInputStr);

    // Check if the input is a phrase enclosed in double quotes
    if (trimmedInputStr[0] == '"' && trimmedInputStr[inputLength - 1] == '"') {
        trimInsideQuotes(trimmedInputStr);
        inputLength = strlen(trimmedInputStr);

        // Calculate the maximum possible size of output
        outputSize = inputLength * 3;

        // Check for potential overflow and adjust the output size
        if (outputSize < inputLength || outputSize < 0) {
            pfree(trimmedInputStr);
            return NULL; // Potential overflow
        }

        // Allocate the output buffer with the adjusted size
        output = (char*)palloc(outputSize + 1); // +1 for the null terminator
        if (output == NULL) {
            pfree(trimmedInputStr);
            return NULL;
        }

        // Initialize pointers for input and output
        inputPtr = trimmedInputStr;
        outputPtr = output;

        while (*inputPtr != '\0') {
            if (*inputPtr == ' ') {
                // Replace space with "<->"
                while (*(inputPtr + 1) == ' ') {
                    // Handle multiples spaces between words and skip over additional spaces
                    inputPtr++;
                }
                if (outputPtr - output + 3 > outputSize) {
                    // Output buffer overflow
                    pfree(trimmedInputStr);
                    pfree(output);
                    return NULL;
                }
                *outputPtr++ = '<';
                *outputPtr++ = '-';
                *outputPtr++ = '>';
            } else {
                // Copy the character
                if (outputPtr - output + 1 > outputSize) {
                    // Output buffer overflow
                    pfree(trimmedInputStr);
                    pfree(output);
                    return NULL;
                }
                *outputPtr++ = *inputPtr;
            }
            inputPtr++;
        }

        pfree(trimmedInputStr);
        return output;
    } else {
        // It's a single word, so no transformation needed
        return trimmedInputStr;
    }
}

// Function to remove leading and trailing spaces of a string
static char *trim(char *s) {
    size_t length;
    size_t start;
    size_t end;
    size_t newLength;

    length = strlen(s);
    
    // Empty string, nothing to trim
    if (s == NULL || length == 0) {
        return s;
    }

    start = 0;
    end = length - 1;

    // Trim leading spaces
    while (start < length && isspace(s[start])) {
        start++;
    }

    // Trim trailing spaces
    while (end > start && isspace(s[end])) {
        end--;
    }

    // Calculate the new length
    newLength = end - start + 1;

    // Shift the non-space part to the beginning of the string
    memmove(s, s + start, newLength);

    // Null-terminate the result
    s[newLength] = '\0';

    return s;
}

// Function to remove leading and trailing spaces inside double quotes
static char *trimInsideQuotes(char *s) {
    size_t length;
    size_t start;
    size_t end;
    size_t i;
    size_t newLength;
    bool insideQuotes;

    length = strlen(s);

    // Empty string, nothing to trim
    if (s == NULL || length == 0) {
        return s;
    }

    insideQuotes = false;
    start = 1;
    end = length - 2;

    for (i = 0; i < length; i++) {
        if (s[i] == '"') {
            insideQuotes = !insideQuotes;
        }

        if (!insideQuotes) {
            // Trim leading spaces inside quotes
            while (start < length && isspace(s[start])) {
                start++;
            }

            // Trim trailing spaces inside quotes
            while (end > start && isspace(s[end])) {
                end--;
            }
        }
    }

    // Calculate the new length
    newLength = end - start + 1;

    // Shift the non-space part to the beginning of the string
    memmove(s, s + start, newLength);

    // Null-terminate the result
    s[newLength] = '\0';

    return s;
}

# include "fts_scan.c"