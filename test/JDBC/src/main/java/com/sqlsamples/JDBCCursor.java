package com.sqlsamples;

import org.apache.logging.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCCursor {
    
    ResultSet cursor_bbl;
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

    void setHoldabilityOnConnection(Connection conn, int holdability) throws SQLException {
        if ("JtdsConnection".equals(conn.getClass().getSimpleName()) &&
                ResultSet.CLOSE_CURSORS_AT_COMMIT == holdability) {
            // CLOSE_CURSORS_AT_COMMIT option not supported in jTDS
            return;
        }
        conn.setHoldability(holdability);
    }

    void openCursor(Connection con_bbl, Logger logger, String[] result, String strLine, BufferedWriter bw) {
        logger.info("Opening Cursor");
        
        if (result[2].toLowerCase().startsWith("prepst")) {
            openCursorOnPreparedStatement(con_bbl, logger, result, bw);
        } else {
            openCursorOnStatement(con_bbl, bw, logger, result);
        }
    }
    
    void openCursorOnPreparedStatement(Connection con_bbl, Logger logger, String[] result, BufferedWriter bw) {
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

        // set cursor options
        int[] cursorOptions = setCursorOptions(i, result, logger);
        int type = cursorOptions[0];
        int concur = cursorOptions[1];
        int holdability = cursorOptions[2];

        String SQL = contentsArray[1];
        
        try {
            setHoldabilityOnConnection(con_bbl, holdability);
            if (!result[3].toLowerCase().startsWith("exec")) {
                if (pstmt_bbl != null) pstmt_bbl.close();
                pstmt_bbl = con_bbl.prepareStatement(SQL, type, concur);
            }

            JDBCPreparedStatement.set_bind_values(contentsArray, pstmt_bbl, bw, logger);
            cursor_bbl = pstmt_bbl.executeQuery();
            bw.write("~~SUCCESS~~");
            bw.newLine();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        } catch (NullPointerException e) {
            logger.error("Null Pointer Exception: " + e.getMessage(), e);
        }
    }

    void openCursorOnStatement(Connection con_bbl, BufferedWriter bw, Logger logger, String[] result) {
        // set cursor options
        int[] cursorOptions = setCursorOptions(3, result, logger);
        int type = cursorOptions[0];
        int concur = cursorOptions[1];
        int holdability = cursorOptions[2];

        String SQL = result[2];
        Statement stmt_sql = null, stmt_bbl = null;
        
        try {
            setHoldabilityOnConnection(con_bbl, holdability);
            stmt_bbl = con_bbl.createStatement(type, concur);
            cursor_bbl = stmt_bbl.executeQuery(SQL);
            bw.write("~~SUCCESS~~");
            bw.newLine();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }
    
    void cursorFetch(BufferedWriter bw, Logger logger, String[] result) {

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
                CompareResults.writeCursorResultSetToFile(bw, cursor_bbl, logger);
            } else if (result[2].toLowerCase().startsWith("last")) {
                cursor_bbl.last();
                CompareResults.writeCursorResultSetToFile(bw, cursor_bbl, logger);
            } else if (result[2].toLowerCase().startsWith("next")) {
                cursor_bbl.next();
                CompareResults.writeCursorResultSetToFile(bw, cursor_bbl, logger);
            } else if (result[2].toLowerCase().startsWith("prev")) {
                cursor_bbl.previous();
                CompareResults.writeCursorResultSetToFile(bw, cursor_bbl, logger);
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
                    CompareResults.writeCursorResultSetToFile(bw, cursor_bbl, logger);
                }
            } else {
                bw.write("~~ERROR~~");
                bw.newLine();
            }
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }
    
    void cursorClose(BufferedWriter bw, Logger logger) {
        logger.info("Closing cursors");
        
        try {
            if (cursor_bbl != null) cursor_bbl.close();
            bw.write("~~SUCCESS~~");
            bw.newLine();
        } catch(SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }
}
