#include <gtest/gtest.h>
#include <fstream>
#include <string>
#include <vector>

using std::string;
using std::vector;

// Trims whitespace from a string from the left and right side.
string trim(const string &s) {
  const string WHITESPACE = " \n\r\t\f\v";

  // Trim whitespace from the left.
  size_t start = s.find_first_not_of(WHITESPACE);
  string left_trimmed = ((start == string::npos) ? "" : s.substr(start));

  // Trim whitespace from the right.
  size_t end = left_trimmed.find_last_not_of(WHITESPACE);
  return (end == string::npos) ? "" : left_trimmed.substr(0, end + 1);
}

// Parses the odbc_schedule file line by line.
string ParseSchedule() {
  const string IGNORE_FLAG = "ignore#!#";
  const int IGNORE_FLAG_LENGTH = IGNORE_FLAG.length();

  string line{};
  std::ifstream schedule_file;
  schedule_file.open("odbc_schedule");

  string filter_string = "*";
  vector<string> tests_to_run;
  vector<string> tests_to_skip;

  if (!schedule_file.is_open()) {
      // ERROR: Cannot open schedule file
      // If odbc_schedule file can't be read, run all tests by default.
      return filter_string;
  }

  // Read from odbc_schedule file
  while (std::getline(schedule_file, line)) {
    line = trim(line);

    if (line.rfind("#", 0) == 0 or line.empty()) {
      continue;
    }
    
    if (line == "all") {
      return filter_string;
    }
     // If line starts with "ignore#!#", get test name and add to tests_to_skip.
    if (line.rfind(IGNORE_FLAG, 0) == 0) {
      string test_name = line.substr(IGNORE_FLAG_LENGTH);
      tests_to_skip.push_back(test_name);
    }
    else {
      tests_to_run.push_back(line);
    }
  }

  // If there are no test names in odbc_schedule file, return the string to run all tests.
  if (tests_to_run.empty() && tests_to_skip.empty()) {
    return filter_string;
  }

  // Build the string GoogleTest will use to run or skip tests.
  filter_string = "";
  for (auto it = tests_to_run.begin(); it != tests_to_run.end(); ++it) {
      filter_string.append(*it);
      filter_string.append(":");
    }

    for (auto it = tests_to_skip.begin(); it != tests_to_skip.end(); ++it) {
      filter_string.append("-");
      filter_string.append(*it);
      filter_string.append(":");
    }
  return filter_string;
}

int main(int argc, char **argv) {
  
  ::testing::InitGoogleTest(&argc, argv);
  ::testing::GTEST_FLAG(filter) = ParseSchedule();
  return RUN_ALL_TESTS();
}
