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
    for f in path.glob(filefilter):
        files.append(f)
    return files


# extract object_name and object_type from line
def get_object(line):
    newline = line.lower()
    if "(" in newline:
        newline = newline.split('(')[0]

    newline = newline.rstrip(';')
    linewords = newline.split()

    # list of object types
    object_types = ['table', 'view', 'function', 'procedure', 'role', 'aggregate', 'schema', 'domain', 'collation', 'index', 'type', 'operator', 'cast', 'family', 'class']
                            
    # setting default object type as object
    obj_type = 'object'
    
    # if object type is operator, check if it is operator, operator class or operator family
    # by looking at the next word in line
    for i in range(len(linewords)):
        if linewords[i] in object_types:
            obj_type = linewords[i]
            if linewords[i] == 'operator' and i+1<len(linewords):
                if linewords[i+1] in object_types:
                    obj_type = obj_type + ' ' + linewords[i+1]
            break

    # list of syntax words
    syntax_words = ['drop', 'create', 'view', 'procedure', 'function', 'table', 'domain', 
            'index', 'schema', 'temporary', 'aggregate', 'cascade', 'if', 'exists', 'owned', 
            'class', 'operator', 'cast', 'family', 'type', 'using', 'alter', 
            'by', 'role', 'as', 'or', 'replace', 'collation', 'not', 'select']
                            
    # creating list of line words that are not present in syntax words
    resultwords  = [word for word in linewords if word not in syntax_words]

    # no object_name for cast
    if obj_type == 'cast':
        obj_name = ''
    # the first word will give the object_name
    else:
        obj_name = resultwords[0]
    return obj_type, obj_name


# search for patterns in the upgrade scripts
def find_pattern(pattern, fname, logger):
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

                    # if pattern is found
                    elif readflag == True and re.search(pattern, line, re.I):

                        # get object_type and object name from line
                        obj_type, obj_name = get_object(line)

                        # add to output file
                        expected_file.write("Unexpected {0} found for {1} {2} in file {3}\n".format(re.sub("[^a-zA-Z0-9 ]", "", pattern), obj_type, obj_name, filename.name))
                    
                    # enable or disable the readflag (flag to ignore the body of procedures)
                    # at max $$ can be present twice in a line
                    # if $$ present twice, we dont change the readflag
                    if len(re.findall(r"[$]{2}", line, re.I)) == 1:
                        readflag = not readflag
                        
                    line = file.readline()
    logger.info("Searching {0} statements completed successfully!".format(re.sub("[^a-zA-Z0-9 ]", "", pattern)))



# search for create statements and return a set of tuple (object_type, object_name)
def find_pattern_create(scripts, logger):

    # set to avoid searching for redundant object names
    object_names = set()
    
    logger.info("Searching created objects!!")
    
    # getting list of object types to be searched from config for babelfishpg_tsql extension
    pattern_tsql = r"^create [\w\s]*\b({0})\b".format(cfg["createObjectSearch"].replace(',', '|'))
    
    # searching only for type and domain in babelfishpg_common extension
    pattern_com = r"^create [\w\s]*\b(type|domain)\b"

    # looping through all the scripts
    for filename in scripts:
        with  open(filename, "r") as file:
            line = file.readline()

            # get pattern based on extension
            if re.search("babelfishpg_common",str(filename)):
                pattern = pattern_com
            else:
                pattern = pattern_tsql

            # flag for ignoring body of procedure
            readflag = True
            while line:
                line = line.strip()
                
                # ignoring comments in the script
                if line.startswith("--") or line.startswith("/*") or line.startswith("#"):
                    line = file.readline()
                    continue

                # if pattern is found
                elif readflag == True and re.search(pattern, line, re.I):

                     # get object_type and object name from line
                    obj_type, obj_name = get_object(line)

                    # adding bracket at the end of regex for functions
                    # such that func(, func ( and func  ( are considered valid
                    if obj_type == 'function':
                        obj_name += r"\s{0,2}[(]"

                    # ignoring helper functions (having ._ )
                    if not re.search("[.]_", obj_name, re.I):
                        object_names.add((obj_type, obj_name))

                # enable or disable the readflag (flag to ignore the body of procedures)
                # at max $$ can be present twice in a line
                # if $$ present twice, don't change the readflag
                if len(re.findall(r"[$]{2}", line, re.I)) == 1:
                    readflag = not readflag    
                line = file.readline()
                
    logger.info("Found all create objects successfully!")
    return object_names


# find if given object_name exists in the files passed by a list
def find_obj(files, obj_name):
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
                elif(re.search( obj_name, testline, re.I)):
                    return True
                testline = testfile.readline()
    return False


