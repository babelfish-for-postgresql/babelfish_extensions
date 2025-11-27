/*
 * This will be a concurrency test for OUTPUT clause operations to ensure no issues or crashes are encountered.
 * Tests EPQ (EvalPlanQual) handling with OUTPUT clauses in concurrent scenarios.
 */

package com.sqlsamples;

import org.apache.logging.log4j.Logger;
import java.io.*;
import java.util.*;
import java.sql.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.Statistics.curr_exec_time;

public class BabelOutputClauseConcurrencyTest {
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
            stmt.execute("CREATE TABLE TestTable_jira_4880 (TestID INT, Param1 VARCHAR(50), LockProcessID INT DEFAULT 0)");
            stmt.execute("INSERT INTO TestTable_jira_4880 VALUES (1, 'InitialValue', 100)");
            stmt.execute("INSERT INTO TestTable_jira_4880 VALUES (2, NULL, 100)");
            
            bw.write("Test data created successfully");
            bw.newLine();
        }
    }
    
    private static void cleanupTestData(BufferedWriter bw) throws Exception {
        String connectionString = initializeConnectionString();
        try (Connection conn = DriverManager.getConnection(connectionString)) {
            Statement stmt = conn.createStatement();
            stmt.execute("DROP TABLE IF EXISTS TestTable_jira_4880");
        }
    }
    
    
    private static void babel_output_concurrency_test(BufferedWriter bw) throws Exception {
        String connectionString = initializeConnectionString();
        
        // Test 1: UPDATE with OUTPUT EPQ
        test_update_output_epq(connectionString, bw);
        bw.write("Test Case 1 completed: UPDATE with OUTPUT EPQ");
        bw.newLine();
        
        // Test 2: DELETE with OUTPUT EPQ
        test_delete_output_epq(connectionString, bw);
        bw.write("Test Case 2 completed: DELETE with OUTPUT EPQ");
        bw.newLine();
        
        // Test 3: INSERT with OUTPUT during concurrent operations
        test_insert_output_concurrent(connectionString, bw);
        bw.write("Test Case 3 completed: INSERT with OUTPUT during concurrent operations");
        bw.newLine();
        
        // Test 4: Mixed DML - INSERT, UPDATE, DELETE in sequence
        test_mixed_dml_output(connectionString, bw);
        bw.write("Test Case 4 completed: Mixed DML - INSERT, UPDATE, DELETE in sequence");
        bw.newLine();
    }
    
    /*
     * Test Case 1: UPDATE with OUTPUT EPQ
     * Verifying: EPQ correctly re-evaluates row after concurrent modification and OUTPUT shows updated values
     * Success Criteria: OUTPUT displays Session1's modified Param1 value in both deleted and inserted columns
     */
    private static void test_update_output_epq(String connectionString, BufferedWriter bw) throws Exception {
        ArrayList<Connection> cxns = new ArrayList<>();
        ArrayList<Thread> threads = new ArrayList<>();

        Connection conn1 = DriverManager.getConnection(connectionString);
        Connection conn2 = DriverManager.getConnection(connectionString);
        cxns.add(conn1);
        cxns.add(conn2);
        
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
    
    /*
     * Test Case 2: DELETE with OUTPUT EPQ
     * Verifying: DELETE with OUTPUT processes EPQ-updated row values from concurrent session
     * Success Criteria: OUTPUT shows Session1's updated Param1 value ('UpdatedBeforeDelete') in deleted row
     */
    private static void test_delete_output_epq(String connectionString, BufferedWriter bw) throws Exception {
        ArrayList<Connection> cxns = new ArrayList<>();
        ArrayList<Thread> threads = new ArrayList<>();

        Connection conn1 = DriverManager.getConnection(connectionString);
        Connection conn2 = DriverManager.getConnection(connectionString);
        cxns.add(conn1);
        cxns.add(conn2);
        
        // Insert test data for DELETE test
        try (Statement stmt = conn1.createStatement()) {
            stmt.execute("INSERT INTO TestTable_jira_4880 VALUES (2, 'ToBeDeleted', 200)");
        }
        
        CountDownLatch session1Ready = new CountDownLatch(1);
        CountDownLatch session1Commit = new CountDownLatch(1);
        
        threads.add(new Thread(new EPQDeleteSession1Worker(conn1, session1Ready, session1Commit, bw)));
        threads.add(new Thread(new EPQDeleteSession2Worker(conn2, session1Ready, session1Commit, bw)));
        
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
    
    /*
     * Test Case 3: INSERT with OUTPUT during concurrent operations
     * Verifying: INSERT with OUTPUT executes successfully despite concurrent lock contention
     * Success Criteria: OUTPUT returns inserted values (TestID=4, Param1='ConcurrentInsert', LockProcessID=400)
     */
    private static void test_insert_output_concurrent(String connectionString, BufferedWriter bw) throws Exception {
        ArrayList<Connection> cxns = new ArrayList<>();
        ArrayList<Thread> threads = new ArrayList<>();

        Connection conn1 = DriverManager.getConnection(connectionString);
        Connection conn2 = DriverManager.getConnection(connectionString);
        cxns.add(conn1);
        cxns.add(conn2);
        
        CountDownLatch session1Ready = new CountDownLatch(1);
        CountDownLatch session1Commit = new CountDownLatch(1);
        
        threads.add(new Thread(new EPQInsertSession1Worker(conn1, session1Ready, session1Commit, bw)));
        threads.add(new Thread(new EPQInsertSession2Worker(conn2, session1Ready, session1Commit, bw)));
        
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
    
    /*
     * Test Case 4: Mixed DML with OUTPUT clauses
     * Verifying: Sequential INSERT/UPDATE/DELETE with OUTPUT under EPQ conditions in single transaction
     * Success Criteria: All three OUTPUT operations return correct values, UPDATE/DELETE show EPQ-processed data
     */
    private static void test_mixed_dml_output(String connectionString, BufferedWriter bw) throws Exception {
        ArrayList<Connection> cxns = new ArrayList<>();
        ArrayList<Thread> threads = new ArrayList<>();

        Connection conn1 = DriverManager.getConnection(connectionString);
        Connection conn2 = DriverManager.getConnection(connectionString);
        cxns.add(conn1);
        cxns.add(conn2);
        
        // Add Param2 column for NULL alignment test
        try (Statement stmt = conn1.createStatement()) {
            try {
                stmt.execute("ALTER TABLE TestTable_jira_4880 ADD Param2 VARCHAR(50)");
            } catch (SQLException e) {
                // Column might already exist, ignore
            }
            // Ensure record 3 exists for the test
            stmt.execute("DELETE FROM TestTable_jira_4880 WHERE TestID = 3");
            stmt.execute("INSERT INTO TestTable_jira_4880 (TestID, Param1, LockProcessID, Param2) VALUES (3, 'TestRecord', 300, NULL)");
        }
        
        CountDownLatch session1Ready = new CountDownLatch(1);
        CountDownLatch session1Commit = new CountDownLatch(1);
        
        threads.add(new Thread(new EPQMixedSession1Worker(conn1, session1Ready, session1Commit, bw)));
        threads.add(new Thread(new EPQMixedSession2Worker(conn2, session1Ready, session1Commit, bw)));
        
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
            stmt.execute("UPDATE TestTable_jira_4880 SET Param1 = 'ModifiedBySession1' WHERE TestID = 1");
            
            // Signal that Session 1 has locked the row
            session1Ready.countDown();
            
            // Wait a bit to ensure Session 2 is blocked
            Thread.sleep(2000);
            
            // Commit to release lock and trigger EPQ in Session 2
            conn.commit();
            session1Commit.countDown();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
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
            ResultSet rs = stmt.executeQuery("UPDATE TestTable_jira_4880 SET LockProcessID = 7 " +
                       "OUTPUT deleted.Param1 as old_param1, inserted.Param1 as new_param1, " +
                       "deleted.LockProcessID as old_lock, inserted.LockProcessID as new_lock " +
                       "WHERE TestID = 1");
            
            bw.write("=== Test Case 1: UPDATE with OUTPUT EPQ ===");
            bw.newLine();
            bw.write("Description: Tests EPQ handling when UPDATE with OUTPUT clause is blocked by concurrent transaction");
            bw.newLine();
            bw.write("UPDATE OUTPUT Results:");
            bw.newLine();
            while (rs.next()) {
                bw.write("old_param1: " + rs.getString("old_param1") + ", new_param1: " + rs.getString("new_param1") + 
                        ", old_lock: " + rs.getInt("old_lock") + ", new_lock: " + rs.getInt("new_lock"));
                bw.newLine();
            }
            rs.close();
            
            conn.commit();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
        }
    }
}

class EPQDeleteSession1Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQDeleteSession1Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
        this.conn = conn;
        this.session1Ready = session1Ready;
        this.session1Commit = session1Commit;
        this.bw = bw;
    }
    
    public void run() {
        try {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            
            // Session 1 - Update the row that will be deleted by Session 2
            stmt.execute("UPDATE TestTable_jira_4880 SET Param1 = 'UpdatedBeforeDelete' WHERE TestID = 2");
            
            // Signal that Session 1 has locked the row
            session1Ready.countDown();
            
            // Wait to ensure Session 2 is blocked
            Thread.sleep(2000);
            
            // Commit to trigger EPQ in Session 2
            conn.commit();
            session1Commit.countDown();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
        }
    }
}

