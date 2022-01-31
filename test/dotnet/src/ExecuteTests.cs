using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Serilog;
using Xunit;
using Xunit.Abstractions;

namespace BabelfishDotnetFramework
{

    public class RunTests
    {
        /* 
         * We create only one Test function to run all the tests to make it more dynamic to add test cases.
         * To do so we use a multi task approach. This makes it easier for the user to only add a query-test file in a folder
         * and mention its path in the config.
         */
        IEnumerable<FileInfo> GetFilesByExtensions(DirectoryInfo dir, String[] noExecTests, params string[] extensions)
        {
            if (extensions == null) 
                throw new ArgumentNullException(nameof(extensions));
            IEnumerable<FileInfo> files = dir.EnumerateFiles("*", SearchOption.AllDirectories);
            return files.Where(f => extensions.Contains(f.Extension) && !noExecTests.Contains(f.Name));
        }
        [Fact]
        public void Test()
        {
            BatchRun batchRun = new BatchRun();
            DirectoryInfo dir = new DirectoryInfo(ConfigSetup.QueryFolder);
            IEnumerable<FileInfo> allFiles;
            string[] testName = ConfigSetup.TestName.Split("---");
            string[] noExecTests = { };
            if (testName.Length > 1)
                noExecTests = testName[1].Split(";");
            if (testName[0] == "all")
                allFiles = GetFilesByExtensions(dir, noExecTests, ".sql", ".txt");
            else
            {
                string[] tests = testName[0].Split(";");
                // allFiles 
                List<FileInfo>  tempList = new List<FileInfo>();
                foreach (string t in tests)
                {
                    if (noExecTests.Contains(t))
                        continue;
                    if (t.Trim().Length <= 1)
                        continue;
                    tempList.Add(new FileInfo(Path.Combine(ConfigSetup.QueryFolder, t.Trim())));
                }
                allFiles = tempList;
            }
            Task<bool>[] tasksInParallel = new Task<bool>[allFiles.Count()];
            bool [] result = new bool[allFiles.Count()];
            int i = 0;
            string time = DateTime.Now.ToString("hh-mm-ss-dd-MM-yy");

            foreach (FileInfo file in allFiles)
            {
                /* Delete the Output Files If it exists. */
                if (File.Exists(Path.Combine(ConfigSetup.OutputFolder, file.Name.Substring(0, file.Name.Length - 4) + ".out")))
                {
                    File.Delete(Path.Combine(ConfigSetup.OutputFolder, file.Name.Substring(0, file.Name.Length - 4) + ".out"));
                }
                if (ConfigSetup.RunInParallel)
                    tasksInParallel[i] = Task.Factory.StartNew(() => batchRun.Execute(file.Name.Substring(0, file.Name.Length - 4), time, file.FullName));
                else
                    result[i] = batchRun.Execute(file.Name.Substring(0, file.Name.Length - 4), time, file.FullName);
                i++;
            }
            if (ConfigSetup.RunInParallel)
            {
                Task.WaitAll(tasksInParallel);
                for (i = 0; i < allFiles.Count(); i++) result[i] = tasksInParallel[i].Result;
                PrintAndLogSummary(result, allFiles, time);
            }
            else
                PrintAndLogSummary(result, allFiles, time);
        }
        static void PrintAndLogSummary(bool[] result, IEnumerable<FileInfo> allFiles, string time)
        {
            /* To print Summary when tests run serially. */
            TestUtils utils = new TestUtils();
            Directory.CreateDirectory(Path.Combine(ConfigSetup.InfoFolder, time));
            var log1 = new LoggerConfiguration().MinimumLevel.Information().WriteTo.File(Path.Combine(ConfigSetup.InfoFolder, time, "SUMMARY.log")).CreateLogger();
            log1.Information("#################################################################################");
            log1.Information("################################# TESTS' STATUS  ################################");
            log1.Information("#################################################################################\n");

            Console.WriteLine("\n#################################################################################");
            Console.WriteLine("################################# TESTS' STATUS  ################################");
            Console.WriteLine("#################################################################################\n");
            utils.PrintLine();
            log1.Information(new string('-', utils.tableWidth));
            utils.PrintRow("NAME OF THE TEST", "STATUS");

            int i = 0;
            int testCount = 0;
            foreach ( FileInfo file in allFiles)
            {
                log1.Information(new string('-', utils.tableWidth));
                utils.PrintLine();
                if (result[i++] == false && BatchRun.testResults.Keys.Contains(file.FullName))
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    log1.Information(utils.PrintRow(file.Name, "FAILED" + BatchRun.testResults[file.FullName]));
                }
                else if (!BatchRun.testResults.Keys.Contains(file.FullName))
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    log1.Information(utils.PrintRow(file.Name, "FAILED OR CRAHSED"));
                }
                else
                {
                    log1.Information(utils.PrintRow(file.Name, "PASSED" + BatchRun.testResults[file.FullName]));
                    testCount++;
                }
            }
            Console.ForegroundColor = ConsoleColor.Black;
            utils.PrintLine();
            log1.Information(new string('-', utils.tableWidth));
            log1.Information(utils.PrintRow("TOTAL NUMBER OF TESTS PASSED ", testCount + "/" + allFiles.Count()));
            utils.PrintLine();
            log1.Information(new string('-', utils.tableWidth));
            Assert.True( (allFiles.Count() == testCount), "###################### NOT ALL TEST FILES PASSED ######################");
        }
    }
}
