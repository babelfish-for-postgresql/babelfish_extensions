package com.sqlsamples;

import org.apache.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCAuthentication {
    
    boolean javaAuthentication(String strLine, BufferedWriter bw, Logger logger) {

        //Properties prop = readConfig("config.txt");  //properties object with configuration info
        
        // Convert .NET input file format for authentication to JDBC
        String[] result = strLine.split("#!#");

        Properties connectionPropertiesBabel = new Properties();

        if(!compareWithFile){
            Properties connectionPropertiesSql = new Properties();

            // get default values from current connection for Sql server
            connectionPropertiesSql.put("serverName", properties.getProperty("sql_URL"));
            connectionPropertiesSql.put("portNumber", properties.getProperty("sql_port"));
            connectionPropertiesSql.put("database", properties.getProperty("sql_databaseName"));
            connectionPropertiesSql.put("user", properties.getProperty("sql_user"));
            connectionPropertiesSql.put("password", properties.getProperty("sql_password"));
            connectionPropertiesSql.put("url", "jdbc:sqlserver://" + properties.getProperty("sql_URL") + ":" + properties.getProperty("sql_port"));

            // get default values from current connection for Babel
            connectionPropertiesBabel.put("serverName", properties.getProperty("babel_URL"));
            connectionPropertiesBabel.put("portNumber", properties.getProperty("babel_port"));
            connectionPropertiesBabel.put("database", properties.getProperty("babel_databaseName"));
            connectionPropertiesBabel.put("user", properties.getProperty("babel_user"));
            connectionPropertiesBabel.put("password", properties.getProperty("babel_password"));
            connectionPropertiesBabel.put("url", "jdbc:sqlserver://" + properties.getProperty("babel_URL") + ":" + properties.getProperty("babel_port"));

            String other_prop = "";

            String connectionString_sql = createConnectionString(result, connectionPropertiesSql, other_prop);
            String connectionString_babel = createConnectionString(result, connectionPropertiesBabel, other_prop);

            logger.info("Establishing connection with the connection string: " + connectionString_sql);
            logger.info("Establishing connection with the connection string: " + connectionString_babel);

            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                // establish connection using connection string
                DriverManager.getConnection(connectionString_sql);
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                // establish connection using connection string
                DriverManager.getConnection(connectionString_babel);
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
            } else {
                logger.info("Both connections created successfully!");
            }
        } else {
            // get default values from current connection
            connectionPropertiesBabel.put("serverName", properties.getProperty("fileGenerator_URL"));

            if (JDBCDriver.equalsIgnoreCase("sqlserver")) {
                connectionPropertiesBabel.put("portNumber", properties.getProperty("fileGenerator_tsql_port"));
            }
            if (JDBCDriver.equalsIgnoreCase("postgresql")) {
                connectionPropertiesBabel.put("portNumber", properties.getProperty("fileGenerator_psql_port"));
            }

            connectionPropertiesBabel.put("database", properties.getProperty("fileGenerator_databaseName"));
            connectionPropertiesBabel.put("user", properties.getProperty("fileGenerator_user"));
            connectionPropertiesBabel.put("password", properties.getProperty("fileGenerator_password"));

            String port = "";

            if (JDBCDriver.equalsIgnoreCase("sqlserver")) {
                port = properties.getProperty("fileGenerator_tsql_port");
            }
            if (JDBCDriver.equalsIgnoreCase("postgresql")) {
                port = properties.getProperty("fileGenerator_psql_port");
            }

            connectionPropertiesBabel.put("url", "jdbc:sqlserver://" + properties.getProperty("fileGenerator_URL") + ":" + port);

            String other_prop = "";

            String connectionString_babel = createConnectionString(result, connectionPropertiesBabel, other_prop);

            try {
                bw.write(strLine);
                bw.newLine();

                // establish connection using connection string
                DriverManager.getConnection(connectionString_babel);
                
                bw.write("~~SUCCESS~~");
                bw.newLine();
                
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            } catch (IOException ioe) {
                ioe.printStackTrace();
                return false;
            }
        }
        
        return true;
    }

    private String createConnectionString(String[] result, Properties connectionPropertiesBabel, String other_prop) {
        for (int i = 1; i < result.length; i++) {
            if (result[i].startsWith("others")) {
                other_prop = result[i].replaceFirst("others\\|-\\|", "");
            } else {
                String[] property = result[i].split("\\|-\\|", -1);
                connectionPropertiesBabel.put(property[0], property[1]);
            }
        }

        return connectionPropertiesBabel.get("url")
                + ";" + "databaseName=" + connectionPropertiesBabel.get("database")
                + ";" + "user=" + connectionPropertiesBabel.get("user")
                + ";" + "password=" + connectionPropertiesBabel.get("password")
                + ";" + other_prop;
    }
}
