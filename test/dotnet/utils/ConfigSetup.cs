using System;
using System.Collections.Generic;
using System.IO;

namespace BabelfishDotnetFramework
{
	public static class ConfigSetup
	{
		/* Declaring variables required for a Test Run. */
		static readonly Dictionary<string, string> Dictionary = LoadConfig();
		public static readonly string BblConnectionString = Dictionary["bblConnectionString"];
		public static readonly string QueryFolder = Dictionary["queryFolder"];
		public static readonly string TestName = Dictionary["testName"];
		public static readonly bool RunInParallel = bool.Parse(Dictionary["runInParallel"]);
		public static readonly bool PrintToConsole = bool.Parse(Dictionary["printToConsole"]);
		public static string Database;
		public static string Provider = Dictionary["provider"];

		/* Using relative paths to locate some important files and folders. */
		public static string InfoFolder = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", "Info");
        public static string OutputFolder = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", "Output");
        public static string ExpectedOutputFolder = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", "ExpectedOutput");

		/* Load configurations from config.txt file. */
		public static Dictionary<string, string> LoadConfig()
		{
			string ConfigFile = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", "config.txt");
			var lines = File.ReadAllLines(ConfigFile);

			Dictionary<string, string> dictionary = new Dictionary<string, string>();
			foreach (string line in lines)
			{
				if (string.IsNullOrWhiteSpace(line)) continue;
				/* Remove extra spaces. */
				string nLine = line.Trim();
				if (nLine[0] == '#') continue;
				string[] kvp = nLine.Split('=');
				if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable(kvp[0].Trim())))
					dictionary[kvp[0].Trim()] = kvp[1].Trim(); // kvp[0] = key, kvp[1] = value
				else
					dictionary[kvp[0].Trim()] = Environment.GetEnvironmentVariable(kvp[0].Trim());
			}
			Database = dictionary["driver"];
			Provider = dictionary["provider"];

			/* Creating Server Connection String and Query. */
			dictionary["bblConnectionString"] = BuildConnectionString(dictionary["babel_URL"], dictionary["babel_port"],
				dictionary["babel_databaseName"],
				dictionary["babel_user"], dictionary["babel_password"]);
			return dictionary;
		}

		static string BuildConnectionString(string url, string port, string db, string uid, string pwd)
		{
			switch (ConfigSetup.Database.ToLowerInvariant())
			{
				case "oledb":
					return @"Provider = " + ConfigSetup.Provider + ";Data Source = " + url + "," + port + "; Initial Catalog = " + db
						   + "; User ID = " + uid + "; Password = " + pwd + ";Pooling=false;";
				case "sql":
					return @"Data Source = " + url + "," + port + "; Initial Catalog = " + db
						   + "; User ID = " + uid + "; Password = " + pwd + ";Pooling=false;";
				default:
					throw new Exception("Driver Not Supported");
			}
		}
	}
}
