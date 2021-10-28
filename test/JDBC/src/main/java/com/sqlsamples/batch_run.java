package com.sqlsamples;

import org.apache.log4j.Logger;

import java.io.*;
import java.sql.*;
import java.util.*;

import static java.util.Objects.isNull;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.Statistics.exec_times;

public class batch_run {

    //method that iterates through an SQL batch and compares their result sets(if any) only.
    //returns true if all statement comparisons pass. returns false otherwise
    public static ArrayList<Integer> batch_run_sql(Connection con_sql, Connection con_bbl, BufferedWriter bw, String testFilePath, Logger logger) {

        ArrayList<Integer> comparisonResults = parse_and_compare(con_sql, con_bbl, bw, testFilePath, logger);

        logger.info("###########################################################################");
        logSummaryResults(logger, comparisonResults);

        return comparisonResults;
    }

    private static void logSummaryResults(Logger logger, ArrayList<Integer> comparisonResults) {
        logger.info("###########################################################################");
        logger.info("################################  SUMMARY  ################################");
        logger.info("###########################################################################");
        logger.info("STATEMENTS TESTED:\t" + (comparisonResults.get(0)+comparisonResults.get(1)));
        logger.info("TESTS PASSED:\t\t" + comparisonResults.get(0));
        logger.info("TESTS FAILED:\t\t" + comparisonResults.get(1));
        logger.info("###########################################################################");
    }

