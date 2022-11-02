#include "../psqlodbc_tests_common.h"
#include <regex>

const string TABLE_NAME = "master_dbo.unique_identifier_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.uniqueidentifier";
const string VIEW_NAME = "master_dbo.unique_identifier_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int GUID_BYTES_EXPECTED = 36;
// Format for GUID: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
//                  Where X is a hexadecimal value (0-F)
const std::regex GUID_REGEX("[\\da-fA-F]{8}[-]([\\da-fA-F]{4}-){3}[\\da-fA-F]{12}");

class PSQL_DataTypes_UniqueIdentifier : public testing::Test {
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

TEST_F(PSQL_DataTypes_UniqueIdentifier, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Insertion_Success) {
  const vector<string> INSERTED_DATA = {
    "NULL",
    "00000000-0000-0000-0000-000000000000", // Min
    "0E984725-C51C-4BF4-9960-E1C80E27ABA0", // Rand
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"  // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, INSERTED_DATA);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",   // Not Hex values
    "00000000-0000-0000-0000-00000000000",    // Too short
    "00000000-0000-0000-0000-0000000000000",  // Too long
    "00000000:0000:0000:0000:000000000000",   // Wrong format
    "00000000-0000-0000-0000-00000000000X",   // Invalid Character
    "123456789"                               // Wrong format, No casting
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Insertion_With_Function_Success) {
  const vector<string> INSERTED_VALUES = {
    "sys.NEWSEQUENTIALID()",
    "sys.newid()"
  };
  const int NUM_OF_INSERTS = INSERTED_VALUES.size();

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::PSQL, TABLE_NAME, INSERTED_VALUES, true);

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;
  RETCODE rcode;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  // Select all from the tables and assert that the following attributes of the type is correct:
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));  
  odbcHandler.Connect(true);
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    ASSERT_EQ(data_len, GUID_BYTES_EXPECTED);
    ASSERT_TRUE(std::regex_match(data, GUID_REGEX));
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "01234567-1234-1234-1234-0123456789AB"
  };

  const vector <string> DATA_UPDATED_VALUES = {
    "NULL",
    "00000000-0000-0000-0000-000000000000", // Min
    "0E984725-C51C-4BF4-9960-E1C80E27ABA0", // Rand
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"  // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES, DATA_UPDATED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Update_Fail) {
  const vector<string> INSERTED_VALUES = {
    "01234567-1234-1234-1234-0123456789AB"
  };

  const vector<string> UPDATED_VALUE = {
    "01234567-1234-1234-1234-0123456wrong"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES, UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  const vector<string> INSERTED_VALUES = {
    "NULL",
    "00000000-0000-0000-0000-000000000000", // Min
    "0E984725-C51C-4BF4-9960-E1C80E27ABA0", // Rand
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"  // Max
  };
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };
  
  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);
  
  const vector<string> INSERTED_VALUES = {
    "00000000-0000-0000-0000-000000000000", // Min
    "0E984725-C51C-4BF4-9960-E1C80E27ABA0", // Rand
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"  // Max
  };

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Table_Single_Primary_Keys) {
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
    "00000000-0000-0000-0000-000000000000", // Min
    "0E984725-C51C-4BF4-9960-E1C80E27ABA0", // Rand
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"  // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_UniqueIdentifier, Table_Composite_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
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
    "00000000-0000-0000-0000-000000000000", // Min
    "0E984725-C51C-4BF4-9960-E1C80E27ABA0", // Rand
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"  // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// Explicit casting is used, ie OPERATOR(sys.=)
TEST_F(PSQL_DataTypes_UniqueIdentifier, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  vector<string> INSERTED_PK = {
    "00000000-0000-0000-0000-000000000000", // Min
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF", // Max
    "0E984725-C51C-4BF4-9960-E1C80E27ABA0", // Rand
    "364FC78D-F4B6-4B33-8453-C2EDF32E8075"  // Rand
  };

  vector<string> INSERTED_DATA = {
    "00000000-0000-0000-0000-000000000000", // Min
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF", // Max
    "90E044B1-3584-4B38-983A-795593AEBA3B", // Rand
    "69F07EFC-B7A5-4621-BDB8-EFD24B3E239A"  // Rand
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
    COL1_NAME + " OPERATOR(sys.=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>=) " + COL2_NAME
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expected_results
  vector<vector<char>> expected_results = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    for (auto & c: INSERTED_PK[i]) c = toupper(c);
    const char* comp_1 = INSERTED_PK[i].c_str();
    for (auto & c: INSERTED_DATA[i]) c = toupper(c);
    const char* comp_2 = INSERTED_DATA[i].c_str();
    
    expected_results[i].push_back(strcmp(comp_1, comp_2) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(comp_1, comp_2) >= 0 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, 
    OPERATIONS_QUERY, expected_results, true, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
