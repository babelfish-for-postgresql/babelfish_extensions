#include "../psqlodbc_tests_common.h"
#include "../string_constants.h"

const string BBF_TABLE_NAME = "master.dbo.text_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.text_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.text_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.text_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";

const string DATATYPE = "text";

const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE}
};

class PSQL_DataTypes_Text : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));

    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", BBF_VIEW_NAME));
    bbf_test_setup.CloseStmt();
    bbf_test_setup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
    
    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", PG_VIEW_NAME));
    pg_test_setup.CloseStmt();
    pg_test_setup.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_Text, Table_Creation) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  const vector<int> BBF_LENGTH_EXPECTED = {10, 2147483647};
  const vector<int> BBF_PRECISION_EXPECTED = {10, 2147483647};
  const vector<int> BBF_SCALE_EXPECTED = {0, 0};
  const vector<string> BBF_NAME_EXPECTED = {"int", "text"};
  const vector<int> BBF_CASE_EXPECTED = {SQL_FALSE, SQL_FALSE};
  const vector<string> BBF_PREFIX_EXPECTED = {"", "\'"};
  const vector<string> BBF_SUFFIX_EXPECTED = {"", "\'"};
  testCommonCharColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
                                TABLE_COLUMNS.size(), COL1_NAME, 
                                BBF_LENGTH_EXPECTED, BBF_PRECISION_EXPECTED,
                                BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED,
                                BBF_CASE_EXPECTED, BBF_PREFIX_EXPECTED, BBF_SUFFIX_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED = {4, 8190};
  const vector<int> PG_PRECISION_EXPECTED = {0, 0};
  const vector<int> PG_SCALE_EXPECTED = {0, 0};
  const vector<string> PG_NAME_EXPECTED = {"int4", "text"};
  const vector<int> PG_CASE_EXPECTED = {SQL_FALSE, SQL_TRUE};
  const vector<string> PG_PREFIX_EXPECTED = {"int4", "\'"};
  const vector<string> PG_SUFFIX_EXPECTED = {"int4", "\'"};

  testCommonCharColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
                                TABLE_COLUMNS.size(), COL1_NAME, 
                                PG_LENGTH_EXPECTED, PG_PRECISION_EXPECTED,
                                PG_SCALE_EXPECTED, PG_NAME_EXPECTED,
                                PG_CASE_EXPECTED, PG_PREFIX_EXPECTED, PG_SUFFIX_EXPECTED);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> INVALID_COLUMNS {    
    {{"invalid1", DATATYPE + "(-1)"}},
    {{"invalid2", DATATYPE + "(0)"}},
    {{"invalid3", DATATYPE + "(8001)"}},
    {{"invalid4", DATATYPE + "(NULL)"}}
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(ServerType::MSSQL, BBF_TABLE_NAME, INVALID_COLUMNS);
  testTableCreationFailure(ServerType::PSQL, PG_TABLE_NAME, INVALID_COLUMNS);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, Insertion_Success) {
  vector<string> inserted_values = {
    "NULL",           // Null
    "",               // Empty
    "A",              // Rand
    STRING_1,
    STRING_20,
    STRING_8000
  };
  
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values, false, inserted_values.size());
  
  inserted_values = duplicateElements(inserted_values);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    STRING_1
  };

  const vector <string> DATA_UPDATED_VALUES = {
    "NULL",           // Null
    "",               // Empty
    "A",              // Rand
    STRING_8000,
    STRING_20,
    STRING_1
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES, DATA_UPDATED_VALUES);
  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES, DATA_UPDATED_VALUES);

  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, View_Creation) {
  const string BBF_VIEW_QUERY = "SELECT * FROM " + BBF_TABLE_NAME;
  const string PG_VIEW_QUERY = "SELECT * FROM " + PG_TABLE_NAME;

  const vector<string> INSERTED_VALUES = {
    "NULL",           // Null
    "",               // Empty
    "A",              // Rand
    STRING_1,
    STRING_20,
    STRING_8000
  };
  
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

  verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
  dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, Table_Single_Primary_Keys) {
  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> INSERTED_VALUES = {
    STRING_1,
    STRING_20,
    STRING_2704
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, Table_Composite_Primary_Keys) {
  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> PK_COLUMNS = {
    COL1_NAME, 
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> INSERTED_VALUES = {
    STRING_1,
    STRING_20,
    STRING_2704
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, Table_Unique_Constraint) {
  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    STRING_1,
    STRING_20,
    STRING_2704
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> INSERTED_PK = {
    "ZZZZZ",      // A > B
    "9999",       // A < B
    "asdf1234"    // A = B
  };

  const vector<string> INSERTED_DATA = {
    "AAAAA",      // A > B
    "0000",       // A < B
    "asdf1234"    // A = B
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();
  
  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  const vector<string> BBF_OPERATIONS_QUERY = {
    "IIF(" + COL1_NAME + " = " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " <> " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " < " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " <= " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " > " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " >= " + COL2_NAME + ", '1', '0')"
  };

  const vector<string> PG_OPERATIONS_QUERY = {
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
    const char *data_A = INSERTED_PK[i].data();
    const char *data_B = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(data_A, data_B) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) >= 0 ? '1' : '0');
  }

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insertString, NUM_OF_DATA);

  testComparisonOperators(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, BBF_OPERATIONS_QUERY, expected_results,
                          false, true);

  testComparisonOperators(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, PG_OPERATIONS_QUERY, expected_results,
                          false, true);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Text, String_Functions) {
  const vector<string> INSERTED_DATA = {
    "aBcDeFg",
    "   test",
    STRING_20
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();
  
  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + std::to_string(i) + ",\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    "LOWER(" + COL2_NAME + ")",
    "UPPER(" + COL2_NAME + ")",
    "TRIM(" + COL2_NAME + ")",
    "CONCAT(" + COL2_NAME + ",\'xyz\')",
  };

  // initialization of EXPECTED_RESULTS
  vector<vector<string>> EXPECTED_RESULTS = {
    {"abcdefg", "   test", "0123456789abcdefghij"},
    {"ABCDEFG", "   TEST", "0123456789ABCDEFGHIJ"},
    {"aBcDeFg", "test", "0123456789abcdefghij"},
    {"aBcDeFgxyz", "   testxyz", "0123456789abcdefghijxyz"}
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insertString, NUM_OF_DATA);

  testStringFunctions(ServerType::MSSQL, BBF_TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, INSERTED_DATA.size(), COL1_NAME);
  testStringFunctions(ServerType::PSQL, PG_TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, INSERTED_DATA.size(), COL1_NAME);
  
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}
