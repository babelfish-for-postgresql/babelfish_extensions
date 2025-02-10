using System;
using System.Linq;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.Management.Common;
using System.Collections.Specialized;
using Microsoft.SqlServer.Management.Sdk.Sfc;

namespace BabelfishDotnetFramework
{
public class DatabaseScripter
{
	public static void ScriptDatabase(string strLine, string testName, TestUtils testUtils, Serilog.Core.Logger logger)
	{
		string[] result = strLine.Split("#!#", StringSplitOptions.RemoveEmptyEntries);
		if (result.Length < 2) throw new ArgumentException("Invalid input string format");

		string flag = result[1].Trim('\r', '\n');

		try
		{
			ServerConnection serverConnection = new ServerConnection(ConfigSetup.BblUrl);
			serverConnection.LoginSecure = false;
			serverConnection.Login = ConfigSetup.BblUser;
			serverConnection.Password = ConfigSetup.BblPasswd;

			// Create a Server object
			Server server = new Server(serverConnection);
			Database database = server.Databases[ConfigSetup.BblDb];
			if (database == null)
			{
				testUtils.PrintToLogsOrConsole($"Database '{ConfigSetup.BblDb}' not found.", logger, "information");
				return;
			}

			testUtils.PrintToLogsOrConsole($"\nScripting database: {ConfigSetup.BblDb}", logger, "information");

			Scripter scripter = new Scripter(server)
			{
				Options = {
					DriAll = true,
					ScriptSchema = true,
					ScriptData = false,
					NoCollation = true,
					Encoding = System.Text.Encoding.UTF8
				}
			};

			ScriptDatabaseObjects(database, scripter, flag, testName, testUtils, logger);
		}
		catch (Exception ex)
		{
			testUtils.PrintToLogsOrConsole(
				$"An error occurred:\n" + 
				$"Message: {ex.Message}\n" +
				$"Stack Trace: {ex.StackTrace}\n" +
				$"Source: {ex.Source}", 
				logger, 
				"information");
		}
	}

	private static void ScriptDatabaseObjects(Database database, Scripter scripter, string flag, string testName, TestUtils testUtils, Serilog.Core.Logger logger)
	{
		const string sys_schema = "sys";
		const string dbo_user = "dbo";
		const string guest_user = "guest";
		const string sysdtb = "sysdatabases";


		Action<SqlSmoObject> scriptObject = obj =>
		{
			testUtils.PrintToLogsOrConsole($"\nScripting {obj.GetType().Name}: {obj.Urn}", logger, "information");
			StringCollection scripts = scripter.Script(new Urn[] { obj.Urn });
			testUtils.ResultSetWriter(scripts, testName);
		};

		Func<SqlSmoObject, bool> filterObject = obj =>
		{
			string schema = GetSchema(obj);
			if (schema == null) return false;
			return (schema != sys_schema && !IsSystemObject(obj));
		};

		// Script Tables and their child objects
		if (database.Tables != null)
		{
			foreach (Table table in database.Tables.Cast<Table>().Where(filterObject))
			{
				try
				{
					scriptObject(table);

					if (table.Indexes != null)
						table.Indexes.Cast<Microsoft.SqlServer.Management.Smo.Index>()
							.Where(idx => !idx.IsSystemObject)
							.ToList()
							.ForEach(scriptObject);
							
					if (table.Triggers != null)
						table.Triggers.Cast<Microsoft.SqlServer.Management.Smo.Trigger>()
							.Where(trg => !trg.IsSystemObject)
							.ToList()
							.ForEach(scriptObject);
				}
				catch (Exception ex)
				{
					// Log the error and continue with next table
					testUtils.PrintToLogsOrConsole($"\nFailed to script table {table.Schema}.{table.Name}: {ex.Message}", logger, "information");
					continue;
				}
			}
		}

		// Script other database objects
		database.Views.Cast<View>().Where(filterObject).ToList().ForEach(scriptObject);
		database.StoredProcedures.Cast<StoredProcedure>().Where(filterObject).ToList().ForEach(scriptObject);
		database.UserDefinedFunctions.Cast<UserDefinedFunction>().Where(filterObject).ToList().ForEach(scriptObject);
		database.UserDefinedDataTypes.Cast<UserDefinedDataType>().ToList().ForEach(scriptObject);
		database.UserDefinedTableTypes.Cast<UserDefinedTableType>().ToList().ForEach(scriptObject);
		database.PartitionFunctions.Cast<PartitionFunction>().ToList().ForEach(scriptObject);
		database.PartitionSchemes.Cast<PartitionScheme>().ToList().ForEach(scriptObject);

		database.Users.Cast<User>()
				.Where(ur => ur.Name != dbo_user && ur.Name != guest_user && !ur.IsSystemObject)
				.ToList()
				.ForEach(scriptObject);
	}

	private static string GetSchema(SqlSmoObject obj)
	{
		if (obj == null) return null;
		return obj switch
		{
			Table table => table.Schema,
			View view => view.Schema,
			StoredProcedure sp => sp.Schema,
			UserDefinedFunction udf => udf.Schema,
			_ => null
		};
	}

	private static bool IsSystemObject(SqlSmoObject obj)
	{
		try
		{
			if (obj == null) return false;

			return obj switch
			{
				Table table => table?.IsSystemObject ?? false,
				View view => view?.IsSystemObject ?? false,
				StoredProcedure sp => sp?.IsSystemObject ?? false,
				UserDefinedFunction udf => udf?.IsSystemObject ?? false,
				Microsoft.SqlServer.Management.Smo.Index index => index?.IsSystemObject ?? false,
				Trigger trigger => trigger?.IsSystemObject ?? false,
				User user => user?.IsSystemObject ?? false,
				_ => false
			};
		}
		catch
		{
			// Fallback in case of any property access issues
			return false;
		}
	}
}

}
