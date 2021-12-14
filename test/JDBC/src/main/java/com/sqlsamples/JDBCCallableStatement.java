package com.sqlsamples;

import com.microsoft.sqlserver.jdbc.SQLServerCallableStatement;
import com.microsoft.sqlserver.jdbc.SQLServerDataTable;
import microsoft.sql.DateTimeOffset;
import org.apache.logging.log4j.Logger;

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

import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCCallableStatement {

    CallableStatement cstmt_bbl;

    void createCallableStatements(Connection con_bbl, String SQL, BufferedWriter bw, Logger logger) {
        try {
            cstmt_bbl = con_bbl.prepareCall(SQL);
        } catch (SQLException e) {
           handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    void closeCallableStatements(BufferedWriter bw, Logger logger) {
        try {
            if (cstmt_bbl != null) cstmt_bbl.close();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    // function to write output of executed callable statement to a file
    void testCallableStatementWithFile(String[] result, BufferedWriter bw, String strLine, Logger logger){
        try {
            bw.write(strLine);
            bw.newLine();
            set_bind_values(result, cstmt_bbl, bw, logger);

            boolean resultSetExist = false;
            int resultsProcessed = 0;
            try {
                resultSetExist = cstmt_bbl.execute();
            } catch (SQLException e) {
                handleSQLExceptionWithFile(e, bw, logger);
                resultsProcessed++;
            }
            CompareResults.processResults(cstmt_bbl, bw, resultsProcessed, resultSetExist, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }


    // method to set values of bind variables in a callable statement
    private void set_bind_values(String[] result, CallableStatement cstmt, BufferedWriter bw, Logger logger) {

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
                        // if there is decimal point, remove everything after the point
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
                        // remove dollar sign else parsing decimal from this will throw exception
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

                        // first line of file has table columns and their data types
                        String strLine = br.readLine();

                        String[] columnMetaData = strLine.split(",");

                        for (String columnMetaDatum : columnMetaData) {
                            String[] column = columnMetaDatum.split("-");
                            sourceDataTable.addColumnMetadata(column[0], CompareResults.SQLtoJDBCDataTypeMapping(column[1]));
                        }

                        // process and add all rows to data table
                        while ((strLine = br.readLine()) != null) {
                            String[] row = strLine.split(",");
                            ArrayList<Object> rowTuple = new ArrayList<>();

                            for(int i = 0; i < row.length; i++) {
                                rowTuple.add(CompareResults.parse_data(row[i], columnMetaData[i], logger));
                            }
                            sourceDataTable.addRow(rowTuple);
                        }
                        
                        // setStructured API is only applicable to SQLServerCallableStatement
                        SQLServerCallableStatement ssCstmt = (SQLServerCallableStatement) cstmt;
                        ssCstmt.setStructured(j - 1, parameter[1], sourceDataTable);
                        cstmt = ssCstmt;
                    }
                }
            } catch (ParseException pe) {
                logger.error("Parse Exception: " + pe.getMessage(), pe);
            } catch (SQLException se) {
                handleSQLExceptionWithFile(se, bw, logger);
            } catch (FileNotFoundException e) {
                logger.error("File Not Found Exception: " + e.getMessage(), e);
            } catch (IOException e) {
                logger.error("IO Exception: " + e.getMessage(), e);
            }
        }
    }
}
