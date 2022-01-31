import re
import pyodbc
from compare_results import handle_exception_in_file, process_multiple_resultsets
from datetime import date, datetime, time
from decimal import Decimal
from uuid import UUID
from xml.dom.minidom import parseString
from utils.config import config_dict as cfg
from utils.base import handle_babel_exception

#based on the keyword process the given prefixes set or simply execute the prepared statements
def parse_prepared_statement(bbl_cnxn, file_writer, query, prep_statement, logger):
    

    if cfg["driver"] == "pyodbc":
        query = re.sub(r"@[a-zA-Z0-9]+", "?", query)
    elif cfg["driver"] == "pymssql":
        query = re.sub(r"@[a-zA-Z0-9]+", "%s", query)
    
    result = query.split("#!#")

    keyword = result[1]

    #use already initialised prepared statement
    if keyword.startswith("exec"):
        params = []

        for i in range(2, len(result)):
            params.append(result[i])
            if i < len(result) - 1:
                params.append(", ")

        logger.info("Executing prepared statement " + repr(prep_statement) + " with the following bind variables: " + "".join(params))
        
        flag = process_prepared_statement_in_file_mode(bbl_cnxn, file_writer, query, prep_statement, result, logger)
    
    elif not keyword.startswith("exec"):
        prep_statement = result[1]
        logger.info("Preparing the query: " + repr(prep_statement))

        params = []

        for i in range(2, len(result)):
            params.append(result[i])
            if i < len(result) - 1:
                params.append(", ")
        
        logger.info("Executing with the bind variables " + "".join(params))
        
        flag = process_prepared_statement_in_file_mode(bbl_cnxn, file_writer, query, prep_statement, result, logger)

    return (flag, prep_statement)

#TODO add more data types
# parse the prefixes and return tuple of bind values
def set_bind_values(result, logger):
    inttype = ["int", "smallint", "tinyint", "bigint"]
    floattype = ["real", "float"]
    bytestype = ["binary", "varbinary"]
    strtype = ["string", "char", "nchar", "varchar", "nvarchar"]
    booltype = ["boolean", "bit"]
    datetype = ["date"]
    datetimetype = ["datetime", "datetime2", "smalldatetime"]
    decimaltype = ["decimal", "numeric", "money", "smallmoney"]
    uuidtype = ["uniqueidentifier"]
    timetype = ["time"]
    xmltype = ["xml"]
    texttype = ["text", "ntext"]

    lst = []


    if result[0] == "storedproc":
        start=3
    elif result[0] == "prepst":
        start=2

    for i in range(start, len(result)):
        params = result[i].split("|-|")
        if len(params) < 2:
            continue
        try:
            if "<NULL>" in params[2]:
                lst.append(None)
            elif params[0].lower() in floattype:
                lst.append(float(params[2]))
            elif params[0].lower() in inttype:
                if "." in params[2]:
                    lst.append(int(float(params[2])))
                else:
                    lst.append(int(params[2]))
            elif params[0].lower() in bytestype:
                lst.append(params[2].encode())
            elif params[0].lower() in strtype:
                lst.append(str(params[2]))
            elif params[0].lower() in booltype:
                if "false" in params[2].lower():
                    lst.append(False)
                else:
                    lst.append(True)
            elif params[0].lower() in datetype:
                lst.append(date.fromisoformat(params[2].strip()))
            elif params[0].lower() in datetimetype:
                try:
                    lst.append(datetime.strptime(params[2].strip(), "%Y-%m-%d %H:%M:%S.%f"))
                except ValueError as e:
                    lst.append(datetime.strptime(params[2].strip(), "%Y-%m-%d %H:%M:%S"))
            elif params[0].lower() in decimaltype:
                lst.append(Decimal(params[2].replace("$", "").replace(",", "").strip()))
            elif params[0].lower() in uuidtype:
                lst.append(UUID(params[2].strip()))
            elif params[0].lower() in timetype:
                dt_obj = datetime.strptime(params[2].strip(), "%H:%M:%S.%f")
                time_obj = time(hour = dt_obj.hour, minute = dt_obj.minute, second = dt_obj.second, microsecond = dt_obj.microsecond)
                lst.append(time_obj)
            elif params[0].lower() in xmltype:
                dom = parseString(params[2].strip())
                lst.append(dom.toxml())
            elif params[0].lower() in texttype:
                with open(params[2].strip(), "r") as f:
                    data = f.read()
                    lst.append(data)
                
            else:    
                raise Exception("Data type " + params[0] + " is not supportted currently")
        except Exception as e:
            logger.error(str(e))
    
    return tuple(lst)

