package com.sqlsamples;

import org.apache.logging.log4j.*;
import org.apache.logging.log4j.core.LoggerContext;
import org.apache.logging.log4j.core.appender.*;
import org.apache.logging.log4j.core.config.AppenderRef;
import org.apache.logging.log4j.core.config.Configuration;
import org.apache.logging.log4j.core.config.Configurator;
import org.apache.logging.log4j.core.config.LoggerConfig;
import org.apache.logging.log4j.core.layout.PatternLayout;

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
        LoggerContext context = LoggerContext.getContext(false);
        Configuration config = context.getConfiguration();

        PatternLayout pattern = PatternLayout.newBuilder().withPattern("%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p - %m%n").build();
        FileAppender fileAppender = FileAppender.newBuilder().setName("fileAppender").setLayout(pattern).withFileName(logFileName+ ".log").build();

        AppenderRef ref = AppenderRef.createAppenderRef("fileAppender", null, null);
        AppenderRef[] refs = new AppenderRef[] { ref };
        LoggerConfig loggerConfig = LoggerConfig.createLogger(false, Level.ERROR, logger.getName(), null, refs, null, config, null);
        loggerConfig.addAppender(fileAppender, null, null);

        config.addLogger(logger.getName(), loggerConfig); /* 2 */
        context.updateLoggers();
    }

    // configure properties of summary logger
    public static void configureSummaryLogger(String logFileName, Logger summaryLogger) throws IOException {
        Logger rootLogger = LogManager.getRootLogger();
        Configurator.setLevel(rootLogger.getName(), Level.DEBUG);

        LoggerContext context = LoggerContext.getContext(false);
        Configuration config = context.getConfiguration();

        PatternLayout pattern = PatternLayout.newBuilder().withPattern("%m%n").build();
        FileAppender fileAppender = FileAppender.newBuilder().setName("summaryFileAppender").setLayout(pattern).withFileName(logFileName+ ".log").build();
        ConsoleAppender consoleAppender = ConsoleAppender.newBuilder().setName("summaryConsoleAppender").setLayout(pattern).build();

        AppenderRef fileRef = AppenderRef.createAppenderRef("summaryFileAppender", null, null);
        AppenderRef consoleRef = AppenderRef.createAppenderRef("summaryConsoleAppender", null, null);

        AppenderRef[] refs = new AppenderRef[] { fileRef, consoleRef };
        LoggerConfig loggerConfig = LoggerConfig.createLogger(false, summaryLogger.getLevel(), summaryLogger.getName(), null, refs, null, config, null);
        loggerConfig.addAppender(fileAppender, null, null);
        loggerConfig.addAppender(consoleAppender, null, null);

        config.addLogger(summaryLogger.getName(), loggerConfig);
        context.updateLoggers();
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
