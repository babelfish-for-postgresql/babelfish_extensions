%{
#include "postgres.h"
#include "lib/stringinfo.h"
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

extern char     *replace_special_chars_fts_impl(char *input_str);

static char     *scanbuf;
static int      scanbuflen;

static char     *translate_simple_term(const char* s);
static char     *trim(char *s, bool insideQuotes);
static void     replaceMultipleSpacesAndSpecialChars(char* input, char **str1, char **str2, bool isEnclosedInQuotes);

%}

%token WORD_TOKEN WS_TOKEN TEXT_TOKEN PREFIX_TERM_TOKEN GENERATION_TERM_TOKEN AND_TOKEN NOT_TOKEN AND_NOT_TOKEN OR_TOKEN INFLECTIONAL_TOKEN THESAURUS_TOKEN FORMSOF_TOKEN O_PAREN_TOKEN C_PAREN_TOKEN COMMA_TOKEN SPECIAL_CHAR_TOKEN NON_ENGLISH_TOKEN
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
    generation_term
    | simple_term
    | prefix_term
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
    GENERATION_TERM_TOKEN {
        fts_yyerror(NULL, "Generation term is not currently supported in Babelfish");
    }
    | FORMSOF_TOKEN O_PAREN_TOKEN generation_type COMMA_TOKEN simple_term_list C_PAREN_TOKEN {
        fts_yyerror(NULL, "Generation term is not currently supported in Babelfish");
    }
    ;