#function to parse the prefixes and ignore the cases that are not supported
def parse_stored_procedures(bbl_cnxn, file_writer, query, logger):
    flag = True

    result=query.split("#!#")
    
    lst=["output", "inputoutput", "return"]
    #skipping cases as not supported by pyodbc/pymssql yet
    if any(word in query for word in lst):
        logger.info("Skipping statement " + repr(query) + " as out/inout/return parameters are not supported currently by pyodbc")
        return True

    bindparam = ""

    for i in range(0, len(result)-3):
        if i != len(result)-4:
            bindparam+="?,"
        else:
            bindparam+="?"

    values = set_bind_values(result, logger)
    
    if len(values)<1:
        stored_proc = "exec " + result[2]
    else:
        stored_proc = "exec " + result[2]+ " " + bindparam
 
    logger.info("Executing stored procedure " + repr(stored_proc) + " with the following input parameters: " + str(values))
    flag = process_stored_procedure_in_file_mode(bbl_cnxn, file_writer, query, stored_proc, values)

    return flag

#function to begin,rollback,commit transactions , set savepoints
def process_transaction_statement(bbl_cnxn, query, trans_list,file_writer, logger):
    flag = True
    result = query.split("#!#")

    #begin transaction
    if result[1].startswith("begin"):
        logger.info("Beginning Transaction")

        #if the statement has isolation prefixes as well
        if len(result) > 2:
            #isolation prefixes only supported in pyodbc
            if result[2].startswith("isolation") and cfg["driver"] == "pyodbc":
                #append name to transaction list if given in the statement
                if len(result) > 4:
                    tran_name = result[4]
                    trans_list.append(tran_name)
                
                #if-elif ladder to set the transaction isolation level
                if result[3] == "ru":
                    logger.info("Transaction isolation level set to TRANSACTION_READ_UNCOMMITTED")

                    try:
                        bbl_cnxn.set_isolation(pyodbc.SQL_TXN_READ_UNCOMMITTED)
                    except Exception as e: 
                        handle_babel_exception(e, logger)

                elif result[3] == "rc":
                    logger.info("Transaction isolation level set to SQL_TXN_READ_COMMITTED")

                    try:
                        bbl_cnxn.set_isolation( pyodbc.SQL_TXN_READ_COMMITTED)
                    except Exception as e: 
                        handle_babel_exception(e, logger)

                elif result[3] == "rr":
                    logger.info("Transaction isolation level set to SQL_TXN_REPEATABLE_READ")

                    try:
                        bbl_cnxn.set_isolation( pyodbc.SQL_TXN_REPEATABLE_READ)
                    except Exception as e: 
                        handle_babel_exception(e, logger)

                elif result[3] == "se":
                    logger.info("Transaction isolation level set to SQL_TXN_SERIALIZABLE")

                    try:
                        bbl_cnxn.set_isolation(pyodbc.SQL_TXN_SERIALIZABLE)
                    except Exception as e: 
                        handle_babel_exception(e, logger)
                
                #use sqlbatch to set snapshot isolation as not supported by pyodbc
                elif result[3] == "ss":
                    logger.info("Transaction isolation level set to Snapshot")
                    flag = process_statement_in_file_mode(bbl_cnxn, file_writer, "SET TRANSACTION ISOLATION LEVEL SNAPSHOT", False)
            #if no isolation prefix add the transaction name to the list
            else:
                trans_list.append(result[2])

        #set autocommit to false to start the transaction
        try:
            bbl_cnxn.set_autocommit(False)
        except Exception as e: 
            handle_exception_in_file(e, file_writer)

    #commit transaction          
    elif result[1].startswith("commit"):
        logger.info("Committing transaction")

        #if the transaction list not empty pop the first element 
        if len(trans_list) > 0:
            trans_list.pop()
        
        try:
            bbl_cnxn.commit()
            bbl_cnxn.set_autocommit(True)
        except Exception as e:
            handle_exception_in_file(e, file_writer)

    #rollback transaction
    elif result[1].startswith("rollback"):
        #if the rollback statement exist with transaction name or simply without any name
        if len(result) < 3 or result[2] in trans_list:
            
            logger.info("Rolling back the transaction")
            #try to pop the transaction name from the list if it exist in the list
            try:
                if result[2] in trans_list:
                    trans_list.pop()
            except:
                pass
            
            try:
                bbl_cnxn.rollback()
                bbl_cnxn.set_autocommit(True)
            except Exception as e:
                handle_exception_in_file(e, file_writer)
        
        #else rollback to savepoint 
        else:

            logger.info("Rolling back to savepoint" + result[2])
            #using sql batch as the pyodbc/pymssql doesnt have methods for rolling back to savepoint
            flag = process_statement_in_file_mode(bbl_cnxn, file_writer, "rollback tran " + result[2], False)
        
    elif result[1].startswith("savepoint"):
        #using sql batch as the pyodbc/pymssql doesnt have methods for setting savepoint
        flag = process_statement_in_file_mode(bbl_cnxn, file_writer, "save tran " + result[2], False)
    
    return (flag, trans_list)

