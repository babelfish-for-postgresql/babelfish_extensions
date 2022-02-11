using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.OleDb;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Diagnostics;
using System.IO;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;
using Microsoft.SqlServer.Server;
using Serilog;
using Serilog.Core;
using Xunit;

namespace BabelfishDotnetFramework
{
	public class TestUtils
	{
		public void PrintToLogsOrConsole(string message, Logger logger, string logLevel)
		{
			if (ConfigSetup.PrintToConsole)
				Console.WriteLine(message);
			else
			{
				if (logLevel.ToLower() == "information")
					logger.Information(message);
				else if (logLevel.ToLower() == "error")
					logger.Error(message);
				else if (logLevel.ToLower() == "warning")
					logger.Warning(message);
			}
		}

		public bool insertBulkCopy(DbConnection bblCnn, DbCommand bblCmd, String sourceTable, String destinationTable, Logger logger, ref int stCount)
		{
			bblCmd.CommandText = "Select * from " + sourceTable;
			DbDataReader reader = null;
			try
			{
				reader = bblCmd.ExecuteReader();
				SqlBulkCopy bulkCopy = new SqlBulkCopy(ConfigSetup.BblConnectionString);
				bulkCopy.DestinationTableName = destinationTable;
				bulkCopy.WriteToServer(reader);
			}
			catch (Exception e)
			{
				PrintToLogsOrConsole("#################################################################", logger, "information");
				PrintToLogsOrConsole(
					$"############# ERROR IN EXECUTING WITH BABEL  ####################\n{e}\n",
					logger, "information");
				stCount--;
				return false;
			}
			finally
			{
				reader.Close();
			}
			return true;
		}

		public void ResultSetWriter(DbConnection cnn, string fileName)
		{
			// USED TO WRITE THE CONNECTION AUTHENTICATIONS IN ONE FILE
			using var file =
				new StreamWriter(Path.Combine(ConfigSetup.OutputFolder, fileName + ".out"), true);
			file.WriteLine("#Q#" + cnn.ConnectionString);
			try
			{
				cnn.Open();
				file.WriteLine("PASSED");
			}
			catch (Exception e)
			{
				file.WriteLine("#E#" + e.Message);
			}
		}
		public void ResultSetWriter(DbCommand cmd, string fileName, ref int count)
		{
			// USED TO WRITE THE RESULT-SETS IN ONE FILE
			using var file =
				new StreamWriter(Path.Combine(ConfigSetup.OutputFolder, fileName + ".out"), true);
			file.WriteLine("#Q#" + cmd.CommandText);
			DbDataReader rdr = null;
			try
			{
				rdr = cmd.ExecuteReader();
			}
			catch (Exception e)
			{
				file.WriteLine("#E#" + e.Message);
				rdr?.Close();
				return;
			}
			int totalNumberOfCol = rdr.FieldCount;
			
			try
			{
				if (rdr.Read())
				{
					string temp = null;
					int colNumber;
					file.Write("#D#");
					for (colNumber = 0; colNumber < totalNumberOfCol - 1; colNumber++)
					{
						file.Write(rdr.GetDataTypeName(colNumber) + "#!#");
						if (rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("image")
							|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("binary")
							|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("varbinary"))
							temp += rdr.GetValue(colNumber) == DBNull.Value
								? null
								: BinaryToString((byte[]) rdr.GetValue(colNumber)) + "#!#";
						else
							temp += rdr.GetValue(colNumber) + "#!#";
					}
					file.WriteLine(rdr.GetDataTypeName(colNumber));
					if (rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("image")
						|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("binary")
						|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("varbinary"))
						file.WriteLine(temp + (rdr.GetValue(colNumber) == DBNull.Value
							? null
							: BinaryToString((byte[]) rdr.GetValue(colNumber))));
					else
						file.WriteLine(temp + rdr.GetValue(colNumber));
				}

				do
				{
					while (rdr.Read())
					{
						//comparing all Column values
						int colNumber;
						for (colNumber = 0; colNumber < totalNumberOfCol - 1; colNumber++)
						{
							if (rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("image")
								|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("binary")
								|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("varbinary"))
								file.WriteLine(rdr.GetValue(colNumber) == DBNull.Value
									? null
									: BinaryToString((byte[]) rdr.GetValue(colNumber)) + "#!#");
							else
								file.Write(rdr.GetValue(colNumber) + "#!#");
						}

						if (rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("image")
							|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("binary")
							|| rdr.GetDataTypeName(colNumber).ToLowerInvariant().StartsWith("varbinary"))
							file.WriteLine(rdr.GetValue(colNumber) == DBNull.Value
								? null
								: BinaryToString((byte[]) rdr.GetValue(colNumber)));
						else
							file.WriteLine(rdr.GetValue(colNumber));
					} 
				} while (rdr.NextResult());

				if (PrepareExecBinding.ListOfOutParameters.Count > 0)
				{
					file.WriteLine($"--OUT PARAMETERS--");
					foreach (string param in PrepareExecBinding.ListOfOutParameters)
					{
						file.WriteLine(cmd.Parameters[param]);
						file.WriteLine(cmd.Parameters[param].DbType.ToString());
						file.WriteLine(cmd.Parameters[param].Value.ToString() + '\n');
					}
					PrepareExecBinding.ListOfOutParameters.Clear();
				}
			}
			catch
			{
				count--;
			}
			finally
			{
				rdr?.Close();
			}
		}

