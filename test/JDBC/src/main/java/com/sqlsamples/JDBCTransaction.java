package com.sqlsamples;

import org.apache.logging.log4j.Logger;

import java.io.BufferedWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Savepoint;
import java.util.*;

import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;
import static java.sql.Connection.*;

public class JDBCTransaction {

    private HashMap<String, AbstractMap.SimpleEntry<Savepoint, Savepoint>> savepointMap = new HashMap<>();
    
    void beginTransaction(Connection con_bbl, BufferedWriter bw, Logger logger) {
        logger.info("Beginning transaction");
        
        try {
            con_bbl.setAutoCommit(false);
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    void transactionCommit(Connection con_bbl, BufferedWriter bw, Logger logger) {
        logger.info("Committing transaction");
        
        try {
            con_bbl.commit();
            con_bbl.setAutoCommit(true);
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    void transactionRollback(Connection con_bbl, BufferedWriter bw, Logger logger) {
        logger.info("Rolling back transaction");
        
        try {
            con_bbl.rollback();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }
    
    void transactionRollbackToSavepoint(Connection con_bbl, String[] result, BufferedWriter bw, Logger logger) {
        logger.info("Rolling back to savepoint " + result[2]);
        if (!savepointMap.containsKey(result[2])) {
            logger.error("Savepoint with the name " + result[2] + " does not exist!");
        } else {
            try {
                con_bbl.rollback(savepointMap.get(result[2]).getKey());
                con_bbl.setAutoCommit(true);
            } catch (SQLException e) {
                handleSQLExceptionWithFile(e, bw, logger);
            }
        }
    }
    
    
    void setTransactionSavepoint(Connection con_bbl, BufferedWriter bw, Logger logger){
        // unnamed savepoint
        logger.info("Setting unnamed savepoint");

        try {
            con_bbl.setSavepoint();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }

    void setTransactionNamedSavepoint(Connection con_bbl, String[] result, BufferedWriter bw, Logger logger) {
        // named savepoint
        logger.info("Setting savepoint " + result[2]);
        
        try {
            Savepoint bblSavepoint = con_bbl.setSavepoint(result[2]);
            savepointMap.put(result[2], new AbstractMap.SimpleEntry<>(bblSavepoint, null));
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }
    
    void setTransactionIsolationLevelUtil(Connection con, int isolationLevel, BufferedWriter bw, Logger logger) {
        try {
            con.setTransactionIsolation(isolationLevel);
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        }
    }
    
    void setTransactionIsolationLevel(Connection con_bbl, String[] result, BufferedWriter bw, Logger logger) {
        if (result.length < 3 || result[2].length() == 0 || result[2].matches("[ \\t]+")) {
            logger.error("No isolation level specified!");
        } else {
            String isolationLevel = result[2];
            
            if (isolationLevel.toLowerCase().startsWith("ru")) {
                logger.info("Transaction isolation level set to TRANSACTION_READ_UNCOMMITTED");
                setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_UNCOMMITTED, bw, logger);
            } else if (isolationLevel.toLowerCase().startsWith("rc")) {
                logger.info("Transaction isolation level set to TRANSACTION_READ_COMMITTED");
                setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_COMMITTED, bw, logger);
            } else if (isolationLevel.toLowerCase().startsWith("rr")) {
                logger.info("Transaction isolation level set to TRANSACTION_REPEATABLE_READ");
                setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_REPEATABLE_READ, bw, logger);
            } else if (isolationLevel.toLowerCase().startsWith("se")) {
                logger.info("Transaction isolation level set to TRANSACTION_SERIALIZABLE");
                setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_SERIALIZABLE, bw, logger);
            } else if (isolationLevel.toLowerCase().startsWith("sn")) {
                logger.info("Transaction isolation level set to TRANSACTION_SNAPSHOT");
                setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_COMMITTED + 4094, bw, logger);
            } else {
                logger.error("Invalid Transaction isolation level! Set from ru, rc, rr or s");
            }
        }
    }
}
