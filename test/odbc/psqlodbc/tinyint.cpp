#include "psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.tinyint_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.tinyint";
const string VIEW_NAME = "master_dbo.tinyint_view_odbc_test";

const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
};

const int TINYINT_BYTES_EXPECTED = 1;

class PSQL_DataTypes_TinyInt : public testing::Test {

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

// Helper function to convert string to equivalent C version of int.
int StringToTinyInt(const string &value) {
  return std::stoi(value.c_str(), NULL, 10);
}

vector<int> getExpectedTinyIntResults(vector<string> data) {
  vector<int> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    if (data[i] != "NULL") {
      expectedResults.push_back(StringToTinyInt(data[i]));
    }
    else {
      // dummy value
      expectedResults.push_back(StringToTinyInt("-1"));
    }
  }
  return expectedResults;
}

TEST_F(PSQL_DataTypes_TinyInt, Table_Creation) {
  // SQL_DESC_LENGTH length reported as 2 for tinyint column instead of 1.
  const vector<int> LENGTH_EXPECTED = {4, 2};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "int2"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Insertion_Success) {
  int data{};
  const int bufferLen = 0;

  const vector<string> VALID_INSERTED_VALUES = {
    "0",
    "255",
    "3",
    "NULL"
  };

  const vector<int> expected = getExpectedTinyIntResults(VALID_INSERTED_VALUES);

  const vector<long> expectedLen(expected.size(), TINYINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, VALID_INSERTED_VALUES, 
    expected, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "-1",
    "256"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Update_Success) {
  int data{};
  const int bufferLen = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<int> data_expected = getExpectedTinyIntResults(DATA_INSERTED);
  const vector<long> expectedInsertLen(DATA_INSERTED.size(), TINYINT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUES = {
    "5",
    "0",
    "255"
  };
  const vector<int> DATA_UPDATED_EXPECTED = getExpectedTinyIntResults(DATA_UPDATED_VALUES);

  const vector<long> expectedLen(DATA_UPDATED_EXPECTED.size(), TINYINT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, DATA_INSERTED, data_expected, expectedInsertLen);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_STINYINT, data, bufferLen, DATA_UPDATED_VALUES, 
    DATA_UPDATED_EXPECTED, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Update_Fail) {
  int data{};
  const int bufferLen = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<int> EXPECTED_DATA_INSERTED = getExpectedTinyIntResults(DATA_INSERTED);
  const vector<long> expectedInsertLen(DATA_INSERTED.size(), TINYINT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUE = {"256"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, DATA_INSERTED, 
    EXPECTED_DATA_INSERTED, expectedInsertLen);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_STINYINT, data, bufferLen, EXPECTED_DATA_INSERTED, 
    expectedInsertLen, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Arithmetic_Operators) {
  const int bufferLen = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  vector<string> INSERTED_PK = {
    "8"
  };

  vector<string> INSERTED_DATA = {
    "2"
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
    COL1_NAME + "+" + COL2_NAME,
    COL1_NAME + "-" + COL2_NAME,
    COL1_NAME + "/" + COL2_NAME,
    COL1_NAME + "*" + COL2_NAME,
    "ABS(" + COL1_NAME + ")",
    "POWER(" + COL1_NAME + "," + COL2_NAME + ")",
    "||/ " + COL1_NAME,
    "LOG(" + COL1_NAME + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<int>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    int data_1 = StringToTinyInt(INSERTED_PK[i]);
    int data_2 = StringToTinyInt(INSERTED_DATA[i]);

    expected_results[i].push_back(data_1 + data_2);
    expected_results[i].push_back(data_1 - data_2);
    expected_results[i].push_back(data_1 / data_2);
    expected_results[i].push_back(data_1 * data_2);

    expected_results[i].push_back(abs(data_1));
    expected_results[i].push_back(pow(data_1, data_2));
    expected_results[i].push_back(cbrt(data_1));
    expected_results[i].push_back(log10(data_1));
  }

  vector<int> col_results(NUM_OF_OPERATIONS, {});
  const vector<long> expectedLen(NUM_OF_OPERATIONS, TINYINT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testArithmeticOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_STINYINT, 
    col_results, bufferLen, OPERATIONS_QUERY, expected_results, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "8"
  };

  const vector<string> INSERTED_DATA = {
    "2"
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
    int data_1 = StringToTinyInt(INSERTED_PK[i]);
    int data_2 = StringToTinyInt(INSERTED_DATA[i]);

    expected_results[i].push_back(data_1 == data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 != data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 < data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 <= data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 > data_2 ? '1' : '0');
    expected_results[i].push_back(data_1 >= data_2 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Comparison_Functions) {
  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "8",
    "2",
    "0",
    "200"
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
    "MIN(" + COL2_NAME + ")",
    "MAX(" + COL2_NAME + ")",
    "SUM(" + COL2_NAME + ")",
    "AVG(" + COL2_NAME + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  const vector<long> expectedLen(NUM_OF_OPERATIONS, TINYINT_BYTES_EXPECTED);

  // initialization of expected_results
  vector<int> expected_results = {};

  int curr = StringToTinyInt(INSERTED_DATA[0]);
  int min_expected = curr, max_expected = curr, sum = curr;

  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = StringToTinyInt(INSERTED_DATA[i]);
    sum += curr;

    min_expected = std::min(curr, min_expected);
    max_expected = std::max(curr, max_expected);
  }
  expected_results.push_back(min_expected);
  expected_results.push_back(max_expected);
  expected_results.push_back(sum);
  expected_results.push_back(sum / NUM_OF_DATA);

  // Create a vector of length NUM_OF_OPERATIONS to store column results
  vector<int> col_results(NUM_OF_OPERATIONS, {});
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, SQL_C_STINYINT, col_results, bufferLen, OPERATIONS_QUERY, expected_results, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  int data{};
  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "255",
    "3",
    "NULL"
  };
  
  const vector<int> EXPECTED_DATA = getExpectedTinyIntResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), TINYINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, INSERTED_DATA, EXPECTED_DATA, expectedLen);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, INSERTED_DATA, EXPECTED_DATA, expectedLen);
  
  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  int data;
  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "1"
  };
  const vector<int> EXPECTED_DATA = getExpectedTinyIntResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), TINYINT_BYTES_EXPECTED);

  // table name without the schema
  const string tableName = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, INSERTED_DATA, 
    EXPECTED_DATA, expectedLen);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Table_Single_Primary_Keys) {
  int data{};

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME},
    {COL2_NAME, DATATYPE_NAME}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "1"
  };
  const vector<int> EXPECTED_DATA = getExpectedTinyIntResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), TINYINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, INSERTED_DATA, 
    EXPECTED_DATA, expectedLen);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_TinyInt, Table_Composite_Primary_Keys) {
  int data{};

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME},
    {COL2_NAME, DATATYPE_NAME}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME,
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "1"
  };
  const vector<int> EXPECTED_DATA = getExpectedTinyIntResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), TINYINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_STINYINT, data, bufferLen, INSERTED_DATA, 
    EXPECTED_DATA, expectedLen);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
