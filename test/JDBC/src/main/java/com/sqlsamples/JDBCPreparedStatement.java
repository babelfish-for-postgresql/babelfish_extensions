package com.sqlsamples;

import com.microsoft.sqlserver.jdbc.SQLServerDataTable;
import com.microsoft.sqlserver.jdbc.SQLServerPreparedStatement;
import com.microsoft.sqlserver.jdbc.Geometry;
import com.microsoft.sqlserver.jdbc.Geography;
import microsoft.sql.DateTimeOffset;
import org.apache.logging.log4j.Logger;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.math.BigDecimal;
import java.sql.*;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.ParseException;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Locale;
import java.nio.file.Paths;

import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCPreparedStatement {

    PreparedStatement pstmt_bbl;

    void createPreparedStatements(Connection con_bbl, String SQL, BufferedWriter bw, Logger logger) {
        try {
            pstmt_bbl = con_bbl.prepareStatement(SQL);
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    void closePreparedStatements(BufferedWriter bw, Logger logger) {
        try {
            if (pstmt_bbl != null) pstmt_bbl.close();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    // function to write output of executed prepared statement to a file
    void testPreparedStatementWithFile(String[] result, BufferedWriter bw, String strLine, Logger logger){
        try {
            bw.write(strLine);
            bw.newLine();
            set_bind_values(result, pstmt_bbl, bw, logger);

            SQLWarning sqlwarn = null;
            boolean resultSetExist = false;
            boolean warningExist = false;
            int resultsProcessed = 0;
            try {
                resultSetExist = pstmt_bbl.execute();
                sqlwarn = pstmt_bbl.getWarnings();
                if(sqlwarn != null) warningExist = true;
            } catch (SQLException e) {
                handleSQLExceptionWithFile(e, bw, logger);
                resultsProcessed++;
            }
            CompareResults.processResults(pstmt_bbl, bw, resultsProcessed, resultSetExist, warningExist, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
    }

    // method to set values of bind variables in a prepared statement
    static void set_bind_values(String[] result, PreparedStatement pstmt, BufferedWriter bw, Logger logger) {

        for (int j = 2; j < (result.length); j++) {
            String[] parameter = result[j].split("\\|-\\|", -1);

            try{
                /* TODO: Add more data types here as we support them */
                if(parameter[2].equalsIgnoreCase("<NULL>")){
                    pstmt.setNull(j - 1, CompareResults.SQLtoJDBCDataTypeMapping(parameter[0]));
                } else if (parameter[0].equalsIgnoreCase("int")) {
                    // if there is decimal point, remove everything after the point
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
                    // remove dollar sign else parsing decimal from this will throw exception
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
                    Timestamp tsLocal = Timestamp.valueOf(parameter[2]);
                    long millis = tsLocal.toLocalDateTime().toInstant(ZoneOffset.UTC).toEpochMilli();
                    Timestamp ts = new Timestamp(millis);
                    ssPstmt.setDateTimeOffset(j - 1, DateTimeOffset.valueOf(ts, 0));
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
                    FileInputStream fstream = new FileInputStream(Paths.get(Paths.get("").toAbsolutePath().toString(), parameter[2]).toString());
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
                            String columnDataType = columnMetaData[i].split("-")[1];
                            Object value = CompareResults.parse_data(row[i], columnDataType, logger);
                            rowTuple.add(value);
                        }
                        sourceDataTable.addRow(rowTuple.toArray());
                    }

                    SQLServerPreparedStatement ssPstmt = (SQLServerPreparedStatement) pstmt;
                    ssPstmt.setStructured(j - 1, parameter[1], sourceDataTable);
                    pstmt = ssPstmt;
                } else if (parameter[0].equalsIgnoreCase("geometry")) {
                    String[] arguments = parameter[2].split(":", 2);
                    String geoWKT = arguments[0];
                    int srid = -1;
                    try{
                        srid = Integer.parseInt(arguments[1]);
                    } finally {
                        Geometry geomWKT = Geometry.STGeomFromText(geoWKT, srid);
                        SQLServerPreparedStatement ssPstmt = (SQLServerPreparedStatement) pstmt;
                        ssPstmt.setGeometry(j - 1, geomWKT);
                        pstmt = ssPstmt;
                    }
                } else if (parameter[0].equalsIgnoreCase("geography")) {
                    String[] arguments = parameter[2].split(":", 2);
                    String geoWKT = arguments[0];
                    int srid = -1;
                    try{
                        srid = Integer.parseInt(arguments[1]);
                    } finally {
                        Geography geogWKT = Geography.STGeomFromText(geoWKT, srid);
                        SQLServerPreparedStatement ssPstmt = (SQLServerPreparedStatement) pstmt;
                        ssPstmt.setGeography(j - 1, geogWKT);
                        pstmt = ssPstmt;
                    }
                }
            } catch (SQLException se) {
                handleSQLExceptionWithFile(se, bw, logger);
            } catch (FileNotFoundException e) {
                logger.error("File Not Found Exception: " + e.getMessage(), e);
            } catch (IOException e) {
                logger.error("IO Exception: " + e.getMessage(), e);
            } catch (ParseException e) {
                logger.error("Parse Exception: " + e.getMessage(), e);
            } catch (NumberFormatException e) {
                logger.error("Number Format Exception: " + e.getMessage(), e);
            } catch (AbstractMethodError e) {
                logger.error("Abstract Method Error: " + e.getMessage(), e);
            } catch (NullPointerException e) {
                logger.error("Null Pointer Exception: " + e.getMessage(), e);
            }
        }
    }
}
