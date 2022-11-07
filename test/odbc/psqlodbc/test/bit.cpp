#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.bit_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.bit";
const string VIEW_NAME = "master_dbo.bit_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int BIT_BYTES_EXPECTED = 1;

class PSQL_DataTypes_Bit : public testing::Test {
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

TEST_F(PSQL_DataTypes_Bit, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// Any non-zero values are converted to 1
TEST_F(PSQL_DataTypes_Bit, Insertion_Success) {
  unsigned char data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "1",
    "-0",
    "-1",
    "2",
    "99999999",
    "-9999999",
    "NULL"
  };
  const vector<unsigned char> EXPECTED = getExpectedResults_Bit(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED.size(), BIT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_BIT, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bit, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "A",
    "TEST_STR"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bit, Update_Success) {
  unsigned char data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<unsigned char> DATA_EXPECTED = getExpectedResults_Bit(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), BIT_BYTES_EXPECTED);

  const vector <string> DATA_UPDATED_VALUES = {
    "NULL",
    "1",
    "0",
    "-100",
    "1000"
  };
  const vector<unsigned char> DATA_UPDATED_EXPECTED = getExpectedResults_Bit(DATA_UPDATED_VALUES);

  const vector<long> EXPECTED_LEN(DATA_UPDATED_EXPECTED.size(), BIT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_BIT, data, BUFFER_LEN, DATA_INSERTED, DATA_EXPECTED, EXPECTED_INSERT_LEN);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_BIT, data, BUFFER_LEN, DATA_UPDATED_VALUES, 
    DATA_UPDATED_EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bit, Update_Fail) {
  unsigned char data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<unsigned char> EXPECTED_DATA_INSERTED = getExpectedResults_Bit(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), BIT_BYTES_EXPECTED);
  const vector<string> DATA_UPDATED_VALUE = {"A"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_BIT, data, BUFFER_LEN, DATA_INSERTED, 
    EXPECTED_DATA_INSERTED, EXPECTED_INSERT_LEN);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_BIT, data, BUFFER_LEN, EXPECTED_DATA_INSERTED, 
    EXPECTED_INSERT_LEN, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// Uses explicit casting, ie OPERATOR(sys.=)
TEST_F(PSQL_DataTypes_Bit, Bitwise_Operators) {
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "0",
    "1"
  };

  const vector<string> INSERTED_DATA = {
    "1",
    "1"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    // COL1_NAME + " OPERATOR(sys.&) " + COL2_NAME, // AND
    // COL1_NAME + " OPERATOR(sys.|) " + COL2_NAME, // OR
    // COL1_NAME + " OPERATOR(sys.#) " + COL2_NAME, // XOR
    "OPERATOR(sys.~)" + COL1_NAME,                      // NOT
    "OPERATOR(sys.-)" + COL1_NAME,                      // NOT

    // COL1_NAME + " OPERATOR(sys.||) " + COL2_NAME,
    // COL1_NAME + " OPERATOR(sys.<<) " + COL2_NAME,
    // COL1_NAME + " OPERATOR(sys.>>) " + COL2_NAME,

    COL1_NAME + " OPERATOR(sys.=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>=) " + COL2_NAME
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<char>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    unsigned char data_1 = stringToBit(INSERTED_PK[i]);
    unsigned char data_2 = stringToBit(INSERTED_DATA[i]);

    // expected_results[i].push_back(data_1 & data_2);
    // expected_results[i].push_back(data_1 | data_2);
    // expected_results[i].push_back(data_1 ^ data_2);
    expected_results[i].push_back(1 & ~data_1 ? '1' : '0');
    expected_results[i].push_back(1 & ~data_1 ? '1' : '0');

    // expected_results[i].push_back(data_1 << 1 & data_2); 
    // expected_results[i].push_back(data_1 << data_2);
    // expected_results[i].push_back(data_1 >> data_2);

    expected_results[i].push_back(data_1 == data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 < data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 <= data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 > data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 >= data_2 ? '1' : '0');
  }

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<char> col_results(NUM_OF_OPERATIONS, -1);
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, BIT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bit, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  unsigned char data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "1",
    "NULL"
  };  
  const vector<unsigned char> EXPECTED_DATA = getExpectedResults_Bit(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), BIT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_BIT, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_BIT, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);
  
  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bit, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};
  
  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  unsigned char data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "1"
  };
  const vector<unsigned char> EXPECTED_DATA = getExpectedResults_Bit(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), BIT_BYTES_EXPECTED);

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_BIT, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Bit, Table_Composite_Keys) {
  unsigned char data;
  const int BUFFER_LEN = 0;

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

  const vector<string> INSERTED_DATA = {
    "0",
    "1"
  };
  const vector<unsigned char> EXPECTED_DATA = getExpectedResults_Bit(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), BIT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_BIT, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