generation_type:
    INFLECTIONAL_TOKEN {
        fts_yyerror(NULL, "Generation term is not currently supported in Babelfish");
    }
    | THESAURUS_TOKEN {
        fts_yyerror(NULL, "Generation term is not currently supported in Babelfish");
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
static char 
*translate_simple_term(const char* inputStr) {
    int             inputLength;
    char            *trimmedInputStr;
    char            *leftStr;
    char            *rightStr;
    bool            isEnclosedInQuotes = false;
    StringInfoData  output;
    const char	    *inputPtr;

    /* Check for empty input - this should not be possible based on lexer rules, but check just in case */
    if (!inputStr || !(inputLength = strlen(inputStr))) {
        ereport(ERROR,
            (errcode(ERRCODE_INTERNAL_ERROR),
             errmsg("Null or empty full-text predicate.")));
    }

    trimmedInputStr = pstrdup(inputStr);

    /* removing trailing and leading spaces */
    trim(trimmedInputStr, false);
    inputLength = strlen(trimmedInputStr);

    /* Check if the input is a phrase enclosed in double quotes */
    if (inputLength >= 2 && trimmedInputStr[0] == '"' && trimmedInputStr[inputLength - 1] == '"') {
        trim(trimmedInputStr, true);
        isEnclosedInQuotes = true;
    }

    /* Rewriting the query in format one<->two | ('one UniqueHash two') in order to handle special characters */
    leftStr = pstrdup(trimmedInputStr);
    rightStr = pstrdup(trimmedInputStr);

    replaceMultipleSpacesAndSpecialChars(trimmedInputStr, &leftStr, &rightStr, isEnclosedInQuotes);
    
    inputLength = strlen(leftStr);

    initStringInfo(&output);
    appendStringInfoString(&output, "");

    /* for strings with special characters `, ', and _ (these result in exact matches) */
    if(strpbrk("`'_", leftStr) != NULL) {
        appendStringInfo(&output, "('%s')", replace_special_chars_fts_impl(leftStr));
        pfree(leftStr);
        pfree(rightStr);
        pfree(trimmedInputStr);
        return output.data;
    }

    /* Initialize pointers for input and output */
    for (inputPtr = leftStr; *inputPtr != '\0'; inputPtr++) {
        if (isspace((unsigned char)*inputPtr)) {
            /* Replace space with "<->" */
            while (isspace((unsigned char)*(inputPtr + 1))) {
                /* Handle multiples spaces between words and skip over additional spaces */
                inputPtr++;
            }
            appendStringInfoString(&output, "<->");
        } else {
            /* Copy the character */
            appendStringInfoChar(&output, *inputPtr);
        }
    }

    /* check for empty strings i.e. "" */
    if (output.len > 0) {
        appendStringInfo(&output, " | ('%s')", replace_special_chars_fts_impl(rightStr));
    }

    appendStringInfoChar(&output, '\0');

    pfree(leftStr);
    pfree(rightStr);
    pfree(trimmedInputStr);

    return output.data;
}

/* Helper function to generate two strings on the basis of the input string
 * 1. space separated words
 * 2. special character (@) separated words
 *
 * Case 1: "one two" will generate "one two" and "one@two"
 * Case 2: "one$two" will generate "one two" and "one@two"
 */
static void 
replaceMultipleSpacesAndSpecialChars(char* input, char **str1, char **str2, bool isEnclosedInQuotes) {
    size_t          inputLen = strlen(input);
    size_t          i;
    bool            inSpace = false;
    StringInfoData  resultSpaceSeparated;
    StringInfoData  resultAmpersandSeparated;
    StringInfoData  modifiedInput;
    const char      *specialChars = "~!&|@#$%^*+=\\;:<>?.\\/";
    const char      *boolOperators = "&!|";
    const char      *forbiddenChars = "([{]})\"";
    const char      *charInForbiddenChars;
    const char      *charInSpecialChars;
    const char      *charInBoolOperators;
    const char      *forbiddenCharsInQuotes = "(){}[],"; /* Additional forbidden characters when in quotes */

    initStringInfo(&resultSpaceSeparated);
    initStringInfo(&resultAmpersandSeparated);
    initStringInfo(&modifiedInput);

    if (isEnclosedInQuotes) {
        for (i = 0; i < inputLen; i++) {
            /* character " in between a phrase should throw syntax error */
            if (i != 0 && i != inputLen - 1 && input[i] == '"') {
                ereport(ERROR,
                    (errcode(ERRCODE_SYNTAX_ERROR),
                     errmsg("Syntax error near '%s' in the full-text search condition '%s'.", input + i + 1, input)));
            }

            if (strchr(forbiddenCharsInQuotes, input[i]) != NULL) {
                /* Replace forbiddenCharsInQuotes characters based on the position */
                while (i + 1 < inputLen && strchr(forbiddenCharsInQuotes, input[i + 1]) != NULL) {
                    i++;
                }
                if (i < inputLen - 1) {
                    appendStringInfoString(&modifiedInput, " ");
                }
            } else {
                if (strchr(specialChars, input[i]) != NULL || strchr("`'_", input[i]) != NULL) {
                    while (i + 1 < inputLen && isspace(input[i + 1])) {
                            i++;
                    }
                    if (i + 1 < inputLen && (strchr(specialChars, input[i + 1]) != NULL || strchr("`'_", input[i + 1]) != NULL)) {
                        ereport(ERROR,
                            (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                             errmsg("Consecutive special characters in the full-text search condition are not currently supported in Babelfish")));
                    } 
                }
                appendStringInfoChar(&modifiedInput, input[i]);
            }
        }
        /* Null-terminate the modified input string */
        appendStringInfoChar(&modifiedInput, '\0');
    } else {
        appendStringInfoString(&modifiedInput, input);
    }

    for (const char *currentCharPtr = modifiedInput.data; *currentCharPtr; ++currentCharPtr) {
        char currentChar = *currentCharPtr;
        char nextChar = *(currentCharPtr + 1);

        /* Store the result of strchr to avoid calling it multiple times */
        charInForbiddenChars = strchr(forbiddenChars, currentChar);
        charInSpecialChars = strchr(specialChars, currentChar);
        charInBoolOperators = strchr(boolOperators, currentChar);

        if (currentChar == '~') {
            ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("Proximity term is not currently supported in Babelfish")));
        }

        if (charInBoolOperators != NULL) {
            ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("Full-text search conditions with boolean operators are not currently supported in Babelfish")));
        }

        /* Check for forbidden characters when not in quotes */
        if (!isEnclosedInQuotes && charInForbiddenChars != NULL) {
            ereport(ERROR,
                (errcode(ERRCODE_SYNTAX_ERROR),
                 errmsg("Syntax error near '%c' in the full-text search condition '%s'.", currentChar, input)));
        }

        /* Check for consecutive special characters */
        if (nextChar && ((charInSpecialChars != NULL && strchr(specialChars, nextChar) != NULL) || (strchr("`'_", currentChar) != NULL && strchr("`'_", nextChar) != NULL))) {
            ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("Consecutive special characters in the full-text search condition are not currently supported in Babelfish")));
        } else if (isspace(currentChar) || charInSpecialChars != NULL || (isEnclosedInQuotes && strchr("`'_", currentChar) != NULL)) {
            if (!inSpace) {
                if (currentCharPtr != modifiedInput.data && *(currentCharPtr + 1))
                        appendStringInfoChar(&resultSpaceSeparated, ' ');
                appendStringInfoChar(&resultAmpersandSeparated, '@');
                inSpace = true;
            }
        } else {
            appendStringInfoChar(&resultSpaceSeparated, currentChar);
            appendStringInfoChar(&resultAmpersandSeparated, currentChar);
            inSpace = false;
        }
    }

    /* Null-terminate the result strings */
    appendStringInfoChar(&resultSpaceSeparated, '\0');
    appendStringInfoChar(&resultAmpersandSeparated, '\0');

    /* Assign the pointers in the main function to the result strings */
    *str1 = resultSpaceSeparated.data;
    *str2 = resultAmpersandSeparated.data;
}


/*
 * Function to remove leading and trailing spaces of a string
 * If flag is true then it removes spaces inside double quotes
 */
static char 
*trim(char *s, bool insideQuotes) {
    size_t length;
    size_t start;
    size_t end;
    size_t newLength;

    /*
     * Empty string, nothing to trim
     * for the empty input, we're automatically throwing error, 
     * so if string is NULL or empty, this clause won't pose any issue, it's just a safety check
     */
    if (!s || !(length = strlen(s))) {
        return s;
    }

    start = 0;
    end = length - 1;

    if(insideQuotes) {
        start++;
        end--;
    }

    /* Trim leading spaces */
    while (start < length && isspace(s[start])) {
        start++;
    }

    /* Trim trailing spaces */
    while (end > start && isspace(s[end])) {
        end--;
    }

    /* Calculate the new length */
    newLength = end - start + 1;

    /* Shift the non-space part to the beginning of the string */
    memmove(s, s + start, newLength);

    /* Null-terminate the result */
    s[newLength] = '\0';

    return s;
}

# include "fts_scan.c"