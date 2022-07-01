from datetime import datetime
import logging
import re
from pathlib import Path
import subprocess
import sys
from utils.config import config_dict as cfg


# create a list of files
def list_files(inpPath, filefilter):
    path = Path(inpPath)

    files = []
    for f in path.rglob(filefilter):
        files.append(f)
    return files


# search for patterns in the upgrade scripts
def find_pattern_drop(pattern, fname, logger):

    # create output file path
    path = Path.cwd().joinpath("output", "sql_validation_framework")
    Path.mkdir(path, parents = True, exist_ok = True)
    f_path = path.joinpath(fname + ".out")

    logger.info("Finding unexpected {0} statements".format(re.sub("[^a-zA-Z0-9 ]", "", pattern)))
    
    # open the output file
    with open(f_path, "w") as expected_file:
        scripts = list_files("../../contrib", "*/sql/upgrades/*.sql")

        # looping through all the upgrade scripts
        for filename in scripts:
            with  open(filename, "r") as file:
  
                line = file.readline()

                # flag for ignoring body of procedure
                readflag = True
                while line:
                    line = line.strip()

                    # ignoring comments in the script
                    if line.startswith("--") or line.startswith("/*") or line.startswith("#"):
                        line = file.readline()
                        continue

                    elif readflag == True and re.search(pattern, line, re.I):
                        # logic to get object name and type from the line
                        newline = line.lower()
                        if "(" in newline:
                            newline = newline.split('(')[0]

                        newline = newline.rstrip(';')
                        if "using" in newline:
                            newline = newline.split('using')[0]

                        linewords = newline.split()

                        object_types = ['table', 'view', 'function', 'procedure', 'role', 'class', 'cast', 'family']
                            
                        # setting default object category as object
                        obj_type = 'object'
                            
                        for word in linewords:
                            if word in object_types:
                                obj_type = word
                                break
                            
                        if obj_type == 'class' or obj_type == 'family':
                            obj_type = 'operator ' + obj_type
                            
                        # list of syntax words
                        syntax_words = ['drop', 'create', 'view', 'procedure', 'function', 'table', 'domain', 
                                'index', 'schema', 'temporary', 'aggregate', 'cascade', 'if', 'exists', 'owned', 
                                'class', 'operator', 'cast', 'family',
                                'by', 'role', 'as', 'or', 'replace', 'collation', 'not', 'select']
                            
                        # creating list of line words that are not present in syntax words so that we are left with object name
                        resultwords  = [word for word in linewords if word not in syntax_words]
                        obj_name = ' '.join(resultwords)

                        # add to output file
                        expected_file.write("Unexpected {0} found for {1} {2} in file {3}\n".format(re.sub("[^a-zA-Z0-9 ]", "", pattern), obj_type, obj_name, filename))
                    
                    # enable or disable the readflag (flag to ignore the body of procedures)
                    # at max $$ can be present twice in a line
                    # if $$ present twice, we dont change the readflag
                    if len(re.findall(r"[$]{2}", line, re.I)) == 1:
                        readflag = not readflag
                        
                    line = file.readline()
    logger.info("Searching {0} statements completed successfully!".format(re.sub("[^a-zA-Z0-9 ]", "", pattern)))



# list of installation and upgrade scripts
def list_scripts_create():
    inpPath = "../../contrib/babelfishpg_tsql/sql"
    path = Path(inpPath)

    scripts = []

    for f in path.glob("*.sql"):
        scripts.append(f)

    path = path.joinpath("upgrades")
    for f in path.glob("*.sql"):
        scripts.append(f)

    # removing helper functions
    scripts.remove(Path(inpPath + "/sys_function_helpers.sql"))
    return scripts


