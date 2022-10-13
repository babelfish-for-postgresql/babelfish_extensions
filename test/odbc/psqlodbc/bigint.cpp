#include <gtest/gtest.h>
#include <sqlext.h>
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"
#include "../src/drivers.h"
#include <cmath>
#include <iostream>
#include <time.h>
#include "psqlodbc_tests_common.h"
using std::pair;

const string TABLE_NAME = "master_dbo.bigint_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.bigint";
const string VIEW_NAME = "master_dbo.bigint_view_odbc_test";
static vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

const int INT_BYTES_EXPECTED = 4;
const int BIGINT_BYTES_EXPECTED = 8;

class PSQL_DataTypes_BigInt : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }

  void TearDown() override {
    OdbcHandler test_teardown(Drivers::GetDriver(ServerType::PSQL));
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

long long int StringToBigInt(const string &value) {
  return strtoll(value.c_str(), NULL, 10);
}

vector<long long int> getExpectedResults(vector<string> data) {
  vector<long long int> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(StringToBigInt(data[i]));
  }

  return expectedResults;
}

TEST_F(PSQL_DataTypes_BigInt, Table_Creation) {

  const vector<int> LENGTH_EXPECTED = {4, 19};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "int8"};

  testCommonColumnAttributes(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, LENGTH_EXPECTED, PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
}

TEST_F(PSQL_DataTypes_BigInt, Insertion_Success) {

  long long int data;
  int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "NULL",
    "-9223372036854775808",
    "9223372036854775807",
    "123456789"
  };
  vector<long long int> expected = getExpectedResults(INSERTED_DATA);

  vector<long> expectedLen(expected.size(), BIGINT_BYTES_EXPECTED);

  testInsertionSuccessNumeric(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, SQL_C_SBIGINT, data, bufferLen, INSERTED_DATA, expected, expectedLen);
}

TEST_F(PSQL_DataTypes_BigInt, Insertion_Fail) {

  const vector<string> INVALID_INSERTED_VALUES = {
    "-9223372036854775809",
    "9223372036854775808"
  };

  testInsertionFailure(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, INVALID_INSERTED_VALUES, true);
}

TEST_F(PSQL_DataTypes_BigInt, Update_Success) {
  long long int data;
  int bufferLen = 0;

  const  vector<string> DATA_INSERTED = {"1"};
  const vector<long long int> data_expected = getExpectedResults(DATA_INSERTED);
  vector<long> expectedInsertLen(DATA_INSERTED.size(), BIGINT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUES = {
    "-9223372036854775808",
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> DATA_UPDATED_EXPECTED = getExpectedResults(DATA_UPDATED_VALUES);

  vector<long> expectedLen(DATA_UPDATED_EXPECTED.size(), BIGINT_BYTES_EXPECTED);
  
  testUpdateSuccessNumeric(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, COL2_NAME, SQL_C_SBIGINT, data, bufferLen, DATA_INSERTED, data_expected, expectedInsertLen, DATA_UPDATED_VALUES, DATA_UPDATED_EXPECTED, expectedLen);
}

TEST_F(PSQL_DataTypes_BigInt, Update_Fail) {
  long long int data;
  int bufferLen = 0;

  const vector<string> DATA_INSERTED = {"12345"};
  const vector<long long int> EXPECTED_DATA_INSERTED = getExpectedResults(DATA_INSERTED);
  vector<long> expectedInsertLen(DATA_INSERTED.size(), BIGINT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUE = {"9223372036854775808"}; // Over max

  testUpdateFailNumeric(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, COL2_NAME, SQL_C_SBIGINT, data, bufferLen, DATA_INSERTED, EXPECTED_DATA_INSERTED, expectedInsertLen, DATA_UPDATED_VALUE);
}

TEST_F(PSQL_DataTypes_BigInt, Arithmetic_Operators) {
  int bufferLen = 0;

  vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };


  const vector<string> INSERTED_PK = {
    "-73708",
    "123",
    "233"
  };

  const vector<string> INSERTED_DATA = {
    "2",
    "3",
    "5"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    COL1_NAME + "+" + COL2_NAME,
    COL1_NAME + "-" + COL2_NAME,
    COL1_NAME + "/" + COL2_NAME,
    COL1_NAME + "*" + COL2_NAME,

    COL1_NAME + "^" + COL2_NAME, // Power
    "|/" + COL2_NAME,            // Square Root
    "||/" + COL2_NAME,           // Cube Root
    "@" + COL1_NAME,             // Absolute Value
  };

  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<long long int>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    long long int data_1 = StringToBigInt(INSERTED_PK[i]);
    long long int data_2 = StringToBigInt(INSERTED_DATA[i]);

    expected_results[i].push_back(data_1 + data_2);
    expected_results[i].push_back(data_1 - data_2);
    expected_results[i].push_back(data_1 / data_2);
    expected_results[i].push_back(data_1 * data_2);

    expected_results[i].push_back(pow(data_1, data_2));
    expected_results[i].push_back(sqrt(data_2));
    expected_results[i].push_back(cbrt(data_2));
    expected_results[i].push_back(abs(data_1));
  }

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<long long int> col_results(NUM_OF_OPERATIONS, -1);
  vector<long> expectedLen(NUM_OF_OPERATIONS, BIGINT_BYTES_EXPECTED);

  testArithmeticOperators(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, SQL_C_SBIGINT, col_results, bufferLen, INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results, expectedLen);
}

TEST_F(PSQL_DataTypes_BigInt, Comparison_Operators) {

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  vector<string> INSERTED_PK = {
    "9223372036854775807",
    "123456789"
  };

  vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "9223372036854775807"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  vector<string> OPERATIONS_QUERY = {
    COL1_NAME + "=" + COL2_NAME,
    COL1_NAME + "<>" + COL2_NAME,
    COL1_NAME + "<" + COL2_NAME,
    COL1_NAME + "<=" + COL2_NAME,
    COL1_NAME + ">" + COL2_NAME,
    COL1_NAME + ">=" + COL2_NAME
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expected_results
  vector<vector<char>> expected_results = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    expected_results[i].push_back(INSERTED_PK[i] == INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] != INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] < INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] <= INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] > INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] >= INSERTED_DATA[i] ? '1' : '0');
  }

  testComparisonOperators(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results);
}

