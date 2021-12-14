package com.sqlsamples;

import org.apache.logging.log4j.*;

import java.util.*;
import java.io.BufferedWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCCrossDialect {

    String URL = properties.getProperty("URL");
    String tsql_port = properties.getProperty("tsql_port");
    String psql_port = properties.getProperty("psql_port");
    String databaseName = properties.getProperty("databaseName");
    String physicalDatabaseName = properties.getProperty("physicalDatabaseName");
    String user = properties.getProperty("user");
    String password = properties.getProperty("password");

    // Key is the username, password and database name concatenated
    // Value is the connection object created using the above 3 attributes
    HashMap<String, Connection> tsqlConnectionMap = new HashMap<>();
    HashMap<String, Connection> psqlConnectionMap = new HashMap<>();

    String newUser = null;
    String newPassword = null;
    String newDatabase = null;
    String newPhysicalDatabase = null;
    String searchPath = null;

    JDBCCrossDialect (Connection connection) {

        // Add already established connection to appropriate hash map
        if (JDBCDriver.equalsIgnoreCase("sqlserver"))
            tsqlConnectionMap.put(user, connection);

        if (JDBCDriver.equalsIgnoreCase("postgresql"))
            psqlConnectionMap.put(user, connection);
    }

    void getConnectionAttributes (String strLine) {
        // Extract username, password and database from string
        String[] connAttributes = strLine.split("\\s+");

        // First two elements of array will be "--" and ("tsql" or "psql")
        for (int i = 2; i < connAttributes.length; i++) {
            String connAttribute = connAttributes[i];

            if (connAttribute.contains("user=")) {
                newUser = connAttribute.split("=")[1];
            } else if (connAttribute.contains("password=")) {
                newPassword = connAttribute.split("=")[1];
            } else if (connAttribute.contains("database=")) {
                newDatabase = connAttribute.split("=")[1];
            } else if (connAttribute.contains("currentSchema=")) {
                searchPath = connAttribute.split("=")[1];
            }
        }

        // If a connection attribute is not provided, we take the value from config file
        if (newUser == null)
            newUser = user;

        if (newPassword == null)
            newPassword = password;

        if (newDatabase == null)
            newDatabase = databaseName;

        if (newPhysicalDatabase == null)
            newPhysicalDatabase = physicalDatabaseName;
    }

    void resetConnectionAttributes () {
        newUser = null;
        newPassword = null;
        newDatabase = null;
    }

    Connection getTsqlConnection (String strLine, BufferedWriter bw, Logger logger) {

        Connection tsqlConnection = null;

        getConnectionAttributes(strLine);

        try {
            // Use sqlserver JDBC driver
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

            // if we already have opened a tsql connection then reuse that
            tsqlConnection = tsqlConnectionMap.get(newUser + newPassword + newDatabase);

            if (tsqlConnection == null) {
                // Create a new connection on tsql port and use that
                String connectionString = createSQLServerConnectionString(URL, tsql_port, newDatabase, newUser, newPassword);
                tsqlConnection = DriverManager.getConnection(connectionString);

                tsqlConnectionMap.put(newUser + newPassword + newDatabase, tsqlConnection);
            }

        } catch (ClassNotFoundException e) {
            logger.error("Class Not Found Exception: " + e.getMessage(), e);
        } catch (SQLException se) {
            handleSQLExceptionWithFile(se, bw, logger);
        }

        resetConnectionAttributes();

        return tsqlConnection;
    }

    Connection getPsqlConnection (String strLine, BufferedWriter bw, Logger logger) {

        Connection psqlConnection = null;

        getConnectionAttributes(strLine);

        try {
            // Use postgresql JDBC driver
            Class.forName("org.postgresql.Driver");

            // if we already have opened a psql connection then reuse that
            psqlConnection = psqlConnectionMap.get(newUser + newPassword + newPhysicalDatabase + searchPath);

            // Create a new connection on psql port and use that
            if (psqlConnection == null) {
                String connectionString = createPostgreSQLConnectionString(URL, psql_port, newPhysicalDatabase, newUser, newPassword);

                if (searchPath != null) {
                    connectionString += ("&currentSchema=" + searchPath);
                }
                psqlConnection = DriverManager.getConnection(connectionString);

                psqlConnectionMap.put(newUser + newPassword + newPhysicalDatabase + searchPath, psqlConnection);
            }

        } catch (ClassNotFoundException e) {
            logger.error("Class Not Found Exception: " + e.getMessage(), e);
        } catch (SQLException se) {
            handleSQLExceptionWithFile(se, bw, logger);
        }

        resetConnectionAttributes();

        return psqlConnection;
    }

    void closeConnectionsUtil (HashMap<String, Connection> connectionMap, BufferedWriter bw, Logger logger) {
        connectionMap.forEach(
            (connectionAttribute, connection) -> {
                if (connection != null) {
                    try {
                        connection.close();
                    } catch (SQLException e) {
                        handleSQLExceptionWithFile(e, bw, logger);
                    }
                }
            }
        );
    }

    void closeConnections (BufferedWriter bw, Logger logger) {
        closeConnectionsUtil(tsqlConnectionMap, bw, logger);
        closeConnectionsUtil(psqlConnectionMap, bw, logger);
    }
}
