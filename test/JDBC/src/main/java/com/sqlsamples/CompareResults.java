package com.sqlsamples;

import microsoft.sql.DateTimeOffset;
import org.apache.logging.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.*;
import java.sql.SQLWarning;
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

    // function to write result set into a file
    public static void writeResultSetToFile(BufferedWriter bw, ResultSet rs, Logger logger) {
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
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }

    // function to write the tuple, result set cursor is pointing to, into a file
    public static void writeCursorResultSetToFile(BufferedWriter bw, ResultSet cursor, Logger logger) {
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
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }

    public static void writeWarningToFile(BufferedWriter bw, SQLWarning sqlwarn, Logger logger) {
        try {
            bw.write("~~WARNING (Code: " + sqlwarn.getErrorCode() + ")~~");
            bw.newLine();
            bw.newLine();
            while (sqlwarn != null) {
                bw.write("~~WARNING (Message: "+ sqlwarn.getMessage() +  "  Server SQLState: " + sqlwarn.getSQLState() + ")~~");
                sqlwarn=sqlwarn.getNextWarning();
            } 
            bw.newLine();
            bw.newLine();
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
                    
    }

    // processes all the results sequentially that we get from executing a JDBC Statement
    static void processResults(Statement stmt, BufferedWriter bw, int resultsProcessed, boolean resultSetExist, boolean warningExist, Logger logger) {
        int updateCount = -9;  // initialize to impossible value

        outer: while (true) {
            boolean exceptionOccurred = true;
            do {
                try {
                    if (stmt.getConnection().isClosed()) {
                        // prevent infinite loop if connection was closed
                        break outer;
                    }
                    if (resultsProcessed > 0) {
                        resultSetExist = stmt.getMoreResults();
                    }
                    exceptionOccurred = false;
                    updateCount = stmt.getUpdateCount();
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw, logger);
                }
                resultsProcessed++;
            } while (exceptionOccurred);

            if ((!resultSetExist) && (updateCount == -1)) {
                break;
            }
            if (warningExist) {
                try{
                    SQLWarning sqlwarn = stmt.getWarnings();
                    writeWarningToFile(bw, sqlwarn, logger);
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw, logger);
                }      
            }
            if (resultSetExist) {
                try (ResultSet rs = stmt.getResultSet()) {
                    writeResultSetToFile(bw, rs, logger);
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw, logger);
                } catch (StringIndexOutOfBoundsException e) {
                    // can be thrown by JtdsResultSet.next()
                    logger.error("StringIndexOutOfBoundsException: " + e.getMessage(), e);
                    handleSQLExceptionWithFile(new SQLException(e), bw, logger);
                    // need to go out of the loop, as result set cannot be read
                    break;
                }
            } else {
                if (updateCount > 0) {
                    try {
                        bw.write("~~ROW COUNT: " + updateCount + "~~");
                        bw.newLine();
                        bw.newLine();
                    } catch (IOException e) {
                        logger.error("IO Exception: " + e.getMessage(), e);
                    }
                }
            }
        }
    }

    // function to map SQL data type to JDBC data types
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

    static int remapSQLTypeForJTDS(int type) {
        switch (type) {
            case NCHAR: return CHAR;
            case NVARCHAR: return VARCHAR;
            case LONGNVARCHAR: return LONGVARCHAR;
            default: return type;
        }
    }

    // function to parse SQL data type to Java data type
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
            logger.error("Parse Exception: " + pe.getMessage(), pe);
        }

        return null;
    }
}