#function to generate output files for sqlbatch statements
def process_statement_in_file_mode(bbl_cnxn, file_writer, query, is_sql_batch):
    try:
        
        #different formatting for sqlbatch and single sql statement
        if is_sql_batch:
            file_writer.write(query)
            file_writer.write("GO")
            file_writer.write("\n")
        else:
            file_writer.write(query)
            file_writer.write("\n")

        result_set_exist = True
        result_processed = 0

        try:
            bbl_cursor = bbl_cnxn.get_cursor()
            bbl_cursor.execute(query)
            result_set_exist = bbl_cursor.description
        except Exception as e:
            handle_exception_in_file(e, file_writer)
            result_processed += 1

        process_multiple_resultsets(bbl_cursor, file_writer, result_processed, result_set_exist)

        try:
            bbl_cursor.close()
        except Exception as e:
            print(str(e))
    
    except Exception as e:
        
        print(str(e)) 

    return True

#function to generate output files for prepared statements
def process_prepared_statement_in_file_mode(bbl_cnxn, file_writer, query, prep_statement, result, logger):
    try:
        
        file_writer.write(query)
        file_writer.write("\n")

        values=set_bind_values(result, logger)

        result_set_exist = True
        result_processed = 0

        try:
            bbl_cursor = bbl_cnxn.get_cursor()
            bbl_cursor.execute(prep_statement, values)
            result_set_exist = bbl_cursor.description

        except Exception as e:
            handle_exception_in_file(e, file_writer)
            result_processed += 1

        process_multiple_resultsets(bbl_cursor, file_writer, result_processed, result_set_exist)

        try:
            bbl_cursor.close()
        except Exception as e:
            print(str(e))


    except Exception as e:
        print(str(e))
    
    return True

#function to generate output files for stored procedures
def process_stored_procedure_in_file_mode(bbl_cnxn, file_writer, query, stored_proc, values):
    try:
        
        file_writer.write(query)
        file_writer.write("\n")

        result_set_exist = True
        result_processed = 0

        try:
            bbl_cursor = bbl_cnxn.get_cursor()
            bbl_cursor.execute(stored_proc, values)
            result_set_exist = bbl_cursor.description

        except Exception as e:
            handle_exception_in_file(e, file_writer)
            result_processed += 1

        process_multiple_resultsets(bbl_cursor, file_writer, result_processed, result_set_exist)

        try:
            bbl_cursor.close()
        except Exception as e:
            print(str(e))
        
    except Exception as e:
        print(str(e))
    
    return True 

         