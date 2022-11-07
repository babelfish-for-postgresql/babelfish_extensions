#include "../psqlodbc_tests_common.h"
#include "../string_constants.h"

const string TABLE_NAME = "master_dbo.nvarchar_table_odbc_test";
const string VIEW_NAME = "master_dbo.nvarchar_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";

const string DATATYPE = "sys.nvarchar";
const string DATATYPE_1 = DATATYPE + "(1)";
const string DATATYPE_20 = DATATYPE + "(20)";
const string DATATYPE_4000 = DATATYPE + "(4000)";

vector<pair<string, string>> TABLE_COLUMNS_1 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_1}
};

vector<pair<string, string>> TABLE_COLUMNS_20 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_20}
};

vector<pair<string, string>> TABLE_COLUMNS_4000 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_4000}
};

class PSQL_DataTypes_nvarChar : public testing::Test {
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

TEST_F(PSQL_DataTypes_nvarChar, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 1};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<int> LENGTH_EXPECTED_20 = {4, 20};
  const vector<int> PRECISION_EXPECTED_20 = {0, 0};
  const vector<int> SCALE_EXPECTED_20 = {0, 0};
  const vector<string> NAME_EXPECTED_20 = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20.size(), COL1_NAME, LENGTH_EXPECTED_20, 
    PRECISION_EXPECTED_20, SCALE_EXPECTED_20, NAME_EXPECTED_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<int> LENGTH_EXPECTED_4000 = {4, 4000};
  const vector<int> PRECISION_EXPECTED_4000 = {0, 0};
  const vector<int> SCALE_EXPECTED_4000 = {0, 0};
  const vector<string> NAME_EXPECTED_4000 = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000.size(), COL1_NAME, LENGTH_EXPECTED_4000, 
    PRECISION_EXPECTED_4000, SCALE_EXPECTED_4000, NAME_EXPECTED_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> INVALID_COLUMNS {
    {{"invalid1", DATATYPE + "(-1)"}},
    {{"invalid1", DATATYPE + "(0)"}},
    {{"invalid1", DATATYPE + "(NULL)"}}
  };
  
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, INVALID_COLUMNS);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Insertion_Success) {
  const vector<string> INSERTERD_VALUES_1 = {
    "NULL", 
    "",
    STRING_1
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTERD_VALUES_1, INSERTERD_VALUES_1);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTERD_VALUES_20 = {
    "NULL", 
    "",
    STRING_20
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTERD_VALUES_20, INSERTERD_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTERD_VALUES_4000 = {
    "NULL", 
    "",
    STRING_4000
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTERD_VALUES_4000, INSERTERD_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Insertion_Failure) {
  const vector<string> INSERTED_VALUE_1 = {
    STRING_1 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUE_1, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUE_20 = {
    STRING_20 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUE_20, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUE_4000 = {
    STRING_4000 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUE_4000, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Update_Success) {
  const vector<string> INSERTED_VALUES_1 = {
    "A"
  };

  const vector <string> DATA_UPDATED_VALUES_1 = {
    "NULL",
    STRING_1,
    "A"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_1, DATA_UPDATED_VALUES_1);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "A"
  };

  const vector <string> DATA_UPDATED_VALUES_20 = {
    "NULL",
    STRING_20,
    "A"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_20, DATA_UPDATED_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "A"
  };

  const vector <string> DATA_UPDATED_VALUES_4000 = {
    "NULL",
    STRING_4000,
    "A"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_4000, DATA_UPDATED_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Update_Fail) {
  const vector<string> INSERTED_VALUES_1 = {
    "A"
  };

  const vector<string> UPDATED_VALUES_1 = {
    STRING_1 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_1, UPDATED_VALUES_1);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "A"
  };

  const vector<string> UPDATED_VALUES_20 = {
    STRING_20 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_20, UPDATED_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "A"
  };

  const vector<string> UPDATED_VALUES_4000 = {
    STRING_4000 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_4000, UPDATED_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, View_creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  const vector<string> INSERTED_VALUES_1 = {
    "NULL", 
    "",
    STRING_1
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "NULL", 
    "",
    STRING_20
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "NULL", 
    "",
    STRING_4000
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Single_Primary_Keys) {
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_1}
  };

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_20}
  };

  // Maximum allowed for PG connection is 2704
  const vector<pair<string, string>> TABLE_COLUMNS_2704 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(2704)"}
  };

  const vector<string> INSERTED_VALUES_1 = {
    "",         // Empty
    STRING_1    // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",         // Empty
    STRING_20   // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_2704 = {
    "",         // Empty
    STRING_2704 // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, INSERTED_VALUES_2704);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Composite_Primary_Keys){
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME,
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_1}
  };

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_20}
  };

  // Maximum allowed for PG connection is 2704
  const vector<pair<string, string>> TABLE_COLUMNS_2704 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(2704)"}
  };

  const vector<string> INSERTED_VALUES_1 = {
    "",         // Empty
    STRING_1    // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",         // Empty
    STRING_20   // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_2704 = {
    "",         // Empty
    STRING_2704 // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, INSERTED_VALUES_2704);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Unique_Constraint) {
  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};
  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);
  const string tableName = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_1}
  };

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_20}
  };

  // Maximum allowed for PG connection is 2704
  const vector<pair<string, string>> TABLE_COLUMNS_2704 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(2704)"}
  };

  const vector<string> INSERTED_VALUES_1 = {
    "",         // Empty
    STRING_1    // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",         // Empty
    STRING_20    // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_2704 = {
    "",         // Empty
    STRING_2704 // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, INSERTED_VALUES_2704);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_20 + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_20}
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
    const char *data_A = INSERTED_PK[i].data();
    const char *data_B = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(data_A, data_B) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) >= 0 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);

  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results,
                          false, true);

  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, String_Functions) {
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

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);

  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);

  testStringFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, INSERTED_DATA.size(), COL1_NAME);

  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
