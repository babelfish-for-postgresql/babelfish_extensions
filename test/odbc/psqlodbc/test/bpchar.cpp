#include "../psqlodbc_tests_common.h"
#include "../string_constants.h"

const string TABLE_NAME = "master_dbo.bpchar_table_odbc_test";
const string VIEW_NAME = "master_dbo.bpchar_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";

const string DATATYPE = "sys.bpchar";

const vector<pair<string, string>> TABLE_COLUMNS_1 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE + "(1)"}
};

const vector<pair<string, string>> TABLE_COLUMNS_4000 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE + "(4000)"}
};

const vector<pair<string, string>> TABLE_COLUMNS_20 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE + "(20)"}
};

class PSQL_DataTypes_Bpchar : public testing::Test{

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

TEST_F(PSQL_DataTypes_Bpchar, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 1};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};
  const vector<string> PREFIX_EXPECTED = {"int4", "'"};
  const vector<string> SUFFIX_EXPECTED = {"int4", "'"};
  const vector<int> IS_CASE_SENSITIVE = {0, 0};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testCommonCharColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED, IS_CASE_SENSITIVE, PREFIX_EXPECTED, SUFFIX_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<int> LENGTH_EXPECTED_4000 = {4, 4000};
  const vector<int> PRECISION_EXPECTED_4000 = {0, 0};
  const vector<int> SCALE_EXPECTED_4000 = {0, 0};
  const vector<string> NAME_EXPECTED_4000 = {"int4", "unknown"};
  

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testCommonCharColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000.size(), COL1_NAME, LENGTH_EXPECTED_4000, 
    PRECISION_EXPECTED_4000, SCALE_EXPECTED_4000, NAME_EXPECTED_4000, IS_CASE_SENSITIVE, PREFIX_EXPECTED, SUFFIX_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<int> LENGTH_EXPECTED_20 = {4, 20};
  const vector<int> PRECISION_EXPECTED_20 = {0, 0};
  const vector<int> SCALE_EXPECTED_20 = {0, 0};
  const vector<string> NAME_EXPECTED_20 = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testCommonCharColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20.size(), COL1_NAME, LENGTH_EXPECTED_20, 
    PRECISION_EXPECTED_20, SCALE_EXPECTED_20, NAME_EXPECTED_20, IS_CASE_SENSITIVE, PREFIX_EXPECTED, SUFFIX_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bpchar, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> INVALID_COLUMNS {
    {{"invalid1", DATATYPE + "(-1)"}},
    {{"invalid1", DATATYPE + "(0)"}},
    {{"invalid1", DATATYPE + "(NULL)"}}
  };
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, INVALID_COLUMNS);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bpchar, Insertion_Success) {
  const vector<string> INSERTED_VALUES_1 = {
    "NULL", 
    STRING_1,
    "" 
  };

  const vector<string> EXPECTED_VALUES_1 = {
    "NULL", 
    STRING_1,
    " " 
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "NULL", // NULL values
    "",
    STRING_1,
    STRING_4000,
    STRING_20
  };

  const vector<string> EXPECTED_VALUES_4000 = {
    "NULL", // NULL values
    "" + std::string(4000, ' '),
    STRING_1 + std::string(3999, ' '),
    STRING_4000,
    STRING_20 + std::string(3980, ' ')
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, EXPECTED_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "NULL", // NULL values
    "",
    STRING_1,
    STRING_20
  };
  
  const vector<string> EXPECTED_VALUES_20 = {
    "NULL", // NULL values
    "" + std::string(20, ' '),
    STRING_1 + std::string(19, ' '),
    STRING_20
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME); 
}

