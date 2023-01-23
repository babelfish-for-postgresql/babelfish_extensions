package com.sqlsamples;

import org.apache.logging.log4j.Logger;

import java.io.*;
import java.sql.*;
import java.util.*;

import static java.util.Objects.isNull;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.Statistics.exec_times;
import static com.sqlsamples.Statistics.curr_exec_time;
import static com.sqlsamples.Statistics.sla;

public class batch_run {

    // method that iterates through an input file and writes output to corresponding .out file.
    static void batch_run_sql(Connection con_bbl, BufferedWriter bw, String testFilePath, Logger logger) {

        boolean isSQLFile = testFilePath.contains(".sql");
        boolean isCrossDialectFile = false;
        boolean tsqlDialect = false;
        boolean psqlDialect = false;
        boolean customSLA = false;

        if (testFilePath.contains(".mix")) {
            isCrossDialectFile = true;
            isSQLFile = true;		        // we want to treat GO as a batch separator in this case
        }

        // initializing objects
        JDBCAuthentication jdbcAuthentication = new JDBCAuthentication();
        JDBCCallableStatement jdbcCallableStatement = new JDBCCallableStatement();
        JDBCCursor jdbcCursor = new JDBCCursor();
        JDBCPreparedStatement jdbcPreparedStatement = new JDBCPreparedStatement();
        JDBCStatement jdbcStatement = new JDBCStatement();
        JDBCTransaction jdbcTransaction = new JDBCTransaction();
        JDBCCrossDialect jdbcCrossDialect = null;
        JDBCBulkCopy jdbcBulkCopy = new JDBCBulkCopy();

        if (isCrossDialectFile)
            jdbcCrossDialect = new JDBCCrossDialect(con_bbl);

        int passed = 0;
        int failed = 0;

        try {
            String SQL;                 // holds the SQL statement
            StringBuilder sqlBatch = new StringBuilder();
            String strLine;             // holds the current line which is getting executed
            FileInputStream fstream;    // stream of input file with the SQL batch queries to be tested
            DataInputStream in;
            BufferedReader br;

            fstream = new FileInputStream(testFilePath);
            // get the object of DataInputStream
            in = new DataInputStream(fstream);
            br = new BufferedReader(new InputStreamReader(in));

            // each iteration will process one line(SQL statement) from input file and compare result sets from SQL server and Babel instance
            while ((strLine = br.readLine()) != null) {
                // if line has no characters, or is commented out, or is a dotnet auth statement, proceed to next line
                if (strLine.length() < 1 || strLine.startsWith("#") || strLine.startsWith("dotnet_auth")) {
                    if (strLine.length() < 1 || strLine.startsWith("#")) {
                        bw.write(strLine);
                        bw.newLine();
                    }
                    continue;
                }
                long startTime = System.nanoTime();

                // if line starts with keyword "prepst", it means it is either a prep exec statement or an exec statement
                if (strLine.startsWith("prepst")) {
                    // Convert .NET input file format for prepared statement to JDBC
                    strLine = strLine.replaceAll("@[a-zA-Z0-9]+", "?");

                    String[] result;
                    // split wrt delimiter
                    result = strLine.split("#!#");
                    // if an exec statement, set bind variables and execute query
                    if ((result[1].startsWith("exec")) || (result[1].startsWith("call"))) {

                        StringBuilder params = new StringBuilder();
                        // populate params with bind variables' types and values (used for logging only)
                        for (int i = 2; i < result.length; i++) {
                            params.append(result[i]);
                            if (i < result.length - 1) params.append(", ");
                        }

                        logger.info("Executing an already prepared statement with the following bind variables: " + params.toString());
                        jdbcPreparedStatement.testPreparedStatementWithFile(result, bw, strLine, logger);

                    } else if (!result[1].equals("exec")) {
                        jdbcPreparedStatement.closePreparedStatements(bw, logger);

                        SQL = result[1];
                        logger.info("Preparing the query: " + SQL);

                        StringBuilder params = new StringBuilder();

                        for (int i = 2; i < result.length; i++) {
                            params.append(result[i]);
                            if (i < result.length - 1) params.append(", ");
                        }

                        jdbcPreparedStatement.createPreparedStatements(con_bbl, SQL, bw, logger);

                        logger.info("Executing with the bind variables " + params.toString());

                        jdbcPreparedStatement.testPreparedStatementWithFile(result, bw, strLine, logger);
                    }
                    
                // if line starts with keyword "storedproc", it means it is a stored procedure
                } else if (strLine.startsWith("storedproc")) {
                    
                    String[] result = strLine.split("#!#");
                    
                    if (result[1].startsWith("prep")) {

                        // close existing callable statements
                        jdbcCallableStatement.closeCallableStatements(bw, logger);
                            
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

                        jdbcCallableStatement.createCallableStatements(con_bbl, SQL, bw, logger);
                        jdbcCallableStatement.testCallableStatementWithFile(result, bw, strLine, logger);

                    } else {

                        logger.info("Executing an already prepared call");
                        jdbcCallableStatement.testCallableStatementWithFile(result, bw, strLine, logger);
                    }

                // if line starts with keyword "txn", it means it is a transaction
                } else if (strLine.startsWith("txn")) {
                    String[] result = strLine.split("#!#");

                    bw.write(strLine);
                    bw.newLine();

                    if (result[1].toLowerCase().startsWith("begin")) {
                        jdbcTransaction.beginTransaction(con_bbl, bw, logger);
                    } else if (result[1].toLowerCase().startsWith("commit")) {
                        jdbcTransaction.transactionCommit(con_bbl, bw, logger);
                    } else if (result[1].toLowerCase().startsWith("rollback")) {
                        if (result.length < 3 || result[2].length() == 0 || result[2].matches("[ \\t]+")) {
                            jdbcTransaction.transactionRollback(con_bbl, bw, logger);
                        } else {
                            // rolling back to a named savepoint
                            jdbcTransaction.transactionRollbackToSavepoint(con_bbl, result, bw, logger);
                        }
                    } else if (result[1].toLowerCase().startsWith("savepoint")) {
                        if (result.length < 3 || result[2].length() == 0 || result[2].matches("[ \\t]+")) {
                            jdbcTransaction.setTransactionSavepoint(con_bbl, bw, logger);
                        } else {
                            jdbcTransaction.setTransactionNamedSavepoint(con_bbl, result, bw, logger);
                        }
                    } else if (result[1].toLowerCase().startsWith("isolation")) {
                        jdbcTransaction.setTransactionIsolationLevel(con_bbl, result, bw, logger);
                    } else {
                        logger.error("Unrecognized Transaction! Either statement syntax is " +
                                "invalid or the test suite does not handle this query at the time");
                    }
                    // assuming transactions don't return a result set
                    bw.write("~~SUCCESS~~");
                    bw.newLine();
                    
                // if line starts with keyword "cursor", it means it is a cursor operation
                } else if (strLine.startsWith("cursor")) {
                    // Convert .NET input file format for prepared statement to JDBC
                    // Used if cursor opened on a result set from a prepared statement
                    if (strLine.contains("prepst")) {
                        strLine = strLine.replaceAll("@[a-zA-Z0-9]+", "?");
                    }

                    String[] result = strLine.split("#!#");

                    bw.write(strLine);
                    bw.newLine();

                    if (result[1].toLowerCase().startsWith("open")) {
                        jdbcCursor.openCursor(con_bbl, logger, result, strLine, bw);

                    } else if (result[1].toLowerCase().startsWith("fetch")) {
                        jdbcCursor.cursorFetch(bw, logger, result);
                    } else if (result[1].toLowerCase().startsWith("close")) {
                        jdbcCursor.cursorClose(bw, logger);
                    } else {
                        logger.error("Unrecognized Cursor action! Either statement syntax is " +
                                "invalid or the test suite does not handle this action at the time");
                    }

                } else if (strLine.startsWith("java_auth")) {
                    jdbcAuthentication.javaAuthentication(strLine, bw, logger);

                } else if (strLine.startsWith("include") && !isSQLFile) {
                    String[] result = strLine.split("#!#");
                    String filePath = new File(result[1]).getAbsolutePath();

                    // Run the iterative parse and compare loop for test file
                    batch_run_sql(con_bbl, bw, filePath, logger);

                } else if (strLine.startsWith("insertbulk")) {
                    bw.write(strLine);
                    bw.newLine();

                    String[] result = strLine.split("#!#");
                    String sourceTable = result[1];
                    String destinationTable = result[2];
                    jdbcBulkCopy.executeInsertBulk(con_bbl, destinationTable, sourceTable, logger, bw);

                } else if (isCrossDialectFile && (  (tsqlDialect = strLine.toLowerCase().startsWith("-- tsql")) ||
                                                    (psqlDialect = strLine.toLowerCase().startsWith("-- psql")))) {
                    // Cross dialect testing

                    Connection connection = null;

                    bw.write(strLine);
                    bw.newLine();

                    /*
                     * If tsql/psql connection with given username exists, reuse it.
                     * Else, create a new tsql/psql connection with that username and
                     * assign it to existing connection object.
                     */
                    if (tsqlDialect) {
                        connection = jdbcCrossDialect.getTsqlConnection(strLine, bw, logger);
                    } else if (psqlDialect) {
                        connection = jdbcCrossDialect.getPsqlConnection(strLine, bw, logger);
                    }

                    // Ensure con_bbl is never null
                    if (connection != null) con_bbl = connection;

                } else if (isCrossDialectFile && ( (tsqlDialect = strLine.toLowerCase().startsWith("-- terminate-tsql-conn")) ||
                                                    (psqlDialect = strLine.toLowerCase().startsWith("-- terminate-psql-conn")))) {

                    bw.write(strLine);
                    bw.newLine();

                    if (tsqlDialect) {
                        jdbcCrossDialect.terminateTsqlConnection(strLine, bw, logger);
                    } else if (psqlDialect) {
                        jdbcCrossDialect.terminatePsqlConnection(strLine, bw, logger);
                    }
                } else {
                    customSLA = strLine.toLowerCase().startsWith("-- sla");
                    // execute statement as a normal SQL statement
                    if (isSQLFile) {
                        if (customSLA){
                            String[] tokens=strLine.split(" ");  
                            sla = Long.parseLong(tokens[2]);
                            sla = sla*(1000000L);
                            continue;
                        }
                        else if (!strLine.equalsIgnoreCase("GO")) {
                            sqlBatch.append(strLine).append(System.lineSeparator());
                            continue;
                        } else {
                            SQL = sqlBatch.toString();
                            sqlBatch = new StringBuilder();
                            bw.write(SQL);
                        }
                    } else {
                        SQL = strLine;
                    }
                    
                    logger.info("Executing: " + SQL);

                    jdbcStatement.closeStatements(bw, logger);
                    jdbcStatement.createStatements(con_bbl, bw, logger);
                    jdbcStatement.testStatementWithFile(SQL, bw, strLine, logger);
                }
                long endTime = System.nanoTime();
                long duration = (endTime - startTime);
                exec_times.add(duration);
                curr_exec_time += duration;
            }
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
        
        // close existing statements if any
        jdbcStatement.closeStatements(bw, logger);
        jdbcPreparedStatement.closePreparedStatements(bw, logger);
        jdbcCallableStatement.closeCallableStatements(bw, logger);

        // close connection used for cross dialect queries
        if (jdbcCrossDialect != null)
            jdbcCrossDialect.closeConnections(bw, logger);
    }
}
