#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.smalldatetime_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.smalldatetime";
const string VIEW_NAME = "master_dbo.smalldatetime_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

class PSQL_DataTypes_SmallDateTime : public testing::Test {
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

TEST_F(PSQL_DataTypes_SmallDateTime, Table_Creation) {
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

TEST_F(PSQL_DataTypes_SmallDateTime, Insertion_Success) {
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "",                           // Default Value
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:29",        // Max
    "2079-06-05 23:59:29",        // Round Down
    "1900-01-01 23:59:59",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  const vector<string> EXPECTED_VALUES = {
    "NULL",
    "1900-01-01 00:00:00",        // Default Value
    "1900-01-01 00:00:00",
    "2079-06-06 00:00:00",        
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:00",        // Max
    "2079-06-05 23:59:00",        // Round Down
    "1900-01-02 00:00:00",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Insertion_Fail) {

  const vector<string> INVALID_INSERTED_VALUES = {
    // "01-01-2000",             // Format (Valid insert on Ubuntu 20. Invalid insert on Ubuntu 22)
    "December 31, 1900 CE",
    "2080-01-01 00:00:00",        // Year
    "1899-12-31 00:00:00",
    "0000-01-01 00:00:00",
    "1900-32-01 00:00:00",        // Month
    "1900-00-01 00:00:00",
    "1900-01-32 00:00:00",        // Day
    "1900-01-00 00:00:00",
    "1900-02-31 00:00:00",        // Feb 31st
    "0001-01-01 24:00:00", 	      // Hour
    "0001-01-01 00:60:00",        // Minutes
    "0001-01-01 00:00:60", 	      // Seconds
    "0001-01-01 00:00:60000", 	  // Milliseconds
    "2079-06-06 23:59:39"         // Rounding up over range
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Update_Success) {
  const vector<string> DATA_INSERTED = {
    "1900-01-01 00:00:00"
  };

  const vector<string> DATA_UPDATED_VALUES = {
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:29",        // Max
    "2079-06-05 23:59:29",        // Round Down
    "1900-01-01 23:59:59",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  const vector<string> EXPECTED_VALUES = {
    "1900-01-01 00:00:00",
    "2079-06-06 00:00:00",        
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:00",        // Max
    "2079-06-05 23:59:00",        // Round Down
    "1900-01-02 00:00:00",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, DATA_INSERTED, DATA_INSERTED);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES, EXPECTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Update_Fail) {
  const vector<string> DATA_INSERTED = {
    "1900-01-01 00:00:00"
  };

  const vector<string> DATA_UPDATED_VALUE = {
    "1900-02-31 00:00:00" // Feb 31st
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, DATA_INSERTED, DATA_INSERTED);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_INSERTED, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "1900-01-01 00:00:00",
    "2000-01-01 00:00:00"
  };

  const vector<string> INSERTED_DATA = {
    "1900-12-31 23:59:00",
    "2000-01-01 00:00:00"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  string insertString{};
  string comma{};
  // insert_string initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    COL1_NAME + "=" + COL2_NAME,
    COL1_NAME + "<>" + COL2_NAME,
    COL1_NAME + "<" + COL2_NAME,
    COL1_NAME + "<=" + COL2_NAME,
    COL1_NAME + ">" + COL2_NAME,
    COL1_NAME + ">=" + COL2_NAME
  };

  // initialization of expected_results
  vector<vector<char>> expected_results = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    const char *date_1 = INSERTED_PK[i].data();
    const char *date_2 = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(date_1, date_2) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) >= 0 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, 
    OPERATIONS_QUERY, expected_results, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Comparison_Functions) {
  const vector<string> INSERTED_DATA = {
    "1900-01-01 00:00:00",
    "1950-12-31 00:00:00",
    "2000-01-19 00:00:00",
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL2_NAME + ")",
    "MAX(" + COL2_NAME + ")"
  };

  // initialization of expected_results
  vector<string> expected_results = {};
  int min_expected = 0, max_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    const char *currMin = INSERTED_DATA[min_expected].data();
    const char *currMax = INSERTED_DATA[max_expected].data();
    const char *curr = INSERTED_DATA[i].data();

    min_expected = strcmp(curr, currMin) < 0 ? i : min_expected;
    max_expected = strcmp(curr, currMax) > 0 ? i : max_expected;
  }
  expected_results.push_back(INSERTED_DATA[min_expected]);
  expected_results.push_back(INSERTED_DATA[max_expected]);

  string insertString{};
  string comma{};
  // insert_string initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + std::to_string(i) + ",\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, expected_results);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  const vector<string> INSERTED_VALUES = {
    "NULL",
    "",                           // Default Value
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:29",        // Max
    "2079-06-05 23:59:29",        // Round Down
    "1900-01-01 23:59:59",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  const vector<string> EXPECTED_VALUES = {
    "NULL",
    "1900-01-01 00:00:00",        // Default Value
    "1900-01-01 00:00:00",
    "2079-06-06 00:00:00",        
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:00",        // Max
    "2079-06-05 23:59:00",        // Round Down
    "1900-01-02 00:00:00",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };
  
  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "1900-01-01 00:00:00",
    "2000-12-31 00:00:00"
  };

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Table_Single_Primary_Keys) {
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
    "1900-01-01 00:00:00",
    "2000-05-20 23:59:00"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallDateTime, Table_Composite_Primary_Keys) {
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
    "1900-01-01 00:00:00",
    "2000-05-20 23:59:00"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