TEST_F(PSQL_DataTypes_Bpchar, Insertion_Failure) {
  const vector<string> INSERTED_VALUES_1 = {
    STRING_1 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    STRING_4000 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    STRING_20 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
  
}

TEST_F(PSQL_DataTypes_Bpchar, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "1"
  };

  const vector<string> UPDATED_VALUES = {
    "a",
    "",
    STRING_1
  };

  const vector<string> EXPECTED_VALUES = {
    "a",
    " ",
    STRING_1
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, UPDATED_VALUES, EXPECTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    STRING_1
  };

  const vector<string> EXPECTED_INSERTED_VALUES_4000 = {
    STRING_1 + std::string(3999, ' ')
  };

  const vector<string> UPDATED_VALUES_4000 = {
    STRING_20,
    " ",
    STRING_4000
  };

  const vector<string> EXPECTED_UPDATED_VALUES_4000 = {
    STRING_20 + std::string(3980, ' '),
    " " + std::string(3999, ' '),
    STRING_4000
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, EXPECTED_INSERTED_VALUES_4000);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, UPDATED_VALUES_4000, EXPECTED_UPDATED_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "1"
  };

  const vector<string> EXPECTED_INSERTED_VALUES_20 = {
    "1" +  std::string(19, ' ')
  };

  const vector<string> UPDATED_VALUES_20 = {
    STRING_20,
    " "
  };

  const vector<string> EXPECTED_UPDATED_VALUES_20 = {
    STRING_20,
    " " + std::string(19, ' ')
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_INSERTED_VALUES_20);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, UPDATED_VALUES_20, EXPECTED_UPDATED_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}


TEST_F(PSQL_DataTypes_Bpchar, Update_Fail) {
  const vector<string> INSERTED_VALUES = {
    STRING_1
  };

  const vector<string> UPDATED_VALUES = {
    STRING_1 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES, UPDATED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    STRING_4000
  };

  const vector<string> UPDATED_VALUES_4000 = {
    STRING_4000 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_4000, UPDATED_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    STRING_20
  };

  const vector<string> UPDATED_VALUES_20 = {
    STRING_20 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_20, UPDATED_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bpchar, View_creation) {
  const vector<string> INSERTED_VALUES = {
    "NULL", // NULL values
    STRING_1,
    "" // blank value
  };

  const vector<string> EXPECTED_VALUES = {
    "NULL", // NULL values
    STRING_1,
    " " // blank value
  };

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "NULL", // NULL values
    STRING_4000,
    "" // blank value
  };

  const vector<string> EXPECTED_VALUES_4000 = {
    "NULL", // NULL values
    STRING_4000,
    "" + std::string(4000, ' ')// blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, EXPECTED_VALUES_4000);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_4000, EXPECTED_VALUES_4000);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "NULL", // NULL values
    STRING_20,
    "" // blank value
  };

  const vector<string> EXPECTED_VALUES_20 = {
    "NULL", // NULL values
    STRING_20,
    "" + std::string(20, ' ')// blank value
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bpchar, Table_Single_Primary_Keys) {

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(1)"}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    STRING_1
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<pair<string, string>> TABLE_COLUMNS_4000 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(4000)"}
  };

  const vector<string> PK_COLUMNS_4000 = {
    COL2_NAME
  };

  tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS_4000);

  const vector<string> INSERTED_VALUES_4000 = {
    STRING_2704
  }; // Maximum byte passed by PG endpoint is limited by 2704 byte, for SQL it's 900, 
     //so 2704 should perfectly handle this case
  const vector<string> EXPECTED_VALUES_4000 = {
    STRING_2704 + std::string(4000 - STRING_2704.size(), ' ')
  }; 

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, EXPECTED_VALUES_4000);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(20)"}
  };

  const vector<string> PK_COLUMNS_20 = {
    COL2_NAME
  };

  tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS_20);

  const vector<string> INSERTED_VALUES_20 = {
    STRING_20
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bpchar, Table_Composite_Primary_Keys){

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(1)"}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME, 
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    STRING_1
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<pair<string, string>> TABLE_COLUMNS_4000 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(4000)"}
  };

  const vector<string> PK_COLUMNS_4000 = {
    COL1_NAME, 
    COL2_NAME
  };

  tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS_4000);

  const vector<string> INSERTED_VALUES_4000 = {
    STRING_2704
  };// Maximum byte passed by PG endpoint is limited by 2704 byte, for SQL it's 900, 
     //so 2704 should perfectly handle this case
  const vector<string> EXPECTED_VALUES_4000 = {
    STRING_2704 + std::string(4000 - STRING_2704.size(), ' ')
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, EXPECTED_VALUES_4000);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(20)"}
  };

  const vector<string> PK_COLUMNS_20 = {
    COL1_NAME, 
    COL2_NAME
  };

  tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS_20);

  const vector<string> INSERTED_VALUES_20 = {
    STRING_20
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bpchar, Table_Unique_Constraint) {

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  // Insert valid values into the table and assert affected rows
  const vector<string> INSERTED_VALUES = {
    STRING_1,
    "" // blank value
  };

  const vector<string> EXPECTED_VALUES = {
    STRING_1,
    " "
  };

  // table name without the schema
  const string tableName = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> UNIQUE_COLUMNS_20 = {
    COL2_NAME
  };

  tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS_20);

  // Insert valid values into the table and assert affected rows
  const vector<string> INSERTED_VALUES_20 = {
    STRING_20,
    ""
  };

  const vector<string> EXPECTED_VALUES_20 = {
    STRING_20,
    "" + std::string(20, ' ')
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> UNIQUE_COLUMNS_4000 = {
    COL2_NAME
  };

  tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS_20);

  // Insert valid values into the table and assert affected rows
  const vector<string> INSERTED_VALUES_4000 = {
    STRING_2704,
    ""
  }; // Maximum byte passed by PG endpoint is limited by 2704 byte, for SQL it's 900, 
     //so 2704 should perfectly handle this case
  
  const vector<string> EXPECTED_VALUES_4000 = {
    STRING_2704 + std::string(4000 - STRING_2704.size(), ' '),
    "" + std::string(4000, ' ')
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, EXPECTED_VALUES_4000);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, false, INSERTED_VALUES_4000.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
  
}

