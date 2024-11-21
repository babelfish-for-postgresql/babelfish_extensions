import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

import com.microsoft.sqlserver.jdbc.SQLServerDataTable;
import com.microsoft.sqlserver.jdbc.SQLServerException;
import com.microsoft.sqlserver.jdbc.SQLServerPreparedStatement;

public class TVPTest {
	
	public static void main(String arr[]) throws ClassNotFoundException, SQLException {
		
		String sql = "SELECT * FROM ?";
		String url = "jdbc:sqlserver://localhost;databaseName=master;user=jdbc_user;password=12345678;allowMultiQueries=true;encrypt=false;trustServerCertificate=true;"; // BBF
		String username = "jdbc_user";
		String password = "12345678";

		Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

		Connection con = DriverManager.getConnection(url, username, password);

		SQLServerPreparedStatement preparedStatement =
		        (SQLServerPreparedStatement) con.prepareStatement(sql);

		preparedStatement.setStructured(1, "dbo.tvp", getSqlServerDataTable());

		Scanner scn = new Scanner(System.in);
		int x = scn.nextInt();
	
		preparedStatement.executeQuery();
	}
	
	private static SQLServerDataTable getSqlServerDataTable() throws SQLServerException {
		SQLServerDataTable inputData = new SQLServerDataTable();
		inputData.addColumnMetadata("ID", java.sql.Types.DECIMAL);
		inputData.addRow(Double.valueOf(0.15));
		return inputData;
	}

}
