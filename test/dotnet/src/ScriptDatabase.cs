using System;
using System.Linq;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.Management.Common;
using System.Collections.Specialized;
using Microsoft.SqlServer.Management.Sdk.Sfc;
using System.Text.RegularExpressions;

namespace BabelfishDotnetFramework
{
public class LoginDatabaseScripter
{
    public static ServerConnection serverConnection;
    public static Server server;
    public static Scripter scripter;

    public static void ConnectionInitialisation()
    {
        // Initialize ServerConnection
        serverConnection = new ServerConnection(ConfigSetup.BblUrl);
        serverConnection.LoginSecure = false;
        serverConnection.Login = ConfigSetup.BblUser;
        serverConnection.Password = ConfigSetup.BblPasswd;

        // Initialize Server
        server = new Server(serverConnection);

        // Initialize Scripter with options
        scripter = new Scripter(server)
        {
            Options = {
                DriAll = true,
                ScriptSchema = true,
                ScriptData = false,
                NoCollation = true
            }
        };
    }
	public static void ScriptDatabase(string strLine, string testName, TestUtils testUtils, Serilog.Core.Logger logger)
	{
		string[] result = strLine.Split("#!#", StringSplitOptions.RemoveEmptyEntries);
		if (result.Length < 2) throw new ArgumentException("Invalid input string format");

		string flag = result[1].Trim('\r', '\n');

		try
		{
			ConnectionInitialisation();

			Database database = server.Databases[ConfigSetup.BblDb];
			if (database == null)
			{
				testUtils.PrintToLogsOrConsole($"Database '{ConfigSetup.BblDb}' not found.", logger, "information");
				return;
			}

			testUtils.PrintToLogsOrConsole($"\nScripting database: {ConfigSetup.BblDb}", logger, "information");

			ScriptDatabaseObjects(database, scripter, flag, testName, testUtils, logger);
		}
		catch (Exception ex)
		{
			testUtils.PrintToLogsOrConsole("An error occurred: " + ex.Message, logger, "information");
		}
		finally
		{
			if (server?.ConnectionContext != null)
			{
				server.ConnectionContext.Disconnect();
			}
			if (serverConnection != null)
			{
				serverConnection.Disconnect(); 
			}
		}
	}

	public static void ScriptLogins(string testName, TestUtils testUtils, Serilog.Core.Logger logger)
	{
		try
		{
			ConnectionInitialisation();

			string currentUser = server.ConnectionContext.TrueLogin;
			var logins = server.Logins.Cast<Login>()
				.Where(l => !l.IsSystemObject && l.Name != currentUser)
				.ToList();

			if (!logins.Any())
			{
				testUtils.PrintToLogsOrConsole("No user-defined logins found.", logger, "information");
				return;
			}

			// Precompile regex patterns
			Regex passwordRegex = new Regex(@"N?'(.*?)'", RegexOptions.Compiled);
			Regex commentBlockRegex = new Regex(@"(?m)^\s*/\*.*?\*/\s*$", RegexOptions.Compiled);
			Regex singleLineCommentRegex = new Regex(@"(?m)^\s*--.*$", RegexOptions.Compiled);
			Regex sidRegex = new Regex(@",\s*SID=0x[0-9A-F]+", RegexOptions.Compiled);

			foreach (Login login in logins)
			{
				try
				{
					testUtils.PrintToLogsOrConsole($"\nScripting Login: {login.Name}", logger, "information");
					StringCollection loginScripts = scripter.Script(new Urn[] { login.Urn });

					for (int i = 0; i < loginScripts.Count; i++)
					{
						// replace password with equal length * 
						loginScripts[i] = passwordRegex.Replace(loginScripts[i], match => "'" + new string('*', match.Groups[1].Value.Length) + "'");
						// remove comments
						loginScripts[i] = commentBlockRegex.Replace(loginScripts[i], "");
						loginScripts[i] = singleLineCommentRegex.Replace(loginScripts[i], "");
						loginScripts[i] = sidRegex.Replace(loginScripts[i], "");
					}
					testUtils.ResultSetWriter(loginScripts, testName);
				}
				catch (Exception ex)
				{
					testUtils.PrintToLogsOrConsole($"Could not script login {login.Name}: {ex.Message}", logger, "warning");
				}
			}
		}
		catch (Exception ex)
		{
			testUtils.PrintToLogsOrConsole($"Error in ScriptLogins: {ex.Message}", logger, "error");
		}
		finally
		{
			if (server?.ConnectionContext != null)
			{
				server.ConnectionContext.Disconnect();
			}
			if (serverConnection != null)
			{
				serverConnection.Disconnect(); 
			}
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
			return (flag == "0" && schema != sysdtb && schema != null && schema != sys_schema && !IsSystemObject(obj)) ||
				   (flag == "1" && schema != sys_schema && !IsSystemObject(obj));
		};

		// Script Tables and their child objects
		foreach (Table table in database.Tables.Cast<Table>().Where(filterObject))
		{
			scriptObject(table);
			table.Indexes.Cast<Microsoft.SqlServer.Management.Smo.Index>().Where(idx => !idx.IsSystemObject).ToList().ForEach(scriptObject);
			table.Triggers.Cast<Trigger>().Where(trg => !trg.IsSystemObject).ToList().ForEach(scriptObject);
		}

		// Script other database objects
		database.Views.Cast<View>().Where(filterObject).ToList().ForEach(scriptObject);
		database.StoredProcedures.Cast<StoredProcedure>().Where(filterObject).ToList().ForEach(scriptObject);
		database.UserDefinedFunctions.Cast<UserDefinedFunction>().Where(filterObject).ToList().ForEach(scriptObject);
		database.UserDefinedDataTypes.Cast<UserDefinedDataType>().ToList().ForEach(scriptObject);
		database.UserDefinedTableTypes.Cast<UserDefinedTableType>().ToList().ForEach(scriptObject);
		database.PartitionFunctions.Cast<PartitionFunction>().ToList().ForEach(scriptObject);
		database.PartitionSchemes.Cast<PartitionScheme>().ToList().ForEach(scriptObject);

		if (flag == "0")
		{
			database.Users.Cast<User>()
				.Where(ur => ur.Name != dbo_user && ur.Name != guest_user && !ur.IsSystemObject)
				.ToList()
				.ForEach(scriptObject);
		}
	}

	private static string GetSchema(SqlSmoObject obj)
	{
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
		return obj switch
		{
			Table table => table.IsSystemObject,
			View view => view.IsSystemObject,
			StoredProcedure sp => sp.IsSystemObject,
			UserDefinedFunction udf => udf.IsSystemObject,
			Microsoft.SqlServer.Management.Smo.Index index => index.IsSystemObject,
			Trigger trigger => trigger.IsSystemObject,
			User user => user.IsSystemObject,
			_ => false
		};
	}
}

}