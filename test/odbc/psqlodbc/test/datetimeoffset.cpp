#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.datetimeoffset_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.datetimeoffset";
const string VIEW_NAME = "master_dbo.datetimeoffset_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DATA_COLUMN = 2;

static const string DATE_TIME_FORMAT{"%Y-%m-%d %H:%M:%S"};
static const string DEFAULT_TIME{" 00:00:00"};
static const string DEFAULT_DATE_TIME{"1900-01-01 00:00:00 +00:00"};

class PSQL_DataTypes_DateTimeOffset : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_teardown(Drivers::GetDriver(ServerType::PSQL));
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

// Helper to get the local timezone (with considerations for daylight savings) for given date
string getTimeZone(const string& date_time) {
  std::istringstream ss{ date_time };
  std::tm dt = {0,0,0,0,0,0,0,0,0};
  ss >> std::get_time(&dt, DATE_TIME_FORMAT.c_str());
  time_t time_obj = std::mktime(&dt);
  time_t* time_ptr = &time_obj;
  tm* offset_epoch = std::localtime(time_ptr);
  std::string ret = std::to_string(offset_epoch->tm_gmtoff / 3600);

  switch (ret.length()) {
    case 0:
      ret.insert(0, "+00");
      break;
    case 1:
      ret.insert(0, "+0");
      break;
    case 2:
      ret.insert(1, "0");
  }
  return " " + ret + ":00";
}

// Helper to generate the expected fully qualified datetimeoffset
string generateExpected(const string& date_time) {
  int num_of_spaces = std::count(date_time.begin(), date_time.end(), ' ');

  switch (num_of_spaces) {
    case 0:
      if (date_time == "NULL") {
        return "NULL";
      }
      if (date_time.empty()) {
        return DEFAULT_DATE_TIME;
      } 
      else {
        return date_time + DEFAULT_TIME + getTimeZone(date_time);
      }
    case 1:
      return date_time + getTimeZone(date_time);
    case 2:
      return date_time;
    default:
      return DEFAULT_DATE_TIME;
  }
}

string dateComparisonHelper(const string& date_time) {
  std::istringstream ss{ date_time };
  std::tm dt = {0,0,0,0,0,0,0,0,0};
  ss >> std::get_time(&dt, DATE_TIME_FORMAT.c_str());
  time_t time_obj = std::mktime(&dt);
  time_t* time_ptr = &time_obj;  

  int timezone_hr = atoi(date_time.substr(date_time.length() - 5, 2).c_str());
  int timezone_min = atoi(date_time.substr(date_time.length() - 2, 2).c_str());
  switch (date_time[date_time.length() - 6]) {
    case '-':
      time_obj += timezone_hr * 3600;
      time_obj += timezone_min * 60;
      break;
    case '+':
      time_obj -= timezone_hr * 3600;
      time_obj -= timezone_min * 60;
      break;
  }
  tm* res = std::localtime(time_ptr);
  size_t millisecond_pos = date_time.find('.');
  string millisecond = millisecond_pos != std::string::npos ? date_time.substr(millisecond_pos, date_time.length() - 6 - millisecond_pos) : "";

  char ret[BUFFER_SIZE] = "";
  sprintf(ret, "%02d-%02d-%02d %02d:%02d:%02d%s",
          res->tm_year + 1900,
          res->tm_mon,
          res->tm_mday,
          res->tm_hour,
          res->tm_min,
          res->tm_sec,
          millisecond.c_str()
          );
  return string(ret);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Table_Creation) {
  // TODO - Expected needs to be fixed.
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Insertion_Success) {
  // NOTE: Inserted Values depend on server's timezone if not specified in insert
  //       Expected Values generated based on localtime's timezone
  //       Make sure server & client are in the same timezone
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "",                                  // Default Value
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",               // Min
    "9999-06-06 23:59:29.999999",        // Max
    "1900-01-01 23:59:59 +14:00",
    "1900-01-01 00:00:00 +12:00",
    "1900-01-01 00:00:00.999999 +12:00",
    "1900-01-01 00:00:00.123456 +12:00",
    "1900-01-01 00:00:00.1",
    "1900-01-01 00:00:00.12",
    "1900-01-01 00:00:00.123",
    "1900-01-01 00:00:00.1234",
    "1900-01-01 00:00:00.12345",
    "1900-01-01 00:00:00.123456",
  };

  // NOTE: Expected Values depend on computer/server's timezone
  vector<string> expected_values = {};
  const int NUM_OF_INSERTS = INSERTED_VALUES.size();

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    expected_values.push_back(generateExpected(INSERTED_VALUES[i]));
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, expected_values);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    // "01-01-2000",                   // Format, MM-DD-YEAR is Valid in Ubuntu 20, Invalid in Ubuntu 22
    "December 31, 1900 CE",
    "10000-01-01 00:00:00",         // Year
    "0000-12-31 00:00:00",
    "0000-01-01 00:00:00",
    "1900-32-01 00:00:00",          // Month
    "1900-00-01 00:00:00",
    "1900-01-32 00:00:00",          // Day
    "1900-01-00 00:00:00",
    "1900-02-31 00:00:00",          // Feb 31st
    // "0001-01-01 24:00:00", 	        // Hour (ODBC considers hr24 as a valid insert despite being out of range [0-23])
    "0001-01-01 00:60:00",          // Minutes
    // "0001-01-01 00:00:60", 	        // Seconds  (ODBC considers 60s as a valid insert despite being out of range [0-59]), rounds up to next minute
    "1900-02-31 00:00:00 +15:00",   // Timezone
    "1900-02-31 00:00:00 -15:00",
    "1900-02-31 00:00:00 +00:60",
    "1900-02-31 00:00:00 -00:60",
  };
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Update_Success) {
  const vector<string> DATA_INSERTED = {
    "1900-01-01 00:00:00 +00:00"
  };

  // NOTE: Inserted Values depend on server's timezone if not specified in insert
  //       Expected Values generated based on localtime's timezone
  //       Make sure server & client are in the same timezone
  const vector<string> DATA_UPDATED_VALUES = {
    "NULL",
    "",                                  // Default Value
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",               // Min
    "9999-06-06 23:59:29.999999",        // Max
    "1900-01-01 23:59:59 +14:00",
    "1900-01-01 00:00:00 +12:00",
    "1900-01-01 00:00:00.999999 +12:00",
    "1900-01-01 00:00:00.123456 +12:00",
  };

  // NOTE: Expected Values depend on computer/server's timezone
  vector<string> expected_values = {};
  const int NUM_OF_DATA = DATA_UPDATED_VALUES.size();

  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_values.push_back(generateExpected(DATA_UPDATED_VALUES[i]));
  }
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, DATA_INSERTED, DATA_INSERTED);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES, expected_values);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Update_Fail) {
  const vector<string> DATA_INSERTED = {
    "1900-01-01 00:00:00 +00:00"
  };

  const vector<string> DATA_UPDATED_VALUE = {
    "1900-02-31 00:00:00" // Feb 31st
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, DATA_INSERTED, DATA_INSERTED);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_INSERTED, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// Explicit casting is used, ie OPERATOR(sys.=)
TEST_F(PSQL_DataTypes_DateTimeOffset, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "1900-01-01 00:00:00 +01:00",
    "1900-01-01 00:00:00 +00:01",
    "1900-01-01 00:00:00",
    "2000-01-01 00:00:05",
    "2000-01-01 00:00:00.54321",
    "2000-01-01 00:00:00.123456",
    "2000-01-01 00:00:00.123456 +10:00"
  };

  const vector<string> INSERTED_DATA = {
    "1900-01-01 00:00:00 -01:00",
    "1900-01-01 00:00:00 +00:02",
    "1900-12-31 23:59:00",
    "2000-01-01 00:00:10",
    "2000-01-01 00:00:00.123456",
    "2000-01-01 00:00:00.123456 +10:00"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    COL1_NAME + " OPERATOR(sys.=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>=) " + COL2_NAME
  };

  // initialization of expected_results
  vector<vector<char>> expected_results = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    string date_1 = dateComparisonHelper(generateExpected(INSERTED_PK[i]));
    string date_2 = dateComparisonHelper(generateExpected(INSERTED_DATA[i]));
    const char* comp_1 = date_1.data();
    const char* comp_2 = date_2.data();
    
    expected_results[i].push_back(strcmp(comp_1, comp_2) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) >= 0 ? '1' : '0');
  }

  string insertString{};
  string comma{};
  // insertString initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, 
    OPERATIONS_QUERY, expected_results, true, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// Explicit casting is used, ie sys.MAX()
