package com.sqlsamples;

import org.apache.logging.log4j.Logger;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static java.lang.System.currentTimeMillis;
import static java.nio.charset.StandardCharsets.UTF_8;
import static java.nio.file.Files.newBufferedWriter;

public class BackendMemoryProfiler implements Runnable {

    private static final Pattern VM_RSS_REGEX = Pattern.compile("^VmRSS:\\s+(\\d+)\\s+kB$");
    private final Logger logger;
    private final int pid;
    private final Path outputFilePath;

    public BackendMemoryProfiler(Connection conn_bbl, String testFilePath, String outputDirPath, Logger logger) {
        int pid = getBackendPid(conn_bbl);
        String testNameFull = Paths.get(testFilePath).getFileName().toString();
        String testName = testNameFull.substring(0, testNameFull.lastIndexOf("."));
        String outputFileName = testName + "_mprof.txt";

        this.logger = logger;
        this.pid = pid;
        this.outputFilePath = Paths.get(outputDirPath, outputFileName);
    }

    @Override
    public void run() {
        long start = currentTimeMillis();
        try (Writer writer = newBufferedWriter(outputFilePath, UTF_8)) {
            logger.error("Memory profiler thread started, backend pid: " + pid + ", " +
                    "output file: " + outputFilePath.getFileName());
            writer.write("# This file contains recorded RSS values, to create a plot run the following from JDBC directory:\n");
            writer.write("# gnuplot -p -e \"set grid; set xlabel 'Elapsed time (millis)'; set ylabel 'Backend RSS for pid: " + pid + " (KB)'; plot './output/" + outputFilePath.getFileName() + "' with linespoints\"\n");
            for (;;) {
                long cur = currentTimeMillis();
                long elapsed = cur - start;
                int rss = readRSS();
                writer.write(elapsed + " " + rss + "\n");
                writer.flush();
                long delay = currentTimeMillis() - cur;
                if (delay < 100) {
                    Thread.sleep(100 - delay);
                }
            }
        } catch (NoSuchFileException e) {
            // backend process exited
        } catch (Throwable e) {
            logger.error(e, e);
        } finally {
            logger.error("Memory profiler thread shut down, backend pid: " + pid + ", " +
                    "output file: " + outputFilePath.getFileName());
        }
    }

    private int readRSS() throws IOException {
        Path status = Paths.get("/proc/" + pid + "/status");
        List<String> lines = Files.readAllLines(status, UTF_8);
        for (String ln : lines) {
            if (ln.startsWith("VmRSS")) {
                Matcher matcher = VM_RSS_REGEX.matcher(ln);
                if (matcher.matches()) {
                    return Integer.parseInt(matcher.group(1));
                }
            }
        }
        throw new IOException("Error reading VmRSS from /proc/pid/status");
    }

    private static int getBackendPid(Connection conn_bbl) {
        try (Statement stmt = conn_bbl.createStatement()) {
            ResultSet rs = stmt.executeQuery("select pg_backend_pid()");
            rs.next();
            return rs.getInt(1);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
