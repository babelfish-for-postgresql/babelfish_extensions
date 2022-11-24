#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.binary_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.binary";
// Default, n = 1, but PG n=4, BBF n=1
const int DATATYPE_SIZE = 1;
const string VIEW_NAME = "master_dbo.binary_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME + "(" + std::to_string(DATATYPE_SIZE) + ")"}
};
// Bytes expected = (2 * n) + 2
// 1 byte takes 2 chracters (in hex) + prepend `0x`
// NOTE - BBF does not prepend `0x` to return data, whilst PG does
const int BINARY_BYTES_EXPECTED = (2 * DATATYPE_SIZE) + 2;

class PSQL_DataTypes_Binary : public testing::Test {
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

TEST_F(PSQL_DataTypes_Binary, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 1};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Binary, Insertion_Success) {
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
    "256"     // Max + 1, truncate
  };
  const vector<string> EXPECTED_VALUES = getExpectedResults_Binary(INSERTED_VALUES, DATATYPE_SIZE);
  const int NUM_OF_INSERTS = INSERTED_VALUES.size();

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, 
                      INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Binary, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "123"
  };
  const vector<string> EXPECTED_VALUES = getExpectedResults_Binary(INSERTED_VALUES, DATATYPE_SIZE);

  const vector <string> UPDATED_VALUES = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
    "256"     // Max + 1, truncate
  };
  const vector<string> EXPECTED_UPDATED_VALUES = getExpectedResults_Binary(UPDATED_VALUES, DATATYPE_SIZE);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME,
                      INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, 
                    UPDATED_VALUES, EXPECTED_UPDATED_VALUES, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Binary, View_creation) {
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
    "256"     // Max + 1, truncate
  };

  const vector<string> EXPECTED_VALUES = getExpectedResults_Binary(INSERTED_VALUES, DATATYPE_SIZE);

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Binary, Table_Single_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME + "(" + std::to_string(DATATYPE_SIZE) + ")"}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);
  
  const vector<string> INSERTED_VALUES = {
    "00",     // Min
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
  };
  const size_t NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<string> EXPECTED_VALUES = getExpectedResults_Binary(INSERTED_VALUES, DATATYPE_SIZE);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, NUM_OF_DATA, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Binary, Table_Composite_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME + "(" + std::to_string(DATATYPE_SIZE) + ")"}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);
  
  const vector<string> INSERTED_VALUES = {
    "00",     // Min
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
  };
  const size_t NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<string> EXPECTED_VALUES = getExpectedResults_Binary(INSERTED_VALUES, DATATYPE_SIZE);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Binary, Table_Unique_Constraint) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME + "(" + std::to_string(DATATYPE_SIZE) + ")"}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE ", UNIQUE_COLUMNS);
  
  const vector<string> INSERTED_VALUES = {
    "00",     // Min
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
  };
  const size_t NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<string> EXPECTED_VALUES = getExpectedResults_Binary(INSERTED_VALUES, DATATYPE_SIZE);

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// Results for `<` are incorrect
TEST_F(PSQL_DataTypes_Binary, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "0",      // A = B
    "96",     // A < B
    "128",    // A > B
  };
  vector<string> where_pk = {};

  const vector<string> INSERTED_DATA = {
    "0",      // A = B
    "255",    // A < B
    "32",     // A > B
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    where_pk.push_back("cast(" + INSERTED_PK[i] + " as sys.varbinary)");
    insertString += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    COL1_NAME + " OPERATOR(sys.=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<>) " + COL2_NAME,
    // COL1_NAME + " OPERATOR(sys.<) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>=) " + COL2_NAME
  };

  // initialization of expected_results
  vector<vector<char>> expected_results = {};

  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    const int DATA_1 = atoi(INSERTED_PK[i].c_str());
    const int DATA_2 = atoi(INSERTED_DATA[i].c_str());

    expected_results[i].push_back(DATA_1 == DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 != DATA_2 ? '1' : '0');
    // expected_results[i].push_back(DATA_1 < DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 <= DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 > DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 >= DATA_2 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, where_pk, INSERTED_DATA, 
    OPERATIONS_QUERY, expected_results, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