TEST_F(PSQL_DataTypes_DateTimeOffset, Comparison_Functions) {
  const vector<string> INSERTED_DATA = {
    "1900-01-01 00:00:00 -10:00",
    "1900-01-01 00:00:00 +00:01",
    "1950-01-01 00:00:00",
    "2000-01-01 00:00:00"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    "sys.MIN(" + COL2_NAME + ")",
    "sys.MAX(" + COL2_NAME + ")"
  };

  // initialization of expected_results
  vector<string> expected_results = {};
  int min_expected = 0, max_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    string curr_min = dateComparisonHelper(generateExpected(INSERTED_DATA[min_expected]));
    string curr_max = dateComparisonHelper(generateExpected(INSERTED_DATA[max_expected]));
    string curr = dateComparisonHelper(generateExpected(INSERTED_DATA[i]));
    const char* comp_min = curr_min.data();
    const char* comp_max = curr_max.data();
    const char* comp_curr = curr.data();

    min_expected = strcmp(comp_curr, comp_min) < 0 ? i : min_expected;
    max_expected = strcmp(comp_curr, comp_max) > 0 ? i : max_expected;
  }
  expected_results.push_back(generateExpected(INSERTED_DATA[min_expected]));
  expected_results.push_back(generateExpected(INSERTED_DATA[max_expected]));

  string insertString{};
  string comma{};
  // insertString initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + std::to_string(i) + ",\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, expected_results);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  // NOTE: Inserted Values depend on server's timezone if not specified in insert
  //       Expected Values generated based on localtime's timezone
  //       Make sure server & client are in the same timezone
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "",                                  // Default Value
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",               // Min
    "9999-06-06 23:59:29.999999",        // Max
    "1900-01-01 23:59:59 +14:00",
    "1900-01-01 00:00:00 +12:00",
    "1900-01-01 00:00:00.999999 +12:00",
    "1900-01-01 00:00:00.123456 +12:00",
  };

  // NOTE: Expected Values depend on computer/server's timezone
  vector<string> expected_values = {};
  const int NUM_OF_INSERTS = INSERTED_VALUES.size();

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    expected_values.push_back(generateExpected(INSERTED_VALUES[i]));
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, expected_values);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, expected_values);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "1900-01-01 00:00:00 +00:00",
    "2000-12-31 00:00:00 +00:00"
  };
  
  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Table_Single_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "1900-01-01 00:00:00 +00:00",
    "2000-05-20 23:59:00 +00:00"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_DateTimeOffset, Table_Composite_Primary_Keys) {
  vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME,
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "1900-01-01 00:00:00 +00:00",
    "2000-05-20 23:59:00 +00:00"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