class EPQDeleteSession2Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQDeleteSession2Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
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
            
            // DELETE with OUTPUT - should see EPQ-processed values
            ResultSet rs = stmt.executeQuery("DELETE FROM TestTable_jira_4880 " +
                       "OUTPUT deleted.Param1, deleted.LockProcessID " +
                       "WHERE TestID = 2");
            
            bw.write("=== Test Case 2: DELETE with OUTPUT EPQ ===");
            bw.newLine();
            bw.write("Description: Tests EPQ handling when DELETE with OUTPUT clause processes updated row values");
            bw.newLine();
            bw.write("DELETE OUTPUT Results:");
            bw.newLine();
            while (rs.next()) {
                bw.write("Param1: " + rs.getString("Param1") + ", LockProcessID: " + rs.getInt("LockProcessID"));
                bw.newLine();
            }
            rs.close();
            
            conn.commit();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
        }
    }
}

class EPQInsertSession1Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQInsertSession1Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
        this.conn = conn;
        this.session1Ready = session1Ready;
        this.session1Commit = session1Commit;
        this.bw = bw;
    }
    
    public void run() {
        try {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            
            // Session 1 - Create lock contention
            stmt.execute("UPDATE TestTable_jira_4880 SET LockProcessID = 999 WHERE TestID = 1");
            
            // Signal that Session 1 has created lock contention
            session1Ready.countDown();
            
            // Keep transaction open for a while
            Thread.sleep(2000);
            
            // Commit to release lock
            conn.commit();
            session1Commit.countDown();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
        }
    }
}

