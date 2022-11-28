from sql_validation import create_logger, close_logger
import sys
import subprocess
from utils.db_client import Db_Client_pyodbc
from pathlib import Path
from utils.config import config_dict as cfg
import csv


# function to exectute the queries
def get_count(cursor, obj_type, all_query, dependent_query, expected_file, summary_file, schema):

    with open(expected_file, "a") as expected_file, open(summary_file, "a") as summary_file:

        # get csv writer
        writer = csv.writer(summary_file, delimiter = ",")

        # list all objects of type obj_type in sys schema
        cursor.execute(all_query.format(schema))
        resultset = cursor.fetchall()
        object = [l[0] for l in resultset]  

        # get user defined objects dependent on the objects
        cursor.execute(dependent_query.format(schema))

        # list of objects having dependency
        dep_object = []
        result = cursor.fetchall()

        for i in result:
            # add dependency count to summary file
            writer.writerow([obj_type, i[0], i[1]])
            dep_object.append(i[0])

        # get objects with no dependency in sorted order
        obj_no_dep = list(set(object) - set(dep_object))
        obj_no_dep.sort()
        for i in obj_no_dep:
            expected_file.write("{0} {1}\n".format(obj_type, i))


# function to pass queries to be executed
def get_dependencies(expfile, sumfile, logger):

    # connect to psql endpoint
    cnxn = Db_Client_pyodbc(cfg["provider"], cfg["fileGenerator_URL"], cfg["fileGenerator_port"], cfg["fileGenerator_databaseName"], cfg["fileGenerator_user"], cfg["fileGenerator_password"], logger)

    # check if connection is successful
    try:
        curs2 = cnxn.get_cursor()
        curs2.close()
    except Exception as e:
        logger.error(str(e))
        return False

    try: 
        cursor = cnxn.get_cursor()

        # get current engine version
        cursor.execute("show server_version;")
        version_str = cursor.fetchall()[0][0]
        version = 0

        # Sometimes version_str might contain characters so we will only parse first few numeric integers
        if '.' in version_str:
            version = float(version_str)
        else:
            for c in version_str:
                if c.isdigit():
                    version = version * 10 + int(c)
                else:
                    break

        # adding filter for information_schema_tsql based on engine version
        if version > 13.5 or version >= 14:
            schema = ", 'information_schema_tsql'::regnamespace"
        else:
            schema=''

        # creating the files
        with open(expfile, "w") as expected_file, open(sumfile, "w") as summary_file:
            writer = csv.writer(summary_file, delimiter = ",")
            writer.writerow(["Object_class", "Object_name", "dependency_count"])
            expected_file.write("Could not find dependencies on\n")

        # get user defined views,tables dependent on sys collations      
        logger.info('Finding dependencies on collations')

        # list all collations in sys schema
        all_query = "SELECT oid::regcollation FROM pg_collation WHERE collnamespace = 'sys'::regnamespace;"
       
       # get dependency count for sys collations
        dependent_query = """SELECT d.refobjid::regcollation, count(distinct v.oid) AS total_count 
                FROM pg_depend AS d 
                JOIN pg_class AS v ON v.oid = d.objid 
                WHERE d.refclassid = 'pg_collation'::regclass 
                    AND d.deptype in ('n')
                    AND d.refobjid in (SELECT oid FROM pg_collation WHERE collnamespace = 'sys'::regnamespace)
                    AND v.relnamespace NOT IN ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                GROUP BY d.refobjid;"""  
        get_count(cursor, "Collation", all_query, dependent_query, expfile, sumfile, schema)


        # get user defined objects from pg_class(views, computed columns) dependent on sys functions 
        logger.info('Finding dependencies on functions')

        # list all functions in sys and information_schema_tsql schema
        # ignoring the functions used by types and operators internally
        # included cast functions to track dependency on cast
        all_query = """SELECT oid::regprocedure FROM pg_proc WHERE prokind = 'f' AND pronamespace IN ('sys'::regnamespace{0}) AND proname NOT LIKE '\_%'
                EXCEPT     
                (   SELECT typinput::oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace 
                    UNION
                    SELECT typoutput::oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace 
                    UNION
                    SELECT typreceive::oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace 
                    UNION
                    SELECT typsend::oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace 
                    UNION
                    SELECT typmodin::oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace 
                    UNION
                    SELECT typmodout::oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace 
                    UNION
                    SELECT typanalyze::oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace 
                    UNION
                    SELECT oprcode::oid FROM pg_operator WHERE oid > 16384
                );"""

       # get dependency count for sys and information_schema_tsql functions
        dependent_query = """SELECT id::regprocedure AS obj_name, sum(total_count) as dep_count 
                FROM
                (   (   SELECT d.refobjid AS id, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_rewrite AS r ON r.oid = d.objid
                        JOIN pg_class AS v ON v.oid = r.ev_class
                        WHERE d.classid = 'pg_rewrite'::regclass
                            AND d.refclassid = 'pg_proc'::regclass 
                            AND d.deptype in('n') 
                            AND d.refobjid in (SELECT oid FROM pg_proc WHERE prokind = 'f' 
                                                AND pronamespace IN ('sys'::regnamespace{0}) 
                                                AND proname NOT LIKE '\_%')
                            AND v.relnamespace not in('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                    UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_class AS v ON v.oid = d.objid 
                        WHERE d.refclassid = 'pg_proc'::regclass 
                            AND d.deptype in ('a')
                            AND d.refobjid in (SELECT oid FROM pg_proc WHERE prokind = 'f' 
                                                AND pronamespace IN ('sys'::regnamespace{0}) 
                                                AND proname NOT LIKE '\_%')
                            AND v.relnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                ) AS temp GROUP BY id;"""
        get_count(cursor, "Function", all_query, dependent_query, expfile, sumfile, schema)


        # get user defined objects from pg_class(views, computed columns) dependent on sys operators   
        logger.info('Finding dependencies on operators')   

        # list all operators for babelfish
        # not using sys schema as some operators are created in pg_catalog schema
        # 16384 - oids assigned by postges for normal operations
        all_query = "SELECT oid::regoperator FROM pg_operator WHERE oid > 16384;"
        
        # get dependency count for operators
        dependent_query = """SELECT id::regoperator AS obj_name, sum(total_count) AS dep_count 
                FROM
                (   (   SELECT d.refobjid AS id, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_rewrite AS r ON r.oid = d.objid
                        JOIN pg_class AS v ON v.oid = r.ev_class
                        WHERE d.classid = 'pg_rewrite'::regclass
                            AND d.refclassid = 'pg_operator'::regclass 
                            AND d.deptype in('n') 
                            AND d.refobjid in (SELECT oid FROM pg_operator WHERE oid > 16384)
                            AND v.relnamespace not in('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY refobjid
                    )
                        UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_class AS v ON v.oid = d.objid 
                        WHERE d.refclassid = 'pg_operator'::regclass 
                            AND d.deptype in ('a')
                            AND d.refobjid in (SELECT oid FROM pg_operator WHERE oid > 16384)
                            AND v.relnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                ) AS temp GROUP BY id;"""     
        get_count(cursor, "Operator", all_query, dependent_query, expfile, sumfile, schema)
            
            
        # get user defined views & tables, union functions & procedures, union types dependent on sys types
        logger.info('Finding dependencies on types') 

        # list sys types
        all_query = "SELECT oid::regtype FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A' AND typname NOT LIKE '\_%';;"

        # get dependency count for sys types
        dependent_query = """SELECT id::regtype AS obj_name, sum(total_count) AS dep_count 
                FROM
                (   (   SELECT d.refobjid AS id, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_class AS v ON v.oid = d.objid 
                        WHERE d.refclassid = 'pg_type'::regclass 
                            AND d.deptype in ('n')
                            AND d.refobjid in (SELECT oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A' AND typname NOT LIKE '\_%')
                            AND v.relnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                        UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_proc AS v ON v.oid = d.objid 
                        WHERE d.refclassid = 'pg_type'::regclass 
                            AND d.deptype in ('n')
                            AND d.refobjid in (SELECT oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A' AND typname NOT LIKE '\_%')
                            AND v.pronamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                        UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_type AS v ON v.oid = d.objid 
                        WHERE d.refclassid = 'pg_type'::regclass 
                            AND d.deptype in ('n')
                            AND d.refobjid in (SELECT oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A' AND typname NOT LIKE '\_%')
                            AND v.typnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                ) AS temp GROUP BY id;"""
        get_count(cursor, "Type", all_query, dependent_query, expfile, sumfile, schema)


        # get user defined objects from pg_class(views) dependent on sys views
        logger.info('Finding dependencies on views')

        # list all babelfish system views from sys and information_schema_tsql views
        all_query = "SELECT oid::regclass FROM pg_class WHERE relkind = 'v' AND relnamespace in ('sys'::regnamespace{0});"

        # get dependency on babelfish system view
        dependent_query = """SELECT d.refobjid::regclass, count(distinct v.oid) AS total_count 
                FROM pg_depend AS d 
                JOIN pg_rewrite AS r ON r.oid = d.objid  
                JOIN pg_class AS v ON v.oid = r.ev_class 
                WHERE d.classid = 'pg_rewrite'::regclass 
                    AND d.refclassid = 'pg_class'::regclass 
                    AND d.deptype in('n') 
                    AND d.refobjid in (SELECT oid FROM pg_class WHERE relkind = 'v' AND relnamespace in ('sys'::regnamespace{0}))
                    AND v.relnamespace not in('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                GROUP BY d.refobjid; """
        get_count(cursor, "View", all_query, dependent_query, expfile, sumfile, schema)
        
        cursor.close()

        if cnxn:
            cnxn.close()

    except Exception as e:
        logger.info(str(e))    
    return True



