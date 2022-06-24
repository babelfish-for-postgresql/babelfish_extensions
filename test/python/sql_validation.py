from datetime import datetime
import logging
import re
from pathlib import Path
import subprocess
from utils.config import config_dict as cfg



#list of installation and upgrade scripts
def list_scripts_drop():
    inpPath="../../contrib"
    path=Path(inpPath)
    scripts=[]

    for f in path.glob("*/sql/upgrades/*.sql"):
        scripts.append(f)

    # path=path.joinpath("upgrades")
    # for f in path.glob("*.sql"):
    #     # print(f)
    #     scripts.append(f)
    return scripts


def find_pattern_drop(fname,logger):
    path = Path.cwd().joinpath("output", "Sql_validation_framework")
    Path.mkdir(path, parents = True, exist_ok = True)
    f_path = path.joinpath(fname+".out")
    logger.info("Running tests for unexpected drop statements !")
    with open(f_path, "w") as expected_file:
        scripts=list_scripts_drop()
        pattern=r"^drop "

        for filename in scripts:
            with  open(filename, "r") as file:
  
                line = file.readline()

                readflag=True
                while line:
                    line=line.strip()
                    if line.startswith("--") or line.startswith("/*") or line.startswith("#"):
                        line=file.readline()
                        continue
                    elif readflag==True:
                        match_f=re.search(pattern,line,re.I)
                        if match_f:
                            # print(filename)
                            # print(line)
                            newline=line
                            if "(" in newline:
                                newline=newline.split('(')[0]
                                # print(line)

                            newline=newline.rstrip(';')
                            if "using" in newline.lower():
                                newline=newline.lower().split('using')[0]

                            linewords=newline.split()
                            object_category=['table','view','function','procedure','role','class','operator','cast']
                            category='object'
                            for word in linewords:
                                if word.lower() in object_category:
                                    category=word.lower()
                                    break
                            if category=='class':
                                category='operator class'
                            
                            stopwords = ['drop','create','view','procedure','function','view','table','cascade','if','exists','owned','by','role','as','or','replace','class','operator','cast']
                            resultwords  = [word for word in linewords if word.lower() not in stopwords]
                            obj_name = ' '.join(resultwords)
                            # print("result : ",obj_name)
                            expected_file.write("Unexpected drop found for {0} {1} in file {2}\n".format(category,obj_name,filename))
                    if len(re.findall(r"[$]{2}",line,re.I)) == 1:
                        readflag=not readflag
                    line=file.readline()
    logger.info("Tests for drop statements completed successfully!!")




#------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##For JDBC tests 

#list of installation and upgrade scripts
def list_scripts_create():
    inpPath="../../contrib/babelfishpg_tsql/sql"
    path=Path(inpPath)

    scripts=[]

    for f in path.glob("*.sql"):
        # print(f)
        scripts.append(f)

    path=path.joinpath("upgrades")
    for f in path.glob("*.sql"):
        # print(f)
        scripts.append(f)

    #Removing helper functions
    scripts.remove(Path(inpPath+"/sys_function_helpers.sql"))
    return scripts


#List of files in JDBC framework
def list_files(inpPath):
    path=Path(inpPath)

    files=[]

    for f in path.rglob("*.*"):
        #print(f)
        files.append(f)
    return files



def find_pattern_create(logger):
    scripts=list_scripts_create()
    object_names=set()
    
    logger.info("Running tests for create statements !")
    
    pat=r"^create [\w\s]*\b({0})\b".format(cfg["createObjectSearch"].replace(',','|'))
    for filename in scripts:
        with  open(filename, "r") as file:

            # print(filename)
            line = file.readline()

            readflag=True
            while line:
                line=line.strip()
                if line.startswith("--") or line.startswith("/*") or line.startswith("#"):
                    line=file.readline()
                    continue
                elif readflag==True:
                    match_f=re.search(pat,line,re.I)
                    if match_f:
                        # print(line)
                        newline=line
                        if "(" in newline:
                            newline=newline.split('(')[0]+"[(]"
                        
                        # if " as " in line.lower():
                        #     line=line.lower().split(' as ')[0]
                        # if " ON " in line:
                        #     line=line.split(' ON ')[0]
                            # print(line)

                        newline=newline.rstrip(';')
                        linewords=newline.split()
                        object_category=['table','view','function','procedure','role','aggregate','schema','domain','collation','index']
                        category='object'
                        for word in linewords:
                            if word.lower() in object_category:
                                category=word.lower()
                        stopwords = ['drop','create','view','procedure','function','table','domain',
                                    'index','schema','temporary','aggregate','cascade','if','exists','owned',
                                    'by','role','as','or','replace','collation','not','select']
                        resultwords  = [word for word in linewords if word.lower() not in stopwords]
                        obj_name = ' '.join(resultwords)

                        # print("word to be searched : ",obj_name.lower())

                        object_names.add((category,obj_name))
                if len(re.findall(r"[$]{2}",line,re.I)) == 1:
                    readflag=not readflag    
                line=file.readline()
                
    # print(object_names)
    logger.info("Found all create objects successfully!")
    return object_names


