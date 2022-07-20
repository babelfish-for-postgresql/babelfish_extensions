from sql_validation import create_logger, close_logger, compare_outfiles
from utils.db_client_psql import Db_Client_psycopg
from pathlib import Path
from utils.config import config_dict as cfg
import csv


def get_dependencies(file, sumfile, logger):

    # connect to psql endpoint
    cnxn = Db_Client_psycopg(cfg["psql_URL"], cfg["psql_port"], cfg["psql_databaseName"], cfg["psql_user"], logger)

    # check if connection is successful
    try:
        curs2 = cnxn.get_cursor()
        curs2.close()
    except Exception as e:
        logger.error(str(e))
        return -1

    try: 
        cursor = cnxn.get_cursor()

        # get current engine version
        cursor.execute("show server_version;")
        version = float(cursor.fetchall()[0][0])

        # adding filter for information_schema_tsql based on engine version
        if version > 13.5:
            schema = ", 'information_schema_tsql'::regnamespace"
        else:
            schema=''

        with open(file, "w") as expected_file, open(sumfile, "w") as summary_file:

            writer = csv.writer(summary_file, delimiter = ",")
            writer.writerow(["Object_class", "Object_name", "dependency_count"])

            # get user defined objects from pg_class dependent on sys views
            logger.info('Finding dependencies on views')

            # get names of all babelfish system views
            cursor.execute("SELECT oid::regclass FROM pg_class where relkind = 'v' and relnamespace = 'sys'::regnamespace;")
            resultset = cursor.fetchall()
            object = [i[0] for i in resultset]

            query = """SELECT d.refobjid::regclass, count(distinct v.oid) AS total_count 
                FROM pg_depend AS d 
                JOIN pg_rewrite AS r ON r.oid = d.objid  
                JOIN pg_class AS v ON v.oid = r.ev_class 
                WHERE d.classid = 'pg_rewrite'::regclass 
                    AND d.refclassid = 'pg_class'::regclass 
                    AND d.deptype in('n') 
                    AND d.refobjid in (SELECT oid FROM pg_class where relkind = 'v' and relnamespace = 'sys'::regnamespace)
                    AND v.relnamespace not in('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                GROUP BY d.refobjid; """
            cursor.execute(query.format(schema))
            result = cursor.fetchall()
            dep_object = []

            # write objects with dependency count in summary file
            for i in result:
                writer.writerow(["view", i[0], i[1]])
                dep_object.append(i[0])

            # get views with no dependency 
            for i in set(object) - set(dep_object):
                expected_file.write("Could not find dependencies on view {}\n".format(i))


            # get user defined objects from pg_class dependent on sys functions 
            logger.info('Finding dependencies on functions')

            cursor.execute("SELECT oid::regprocedure FROM pg_proc where prokind = 'f' and pronamespace = 'sys'::regnamespace;")
            resultset = cursor.fetchall()
            object = [l[0] for l in resultset]

            query = """SELECT id::regprocedure AS obj_name, sum(total_count) as dep_count 
                FROM
                (   (   SELECT d.refobjid AS id, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_rewrite AS r ON r.oid = d.objid
                        JOIN pg_class AS v ON v.oid = r.ev_class
                        WHERE d.classid = 'pg_rewrite'::regclass
                            AND d.refclassid = 'pg_proc'::regclass 
                            AND d.deptype in('n') 
                            AND d.refobjid in (SELECT oid FROM pg_proc where prokind = 'f' and pronamespace = 'sys'::regnamespace)
                            AND v.relnamespace not in('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                    UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_class AS v on v.oid = d.objid 
                        WHERE d.refclassid = 'pg_proc'::regclass 
                            AND d.deptype in ('a')
                            AND d.refobjid in (SELECT oid FROM pg_proc where prokind = 'f' and pronamespace = 'sys'::regnamespace)
                            AND v.relnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                ) AS temp GROUP BY id;"""       
            cursor.execute(query.format(schema))

            dep_object = []
            result = cursor.fetchall()
            for i in result:
                writer.writerow(["function", i[0], i[1]])
                dep_object.append(i[0])

            # get functions with no dependency 
            for i in set(object) - set(dep_object):
                expected_file.write("Could not find dependencies on function {}\n".format(i))

            # get user defined views dependent on sys operators   
            logger.info('Finding dependencies on operators')   

            cursor.execute("SELECT oid::regoperator FROM pg_operator where oid > 16384;")
            resultset = cursor.fetchall()
            object = [l[0] for l in resultset]

            query = """SELECT id::regoperator AS obj_name, sum(total_count) AS dep_count 
                FROM
                (   (   SELECT d.refobjid AS id, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_rewrite AS r ON r.oid = d.objid
                        JOIN pg_class AS v ON v.oid = r.ev_class
                        WHERE d.classid = 'pg_rewrite'::regclass
                            AND d.refclassid = 'pg_operator'::regclass 
                            AND d.deptype in('n') 
                            AND d.refobjid in (SELECT oid FROM pg_operator where oid > 16384)
                            AND v.relnamespace not in('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY refobjid
                    )
                        UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_class AS v on v.oid = d.objid 
                        WHERE d.refclassid = 'pg_operator'::regclass 
                            AND d.deptype in ('a')
                            AND d.refobjid in (select oid FROM pg_operator where oid > 16384)
                            AND v.relnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                ) AS temp GROUP BY id;"""  
            cursor.execute(query.format(schema))

            dep_object = []
            result = cursor.fetchall()
            for i in result:
                writer.writerow(["operator", i[0], i[1]])
                dep_object.append(i[0])

            # get operators with no dependency 
            for i in set(object) - set(dep_object):
                expected_file.write("Could not find dependencies on operator {}\n".format(i))

            # get user defined views & tables, union functions & procedures, union types dependent on sys types
            logger.info('Finding dependencies on types') 

            cursor.execute("SELECT oid::regtype FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A';")
            resultset = cursor.fetchall()
            object = [l[0] for l in resultset]

            query = """SELECT id::regtype AS obj_name, sum(total_count) AS dep_count 
                FROM
                (   (   SELECT d.refobjid AS id, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_class AS v on v.oid = d.objid 
                        WHERE d.refclassid = 'pg_type'::regclass 
                            AND d.deptype in ('n')
                            AND d.refobjid in (SELECT oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A')
                            AND v.relnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                        UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_proc AS v on v.oid = d.objid 
                        WHERE d.refclassid = 'pg_type'::regclass 
                            AND d.deptype in ('n')
                            AND d.refobjid in (SELECT oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A')
                            AND v.pronamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                        UNION ALL
                    (   SELECT d.refobjid, count(distinct v.oid) AS total_count 
                        FROM pg_depend AS d 
                        JOIN pg_type AS v on v.oid = d.objid 
                        WHERE d.refclassid = 'pg_type'::regclass 
                            AND d.deptype in ('n')
                            AND d.refobjid in (SELECT oid FROM pg_type WHERE typnamespace = 'sys'::regnamespace AND typtype in ('b','d') AND typcategory <> 'A')
                            AND v.typnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                        GROUP BY d.refobjid
                    )
                ) AS temp GROUP BY id;"""

            cursor.execute(query.format(schema))

            dep_object = []
            result = cursor.fetchall()
            for i in result:
                writer.writerow(["type", i[0], i[1]])
                dep_object.append(i[0])

            # get type with no dependency 
            for i in set(object) - set(dep_object):
                expected_file.write("Could not find dependencies on type {}\n".format(i))


            # get user defined views,tables dependent on sys collations      
            logger.info('Finding dependencies on collations')

            cursor.execute("SELECT oid::regcollation FROM pg_collation where collnamespace = 'sys'::regnamespace;")
            resultset = cursor.fetchall()
            object = [l[0] for l in resultset]          

            query = """SELECT d.refobjid::regcollation, count(distinct v.oid) AS total_count 
                FROM pg_depend AS d 
                JOIN pg_class AS v on v.oid = d.objid 
                WHERE d.refclassid = 'pg_collation'::regclass 
                    AND d.deptype in ('n')
                    AND d.refobjid in (SELECT oid FROM pg_collation where collnamespace = 'sys'::regnamespace)
                    AND v.relnamespace not in ('sys'::regnamespace, 'pg_catalog'::regnamespace, 'information_schema'::regnamespace{0})
                GROUP BY d.refobjid;"""  
            cursor.execute(query.format(schema))
            dep_object = []
            result = cursor.fetchall()
            for i in result:
                writer.writerow(["collation", i[0], i[1]])
                dep_object.append(i[0])

            # get collations with no dependency 
            for i in set(object) - set(dep_object):
                expected_file.write("Could not find dependencies on collation {}\n".format(i))
        
        cursor.close()

        if cnxn:
            cnxn.close()

    except Exception as e:
        logger.info(str(e))
    return version


def main():

    logfname, logger = create_logger("upgrade_validation")
    
    file_name = "expected_dependency"

    # path for output file
    outfile = Path.cwd().joinpath("output", "upgrade_validation")
    Path.mkdir(outfile, parents = True, exist_ok = True)
    summaryfile = outfile.joinpath("dependency_summary" + ".csv")
    outfile = outfile.joinpath(file_name + ".out")

    version = get_dependencies(outfile, summaryfile, logger)

    try:
        assert version > 0
    except AssertionError as e:
        logger.error("Can't connect to database! Test Failed!")
        close_logger(logger)

    assert version > 0

    # get expected file based on engine version
    expected_file = Path.cwd().joinpath("expected", "upgrade_validation", str(version).replace('.','_'), file_name + ".out")

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
