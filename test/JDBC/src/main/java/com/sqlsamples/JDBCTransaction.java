package com.sqlsamples;

import org.apache.log4j.Logger;

import java.io.BufferedWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Savepoint;
import java.util.*;

import static com.sqlsamples.Config.compareWithFile;
import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;
import static java.sql.Connection.*;

public class JDBCTransaction {

    private HashMap<String, AbstractMap.SimpleEntry<Savepoint, Savepoint>> savepointMap = new HashMap<>();
    
    boolean setAutoCommitBehaviour(Connection con_sql, Connection con_bbl, boolean autoCommitBehaviour, Logger logger) {
        boolean exceptionSQL = false, exceptionBabel = false;
        
        try {
            con_sql.setAutoCommit(autoCommitBehaviour);
        } catch (SQLException e) {
            exceptionSQL = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        try {
            con_bbl.setAutoCommit(autoCommitBehaviour);
        } catch (SQLException e) {
            exceptionBabel = true;
            logger.warn("SQL Exception: " + e.getMessage(), e);
        }

        if (exceptionSQL && exceptionBabel) {
            logger.info("Both SQL Server and Babel threw an exception!");
            return  true;
        } else if (exceptionSQL) {
            logger.info("SQL Server threw an exception but Babel did not!");
            return  false;
        } else if (exceptionBabel) {
            logger.info("Babel threw an exception but SQL Server did not!");
            return false;
        } else return true;
    }
    
    boolean beginTransaction(Connection con_sql, Connection con_bbl, BufferedWriter bw, Logger logger) {
        logger.info("Beginning transaction");
        
        if (!compareWithFile) {
            return setAutoCommitBehaviour(con_sql, con_bbl, false, logger);
        } else {
            try {
                con_bbl.setAutoCommit(false);
                return true;
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            }
        }
    }

    boolean transactionCommit(Connection con_sql, Connection con_bbl, BufferedWriter bw, Logger logger) {
        logger.info("Committing transaction");
        
        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                con_sql.commit();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                con_bbl.commit();
            } catch (SQLException e) {
                exceptionBabel = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            if (exceptionSQL && exceptionBabel) {
                logger.info("Both SQL Server and Babel threw an exception!");
                return true;
            } else if (exceptionSQL) {
                logger.info("SQL Server threw an exception but Babel did not!");
                return false;
            } else if (exceptionBabel) {
                logger.info("Babel threw an exception but SQL Server did not!");
                return false;
            }

            //set default behaviour
            return setAutoCommitBehaviour(con_sql, con_bbl, true, logger);
            
        } else {
            try {
                con_bbl.commit();
                con_bbl.setAutoCommit(true);
                return true;
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            }
        }
    }

    boolean transactionRollback(Connection con_sql, Connection con_bbl, BufferedWriter bw, Logger logger) {
        logger.info("Rolling back transaction");
        
        if (!compareWithFile) {
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                con_sql.rollback();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                con_bbl.rollback();
            } catch (SQLException e) {
                exceptionBabel = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            if (exceptionSQL && exceptionBabel) {
                logger.info("Both SQL Server and Babel threw an exception!");
                return true;
            } else if (exceptionSQL) {
                logger.info("SQL Server threw an exception but Babel did not!");
                return false;
            } else if (exceptionBabel) {
                logger.info("Babel threw an exception but SQL Server did not!");
                return false;
            }

            //set default behaviour
            return setAutoCommitBehaviour(con_sql, con_bbl, true, logger);
        } else {
            try {
                con_bbl.rollback();
                return true;
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            }
        }
    }
    
