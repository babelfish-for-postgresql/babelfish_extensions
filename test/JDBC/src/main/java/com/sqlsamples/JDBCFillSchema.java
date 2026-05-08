package com.sqlsamples;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.logging.log4j.Logger;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCFillSchema {
    
    static void testFillSchema(BufferedWriter bw, Logger logger, Connection con_bbl, String query) throws IOException {
        try {
            bw.write("~~START~~");
            bw.newLine();

            Statement stmt = con_bbl.createStatement();
            ResultSet rs = stmt.executeQuery(query);
            ResultSetMetaData rsmd = rs.getMetaData();

            String tableName = extractTableName(query);
            List<String> primaryKeyColumns = new ArrayList<>();
            
            if (tableName != null && !tableName.isEmpty()) {
                try {
                    DatabaseMetaData dbmeta = con_bbl.getMetaData();
                    ResultSet pkRs = dbmeta.getPrimaryKeys(null, null, tableName);
                    while (pkRs.next()) {
                        primaryKeyColumns.add(pkRs.getString("COLUMN_NAME"));
                    }
                    pkRs.close();
                } catch (SQLException e) {
                    logger.warn("Could not retrieve primary keys for table: " + tableName);
                }
            }
            
            bw.write("Table Columns:");
            bw.newLine();
            
            int columnCount = rsmd.getColumnCount();
            for (int i = 1; i <= columnCount; i++) {
                String columnName = rsmd.getColumnName(i);
                String columnClassName = rsmd.getColumnClassName(i);
                int nullable = rsmd.isNullable(i);
                boolean isPrimaryKey = primaryKeyColumns.contains(columnName);
                
                bw.write("Column: " + columnName);
                bw.newLine();
                bw.write("  - Is Primary Key: " + (isPrimaryKey ? "True" : "False"));
                bw.newLine();
                bw.write("  - Data Type: " + mapToNetType(columnClassName));
                bw.newLine();
                
                String allowNull;
                if (nullable == ResultSetMetaData.columnNoNulls) {
                    allowNull = "False";
                } else if (nullable == ResultSetMetaData.columnNullable) {
                    allowNull = "True";
                } else {
                    allowNull = "Unknown";
                }
                bw.write("  - Allow Null: " + allowNull);
                bw.newLine();
            }
            
            bw.newLine();
            bw.write("Primary Key Columns:");
            bw.newLine();
            if (!primaryKeyColumns.isEmpty()) {
                for (String pkCol : primaryKeyColumns) {
                    bw.write("- " + pkCol);
                    bw.newLine();
                }
            } else {
                bw.write("- None");
                bw.newLine();
            }
            
            rs.close();
            stmt.close();
            
            bw.write("~~END~~");
            bw.newLine();
            bw.newLine();
            
            logger.info("FillSchema test completed for query: " + query);
            
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }
    
    private static String mapToNetType(String javaClassName) {
        if (javaClassName == null) return "System.Object";
        
        switch (javaClassName) {
            case "java.lang.Integer":
                return "System.Int32";
            case "java.lang.Long":
                return "System.Int64";
            case "java.lang.Short":
                return "System.Int16";
            case "java.lang.Byte":
                return "System.Byte";
            case "java.lang.String":
                return "System.String";
            case "java.lang.Boolean":
                return "System.Boolean";
            case "java.lang.Double":
                return "System.Double";
            case "java.lang.Float":
                return "System.Single";
            case "java.math.BigDecimal":
                return "System.Decimal";
            case "java.sql.Date":
            case "java.sql.Timestamp":
            case "java.time.LocalDateTime":
                return "System.DateTime";
            case "java.sql.Time":
                return "System.TimeSpan";
            case "[B":  
                return "System.Byte[]";
            default:
                return javaClassName;
        }
    }
    
    private static String extractTableName(String query) {
        try {
            Pattern pattern = Pattern.compile("\\bFROM\\s+([^\\s,;()]+)", Pattern.CASE_INSENSITIVE);
            Matcher matcher = pattern.matcher(query);
            if (matcher.find()) {
                String tableName = matcher.group(1);
                if (tableName.contains(".")) {
                    tableName = tableName.substring(tableName.lastIndexOf(".") + 1);
                }
                tableName = tableName.replaceAll("[\\[\\]\"]", "");
                return tableName;
            }
        } catch (Exception e) {
            // ignore
        }
        return null;
    }
}