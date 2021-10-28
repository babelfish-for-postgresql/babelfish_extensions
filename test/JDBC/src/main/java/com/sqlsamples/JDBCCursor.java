package com.sqlsamples;

import org.apache.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import static com.sqlsamples.Config.compareWithFile;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCCursor {
    
    ResultSet cursor_sql;
    ResultSet cursor_bbl;
    PreparedStatement pstmt_sql;
    PreparedStatement pstmt_bbl;
    
    int[] setCursorOptions(int i, String[] result, Logger logger) {
        int type = ResultSet.TYPE_FORWARD_ONLY;
        int concur = ResultSet.CONCUR_READ_ONLY;
        int holdability = 0;

        for(; i < result.length; i++) {
            if (result[i].equalsIgnoreCase("TYPE_FORWARD_ONLY")) {
                logger.info("Setting cursor type: forward-only");
                type = ResultSet.TYPE_FORWARD_ONLY;
            } else if (result[i].equalsIgnoreCase("TYPE_SCROLL_SENSITIVE")) {
                logger.info("Setting cursor type: scroll sensitive");
                type = ResultSet.TYPE_SCROLL_SENSITIVE;
            } else if (result[i].equalsIgnoreCase("TYPE_SCROLL_INSENSITIVE")) {
                logger.info("Setting cursor type: scroll insensitive");
                type = ResultSet.TYPE_SCROLL_INSENSITIVE;
            } else if (result[i].equalsIgnoreCase("CONCUR_READ_ONLY")) {
                logger.info("Setting cursor concurrency: read-only");
                concur = ResultSet.CONCUR_READ_ONLY;
            } else if (result[i].equalsIgnoreCase("CONCUR_UPDATABLE")) {
                logger.info("Setting cursor concurrency: updatable");
                concur = ResultSet.CONCUR_UPDATABLE;
            } else if (result[i].equalsIgnoreCase("HOLD_CURSORS_OVER_COMMIT")) {
                logger.info("Setting cursor holdability: hold cursors over commit");
                holdability = ResultSet.HOLD_CURSORS_OVER_COMMIT;
            } else if (result[i].equalsIgnoreCase("CLOSE_CURSORS_AT_COMMIT")) {
                logger.info("Setting cursor holdability: close cursors at commit");
                holdability = ResultSet.CLOSE_CURSORS_AT_COMMIT;
            } else {
                logger.error("Invalid Cursor attribute!");
            }
        }
        
        return new int[]{type, concur, holdability};
    }
    
    boolean openCursor(Connection con_sql, Connection con_bbl, Logger logger, String[] result, String strLine, BufferedWriter bw) {
        logger.info("Opening Cursor");
        
        if (result[2].toLowerCase().startsWith("prepst")) {
            return openCursorOnPreparedStatement(con_sql, con_bbl, logger, result, bw);
        } else {
            return openCursorOnStatement(con_sql, con_bbl, bw, logger, result);
        }
    }
    
    boolean openCursorOnPreparedStatement(Connection con_sql, Connection con_bbl, Logger logger, String[] result, BufferedWriter bw) {
        // array with prepared statement relevant contents
        List<String> contents = new ArrayList<>();
        contents.add(result[2]);
        contents.add(result[3]);
        
        int i;

        // while the result array contains prepared statement relevant delimiter
        // add those array elements to contents' list
        for (i = 4; i < result.length && result[i].contains("|-|"); i++) {
            contents.add(result[i]);
        }

        String[] contentsArray = contents.toArray(new String[0]);

        //set cursor options
        int[] cursorOptions = setCursorOptions(i, result, logger);
        int type = cursorOptions[0];
        int concur = cursorOptions[1];
        int holdability = cursorOptions[2];

        String SQL = contentsArray[1];
        
        if(!compareWithFile) {

            boolean exceptionSQL = false, exceptionBabel = false;
            
            if (holdability != 0) {
                
                try {
                    con_sql.setHoldability(holdability);
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }
                
                try {
                    con_bbl.setHoldability(holdability);
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
            }

            if (!result[3].toLowerCase().startsWith("exec")) {
                //if it is not an prepare and execute statement, close 
                //existing prepared statements and prepare SQL query mentioned
                try {
                    if (pstmt_sql != null)
                        pstmt_sql.close();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    if (pstmt_bbl != null)
                        pstmt_bbl.close();
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

                try {
                    pstmt_sql = con_sql.prepareStatement(SQL, type, concur);
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }
                
                try {
                    pstmt_bbl = con_bbl.prepareStatement(SQL, type, concur);
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
            }

            JDBCPreparedStatement.set_bind_values(contentsArray, pstmt_sql, logger);
            JDBCPreparedStatement.set_bind_values(contentsArray, pstmt_bbl, logger);

            try {
                cursor_sql = pstmt_sql.executeQuery();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                cursor_bbl = pstmt_bbl.executeQuery();
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
                con_bbl.setHoldability(holdability);
                if (!result[3].toLowerCase().startsWith("exec")) {
                    if (pstmt_bbl != null) pstmt_bbl.close();
                    pstmt_bbl = con_bbl.prepareStatement(SQL, type, concur);
                }

                JDBCPreparedStatement.set_bind_values(contentsArray, pstmt_bbl, logger);
                cursor_bbl = pstmt_bbl.executeQuery();
                bw.write("~~SUCCESS~~");
                bw.newLine();
                return true;
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }

	return true;
    }

    boolean openCursorOnStatement(Connection con_sql, Connection con_bbl, BufferedWriter bw, Logger logger, String[] result) {
        //set cursor options
        int[] cursorOptions = setCursorOptions(3, result, logger);
        int type = cursorOptions[0];
        int concur = cursorOptions[1];
        int holdability = cursorOptions[2];

        String SQL = result[2];
        Statement stmt_sql = null, stmt_bbl = null;
        
        if(!compareWithFile) {
            if (holdability != 0) {
                
                boolean exceptionSQL = false, exceptionBabel = false;

                try {
                    con_sql.setHoldability(holdability);
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }
                
                try {
                    con_bbl.setHoldability(holdability);
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

                try {
                    stmt_sql = con_sql.createStatement(type, concur);
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }


                try {
                    stmt_bbl = con_bbl.createStatement(type, concur);
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
                
                try {
                    cursor_sql = stmt_sql.executeQuery(SQL);
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }
                
                try {
                    cursor_bbl = stmt_bbl.executeQuery(SQL);
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
            }
        } else {
            try {
                con_bbl.setHoldability(holdability);
                stmt_bbl = con_bbl.createStatement(type, concur);
                cursor_bbl = stmt_bbl.executeQuery(SQL);
                bw.write("~~SUCCESS~~");
                bw.newLine();
                return true;
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }
        
        return true;
    }
    
    boolean cursorFetch(BufferedWriter bw, Logger logger, String[] result) {
        
        if(!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            if (cursor_bbl == null) {
                if (cursor_sql == null) {
                    logger.info("Both cursors pointing to null result sets!");
                    return true;
                } else {
                    logger.warn("Cursor in Babel is pointing to a null result set. Cursor in SQL server is not!");
                    return false;
                }
            } else if (cursor_sql == null) {
                logger.warn("Cursor in SQL is pointing to a null result set. Cursor in Babel server is not!");
                return false;
            } else if (result[2].toLowerCase().startsWith("beforefirst")) {
                logger.info("Moving cursor just before the first row");

                try {
                    cursor_sql.beforeFirst();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    cursor_bbl.beforeFirst();
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

                boolean sqlIsBeforeFirst = false, babelIsBeforeFirst = false;
                
                try {
                    sqlIsBeforeFirst = cursor_sql.isBeforeFirst();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }
                
                try {
                    babelIsBeforeFirst = cursor_bbl.isBeforeFirst();
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
                } else {
                    return CompareResults.cursorPositionAssert(sqlIsBeforeFirst, babelIsBeforeFirst, logger,
                            "One of the cursors is not just before the first row!");
                }
            } else if (result[2].toLowerCase().startsWith("afterlast")) {
                logger.info("Moving cursor just after the last row");

                try {
                    cursor_sql.afterLast();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }
                
                try {
                    cursor_bbl.afterLast();
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
                    
                boolean sqlIsAfterLast = false, babelIsAfterLast = false;

                try {
                    sqlIsAfterLast = cursor_sql.isAfterLast();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    babelIsAfterLast = cursor_bbl.isAfterLast();
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
                } else {
                    return CompareResults.cursorPositionAssert(sqlIsAfterLast, babelIsAfterLast, logger,
                            "One of the cursors is not just after the last row!");
                }
            } else if (result[2].toLowerCase().startsWith("first")) {
                logger.info("Moving cursor to the first row");
                
                boolean sqlIsValidRow = false, babelIsValidRow = false;

                try {
                    sqlIsValidRow = cursor_sql.first();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    babelIsValidRow = cursor_bbl.first();
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

                if (CompareResults.cursorPositionAssert(sqlIsValidRow, babelIsValidRow, logger, "One of the ResultSets is empty!")) {

                    boolean sqlIsFirstRow = false, babelIsFirstRow = false;

                    try {
                        sqlIsFirstRow = cursor_sql.isFirst();
                    } catch (SQLException e) {
                        exceptionSQL = true;
                        logger.warn("SQL Exception: " + e.getMessage(), e);
                    }

                    try {
                        babelIsFirstRow = cursor_bbl.isFirst();
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
                    } else {
                        return CompareResults.cursorPositionAssert(sqlIsFirstRow, babelIsFirstRow, logger,
                                "One of the cursors is not at the last row!");
                    }
                }
            } else if (result[2].toLowerCase().startsWith("last")) {
                logger.info("Moving cursor to the last row");
                
                boolean sqlIsValidRow = false, babelIsValidRow = false;
                
                try {
                    sqlIsValidRow = cursor_sql.last();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    babelIsValidRow = cursor_bbl.last();
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
                
                if (CompareResults.cursorPositionAssert(sqlIsValidRow, babelIsValidRow, logger, "One of the ResultSets is empty!")) {
                    boolean sqlIsLastRow = false, babelIsLastRow = false;

                    try {
                        sqlIsLastRow = cursor_sql.isLast();
                    } catch (SQLException e) {
                        exceptionSQL = true;
                        logger.warn("SQL Exception: " + e.getMessage(), e);
                    }

                    try {
                        babelIsLastRow = cursor_bbl.isLast();
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
                    } else {
                        return CompareResults.cursorPositionAssert(sqlIsLastRow, babelIsLastRow, logger,
                                "One of the cursors is not at the last row!");
                    }
                }
            } else if (result[2].toLowerCase().startsWith("next")) {
                logger.info("Moving cursor to the next row");
                
                boolean sqlIsValidRow = false, babelIsValidRow = false;

                try {
                    sqlIsValidRow = cursor_sql.next();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    babelIsValidRow = cursor_bbl.next();
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
                
                if (CompareResults.cursorPositionAssert(sqlIsValidRow, babelIsValidRow, logger, "One of the ResultSets has no more rows!")) {
                    return CompareResults.cursorPositionAssert(cursor_sql, cursor_bbl, logger);
                }
            } else if (result[2].toLowerCase().startsWith("prev")) {
                logger.info("Moving cursor to the previous row");

                boolean sqlIsValidRow = false, babelIsValidRow = false;

                try {
                    sqlIsValidRow = cursor_sql.previous();
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    babelIsValidRow = cursor_bbl.previous();
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
                } else {
                    if (CompareResults.cursorPositionAssert(sqlIsValidRow, babelIsValidRow, logger,
                            "One of the ResultSets has previous row off the ResultSet!")) {
                        return CompareResults.cursorPositionAssert(cursor_sql, cursor_bbl, logger);
                    }
                }
            } else if (result[2].toLowerCase().startsWith("abs") || result[2].toLowerCase().startsWith("rel")) {
                if (result.length < 4 || result[3].length() == 0 || result[3].matches("[ \\t]+")) {
                    logger.error("No integer argument specified with fetch absolute/relative!");
                } else {

                    int pos = Integer.parseInt(result[3]);

                    String message;

                    if (result[2].toLowerCase().startsWith("abs")) {

                        boolean sqlIsOnResultSet = false, babelIsOnResultSet = false;

                        if (result[2].toLowerCase().startsWith("abs")) {
                            message = "Moving cursor to row " + pos;

                            try {
                                sqlIsOnResultSet = cursor_sql.absolute(pos);
                            } catch (SQLException e) {
                                exceptionSQL = true;
                                logger.warn("SQL Exception: " + e.getMessage(), e);
                            }

                            try {
                                babelIsOnResultSet = cursor_bbl.absolute(pos);
                            } catch (SQLException e) {
                                exceptionBabel = true;
                                logger.warn("SQL Exception: " + e.getMessage(), e);
                            }
                        } else {
                            message = "Moving cursor relatively by " + pos + " rows";

                            try {
                                sqlIsOnResultSet = cursor_sql.relative(pos);
                            } catch (SQLException e) {
                                exceptionSQL = true;
                                logger.warn("SQL Exception: " + e.getMessage(), e);
                            }

                            try {
                                babelIsOnResultSet = cursor_bbl.relative(pos);
                            } catch (SQLException e) {
                                exceptionBabel = true;
                                logger.warn("SQL Exception: " + e.getMessage(), e);
                            }
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
                        } else {
                            logger.info(message);
                            if (CompareResults.cursorPositionAssert(sqlIsOnResultSet, babelIsOnResultSet, logger, "Row indices do not match! One of the cursors is inside the ResultSet, the other one is not!")) {
                                return CompareResults.cursorPositionAssert(cursor_sql, cursor_bbl, logger);
                            }
                        }
                    }
                }
            } else {
                logger.warn("Invalid fetch attribute! Set from beforefirst, afterlast, first, last, next, prev, abs or rel");
                return false;
            }
        } else {

            try {
                if (cursor_bbl == null) {
                    bw.write("~~ERROR~~");
                    bw.newLine();
                } else if (result[2].toLowerCase().startsWith("beforefirst")) {
                    cursor_bbl.beforeFirst();
                    bw.write("~~SUCCESS~~");
                    bw.newLine();
                } else if (result[2].toLowerCase().startsWith("afterlast")) {
                    cursor_bbl.afterLast();
                    bw.write("~~SUCCESS~~");
                    bw.newLine();
                } else if (result[2].toLowerCase().startsWith("first")) {
                    cursor_bbl.first();
                    CompareResults.writeCursorResultSetToFile(bw, cursor_bbl);
                } else if (result[2].toLowerCase().startsWith("last")) {
                    cursor_bbl.last();
                    CompareResults.writeCursorResultSetToFile(bw, cursor_bbl);
                } else if (result[2].toLowerCase().startsWith("next")) {
                    cursor_bbl.next();
                    CompareResults.writeCursorResultSetToFile(bw, cursor_bbl);
                } else if (result[2].toLowerCase().startsWith("prev")) {
                    cursor_bbl.previous();
                    CompareResults.writeCursorResultSetToFile(bw, cursor_bbl);
                } else if (result[2].toLowerCase().startsWith("abs") || result[2].toLowerCase().startsWith("rel")) {
                    if (result.length < 4 || result[3].length() == 0 || result[3].matches("[ \\t]+")) {
                        bw.write("~~ERROR~~");
                        bw.newLine();
                    } else {
                        int pos = Integer.parseInt(result[3]);
                        
                        if (result[2].toLowerCase().startsWith("abs")) {
                            cursor_bbl.absolute(pos);
                        } else {
                            cursor_bbl.relative(pos);
                        }
                        CompareResults.writeCursorResultSetToFile(bw, cursor_bbl);
                    }
                } else {
                    bw.write("~~ERROR~~");
                    bw.newLine();
                }
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            } catch (IOException ioe) {
                logger.warn("IO Exception: " + ioe.getMessage(), ioe);
                ioe.printStackTrace();
                return false;
            }
        }
        
        return true;
    }
    
    boolean cursorClose(BufferedWriter bw, Logger logger) {
        logger.info("Closing cursors");
        
        if(!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                if (cursor_sql != null) cursor_sql.close();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                if (cursor_bbl != null) cursor_bbl.close();
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
                if (cursor_bbl != null) cursor_bbl.close();
                bw.write("~~SUCCESS~~");
                bw.newLine();
            } catch(SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            } catch (IOException ioe) {
                logger.warn("IO Exception: " + ioe.getMessage(), ioe);
                ioe.printStackTrace();
                return false;
            }
        }
        
        return true;
    }
}
