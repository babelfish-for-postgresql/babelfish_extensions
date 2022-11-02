#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.real_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.real";
const string VIEW_NAME = "master_dbo.real_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DATA_COLUMN = 2;
const int FLOAT_BYTES_EXPECTED = 4;

class PSQL_DataTypes_Real : public testing::Test {
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

TEST_F(PSQL_DataTypes_Real, Table_Creation) {
  // TODO - Expected needs to be fixed.
  const vector<int> LENGTH_EXPECTED = {4, 4};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "float4"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Insertion_Success) {
  float data;
  const int BUFFER_LEN = 0;

  // Range of around 1E-37 to 1E+37 with a precision of at least 6 decimal digits
  const vector<string> VALID_INSERTED_VALUES = {
    "0",
    "0.123456",
    "-0.123456",
    "123456.123456",
    "0.123456789",
    "1E+37",
    "1E-37",
    "-1E+37",
    "-1E-37",
    "1e+10",
    "1e-20",
    "0000000000000000001",
    "-0123456789.12345",
    "NULL"
  };
  const vector<float> expected = getExpectedResults_Float(VALID_INSERTED_VALUES);

  const vector<long> EXPECTED_LEN(expected.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, VALID_INSERTED_VALUES, 
    expected, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "1E+39",  // 1E+38 is valid..?
    "1E-46",  // 1E-45 is valid..?
    "-1E+39", // -1E+38 is valid..?
    "-1E-46", // -1E-45 is valid..?
    "999999999999999999999999999999999999999"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Update_Success) {
  float data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"0"};
  const vector<float> EXPECTED_DATA_INSERTED = getExpectedResults_Float(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), FLOAT_BYTES_EXPECTED);

  const vector <string> DATA_UPDATED_VALUES = {
    "-0.123456",
    "0.123456789",
    "1E+37"
  };
  const vector<float> DATA_UPDATED_EXPECTED = getExpectedResults_Float(DATA_UPDATED_VALUES);

  const vector<long> EXPECTED_LEN(DATA_UPDATED_EXPECTED.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, DATA_INSERTED, 
    EXPECTED_DATA_INSERTED, EXPECTED_INSERT_LEN);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_FLOAT, data, BUFFER_LEN, DATA_UPDATED_VALUES, 
    DATA_UPDATED_EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Update_Fail) {
  float data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"0"};
  const vector<float> EXPECTED_DATA_INSERTED = getExpectedResults_Float(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), FLOAT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUE = {"1E+10000"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, DATA_INSERTED, 
    EXPECTED_DATA_INSERTED, EXPECTED_INSERT_LEN);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_FLOAT, data, BUFFER_LEN, EXPECTED_DATA_INSERTED, 
    EXPECTED_INSERT_LEN, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Arithmetic_Operators) {
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "-0.123456",
    "0.123456789",
    "1E+3"
  };

  const vector<string> INSERTED_DATA = {
    "4",
    "9",
    "10.0"
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

    COL1_NAME + "^" + COL2_NAME, // Power
    "|/" + COL2_NAME,            // Square Root
    "||/" + COL2_NAME,           // Cube Root
    "@" + COL2_NAME,             // Absolute Value
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<float>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < INSERTED_DATA.size(); i++) {
    expected_results.push_back({});
    const float data_1 = stringToFloat(INSERTED_PK[i]);    
    const float data_2 = stringToFloat(INSERTED_DATA[i]);    

    expected_results[i].push_back(data_1 + data_2);
    expected_results[i].push_back(data_1 - data_2);
    expected_results[i].push_back(data_1 / data_2);
    expected_results[i].push_back(data_1 * data_2);

    expected_results[i].push_back(pow(data_1, data_2));
    expected_results[i].push_back(sqrt(data_2));
    expected_results[i].push_back(cbrt(data_2));
    expected_results[i].push_back(abs(data_2));
  }

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<float> col_results(NUM_OF_OPERATIONS, -1);
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, FLOAT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testArithmeticOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_FLOAT, 
    col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Arithmetic_Functions) {
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "-0.123456",
    "0.123456789",
    "1E+3"
  };

  const vector<string> INSERTED_DATA = {
    "4",
    "9",
    "10.0"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  string insertString{};
  string comma{};
  // insertString initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL1_NAME + ")",
    "MAX(" + COL1_NAME + ")",
    "SUM(" + COL1_NAME + ")",
    "AVG(" + COL1_NAME + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expected_results
  vector<float> expected_results = {};
  float curr = stringToFloat(INSERTED_PK[0]);
  float min_expected = curr, max_expected = curr, sum_expected = curr, avg_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = stringToFloat(INSERTED_PK[i]);
    sum_expected += curr;
    min_expected = std::min(min_expected, curr);
    max_expected = std::max(max_expected, curr);
  }
  avg_expected = sum_expected / NUM_OF_DATA;
  expected_results.push_back(min_expected);
  expected_results.push_back(max_expected);
  expected_results.push_back(sum_expected);
  expected_results.push_back(avg_expected);

  vector<float> col_results(NUM_OF_OPERATIONS, -1);
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, SQL_C_FLOAT, col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "-1",
    // value with decimals don't work as expected
    // "0.9", 
    "1E+3"
  };

  const vector<string> INSERTED_DATA = {
    "4",
    // "9",
    "10.0"
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
    float data_1 = stringToFloat(INSERTED_PK[i]);    
    float data_2 = stringToFloat(INSERTED_DATA[i]);

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

TEST_F(PSQL_DataTypes_Real, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  float data;
  const int BUFFER_LEN = 0;

  const vector<string> VALID_INSERTED_VALUES = {
    "0",
    "1",
    "NULL"
  };
  const vector<float> EXPECTED_DATA = getExpectedResults_Float(VALID_INSERTED_VALUES);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, VALID_INSERTED_VALUES, EXPECTED_DATA, EXPECTED_LEN);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, VALID_INSERTED_VALUES, EXPECTED_DATA, EXPECTED_LEN);
  
  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };
  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  float data;
  const int BUFFER_LEN = 0;

  const vector<string> VALID_INSERTED_VALUES = {
    "0.1234",
    "1234"
  };
  const vector<float> EXPECTED_DATA = getExpectedResults_Float(VALID_INSERTED_VALUES);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, VALID_INSERTED_VALUES, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, VALID_INSERTED_VALUES, true, VALID_INSERTED_VALUES.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Table_Single_Primary_Keys) {
  float data;

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

  const int BUFFER_LEN = 0;

  vector<string> VALID_INSERTED_VALUES = {
    "0.1234",
    "1234"
  };

  const vector<float> EXPECTED_DATA = getExpectedResults_Float(VALID_INSERTED_VALUES);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, VALID_INSERTED_VALUES, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, VALID_INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Real, Table_Composite_Primary_Keys) {
  float data;

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

  const int BUFFER_LEN = 0;

  const vector<string> VALID_INSERTED_VALUES = {
    "0.1234",
    "1234"
  };

  const vector<float> EXPECTED_DATA = getExpectedResults_Float(VALID_INSERTED_VALUES);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), FLOAT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_FLOAT, data, BUFFER_LEN, VALID_INSERTED_VALUES, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, VALID_INSERTED_VALUES, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
