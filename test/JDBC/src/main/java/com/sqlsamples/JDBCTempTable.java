package com.sqlsamples;

import java.io.*;
import java.util.*;
import java.sql.*;

import org.junit.jupiter.api.*;
import java.util.concurrent.ThreadLocalRandom;

import static com.sqlsamples.Config.*;
import static com.sqlsamples.Statistics.curr_exec_time;

public class JDBCTempTable {
    public static boolean toRun = false;

    public static String initializeConnectionString() {
        String url = properties.getProperty("URL");
        String port = properties.getProperty("tsql_port");
        String databaseName = properties.getProperty("databaseName");
        String user = properties.getProperty("user");
        String password = properties.getProperty("password");

        return createSQLServerConnectionString(url, port, databaseName, user, password);
    }

    public static void runTest(BufferedWriter bw) {
        long startTime = System.nanoTime();

        try {
            check_oids_equal(bw);
            concurrency_test(bw);

            /* Disabled in GitHub because of runtime. */
            // fill_oid_buffer(bw);
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

    /*
     * This is a straightforward test to assert that temp tables created across different connections will have the same OID start.
     */
    private static void check_oids_equal(BufferedWriter bw) throws Exception {
        int num_connections = 2;

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
        boolean all_oids_equal = true;
        for (Integer i : oids)
        {
            if (!i.equals(oids.get(0))) {
                all_oids_equal = false;
                bw.newLine();
                break;
            }
        }

        if (!all_oids_equal)
        {
            bw.write("OID check failed! Not all oids were equal:");
            bw.newLine();
            for (Integer i : oids)
            {
                bw.write(i.toString());
                bw.newLine();
            }
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

    /*
     * This takes about 20 minutes to run. This passes but it will be disabled by default
     */
    private static void fill_oid_buffer(BufferedWriter bw) throws Exception {
        String connectionString = initializeConnectionString();
        Connection c = DriverManager.getConnection(connectionString);
        Statement s = c.createStatement();

        try {
            bw.newLine();
            for (int i = 0; i < 17000; i++) {
                String queryString = "CREATE TABLE #tab" + i + " (a int identity, b nvarchar(20))";
                s.execute(queryString);
            }
        } catch (Exception e) {
            if (e.getMessage().startsWith("Unable to allocate oid for temp table.")) {
                ResultSet rs = s.executeQuery("SELECT TOP 1 reloid FROM sys.babelfish_get_enr_list() where relname not like '%index' order by reloid desc");
                rs.next();
                int oid_high = Integer.parseInt(rs.getString("reloid"));

                rs = s.executeQuery("SELECT TOP 1 reloid FROM sys.babelfish_get_enr_list() where relname not like '%index' order by reloid asc");
                rs.next();
                int oid_low = Integer.parseInt(rs.getString("reloid"));

                rs = s.executeQuery("SELECT count(*) FROM sys.babelfish_get_enr_list()");
                rs.next();
                int oid_count = Integer.parseInt(rs.getString("count"));

                /* Handle verification */
                if (oid_count != 65535 && (oid_high - oid_low) != 65535)
                {
                    bw.write("Unable to allocate oid for temp table, but oid usage was not as expected.");
                    bw.newLine();
                    bw.write("oid count = " + oid_count);
                    bw.newLine();
                    bw.write("oid high = " + oid_high);
                    bw.newLine();
                    bw.write("oid low = " + oid_low);
                    bw.newLine();
                }
            } else {
                bw.write(e.getMessage());
                bw.newLine();
            }
        }
        c.close();
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