class EPQInsertSession2Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQInsertSession2Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
        this.conn = conn;
        this.session1Ready = session1Ready;
        this.session1Commit = session1Commit;
        this.bw = bw;
    }
    
    public void run() {
        try {
            // Wait for Session 1 to create lock contention
            session1Ready.await();
            
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            
            // INSERT with OUTPUT during concurrent operations
            ResultSet rs = stmt.executeQuery("INSERT INTO TestTable_jira_4880 (TestID, Param1, LockProcessID) " +
                       "OUTPUT inserted.TestID, inserted.Param1, inserted.LockProcessID " +
                       "VALUES (4, 'ConcurrentInsert', 400)");
            
            bw.write("=== Test Case 3: INSERT with OUTPUT during concurrent operations ===");
            bw.newLine();
            bw.write("Description: Tests INSERT with OUTPUT clause execution during concurrent lock contention");
            bw.newLine();
            bw.write("INSERT OUTPUT Results:");
            bw.newLine();
            while (rs.next()) {
                bw.write("TestID: " + rs.getInt("TestID") + ", Param1: " + rs.getString("Param1") + 
                        ", LockProcessID: " + rs.getInt("LockProcessID"));
                bw.newLine();
            }
            rs.close();
            
            conn.commit();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
        }
    }
}

class EPQMixedSession1Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQMixedSession1Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
        this.conn = conn;
        this.session1Ready = session1Ready;
        this.session1Commit = session1Commit;
        this.bw = bw;
    }
    
    public void run() {
        try {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            
            // Complex transaction affecting multiple rows
            stmt.execute("UPDATE TestTable_jira_4880 SET Param1 = 'Session1Modified' WHERE TestID IN (1, 2, 3)");
            stmt.execute("UPDATE TestTable_jira_4880 SET Param2 = NULL WHERE TestID = 1");
            
            // Signal that Session 1 has locked rows
            session1Ready.countDown();
            
            // Keep transaction open for mixed DML operations
            Thread.sleep(3000);
            
            // Commit to trigger EPQ for UPDATE and DELETE
            conn.commit();
            session1Commit.countDown();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
            try {
                bw.write("EPQMixedSession1Worker error: " + e.getMessage());
                bw.newLine();
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }
    }
}

