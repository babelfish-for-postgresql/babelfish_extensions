using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.IO;
using Serilog;

namespace BabelfishDotnetFramework
{
	public class BatchRun
	{
		public static Dictionary<string, string> testResults = new Dictionary<string, string>();
		
		/*
		 * BatchRunner - Backbone of all the tests. From reading the files to executing and
		 * comparing results, everything is handled here.
		 */
		bool BatchRunner(DbConnection bblCnn, string queryFilePath, Serilog.Core.Logger logger)
		{
			TestUtils testUtils = new TestUtils();
			testUtils.PrintToLogsOrConsole("Query file: " + queryFilePath,logger,"info");
			testUtils.PrintToLogsOrConsole("###########################################################################", logger, "information");
			testUtils.PrintToLogsOrConsole("############################ BATCH RUN STARTED ############################", logger, "information");
			testUtils.PrintToLogsOrConsole("###########################################################################\n", logger, "information");
			
			DbCommand bblCmd = testUtils.CreateDbCommand(null, bblCnn);
			DbTransaction bblTransaction = null;

			bool testFlag = true;

			bool isSql = queryFilePath.Substring( queryFilePath.Length - 3).Equals("sql");
			string[] temp = queryFilePath.Split('/');
			string testName = temp[^1].Substring(0, temp[^1].Length - 4); /* Extract the File Name from the File Path */

			int testCaseCount = 0; /* Holds the total number of test cases in the file. */
			int stCount = 0; /* Holds the number of tests passed. */

			try
			{
				string[] lines = null;

				lines = testUtils.ReadFile(queryFilePath);
				if (lines == null)
					return false;

				stCount = lines.Length;
				testCaseCount = lines.Length;

				for (int i = 0; i < lines.Length; i++)
				{
					string strLine = lines[i];

					/*
					 * If file is an sql script then read all the lines until the next "go".
					 */
					if(isSql)
					{
						strLine = "";
						while (i < lines.Length && !lines[i].Equals("go", StringComparison.InvariantCultureIgnoreCase)
												&& !lines[i].Equals("go;", StringComparison.InvariantCultureIgnoreCase))
						{
							strLine += lines[i++] + "\r\n";
							stCount--;
							testCaseCount--;
						}
					}
					try
					{
						if (strLine.Length < 1 || strLine.StartsWith('#'))
						{
							stCount--;
							testCaseCount--;
							continue;
						}

						string query = null;

						/* If the query is a prepare-exec statement. */
						if (strLine.StartsWith("prepst"))
						{
							string[] result = new string[10];
							result = strLine.Split("#!#", StringSplitOptions.RemoveEmptyEntries);

							/* Execute an already prepared statement. */
							if (result[1].ToLowerInvariant().StartsWith("exec"))
							{
								testUtils.PrintToLogsOrConsole("#################################################################", logger, "information");
								testUtils.PrintToLogsOrConsole("############################# EXEC ##############################", logger, "information");
								testUtils.PrintToLogsOrConsole("#################################################################\n", logger, "information");
								testUtils.PrintToLogsOrConsole(String.Format("WITH PARAMETER DEFINATION = " + strLine), logger, "information");
								if (bblTransaction != null)
								{
									bblCmd.Transaction = bblTransaction;
								}
								bblCmd = PrepareExecBinding.SetBindParams(result, bblCmd, true, logger);
								testUtils.ResultSetWriter(bblCmd, testName, ref stCount);
							}
							/* To prepare and execute a statement. */
							else if (!result[1].ToLowerInvariant().StartsWith("exec"))
							{
								bblCmd?.Dispose();
								bblCmd = testUtils.CreateDbCommand(null, bblCnn);
								testUtils.PrintToLogsOrConsole(
									$"####################### EXECUTING PREPARE/EXEC FOR QUERY- {strLine} #######################", logger, "information");
								query = result[1];
								bblCmd.CommandText = query;
								if (bblTransaction != null)
								{
									bblCmd.Transaction = bblTransaction;
								}
								bblCmd = PrepareExecBinding.SetBindParams(result, bblCmd, false, logger);
								bblCmd.Prepare();
								testUtils.ResultSetWriter(bblCmd, testName, ref stCount);
							}
						}
						/* If the query is a Transaction Manager Request. */
						else if (strLine.ToLowerInvariant().StartsWith("txn"))
						{
							string[] result = new string[10];
							result = strLine.Split("#!#", StringSplitOptions.RemoveEmptyEntries);
							bblCmd?.Dispose();
							bblCmd = testUtils.CreateDbCommand(null, bblCnn);
							testUtils.PrintToLogsOrConsole("#################################################################", logger, "information");
							testUtils.PrintToLogsOrConsole(
								$"######################### TRANSACTION {result[1]} #######################", logger, "information");
							testUtils.PrintToLogsOrConsole("#################################################################", logger, "information");
							
							if (result[1].ToLowerInvariant().StartsWith("begin"))
							{
								if (result.Length > 2)
								{
									if (result[2].ToLowerInvariant().StartsWith("isolation"))
									{
										string tranName = null;
										if (result.Length > 4)
											tranName = result[4];
										if (result[3] == "rc") /* For Isolation Read-Commited */
										{
											bblTransaction = testUtils.GetDbBeginTransaction(bblCnn,
												IsolationLevel.ReadCommitted, tranName);
											testUtils.PrintToLogsOrConsole("################### ISOLATION READ COMMITED ###################\n", logger, "information");
										}
										else if (result[3] == "rr") /* For Isolation Repeatable Read */
										{
											bblTransaction = testUtils.GetDbBeginTransaction(bblCnn,
												IsolationLevel.RepeatableRead, tranName);
											testUtils.PrintToLogsOrConsole("################### ISOLATION REPEATABLE READ ###################\n", logger, "information");
										}
										else if (result[3] == "ru") /* For Isolation Read-Uncommited */
										{
											bblTransaction = testUtils.GetDbBeginTransaction(bblCnn,
												IsolationLevel.ReadUncommitted, tranName);
											testUtils.PrintToLogsOrConsole("################### ISOLATION READ UNCOMMITED ###################\n", logger, "information");
										}
										else if (result[3] == "s") /* For Isolation Serializable */
										{
											bblTransaction = testUtils.GetDbBeginTransaction(bblCnn,
												IsolationLevel.Serializable, tranName);
											testUtils.PrintToLogsOrConsole("################### ISOLATION SERIALIZABLE ###################\n", logger, "information");
										}
										else if (result[3] == "ss") /* For Isolation Snapshot */
										{
											bblTransaction = testUtils.GetDbBeginTransaction(bblCnn,
												IsolationLevel.Snapshot, tranName);
											testUtils.PrintToLogsOrConsole("################### SNAPSHOT ###################\n", logger, "information");
										}

									}
									else
									{
										/* Begin with Transaction Name. */
										bblTransaction = testUtils.GetDbBeginTransaction(bblCnn,
											result[2]);
										testUtils.PrintToLogsOrConsole(
											$"################### TRAN BEGIN WITH NAME- {result[2]} ###################", logger, "information");
									}

								}
								else
								{
									/* Begin without Transaction Name. */
									bblTransaction = bblCnn.BeginTransaction();
									testUtils.PrintToLogsOrConsole("################### TRAN BEGIN ###################", logger, "information");
								}

							}
							else if (result[1].ToLowerInvariant().StartsWith("commit"))
							{
								bblTransaction.Commit();
							}
							else if (result[1].ToLowerInvariant().StartsWith("rollback"))
							{
								if (result.Length > 2)
								{
									/* Rollback with Name. */
									testUtils.RollbackTransaction(bblTransaction, result[2]);
								}
								else
								{
									/* Rollback without Name. */
									bblTransaction.Rollback();
								}
							}
							else if (result[1].ToLowerInvariant().StartsWith("save"))
							{
								testUtils.SaveTransaction(bblTransaction, result[2]);
							}
						}
						/* If the query is a Bulk Load Request. */
						else if (strLine.ToLowerInvariant().StartsWith("insertbulk"))
						{
							var result = strLine.Split("#!#", StringSplitOptions.RemoveEmptyEntries);
							testUtils.PrintToLogsOrConsole(
								$"########################## INSERT BULK:- {strLine} ##########################", logger, "information");
							string sourceTable = result[1];
							string destinationTable = result[2];
							testFlag &= testUtils.insertBulkCopy(bblCnn, bblCmd, sourceTable, destinationTable, logger, ref stCount);
						}
						/* Case for sp_customtype RPC. */
						else if (strLine.ToLowerInvariant().StartsWith("storedp"))
						{
							var result = strLine.Substring(13).Split("#!#", StringSplitOptions.RemoveEmptyEntries);
							testUtils.PrintToLogsOrConsole($"#################################################################", logger, "information");
							testUtils.PrintToLogsOrConsole(
								$"################### STORED PROCEDURE:- {strLine} ################", logger, "information");
							testUtils.PrintToLogsOrConsole($"#################################################################", logger, "information");
							bblCmd?.Dispose();
							bblCmd = testUtils.CreateDbCommand(null, bblCnn);
							if (bblTransaction != null)
							{
								bblCmd.Transaction = bblTransaction;
							}
							bblCmd.CommandType = CommandType.StoredProcedure;
							bblCmd.CommandText = result[1];
							bblCmd = PrepareExecBinding.SetBindParams(result, bblCmd, false, logger);
							
							testUtils.ResultSetWriter(bblCmd, testName, ref stCount);

							testUtils.PrintToLogsOrConsole("#################################################################", logger, "information");
							testUtils.PrintToLogsOrConsole("####################### END OF PROCEDURE ########################", logger, "information");
							testUtils.PrintToLogsOrConsole("#################################################################\n", logger, "information");
						}
						/* Case for Authentication Steps. */
						else if (strLine.ToLowerInvariant().StartsWith("dotnet_auth"))
						{
							testUtils.PrintToLogsOrConsole("#################################################################", logger, "information");
							testUtils.PrintToLogsOrConsole("######################## AUTHENTICATION #########################", logger, "information");
							testUtils.PrintToLogsOrConsole("#################################################################\n", logger, "information");
							if (bblCnn.State == ConnectionState.Open)
								bblCnn.Close();
							try
							{
								string conString = testUtils.AuthHelper(strLine);
								testUtils.ResultSetWriter(new SqlConnection(conString), testName);

								testUtils.PrintToLogsOrConsole("############## AUTHENTICATION PASSED #########################", logger, "information");
							}
							catch (Exception e)
							{
								testUtils.PrintToLogsOrConsole(String.Format("############## AUTHENTICATION FAILED #########################\n" + e), logger, "information");
							}
						}
						else
						{
							/*
							 * Case for simple select and other DDL and DML queries which are in the domain of "SQL Batch" request.
							 */					
							query = strLine;
							testUtils.PrintToLogsOrConsole(
								$"####################### EXECUTING SIMPLE QUERY- {query} #######################\n", logger, "information");
							if (query.ToLowerInvariant().StartsWith("select"))
							{
								bblCmd?.Dispose();
								bblCmd = testUtils.CreateDbCommand(null, bblCnn);
								if (bblTransaction != null)
								{
									bblCmd.Transaction = bblTransaction;
								}
								bblCmd.CommandText = query;

								testUtils.ResultSetWriter(bblCmd, testName, ref stCount);
							}
							else if (query.ToLowerInvariant().StartsWith("insert") || query.ToLowerInvariant().StartsWith("update") || query.ToLowerInvariant().StartsWith("alter")
									 || query.ToLowerInvariant().StartsWith("delete") || query.ToLowerInvariant().StartsWith("begin") || query.ToLowerInvariant().StartsWith("commit")
									 || query.ToLowerInvariant().StartsWith("rollback") || query.ToLowerInvariant().StartsWith("save") || query.ToLowerInvariant().StartsWith("use")
									 || query.ToLowerInvariant().StartsWith("create") || query.ToLowerInvariant().StartsWith("drop") || query.ToLowerInvariant().StartsWith("exec") || query.ToLowerInvariant().StartsWith("declare"))
							{
								bblCmd?.Dispose();
								bblCmd = testUtils.CreateDbCommand(null, bblCnn);

								if (bblTransaction != null)
								{
									bblCmd.Transaction = bblTransaction;
								}
								bblCmd.CommandText = query;

								testUtils.ResultSetWriter(bblCmd, testName, ref stCount);
								bblCmd.Dispose();								
							}
							else
							{
								bblCmd?.Dispose();
								stCount--;
								testCaseCount--;
							}

						}
					}
					catch (Exception e)
					{
						bblCmd?.Dispose();
						testUtils.PrintToLogsOrConsole(String.Format("############### QUERY COULD NOT RUN SUCCESSFULLY WITH ERROR DISPLAYED BELOW ################\n" + e), logger, "information");
						testFlag = false;
						stCount--;
					}
				}
			}
			catch (Exception e)
			{
				testUtils.PrintToLogsOrConsole(String.Format("Error: " + e),  logger, "information");
			}
			finally
			{
				bblCmd?.Dispose();
			}

			testUtils.PrintToLogsOrConsole("###########################################################################", logger, "information");
			testUtils.PrintToLogsOrConsole("############################# EXIT BATCH RUN ##############################", logger, "information");
			testUtils.PrintToLogsOrConsole("###########################################################################", logger, "information");


			testResults[queryFilePath] = "";

			return testFlag;
		}

