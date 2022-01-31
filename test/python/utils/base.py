from utils.config import read_config
from pathlib import Path
import pymssql
import pyodbc
import re

#to make list of files paths to run as tests
def add_files():
    cfg = read_config()
    
    testnames = cfg["testName"]
    if ";" in testnames:
        testnames = testnames.split(";")
    else:
        testnames = [testnames]

    testdir = cfg["inputFilesPath"]
    #pth = Path.cwd().joinpath(testdir)
    pth = Path(testdir)
    
    #recursively search and return .sql and .txt files
    if "all" in testnames:
        files = []
        for f in pth.rglob("*.txt"):
            files.append(f)

        for f in pth.rglob("*.sql"):
            files.append(f)
        
        return files
    #search for testcase name recursively
    else:
        lst = []
        for item in testnames:
            for f in pth.rglob(item):
                lst.append(f)
        
        return lst

#to handle exceptions for babel server execution and return corresponding error code
def handle_babel_exception(e, logger):
    if issubclass(type(e), pyodbc.Error):
        code = re.findall(r"\(\d+\)", e.args[1])

        if len(code) > 0:
            code = code[0][1:-1]
            logger.warning("Babel Exception: " + str(code))  

        logger.warning("Babel Exception: " + e.args[1])
    
    elif issubclass(type(e),pymssql.Error):
        logger.warning("Babel Exception: " + str(e.args[0])) 
        logger.warning("Babel Exception: " + repr(str(e.args[1].decode())))
    
    #default
    else:
        logger.warning("Babel Exception: " + str(e))
