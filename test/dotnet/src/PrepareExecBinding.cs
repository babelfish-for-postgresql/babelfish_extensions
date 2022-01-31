using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.OleDb;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.IO;
using System.Text;

namespace BabelfishDotnetFramework
{
    public static class PrepareExecBinding
    {
    	public static List<string> ListOfOutParameters;

		public static DbCommand SetBindParams(string[] result,
                                        DbCommand sqlCmd,
                                        bool execFlag,
                                        Serilog.Core.Logger logger)
		{
			TestUtils testUtils = new TestUtils();
			try
			{
				/* If sp_execute then only set value of parameter. */
				if (execFlag)
				{
					for (int i = 2; i < result.Length; i++)
					{
						string[] param = result[i].Split("|-|");
						if (param[2].Trim().ToLowerInvariant() == "<null>")
						{
							sqlCmd.Parameters[param[1]].Value = DBNull.Value;
							if (param.Length > 3)
								sqlCmd.Parameters[param[1].Trim()].Scale = byte.Parse(param[2]);
						}
						switch (param[0].Split('-')[0].Trim().ToLowerInvariant())
						{
							case "int":
							case "smallint": 
							case "bigint":
							case "tinyint":
							case "bit": 
							case "float":
							case "real":
							case "money":
							case "smallmoney":
							case "date":
							case "datetime":
							case "smalldatetime":
							case "uniqueidentifier":
								sqlCmd.Parameters[param[1].Trim()].Value = GetSqlDbValue(param[0], param[2].Trim());
								break;
							case "char":
							case "nchar":
							case "varchar":
							case "nvarchar":
							case "text":
							case "ntext":
							case "string":
							case "xml":
							{
								sqlCmd.Parameters[param[1].Trim()].Value = GetSqlDbValue(param[0], param[2].Trim());
								sqlCmd.Parameters[param[1].Trim()].Size = 100;
								/* If Locale id present and the driver is SqlClient then set it. */
								if (param.Length > 3 && ConfigSetup.Database.Equals("sql", StringComparison.InvariantCulture))
									if (param[3].Trim().ToLowerInvariant() != "input" && param[3].Trim().ToLowerInvariant() != "output"
										&& param[3].Trim().ToLowerInvariant() != "inputoutput" && param[3].Trim().ToLowerInvariant() != "return")
										((SqlParameter) sqlCmd.Parameters[param[1].Trim()]).LocaleId = int.Parse(param[3].Trim());
							} 
								break;
							case "decimal":
							case "numeric":
							{
								sqlCmd.Parameters[param[1].Trim()].Value = GetSqlDbValue(param[0], param[2].Trim());
								sqlCmd.Parameters[param[1].Trim()].Precision = byte.Parse(param[3].Trim());
								sqlCmd.Parameters[param[1].Trim()].Scale = byte.Parse(param[4].Trim());
							} 
								break;
							case "binary":
							case "varbinary":
							case "image":
							{
								sqlCmd.Parameters[param[1].Trim()].Value = GetSqlDbValue(param[0], param[2].Trim());
								sqlCmd.Parameters[param[1].Trim()].Size = ((byte[]) sqlCmd.Parameters[param[1].Trim()].Value).Length;
							} 
								break;
							case "time":
							case "datetime2":
							case "datetimeoffset":
							{
								/* varchar since we want the original value to be asigned and then set the scale. */
								sqlCmd.Parameters[param[1].Trim()].Value = GetSqlDbValue("varchar", param[2].Trim());
								sqlCmd.Parameters[param[1].Trim()].Scale = byte.Parse(param[3].Trim());
							}
								break;
							case "sql_variant":
							{
								sqlCmd.Parameters[param[1].Trim()].Size = 100; /* Todo call this recursively inorder to avoid this. */
								sqlCmd.Parameters[param[1].Trim()].Value = param[2].Trim().ToLowerInvariant() == "<null>" ?
									DBNull.Value : GetSqlDbValue(param[0].Split('-')[1].Trim(), param[2].Trim());
							}
								break;
							case "tvp":
							{
								if (ConfigSetup.Database.Equals("oledb", StringComparison.InvariantCulture))
								{
									testUtils.PrintToLogsOrConsole("TVP NOT SUPPORTED BY OLEDB", logger, "error");
									break;	
								}
								((SqlParameter) sqlCmd.Parameters[param[1].Trim()]).TypeName = param[2].Trim();
								var temp = testUtils.FetchTvpValueUsingSqlDataRecord(param[3].Trim());
								((SqlParameter) sqlCmd.Parameters[param[1].Trim()]).SqlValue = temp;
								sqlCmd.Parameters[param[1].Trim()].Size = 1000;
							}
								break;
							default:
								throw new Exception("DATATYPE NOT SUPPORTED:- " + param[0]);
						}
					}
				}
				/* If sp_prepexec then create and add Parameters with Value. */
				else
				{
					ListOfOutParameters = new List<string>();

					for (int i = 2; i < result.Length; i++)
					{

						string[] param = result[i].Split("|-|", StringSplitOptions.RemoveEmptyEntries);
						DbParameter parameter = testUtils.CreateDbParameter(param[1].Trim(), param[0].Trim());
						if (ConfigSetup.Database.Equals("oledb", StringComparison.InvariantCulture))
							ReplaceParamNameWithQuestionMark(sqlCmd, param[1].Trim());

						if (param[^1].Trim().ToLowerInvariant() == "input")
						{
							parameter.Direction = ParameterDirection.Input;
						}
						else if (param[^1].Trim().ToLowerInvariant() == "output")
						{
							ListOfOutParameters.Add(param[1].Trim());
							parameter.Direction = ParameterDirection.Output;
						}
						else if (param[^1].Trim().ToLowerInvariant() == "inputoutput")
						{
							ListOfOutParameters.Add(param[1].Trim());
							parameter.Direction = ParameterDirection.InputOutput;
						}
						else if (param[^1].Trim().ToLowerInvariant() == "return")
						{
							ListOfOutParameters.Add(param[1].Trim());
							parameter.Direction = ParameterDirection.ReturnValue;
						}

						switch (param[0].Split('-')[0].Trim().ToLowerInvariant())
						{
							case "int":
							case "smallint": 
							case "bigint":
							case "tinyint":
							case "bit": 
							case "float":
							case "real":
							case "money":
							case "smallmoney":
							case "date":
							case "datetime":
							case "smalldatetime":
							case "uniqueidentifier":
								parameter.Value = GetSqlDbValue(param[0], param[2].Trim());
								break;
							case "char":
							case "nchar":
							case "varchar":
							case "nvarchar":
							case "text":
							case "ntext":
							case "string":
							case "xml":
							{
								parameter.Value = GetSqlDbValue(param[0], param[2].Trim());
								parameter.Size = 100;
								/* If Locale id present and its sql server then set it. */
								if (param.Length > 3 && ConfigSetup.Database.Equals("sql", StringComparison.InvariantCulture))
									if (param[3].Trim().ToLowerInvariant() != "input" && param[3].Trim().ToLowerInvariant() != "output"
										&& param[3].Trim().ToLowerInvariant() != "inputoutput" && param[3].Trim().ToLowerInvariant() != "return")
										((SqlParameter) parameter).LocaleId = int.Parse(param[3].Trim());
							} 
								break;
							case "decimal":
							case "numeric":
							{
								parameter.Value = GetSqlDbValue(param[0], param[2].Trim());
								parameter.Precision = byte.Parse(param[3].Trim());
								parameter.Scale = byte.Parse(param[4].Trim());
							} 
								break;
							case "binary":
							case "varbinary":
							case "image":
							{
								parameter.Value = GetSqlDbValue(param[0], param[2].Trim());
								parameter.Size = ((byte[]) parameter.Value).Length;
							} 
								break;
							case "time":
							case "datetime2":
							case "datetimeoffset":
							{
								parameter.Size = -1;
								/* varchar since we want the original value to be asigned and then set the scale. */
								parameter.Value = GetSqlDbValue("varchar", param[2].Trim());
								parameter.Scale = byte.Parse(param[3].Trim());
							}
								break;
							case "sql_variant":
							{
								parameter.Size = 100;
								parameter.Value = param[2].Trim().ToLowerInvariant() == "<null>" ?
									DBNull.Value : GetSqlDbValue(param[0].Split('-')[1].Trim(), param[2].Trim());
							}
								break;
							case "tvp":
							{
								if (ConfigSetup.Database.Equals("oledb", StringComparison.InvariantCulture))
								{
									testUtils.PrintToLogsOrConsole("TVP NOT SUPPORTED BY OLEDB", logger, "error");
									break;	
								}
								((SqlParameter) parameter).TypeName = param[2].Trim();
								var temp = testUtils.FetchTvpValueUsingSqlDataRecord(param[3].Trim());
								((SqlParameter) parameter).SqlValue = temp;
								parameter.Size = 1000;
							}
								break;
							default:
								throw new Exception("DATATYPE NOT SUPPORTED:- " + param[0]);
						}
						sqlCmd.Parameters.Add(parameter);
					}
				}

			}
			catch (Exception e)
			{
				testUtils.PrintToLogsOrConsole(String.Format("################### ERROR WITH SETTING PARAMETERS ###################\n" + e), logger, "information");
			}
			return sqlCmd;
		}

