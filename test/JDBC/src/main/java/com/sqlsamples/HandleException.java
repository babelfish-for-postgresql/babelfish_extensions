package com.sqlsamples;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.SQLException;

import org.postgresql.util.PSQLException;

import static com.sqlsamples.Config.outputErrorCode;

public class HandleException {
    
    //function to handle SQL exception if compareWithFile mode is used
    //if compareWithFile mode is on, writes error message to a file if executed statement throws SQL exception
    static boolean handleSQLExceptionWithFile(SQLException e, BufferedWriter bw){
        
        try {
            if (outputErrorCode) {
                bw.write("~~ERROR (Code: " + e.getErrorCode() + ")~~");
                bw.newLine();
                bw.newLine();

                //Ensure SQLState is printed as part of pg error message
                if (e instanceof PSQLException) {
                    String errorMsg = e.getMessage();

                    //Do not print error location as part of error message
                    int index = errorMsg.indexOf("Location:");

                    if (index != -1) {
                        errorMsg = errorMsg.substring(0, index);
                    } else {
                        errorMsg += "\n  ";
                    }
                    bw.write("~~ERROR (Message: "+ errorMsg + "  Server SQLState: " + e.getSQLState() + ")~~");
                } else {
                    bw.write("~~ERROR (Message: "+ e.getMessage() + ")~~");
                }
            } else {
                bw.write("~~ERROR~~");
            }
            bw.newLine();
            bw.newLine();
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return false;
    }
}
