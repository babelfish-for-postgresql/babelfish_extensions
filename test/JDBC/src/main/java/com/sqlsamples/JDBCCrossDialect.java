package com.sqlsamples;

import java.util.*;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import static com.sqlsamples.Config.*;

public class JDBCCrossDialect {

    String URL = properties.getProperty("fileGenerator_URL");
    String tsql_port = properties.getProperty("fileGenerator_tsql_port");
    String psql_port = properties.getProperty("fileGenerator_psql_port");
    String databaseName = properties.getProperty("fileGenerator_databaseName");
    String physicalDatabaseName = properties.getProperty("fileGenerator_physicalDatabaseName");
    String user = properties.getProperty("fileGenerator_user");
    String password = properties.getProperty("fileGenerator_password");

    //Key is the username, password and database name concatenated
    //Value is the connection object craeted using the above 3 attributes
    HashMap<String, Connection> tsqlConnectionMap = new HashMap<>();
    HashMap<String, Connection> psqlConnectionMap = new HashMap<>();

    String newUser = null;
    String newPassword = null;
    String newDatabase = null;
    String newPhysicalDatabase = null;
    String searchPath = null;

    JDBCCrossDialect (Connection connection) {

        //Add already established connection to appropriate hash map
        if (JDBCDriver.equalsIgnoreCase("sqlserver"))
            tsqlConnectionMap.put(user, connection);

        if (JDBCDriver.equalsIgnoreCase("postgresql"))
            psqlConnectionMap.put(user, connection);
    }

    void getConnectionAttributes (String strLine) {
        //Extract username, password and database from string
        String[] connAttributes = strLine.split("\\s+");

        //First two elements of array will be "--" and ("tsql" or "psql")
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

        //If a connection attribute is not provided, we take the value from config file
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

    Connection getTsqlConnection (String strLine) {

        Connection tsqlConnection = null;

        getConnectionAttributes(strLine);

        try {
            //Use sqlserver JDBC driver
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

            //if we already have opened a tsql connection then reuse that
            tsqlConnection = tsqlConnectionMap.get(newUser + newPassword + newDatabase);

            if (tsqlConnection == null) {
                //Create a new connection on tsql port and use that
                String connectionString = createSQLServerConnectionString(URL, tsql_port, newDatabase, newUser, newPassword);
                tsqlConnection = DriverManager.getConnection(connectionString);

                tsqlConnectionMap.put(newUser + newPassword + newDatabase, tsqlConnection);
            }

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
        }

        resetConnectionAttributes();

        return tsqlConnection;
    }

    Connection getPsqlConnection (String strLine) {

        Connection psqlConnection = null;

        getConnectionAttributes(strLine);

        try {
            //Use postgresql JDBC driver
            Class.forName("org.postgresql.Driver");

            //if we already have opened a psql connection then reuse that
            psqlConnection = psqlConnectionMap.get(newUser + newPassword + newPhysicalDatabase + searchPath);

            //Create a new connection on psql port and use that
            if (psqlConnection == null) {
                String connectionString = createPostgreSQLConnectionString(URL, psql_port, newPhysicalDatabase, newUser, newPassword);

                if (searchPath != null) {
                    connectionString += ("&currentSchema=" + searchPath);
                }
                psqlConnection = DriverManager.getConnection(connectionString);

                psqlConnectionMap.put(newUser + newPassword + newPhysicalDatabase + searchPath, psqlConnection);
            }

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
        }

        resetConnectionAttributes();

        return psqlConnection;
    }

    void closeConnectionsUtil (HashMap<String, Connection> connectionMap) {
        connectionMap.forEach(
            (connectionAttribute, connection) -> {
                if (connection != null) {
                    try {
                        connection.close();
                    } catch (SQLException e) {
                        e.printStackTrace();
                    }
                }
            }
        );
    }

    void closeConnections () {
        closeConnectionsUtil(tsqlConnectionMap);
        closeConnectionsUtil(psqlConnectionMap);
    }
}