    //helper method that parses a testFile and compares result sets if any
    //Returns a tuple with number of statements that passed and failed
    private static ArrayList<Integer> parse_and_compare(Connection con_sql, Connection con_bbl, BufferedWriter bw, String testFilePath, Logger logger) {

        boolean isSQLFile = testFilePath.contains(".sql");
        boolean isCrossDialectFile = false;
        boolean tsqlDialect = false;
        boolean psqlDialect = false;

        if (testFilePath.contains(".mix")) {
            isCrossDialectFile = true;
            isSQLFile = true;		//we want to treat GO as a batch separator in this case
        }

        //initializing objects
        JDBCAuthentication jdbcAuthentication = new JDBCAuthentication();
        JDBCCallableStatement jdbcCallableStatement = new JDBCCallableStatement();
        JDBCCursor jdbcCursor = new JDBCCursor();
        JDBCPreparedStatement jdbcPreparedStatement = new JDBCPreparedStatement();
        JDBCStatement jdbcStatement = new JDBCStatement();
        JDBCTransaction jdbcTransaction = new JDBCTransaction();
        JDBCCrossDialect jdbcCrossDialect = null;

        if (isCrossDialectFile)
            jdbcCrossDialect = new JDBCCrossDialect(con_bbl);

        int passed = 0;
        int failed = 0;

        try {
            String SQL;                 //holds the SQL statement
            StringBuilder sqlBatch = new StringBuilder();
            String strLine;             //holds the current line which is getting executed
            FileInputStream fstream;    //stream of input file with the SQL batch queries to be tested
            DataInputStream in;
            BufferedReader br;

            fstream = new FileInputStream(testFilePath);
            //get the object of DataInputStream
            in = new DataInputStream(fstream);
            br = new BufferedReader(new InputStreamReader(in));

            //each iteration will process one line(SQL statement) from input file and compare result sets from SQL server and Babel instance
            while ((strLine = br.readLine()) != null) {
                logger.info("###########################################################################");

                boolean flag = true;    //flag represents whether test passed (1) or failed (0)
                //if line has no characters, or is commented out, or is a dotnet auth statement, proceed to next line
                if (strLine.length() < 1 || strLine.startsWith("#") || strLine.startsWith("dotnet_auth")) {
                    if (strLine.length() < 1 || strLine.startsWith("#")) {
                        if (compareWithFile) {
                            bw.write(strLine);
                            bw.newLine();
                        }
                    }
                    continue;
                }

                long startTime = System.nanoTime();

                //if line starts with keyword "prepst", it means it is either a prep exec statement or an exec statement
                if (strLine.startsWith("prepst")) {

                    // Convert .NET input file format for prepared statement to JDBC
                    strLine = strLine.replaceAll("@[a-zA-Z0-9]+", "?");

                    String[] result;
                    //split wrt delimiter
                    result = strLine.split("#!#");
                    //if an exec statement, set bind variables and execute query
                    if ((result[1].startsWith("exec")) || (result[1].startsWith("call"))) {

                        StringBuilder params = new StringBuilder();
                        //populate params with bind variables' types and values (used for logging only)
                        for (int i = 2; i < result.length; i++) {
                            params.append(result[i]);
                            if (i < result.length - 1) params.append(", ");
                        }

                        logger.info("Executing an already prepared statement with the following bind variables: " + params.toString());
                        if (compareWithFile) {
                            flag = jdbcPreparedStatement.testPreparedStatementWithFile(result, bw, strLine, logger);
                        } else {
                            flag = jdbcPreparedStatement.executeAndComparePreparedStatement(result, logger);
                        }

                    } else if (!result[1].equals("exec")) {

                        flag = jdbcPreparedStatement.closePreparedStatements(logger);

                        SQL = result[1];
                        logger.info("Preparing the query: " + SQL);

                        StringBuilder params = new StringBuilder();

                        for (int i = 2; i < result.length; i++) {
                            params.append(result[i]);
                            if (i < result.length - 1) params.append(", ");
                        }

                        if (flag) {
                            flag = jdbcPreparedStatement.createPreparedStatements(con_sql, con_bbl, SQL, logger);
                        }

                        logger.info("Executing with the bind variables " + params.toString());

                        if (flag) {
                            if (compareWithFile) {
                                flag = jdbcPreparedStatement.testPreparedStatementWithFile(result, bw, strLine, logger);
                            } else {
                                flag = jdbcPreparedStatement.executeAndComparePreparedStatement(result, logger);
                            }
                        }
                    }
                    
                    //if line starts with keyword "storedproc", it means it is a stored procedure
                } else if (strLine.startsWith("storedproc")) {
                    
                    String[] result = strLine.split("#!#");
                    
                    if (result[1].startsWith("prep")) {

                        //close existing callable statements
                        flag = jdbcCallableStatement.closeCallableStatements(logger);
                            
                        SQL = result[2];
                        StringBuilder bindparam = new StringBuilder();
                            
                        for ( int i = 0; i <= result.length - 4; i++) {
                            if (i == 0) {
                                bindparam.append("(");
                            } 
                            
                            if (i != result.length - 4) {
                                bindparam.append("?,");
                            } else {
                                bindparam.append("?)");
                            }
                        }

                        // Convert .NET input file format for callable statement to JDBC
                        SQL = "{ call " + SQL + bindparam + " }";
                        
                        logger.info("Preparing and executing call: " + SQL);

                        if (flag) {
                            flag = jdbcCallableStatement.createCallableStatements(con_sql, con_bbl, SQL, logger);
                        }
                        
                        if(flag) {
                            if (compareWithFile) {
                                flag = jdbcCallableStatement.testCallableStatementWithFile(result, bw, strLine, logger);
                            } else {
                                flag = jdbcCallableStatement.executeAndCompareCallableStatement(result, logger);
                            }
                        }
                    } else {

                        logger.info("Executing an already prepared call");

                        if (compareWithFile) {
                            flag = jdbcCallableStatement.testCallableStatementWithFile(result, bw, strLine, logger);
                        } else {
                            flag = jdbcCallableStatement.executeAndCompareCallableStatement(result, logger);
                        }
                    }

                    //if line starts with keyword "txn", it means it is a transaction
                } else if (strLine.startsWith("txn")) {
                    String[] result = strLine.split("#!#");

                    if(compareWithFile){
                        bw.write(strLine);
                        bw.newLine();
                    }

                    if (result[1].toLowerCase().startsWith("begin")) {
                        flag = jdbcTransaction.beginTransaction(con_sql, con_bbl, bw, logger);
                    } else if (result[1].toLowerCase().startsWith("commit")) {
                        flag = jdbcTransaction.transactionCommit(con_sql, con_bbl, bw, logger);
                    } else if (result[1].toLowerCase().startsWith("rollback")) {
                        if (result.length < 3 || result[2].length() == 0 || result[2].matches("[ \\t]+")) {
                            flag = jdbcTransaction.transactionRollback(con_sql, con_bbl, bw, logger);
                        } else {
                            //rolling back to a named savepoint
                            flag = jdbcTransaction.transactionRollbackToSavepoint(con_sql, con_bbl, result, bw, logger);
                        }
                    } else if (result[1].toLowerCase().startsWith("savepoint")) {
                        if (result.length < 3 || result[2].length() == 0 || result[2].matches("[ \\t]+")) {
                            flag = jdbcTransaction.setTransactionSavepoint(con_sql, con_bbl, bw, logger);
                        } else {
                            flag = jdbcTransaction.setTransactionNamedSavepoint(con_sql, con_bbl, result, bw, logger);
                        }
                    } else if (result[1].toLowerCase().startsWith("isolation")) {
                        flag = jdbcTransaction.setTransactionIsolationLevel(con_sql, con_bbl, result, logger);
                    } else {
                        logger.warn("Unrecognized Transaction! Either statement syntax is " +
                                "invalid or the test suite does not handle this query at the time");
                        flag = false;
                    }
                    //assuming transactions don't return a result set
                    if (compareWithFile) {
                        bw.write("~~SUCCESS~~");
                        bw.newLine();
                    }
                    
                    //if line starts with keyword "cursor", it means it is a cursor operation
                } else if (strLine.startsWith("cursor")) {

                    // Convert .NET input file format for prepared statement to JDBC
                    // Used if cursor opened on a result set from a prepared statement
                    if (strLine.contains("prepst")) {
                        strLine = strLine.replaceAll("@[a-zA-Z0-9]+", "?");
                    }

                    String[] result = strLine.split("#!#");

                    if (compareWithFile) {
                        bw.write(strLine);
                        bw.newLine();
                    }

                    if (result[1].toLowerCase().startsWith("open")) {
                        flag = jdbcCursor.openCursor(con_sql, con_bbl, logger, result, strLine, bw);

                    } else if (result[1].toLowerCase().startsWith("fetch")) {
                        flag = jdbcCursor.cursorFetch(bw, logger, result);
                    } else if (result[1].toLowerCase().startsWith("close")) {
                        flag = jdbcCursor.cursorClose(bw, logger);
                    } else {
                        logger.warn("Unrecognized Cursor action! Either statement syntax is " +
                                "invalid or the test suite does not handle this action at the time");
                        flag = false;
                    }

                } else if (strLine.startsWith("java_auth")) {
                    flag = jdbcAuthentication.javaAuthentication(strLine, bw, logger);

                } else if (strLine.startsWith("include") && !isSQLFile) {
                    String[] result = strLine.split("#!#");
                    String filePath = new File(result[1]).getAbsolutePath();

                    //Run the iterative parse and compare loop for test file
                    parse_and_compare(con_sql, con_bbl, bw, filePath, logger);

                } else if (isCrossDialectFile && (  (tsqlDialect = strLine.toLowerCase().startsWith("-- tsql")) ||
                                                    (psqlDialect = strLine.toLowerCase().startsWith("-- psql")))) {
                    //Cross dialect testing

                    bw.write(strLine);
                    bw.newLine();

                    /*
                     * If tsql/psql connection with given username exists, reuse it.
                     * Else, create a new tsql/psql connection with that username and
                     * assign it to existing connection object.
                     */
                    if (tsqlDialect) {
                        con_bbl = jdbcCrossDialect.getTsqlConnection(strLine);
                    } else if (psqlDialect) {
                        con_bbl = jdbcCrossDialect.getPsqlConnection(strLine);
                    }

                    //Ensure connection object is not null
                    assert(con_bbl != null);

                } else {
                    // execute statement as a normal SQL statement
                    if (isSQLFile) {
                        //strLine = strLine.trim();
                        if (!strLine.equalsIgnoreCase("GO")) {
                            sqlBatch.append(strLine).append(System.lineSeparator());
                            continue;
                        } else {
                            SQL = sqlBatch.toString();
                            sqlBatch = new StringBuilder();
                            if (compareWithFile) {
                                bw.write(SQL);
                                //bw.newLine();
                            }
                        }
                    } else {
                        SQL = strLine;
                    }
                    
                    logger.info("Executing: " + SQL);

                    flag = jdbcStatement.closeStatements(logger);
                    
                    if (flag) {
                        flag = jdbcStatement.createStatements(con_sql, con_bbl, logger);
                    }
                    
                    if (flag) {
                        if (compareWithFile) {
                            flag = jdbcStatement.testStatementWithFile(SQL, bw, strLine);
                        } else {
                            flag = jdbcStatement.executeAndCompareStatement(SQL, logger);
                        }
                    }
                }

                //increment number of queries processed and determine whether test for query failed or passed. Log info accordingly
                if (flag) {
                    passed++;
                    logger.info("Test passed!");
                } else {
                    failed++;
                    logger.info("Test failed!");
                }

                long endTime = System.nanoTime();
                long duration = (endTime - startTime);
                exec_times.add(duration);
            }
        } catch (IOException ioe) {
            logger.warn("IO Exception: " + ioe.getMessage(), ioe);
            ioe.printStackTrace();
        }
        
        //close existing statements if any
        jdbcStatement.closeStatements(logger);
        jdbcPreparedStatement.closePreparedStatements(logger);
        jdbcCallableStatement.closeCallableStatements(logger);

        //close connection used for cross dialect queries
        if (jdbcCrossDialect != null)
            jdbcCrossDialect.closeConnections();

        ArrayList<Integer> comparisonResults = new ArrayList<>();
        comparisonResults.add(passed);
        comparisonResults.add(failed);

        return comparisonResults;
    }

    //method to close any existing result sets
    static void closeResultSetIfNotNull(ResultSet rs, Logger logger){
        if (rs != null) {
            try {
                rs.close();
            } catch (Exception e) {
                logger.warn(e.getMessage());
            }
        }
    }
}
