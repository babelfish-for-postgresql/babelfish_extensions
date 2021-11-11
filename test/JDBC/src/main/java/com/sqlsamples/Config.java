package com.sqlsamples;

import org.apache.log4j.*;

import java.io.*;
import java.util.Map;
import java.util.Properties;

import static java.util.Objects.isNull;

public class Config {
    
    static Properties properties = readConfig();
    static String inputFilesDirectoryPath = properties.getProperty("inputFilesPath");
    static boolean printLogsToConsole = Boolean.parseBoolean(properties.getProperty("printLogsToConsole"));
    static String JDBCDriver = properties.getProperty("driver");
    static boolean performanceTest = Boolean.parseBoolean(properties.getProperty("performanceTest"));
    static boolean outputColumnName = Boolean.parseBoolean(properties.getProperty("outputColumnName"));
    static boolean outputErrorCode = Boolean.parseBoolean(properties.getProperty("outputErrorCode"));
    static String scheduleFileName = properties.getProperty("scheduleFile");
    static String testFileRoot = properties.getProperty("testFileRoot");

    static String connectionString = constructConnectionString();

    // read configuration from text file "config.txt" and load it as properties
    static Properties readConfig() {
        Properties prop = new Properties();
        String filePath = System.getProperty("babel-config-file");
        if (filePath == null){
            filePath = "resources/config.txt";
        }
        
        try {
            File file = new File(filePath);
            FileInputStream fis;

            if (file.isFile()) {
                fis = new FileInputStream(file);
            } else {
                // try alternate path
                fis = new FileInputStream("src/main/resources/config.txt");
            }

            prop.load(fis);

            // override configuration if system environment variables are defined
            String env, property;

            for(Map.Entry<Object, Object> entry : prop.entrySet()){
                property = entry.getKey().toString();
                env = System.getenv(property);
                if (isNull(env)) {
                    env = System.getProperty(property);
                }

                if(!isNull(env)) {
                    prop.put(property, env);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        return prop;
    }

    // configure properties of logger
    public static void configureLogger(String logFileName, Logger logger) throws IOException {
        logger.setLevel(Level.ERROR);
        PatternLayout pattern = new PatternLayout("%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p - %m%n");
        FileAppender fileAppender = new FileAppender(pattern, logFileName+ ".log");
        logger.addAppender(fileAppender);
    }

    // configure properties of summary logger
    public static void configureSummaryLogger(String logFileName, Logger summaryLogger) throws IOException {
        Logger.getRootLogger().setLevel(Level.DEBUG);
        PatternLayout pattern = new PatternLayout("%m%n");
        FileAppender fileAppender = new FileAppender(pattern, logFileName+ ".log");
        ConsoleAppender consoleAppender = new ConsoleAppender(pattern);
        summaryLogger.addAppender(fileAppender);
        summaryLogger.addAppender(consoleAppender);
    }
    
    static String createSQLServerConnectionString(String URL, String port, String databaseName, String user, String password) {
        return "jdbc:sqlserver://" + URL + ":" + port + ";" + "databaseName="
                + databaseName + ";" + "user=" + user + ";" + "password=" + password;
    }

    static String createPostgreSQLConnectionString(String URL, String port, String databaseName, String user, String password) {
        return "jdbc:postgresql://" + URL + ":" + port + "/"
                + databaseName + "?" + "user=" + user + "&" + "password=" + password;
    }
    
    private static String constructConnectionString() {

        String URL = properties.getProperty("URL");
        String port = properties.getProperty("port");
        String databaseName = properties.getProperty("databaseName");
        String physicalDatabaseName = properties.getProperty("physicalDatabaseName");
        String user = properties.getProperty("user");
        String password = properties.getProperty("password");

        // return connection strings
        if (JDBCDriver.equalsIgnoreCase("sqlserver")) {
            String tsql_port = properties.getProperty("tsql_port");
            return createSQLServerConnectionString(URL, tsql_port, databaseName, user, password);
        } else if (JDBCDriver.equalsIgnoreCase("postgresql")) {
            String psql_port = properties.getProperty("psql_port");
            return createPostgreSQLConnectionString(URL, psql_port, physicalDatabaseName, user, password);
        } else System.out.println("Incorrect driver specified in config.txt . Please specify either \"sqlserver\" or \"postgresql\"");
        
        return null;
    }
}
