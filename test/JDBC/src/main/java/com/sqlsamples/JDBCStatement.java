package com.sqlsamples;

import org.apache.logging.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.SQLWarning;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCStatement {

    Statement stmt_bbl;
    
    void createStatements(Connection con_bbl, BufferedWriter bw, Logger logger) {
        try {
            stmt_bbl = con_bbl.createStatement();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }
    
    void closeStatements(BufferedWriter bw, Logger logger) {
        try {
            if (stmt_bbl != null) stmt_bbl.close();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    // function to write output of executed statement to a file
    void testStatementWithFile(String SQL, BufferedWriter bw, String strLine, Logger logger){
        try {
            bw.write(strLine);
            bw.newLine();

            if (SQL.isEmpty()) {
                return;
            }

            SQLWarning sqlwarn = null;
            boolean resultSetExist = false;
            boolean warningExist = false;
            int resultsProcessed = 0;
            try {
                resultSetExist = stmt_bbl.execute(SQL);
                sqlwarn = stmt_bbl.getWarnings();
                if(sqlwarn != null) warningExist = true;
            } catch (SQLException e) {
                handleSQLExceptionWithFile(e, bw, logger);
                resultsProcessed++;
            }
            CompareResults.processResults(stmt_bbl, bw, resultsProcessed, resultSetExist, warningExist, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        } catch (IllegalStateException e) {
            logger.error("Illegal State Exception: " + e.getMessage(), e);
        }
    }
}
