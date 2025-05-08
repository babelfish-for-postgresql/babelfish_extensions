package com.sqlsamples;

import org.apache.logging.log4j.Logger;
import java.io.*;
import java.util.*;
import java.sql.*;

import org.junit.jupiter.api.*;
import java.util.concurrent.ThreadLocalRandom;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.Statistics.curr_exec_time;

public class JDBCTempTable {
    public static boolean toRun = false;

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
            if (check_temp_oid_buffer_enabled(bw, logger)) {
                check_oids_equal(bw);
                test_oid_buffer(bw, logger);
                psql_test(bw, logger);
                test_lock_contention(bw, logger);
            }
            concurrency_test(bw);
            test_trigger_on_temp_table(bw, logger);
        } catch (Exception e) {
            try {
                bw.write(e.getMessage());
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }

        long endTime = System.nanoTime();
        curr_exec_time = endTime - startTime;
    }

    private static boolean check_temp_oid_buffer_enabled(BufferedWriter bw, Logger logger) throws Exception {
        String temp_oid_buffer_size = "babelfishpg_tsql.temp_oid_buffer_size";
        Connection c = DriverManager.getConnection(connectionString);
        JDBCCrossDialect cx = new JDBCCrossDialect(c);
        Connection psql = cx.getPsqlConnection("-- psql", bw, logger);
        Statement check_guc = psql.createStatement();
        ResultSet rs = check_guc.executeQuery("SHOW " + temp_oid_buffer_size);
        if (!rs.next()) {
            bw.write("Table is missing.");
            bw.newLine();
        }
        int buffer_size = Integer.parseInt(rs.getString(temp_oid_buffer_size));
        return buffer_size != 0;
    }

    /*
     * Helper function that creates the specified number of connections, creates a temp table on each connection, and returns whether all the OIDs are equal or not.
     */
    private static boolean check_oids_equal_helper(int num_connections) throws Exception {
        ArrayList<Connection> connections = new ArrayList<Connection>();
        String connectionString = initializeConnectionString();

        /* Create connections */
        for (int i = 0; i < num_connections; i++) {
            Connection connection = DriverManager.getConnection(connectionString);
            connections.add(connection);
        }

        /* Run test on each connection */
        ArrayList<Integer> oids = new ArrayList<>();
        String queryString = "";
        String tableName = "";
        int count = 0; 
        for (Connection c : connections)
        {
            tableName = "#t" + count;
            queryString = "CREATE TABLE " + tableName + " (a int)";
            int result = create_table_and_report_oid(c, queryString, tableName);
            oids.add(result);
            count++;
            c.close();
        }

        // The oids should all be equal here. 
        for (Integer i : oids)
        {
            if (!i.equals(oids.get(0))) {
                return false;
            }
        }
        return true;
    }

    /*
     * This is a straightforward test to assert that temp tables created across different connections will have the same OID start.
     */
    private static void check_oids_equal(BufferedWriter bw) throws Exception {
        int num_connections = 2;

        if (!check_oids_equal_helper(num_connections))
        {
            bw.write("OID check failed! Not all oids were equal:");
            bw.newLine();
        }
    }

    /*
     * Create a table (via provided query string), report back the OID of the table that was just created.
     */
    private static int create_table_and_report_oid(Connection c, String queryString, String tablename) throws Exception {
        Statement s = c.createStatement();
        s.execute(queryString);

        ResultSet rs = s.executeQuery("SELECT * FROM sys.babelfish_get_enr_list() WHERE RELNAME = '" + tablename + "'");

        if (!rs.next()) {
            throw new Exception("Tablename not found in sys.babelfish_get_enr_list");
        }
        String reloid = rs.getString("reloid");

        return Integer.parseInt(reloid);
    }

    /*
     * This will be a short stress test to create multiple tables in parallel to ensure no issues or crashes are encountered.
     */
    private static void concurrency_test(BufferedWriter bw) throws Exception {
        int num_connections = 10;
        int num_tables = 5000;
        
        /* Create a UDT so that we can test non-ENR temp tables */
        String connectionString = initializeConnectionString();
        ArrayList<Connection> cxns = new ArrayList<>();
        Connection c = DriverManager.getConnection(connectionString);
        cxns.add(c);
        c.createStatement().execute("CREATE TYPE my_temp_type FROM int");

        ArrayList<Thread> threads = new ArrayList<>();

        /* Create connections */
        for (int i = 0; i < num_connections; i++) {
            Connection connection = DriverManager.getConnection(connectionString);
            cxns.add(connection);
            Thread t = new Thread(new Worker(connection, i + 1, num_tables / num_connections, bw));
            threads.add(t);
            t.start();
        }
        for (Thread t : threads)
        {
            t.join();
        }
        c.createStatement().execute("DROP TYPE my_temp_type");

        for (Connection cxn : cxns) {
            cxn.close();
        }
    }

    private static void test_oid_buffer(BufferedWriter bw, Logger logger) throws Exception {
        String connectionString = initializeConnectionString();
        Connection c = DriverManager.getConnection(connectionString);
        JDBCCrossDialect cx = new JDBCCrossDialect(c);

        Connection psql = cx.getPsqlConnection("-- psql", bw, logger);
        int num_connections = 2;

        /*
         * TEST: After disabling GUC, ensure that the OIDs are not equal, meaning we aren't using
         * the OID buffer.
         */
        Statement alter_guc = psql.createStatement();
        alter_guc.execute("ALTER DATABASE babelfish_db SET babelfishpg_tsql.temp_oid_buffer_size = 0");

        if (check_oids_equal_helper(num_connections)) {
            bw.write("OID check failed! Oids were equal after disabling guc.");
            bw.newLine();
        }

        /*
         * TEST: Ensure that we can create up to (and no more) than the oid buffer size.
         */
        alter_guc.execute("ALTER DATABASE babelfish_db SET babelfishpg_tsql.temp_oid_buffer_size = 3");

        /* We need a new connection here to pick up the updated guc. */
        Connection c2 = DriverManager.getConnection(connectionString);
        Statement s = c2.createStatement();

        try {
            for (int i = 0; i < 4; i++) {
                String queryString = "CREATE TABLE #tab" + i + " (a int)";
                s.execute(queryString);
            }
            /* If we reach this point, we created more tables than we should have been able to. */
            bw.write("Created more tables than buffer should have allowed for");
            bw.newLine();
        } catch (Exception e) {
            if (!e.getMessage().startsWith("Unable to allocate oid for temp table.")) {
                bw.write(e.getMessage());
                bw.newLine();
            }
        }

        /* If the table was created, throw an error. */
        ResultSet rs = s.executeQuery("SELECT * FROM babelfish_get_enr_list() WHERE relname = \'#table_cant_be_created\'");
        if (rs.next()) {
            bw.write("A table was created that should have reached buffer size limit.");
            bw.newLine();
        }

        /*
         * TEST: Ensure that we can wraparound properly.
         */
        rs = s.executeQuery("SELECT * FROM babelfish_get_enr_list() WHERE relname = \'#tab0\'");
        if (!rs.next()) {
            bw.write("Table is missing.");
            bw.newLine();
        }
        int old_oid = Integer.parseInt(rs.getString("reloid"));
        s.execute("DROP TABLE #tab0");
        int new_oid = create_table_and_report_oid(c2, "CREATE TABLE #new_table(a int)", "#new_table");
        
        if (old_oid > new_oid) {
            bw.write(String.format("Wraparound did not handle new OIDs properly. Old OID was %d and new oid is %d", old_oid, new_oid));
            bw.newLine();
        }

        c2.close();

        /* Restore GUC after tests. */
        alter_guc.execute("ALTER DATABASE babelfish_db SET babelfishpg_tsql.temp_oid_buffer_size = 65536");
        psql.close();
        c.close();
    }

    /*
     * Sanity checks that must be done from psql endpoint.
     */
    private static void psql_test(BufferedWriter bw, Logger logger) throws Exception {
        /* Test GUC crash resiliency - Create a few normal tables (to advance OID counter). Ensure that the GUC remains the same from a different session. */
        Connection connection = DriverManager.getConnection(connectionString);
        Statement s = connection.createStatement();

        /* Create a few tables so that the OID counter is not a predictable value. */
        for (int i = 0; i < 100; i++)
        {
            s.execute("CREATE TABLE crash_res_dummy_table(a int)");
            s.execute("DROP TABLE crash_res_dummy_table");
        }
        
        s.execute("CREATE TABLE #t1(a int)");

        /* Create two new connections to check the GUC value from postgres. */
        Connection c = DriverManager.getConnection(connectionString);
        JDBCCrossDialect cx = new JDBCCrossDialect(c);
        Connection psql = cx.getPsqlConnection("-- psql", bw, logger);

        Statement check_guc = psql.createStatement();
        ResultSet rs = check_guc.executeQuery("SHOW babelfishpg_tsql.temp_oid_buffer_start");
        if (!rs.next()) {
            bw.write("Table is missing.");
            bw.newLine();
        }
        int buffer_start = Integer.parseInt(rs.getString("babelfishpg_tsql.temp_oid_buffer_start"));

        if (buffer_start == Integer.MIN_VALUE)
        {
            bw.write("Oid buffer guc was not set properly!");
            bw.newLine();
        }

        Connection c2 = DriverManager.getConnection(connectionString);
        JDBCCrossDialect cx2 = new JDBCCrossDialect(c2);
        Connection psql2 = cx2.getPsqlConnection("-- psql", bw, logger);

        check_guc = psql2.createStatement();
        rs = check_guc.executeQuery("SHOW babelfishpg_tsql.temp_oid_buffer_start");
        if (!rs.next()) {
            bw.write("Table is missing.");
            bw.newLine();
        }
        int buffer_start_2 = Integer.parseInt(rs.getString("babelfishpg_tsql.temp_oid_buffer_start"));

        if (buffer_start_2 == Integer.MIN_VALUE)
        {
            bw.write("2nd Oid buffer guc was not set properly!");
            bw.newLine();
        }

        if (buffer_start_2 != buffer_start) {
            bw.write("Oid buffer guc was different between two connections!");
            bw.newLine();
        }

        /* Ensure that psql still can't create tables with '#'. */
        try {
            check_guc.execute("CREATE TABLE #psql_table_with_hash(a int)");
        } catch (Exception e) {
            if (!e.getMessage().startsWith("ERROR: syntax error at or near \"#\"")) {
                bw.write(e.getMessage());
                bw.newLine();
            }
        }

        psql2.close();
        c2.close();
        psql.close();
        c.close();
        connection.close();
    }

    private static void test_trigger_on_temp_table(BufferedWriter bw, Logger logger) throws Exception {
        ArrayList<Connection> connections = new ArrayList<Connection>();
        Statement s;
        String queryString;

        /* Create connections */
        for (int i = 0; i < 2; i++) {
            Connection connection = DriverManager.getConnection(connectionString);
            connections.add(connection);
        }

        /* On connection 1: create a temp table and a trigger on it.
         * On connection 2: try dropping the trigger. It should raise an error instead of crashing.
         */
        Connection c1 = connections.get(0);
        s = c1.createStatement();
        queryString = "CREATE TABLE #t1(a int)";
        s.execute(queryString);
        queryString = "CREATE TRIGGER bar ON #t1 FOR INSERT AS BEGIN SELECT 1 END";
        try {
            s.execute(queryString);
        } catch (Exception e) {
            if (!e.getMessage().equals("Cannot create trigger on a temporary object.")) {
                bw.write(e.getMessage());
                bw.newLine();
            }
        }
        Connection c2 = connections.get(1);
        s = c2.createStatement();
        queryString = "DROP TRIGGER bar";
        try {
            s.execute(queryString);
        } catch (Exception e) {
            if (!e.getMessage().equals("trigger \"bar\" does not exist")) {
                bw.write(e.getMessage());
                bw.newLine();
            }
        }
    }

    private static void test_lock_contention(BufferedWriter bw, Logger logger) throws Exception {
        String connectionString = initializeConnectionString();

        /* Sanity check of pg_locks catalog */
        Connection c = DriverManager.getConnection(connectionString);
        Statement s = c.createStatement();
        ResultSet rs;
        s.execute("BEGIN TRAN");
        s.execute("CREATE TABLE #t1 (a INT)");
        rs = s.executeQuery("SELECT relation FROM pg_locks JOIN sys.babelfish_get_enr_list() ON (relation = reloid) where relname = '#t1'");
        if (rs.next()) {
            bw.write("Unexpected lock acquisition on a TSQL temp table.\n");
        }
        s.execute("ALTER TABLE #t1 ADD b AS a + 1");
        rs = s.executeQuery("SELECT relation FROM pg_locks JOIN sys.babelfish_get_enr_list() ON (relation = reloid) where relname = '#t1'");
        if (rs.next()) {
            bw.write("Unexpected lock acquisition on a TSQL temp table.\n");
        }
        s.execute("ALTER TABLE #t1 DROP COLUMN b");
        rs = s.executeQuery("SELECT relation FROM pg_locks JOIN sys.babelfish_get_enr_list() ON (relation = reloid) where relname = '#t1'");
        if (rs.next()) {
            bw.write("Unexpected lock acquisition on a TSQL temp table.\n");
        }
        s.execute("DROP TABLE #t1");
        rs = s.executeQuery("SELECT relation FROM pg_locks JOIN sys.babelfish_get_enr_list() ON (relation = reloid) where relname = '#t1'");
        if (rs.next()) {
            bw.write("Unexpected lock acquisition on a TSQL temp table.\n");
        }
        c.close();

        int num_connections = 2;
        
        ArrayList<Connection> cxns = new ArrayList<>();

        ArrayList<Thread> threads = new ArrayList<>();

        /* Create connections */
        for (int i = 0; i < num_connections; i++) {
            Connection connection = DriverManager.getConnection(connectionString);
            cxns.add(connection);
            Thread t = new Thread(new LockContentionWorker(connection, bw));
            threads.add(t);
            t.start();
        }

        /* 
         * Unfortunately, setQueryTimeout (used in the worker thread) does not always work correctly.
         * So we need to manaully try to detect a hanging thread.
         */
        Thread.sleep(1000);
        for (Thread t : threads)
        {
            if (t.isAlive()) {
                bw.write("Lock contention detected.\n");
                return;
            }
        }
    }
}