		/* Used for Oledb drivers to convert bind variables from @name to ?. */
	    static void ReplaceParamNameWithQuestionMark(DbCommand cmd, string paramName)
		{
			cmd.CommandText = cmd.CommandText.Replace("@" + paramName, "?");
		}

		/* Returns the OleDb Type for OleDb drivers. */
		public static OleDbType GetOleDbType(string type)
		{
			switch (type.Split('-')[0].ToLower())
			{
				case "int":
					return OleDbType.Integer;
				case "smallint":
					return OleDbType.SmallInt;
				case "bigint":
					return OleDbType.BigInt;
				case "tinyint":
					return OleDbType.TinyInt;
				case "bit":
					return OleDbType.Boolean;
				case "nchar":
					return OleDbType.WChar;
				case "varchar":
					return OleDbType.VarChar;
				case "char":
					return OleDbType.Char;
				case "nvarchar":
				case "string":
					return OleDbType.VarWChar;
				case "text":
					return OleDbType.VarChar;
				case "ntext":
					return OleDbType.VarWChar;
				case "float":
					return OleDbType.Double;
				case "decimal":
				case "numeric":
					return OleDbType.Decimal;
				case "real":
					return OleDbType.Double;
				case "date":
					return OleDbType.DBDate;
				case "time":
					return OleDbType.DBTime;
				case "datetime":
					return OleDbType.DBTimeStamp;
				case "datetime2":
					return OleDbType.DBTimeStamp;
				case "binary":
					return OleDbType.Binary;
				case "varbinary":
					return OleDbType.VarBinary;
				case "uniqueidentifier":
					return OleDbType.Guid;
				case "sql_variant":
					return OleDbType.Variant;
				default:
					throw new Exception("DATA TYPE NOT SUPPORTED " + type);
			}
		}

