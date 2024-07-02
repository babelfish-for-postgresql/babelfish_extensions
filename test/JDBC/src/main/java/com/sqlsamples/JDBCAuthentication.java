package com.sqlsamples;

import org.apache.logging.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCAuthentication {
    
    void javaAuthentication(String strLine, BufferedWriter bw, Logger logger) {
        
        // Convert .NET input file format for authentication to JDBC
        String[] result = strLine.split("#!#");

        Properties connectionPropertiesBabel = new Properties();

        // get default values from current connection
        connectionPropertiesBabel.put("serverName", properties.getProperty("URL"));

        if (JDBCDriver.equalsIgnoreCase("sqlserver")) {
            connectionPropertiesBabel.put("portNumber", properties.getProperty("tsql_port"));
        }
        if (JDBCDriver.equalsIgnoreCase("postgresql")) {
            connectionPropertiesBabel.put("portNumber", properties.getProperty("psql_port"));
        }

        connectionPropertiesBabel.put("database", properties.getProperty("databaseName"));
        connectionPropertiesBabel.put("user", properties.getProperty("user"));
        connectionPropertiesBabel.put("password", properties.getProperty("password"));

        String port = "";

        if (JDBCDriver.equalsIgnoreCase("sqlserver")) {
            port = properties.getProperty("tsql_port");
        }
        if (JDBCDriver.equalsIgnoreCase("postgresql")) {
            port = properties.getProperty("psql_port");
        }

        if (useJTDSInsteadOfMSSQLJDBC) {
            connectionPropertiesBabel.put("url", "jdbc:jtds:sqlserver://" + properties.getProperty("URL") + ":" + port);
        } else {
            connectionPropertiesBabel.put("url", "jdbc:sqlserver://" + properties.getProperty("URL") + ":" + port);
        }

        String other_prop = "";

        String connectionString_babel = createConnectionString(result, connectionPropertiesBabel, other_prop);

        try {
            bw.write(strLine);
            bw.newLine();

            // establish connection using connection string
            Connection connection = DriverManager.getConnection(connectionString_babel);
                
            bw.write("~~SUCCESS~~");
            bw.newLine();

            connection.close();
                
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException ioe) {
            logger.error("IO Exception: " + ioe.getMessage(), ioe);
        }
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

        if (useJTDSInsteadOfMSSQLJDBC) {
            return connectionPropertiesBabel.get("url")
                    + "/" + connectionPropertiesBabel.get("database")
                    + ";" + "user=" + connectionPropertiesBabel.get("user")
                    + ";" + "password=" + connectionPropertiesBabel.get("password")
                    + ";" + other_prop;
        } else {
            return connectionPropertiesBabel.get("url")
                    + ";" + "databaseName=" + connectionPropertiesBabel.get("database")
                    + ";" + "user=" + connectionPropertiesBabel.get("user")
                    + ";" + "password=" + connectionPropertiesBabel.get("password")
                    + ";" + other_prop;
        }
    }
}
