package com.sqlsamples;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;

import org.apache.logging.log4j.Logger;

import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCMetadata {

    static void testDatabaseMetadata(BufferedWriter bw, Logger logger, Connection con_bbl,
                                     String method, String data) throws IOException {
        try {
            DatabaseMetaData dbmeta = con_bbl.getMetaData();
            switch (method) {
                case "getCatalogs": testGetCatalogs(bw, logger, dbmeta); break;
                case "getColumnPrivileges": testGetColumnPrivileges(bw, logger, dbmeta, data); break;
                case "getTables": testGetTables(bw, logger, dbmeta, data); break;
                case "getColumns": testGetColumns(bw, logger, dbmeta, data); break;
                case "getFunctions": testGetFunctions(bw, logger, dbmeta, data); break;
                case "getFunctionColumns": testGetFunctionColumns(bw, logger, dbmeta, data); break;
                case "getBestRowIdentifier": testGetBestRowIdentifier(bw, logger, dbmeta, data); break;
                case "getCrossReference": testGetCrossReference(bw, logger, dbmeta, data); break;
                case "getExportedKeys": testGetExportedKeys(bw, logger, dbmeta, data); break;
                case "getImportedKeys": testGetImportedKeys(bw, logger, dbmeta, data); break;
                case "getIndexInfo": testGetIndexInfo(bw, logger, dbmeta, data); break;
                case "getMaxConnections": testGetMaxConnections(bw, dbmeta); break;
                case "getPrimaryKeys": testGetPrimaryKeys(bw, logger, dbmeta, data); break;
                case "getProcedureColumns": testGetProcedureColumns(bw, logger, dbmeta, data); break;
                case "getProcedures": testGetProcedures(bw, logger, dbmeta, data); break;
                case "getSchemas": testGetSchemas(bw, logger, dbmeta, data); break;
                case "getTablePrivileges": testGetTablePrivileges(bw, logger, dbmeta, data); break;
                case "getTypeInfo": testGetTypeInfo(bw, logger, dbmeta); break;
                case "getUserName": testGetUserName(bw, dbmeta); break;
                case "getVersionColumns": testGetVersionColumns(bw, logger, dbmeta, data); break;
                default: throw new SQLException("Unexpected Metadata method: " + method);
            }

        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    private static void testGetCatalogs(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta) throws SQLException {
        ResultSet rs = dbmeta.getCatalogs();
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetColumnPrivileges(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 4) {
            throw new SQLException("Invalid number of parameters for 'getColumnPrivileges'," +
                    " expected: '#!#getColumnPrivileges#!#catalog|schema|table|column'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        String column = parts[3];
        ResultSet rs = dbmeta.getColumnPrivileges(catalog, schema, table, column);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetTables(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length < 3) {
            throw new SQLException("Invalid number of parameters for 'getTables'," +
                    " expected: '#!#getTables#!#catalog|schema|table[|type1|...|typeN]'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        String[] types = null;
        if (parts.length > 3) {
            types = Arrays.copyOfRange(parts, 3, parts.length);
        }
        ResultSet rs = dbmeta.getTables(catalog, schema, table, types);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetColumns(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3 && parts.length != 4) {
            throw new SQLException("Invalid number of parameters for 'getColumns'," +
                    " expected: '#!#getColumns#!#catalog|schema|table[|column]'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        String column = null;
        if (parts.length == 4) {
            column = parts[3];
        }
        ResultSet rs = dbmeta.getColumns(catalog, schema, table, column);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetFunctions(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 2 && parts.length != 3) {
            throw new SQLException("Invalid number of parameters for 'getFunctions'," +
                    " expected: '#!#getFunctions#!#catalog|schema[|function]'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String function = null;
        if (parts.length == 3) {
            function = parts[2];
        }
        ResultSet rs = dbmeta.getFunctions(catalog, schema, function);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetFunctionColumns(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3 && parts.length != 4) {
            throw new SQLException("Invalid number of parameters for 'getFunctionColumns'," +
                    " expected: '#!#getFunctionColumns#!#catalog|schema|function[|column]'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String function = parts[2];
        String column = null;
        if (parts.length == 4) {
            column = parts[3];
        }
        ResultSet rs = dbmeta.getFunctionColumns(catalog, schema, function, column);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetBestRowIdentifier(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 5) {
            throw new SQLException("Invalid number of parameters for 'getBestRowIdentifier'," +
                    " expected: '#!#getBestRowIdentifier#!#catalog|schema|table|scope|nullable'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        int scope = Integer.parseInt(parts[3]);
        boolean nullable = Boolean.parseBoolean(parts[4]);
        ResultSet rs = dbmeta.getBestRowIdentifier(catalog, schema, table, scope, nullable);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetCrossReference(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 6) {
            throw new SQLException("Invalid number of parameters for 'getCrossReference'," +
                    " expected: '#!#getCrossReference#!#catalog1|schema1|table1|catalog2|schema2|table2'");
        }
        String catalog1 = parts[0];
        String schema1 = parts[1];
        String table1 = parts[2];
        String catalog2 = parts[3];
        String schema2 = parts[4];
        String table2 = parts[5];
        ResultSet rs = dbmeta.getCrossReference(catalog1, schema1, table1, catalog2, schema2, table2);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetExportedKeys(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3) {
            throw new SQLException("Invalid number of parameters for 'getExportedKeys'," +
                    " expected: '#!#getExportedKeys#!#catalog|schema|table'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        ResultSet rs = dbmeta.getExportedKeys(catalog, schema, table);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetImportedKeys(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3) {
            throw new SQLException("Invalid number of parameters for 'getImportedKeys'," +
                    " expected: '#!#getImportedKeys#!#catalog|schema|table'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        ResultSet rs = dbmeta.getImportedKeys(catalog, schema, table);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetIndexInfo(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 5) {
            throw new SQLException("Invalid number of parameters for 'getIndexInfo'," +
                    " expected: '#!#getIndexInfo#!#catalog|schema|table|unique|approximate'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        boolean unique = Boolean.parseBoolean(parts[3]);
        boolean approximate = Boolean.parseBoolean(parts[4]);
        ResultSet rs = dbmeta.getIndexInfo(catalog, schema, table, unique, approximate);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetMaxConnections(BufferedWriter bw, DatabaseMetaData dbmeta) throws SQLException, IOException {
        int maxConn = dbmeta.getMaxConnections();

        bw.write("~~START~~");
        bw.newLine();

        bw.write(String.valueOf(maxConn));
        bw.newLine();

        bw.write("~~END~~");
        bw.newLine();
        bw.newLine();
    }

    private static void testGetPrimaryKeys(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3) {
            throw new SQLException("Invalid number of parameters for 'getPrimaryKeys'," +
                    " expected: '#!#getPrimaryKeys#!#catalog|schema|table'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        ResultSet rs = dbmeta.getPrimaryKeys(catalog, schema, table);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetProcedureColumns(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3 && parts.length != 4) {
            throw new SQLException("Invalid number of parameters for 'getProcedureColumns'," +
                    " expected: '#!#getProcedureColumns#!#catalog|schema|procedure[|column]'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String procedure = parts[2];
        String column = null;
        if (parts.length == 4) {
            column = parts[3];
        }
        ResultSet rs = dbmeta.getProcedureColumns(catalog, schema, procedure, column);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetProcedures(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 2 && parts.length != 3) {
            throw new SQLException("Invalid number of parameters for 'getProcedures'," +
                    " expected: '#!#getProcedures#!#catalog|schema[|procedure]'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String procedure = null;
        if (parts.length == 3) {
            procedure = parts[2];
        }
        ResultSet rs = dbmeta.getFunctions(catalog, schema, procedure);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetSchemas(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 1 && parts.length != 2) {
            throw new SQLException("Invalid number of parameters for 'getSchemas'," +
                    " expected: '#!#getSchemas#!#catalog[|schema]'");
        }
        String catalog = parts[0];
        String schema = null;
        if (parts.length == 2) {
            schema = parts[1];
        }
        ResultSet rs = dbmeta.getSchemas(catalog, schema);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetTablePrivileges(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3) {
            throw new SQLException("Invalid number of parameters for 'getTablePrivileges'," +
                    " expected: '#!#getTablePrivileges#!#catalog|schema|table'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        ResultSet rs = dbmeta.getTablePrivileges(catalog, schema, table);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetTypeInfo(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta) throws SQLException {
        ResultSet rs = dbmeta.getTypeInfo();
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }

    private static void testGetUserName(BufferedWriter bw, DatabaseMetaData dbmeta) throws SQLException, IOException {
        String userName = dbmeta.getUserName();

        bw.write("~~START~~");
        bw.newLine();

        bw.write(userName);
        bw.newLine();

        bw.write("~~END~~");
        bw.newLine();
        bw.newLine();
    }

    private static void testGetVersionColumns(BufferedWriter bw, Logger logger, DatabaseMetaData dbmeta, String data) throws SQLException {
        String[] parts = data.split("\\|");
        if (parts.length != 3) {
            throw new SQLException("Invalid number of parameters for 'getVersionColumns'," +
                    " expected: '#!#getVersionColumns#!#catalog|schema|table'");
        }
        String catalog = parts[0];
        String schema = parts[1];
        String table = parts[2];
        ResultSet rs = dbmeta.getVersionColumns(catalog, schema, table);
        CompareResults.writeResultSetToFile(bw, rs, logger);
    }
}
