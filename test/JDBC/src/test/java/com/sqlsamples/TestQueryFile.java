package com.sqlsamples;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import java.io.*;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.Date;
import java.util.stream.Stream;

import static com.sqlsamples.Config.*;

import static com.sqlsamples.Statistics.exec_times;

public class TestQueryFile {
    
    static String timestamp = new SimpleDateFormat("dd-MM-yyyy'T'HH:mm:ss.SSS").format(new Date());
    static String generatedFilesDirectoryPath = testFileRoot + "/expected/";
    static String sqlServerGeneratedFilesDirectoryPath = testFileRoot + "/sql_expected/";
    static String outputFilesDirectoryPath = testFileRoot + "/output/";
    static Logger summaryLogger = LogManager.getLogger("testSummaryLogger");    //logger to write summary of tests executed
    static Logger logger = LogManager.getLogger("eventLoggger");                //logger to log any test framework events
    static ArrayList<AbstractMap.SimpleEntry<String, Boolean>> summaryMap = new ArrayList<>(); //map to store test names and status
    static ArrayList<AbstractMap.SimpleEntry<String, ArrayList<Integer>>> testCountMap = new ArrayList<>(); //map to store test names and number of tests passed
    static ArrayList <String> fileList = new ArrayList<>();
    static HashMap<String, String> filePaths = new HashMap<>(); //map to store fileName and their paths
    static ArrayList<String> testsToRun = new ArrayList();
    static HashSet<String> testsToIgnore = new HashSet();
    static File diffFile;
    
    String inputFileName;
    Connection connection_bbl;  // connection object for Babel instance
    
    public static void createTestFilesListUtil(String directory, String testToRun) {
        File dir = new File(directory);

        File[] directoryListing = dir.listFiles();
        if (directoryListing != null) {
            for (File file : directoryListing) {

                if (file.getName().startsWith(".")) {
                    continue;
                }

                if (file.isDirectory()) {
                    createTestFilesListUtil(file.getAbsolutePath(), testToRun);
                } else {
                    // append filename to arraylist and omit extension
                    String fileName = file.getName().replaceFirst("[.][^.]+$", "");

                    if (testToRun.equals("all") || testToRun.equals(fileName)) {
                        fileList.add(fileName);
                        filePaths.put(fileName, file.getAbsolutePath());
                    }
                }
            }
        }
    }

    public static void createTestFilesList(String directory) {
        for(String testToRun : testsToRun) {
            /* prefix indicates it is a postgres command */
            if (testToRun.startsWith("cmd#!#")) {
                fileList.add(testToRun);
            }
            else if (testToRun.startsWith("ignore#!#")) {
                testsToIgnore.add(testToRun.split("#!#", -1)[1]);
            } else {
                createTestFilesListUtil(directory, testToRun);
            }
        }
    }

    public static void execCommand(String cmd) throws ClassNotFoundException {
        String[] command = cmd.split("#!#");

        String URL = properties.getProperty("URL");
        String tsql_port = properties.getProperty("tsql_port");
        String psql_port = properties.getProperty("psql_port");
        String databaseName = properties.getProperty("databaseName");
        String physicalDatabaseName = properties.getProperty("physicalDatabaseName");
        String user = properties.getProperty("user");
        String password = properties.getProperty("password");
        String connectionString;

        if (command[1].equalsIgnoreCase("sqlserver")) {
            /* if are trying to execute a t-sql command but we are using postgres driver */
            if(JDBCDriver.equalsIgnoreCase("postgresql")) {
                Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");     //use sql server driver
            }
            connectionString = createSQLServerConnectionString(URL, tsql_port, databaseName, user, password);
            summaryLogger.info("Execute T-SQL Command: " + command[2]);
        } else if (command[1].equalsIgnoreCase("postgresql")) {
            /* if are trying to execute a postgres command but we are using sqlserver driver */
            if(JDBCDriver.equalsIgnoreCase("sqlserver")) {
                Class.forName("org.postgresql.Driver");     //use postgres driver
            }
            connectionString = createPostgreSQLConnectionString(URL, psql_port, physicalDatabaseName, user, password);
            summaryLogger.info("Execute Postgres Command: " + command[2]);
        } else {
            summaryLogger.error("Invalid cmd type. Choose from \"sqlserver\" or \"postgresql\"");
            return;
        }

        try {
            DriverManager.getConnection(connectionString).createStatement().executeQuery(command[2]);
        } catch (SQLException e) {
            summaryLogger.error(e.getMessage());
        }

        /* use the driver specified in config.txt */
        selectDriver();
    }

