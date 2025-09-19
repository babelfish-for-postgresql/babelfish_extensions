package com.sqlsamples;

import org.apache.logging.log4j.Logger;
import java.io.*;
import java.util.*;
import java.sql.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.Statistics.curr_exec_time;

public class JDBCBabelOutputConcurrency {
    static AtomicInteger errorCount = new AtomicInteger(0);
    
    private static String initializeConnectionString() {
        String url = properties.getProperty("URL");
        String port = properties.getProperty("tsql_port");
        String databaseName = properties.getProperty("databaseName");
        String user = properties.getProperty("user");
        String password = properties.getProperty("password");

        return createSQLServerConnectionString(url, port, databaseName, user, password);
    }

    public static void runTest(BufferedWriter bw, Logger logger) {
        long startTime = System.nanoTime();

        try {
            setupTestData(bw);
            babel_output_concurrency_test(bw);
            cleanupTestData(bw);
            
            if (errorCount.get() > 0) {
                bw.write("Test failed with " + errorCount.get() + " errors");
                bw.newLine();
            }
            else {
                bw.write("Test passed");
                bw.newLine();
            }
        } catch (Exception e) {
            try {
                bw.write(e.getMessage());
                bw.newLine();
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }

        long endTime = System.nanoTime();
        curr_exec_time = endTime - startTime;
    }
    
    private static void setupTestData(BufferedWriter bw) throws Exception {
        String connectionString = initializeConnectionString();
        try (Connection conn = DriverManager.getConnection(connectionString)) {
            Statement stmt = conn.createStatement();
            
            // Create test table
            stmt.execute("CREATE TABLE EmailPosts (EmailPostID INT, Param1 VARCHAR(50), LockProcessID INT DEFAULT 0)");
            stmt.execute("INSERT INTO EmailPosts VALUES (1, 'InitialValue', 100)");
            stmt.execute("INSERT INTO EmailPosts VALUES (2, NULL, 100)");
            
            bw.write("Test data created successfully");
            bw.newLine();
        }
    }
    
    private static void cleanupTestData(BufferedWriter bw) throws Exception {
        String connectionString = initializeConnectionString();
        try (Connection conn = DriverManager.getConnection(connectionString)) {
            Statement stmt = conn.createStatement();
            stmt.execute("DROP TABLE IF EXISTS EmailPosts");
        }
    }
    
    /*
     * This will be a concurrency test for OUTPUT clause operations to ensure no issues or crashes are encountered.
     */
    private static void babel_output_concurrency_test(BufferedWriter bw) throws Exception {
        String connectionString = initializeConnectionString();
        ArrayList<Connection> cxns = new ArrayList<>();
        ArrayList<Thread> threads = new ArrayList<>();

        /* Create connections for EPQ test */
        Connection conn1 = DriverManager.getConnection(connectionString);
        Connection conn2 = DriverManager.getConnection(connectionString);
        cxns.add(conn1);
        cxns.add(conn2);
        
        // Create EPQ scenario: Session 1 locks row, Session 2 waits and triggers EPQ
        CountDownLatch session1Ready = new CountDownLatch(1);
        CountDownLatch session1Commit = new CountDownLatch(1);
        
        threads.add(new Thread(new EPQSession1Worker(conn1, session1Ready, session1Commit, bw)));
        threads.add(new Thread(new EPQSession2Worker(conn2, session1Ready, session1Commit, bw)));
        
        for (Thread t : threads) {
            t.start();
        }
        
        for (Thread t : threads) {
            t.join();
        }
        
        for (Connection cxn : cxns) {
            cxn.close();
        }
    }
    
}

class EPQSession1Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQSession1Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
        this.conn = conn;
        this.session1Ready = session1Ready;
        this.session1Commit = session1Commit;
        this.bw = bw;
    }
    
    public void run() {
        try {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            
            // Session 1 - Start transaction and lock the row
            stmt.execute("UPDATE EmailPosts SET Param1 = 'ModifiedBySession1' WHERE EmailPostID = 1");
            
            // Signal that Session 1 has locked the row
            session1Ready.countDown();
            
            // Wait a bit to ensure Session 2 is blocked
            Thread.sleep(2000);
            
            // Commit to release lock and trigger EPQ in Session 2
            conn.commit();
            session1Commit.countDown();
            
        } catch (Exception e) {
            JDBCBabelOutputConcurrency.errorCount.incrementAndGet();
        }
    }
}

class EPQSession2Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQSession2Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
        this.conn = conn;
        this.session1Ready = session1Ready;
        this.session1Commit = session1Commit;
        this.bw = bw;
    }
    
    public void run() {
        try {
            // Wait for Session 1 to lock the row
            session1Ready.await();
            
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            
            // This will be blocked until Session 1 commits, then EPQ will process it
            stmt.execute("UPDATE EmailPosts SET LockProcessID = 7 " +
                       "OUTPUT deleted.Param1 as old_param1, inserted.Param1 as new_param1, " +
                       "deleted.LockProcessID as old_lock, inserted.LockProcessID as new_lock " +
                       "WHERE EmailPostID = 1");
            
            conn.commit();
            
        } catch (Exception e) {
            JDBCBabelOutputConcurrency.errorCount.incrementAndGet();
        }
    }
}