# search for create statements and return a set of tuple (object_type, object_name)
def find_pattern_create(logger):
    scripts = list_scripts_create()

    # set to avoid searching for redundant object names
    object_names = set()
    
    logger.info("Searching created objects!!")
    
    # getting list of object types to be searched from config
    pattern = r"^create [\w\s]*\b({0})\b".format(cfg["createObjectSearch"].replace(',', '|'))
    
    # looping through all the scripts
    for filename in scripts:
        with  open(filename, "r") as file:
            line = file.readline()

            # flag for ignoring body of procedure
            readflag = True
            while line:
                line = line.strip()
                
                # ignoring comments in the script
                if line.startswith("--") or line.startswith("/*") or line.startswith("#"):
                    line = file.readline()
                    continue

                elif readflag == True and re.search(pattern, line, re.I):
                    # logic to get object name and type from the line
                    newline = line.lower()
                    
                    if "(" in newline:
                        newline = newline.split('(')[0].strip()

                    newline = newline.rstrip(';')
                    linewords = newline.split()
                    object_types = ['table', 'view', 'function', 'procedure', 'role', 'aggregate', 'schema', 'domain', 'collation', 'index']
                        
                    # setting default object category as object
                    obj_type = 'object'
                    for word in linewords:
                        if word in object_types:
                            obj_type = word
                        
                    # list of syntax words
                    syntax_words = ['drop', 'create', 'view', 'procedure', 'function', 'table', 'domain', 
                                'index', 'schema', 'temporary', 'aggregate', 'cascade', 'if', 'exists', 'owned', 
                                'class', 'operator', 'cast', 'family',
                                'by', 'role', 'as', 'or', 'replace', 'collation', 'not', 'select']

                    # creating list of line words that are not present in syntax words so that we are left with object name
                    resultwords  = [word for word in linewords if word not in syntax_words]
                    obj_name = ' '.join(resultwords)

                    # adding bracket at the end of regex for functions
                    # such that func(, func ( and func  ( are considered valid
                    if obj_type == 'function':
                        obj_name += r"\s{0,2}[(]"

                    object_names.add((obj_type, obj_name))

                # enable or disable the readflag (flag to ignore the body of procedures)
                # at max $$ can be present twice in a line
                # if $$ present twice, we dont change the readflag
                if len(re.findall(r"[$]{2}", line, re.I)) == 1:
                    readflag = not readflag    
                line = file.readline()
                
    logger.info("Found all create objects successfully!")
    return object_names


# find if given pattern exists in the files passed by a list
def find_obj(files, pattern):
    for i in files:
        with open(i, "r") as testfile:
            testline = testfile.readline()

            while testline:
                testline = testline.strip()

                # ignoring comments in the file
                if testline.startswith("--") or testline.startswith("/*") or testline.startswith("#"):
                    testline = testfile.readline()
                    continue

                # if pattern exists, return true
                elif(re.search( pattern, testline, re.I)):
                    return True
                testline = testfile.readline()
    return False


# find the object name in the test files
def find_in_JDBC(fname, logger):

    # get the list of JDBC input files
    files = list_files("../JDBC/input", "*.*")

    # get the set of create object_name
    object_name = find_pattern_create(logger)
    
    # set output file path
    path = Path.cwd().joinpath("output", "sql_validation_framework")
    Path.mkdir(path, parents = True, exist_ok = True)
    f_path = path.joinpath(fname + ".out")

    with open(f_path, "w") as expected_file:
        for object in object_name:

            # flag for object name found or not in the JDBC input files
            flag = False

            pattern = object[1]

            # replacing . as in regex it means any character
            if "." in object[1]:
                pattern = object[1].replace(".", "[.]")

            # adding word boundary if object is not a function
            if not object[0] == 'function':
                pattern = pattern + r"\b"

            flag = find_obj(files, r"\b" + pattern)

            # searching again without schema name for objects in sys schema

            if(flag == False and "sys." in object[1]):
                pattern = r"\b" + pattern.replace("sys[.]", "")
                
                # creating pattern to identify @@func calls
                if object[0] == 'function':
                    pattern = "(" + "@@" + pattern.replace("\s{0,2}[(]", "").replace("\\b", "") + ")|(" +  pattern + ")"
                

                flag = find_obj(files, pattern)
            
            # if tests not found, add it to output file
            if flag == False:
                expected_file.write("Could not find tests for {0} {1}\n".format(object[0], object[1].split('\s')[0]))
    logger.info("Tests for objects found successfully!")