class Worker implements Runnable {
    public static int table_count = 0;
    private int num_to_create;
    private BufferedWriter bw;

    Connection c;
    String prefix;
    String[] column_descriptions = new String[]{
        "(a int)",                                          /* Plain table */
        "(a my_temp_type)",                                 /* Non-ENR */
        "(a nvarchar(200))",                                /* Toasted */
        "(a int primary key identity)",                     /* Primary key, identity */
        "(a int primary key identity, b nvarchar(200))"    /* Primary key, identity, toasted */
    };

    Worker(Connection c, int i, int num_to_create, BufferedWriter bw) {
        this.c = c;
        this.prefix = "thr" + i + "_";
        this.num_to_create = num_to_create;
        this.bw = bw;
    }

    public void run() {
        try {
            try {
                Statement s = c.createStatement();
                for (int i = 0; i < num_to_create; i++) {
                    /* Pick a random table type to create */
                    int r = ThreadLocalRandom.current().nextInt(0, column_descriptions.length);

                    /* Name format: thr[thread number]_#tab[table number]_[column_description index] */
                    String tablename = prefix + "#tab" + i + "_" + r;

                    s.execute("CREATE TABLE " + tablename + column_descriptions[r]);
                    s.execute("DROP TABLE " + tablename);
                    table_count++;
                }
            } catch (Exception e) {
                bw.write(e.getMessage());
                bw.newLine();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

class LockContentionWorker implements Runnable {

    private Connection c;
    private BufferedWriter bw;

    LockContentionWorker(Connection c, BufferedWriter bw) {
        this.c = c;
        this.bw = bw;
    }

    public void run() {
        try {
            try {
                Statement s = c.createStatement();
                s.setQueryTimeout(1);
                s.execute("BEGIN TRAN;");
                s.execute("CREATE TABLE #temp_table1 (a int primary key not null identity, b as a + 1, c text);");
            } catch (Exception e) {
                bw.write(e.getMessage());
                bw.newLine();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}