def find_inp_JDBC(fname,logger):
    files=list_files("../JDBC/input")
    object_name=find_pattern_create(logger)
    path = Path.cwd().joinpath("output", "Sql_validation_framework")
    Path.mkdir(path, parents = True, exist_ok = True)
    f_path = path.joinpath(fname+".out")
    with open(f_path, "w") as expected_file:
        for object in object_name:

            #Flag for object name found or not in the JDBC input files
            flag=False
            # print(object[1])
            for i in files:
                with open(i, "r") as testfile:
                    testline=testfile.readline()

                    while testline:
                        testline=testline.strip()
                        if testline.startswith("--") or testline.startswith("/*") or testline.startswith("#"):
                            testline=testfile.readline()
                            continue

                        elif(re.search(r"\b"+object[1]+r"\b",testline,re.I)):
                            flag=True
                            # print("Found\nline :   ",testline)
                            # print("file name : ",i)
                            break
                        testline=testfile.readline()
                    else:
                        continue
                    break

            if(flag==False and "sys." in object[1]):
                result_wo_sys=object[1].split('.',maxsplit=2)[1]

                for i in files:
                    with open(i, "r") as testfile:
                        testline=testfile.readline()
                                
                        while testline:
                            testline=testline.strip()
                            if testline.startswith("--") or testline.startswith("/*") or testline.startswith("#"):
                                testline=testfile.readline()
                                continue

                            elif(re.search(r"\b"+result_wo_sys+r"\b", testline,re.I)):
                                flag=True
                                # print("Found\nline :   ",testline)
                                # print("file name : ",i)
                                break
                            testline=testfile.readline()
                        else:
                            continue
                        break
            if flag==False:
                expected_file.write("Could not find tests for {0} {1}\n".format(object[0],object[1].split('[')[0]))
    logger.info("Tests for create statements completed successfully!!")


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##For any search


def find_patterns(logger):
    files=list_files("../../contrib/babelfishpg_tsql/sql/upgrades")
    
    path = Path.cwd().joinpath("output", "Sql_validation_framework")
    Path.mkdir(path, parents = True, exist_ok = True)
    f_path = path.joinpath("Pattern_match_results.out")
    
    logger.info("Running random pattern search!!")
    
    with open(f_path, "w") as expected_file:
        patterns=cfg["searchPatterns"].split(',')

        for pattern in patterns:
            # pattern = r"{0}".format(pattern)
            # pattern="query\d"
            # print(pattern)
            expected_file.write("Pattern : {0} \n".format(pattern))
            for filename in files:
                with  open(filename, "r") as file:
  
                    # print(cfg["pattern"])
                    # pat=cfg["pattern"].strip("'")

                    line = file.readline()

                    while line:
                        match_f=re.findall(pattern,line,re.I)
                        if match_f:
                            # print(line)
                            expected_file.write("{0} \n".format(line))
                        line=file.readline()
    logger.info("Patterns found successfully!!")


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Main function,  logs and output file comparisons


def compare_outfiles(outfile, expected_file, logfname, filename, logger):
    try:
        diff_file = Path.cwd().joinpath("logs", logfname, "sql_validation", filename + ".diff")
        f_handle = open(diff_file, "wb")

        proc_sort = subprocess.run(args = ["sort", "-o", expected_file, expected_file])
        proc_sort = subprocess.run(args = ["sort", "-o", outfile, outfile])

        proc = subprocess.run(args = ["diff", "-a", "-u", "-I", "~~ERROR",expected_file, outfile], stdout = f_handle, stderr = f_handle)
        
        rcode = proc.returncode
        f_handle.close()
        
        if rcode == 0:
            logger.info("No difference found!")
            return True
        elif rcode ==  1:
            with open(diff_file,"r") as f:
                print(f.read())
            return False
        elif rcode == 2:
            with open(diff_file,"r") as f:
                print(f.read())
            logger.error("Some error occured while executing the diff command!")
            return False
        else:
            logger.error("Unknown exit code encountered while running diff!")
            return False
        
    except Exception as e:
        logger.error(str(e))
    
    return False




def create_logger():
    log_folder_name = datetime.now().strftime('log_%H_%M_%d_%m_%Y')
    path = Path.cwd().joinpath("logs", log_folder_name)
    Path.mkdir(path, parents = True, exist_ok = True)

    filename="sql_validation"
    logname = datetime.now().strftime(filename + '_%H_%M_%d_%m_%Y.log')

    path = Path.cwd().joinpath("logs", log_folder_name,filename)
    Path.mkdir(path, parents = True, exist_ok = True)

    #Creating logger with two handlers, file as well as console
    #File logger
    file_path=path.joinpath(logname)

    fh = logging.FileHandler(filename = file_path, mode = "w")
    formatter = logging.Formatter('%(asctime)s-%(levelname)s-%(message)s')
    fh.setFormatter(formatter)
    logger = logging.getLogger(filename)
    logger.addHandler(fh)
    logger.setLevel(logging.DEBUG)

    #console logger
    sh = logging.StreamHandler()
    sh.setFormatter(formatter)
    logger.addHandler(sh)
    logger.setLevel(logging.DEBUG)

    return log_folder_name ,logger


def close_logger(logger):
    if logger is None:
        return
    else:
        for handler in list(logger.handlers):
            logger.removeHandler(handler) 
            handler.close()

def main():

    fname_drop="Expected_drop"
    fname_create="Expected_create"

    logfname,logger=create_logger()

    find_pattern_drop(fname_drop, logger)
    expected_file=Path.cwd().joinpath("expected", "Sql_validation_framework",fname_drop+".out")
    outfile=Path.cwd().joinpath("output", "Sql_validation_framework",fname_drop+".out")
    result1=compare_outfiles(outfile, expected_file, logfname,fname_drop,logger)
    
    find_inp_JDBC(fname_create, logger)
    expected_file=Path.cwd().joinpath("expected", "Sql_validation_framework",fname_create+".out")
    outfile=Path.cwd().joinpath("output", "Sql_validation_framework",fname_create+".out")
    result2=compare_outfiles(outfile, expected_file, logfname, fname_create,logger)

    find_patterns(logger)
    close_logger(logger)

    assert result1 == 0 and result2 == 0, "Test Passed"

if __name__=="__main__":
    main()
