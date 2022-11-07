#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.bigint_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.bigint";
const string VIEW_NAME = "master_dbo.bigint_view_odbc_test";

const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

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
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_teardown(Drivers::GetDriver(ServerType::PSQL));
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_BigInt, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 20};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "int8"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Insertion_Success) {
  long long int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "NULL",
    "-9223372036854775808",
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> EXPECTED = getExpectedResults_BigInt(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED.size(), BIGINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "-9223372036854775809",
    "9223372036854775808"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Update_Success) {
  long long int data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<long long int> DATA_EXPECTED = getExpectedResults_BigInt(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), BIGINT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUES = {
    "-9223372036854775808",
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> DATA_UPDATED_EXPECTED = getExpectedResults_BigInt(DATA_UPDATED_VALUES);

  const vector<long> EXPECTED_LEN(DATA_UPDATED_EXPECTED.size(), BIGINT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, DATA_INSERTED, DATA_EXPECTED, EXPECTED_INSERT_LEN);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, DATA_UPDATED_VALUES, 
    DATA_UPDATED_EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Update_Fail) {
  long long int data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"12345"};
  const vector<long long int> EXPECTED_DATA_INSERTED = getExpectedResults_BigInt(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), BIGINT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUE = {"9223372036854775808"}; // Over max

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, DATA_INSERTED, 
    EXPECTED_DATA_INSERTED, EXPECTED_INSERT_LEN);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, EXPECTED_DATA_INSERTED, 
    EXPECTED_INSERT_LEN, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Arithmetic_Operators) {
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
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
    "@" + COL1_NAME,             // Absolute Value
  };

  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<long long int>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    long long int data_1 = stringToBigInt(INSERTED_PK[i]);
    long long int data_2 = stringToBigInt(INSERTED_DATA[i]);

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
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, BIGINT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testArithmeticOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_SBIGINT, 
    col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "9223372036854775807",
    "123456789"
  };

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "9223372036854775807"
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
    long long int data_1 = stringToBigInt(INSERTED_PK[i]);
    long long int data_2 = stringToBigInt(INSERTED_DATA[i]);

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

TEST_F(PSQL_DataTypes_BigInt, Comparison_Functions) {
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789",
    "-9223372036854775808"
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

  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, BIGINT_BYTES_EXPECTED);

  // initialization of expected_results
  vector<long long int> expected_results = {};

  long long int curr = stringToBigInt(INSERTED_DATA[0]);
  long long int min_expected = curr, max_expected = curr, sum = curr;

  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = stringToBigInt(INSERTED_DATA[i]);
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
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, SQL_C_SBIGINT, col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  long long int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789",
    "-9223372036854775808"
  };
  
  const vector<long long int> EXPECTED_DATA = getExpectedResults_BigInt(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), BIGINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);
  
  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  long long int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> EXPECTED_DATA = getExpectedResults_BigInt(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), BIGINT_BYTES_EXPECTED);

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Table_Single_Primary_Keys) {
  long long int data;

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

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> EXPECTED_DATA = getExpectedResults_BigInt(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), BIGINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_BigInt, Table_Composite_Primary_Keys) {
  long long int data;

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

  const vector<string> INSERTED_DATA = {
    "9223372036854775807",
    "123456789"
  };
  const vector<long long int> EXPECTED_DATA = getExpectedResults_BigInt(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), BIGINT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SBIGINT, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