    static void selectDriver() throws ClassNotFoundException {
        if (JDBCDriver.equalsIgnoreCase("postgresql")) {
            Class.forName("org.postgresql.Driver");
        } else if (JDBCDriver.equalsIgnoreCase("sqlserver")) {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        } else throw new ClassNotFoundException("Driver not found for: " + JDBCDriver +". Choose from either 'sqlserver' or 'postgresql'");
    }

    // test data is seeded from here
    static Stream<String> inputFileNames() {
        File dir = new File(inputFilesDirectoryPath);
        File scheduleFile = new File(scheduleFileName);
        
        try (BufferedReader br = new BufferedReader(new FileReader(scheduleFile))) {
            String line;
            while ((line = br.readLine()) != null) {
                if (!line.startsWith("#") && line.trim().length() > 0)
                    testsToRun.add(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        createTestFilesList(dir.getAbsolutePath());
        return fileList.stream();
    }

    // configure logger for summary file and setup initial directory structure
    @BeforeAll
    public static void setup() throws IOException {
        String testRunDir = "Info/" + timestamp + "/";
        new File(testRunDir).mkdirs();
        
        new File(outputFilesDirectoryPath).mkdirs();
        diffFile = new File(testRunDir + timestamp + ".diff");
        diffFile.createNewFile();
        
        String logSummaryFile = testRunDir + timestamp + "_runSummary";
        configureSummaryLogger(logSummaryFile, summaryLogger);

        String logFile = testRunDir + timestamp;
        configureLogger(logFile, logger);
        
        summaryLogger.info("Started test suite. Now running tests...");
    }
    
    // close connections that are not null after every test
    @AfterEach
    public void closeConnections() throws SQLException {
        if (connection_bbl != null) connection_bbl.close();
    }

    // write summary log after all tests have been executed
    @AfterAll
    public static void logSummary() {
        int passed = 0;
        int failed = 0;
        int maxlen = 0;
        String testStats = "";

        summaryLogger.info("All tests executed successfully!");

        summaryLogger.info("###########################################################################");
        summaryLogger.info("################################  SUMMARY  ################################");
        summaryLogger.info("###########################################################################");

        // get max length of test name (used for pretty print in logs)
        for(AbstractMap.SimpleEntry<String, Boolean> set: summaryMap){
            String testMethodName = set.getKey();
            int len = testMethodName.length();
            if(len > maxlen) maxlen = len;
        }
        
        // for every test in map, log test name and status
        int i;
        
        for (i = 0; i < summaryMap.size(); i++) {
            String testMethodName = summaryMap.get(i).getKey();

            boolean status = summaryMap.get(i).getValue();
            int testsPassed = 0, totalTests = 0;

            if(status){
                //extra spaces for right side padding
                summaryLogger.info((testMethodName + ":" + "                                                     ").substring(0, maxlen+2) + "Passed!" + testStats);
                passed++;
            }
            else{
                //extra spaces for right side padding
                summaryLogger.info((testMethodName + ":" + "                                                     ").substring(0, maxlen+2) + "Failed!" + testStats);
                failed++;
            }
        }

        summaryLogger.info("###########################################################################");
        summaryLogger.info("TOTAL TESTS:\t" + (passed + failed));
        summaryLogger.info("TESTS PASSED:\t" + passed);
        summaryLogger.info("TESTS FAILED:\t" + failed);
        summaryLogger.info("###########################################################################");
        
        if (performanceTest) {
            performanceSummary(exec_times);
        }
        
        // print absolute path to file containing diff
        if(failed > 0) {
            summaryLogger.info("Output diff can be found in '" + diffFile.getAbsolutePath() + "'");
        }

        // displays content of file holding diff to console
        if(printLogsToConsole) {
            System.out.println("############################# DIFF STARTS HERE #############################");
            try (BufferedReader br = new BufferedReader(new FileReader(diffFile))) {
                String line;
                while ((line = br.readLine()) != null) {
                    System.out.println(line);
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            System.out.println("############################## DIFF ENDS HERE ##############################");
        }
    }

    // generates performance report which has mean, median, mode of query execution times
    static void performanceSummary(ArrayList<Long> exec_times) {

        com.sqlsamples.Statistics stats = new com.sqlsamples.Statistics(exec_times.stream().filter(Objects::nonNull).mapToDouble(i -> i).toArray());

        HashMap <String, com.sqlsamples.Statistics> statisticsHashMap = new HashMap<String, com.sqlsamples.Statistics>() {
            {
                put(connectionString, stats);
            }
        };

        String testRunDir = "Info/" + timestamp + "/";

        String CSVFileName = testRunDir + timestamp + "_performanceReport";
        com.sqlsamples.ExportResults.createCSVFile(CSVFileName, statisticsHashMap);
    }
    
    private static boolean compareOutFiles (File outputFile, File expectedFile) {
        String outputFilePath = outputFile.getAbsolutePath();
        String expectedFilePath = expectedFile.getAbsolutePath();
        ProcessBuilder diffProcessBuilder;

        // if expected file is generated from SQL Server, do not compare error code and message
        if (expectedFilePath.contains("sql_expected")) {
            diffProcessBuilder = new ProcessBuilder("diff", "-a", "-u", "-I", "~~ERROR", expectedFilePath, outputFilePath);
        } else {
            diffProcessBuilder = new ProcessBuilder("diff", "-a", "-u", expectedFilePath, outputFilePath);
        }

        try {
            diffProcessBuilder.redirectError(ProcessBuilder.Redirect.appendTo(diffFile));
            diffProcessBuilder.redirectOutput(ProcessBuilder.Redirect.appendTo(diffFile));
            int exitCode = diffProcessBuilder.start().waitFor();
            
            switch (exitCode) {
                case 0:
                    return true;

                case 1:
                    return false;

                case 2:
                    System.out.println("There was some trouble when the diff command was executed!");
                    return false;

                default:
                    System.out.println("Unknown exit code encountered while running diff!");
                    return false;
            }
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        } 
        
        return false;
    }

    // parameterized test
    @ParameterizedTest(name="{0}")
    @MethodSource("inputFileNames")
    public void TestQueryBatch(String inputFileName) throws SQLException, ClassNotFoundException, Throwable {

        // if it is a command and not a fileName
        if (inputFileName.startsWith("cmd#!#")) {
            execCommand(inputFileName);
            return;
        } else if (testsToIgnore.contains(inputFileName)) {
            // if test is to be ignored, don't run it
            return;
        } else {
            selectDriver();
            connection_bbl = DriverManager.getConnection(connectionString);
        }

        summaryLogger.info("RUNNING " + inputFileName);

        logger.info("Running " + inputFileName + "...");

        String testFilePath = filePaths.get(inputFileName);
        
        boolean result; // whether test passed or failed
        int failed;
        
        File outputFile = new File(outputFilesDirectoryPath + inputFileName + ".out");

        // generate buffer reader associated with the file
        FileWriter fw = new FileWriter(outputFile);
        BufferedWriter bw = new BufferedWriter(fw);
        batch_run.batch_run_sql(connection_bbl, bw, testFilePath, logger);
        bw.close();
        
        File expectedFile = new File(generatedFilesDirectoryPath + inputFileName + ".out");
        File sqlExpectedFile = new File(sqlServerGeneratedFilesDirectoryPath + inputFileName + ".out");

        if (expectedFile.exists()) {
            // get the diff
            result = compareOutFiles(outputFile, expectedFile);
        } else if (sqlExpectedFile.exists()) {
            // get the diff
            result = compareOutFiles(outputFile, sqlExpectedFile);
        } else {
            result = false;
        }

        summaryMap.add(new AbstractMap.SimpleEntry<>(inputFileName, result)); //add test name and result to map

        try {
            Assertions.assertTrue(result);
        } catch (AssertionError e) {
            Throwable throwable = new Throwable(inputFileName + " FAILED! Output diff can be found in '" + diffFile.getAbsolutePath() + "'");
            throwable.setStackTrace(new StackTraceElement[0]);
            throw throwable;
        }
    }
}