class EPQMixedSession2Worker implements Runnable {
    private final Connection conn;
    private final CountDownLatch session1Ready;
    private final CountDownLatch session1Commit;
    private final BufferedWriter bw;
    
    EPQMixedSession2Worker(Connection conn, CountDownLatch session1Ready, CountDownLatch session1Commit, BufferedWriter bw) {
        this.conn = conn;
        this.session1Ready = session1Ready;
        this.session1Commit = session1Commit;
        this.bw = bw;
    }
    
    public void run() {
        try {
            // Wait for Session 1 to lock rows
            session1Ready.await();
            
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            
            // First: INSERT new record
            ResultSet rs1 = stmt.executeQuery("INSERT INTO TestTable_jira_4880 (TestID, Param1, LockProcessID) " +
                       "OUTPUT inserted.TestID, inserted.Param1, inserted.LockProcessID " +
                       "VALUES (5, 'NewRecord', 500)");
            
            bw.write("=== Test Case 4: Mixed DML with OUTPUT clauses ===");
            bw.newLine();
            bw.write("Description: Tests sequence of INSERT, UPDATE, DELETE with OUTPUT clauses under EPQ conditions");
            bw.newLine();
            bw.write("Mixed DML - INSERT OUTPUT Results:");
            bw.newLine();
            while (rs1.next()) {
                bw.write("TestID: " + rs1.getInt("TestID") + ", Param1: " + rs1.getString("Param1") + 
                        ", LockProcessID: " + rs1.getInt("LockProcessID"));
                bw.newLine();
            }
            rs1.close();
            
            // Second: UPDATE existing record (will trigger EPQ)
            ResultSet rs2 = stmt.executeQuery("UPDATE TestTable_jira_4880 " +
                       "SET LockProcessID = TestTable_jira_4880.LockProcessID + 100, Param1 = 'EPQ_Updated' " +
                       "OUTPUT deleted.TestID, deleted.Param1 as old_param, " +
                       "deleted.LockProcessID as old_lock, " +
                       "inserted.TestID, inserted.Param1 as new_param, " +
                       "inserted.LockProcessID as new_lock " +
                       "WHERE TestID = 1");
            
            bw.write("Mixed DML - UPDATE OUTPUT Results:");
            bw.newLine();
            while (rs2.next()) {
                bw.write("deleted - TestID: " + rs2.getInt(1) + ", old_param: " + rs2.getString("old_param") + 
                        ", old_lock: " + rs2.getInt("old_lock"));
                bw.newLine();
                bw.write("inserted - TestID: " + rs2.getInt(4) + ", new_param: " + rs2.getString("new_param") + 
                        ", new_lock: " + rs2.getInt("new_lock"));
                bw.newLine();
            }
            rs2.close();
            
            // Third: DELETE another record (will trigger EPQ)
            ResultSet rs3 = stmt.executeQuery("DELETE FROM TestTable_jira_4880 " +
                       "OUTPUT deleted.TestID, deleted.LockProcessID, " +
                       "deleted.Param1 " +
                       "WHERE TestID = 2");
            
            bw.write("Mixed DML - DELETE OUTPUT Results:");
            bw.newLine();
            while (rs3.next()) {
                bw.write("TestID: " + rs3.getInt("TestID") + ", LockProcessID: " + rs3.getInt("LockProcessID") + 
                        ", Param1: " + rs3.getString("Param1"));
                bw.newLine();
            }
            rs3.close();
            
            conn.commit();
            
        } catch (Exception e) {
            BabelOutputClauseConcurrencyTest.errorCount.incrementAndGet();
            try {
                bw.write("EPQMixedSession2Worker error: " + e.getMessage());
                bw.newLine();
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }
    }
}
