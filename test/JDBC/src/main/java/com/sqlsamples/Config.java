package com.sqlsamples;

import org.apache.log4j.*;

import java.io.*;
import java.util.Map;
import java.util.Properties;

import static java.util.Objects.isNull;

public class Config {
    
    static Properties properties = readConfig();
    static boolean compareWithFile = Boolean.parseBoolean(properties.getProperty("compareWithFile"));
    static String inputFilesDirectoryPath = properties.getProperty("inputFilesPath");
    static boolean runInParallel = Boolean.parseBoolean(properties.getProperty("runInParallel"));
    static boolean printLogsToConsole = Boolean.parseBoolean(properties.getProperty("printLogsToConsole"));
    static String JDBCDriver = properties.getProperty("driver");
    static boolean performanceTest = Boolean.parseBoolean(properties.getProperty("performanceTest"));
    static boolean outputColumnName = Boolean.parseBoolean(properties.getProperty("outputColumnName"));
    static boolean outputErrorCode = Boolean.parseBoolean(properties.getProperty("outputErrorCode"));
    static String scheduleFileName = properties.getProperty("scheduleFile");
    static String testFileRoot = properties.getProperty("testFileRoot");

    static String sqlServer_connectionString = constructConnectionString("sql");
    static String babel_connectionString = constructConnectionString("babel");
    static String fileGenerator_connectionString = constructConnectionString("fileGenerator");

    //read configuration from text file "config.txt" and load it as properties
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
                //try alternate path
                fis = new FileInputStream("src/main/resources/config.txt");
            }

            prop.load(fis);

            //override configuration if system environment variables are defined
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

    //configure properties of logger
    public static void configureLogger(Logger logger, String logFileName) throws IOException {

        if(compareWithFile){
            //disable logging if we are comparing against expected output
            logger.setLevel(Level.OFF);
        } else {
            logger.setLevel(Level.DEBUG);
            PatternLayout pattern = new PatternLayout("%m%n");
            FileAppender fileAppender = new FileAppender(pattern, logFileName+ ".log");
            logger.addAppender(fileAppender);

            if(printLogsToConsole){
                ConsoleAppender consoleAppender = new ConsoleAppender(pattern);
                logger.addAppender(consoleAppender);
            }
        }
    }

    //configure properties of summary logger
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
    
    private static String constructConnectionString(String prefix) {

        String URL = properties.getProperty(prefix + "_URL");
        String port = properties.getProperty(prefix + "_port");
        String databaseName = properties.getProperty(prefix + "_databaseName");
        String physicalDatabaseName = properties.getProperty(prefix + "_physicalDatabaseName");
        String user = properties.getProperty(prefix + "_user");
        String password = properties.getProperty(prefix + "_password");

        //return connection strings
        switch (prefix) {
            case "fileGenerator":
                if (JDBCDriver.equalsIgnoreCase("sqlserver")) {
                    String tsql_port = properties.getProperty(prefix + "_tsql_port");
                    return createSQLServerConnectionString(URL, tsql_port, databaseName, user, password);
                } else if (JDBCDriver.equalsIgnoreCase("postgresql")) {
                    String psql_port = properties.getProperty(prefix + "_psql_port");
                    return createPostgreSQLConnectionString(URL, psql_port, physicalDatabaseName, user, password);
                } else System.out.println("Incorrect driver specified in config.txt . Please specify either \"sqlserver\" or \"postgresql\"");
                break;
            case "sql":
            case "babel":
                return createSQLServerConnectionString(URL, port, databaseName, user, password);
        }
        
        return null;
    }
}
