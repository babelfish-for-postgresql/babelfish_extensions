#include "../psqlodbc_tests_common.h"
#include "../string_constants.h"

const string TABLE_NAME = "master_dbo.sysname_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE = "sys.sysname";
const string VIEW_NAME = "master_dbo.sysname_view_odbc_test";

const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, " int PRIMARY KEY"},
    {COL2_NAME, DATATYPE}
};

class PSQL_Datatypes_Sysname: public testing::Test {
   void SetUp() override {
    if(!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
   }

   void TearDown() override {
    if(!Drivers::DriverExists(ServerType::PSQL)) {
        GTEST_SKIP() << "PSQL Driver not present: skipping tear down.";
    }
    OdbcHandler test_cleanup(Drivers::GetDriver(ServerType::PSQL));
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_cleanup.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
   }

};

TEST_F(PSQL_Datatypes_Sysname, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 128};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};
  const vector<string> PREFIX_EXPECTED = {"int4", "'"};
  const vector<string> SUFFIX_EXPECTED = {"int4", "'"};
  const vector<int> IS_CASE_SENSITIVE = {0, 0};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonCharColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED, IS_CASE_SENSITIVE, PREFIX_EXPECTED, SUFFIX_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE + "(4)"}} // Cannot specify a column width on data type datatime.
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, invalid_columns);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// inserted values differ that of expected?
TEST_F(PSQL_Datatypes_Sysname, Insertion_Success) {
  const vector<string> INSERTED_VALUES = {
    "NULL", // NULL value
    STRING_1,
    STRING_128,
    STRING_20,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Insertion_Failure) {
  const vector<string> INSERTED_VALUES = {
    STRING_128 + "t"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "a"
  };

  const vector<string> UPDATED_VALUES = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, UPDATED_VALUES, UPDATED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Update_Fail) {
  const vector<string> INSERTED_VALUES = {
    STRING_1
  };

  const vector<string> UPDATED_VALUES = {
    STRING_128 + "t"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES, UPDATED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, View_Creation) {
  const vector<string> INSERTED_VALUES = {
    "NULL", // NULL values
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Single_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Composite_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME, 
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Table_Unique_Constraint) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  // Insert valid values into the table and assert affected rows
  const vector<string> INSERTED_VALUES = {
    STRING_1,
    STRING_20,
    STRING_128,
    "" // blank value
  };

  // table name without the schema
  const string tableName = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_Datatypes_Sysname, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE}
  };

  const vector<string> INSERTED_PK = {
    "Name One",
    "NNN",
    "BBB"
  };

  const vector<string> INSERTED_DATA = {
    "Name One",
    "MMM",
    "AAA"
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

TEST_F(PSQL_Datatypes_Sysname, String_Operators) {

  const vector<string> INSERTED_DATA = {
    "  One Two!"
  };

  const vector<string> INSERTED_PK = {
    "1"
  };

  const int NUM_OF_DATA = INSERTED_DATA.size();
  
  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + INSERTED_PK[i] + ",\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    "lower(" + COL2_NAME + ")",
    "upper(" + COL2_NAME + ")",
    COL1_NAME +"||" + COL2_NAME,
    "Trim(" + COL2_NAME + ")",
    "Trim(TRAILING '!' from " + COL2_NAME + ")",
    "Trim(TRAILING ' ' from " + COL2_NAME + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of EXPECTED_RESULTS
  vector<vector<string>> EXPECTED_RESULTS = {};
  for(int i = 0; i < NUM_OF_OPERATIONS; i++){
    EXPECTED_RESULTS.push_back({});
  }

  string current = INSERTED_DATA[0];
  transform(current.begin(), current.end(), current.begin(), ::tolower);
  EXPECTED_RESULTS[0].push_back(current);
  EXPECTED_RESULTS[1].push_back("  ONE TWO!");
  EXPECTED_RESULTS[2].push_back(INSERTED_PK[0] + INSERTED_DATA[0]);
  EXPECTED_RESULTS[3].push_back("One Two!");
  EXPECTED_RESULTS[4].push_back("  One Two");
  EXPECTED_RESULTS[5].push_back("  One Two!");
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testStringFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, EXPECTED_RESULTS, NUM_OF_DATA, COL1_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
