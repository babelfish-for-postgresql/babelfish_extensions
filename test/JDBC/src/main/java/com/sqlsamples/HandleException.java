package com.sqlsamples;

import org.apache.logging.log4j.*;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.SQLException;

import org.postgresql.util.PSQLException;

import static com.sqlsamples.Config.outputErrorCode;

public class HandleException {

    // function to handle SQL exception
    // writes error message to a file
    static void handleSQLExceptionWithFile(SQLException e, BufferedWriter bw, Logger logger){
        try {
            if (outputErrorCode) {
                bw.write("~~ERROR (Code: " + e.getErrorCode() + ")~~");
                bw.newLine();
                bw.newLine();

                // Ensure SQLState is printed as part of pg error message
                if (e instanceof PSQLException) {
                    String errorMsg = e.getMessage();

                    // Do not print error location as part of error message
                    int index = errorMsg.indexOf("Location:");

                    if (index != -1) {
                        errorMsg = errorMsg.substring(0, index);
                    } else {
                        errorMsg += "\n  ";
                    }
                    bw.write("~~ERROR (Message: "+ errorMsg + "  Server SQLState: " + e.getSQLState() + ")~~");
                } else {
                    String errorMsg = e.getMessage();
                    //Do not print ClientConnectionId as part of error message
                    int index = errorMsg.indexOf("ClientConnectionId");
                    if (index != -1) {
                        errorMsg = errorMsg.substring(0, index);
                    }
                    bw.write("~~ERROR (Message: "+ errorMsg + ")~~");
                }
            } else {
                bw.write("~~ERROR~~");
            }
            bw.newLine();
            bw.newLine();
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }
}