TEST_F(PSQL_DataTypes_Bpchar, Comparison_Operators) {

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE + "(4000)" + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE + "(4000)"}
  };

  const vector<string> INSERTED_PK = {
    "One",
    "BBBB",
    "EEEE"
  };

  const vector<string> INSERTED_DATA = {
    "One",
    "AAAA",
    "FFFF"
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
  vector<vector<char>> expectedResults = {};

  for (int i = 0; i < NUM_OF_DATA; i++) {
    expectedResults.push_back({});
    const char *date_1 = INSERTED_PK[i].data();
    const char *date_2 = INSERTED_DATA[i].data();
    expectedResults[i].push_back(strcmp(date_1, date_2) == 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(date_1, date_2) != 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(date_1, date_2) < 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(date_1, date_2) <= 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(date_1, date_2) > 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(date_1, date_2) >= 0 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, 
    OPERATIONS_QUERY, expectedResults, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bpchar, String_Operators) {

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
  vector<vector<string>> EXPECTED_RESULTS = {{}};
  
  for(int i = 0; i < NUM_OF_OPERATIONS; i++)
  {
    EXPECTED_RESULTS.push_back({});
  }
  
  string current =  INSERTED_DATA[0];
  transform(current.begin(), current.end(), current.begin(), ::tolower);
  EXPECTED_RESULTS[0].push_back(current + std::string(4000 - current.size(), ' '));
  EXPECTED_RESULTS[1].push_back("  ONE TWO!" + std::string(3990, ' '));
  EXPECTED_RESULTS[2].push_back(INSERTED_PK[0] + INSERTED_DATA[0] + std::string(3990, ' '));
  EXPECTED_RESULTS[3].push_back("One Two!");
  EXPECTED_RESULTS[4].push_back("  One Two!" + std::string(3990, ' ')); // TRIM (trailing !) did not remove '!' on PG
  EXPECTED_RESULTS[5].push_back("  One Two!");
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testStringFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, EXPECTED_RESULTS, NUM_OF_DATA, COL1_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
