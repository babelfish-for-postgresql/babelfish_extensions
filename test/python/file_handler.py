from pathlib import Path
from utils.config import config_dict as cfg
import logging
from datetime import datetime
from batch_run import batch_run
from utils.db_client import   Db_Client_pymssql, Db_Client_pyodbc
import subprocess
import sys

#compare the generated and expected output files using diff command
def compare_outfiles(outfile, expected_file, logfname, filename, logger):
    try:
        diff_file = Path.cwd().joinpath("logs", logfname, filename, filename + ".diff")
        f_handle = open(diff_file, "wb")

        if "sql_expected" in expected_file.as_uri():
            if sys.platform.startswith("win"):
                proc = subprocess.run(args = ["fc", expected_file, outfile], stdout = f_handle, stderr = f_handle)
            else:
                proc = subprocess.run(args = ["diff", "-a", "-u", "-I", "~~ERROR", expected_file, outfile], stdout = f_handle, stderr = f_handle)
        else:
            if sys.platform.startswith("win"):
                proc = subprocess.run(args = ["fc", expected_file, outfile], stdout = f_handle, stderr = f_handle)
            else:
                proc = subprocess.run(args = ["diff", "-a", "-u", expected_file, outfile], stdout = f_handle, stderr = f_handle)

        rcode = proc.returncode
        f_handle.close()
        
        if rcode == 0:
            return True
        elif rcode ==  1:
            if cfg["printLogsToConsole"] == "true":
                with open(diff_file,"r") as f:
                    print(f.read())
            return False
        elif rcode == 2:
            if cfg["printLogsToConsole"] == "true":
                with open(diff_file,"r") as f:
                    print(f.read())
            logger.error("There was some trouble when the diff command was executed!")
            return False
        else:
            logger.error("Unknown exit code encountered while running diff!")
            return False
        
    except Exception as e:
        logger.error(str(e))
    
    return False

#main function to setup and tear down logger as well as connections for each testcase
def file_handler(file,logfname):
    
    #initialize variables
    passed = 0
    failed = 1

    #get the filname from absolute path and make a directory for the file logs   
    filename = file.name
    filename = filename.split(".")[0]
    logname = datetime.now().strftime(filename + '_%H_%M_%d_%m_%Y.log')
    try:
        path = Path.cwd().joinpath("logs", logfname, filename)
        Path.mkdir(path, parents = True, exist_ok = True)
    except:
        pass
    
    #settup logger for the specific file
    f_path = path.joinpath(logname)
    fh = logging.FileHandler(filename = f_path, mode = "w")
    formatter = logging.Formatter('%(asctime)s-%(levelname)s-%(message)s')
    fh.setFormatter(formatter)
    logger = logging.getLogger(filename)
    logger.addHandler(fh)
    logger.setLevel(logging.DEBUG)

    #add console logger in printLogsToConsole set 
    if cfg["runInParallel"] == "false" and cfg["printLogsToConsole"] == "true":
        sh = logging.StreamHandler()
        sh.setFormatter(formatter)
        logger.addHandler(sh)
        logger.setLevel(logging.DEBUG)
    
    bbl_cnxn = None

    #setup the connections to database
    if cfg["driver"].lower() == "pyodbc":
        bbl_cnxn = Db_Client_pyodbc(cfg["provider"], cfg["fileGenerator_URL"], cfg["fileGenerator_port"], cfg["fileGenerator_databaseName"], cfg["fileGenerator_user"], cfg["fileGenerator_password"], logger)

    elif cfg["driver"].lower() == "pymssql":
        bbl_cnxn = Db_Client_pymssql(cfg["fileGenerator_URL"], cfg["fileGenerator_port"], cfg["fileGenerator_databaseName"], cfg["fileGenerator_user"], cfg["fileGenerator_password"], logger)
    
    #checking wether the connection was succesful or not by getting a cursor object
    try:
        curs2 = bbl_cnxn.get_cursor()
        curs2.close()
    except Exception as e:
        logger.error(str(e))
        
        return (passed, failed)

    #initialise a file_handler
    outfile = Path.cwd().joinpath("output",cfg["driver"], filename + ".out")
    
    try:
        file_handler = open(outfile, "w")
        passed,failed = batch_run(bbl_cnxn, file_handler, file, logger)
        file_handler.close()
        if bbl_cnxn:
            bbl_cnxn.close()
    except Exception as e:
        logger.error(str(e))

    bbl_expected_file = Path.cwd().joinpath("expected", cfg["driver"],filename + ".out")
    sql_expected_file = Path.cwd().joinpath("sql_expected", cfg["driver"],filename + ".out")
    
    #to check for expected file in both sql and babel expected folders
    if bbl_expected_file.exists():
        result = compare_outfiles(outfile, bbl_expected_file, logfname, filename, logger)
    elif sql_expected_file.exists():
        result = compare_outfiles(outfile, sql_expected_file, logfname, filename, logger)
    #if expected file doesnt exist return failed
    else:
        logger.error("No expected file found with the associated testfile")
        result = False

    #based on result set passed and failed test values
    if result:
        passed = 1
        failed = 0
    else:
        passed = 0
        failed = 1
        
    
    
    
    #remove log handlers and close file/stream handlers
    logger.removeHandler(fh)
    fh.close()
    if cfg["runInParallel"] == "false" and cfg["printLogsToConsole"] == "true":
        logger.removeHandler(sh)
        sh.close()
    
    return (passed, failed) 
