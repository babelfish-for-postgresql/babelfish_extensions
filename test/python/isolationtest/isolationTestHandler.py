import traceback

from antlr4 import *
from .parser.specLexer import specLexer
from .parser.specParser import specParser
from .specParserVisitorImpl import *


def isolationTestHandler(testFile, fileWriter, logger):
    testName = testFile.name.split('.')[0]

    try:
        logger.info("Starting : {}".format(testName))
        try:
            testSpec = parseSpecInput(str(testFile))
            if(testSpec is None):
                raise Exception("TestSpec object is not generated")
            else:
                print(testSpec)
                logger.info("Successfully parsed")
        except Exception as e:
            logger.error("Error while parsing : {}".format(str(e)))
            return False

        testSpec.logger = logger
        testSpec.fileWriter = fileWriter

        testSpec.initTestRun()

        logger.info("Completed : {}".format(testName))
        return True
    except Exception as e:
        logger.error(str(e))
        traceback.print_exc()
    return False


def parseSpecInput(filename):
    input_stream = FileStream(filename)
    lexer = specLexer(input_stream)
    token_stream = CommonTokenStream(lexer)
    parser = specParser(token_stream)
    tree = parser.parse()
    visitor = specParserVisitorImpl()
    visitor.visit(tree)
    return visitor.testSpec
