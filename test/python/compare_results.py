#compare result sets using simple assertions

import re
import pymssql
import pyodbc
from utils.config import config_dict as cfg


#function to write output of sql query to a file
def write_results_to_file(file_writer, bbl_data, bbl_rs):
    try:
        file_writer.write("~~START~~")
        file_writer.write("\n")

        metadata = bbl_rs.description
        columns = len(metadata)

        if cfg["outputColumnName"] == "true":
            for i in range(columns):
                file_writer.write(metadata[i][0])
                if i != (columns -1):
                    file_writer.write("#!#")
            
            file_writer.write("\n")

        
        for i in range(columns):
            if cfg["driver"] == "pyodbc":
                file_writer.write(metadata[i][1].__name__)
            elif cfg["driver"] == "pymssql":
                file_writer.write(type(metadata[i][1]).__name__)

            if i != (columns - 1):
                file_writer.write("#!#")
        
        file_writer.write("\n")

        for i in range(len(bbl_data)):
            for j in range(columns):
                if bbl_data[i][j] is None:
                    file_writer.write("<NULL>")
                else:
                    str_data = str(bbl_data[i][j])
                    str_data = re.sub("[\r\n]+", "<newline>",str_data)
                    file_writer.write(str_data)
                
                if j != (columns - 1):
                    file_writer.write("#!#")
            
            file_writer.write("\n")
        
        file_writer.write("~~END~~")
        file_writer.write("\n")
        file_writer.write("\n")


    except (IOError, OSError) as e:
        print(str(e))

    except Exception as e:
        handle_exception_in_file(e, file_writer)

#function to handle exception
def handle_exception_in_file(e, file_writer):
    try:
        if cfg["outputErrorCode"] == "true":
            if issubclass(type(e), pyodbc.Error):
                code = re.findall(r"\(\d+\)", e.args[1])
                if len(code) > 0:
                    ecode = code[0][1:-1] 
                    file_writer.write("~~ERROR (Code: " + str(ecode) + ")~~")
                    file_writer.write("\n")
                
                file_writer.write("~~ERROR (Message: "+ e.args[1] + ")~~")
            
            elif issubclass(type(e), pymssql.Error):
                
                file_writer.write("~~ERROR (Code: " + str(e.args[0]) + ")~~")
                file_writer.write("\n")
                file_writer.write("~~ERROR (Message: " + repr(str(e.args[1].decode())) + ")~~")
            
            file_writer.write("\n")
            file_writer.write("\n")
        else:
            file_writer.write("~~ERROR~~")
            file_writer.write("\n")
            file_writer.write("\n")
        
    except Exception as err:
        print(str(err)) 
    
#processes all the result sets sequentially that we get from executing a sql query
def process_multiple_resultsets(bbl_rs, file_writer, result_processed, result_set_exist):
    #not possible initial value
    count = -10

    while True:
        
        exception_raised = True

        while exception_raised:
            try:
                if result_processed > 0:
                    result_set_exist = bbl_rs.nextset()
                
                exception_raised = False
                count = bbl_rs.rowcount

            except Exception as e:
                handle_exception_in_file(e, file_writer)
            
            result_processed += 1

        
        if not result_set_exist and count == -1 and cfg["driver"] == "pyodbc":
            break        
        
        
        if result_set_exist:
            try:
                bbl_data = bbl_rs.fetchall()
                write_results_to_file(file_writer, bbl_data, bbl_rs)
            except Exception as e:
                handle_exception_in_file(e, file_writer)
        else:
            if count > 0:
                try:
                    file_writer.write("~~ROW COUNT: " + str(count) + "~~")
                    file_writer.write("\n")
                    file_writer.write("\n")
                except Exception as e:
                    print(str(e)) 
        
        if not result_set_exist and cfg["driver"] == "pymssql":
            break
        

        