# compare the generated and expected file using diff
def compare_outfiles(outfile, expected_file, logfname, filename, logger):
    try:
        diff_file = Path.cwd().joinpath("logs", logfname, filename + ".diff")
        f_handle = open(diff_file, "wb")

        # get diff of the files
        if sys.platform.startswith("win"):
            proc = subprocess.run(args = ["fc", expected_file, outfile], stdout = f_handle, stderr = f_handle)
        else:
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


def main():

    logfname, logger = create_logger("upgrade_validation")    
    file_name = "expected_dependency"

    # path for output file
    outfile = Path.cwd().joinpath("output", "upgrade_validation")
    Path.mkdir(outfile, parents = True, exist_ok = True)

    #summary file
    summaryfile = outfile.joinpath("dependency_summary" + ".csv")

    # output file
    outfile = outfile.joinpath(file_name + ".out")

    connect = get_dependencies(outfile, summaryfile, logger)

    # exit if can't connect to database
    try:
        assert connect == True
    except AssertionError as e:
        logger.error("Can't connect to database! Test Failed!")
        close_logger(logger)

    assert connect == True

    # get expected file based on engine version
    expected_file = Path.cwd().joinpath("expected", "upgrade_validation", file_name + ".out")

    result = compare_outfiles(outfile, expected_file, logfname, file_name, logger)

    try:
        assert result == True
        logger.info("Test Passed!")
    except AssertionError as e:
        logger.error("Test Failed!")

    close_logger(logger)

    assert result == True

if __name__ == "__main__":
    main()
