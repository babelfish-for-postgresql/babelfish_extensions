#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.int_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.int";
const string VIEW_NAME = "master_dbo.int_view_odbc_test";

const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

class PSQL_DataTypes_Int : public testing::Test {

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

TEST_F(PSQL_DataTypes_Int, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 4};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "int4"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Insertion_Success) {
  int data;
  const int BUFFER_LEN = 0;

  const vector<string> VALID_INSERTED_VALUES = {
    "-2147483648",
    "2147483647",
    "3",
    "NULL"
  };

  const vector<int> EXPECTED = getExpectedResults_Int(VALID_INSERTED_VALUES);

  const vector<long> EXPECTED_LEN(EXPECTED.size(), INT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, VALID_INSERTED_VALUES, 
    EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "-2147483649",
    "2147483648"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Update_Success) {
  int data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<int> DATA_EXPECTED = getExpectedResults_Int(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), INT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUES = {
    "5",
    "-2147483648",
    "2147483647"
  };
  const vector<int> DATA_UPDATED_EXPECTED = getExpectedResults_Int(DATA_UPDATED_VALUES);

  const vector<long> EXPECTED_LEN(DATA_UPDATED_EXPECTED.size(), INT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, DATA_INSERTED, DATA_EXPECTED, EXPECTED_INSERT_LEN);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SLONG, data, BUFFER_LEN, DATA_UPDATED_VALUES, 
    DATA_UPDATED_EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Update_Fail) {
  int data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<int> EXPECTED_DATA_INSERTED = getExpectedResults_Int(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), INT_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUE = {"2147483648"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, DATA_INSERTED, 
    EXPECTED_DATA_INSERTED, EXPECTED_INSERT_LEN);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SLONG, data, BUFFER_LEN, EXPECTED_DATA_INSERTED, 
    EXPECTED_INSERT_LEN, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Arithmetic_Operators) {
  const int BUFFER_LEN = 0;

  vector<string> INSERTED_PK = {
    "2",
    "18",
    "2147483645"
  };

  vector<string> INSERTED_DATA = {
    "12",
    "2",
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
    int data_1 = stringToInt(INSERTED_PK[i]);
    int data_2 = stringToInt(INSERTED_DATA[i]);

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
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, INT_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testArithmeticOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_SLONG, 
    col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Comparison_Operators) {
  vector<string> INSERTED_PK = {
    "-123",
    "2",
    "18",
    "2147483645"
  };

  vector<string> INSERTED_DATA = {
    "-8435"
    "12",
    "2",
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
    int data_1 = stringToInt(INSERTED_PK[i]);
    int data_2 = stringToInt(INSERTED_DATA[i]);

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

TEST_F(PSQL_DataTypes_Int, Comparison_Functions) {
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "8",
    "2",
    "-123",
    "2147483647"
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

  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, INT_BYTES_EXPECTED);

  // initialization of expected_results
  vector<int> expected_results = {};

  int curr = stringToInt(INSERTED_DATA[0]);
  int min_expected = curr, max_expected = curr, sum = curr;

  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = stringToInt(INSERTED_DATA[i]);
    sum += curr;

    min_expected = std::min(curr, min_expected);
    max_expected = std::max(curr, max_expected);
  }
  expected_results.push_back(min_expected);
  expected_results.push_back(max_expected);
  expected_results.push_back(sum);
  expected_results.push_back(sum / NUM_OF_DATA);

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<int> col_results(NUM_OF_OPERATIONS, -1);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, SQL_C_SLONG, col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "8",
    "2",
    "-123",
    "2147483647"
  };
  
  const vector<int> EXPECTED_DATA = getExpectedResults_Int(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);
  
  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Table_Single_Primary_Keys) {
  int data;

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

  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "9453542",
    "-42"
  };
  const vector<int> EXPECTED_DATA = getExpectedResults_Int(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Table_Composite_Primary_Keys) {
  int data;

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

  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "9453542",
    "-42"
  };
  const vector<int> EXPECTED_DATA = getExpectedResults_Int(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Int, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "9453542",
    "-42"
  };
  const vector<int> EXPECTED_DATA = getExpectedResults_Int(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