    boolean transactionRollbackToSavepoint(Connection con_sql, Connection con_bbl, String[] result, BufferedWriter bw, Logger logger) {
        logger.info("Rolling back to savepoint " + result[2]);
        if (!savepointMap.containsKey(result[2])) {
            logger.error("Savepoint with the name " + result[2] + " does not exist!");
            return false;
        } else {
            if (!compareWithFile){
                boolean exceptionSQL = false, exceptionBabel = false;

                try {
                    con_sql.rollback(savepointMap.get(result[2]).getKey());
                } catch (SQLException e) {
                    exceptionSQL = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                try {
                    if (savepointMap.get(result[2]).getValue() == null) {
                        logger.error("Savepoint for Babel does not exist but it exists for SQL Server");
                        return false;
                    } else {
                        con_bbl.rollback(savepointMap.get(result[2]).getValue());
                    }
                } catch (SQLException e) {
                    exceptionBabel = true;
                    logger.warn("SQL Exception: " + e.getMessage(), e);
                }

                if (exceptionSQL && exceptionBabel) {
                    logger.info("Both SQL Server and Babel threw an exception!");
                    return  true;
                } else if (exceptionSQL) {
                    logger.info("SQL Server threw an exception but Babel did not!");
                    return  false;
                } else if (exceptionBabel) {
                    logger.info("Babel threw an exception but SQL Server did not!");
                    return false;
                }

                //set default behaviour
                return setAutoCommitBehaviour(con_sql, con_bbl, true, logger);

            } else {
                try {
                    con_bbl.rollback(savepointMap.get(result[2]).getKey());
                    con_bbl.setAutoCommit(true);
                    return true;
                } catch (SQLException e) {
                    return handleSQLExceptionWithFile(e, bw);
                }
            }
        }
    }
    
    
    boolean setTransactionSavepoint(Connection con_sql, Connection con_bbl, BufferedWriter bw, Logger logger){
        //unnamed savepoint
        logger.info("Setting unnamed savepoint");
        
        if(!compareWithFile) {

            boolean exceptionSQL = false, exceptionBabel = false;
            
            try {
                con_sql.setSavepoint();
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                con_bbl.setSavepoint();
            } catch (SQLException e) {
                exceptionBabel = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            if (exceptionSQL && exceptionBabel) {
                logger.info("Both SQL Server and Babel threw an exception!");
                return true;
            } else if (exceptionSQL) {
                logger.info("SQL Server threw an exception but Babel did not!");
                return false;
            } else if (exceptionBabel) {
                logger.info("Babel threw an exception but SQL Server did not!");
                return false;
            } else return true;
        } else {
            try {
                con_bbl.setSavepoint();
                return true;
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            }
        }
    }

    boolean setTransactionNamedSavepoint(Connection con_sql, Connection con_bbl, String[] result, BufferedWriter bw, Logger logger) {
        //named savepoint
        logger.info("Setting savepoint " + result[2]);
        
        if (!compareWithFile) {
            Savepoint sqlSavepoint = null, bblSavepoint = null;
            
            boolean exceptionSQL = false, exceptionBabel = false;

            try {
                bblSavepoint = con_bbl.setSavepoint(result[2]);
            } catch (SQLException e) {
                exceptionBabel = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            try {
                sqlSavepoint = con_sql.setSavepoint(result[2]);
            } catch (SQLException e) {
                exceptionSQL = true;
                logger.warn("SQL Exception: " + e.getMessage(), e);
            }

            if (exceptionSQL && exceptionBabel) {
                logger.info("Both SQL Server and Babel threw an exception!");
                return true;
            } else if (exceptionSQL) {
                logger.info("SQL Server threw an exception but Babel did not!");
                return false;
            } else if (exceptionBabel) {
                logger.info("Babel threw an exception but SQL Server did not!");
                return false;
            }

            savepointMap.put(result[2], new AbstractMap.SimpleEntry<>(sqlSavepoint, bblSavepoint));
            return true;
        } else {
            try {
                Savepoint bblSavepoint = con_bbl.setSavepoint(result[2]);
                savepointMap.put(result[2], new AbstractMap.SimpleEntry<>(bblSavepoint, null));
                return true;
            } catch (SQLException e) {
                return handleSQLExceptionWithFile(e, bw);
            }
        }
    }
    
    boolean setTransactionIsolationLevelUtil(Connection con, int isolationLevel, Logger logger) {
        try {
            con.setTransactionIsolation(isolationLevel);
            return false;
        } catch (SQLException e) {
            logger.warn("SQL Exception: " + e.getMessage(), e);
            return true;
        }
    }
    
    boolean setTransactionIsolationLevel(Connection con_sql, Connection con_bbl, String[] result, Logger logger) {
        if (result.length < 3 || result[2].length() == 0 || result[2].matches("[ \\t]+")) {
            logger.error("No isolation level specified!");
            return false;
        } else {
            String isolationLevel = result[2];
            
            if(!compareWithFile) {
                boolean exceptionSQL, exceptionBabel;

                if (isolationLevel.toLowerCase().startsWith("ru")) {
                    logger.info("Transaction isolation level set to TRANSACTION_READ_UNCOMMITTED");
                    exceptionSQL = setTransactionIsolationLevelUtil(con_sql, TRANSACTION_READ_UNCOMMITTED, logger);
                    exceptionBabel = setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_UNCOMMITTED, logger);

                } else if (isolationLevel.toLowerCase().startsWith("rc")) {
                    logger.info("Transaction isolation level set to TRANSACTION_READ_COMMITTED");
                    exceptionSQL = setTransactionIsolationLevelUtil(con_sql, TRANSACTION_READ_COMMITTED, logger);
                    exceptionBabel = setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_COMMITTED, logger);

                } else if (isolationLevel.toLowerCase().startsWith("rr")) {
                    logger.info("Transaction isolation level set to TRANSACTION_REPEATABLE_READ");
                    exceptionSQL = setTransactionIsolationLevelUtil(con_sql, TRANSACTION_REPEATABLE_READ, logger);
                    exceptionBabel = setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_REPEATABLE_READ, logger);

                } else if (isolationLevel.toLowerCase().startsWith("se")) {
                    logger.info("Transaction isolation level set to TRANSACTION_SERIALIZABLE");
                    exceptionSQL = setTransactionIsolationLevelUtil(con_sql, TRANSACTION_SERIALIZABLE, logger);
                    exceptionBabel = setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_SERIALIZABLE, logger);

                } else if (isolationLevel.toLowerCase().startsWith("sn")) {
                    logger.info("Transaction isolation level set to TRANSACTION_SNAPSHOT");
                    exceptionSQL = setTransactionIsolationLevelUtil(con_sql, TRANSACTION_READ_COMMITTED + 4094, logger);
                    exceptionBabel = setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_COMMITTED + 4094, logger);

                } else {
                    logger.error("Invalid Transaction isolation level! Set from ru, rc, rr or s");
                    return false;
                }

                if (exceptionSQL && exceptionBabel) {
                    logger.info("Both SQL Server and Babel threw an exception!");
                    return  true;
                } else if (exceptionSQL) {
                    logger.info("SQL Server threw an exception but Babel did not!");
                    return  false;
                } else if (exceptionBabel) {
                    logger.info("Babel threw an exception but SQL Server did not!");
                    return false;
                } else return true;
            } else {
                if (isolationLevel.toLowerCase().startsWith("ru")) {
                    logger.info("Transaction isolation level set to TRANSACTION_READ_UNCOMMITTED");
                    setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_UNCOMMITTED, logger);
                    return true;

                } else if (isolationLevel.toLowerCase().startsWith("rc")) {
                    logger.info("Transaction isolation level set to TRANSACTION_READ_COMMITTED");
                    setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_COMMITTED, logger);
                    return true;

                } else if (isolationLevel.toLowerCase().startsWith("rr")) {
                    logger.info("Transaction isolation level set to TRANSACTION_REPEATABLE_READ");
                    setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_REPEATABLE_READ, logger);
                    return true;

                } else if (isolationLevel.toLowerCase().startsWith("se")) {
                    logger.info("Transaction isolation level set to TRANSACTION_SERIALIZABLE");
                    setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_SERIALIZABLE, logger);
                    return true;

                } else if (isolationLevel.toLowerCase().startsWith("sn")) {
                    logger.info("Transaction isolation level set to TRANSACTION_SNAPSHOT");
                    setTransactionIsolationLevelUtil(con_bbl, TRANSACTION_READ_COMMITTED + 4094, logger);
                    return true;

                } else {
                    logger.error("Invalid Transaction isolation level! Set from ru, rc, rr or s");
                    return false;
                }
            }
        }
    }
}