		/* Returns the SqlDb Type for SqlClient drivers. */
		public static SqlDbType GetSqlDbType(string type)
		{
			switch (type.Split('-')[0].ToLower())
			{
				case "int":
					return SqlDbType.Int;
				case "smallint":
					return SqlDbType.SmallInt;
				case "bigint":
					return SqlDbType.BigInt;
				case "tinyint":
					return SqlDbType.TinyInt;
				case "bit":
					return SqlDbType.Bit;
				case "nchar":
					return SqlDbType.NChar;
				case "varchar":
					return SqlDbType.VarChar;
				case "char":
					return SqlDbType.Char;
				case "nvarchar":
				case "string":
					return SqlDbType.NVarChar;
				case "text":
					return SqlDbType.Text;
				case "ntext":
					return SqlDbType.NText;
				case "float":
					return SqlDbType.Float;
				case "decimal":
				case "numeric":
					return SqlDbType.Decimal;
				case "money":
					return SqlDbType.Money;
				case "smallmoney":
					return SqlDbType.SmallMoney;
				case "real":
					return SqlDbType.Real;
				case "smalldatetime":
					return SqlDbType.SmallDateTime;
				case "date":
					return SqlDbType.Date;
				case "time":
					return SqlDbType.Time;
				case "datetime":
					return SqlDbType.DateTime;
				case "datetimeoffset":
					return SqlDbType.DateTimeOffset;
				case "datetime2":
					return SqlDbType.DateTime2;
				case "binary":
					return SqlDbType.Binary;
				case "varbinary":
					return SqlDbType.VarBinary;
				case "image":
					return SqlDbType.Image;
				case "xml":
					return SqlDbType.Xml;
				case "uniqueidentifier":
					return SqlDbType.UniqueIdentifier;
				case "sql_variant":
					return SqlDbType.Variant;
				case "tvp":
					return SqlDbType.Structured;
				case "udt":
					return SqlDbType.Udt;
				default:
					throw new Exception("DATA TYPE NOT SUPPORTED " + type);
			}
		}

		/* Returns the Value after an appropriate parse for a particular type. */
		public static object GetSqlDbValue(string type, string value)
		{
			if(value.ToLower() == "<null>")
				return DBNull.Value;
			switch (type.ToLower())
			{
				case "int":
					return Int32.Parse(value);
				case "smallint":
					return Int16.Parse(value);
				case "bigint":
					return Int64.Parse(value);
				case "tinyint":
					return byte.Parse(value);
				case "bit":
					return bool.Parse(value);
				case "nchar":
					return value;
				case "varchar":
					return value;
				case "char":
				case "nvarchar":
				case "string":
					return value;
				case "text":
				case "ntext":
					string result = "";
					string[] read = File.ReadAllLines(value);
					foreach (string line in read)
						result += line + '\n';
					result.Remove(result.Length - 1);
					return result;
				case "float":
					return double.Parse(value);
				case "decimal":
				case "numeric":
					return decimal.Parse(value);
				case "money":
				case "smallmoney":
					return SqlMoney.Parse(value);
				case "real":
					return Single.Parse(value);
				case "date":
				case "datetime":
				case "smalldatetime":
				case "datetime2":
					return DateTime.Parse(value);
				case "time":
					return TimeSpan.Parse(value);
				case "binary":
				case "varbinary":
					byte[] byteArray = Encoding.ASCII.GetBytes(value);
					return byteArray;
				case "image":
					FileStream fs = new FileStream(value, FileMode.Open, FileAccess.Read);
					BinaryReader br = new BinaryReader(fs);
					byteArray = br.ReadBytes((Int32)fs.Length);
					return byteArray;
				case "xml":
					return value;
				case "uniqueidentifier":
					return new Guid(value);
				default:
					return value;
			}
		}
	}
}
