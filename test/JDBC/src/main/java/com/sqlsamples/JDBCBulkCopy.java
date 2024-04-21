package com.sqlsamples;

import com.microsoft.sqlserver.jdbc.SQLServerBulkCopy;
import org.apache.logging.log4j.Logger;

import java.io.BufferedWriter;
import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import static com.sqlsamples.HandleException.handleSQLExceptionWithFile;

public class JDBCBulkCopy {

    void executeInsertBulk(Connection con_bbl, String destinationTable, String sourceTable, Logger logger, BufferedWriter bw)
    {
        ResultSet rsSourceData = null;
        Statement stmt_sql = null;
        Statement stmt_bbl = null;
        try {
            stmt_bbl = con_bbl.createStatement();
            rsSourceData = stmt_bbl.executeQuery("select * from " + sourceTable);
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
            return;
        }
        try {
            SQLServerBulkCopy bulkCopy = new SQLServerBulkCopy(con_bbl);
            bulkCopy.setDestinationTableName(destinationTable);
            bulkCopy.writeToServer(rsSourceData);

            /* To fetch the rowcount we have added this implicit query. */
            rsSourceData = stmt_bbl.executeQuery("Select @@rowcount");
            rsSourceData.next();
            bw.write("~~ROW COUNT: " + rsSourceData.getString(1) + "~~");
            bw.newLine();
            bw.newLine();
        } catch (SQLException e) {
            handleSQLExceptionWithFile(e, bw, logger);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