		string BinaryToString(byte[] a)
		{
			string s = null;
			if(a != null)
				foreach (var temp in a)
				{
					s += temp;
				}
			return s;
		}

		private static Type GetDType(string name)
		{
			// FETCHES THE DATA TYPE FROM THE STRING
			Type type = null;
			name = name.ToLower();
			if (name.Equals("int", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Int32");
			}
			else if (name.Equals("smallint", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Int16");
			}
			else if (name.Equals("bigint", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Int64");
			}
			else if (name.Equals("tinyint", StringComparison.InvariantCultureIgnoreCase))
			{
				// int 32 just to differentiate from Binary types
				type = Type.GetType("System.Int32");
			}
			else if (name.Equals("nchar", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.String");
			}
			else if (name.Equals("nvarchar", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.String");
			}
			else if (name.Equals("bit", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Boolean");
			}
			else if (name.Equals("float", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Double");
			}
			else if (name.Equals("numeric", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Decimal");
			}
			else if (name.Equals("money", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Decimal");
			}
			else if (name.Equals("smallmoney", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Decimal");
			}
			else if (name.Equals("real", StringComparison.InvariantCultureIgnoreCase))
			{

				type = Type.GetType("System.Single");
			}
			else if (name.Equals("smalldatetime", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.DateTime");
			}
			else if (name.Equals("datetime", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.DateTime");
			}
			else if (name.Equals("binary", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Byte");
			}
			else if (name.Equals("varbinary", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Byte");
			}
			else if (name.Equals("image", StringComparison.InvariantCultureIgnoreCase))
			{
				type = Type.GetType("System.Byte");
			}
			return type;
		}
		static List<List<string>> FetchTvpTableFromFile(string file)
		{
			var rows = new List<List<string>>();
			using var reader = new StreamReader(file);
			while (!reader.EndOfStream)
			{
				var columns = new List<string>();
				var line = reader.ReadLine();
				if (line != null)
				{
					var values = line.Split(',');

					foreach (var value in values)
					{
						columns.Add(value);
					}
				}
				rows.Add(columns);
			}

			return rows;
		}

		private static readonly List<string> VarTypes = new List<string> { "varchar", "char", "nvarchar", "nchar", "varbinary", "binary"};
		private static readonly List<string> DecimalTypes = new List<string> { "numeric", "decimal"};
		public SqlDataRecord[] FetchTvpValueUsingSqlDataRecord(string file)
		{
			List<List<string>> rows = FetchTvpTableFromFile(file);
			int numberOfRows = rows.Count;
			int numberOfColumns = rows[0].Count;
			SqlDataRecord[] record = new SqlDataRecord[numberOfRows - 1];
			SqlMetaData[] metadata = new SqlMetaData[numberOfColumns];

			for (var currentCol = 0; currentCol < numberOfColumns; currentCol++)
			{
				if (VarTypes.Contains(rows[0][currentCol].Split("-")[1].ToLowerInvariant()))
				{
					metadata[currentCol] = new SqlMetaData(rows[0][currentCol].Split("-")[0],
						PrepareExecBinding.GetSqlDbType(rows[0][currentCol].Split("-")[1]), long.Parse(rows[0][currentCol].Split("-")[2]));
				}
				else if(DecimalTypes.Contains(rows[0][currentCol].Split("-")[1].ToLowerInvariant()))
					metadata[currentCol] = new SqlMetaData(rows[0][currentCol].Split("-")[0],
							PrepareExecBinding.GetSqlDbType(rows[0][currentCol].Split("-")[1]), byte.Parse(rows[0][currentCol].Split("-")[2]), byte.Parse(rows[0][currentCol].Split("-")[3]));
				else
				{
					metadata[currentCol] = new SqlMetaData(rows[0][currentCol].Split("-")[0],
						PrepareExecBinding.GetSqlDbType(rows[0][currentCol].Split("-")[1]));
				}
			}

			for (var currentRow = 1; currentRow < numberOfRows; currentRow++)
			{
				record[currentRow - 1] = new SqlDataRecord(metadata);
				for (int currentCol = 0; currentCol < numberOfColumns; currentCol++)
					record[currentRow - 1].SetValue(currentCol,
						PrepareExecBinding.GetSqlDbValue(rows[0][currentCol].Split("-")[1], rows[currentRow][currentCol]));
			}
			return record;
		}
		public DataTable FetchTvpValue(string file)
		{
			List<List<string>> rows = FetchTvpTableFromFile(file);
			int numberOfRows = rows.Count;
			int numberOfColumns = rows[0].Count;
			DataTable table = new DataTable();
			string[] columnName = new string[numberOfColumns];
			for (int currentCol = 0; currentCol < numberOfColumns; currentCol++)
			{
				// add the column metadata
				table.Columns.Add(rows[0][currentCol].Split("-")[0], GetDType(rows[0][currentCol].Split("-")[1]));
				columnName[currentCol] = rows[0][currentCol].Split("-")[0];
			}

			// add the TVP rows
			for (int currentRow = 1; currentRow < numberOfRows; currentRow++)
			{
				DataRow newRow = table.NewRow();
				for (int currentCol = 0; currentCol < numberOfColumns; currentCol++)
				{
					newRow[columnName[currentCol]] = rows[currentRow][currentCol];
				}
				table.Rows.Add(newRow);
			}
			return table;
		}
		public string AuthHelper(string strLine)
		{
			Dictionary<string, string> dictionary = ConfigSetup.LoadConfig();
			dictionary["url"] = dictionary["babel_URL"];
			dictionary["db"] = dictionary["babel_databaseName"];
			dictionary["user"] = dictionary["babel_user"];
			dictionary["pwd"] = dictionary["babel_password"];
			dictionary["others"] = "";

			string[] result = new string[10];
			result = strLine.Split("#!#", StringSplitOptions.RemoveEmptyEntries);
			for (int i = 1; i < result.Length; i++)
			{
				if (result[i].ToLowerInvariant().StartsWith("pwd"))
					dictionary["pwd"] = result[i].Split("|-|")[1];
				else if (result[i].ToLowerInvariant().StartsWith("db"))
					dictionary["db"] = result[i].Split("|-|")[1];
				else if (result[i].ToLowerInvariant().StartsWith("user"))
					dictionary["user"] = result[i].Split("|-|")[1];
				else if (result[i].ToLowerInvariant().StartsWith("others"))
					dictionary["others"] = result[i].Split("|-|")[1];
			}
			return @"Data Source = " + dictionary["url"] + "; Initial Catalog = " + dictionary["db"] +
												"; User ID = " + dictionary["user"] + "; Password = " + dictionary["pwd"] + ";Pooling=false;" + dictionary["others"];
		}

		/* Depending on the OS we use the appropriate diff command. */
        ProcessStartInfo GetDiffFileProcessDependingOnOs(string output, string expectedOutput, string diffFile)
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                return new  ProcessStartInfo
                {
                    FileName = @"powershell.exe",
                    Arguments = $"-c \"diff (cat {output}) (cat {expectedOutput}) > {diffFile}\"",
                    UseShellExecute = false,
                    CreateNoWindow = false,
                    RedirectStandardError = true
                };
            return new  ProcessStartInfo
            {
                FileName = @"bash",
                Arguments = $"-c \"diff {output} {expectedOutput} > {diffFile}\"",
                UseShellExecute = false,
                CreateNoWindow = false,
                RedirectStandardError = true
            };
        }

		public bool GenerateDiff(string testName, string time, Logger log)
		{
			string output = Path.Combine(ConfigSetup.OutputFolder, testName + ".out");
			string expectedOutput = Path.Combine(ConfigSetup.ExpectedOutputFolder, testName + ".out");
			string diffFile = Path.Combine(ConfigSetup.InfoFolder, time, testName + ".diff");
			if (!Directory.Exists(Path.Combine(ConfigSetup.InfoFolder, time)))
				Directory.CreateDirectory(Path.Combine(ConfigSetup.InfoFolder, time));
			var ps = GetDiffFileProcessDependingOnOs(output, expectedOutput, diffFile);
			var process = Process.Start(ps);
			if (process != null)
			{
				process.WaitForExit();
				process.Kill();
				var tempArray = ReadFile(diffFile);	
				PrintToLogsOrConsole($"DIFF RETURN VALUE: " + (tempArray.Length > 0 ? "1" :"0"), log, "info");
				if (ConfigSetup.PrintToConsole)
				{
					string temp = "";
					foreach (var line in tempArray)
					{
						temp += line+"\r\n";
					}
					PrintToLogsOrConsole(temp, log, "info");
				}
				return process.ExitCode.ToString().Equals("0");
			}

			return false;
		} 
		public int tableWidth = 73;
		
		/* USED TO PRINT THE OUTPUT */
		public void PrintLine()
		{
			Console.ForegroundColor = ConsoleColor.Black;
			Console.WriteLine(new string('-', tableWidth));
		}

		public string PrintRow(params string[] columns)
		{
			int width = (tableWidth - columns.Length) / columns.Length;
			string row = "|";

			foreach (string column in columns)
			{
				row += AlignCentre(column, width) + "|";
			}
			Console.WriteLine(row);
			return row;
		}

		/* USED TO PRINT THE OUTPUT */
		string AlignCentre(string text, int width)
		{
			text = text.Length > width ? text.Substring(0, width - 3) + "..." : text;

			if (string.IsNullOrEmpty(text))
			{
				return new string(' ', width);
			}

			return text.PadRight(width - (width - text.Length) / 2).PadLeft(width);
		}

		public DbConnection GetDbConnection(string connectionString)
		{
			return ConfigSetup.Database.ToLowerInvariant() switch
			{
				"oledb" => new OleDbConnection(connectionString),
				"sql" => new SqlConnection(connectionString),
				_ => null
			};
		}

		public DbCommand CreateDbCommand(string commandText, DbConnection con)
		{
			return ConfigSetup.Database.ToLowerInvariant() switch
			{
				"oledb" => new OleDbCommand(commandText, (OleDbConnection) con),
				"sql" => new SqlCommand(commandText, (SqlConnection) con),
				_ => null
			};
		}

		public DbTransaction GetDbBeginTransaction(DbConnection con, IsolationLevel i, string tranName)
		{
			switch (ConfigSetup.Database.ToLowerInvariant())
			{
				case "oledb": return ((OleDbConnection) con).BeginTransaction(i);
				case "sql": return ((SqlConnection) con).BeginTransaction(i, tranName);
				default:
					return null;
			}
		}
		public DbTransaction GetDbBeginTransaction(DbConnection con, string tranName)
		{
			switch (ConfigSetup.Database.ToLowerInvariant())
			{
				case "oledb": return ((OleDbConnection) con).BeginTransaction();
				case "sql": return ((SqlConnection) con).BeginTransaction(tranName);
				default:
					return null;
			}
		}
		public void RollbackTransaction(DbTransaction transaction, string tranName)
		{
			switch (ConfigSetup.Database.ToLowerInvariant())
			{
				case "oledb":
						((OleDbTransaction) transaction).Rollback();
					break;
				case "sql":
					((SqlTransaction) transaction).Rollback(tranName);
					break;
			}
		}

		public void SaveTransaction(DbTransaction transaction, string tranName)
		{
			switch (ConfigSetup.Database.ToLowerInvariant())
			{
				case "sql":
					((SqlTransaction) transaction).Save(tranName);
					break;
			}
		}

		public DbParameter CreateDbParameter(string parameterName, string dbType)
		{
			switch (ConfigSetup.Database.ToLowerInvariant())
			{
				case "oledb":
					return new OleDbParameter
					{
						ParameterName =  parameterName,
						OleDbType = PrepareExecBinding.GetOleDbType(dbType),
					};
				case "sql": 
					return new SqlParameter
					{
						ParameterName = parameterName,
						SqlDbType = PrepareExecBinding.GetSqlDbType(dbType)
					};
				default:
					return null;
			}
		}

		/* Read Queries from file */
		public string[] ReadFile(string queryFilePath)
		{
			try
			{
				return File.ReadAllLines(queryFilePath);
			}
			catch (Exception e)
			{
				Console.WriteLine("No such file: " + e);
				Console.WriteLine(queryFilePath);
				return null;
			}
		}
	}
}