		/* Helper Function to Execute the batchrunner. */
		public bool Execute(string testName, string time, string queryPath)
		{
			DbConnection bblCnn = null;
			bool flag = false;
			TestUtils testUtils = new TestUtils();
			string logsDirectory = Path.Combine(ConfigSetup.InfoFolder, time, testName);
			try
			{
				bblCnn = testUtils.GetDbConnection(ConfigSetup.BblConnectionString);
				bblCnn.Open();

				if(!ConfigSetup.PrintToConsole)
					System.IO.Directory.CreateDirectory(logsDirectory);

				Serilog.Core.Logger log = null;
				if(!ConfigSetup.PrintToConsole)
					log = new LoggerConfiguration().MinimumLevel.Information().WriteTo.File(Path.Combine(logsDirectory, "ResultsCompareLog.log")).CreateLogger();
				try
				{
					Console.WriteLine("[{0:HH-mm-ss-dd-MM-yyyy}]:- STARTING {1} ", DateTime.Now , testName);
					flag = BatchRunner(bblCnn, queryPath, log);
					Console.WriteLine("[{0:HH-mm-ss-dd-MM-yyyy}]:- FINISHED RUNNING {1} \n {2}", DateTime.Now,
						testName, "");
					
					flag = testUtils.GenerateDiff(testName, time, log);
				}
				catch (Exception e)
				{
					Console.WriteLine("[{0:HH-mm-ss-dd-MM-yyyy}]:- FINISHED RUNNING {1}", DateTime.Now, testName);
					Console.WriteLine(e);
					return false;
				}
			}
			catch (Exception e)
			{
				Console.WriteLine("FAILURE:- " + e);
			}
			finally
			{
				bblCnn?.Close();
			}
			return flag;
		}
	}
}
