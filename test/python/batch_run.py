from utils.config import config_dict as cfg
from execute_query import  parse_prepared_statement, parse_stored_procedures, process_transaction_statement,process_statement_in_file_mode,process_statement_in_file_mode_ddl
from  python_authentication import py_authentication
if cfg['runIsolationTests'] == 'true':
    from isolationtest.isolationTestHandler import isolationTestHandler
import os
from compare_results import handle_exception_in_file
from pathlib import Path
import subprocess

#categorise statements based on prefixes and accordingly process them
def batch_run(bbl_cnxn, file_handler, file, logger):
    passed = 0
    failed = 0

    filename = file.name
    f_type = filename.split(".")[1]
    
    if filename.split(".")[0][:4] == 'ddl_' and cfg['ddlExport'] == 'true':
        with open(file, "r") as f:
            sqlbatch = ""

            line = f.readline()
            while line:
                line = line.replace("\n", "")
                #ignore empty lines
                if len(line) < 1:
                    line = f.readline()
                    continue
                else:
                    if line == "--DROP":
                        dest = Path.cwd().joinpath("output",cfg["driver"], filename.split(".")[0] + ".out")
                        f_obj = open(dest, 'a')
                        work_dir = Path.cwd().joinpath("sqltoolsservice")
                        script_path = Path.cwd().joinpath("SMO_script.ps1")
                        params="?".join([cfg["fileGenerator_URL"],cfg["fileGenerator_port"],cfg["fileGenerator_databaseName"],cfg["fileGenerator_user"],cfg["fileGenerator_password"]])
                        args = []
                        args.append("pwsh -WorkingDirectory {} -File {} {}".format(work_dir,script_path,params))
                        p=subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=True,text=True)
                        p_out, p_err = p.communicate()
                        f_obj.write(p_out)

                    elif line.lower() == "go" or line.lower() == "go;":
                        flag = True
                        flag = process_statement_in_file_mode_ddl(bbl_cnxn, file_handler, sqlbatch)
                        if flag:
                            passed += 1
                        else:
                            failed += 1

                        sqlbatch = ""
                    else:
                        sqlbatch += line + os.linesep
                    line = f.readline()
    
    elif f_type == "sql":
        with open(file, "r") as f:
            
            sqlbatch = ""

            line = f.readline()
            while line:
                line = line.replace("\n", "")
                #ignore empty lines
                if len(line) < 1:
                    line = f.readline()
                    continue
                else:
                    if line.lower() == "go" or line.lower() == "go;":
                        flag = True
                        flag = process_statement_in_file_mode(bbl_cnxn, file_handler, sqlbatch, True)

                        if flag:
                            passed += 1
                        else:
                            failed += 1

                        sqlbatch = ""
                    else:
                        sqlbatch += line + os.linesep
                    line = f.readline()
    
    elif f_type == "txt":

        with open(file,"r") as f:
            lines = f.readlines()

        lines = [line.replace("\n", "") for line in lines]
        
        prep_statement = None
        trans_list = []
        for line in lines:
            flag = True
            #commented line or empty 
            if line.startswith("#") or len(line) < 1:
                file_handler.write(line)
                file_handler.write("\n")
                continue

            #run auth_test
            elif line.startswith("py_auth"):
                flag = py_authentication(file_handler, line, logger)

            #run prepared_statements
            elif line.startswith("prepst"):
                flag,prep_statement = parse_prepared_statement(bbl_cnxn, file_handler, line, prep_statement, logger)
            
            #run stored procedure
            elif line.startswith("storedproc"):
                flag = parse_stored_procedures(bbl_cnxn, file_handler, line, logger)
            
            #run the transaction statements
            elif line.startswith("txn"):
                flag,trans_list = process_transaction_statement(bbl_cnxn, line, trans_list, file_handler, logger)
            
            # skip cursor operations
            elif line.startswith("cursor"):
                flag = True
                logger.info("Skipping statement " + line + " as cursor operations are not supported currently by pyodbc/pymssql")
            
            # run as normal sql statement
            else:
                flag= process_statement_in_file_mode(bbl_cnxn, file_handler, line, False)

            if flag:
                passed += 1
            else:
                failed += 1

    elif f_type == "spec":
        flag = isolationTestHandler(file ,file_handler, logger)

    return (passed, failed)    

        
    
    
    
