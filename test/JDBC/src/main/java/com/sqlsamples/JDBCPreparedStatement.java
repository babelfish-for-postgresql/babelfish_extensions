package com.sqlsamples;

import com.microsoft.sqlserver.jdbc.SQLServerDataTable;
import com.microsoft.sqlserver.jdbc.SQLServerPreparedStatement;
import microsoft.sql.DateTimeOffset;
import org.apache.log4j.Logger;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.math.BigDecimal;
import java.sql.*;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.ParseException;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Locale;

import static com.sqlsamples.Config.compareWithFile;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCPreparedStatement {
    
    PreparedStatement pstmt_sql;
    PreparedStatement pstmt_bbl;

    boolean createPreparedStatements(Connection con_sql, Connection con_bbl, String SQL, Logger logger) {

        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                pstmt_sql = con_sql.prepareStatement(SQL);
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                pstmt_bbl = con_bbl.prepareStatement(SQL);
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
                pstmt_bbl = con_bbl.prepareStatement(SQL);
            } catch (SQLException e) {
                logger.error("Could not create prepared statement!");
            }

            return true;
        }
    }

    boolean closePreparedStatements(Logger logger) {
        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                if (pstmt_sql != null) pstmt_sql.close();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                if (pstmt_bbl != null) pstmt_bbl.close();
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
                if (pstmt_bbl != null) pstmt_bbl.close();
            } catch (SQLException e) {
                logger.error("Could not create statement!");
            }

            return true;
        }
    }

    //function to execute prepared statement and compare results between two servers
    boolean executeAndComparePreparedStatement(String[] result, Logger logger){
        boolean flag = true;

        //set bind variables - SQL server
        set_bind_values(result, pstmt_sql, logger);

        //set bind variables - Babel instance
        set_bind_values(result, pstmt_bbl, logger);

        boolean rs_sql_exists = false, rs_bbl_exists = false;
        boolean exceptionSQL = false, exceptionBabel = false;

        try {
            rs_sql_exists = pstmt_sql.execute();
        } catch (SQLException e) {
            exceptionSQL = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        try {
            rs_bbl_exists = pstmt_bbl.execute();
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
                        sqlDoesNextResultSetExist = pstmt_sql.getMoreResults();
                    } else sqlDoesNextResultSetExist = true;
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    if (!isFirstResultSet) {
                        bblDoesNextResultSetExist = pstmt_bbl.getMoreResults();
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
                        rs_sql = pstmt_sql.getResultSet();
                    } catch (SQLException e) {
                        exceptionSQL = true;
                        logger.warn("SQL Exception: " + e.getMessage(), e);
                    }

                    try {
                        rs_bbl = pstmt_bbl.getResultSet();
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

    //function to write output of executed prepared statement to a file if compareWithFile mode is used
    //executes prepared statement and compares results of server with file otherwise
    boolean testPreparedStatementWithFile(String[] result, BufferedWriter bw, String strLine, Logger logger){
        try {
            if (compareWithFile) {
                bw.write(strLine);
                bw.newLine();
                set_bind_values(result, pstmt_bbl, logger);

                boolean resultSetExist = false;
                int resultsProcessed = 0;
                try {
                    resultSetExist = pstmt_bbl.execute();
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw);
                    resultsProcessed++;
                }
                CompareResults.processResults(pstmt_bbl, bw, resultsProcessed, resultSetExist);
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return true;
    }

    //method to set values of bind variables in a prepared statement
    static void set_bind_values(String[] result, PreparedStatement pstmt, Logger logger) {

        for (int j = 2; j < (result.length); j++) {
            String[] parameter = result[j].split("\\|-\\|", -1);

            try{
                /* TODO: Add more data types here as we support them */
                if(parameter[2].equalsIgnoreCase("<NULL>")){
                    pstmt.setNull(j - 1, CompareResults.SQLtoJDBCDataTypeMapping(parameter[0]));
                } else if (parameter[0].equalsIgnoreCase("int")) {
                    //if there is decimal point, remove everything after the point
                    if (parameter[2].indexOf('.') != -1) parameter[2] = parameter[2].substring(0, parameter[2].indexOf('.') - 1);
                    pstmt.setInt(j - 1, Integer.parseInt(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("string")
                        || parameter[0].equalsIgnoreCase("char")
                        || parameter[0].equalsIgnoreCase("nchar")
                        || parameter[0].equalsIgnoreCase("varchar")
                        || parameter[0].equalsIgnoreCase("nvarchar")
                        || parameter[0].equalsIgnoreCase("uniqueidentifier")
                        || parameter[0].equalsIgnoreCase("varcharmax")
                        || parameter[0].equalsIgnoreCase("nvarcharmax")) {
                    pstmt.setString(j - 1, parameter[2]);
                } else if (parameter[0].equalsIgnoreCase("boolean")
                        || parameter[0].equalsIgnoreCase("bit")) {
                    pstmt.setBoolean(j - 1, Boolean.parseBoolean(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("long")
                        || parameter[0].equalsIgnoreCase("bigint")) {
                    pstmt.setLong(j - 1, Long.parseLong(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("double")
                        || parameter[0].equalsIgnoreCase("float")) {
                    pstmt.setDouble(j - 1, Double.parseDouble(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("unsigned_char")
                        || parameter[0].equalsIgnoreCase("smallint")
                        || parameter[0].equalsIgnoreCase("tinyint")) {
                    pstmt.setShort(j - 1, Short.parseShort(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("real")) {
                    pstmt.setFloat(j - 1, Float.parseFloat(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("byte")) {
                    pstmt.setByte(j - 1, Byte.parseByte(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("binary")
                        || parameter[0].equalsIgnoreCase("varbinary")
                        || parameter[0].equalsIgnoreCase("timestamp")
                        || parameter[0].equalsIgnoreCase("udt")) {
                    byte[] byteArray = parameter[2].getBytes();
                    pstmt.setBytes(j - 1, byteArray);
                } else if (parameter[0].equalsIgnoreCase("decimal")
                        || parameter[0].equalsIgnoreCase("money")
                        || parameter[0].equalsIgnoreCase("smallmoney")
                        || parameter[0].equalsIgnoreCase("numeric")) {
                    DecimalFormat format = (DecimalFormat) NumberFormat.getInstance(Locale.US);
                    format.setParseBigDecimal(true);
                    //remove dollar sign else parsing decimal from this will throw exception
                    String decimalString = parameter[2].replace("$", "");
                    BigDecimal number = (BigDecimal) format.parse(decimalString);
                    pstmt.setBigDecimal(j - 1, number);
                } else if (parameter[0].equalsIgnoreCase("datetime")
                        || parameter[0].equalsIgnoreCase("datetime2")
                        || parameter[0].equalsIgnoreCase("smalldatetime")) {
                    pstmt.setTimestamp(j - 1, Timestamp.valueOf(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("date")) {
                    pstmt.setDate(j - 1, Date.valueOf(parameter[2]));
                } else if (parameter[0].equalsIgnoreCase("time")) {
                    pstmt.setTime(j - 1, Time.valueOf(LocalTime.parse(parameter[2])));
                } else if (parameter[0].equalsIgnoreCase("datetimeoffset")) {
                    SQLServerPreparedStatement ssPstmt = (SQLServerPreparedStatement) pstmt;
                    ssPstmt.setDateTimeOffset(j - 1, DateTimeOffset.valueOf(Timestamp.valueOf(parameter[2]), 0));
                    pstmt = ssPstmt;
                } else if (parameter[0].equalsIgnoreCase("text")
                        || parameter[0].equalsIgnoreCase("ntext")) {
                    Reader r = new FileReader(parameter[2]);
                    pstmt.setCharacterStream(j - 1, r);
                } else if (parameter[0].equalsIgnoreCase("image")) {
                    File file = new File(parameter[2]);
                    BufferedImage bImage = ImageIO.read(file);
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    ImageIO.write(bImage, "jpg", bos );
                    byte [] byteArray = bos.toByteArray();
                    pstmt.setBytes(j - 1, byteArray);
                } else if (parameter[0].equalsIgnoreCase("xml")) {
                    SQLXML sqlxml = pstmt.getConnection().createSQLXML();
                    sqlxml.setString(parameter[2]);
                    pstmt.setSQLXML(j - 1, sqlxml);
                } else if (parameter[0].equalsIgnoreCase("tvp")) {
                    FileInputStream fstream = new FileInputStream(parameter[2]);
                    DataInputStream in = new DataInputStream(fstream);
                    BufferedReader br = new BufferedReader(new InputStreamReader(in));

                    SQLServerDataTable sourceDataTable = new SQLServerDataTable();

                    //first line of file has table columns and their data types
                    String strLine = br.readLine();

                    String[] columnMetaData = strLine.split(",");

                    for (String columnMetaDatum : columnMetaData) {
                        String[] column = columnMetaDatum.split("-");
                        sourceDataTable.addColumnMetadata(column[0], CompareResults.SQLtoJDBCDataTypeMapping(column[1]));
                    }

                    //process and add all rows to data table
                    while ((strLine = br.readLine()) != null) {
                        String[] row = strLine.split(",");
                        ArrayList<Object> rowTuple = new ArrayList<>();
                        
                        for(int i = 0; i < row.length; i++) {
                            String columnDataType = columnMetaData[i].split("-")[1];
                            Object value = CompareResults.parse_data(row[i], columnDataType, logger);
                            rowTuple.add(value);
                        }
                        sourceDataTable.addRow(rowTuple.toArray());
                    }

                    SQLServerPreparedStatement ssPstmt = (SQLServerPreparedStatement) pstmt;
                    ssPstmt.setStructured(j - 1, parameter[1], sourceDataTable);
                    pstmt = ssPstmt;
                }
            } catch (SQLException se) {
                logger.warn("SQL Exception: " + se.getMessage(), se);
            } catch (FileNotFoundException e) {
                logger.warn("File Not Found Exception: " + e.getMessage(), e);
            } catch (IOException e) {
                logger.warn("IO Exception: " + e.getMessage(), e);
            } catch (ParseException e) {
                e.printStackTrace();
            }
        }
    }

}