TEST_F(PSQL_DataTypes_BigInt, Comparison_Functions) {

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789",
    "-9223372036854775808"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL2_NAME + ")",
    "MAX(" + COL2_NAME + ")",
    "SUM(" + COL2_NAME + ")",
    "AVG(" + COL2_NAME + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expected_results
  vector<long long int> expected_results = {};
  long long int curr = StringToBigInt(INSERTED_DATA[0]);
  long long int min_expected = curr, max_expected = curr, sum = curr;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = StringToBigInt(INSERTED_DATA[i]);
    sum += curr;

    min_expected = std::min(curr, min_expected);
    max_expected = std::max(curr, max_expected);
  }
  expected_results.push_back(min_expected);
  expected_results.push_back(max_expected);
  expected_results.push_back(sum);
  expected_results.push_back(sum / NUM_OF_DATA);

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<long long int> col_results(NUM_OF_OPERATIONS, -1);
  
  testComparisonFunctionsNumeric(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, SQL_C_SBIGINT, col_results, 0, INSERTED_DATA, OPERATIONS_QUERY, expected_results,{8,8,8,8});
}

TEST_F(PSQL_DataTypes_BigInt, View_Creation) {

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  long long int data;
  int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789",
    "-9223372036854775808"
  };
  
  const vector<long long int> EXPECTED_DATA = {
    StringToBigInt("9223372036854775807"),
    StringToBigInt("123456789"),
    StringToBigInt("-9223372036854775808")
  };

  vector<long> expectedLen(EXPECTED_DATA.size(), BIGINT_BYTES_EXPECTED);

  testViewCreationNumeric(VIEW_NAME, TABLE_NAME, TABLE_COLUMNS, COL1_NAME, SQL_C_SBIGINT, data, bufferLen, INSERTED_DATA, EXPECTED_DATA, expectedLen);
}

TEST_F(PSQL_DataTypes_BigInt, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME + " UNIQUE"}
  };

  const vector<string> UNIQUE_COLUMN_NAME = {COL2_NAME};

  long long int data;
  int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> EXPECTED_DATA = {
    StringToBigInt("9223372036854775807"),
    StringToBigInt("123456789")
  };

  vector<long> expectedLen(EXPECTED_DATA.size(), BIGINT_BYTES_EXPECTED);

  testUniqueConstraintNumeric(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, SQL_C_SBIGINT, data, bufferLen, UNIQUE_COLUMN_NAME, INSERTED_DATA, EXPECTED_DATA, expectedLen);
}

TEST_F(PSQL_DataTypes_BigInt, Table_Composite_Keys) {

  long long int data;

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

  int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> EXPECTED_DATA = getExpectedResults(INSERTED_DATA);

  vector<long> expectedLen(EXPECTED_DATA.size(), BIGINT_BYTES_EXPECTED);

  testPrimaryKeysNumeric(TABLE_NAME, TABLE_COLUMNS, COL1_NAME, SQL_C_SBIGINT, data, bufferLen, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS, INSERTED_DATA, EXPECTED_DATA, expectedLen);
}
