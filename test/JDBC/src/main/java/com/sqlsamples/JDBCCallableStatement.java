package com.sqlsamples;

import com.microsoft.sqlserver.jdbc.SQLServerCallableStatement;
import com.microsoft.sqlserver.jdbc.SQLServerDataTable;
import microsoft.sql.DateTimeOffset;
import org.apache.log4j.Logger;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.math.BigDecimal;
import java.sql.*;
import java.sql.Date;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.ParseException;
import java.time.LocalTime;
import java.util.*;

import static com.sqlsamples.Config.compareWithFile;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCCallableStatement {

    CallableStatement cstmt_sql;
    CallableStatement cstmt_bbl;

    boolean createCallableStatements(Connection con_sql, Connection con_bbl, String SQL, Logger logger) {

        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                cstmt_sql = con_sql.prepareCall(SQL);
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                cstmt_bbl = con_bbl.prepareCall(SQL);
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
                cstmt_bbl = con_bbl.prepareCall(SQL);
            } catch (SQLException e) {
                logger.error("Could not create prepared statement!");
            }

            return true;
        }
    }

    boolean closeCallableStatements(Logger logger) {
        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                if (cstmt_sql != null) cstmt_sql.close();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                if (cstmt_bbl != null) cstmt_bbl.close();
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
                if (cstmt_bbl != null) cstmt_bbl.close();
            } catch (SQLException e) {
                logger.error("Could not create statement!");
            }

            return true;
        }
    }

    //function to execute prepared statement and compare results between two servers
    boolean executeAndCompareCallableStatement(String[] result, Logger logger){
        boolean flag = true;

        //set bind variables - SQL server
        set_bind_values(result, cstmt_sql, logger);

        //set bind variables - Babel instance
        set_bind_values(result, cstmt_bbl, logger);

        boolean rs_sql_exists = false, rs_bbl_exists = false;
        boolean exceptionSQL = false, exceptionBabel = false;

        try {
            rs_sql_exists = cstmt_sql.execute();
        } catch (SQLException e) {
            exceptionSQL = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        try {
            rs_bbl_exists = cstmt_bbl.execute();
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
                        sqlDoesNextResultSetExist = cstmt_sql.getMoreResults();
                    } else sqlDoesNextResultSetExist = true;
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    if (!isFirstResultSet) {
                        bblDoesNextResultSetExist = cstmt_bbl.getMoreResults();
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
                        rs_sql = cstmt_sql.getResultSet();
                    } catch (SQLException e) {
                        exceptionSQL = true;
                        logger.warn("SQL Exception: " + e.getMessage(), e);
                    }

                    try {
                        rs_bbl = cstmt_bbl.getResultSet();
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

    //function to write output of executed callable statement to a file if compareWithFile mode is used
    //executes callable statement and compares results of server with file otherwise
    boolean testCallableStatementWithFile(String[] result, BufferedWriter bw, String strLine, Logger logger){
        try {
            if (compareWithFile) {
                bw.write(strLine);
                bw.newLine();
                set_bind_values(result, cstmt_bbl, logger);

                boolean resultSetExist = false;
                int resultsProcessed = 0;
                try {
                    resultSetExist = cstmt_bbl.execute();
                } catch (SQLException e) {
                    handleSQLExceptionWithFile(e, bw);
                    resultsProcessed++;
                }
                CompareResults.processResults(cstmt_bbl, bw, resultsProcessed, resultSetExist);
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return true;
    }


    //method to set values of bind variables in a callable statement
    private void set_bind_values(String[] result, CallableStatement cstmt, Logger logger) {

        for (int j = 3; j < (result.length); j++) {
            String[] parameter = result[j].split("\\|-\\|", -1);
            parameter[0] = parameter[0].toLowerCase();
            try{
                if (parameter[parameter.length - 1].toLowerCase().contains("out")) {
                    cstmt.registerOutParameter(j - 2, CompareResults.SQLtoJDBCDataTypeMapping(parameter[0]));
                }
                if (parameter[parameter.length - 1].toLowerCase().contains("in")) {
                    /* TODO: Add more data types here as we support them */
                    if (parameter[2].equalsIgnoreCase("<NULL>")) {
                        cstmt.setNull(j - 2, CompareResults.SQLtoJDBCDataTypeMapping(parameter[0]));
                    } else if (parameter[0].equalsIgnoreCase("int")) {
                        //if there is decimal point, remove everything after the point
                        if (parameter[2].indexOf('.') != -1) parameter[2] = parameter[2].substring(0, parameter[2].indexOf('.') - 1);
                        cstmt.setInt(j - 2, Integer.parseInt(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("string")
                            || parameter[0].equalsIgnoreCase("char")
                            || parameter[0].equalsIgnoreCase("nchar")
                            || parameter[0].equalsIgnoreCase("varchar")
                            || parameter[0].equalsIgnoreCase("nvarchar")
                            || parameter[0].equalsIgnoreCase("uniqueidentifier")
                            || parameter[0].equalsIgnoreCase("varcharmax")
                            || parameter[0].equalsIgnoreCase("nvarcharmax")) {
                        cstmt.setString(j - 2, parameter[2]);
                    } else if (parameter[0].equalsIgnoreCase("boolean")
                            || parameter[0].equalsIgnoreCase("bit")) {
                        cstmt.setBoolean(j - 2, Boolean.parseBoolean(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("long")
                            || parameter[0].equalsIgnoreCase("bigint")) {
                        cstmt.setLong(j - 2, Long.parseLong(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("double")
                            || parameter[0].equalsIgnoreCase("float")) {
                        cstmt.setDouble(j - 2, Double.parseDouble(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("unsigned_char")
                            || parameter[0].equalsIgnoreCase("smallint")
                            || parameter[0].equalsIgnoreCase("tinyint")) {
                        cstmt.setShort(j - 2, Short.parseShort(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("real")) {
                        cstmt.setFloat(j - 2, Float.parseFloat(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("byte")) {
                        cstmt.setByte(j - 2, Byte.parseByte(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("binary")
                            || parameter[0].equalsIgnoreCase("varbinary")
                            || parameter[0].equalsIgnoreCase("timestamp")
                            || parameter[0].equalsIgnoreCase("udt")) {
                        byte[] byteArray = parameter[2].getBytes();
                        cstmt.setBytes(j - 2, byteArray);
                    } else if (parameter[0].equalsIgnoreCase("decimal")
                            || parameter[0].equalsIgnoreCase("money")
                            || parameter[0].equalsIgnoreCase("smallmoney")
                            || parameter[0].equalsIgnoreCase("numeric")) {
                        DecimalFormat format = (DecimalFormat) NumberFormat.getInstance(Locale.US);
                        format.setParseBigDecimal(true);
                        //remove dollar sign else parsing decimal from this will throw exception
                        String decimalString = parameter[2].replace("$", "");
                        BigDecimal number = (BigDecimal) format.parse(decimalString);
                        cstmt.setBigDecimal(j - 2, number);
                    } else if (parameter[0].equalsIgnoreCase("datetime")
                            || parameter[0].equalsIgnoreCase("datetime2")
                            || parameter[0].equalsIgnoreCase("smalldatetime")) {
                        cstmt.setTimestamp(j - 2, Timestamp.valueOf(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("date")) {
                        cstmt.setDate(j - 2, Date.valueOf(parameter[2]));
                    } else if (parameter[0].equalsIgnoreCase("time")) {
                        cstmt.setTime(j - 2, Time.valueOf(LocalTime.parse(parameter[2])));
                    } else if (parameter[0].equalsIgnoreCase("datetimeoffset")) {
                        SQLServerCallableStatement ssCstmt = (SQLServerCallableStatement) cstmt;
                        ssCstmt.setDateTimeOffset(j - 1, DateTimeOffset.valueOf(Timestamp.valueOf(parameter[2]), 0));
                        cstmt = ssCstmt;
                    } else if (parameter[0].equalsIgnoreCase("text")
                            || parameter[0].equalsIgnoreCase("ntext")) {
                        Reader r = new FileReader(parameter[2]);
                        cstmt.setCharacterStream(j - 2, r);
                    } else if (parameter[0].equalsIgnoreCase("image")) {
                        File file = new File(parameter[2]);
                        BufferedImage bImage = ImageIO.read(file);
                        ByteArrayOutputStream bos = new ByteArrayOutputStream();
                        ImageIO.write(bImage, "jpg", bos);
                        byte[] byteArray = bos.toByteArray();
                        cstmt.setBytes(j - 2, byteArray);
                    } else if (parameter[0].equalsIgnoreCase("xml")) {
                        SQLXML sqlxml = cstmt.getConnection().createSQLXML();
                        sqlxml.setString(parameter[2]);
                        cstmt.setSQLXML(j - 2, sqlxml);
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
                                rowTuple.add(CompareResults.parse_data(row[i], columnMetaData[i], logger));
                            }
                            sourceDataTable.addRow(rowTuple);
                        }
                        
                        //setStructured API is only applicable to SQLServerCallableStatement
                        SQLServerCallableStatement ssCstmt = (SQLServerCallableStatement) cstmt;
                        ssCstmt.setStructured(j - 1, parameter[1], sourceDataTable);
                        cstmt = ssCstmt;
                    }
                }
            } catch (ParseException pe) {
                logger.warn("Parse Exception: " + pe.getMessage(), pe);
            } catch (SQLException se) {
                logger.warn("SQL Exception: " + se.getMessage(), se);
            } catch (FileNotFoundException e) {
                logger.warn("File Not Found Exception: " + e.getMessage(), e);
            } catch (IOException e) {
                logger.warn("IO Exception: " + e.getMessage(), e);
            }
        }
    }
}
