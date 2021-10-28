package com.sqlsamples;

import org.apache.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import static com.sqlsamples.Config.compareWithFile;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCStatement {
    
    Statement stmt_sql;
    Statement stmt_bbl;
    
    boolean createStatements(Connection con_sql, Connection con_bbl, Logger logger) {
        
        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                stmt_sql = con_sql.createStatement();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                stmt_bbl = con_bbl.createStatement();
            } catch (SQLException e) {
                exceptionBabel = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            if (exceptionSQL && exceptionBabel) {
                logger.info("Both SQL Server and Babel threw an exception!");
                return true;
            } else if (exceptionSQL) {
                logger.info("SQL Server threw an exception but Babel did not!");
                return false;
            } else if (exceptionBabel) {
                logger.info("Babel threw an exception but SQL Server did not!");
                return false;
            } else return true;
        } else {
            try {
                stmt_bbl = con_bbl.createStatement();
            } catch (SQLException e) {
                logger.error("Could not create statement!");
            }
            
            return true;
        }
    }
    
    boolean closeStatements(Logger logger) {
        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                if (stmt_sql != null) stmt_sql.close();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                if (stmt_bbl != null) stmt_bbl.close();
            } catch (SQLException e) {
                exceptionBabel = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            if (exceptionSQL && exceptionBabel) {
                logger.info("Both SQL Server and Babel threw an exception!");
                return true;
            } else if (exceptionSQL) {
                logger.info("SQL Server threw an exception but Babel did not!");
                return false;
            } else if (exceptionBabel) {
                logger.info("Babel threw an exception but SQL Server did not!");
                return false;
            } else return true;
        } else {
            try {
                if (stmt_bbl != null) stmt_bbl.close();
            } catch (SQLException e) {
                logger.error("Could not create statement!");
            }

            return true;
        }
    }
    
    //function to execute statement and compare results
    boolean executeAndCompareStatement(String SQL, Logger logger) {
        boolean flag = true;

        boolean rs_sql_exists = false, rs_bbl_exists = false;
        boolean exceptionSQL = false, exceptionBabel = false;

        try {
            rs_sql_exists = stmt_sql.execute(SQL);
        } catch (SQLException e) {
            exceptionSQL = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        try {
            rs_bbl_exists = stmt_bbl.execute(SQL);
        } catch (SQLException e) {
            exceptionBabel = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        if (exceptionSQL && exceptionBabel) {
            logger.info("Both SQL Server and Babel threw an exception!");
            return true;
        } else if (exceptionSQL) {
            logger.info("SQL Server threw an exception but Babel did not!");
            return false;
        } else if (exceptionBabel) {
            logger.info("Babel threw an exception but SQL Server did not!");
            return false;
        }

        if (!rs_sql_exists && !rs_bbl_exists) {
            logger.info("Both servers produced no result sets");
        } else if (rs_sql_exists && !rs_bbl_exists) {
            logger.error("SQL server returned a result set but Babel did not");
            flag = false;
        } else if (!rs_sql_exists) {
            logger.error("Babel returned a result set but SQL server did not");
            flag = false;
        } else {

            ResultSet rs_sql = null;
            ResultSet rs_bbl = null;
            boolean isFirstResultSet = true;
            while (true) {
                boolean sqlDoesNextResultSetExist = false;
                boolean bblDoesNextResultSetExist = false;

                try {
                    if (!isFirstResultSet) {
                        sqlDoesNextResultSetExist = stmt_sql.getMoreResults();
                    } else sqlDoesNextResultSetExist = true;
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    if (!isFirstResultSet) {
                        bblDoesNextResultSetExist = stmt_bbl.getMoreResults();
                    } else bblDoesNextResultSetExist = true;
                } catch (SQLException e) {
                    exceptionBabel = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                if ((sqlDoesNextResultSetExist && !bblDoesNextResultSetExist)) {
                    logger.info("SQL Server has a result set but Babel does not!");
                    return false;
                } else if ((!sqlDoesNextResultSetExist && bblDoesNextResultSetExist)) {
                    logger.info("Babel has a result set but SQL Server does not!");
                    return false;
                } else if (!sqlDoesNextResultSetExist) {
                    break;
                } else {
                    try {
                        rs_sql = stmt_sql.getResultSet();
                    } catch (SQLException e) {
                        exceptionSQL = true;
                        logger.warn("SQL Exception: " + e.getMessage(), e);
                    }

                    try {
                        rs_bbl = stmt_bbl.getResultSet();
                    } catch (SQLException e) {
                        exceptionBabel = true;
                        logger.warn("SQL Exception: " + e.getMessage(), e);
                    }

                    if (exceptionSQL && exceptionBabel) {
                        logger.info("Both SQL Server and Babel threw an exception!");
                        return true;
                    } else if (exceptionSQL) {
                        logger.info("SQL Server threw an exception but Babel did not!");
                        return false;
                    } else if (exceptionBabel) {
                        logger.info("Babel threw an exception but SQL Server did not!");
                        return false;
                    }

                    //Compare the two result sets, returns true if both are same. Return false otherwise
                    if (CompareResults.compareResultSets(rs_sql, rs_bbl, logger)) {
                        logger.info("Result sets are same!");
                    } else {
                        flag = false;   //test for this query has failed, so set flag to false
                    }

                    isFirstResultSet = false;

                    batch_run.closeResultSetIfNotNull(rs_sql, logger);
                    batch_run.closeResultSetIfNotNull(rs_bbl, logger);
                }
            }
        }

        return flag;
    }

    //function to write output of executed statement to a file if compareWithFile mode is used
    //executes statement and compares results of server with file otherwise
    boolean testStatementWithFile(String SQL, BufferedWriter bw, String strLine){
        try {
            if (compareWithFile) {
                bw.write(strLine);
                bw.newLine();

                boolean resultSetExist = false;
                int resultsProcessed = 0;
                try {
                    resultSetExist = stmt_bbl.execute(SQL);
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw);
                    resultsProcessed++;
                }
                CompareResults.processResults(stmt_bbl, bw, resultsProcessed, resultSetExist);
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return true;
    }
}
