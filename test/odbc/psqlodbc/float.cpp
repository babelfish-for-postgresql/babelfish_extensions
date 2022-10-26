#include "psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.float_table_odbc_test";
const string VIEW_NAME = "master_dbo.float_view_odbc_test";
const string DATATYPE_NAME = "sys.float";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";

const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

const string FLOAT_15 = "1e308";
const string FLOAT_383 = "-1e307";

const int FLOAT_BYTES_EXPECTED = 8;

class PSQL_DataTypes_Float : public testing::Test {

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

    OdbcHandler test_cleanup(Drivers::GetDriver(ServerType::PSQL));
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_cleanup.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

// Helper to convert string to double/float
double StringToFloat(const string &value) {
  if (value == "NULL") {
    return 0;
  }
  return atof(value.c_str());
}

vector<double> getExpectedFloatResults(vector<string> data) {
  vector<double> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(StringToFloat(data[i]));
  }

  return expectedResults;
}

TEST_F(PSQL_DataTypes_Float, ColAttributes) {
  const vector<int> LENGTH_EXPECTED = {4, 8};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "float8"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE_NAME + "(0)"}} // Cannot specify a column width on data type float.
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, invalid_columns);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Insertion_Success) {
  double data{};
  const int bufferLen = 0;

  const vector<string> VALID_INSERTED_VALUES = {
    FLOAT_15,
    FLOAT_383,
    "0.4347509234",
    "NULL"
  };

  const vector<double> expected = getExpectedFloatResults(VALID_INSERTED_VALUES);

  const vector<long> expectedLen(expected.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, VALID_INSERTED_VALUES, 
    expected, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Insertion_Failure) {
  // Range -1e308 to -1e-307  0 and 0 1e307 to 1e308 
  const vector<string> INVALID_INSERTED_VALUES = {
    "1e309",
    "-1e309",
    "1e-325",
    "-1e-324"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
  }


TEST_F(PSQL_DataTypes_Float, Update_Success) {
  double data;
  const int bufferLen = 0;

  const vector<string> DATA_INSERTED = {"0.1"};
  const vector<double> data_expected = getExpectedFloatResults(DATA_INSERTED);
  const vector<long> expectedInsertLen(DATA_INSERTED.size(), FLOAT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUES = {
    FLOAT_383,
    "0",
    FLOAT_15
  };
  const vector<double> DATA_UPDATED_EXPECTED = getExpectedFloatResults(DATA_UPDATED_VALUES);

  const vector<long> expectedLen(DATA_UPDATED_EXPECTED.size(), FLOAT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, DATA_INSERTED, data_expected, expectedInsertLen);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_DOUBLE, data, bufferLen, DATA_UPDATED_VALUES, 
    DATA_UPDATED_EXPECTED, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Update_Fail) {
  double data;
  const int bufferLen = 0;

  const vector<string> DATA_INSERTED = {"0.1"};
  const vector<double> EXPECTED_DATA_INSERTED = getExpectedFloatResults(DATA_INSERTED);
  const vector<long> expectedInsertLen(DATA_INSERTED.size(), FLOAT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUES = {
    "1e400"
  };
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, DATA_INSERTED, EXPECTED_DATA_INSERTED, expectedInsertLen);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_DOUBLE, data, bufferLen, EXPECTED_DATA_INSERTED, 
    expectedInsertLen, DATA_UPDATED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Arithmetic_Operators) {
  const int bufferLen = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "0.8"
  };

  const vector<string> INSERTED_DATA = {
    "22.2"
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
    COL1_NAME + "*" + COL2_NAME,
    COL1_NAME + "/" + COL2_NAME,
    "ABS(" + COL1_NAME + ")",
    "POWER(" + COL1_NAME + "," + COL2_NAME + ")",
    "||/ " + COL1_NAME,
    "LOG(" + COL1_NAME+")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<double>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    double data_1 = StringToFloat(INSERTED_PK[i]);
    double data_2 = StringToFloat(INSERTED_DATA[i]);

    expected_results[i].push_back(data_1 + data_2);
    expected_results[i].push_back(data_1 - data_2);
    expected_results[i].push_back(data_1 * data_2);
    expected_results[i].push_back(data_1 / data_2);

    expected_results[i].push_back(abs(data_1));
    expected_results[i].push_back(pow(data_1, data_2));
    expected_results[i].push_back(cbrt(data_1));
    expected_results[i].push_back(log10(data_1));
  }

  vector<double> col_results(NUM_OF_OPERATIONS, -1);
  const vector<long> expectedLen(NUM_OF_OPERATIONS, FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testArithmeticOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_DOUBLE, 
    col_results, bufferLen, OPERATIONS_QUERY, expected_results, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "0.8"
  };

  const vector<string> INSERTED_DATA = {
    "22.2"
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
    expected_results[i].push_back(INSERTED_PK[i] == INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] != INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] < INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] <= INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] > INSERTED_DATA[i] ? '1' : '0');
    expected_results[i].push_back(INSERTED_PK[i] >= INSERTED_DATA[i] ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Comparison_Functions) {
  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "1.8",
    "22.2",
    "0.4347509234",
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

  const vector<long> expectedLen(NUM_OF_OPERATIONS, FLOAT_BYTES_EXPECTED);

  // initialization of expected_results
  vector<double> expected_results = {};

  double curr = StringToFloat(INSERTED_DATA[0]);
  double min_expected = curr, max_expected = curr, sum = curr;

  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = StringToFloat(INSERTED_DATA[i]);
    sum += curr;

    min_expected = std::min(curr, min_expected);
    max_expected = std::max(curr, max_expected);
  }
  expected_results.push_back(min_expected);
  expected_results.push_back(max_expected);
  expected_results.push_back(sum);
  expected_results.push_back(sum / NUM_OF_DATA);

  // Create a vector of length NUM_OF_OPERATIONS to store column results
  vector<double> col_results(NUM_OF_OPERATIONS, {});
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, SQL_C_DOUBLE, col_results, bufferLen, OPERATIONS_QUERY, expected_results, expectedLen);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, View_creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  double data;
  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    FLOAT_15,
    FLOAT_383,
    "0.4347509234",
    "NULL"
  };
  
  const vector<double> EXPECTED_DATA = getExpectedFloatResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, INSERTED_DATA, EXPECTED_DATA, expectedLen);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, INSERTED_DATA, EXPECTED_DATA, expectedLen);
  
  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  double data;
  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "0.8",
    "22.2"
  };
  const vector<double> EXPECTED_DATA = getExpectedFloatResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  // table name without the schema
  const string tableName = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, INSERTED_DATA, 
    EXPECTED_DATA, expectedLen);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Table_Single_Primary_Keys) {
  double data;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "0.8",
    "22.2"
  };
  const vector<double> EXPECTED_DATA = getExpectedFloatResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, INSERTED_DATA, 
    EXPECTED_DATA, expectedLen);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Float, Table_Composite_Primary_Keys) {
  double data;

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

  const int bufferLen = 0;

  const vector<string> INSERTED_DATA = {
    "0.8",
    "22.2"
  };
  const vector<double> EXPECTED_DATA = getExpectedFloatResults(INSERTED_DATA);

  const vector<long> expectedLen(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, bufferLen, INSERTED_DATA, 
    EXPECTED_DATA, expectedLen);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
