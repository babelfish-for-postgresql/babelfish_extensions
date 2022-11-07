#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.money_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.money";
const string VIEW_NAME = "master_dbo.money_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DOUBLE_BYTES_EXPECTED = 8;

class PSQL_DataTypes_Money : public testing::Test {
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

TEST_F(PSQL_DataTypes_Money, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Insertion_Success) {
  double data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "-922337203685477.5808",
    "922337203685477.5807",
    "0",
    "100000000.01",
    "-100000000.01",
    "NULL"
  };
  const vector<double> EXPECTED = getExpectedResults_Double(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED.size(), DOUBLE_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "AAA",
    "-922337203685477.5809",
    "922337203685477.5808",
    "999999999999999999999999999999",
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Update_Success) {
  double data;
  const int BUFFER_LEN = 0;

  const vector<string> DATA_INSERTED = {"1"};
  const vector<double> DATA_EXPECTED = getExpectedResults_Double(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), DOUBLE_BYTES_EXPECTED);

  const vector <string> DATA_UPDATED_VALUES = {
    "NULL",
    "-922337203685477.5808",
    "922337203685477.5807",
    "0"
  };
  const vector<double> DATA_UPDATED_EXPECTED = getExpectedResults_Double(DATA_UPDATED_VALUES);

  const vector<long> EXPECTED_LEN(DATA_UPDATED_EXPECTED.size(), DOUBLE_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, DATA_INSERTED, DATA_EXPECTED, EXPECTED_INSERT_LEN);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, DATA_UPDATED_VALUES, 
    DATA_UPDATED_EXPECTED, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Update_Fail) {
  double data;
  const int BUFFER_LEN = 0;
  
  const vector<string> DATA_INSERTED = {"12345"};
  const vector<double> EXPECTED_DATA_INSERTED = getExpectedResults_Double(DATA_INSERTED);
  const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), DOUBLE_BYTES_EXPECTED);

  const vector<string> DATA_UPDATED_VALUE = {"999999999999999999999999999999"}; // Over max

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, DATA_INSERTED, 
    EXPECTED_DATA_INSERTED, EXPECTED_INSERT_LEN);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, EXPECTED_DATA_INSERTED, 
    EXPECTED_INSERT_LEN, DATA_UPDATED_VALUE);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Arithmetic_Operators) {
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "-987654321.1234",
    "-123456789.4321",
    "0"
  };

  const vector<string> INSERTED_DATA = {
    "2.01",
    "-100000000.01",
    "922337203685477.5807"
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
    COL1_NAME + "*" + COL2_NAME
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<double>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < INSERTED_DATA.size(); i++) {
    expected_results.push_back({});
    const double data_1 = stringToDouble(INSERTED_PK[i]);
    const double data_2 = stringToDouble(INSERTED_DATA[i]);

    expected_results[i].push_back(data_1 + data_2);
    expected_results[i].push_back(data_1 - data_2);
    expected_results[i].push_back(data_1 / data_2);
    expected_results[i].push_back(data_1 * data_2);
  }

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<double> col_results(NUM_OF_OPERATIONS, -1);
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, DOUBLE_BYTES_EXPECTED);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testArithmeticOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_DOUBLE, 
    col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "-987654321.1234",
    "-123456789.4321",
    "0"
  };

  const vector<string> INSERTED_DATA = {
    "2.01",
    "-100000000.01",
    "922337203685477.5807"
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
    const double data_1 = stringToDouble(INSERTED_PK[i]);
    const double data_2 = stringToDouble(INSERTED_DATA[i]);

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

TEST_F(PSQL_DataTypes_Money, Comparison_Functions) {
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "-987654321.1234",
    "-123456789.4321",
    "0"
  };

  const vector<string> INSERTED_DATA = {
    "2.01",
    "-100000000.01",
    "922337203685477.5807"
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
    "MIN(" + COL1_NAME + ")",
    "MAX(" + COL1_NAME + ")",
    "SUM(" + COL1_NAME + ")",
    "AVG(" + COL1_NAME + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();
  
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, DOUBLE_BYTES_EXPECTED);

  // initialization of expected_results
  vector<double> expected_results = {};
  double curr = stringToDouble(INSERTED_PK[0]);
  double min_expected = curr, max_expected = curr, sum_expected = curr, avg_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = stringToDouble(INSERTED_PK[i]);
    sum_expected += curr;
    min_expected = std::min(min_expected, curr);
    max_expected = std::max(max_expected, curr);
  }
  avg_expected = sum_expected / NUM_OF_DATA;
  expected_results.push_back(min_expected);
  expected_results.push_back(max_expected);
  expected_results.push_back(sum_expected);
  expected_results.push_back(avg_expected);

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<double> col_results(NUM_OF_OPERATIONS, -1);
  
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonFunctions(ServerType::PSQL, TABLE_NAME, SQL_C_DOUBLE, col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  double data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "123456789.0001",
    "1",
    "NULL"
  };
  
  const vector<double> EXPECTED_DATA = getExpectedResults_Double(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), DOUBLE_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);
  
  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  double data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "1000.0001",
    "-1000.0001"
  };
  const vector<double> EXPECTED_DATA = getExpectedResults_Double(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), DOUBLE_BYTES_EXPECTED);

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Table_Single_Primary_Keys) {
  double data;

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
    "1000.01",
    "-100.0001"
  };
  const vector<double> EXPECTED_DATA = getExpectedResults_Double(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), DOUBLE_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Money, Table_Composite_Keys) {
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

  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "1000.01",
    "-100.0001"
  };
  const vector<double> EXPECTED_DATA = getExpectedResults_Double(INSERTED_DATA);

  const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), DOUBLE_BYTES_EXPECTED);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_DOUBLE, data, BUFFER_LEN, INSERTED_DATA, 
    EXPECTED_DATA, EXPECTED_LEN);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