# find patterns in the framework
def find_patterns(logfname, logger):
    
    logger.info("Running tests for pattern search!!")
    
    # get the list of patterns from config
    patterns = cfg["searchPatterns"].split(',')
    found = True
    result = False

    for pattern in patterns:
        # generate outputfile name
        filename = "expected_" + re.sub("[^a-zA-Z0-9 ]", "", pattern)
        
        # search for the pattern
        find_pattern_drop(pattern, filename, logger)
        
        expected_file = Path.cwd().joinpath("expected", "sql_validation_framework", filename + ".out")
        outfile = Path.cwd().joinpath("output", "sql_validation_framework", filename + ".out")
        
        # check if expected and output files are same
        result = compare_outfiles(outfile, expected_file, logfname, filename, logger)

        # varaible to pass the test if no diff found for all patterns else fail the test
        found = found and result
    
    logger.info("Patterns searched successfully!!")
    return found


# compare the generated and expected file using diff
def compare_outfiles(outfile, expected_file, logfname, filename, logger):
    try:
        diff_file = Path.cwd().joinpath("logs", logfname, "sql_validation", filename + ".diff")
        f_handle = open(diff_file, "wb")

        # sorting the files as set will give unordered outputs
        if sys.platform.startswith("win"):
            proc_sort = subprocess.run(args = ["sort", expected_file, "/o", expected_file])
            proc_sort = subprocess.run(args = ["sort", outfile, "/o", outfile])
            proc = subprocess.run(args = ["fc", expected_file, outfile], stdout = f_handle, stderr = f_handle)
        else:
            proc_sort = subprocess.run(args = ["sort", "-o", expected_file, expected_file])
            proc_sort = subprocess.run(args = ["sort", "-o", outfile, outfile])
            proc = subprocess.run(args = ["diff", "-a", "-u", "-I", "~~ERROR", expected_file, outfile], stdout = f_handle, stderr = f_handle)
        
        rcode = proc.returncode
        f_handle.close()
        
        # adding logs based on the returncode of diff command
        if rcode == 0:
            logger.info("No difference found!")
            return True
        elif rcode ==  1:
            with open(diff_file, "r") as f:
                logger.info("\n" + f.read())
            return False
        elif rcode == 2:
            with open(diff_file, "r") as f:
                logger.info("\n" + f.read())
            logger.error("Some error occured while executing the diff command!")
            return False
        else:
            logger.error("Unknown exit code encountered while running diff!")
            return False
        
    except Exception as e:
        logger.error(str(e))
    
    return False



# set up logger for the framework
def create_logger():

    # set up path for logger
    log_folder_name = datetime.now().strftime('log_%H_%M_%d_%m_%Y')
    path = Path.cwd().joinpath("logs", log_folder_name)
    Path.mkdir(path, parents = True, exist_ok = True)

    filename = "sql_validation"
    logname = datetime.now().strftime(filename + '_%H_%M_%d_%m_%Y.log')

    path = Path.cwd().joinpath("logs", log_folder_name, filename)
    Path.mkdir(path, parents = True, exist_ok = True)

    # creating logger with two handlers, file as well as console
    # file logger
    file_path = path.joinpath(logname)

    fh = logging.FileHandler(filename = file_path, mode = "w")
    formatter = logging.Formatter('%(asctime)s-%(levelname)s-%(message)s')
    fh.setFormatter(formatter)
    logger = logging.getLogger(filename)
    logger.addHandler(fh)
    logger.setLevel(logging.DEBUG)

    # console logger
    sh = logging.StreamHandler()
    sh.setFormatter(formatter)
    logger.addHandler(sh)
    logger.setLevel(logging.DEBUG)

    return log_folder_name, logger


# remove and close log handlers
def close_logger(logger):
    if logger is None:
        return
    else:
        for handler in list(logger.handlers):
            logger.removeHandler(handler) 
            handler.close()

def main():

    fname_create = "expected_create"

    logfname, logger = create_logger()

    result1 = find_patterns(logfname, logger)

    find_in_JDBC(fname_create, logger)
    expected_file = Path.cwd().joinpath("expected", "sql_validation_framework", fname_create + ".out")
    outfile = Path.cwd().joinpath("output", "sql_validation_framework", fname_create + ".out")
    result2 = compare_outfiles(outfile, expected_file, logfname, fname_create, logger)

    try:
        assert result1 == True and result2 == True
        logger.info("Test Passed!")
    except AssertionError as e:
        logger.error("Test Failed!")

    close_logger(logger)

    assert result1 == True and result2 == True

if __name__ == "__main__":
    main()