# find the object name in the test files
def find_in_testfiles(type, searchinfiles, object_names, f_path, logger):

    with open(f_path, "a") as expected_file:
        for object in object_names:

            # flag for object name found or not in the JDBC input files
            flag = False
            object_name = object[1]

            # replacing . as in regex it means any character
            if "." in object[1]:
                object_name = object[1].replace(".", "[.]")

            if "information_schema_tsql" in object[1]:
                object_name = object[1].replace("information_schema_tsql", "information_schema")

            # adding word boundary if object is not a function
            if not object[0] == 'function':
                object_name = object_name + r"\b"

            flag = find_obj(searchinfiles, r"\b" + object_name)

            # searching again without schema name for objects in all schemas
            if(flag == False and "." in object[1]):
                object_name = r"\b(?<![.])" + object_name.split(".]")[-1]
                
                # creating pattern to identify @@func calls
                if object[0] == 'function':
                    object_name = "(" + "@@" + object_name.replace("\s{0,2}[(]", "").replace("\\b", "") + ")|(" +  object_name + ")"
                
                flag = find_obj(searchinfiles, object_name)
            
            # if tests not found, add it to output file
            if flag == False:
                expected_file.write("Could not find {0}tests for {1} {2}\n".format(type, object[0], object[1].split('\s')[0]))
    logger.info("{}Tests for objects found successfully!".format(type))


# creates list of all files to be searched for upgrade test
def list_upgrade_files():
    upgrade_files = []

    inpPath = "../JDBC/upgrade"

    # searching prepare and verify scripts in upgrade directory
    update_files = list_files(inpPath, "**/*[-][v][u][-]*.*")
    upgrade_files.extend(update_files)

    # list all schedule files
    sch_files = list_files(inpPath, "**/schedule")

    # create a set of test files to be looked into JDBC input
    search_tests = set()
    for filename in sch_files:
        with  open(filename, "r") as file:
            line = file.readline()

            while line:
                line = line.strip()

                # ignoring comments and empty lines in the schedule file
                if line.startswith("ignore") or line.startswith("#") or line.startswith("cmd") or line.startswith("all") or line.startswith("$") or not line:
                    line = file.readline()
                    continue

                search_tests.add(line)
                line = file.readline()

    # search prepare and verify scripts for the test file
    path=Path("../JDBC/input")
    for test in search_tests:
        for i in path.rglob("*.*"):
            if re.search(test + "-vu-*.*", str(i)):
                upgrade_files.append(i)

    return upgrade_files


# initialize and find tests for JDBC and upgrade framework
def find_tests(fname, logger):
    # set output file path
    path = Path.cwd().joinpath("output", "sql_validation_framework")
    Path.mkdir(path, parents = True, exist_ok = True)
    f_path = path.joinpath(fname + ".out")

    f = open(f_path,"w")
    f.close()

    # getting installation scripts for babelfish_tsql extension
    inpPath = "../../contrib/babelfishpg_tsql/sql"
    inst_scripts = list_files(inpPath, "*.sql")

    # removing scripts having helper functions and redundant script
    for i in inst_scripts:
        if re.search("sys_function_helpers.sql", str(i)):
            inst_scripts.remove(Path(inpPath).joinpath("sys_function_helpers.sql"))
        if re.search("babelfishpg_tsql--1.0.0.sql", str(i)):
            inst_scripts.remove(Path(inpPath).joinpath("babelfishpg_tsql--1.0.0.sql"))
    
    # getting installation scripts for babelfish_common extension
    inpPath = "../../contrib/babelfishpg_common/sql"
    inst_scripts.extend(list_files(inpPath, "*.sql"))
    
    # removing redundant script
    for i in inst_scripts:
        if re.search("babelfishpg_common--1.0.0.sql", str(i)):
            inst_scripts.remove(Path(inpPath).joinpath("babelfishpg_common--1.0.0.sql"))

    # get the set of create object_name for installation scripts
    object_names_inst = find_pattern_create(inst_scripts, logger)

    # get the list of JDBC/input files
    all_files = list_files("../JDBC/input", "**/*.*")

    # search for objects in the JDBC input files
    find_in_testfiles("", all_files, object_names_inst, f_path, logger)

    # get list of prepare and verify scripts in schedule and upgrade directory
    upgrade_files = list_upgrade_files()

    # search for objects in upgrade test files
    find_in_testfiles("upgrade ", upgrade_files, object_names_inst, f_path, logger)


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
        find_pattern(pattern, filename, logger)
        
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
        diff_file = Path.cwd().joinpath("logs", logfname, filename + ".diff")
        f_handle = open(diff_file, "wb")

        # sorting the files as set will give unordered outputs
        if sys.platform.startswith("win"):
            subprocess.run(args = ["sort", expected_file, "/o", expected_file])
            subprocess.run(args = ["sort", outfile, "/o", outfile])
            proc = subprocess.run(args = ["fc", expected_file, outfile], stdout = f_handle, stderr = f_handle)
        else:
            subprocess.run(args = ["sort", "-o", expected_file, expected_file])
            subprocess.run(args = ["sort", "-o", outfile, outfile])
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
def create_logger(filename):

    # set up path for logger
    log_folder_name = datetime.now().strftime('log_%H_%M_%d_%m_%Y')
    path = Path.cwd().joinpath("logs", log_folder_name)
    Path.mkdir(path, parents = True, exist_ok = True)

    logname = datetime.now().strftime(filename + '_%H_%M_%d_%m_%Y.log')

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
    
    logfname, logger = create_logger("sql_validation")

    result1 = find_patterns(logfname, logger)

    find_tests(fname_create, logger)
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
