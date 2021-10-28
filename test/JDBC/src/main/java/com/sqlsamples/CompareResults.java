package com.sqlsamples;

import org.junit.jupiter.api.Assertions;
import org.opentest4j.AssertionFailedError;
import microsoft.sql.DateTimeOffset;
import org.apache.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.*;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.ParseException;
import java.time.LocalTime;
import java.util.Locale;

import static com.sqlsamples.Config.outputColumnName;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;
import static java.sql.Types.*;
import static java.util.Objects.isNull;

public class CompareResults {

    //function that compare result sets from SQL server and babel instance
    public static boolean compareResultSets(ResultSet rs1, ResultSet rs2, Logger logger) {

        logger.info("Comparing result sets...");

        ResultSetMetaData rsmd1 = null, rsmd2 = null;
        int cols1 = -1, cols2 = -1;
        boolean exceptionSQL = false, exceptionBabel = false;

        try {
            rsmd1 = rs1.getMetaData();
        } catch (SQLException e) {
            exceptionSQL = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        try {
            rsmd2 = rs2.getMetaData();
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
            cols1 = rsmd1.getColumnCount();
        } catch (SQLException e) {
            exceptionSQL = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        try {
            cols2 = rsmd2.getColumnCount();
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

        //assert number of columns in both result sets are same
        try{
            Assertions.assertEquals(cols1, cols2, "Result sets are different! Number of columns do not match");
        } catch (AssertionFailedError afe) {
            logger.error("Assertion Failed Error: " + afe.getMessage());
            return false;
        }

        //boolean flags to check whether next row exists
        boolean doesNextExist1 = false, doesNextExist2 = false;

        try {
            doesNextExist1 = rs1.next();
        } catch (SQLException e) {
            exceptionSQL = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        try {
            doesNextExist2 = rs2.next();
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

        try{
            Assertions.assertEquals(doesNextExist1, doesNextExist2, "Result sets are different! One of them is empty!");
        } catch (AssertionFailedError afe) {
            logger.error("Assertion Failed Error: " + afe.getMessage());
            return false;
        }

        while (doesNextExist1 && doesNextExist2) {
            for (int i = 1; i <= cols1; i++) {
                //assert object content for a particular row and column is same
                try{
                    Object str1 = null, str2 = null;
                    int type;

                    try {
                        type = rsmd1.getColumnType(i);
                        if (type == BINARY || type == VARBINARY || type == LONGVARBINARY) {
                            str1 = rs1.getString(i);
                        } else str1 = rs1.getObject(i);
                    } catch (SQLException e) {
                        exceptionSQL = true;
                        logger.warn("SQL Exception: " + e.getMessage(), e);
                    }

                    try {
                        type = rsmd2.getColumnType(i);
                        if (type == BINARY || type == VARBINARY || type == LONGVARBINARY) {
                            str2 = rs2.getString(i);
                        } else str2 = rs2.getObject(i);
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
                    
                    Assertions.assertEquals(str1, str2, "Result sets are different! Objects in tuple do not match!");
                } catch (AssertionFailedError afe) {
                    int row;
                    
                    try {
                        row = rs2.getRow();
                    } catch (SQLException e) {
                        logger.warn("Exception in fetching row index from Babel: " + e.getMessage(), e);
                        return false;
                    }
                    
                    String msg = "Mismatch at row: " + row + " and column: " + i;
                    logger.error(msg);
                    logger.error("Assertion Failed Error: " + afe.getMessage());
                    return false;
                }
            }
            
            try {
                doesNextExist1 = rs1.next();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                doesNextExist2 = rs2.next();
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
            
            //assert both result sets have either next row present or absent
            try{
                Assertions.assertEquals(doesNextExist1, doesNextExist2, "Result sets are different! Unequal number of rows");
            } catch (AssertionFailedError afe) {
                logger.error("Assertion Failed Error: " + afe.getMessage());
                return false;
            }
        }
        return true;

    }

    //function to assert that result set cursor is at the same position if cursor is outside the result set
    public static boolean cursorPositionAssert(boolean pos_sql, boolean pos_bbl, Logger logger, String assertFailedMsg){
        try{
            Assertions.assertEquals(pos_sql, pos_bbl, assertFailedMsg);
        } catch (AssertionFailedError afe) {
            logger.error("Assertion Failed Error: " + afe.getMessage());
            return false;
        }

        return true;
    }

    //overloaded method to assert that result set cursor is at the same position if cursor is within the result set
    public static boolean cursorPositionAssert(ResultSet cursor_sql, ResultSet cursor_bbl, Logger logger) {
        try {
            int sqlRow = 0, babelRow = 0;
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                sqlRow = cursor_sql.getRow();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                babelRow = cursor_bbl.getRow();
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

            Assertions.assertEquals(sqlRow, babelRow, "Row indices do not match!");
        } catch (AssertionFailedError afe) {
            logger.error("Assertion Failed Error: " + afe.getMessage());
            return false;
        }
        return true;
    }

    //function to write result set into a file
    public static void writeResultSetToFile(BufferedWriter bw, ResultSet rs) {
        try {
            bw.write("~~START~~");
            bw.newLine();

            ResultSetMetaData rsmd = rs.getMetaData();
            int cols = rsmd.getColumnCount();

            if (outputColumnName) {
	        for (int i = 1; i <= cols; i++) {
                    bw.write(rsmd.getColumnName(i));
                    if (i != cols) bw.write("#!#");
                }
                bw.newLine();
	    }

            for (int i = 1; i <= cols; i++) {
                bw.write(rsmd.getColumnTypeName(i));
                if (i != cols) bw.write("#!#");
            }
            bw.newLine();

            while (rs.next()) {
                for (int i = 1; i <= cols; i++) {
                    if(isNull(rs.getObject(i))){
                        bw.write("<NULL>");
                    } else {
                        String str = rs.getString(i);
                        str = str.replaceAll("[\r\n]+", "<newline>");
                        bw.write(str);
                    }

                    if (i != cols) bw.write("#!#");
                }
                bw.newLine();
            }

            bw.write("~~END~~");
            bw.newLine();
            bw.newLine();
            
            rs.close();

        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw);
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }
    }

    //function to write the tuple, result set cursor is pointing to, into a file
    public static void writeCursorResultSetToFile(BufferedWriter bw, ResultSet cursor) {
        try {
            bw.write("~~START~~");
            bw.newLine();

            ResultSetMetaData rsmd = cursor.getMetaData();
            int cols = rsmd.getColumnCount();

            if (outputColumnName) {
	        for (int i = 1; i <= cols; i++) {
                    bw.write(rsmd.getColumnName(i));
                    if (i != cols) bw.write("#!#");
                }
                bw.newLine();
	    }
            
            for (int i = 1; i <= cols; i++) {
                //bw.write(JDBCtoSQLDataTypeMapping(rsmd.getColumnType(i)));
                bw.write(rsmd.getColumnTypeName(i));
                if (i != cols) bw.write("#!#");
            }

            bw.newLine();

            for (int i = 1; i <= cols; i++) {
                if(isNull(cursor.getObject(i))){
                    bw.write("<NULL>");
                } else {
                    bw.write(cursor.getObject(i).toString());
                }
                if (i != cols) bw.write("#!#");
            }
            bw.newLine();
            bw.write("~~END~~");
            bw.newLine();
            bw.newLine();

        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw);
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }
    }

    //processes all the results sequentially that we get from executing a JDBC Statement
    static void processResults(Statement stmt, BufferedWriter bw, int resultsProcessed, boolean resultSetExist) {
        int updateCount = -9;  // initialize to impossible value

        while (true) {
            boolean exceptionOccurred = true;
            do {
                try {
                    if (resultsProcessed > 0) {
                        resultSetExist = stmt.getMoreResults();
                    }
                    exceptionOccurred = false;
                    updateCount = stmt.getUpdateCount();
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw);
                }
                resultsProcessed++;
            } while (exceptionOccurred);

            if ((!resultSetExist) && (updateCount == -1)) {
                break;
            }

            if (resultSetExist) {
                try (ResultSet rs = stmt.getResultSet()) {
                    writeResultSetToFile(bw, rs);
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw);
                }
            } else {
                if (updateCount > 0) {
                    try {
                        bw.write("~~ROW COUNT: " + updateCount + "~~");
                        bw.newLine();
                        bw.newLine();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    //function to map SQL data type to JDBC data types
    static int SQLtoJDBCDataTypeMapping(String sqlDataType) {
        
        if(sqlDataType.equalsIgnoreCase("bigint")) {
            return BIGINT;
        } else if (sqlDataType.equalsIgnoreCase("binary")
                || sqlDataType.equalsIgnoreCase("timestamp")) {
            return BINARY;
        } else if (sqlDataType.equalsIgnoreCase("bit")) {
            return BIT;
        } else if (sqlDataType.equalsIgnoreCase("char")
                || sqlDataType.equalsIgnoreCase("uniqueidentifier")) {
            return CHAR;
        } else if (sqlDataType.equalsIgnoreCase("date")) {
            return DATE;
        } else if (sqlDataType.equalsIgnoreCase("datetime")
                || sqlDataType.equalsIgnoreCase("datetime2")
                || sqlDataType.equalsIgnoreCase("smalldatetime")) {
            return TIMESTAMP;
        } else if (sqlDataType.equalsIgnoreCase("datetimeoffset")) {
            return microsoft.sql.Types.DATETIMEOFFSET;
        } else if (sqlDataType.equalsIgnoreCase("decimal")
                || sqlDataType.equalsIgnoreCase("money")
                || sqlDataType.equalsIgnoreCase("smallmoney")) {
            return DECIMAL;
        } else if (sqlDataType.equalsIgnoreCase("float")) {
            return DOUBLE;
        } else if (sqlDataType.equalsIgnoreCase("image")) {
            return LONGVARBINARY;
        } else if (sqlDataType.equalsIgnoreCase("int")) {
            return INTEGER;
        } else if (sqlDataType.equalsIgnoreCase("nchar")) {
            return NCHAR;
        } else if (sqlDataType.equalsIgnoreCase("nvarchar")
                || sqlDataType.equalsIgnoreCase("nvarcharmax")) {
            return NVARCHAR;
        } else if (sqlDataType.equalsIgnoreCase("ntext")
                || sqlDataType.equalsIgnoreCase("xml")) {
            return LONGNVARCHAR;
        } else if (sqlDataType.equalsIgnoreCase("numeric")) {
            return NUMERIC;
        } else if (sqlDataType.equalsIgnoreCase("real")) {
            return REAL;
        } else if (sqlDataType.equalsIgnoreCase("smallint")) {
            return SMALLINT;
        } else if (sqlDataType.equalsIgnoreCase("text")) {
            return LONGVARCHAR;
        } else if (sqlDataType.equalsIgnoreCase("time")) {
            return TIME;
        } else if (sqlDataType.equalsIgnoreCase("tinyint")) {
            return TINYINT;
        } else if (sqlDataType.equalsIgnoreCase("udt")
                || sqlDataType.equalsIgnoreCase("varbinary")
                || sqlDataType.equalsIgnoreCase("varbinarymax")
                || sqlDataType.equalsIgnoreCase("geometry")
                || sqlDataType.equalsIgnoreCase("geography")) {
            return VARBINARY;
        } else if (sqlDataType.equalsIgnoreCase("varchar")
                || sqlDataType.equalsIgnoreCase("varcharmax")) {
            return VARCHAR;
        } else if (sqlDataType.equalsIgnoreCase("sqlvariant")) {
            return microsoft.sql.Types.SQL_VARIANT;
        } else return 0;
    }

    //function to parse SQL data type to Java data type
    static Object parse_data(String result, String datatype, Logger logger) {

        try {
            if(result.equals("<NULL>")){
                return null;
            }

            /* TODO: Add more data types here as we support them */
            if (datatype.equalsIgnoreCase("int")) {
                return Integer.parseInt(result);
            } else if (datatype.equalsIgnoreCase("string")
                    || datatype.equalsIgnoreCase("char")
                    || datatype.equalsIgnoreCase("nchar")
                    || datatype.equalsIgnoreCase("varchar")
                    || datatype.equalsIgnoreCase("nvarchar")
                    || datatype.equalsIgnoreCase("uniqueidentifier")
                    || datatype.equalsIgnoreCase("varcharmax")
                    || datatype.equalsIgnoreCase("nvarcharmax")) {
                return result;
            } else if (datatype.equalsIgnoreCase("boolean")
                    || datatype.equalsIgnoreCase("bit")) {
                return Boolean.parseBoolean(result);
            } else if (datatype.equalsIgnoreCase("long")
                    || datatype.equalsIgnoreCase("bigint")) {
                return Long.parseLong(result);
            } else if (datatype.equalsIgnoreCase("double")
                    || datatype.equalsIgnoreCase("float")) {
                return Double.parseDouble(result);
            } else if (datatype.equalsIgnoreCase("unsigned_char")
                    || datatype.equalsIgnoreCase("smallint")
                    || datatype.equalsIgnoreCase("tinyint")) {
                return Short.parseShort(result);
            } else if (datatype.equalsIgnoreCase("real")) {
                return Float.parseFloat(result);
            } else if (datatype.equalsIgnoreCase("byte")) {
                return Byte.parseByte(result);
            } else if (datatype.equalsIgnoreCase("binary")
                    || datatype.equalsIgnoreCase("varbinary")
                    || datatype.equalsIgnoreCase("timestamp")
                    || datatype.equalsIgnoreCase("udt")) {
                return result;
            } else if (datatype.equalsIgnoreCase("decimal")
                    || datatype.equalsIgnoreCase("money")
                    || datatype.equalsIgnoreCase("smallmoney")
                    || datatype.equalsIgnoreCase("numeric")) {
                DecimalFormat format = (DecimalFormat) NumberFormat.getInstance(Locale.US);
                format.setParseBigDecimal(true);
                return format.parse(result);
            } else if (datatype.equalsIgnoreCase("datetime")
                    || datatype.equalsIgnoreCase("datetime2")
                    || datatype.equalsIgnoreCase("smalldatetime")){
                return Timestamp.valueOf(result);
            } else if (datatype.equalsIgnoreCase("date")){
                return Date.valueOf(result);
            } else if (datatype.equalsIgnoreCase("time")){
                return Time.valueOf(LocalTime.parse(result));
            } else if (datatype.equalsIgnoreCase("text")
                    || datatype.equalsIgnoreCase("ntext")){
                return result.replaceAll("<newline>", System.lineSeparator());
            } else if (datatype.equalsIgnoreCase("datetimeoffset")){
                return DateTimeOffset.valueOf(Timestamp.valueOf(result), 0);
            }
        } catch (ParseException pe) {
            logger.warn("Parse Exception: " + pe.getMessage(), pe);
        }

        return null;
    }
}
