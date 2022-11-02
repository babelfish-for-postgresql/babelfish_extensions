#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string BBF_TABLE_NAME = "master.dbo.smallint_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.smallint_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.smallint_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.smallint_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "smallint";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

const int SMALLINT_BYTES_EXPECTED = 2;

class PSQL_DataTypes_SmallInt : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));

    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", BBF_VIEW_NAME));
    bbf_test_setup.CloseStmt();
    bbf_test_setup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
    
    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", PG_VIEW_NAME));
    pg_test_setup.CloseStmt();
    pg_test_setup.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_SmallInt, Table_Creation) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  const vector<int> BBF_LENGTH_EXPECTED = {10, 5};
  const vector<int> BBF_PRECISION_EXPECTED = {10, 5};
  const vector<int> BBF_SCALE_EXPECTED = {0, 0};
  const vector<string> BBF_NAME_EXPECTED = {"int", "smallint"};

  testCommonColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
    TABLE_COLUMNS.size(), COL1_NAME, 
    BBF_LENGTH_EXPECTED, BBF_PRECISION_EXPECTED, 
    BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED = {4, 2};
  const vector<int> PG_PRECISION_EXPECTED = {0, 0};
  const vector<int> PG_SCALE_EXPECTED = {0, 0};
  const vector<string> PG_NAME_EXPECTED = {"int4", "int2"};

  testCommonColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
    TABLE_COLUMNS.size(), COL1_NAME, 
    PG_LENGTH_EXPECTED, PG_PRECISION_EXPECTED, 
    PG_SCALE_EXPECTED, PG_NAME_EXPECTED);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Insertion_Success) {
  short int data;
  const int BUFFER_LEN = 0;

  vector<string> inserted_values = {
    "NULL",
    "0",
    "530",
    "-32768",
    "32767"
  };
  const int NUM_OF_DATA = inserted_values.size();

  vector<short int> expected_values = getExpectedResults_ShortInt(inserted_values);
  const vector<long> EXPECTED_LEN(expected_values.size() * 2, SMALLINT_BYTES_EXPECTED);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, inserted_values, expected_values, EXPECTED_LEN, 0);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values, true, NUM_OF_DATA);

  inserted_values = duplicateElements(inserted_values);
  expected_values = duplicateElements(expected_values);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, SQL_C_SSHORT, 
                      data, BUFFER_LEN, inserted_values, expected_values, EXPECTED_LEN);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT, 
                      data, BUFFER_LEN, inserted_values, expected_values, EXPECTED_LEN);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES = {
    "-32769", // Under Min
    "32768"   // Over Max
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);

  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Update_Success) {
  short int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_VALUES = {
    "530"
  };
  const vector<short int> EXPECTED_VALUES = getExpectedResults_ShortInt(INSERTED_VALUES);
  const vector<long> EXPECTED_INSERT_LEN(INSERTED_VALUES.size(), SMALLINT_BYTES_EXPECTED);

  const vector<string> UPDATED_VALUES = {
    "NULL",
    "-32768",
    "32767",
    "0",
    "530"
  };
  const vector<short int> EXPECTED_UPDATED_VALUES = getExpectedResults_ShortInt(UPDATED_VALUES);
  const vector<long> EXPECTED_UPDATE_LEN(UPDATED_VALUES.size(), SMALLINT_BYTES_EXPECTED);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_INSERT_LEN);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SSHORT, 
                    data, BUFFER_LEN, UPDATED_VALUES, EXPECTED_UPDATED_VALUES, EXPECTED_UPDATE_LEN);
  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SSHORT, 
                    data, BUFFER_LEN, UPDATED_VALUES, EXPECTED_UPDATED_VALUES, EXPECTED_UPDATE_LEN);

  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT, 
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_INSERT_LEN);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Update_Fail) {
  short int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_VALUES = {
    "530"
  };
  const vector<short int> EXPECTED_VALUES = getExpectedResults_ShortInt(INSERTED_VALUES);
  const vector<long> EXPECTED_INSERT_LEN(INSERTED_VALUES.size(), SMALLINT_BYTES_EXPECTED);

  const vector<string> UPDATED_VALUES = {
    "-32769",       // Under Min
    "32768",        // Over Max
    "9999999999999" // Over
  };
  const vector<long> EXPECTED_UPDATE_LEN(UPDATED_VALUES.size(), SMALLINT_BYTES_EXPECTED);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_INSERT_LEN, 0);

  testUpdateFail(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SSHORT, 
                data, BUFFER_LEN, EXPECTED_VALUES, EXPECTED_UPDATE_LEN, UPDATED_VALUES);
  testUpdateFail(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SSHORT, 
                data, BUFFER_LEN, EXPECTED_VALUES, EXPECTED_UPDATE_LEN, UPDATED_VALUES);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, View_creation) {
  short int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_VALUES = {
    "NULL",
    "0",
    "530",
    "-32768",
    "32767"
  };
  const int NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<short int> EXPECTED_VALUES = getExpectedResults_ShortInt(INSERTED_VALUES);
  const vector<long> EXPECTED_LEN(EXPECTED_VALUES.size(), SMALLINT_BYTES_EXPECTED);


  const string BBF_VIEW_QUERY = "SELECT * FROM " + BBF_TABLE_NAME;
  const string PG_VIEW_QUERY = "SELECT * FROM " + PG_TABLE_NAME;

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_LEN, 0);

  createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

  verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, SQL_C_SSHORT, 
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_LEN);
  verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, SQL_C_SSHORT, 
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_LEN);

  dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
  dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Table_Single_Primary_Keys) {
  short int data;
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "0",
    "530",
    "-32768",
    "32767"
  };
  const int NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<short int> EXPECTED_VALUES = getExpectedResults_ShortInt(INSERTED_VALUES);
  const vector<long> EXPECTED_LEN(NUM_OF_DATA, SMALLINT_BYTES_EXPECTED);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_LEN, 0);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, NUM_OF_DATA, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, NUM_OF_DATA, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Table_Composite_Keys) {
  short int data;
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> PK_COLUMNS = {
    COL1_NAME,
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "0",
    "530",
    "-32768",
    "32767"
  };
  const int NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<short int> EXPECTED_VALUES = getExpectedResults_ShortInt(INSERTED_VALUES);
  const vector<long> EXPECTED_LEN(NUM_OF_DATA, SMALLINT_BYTES_EXPECTED);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_LEN, 0);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, 0, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, 0, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Table_Unique_Constraint) {
  short int data;
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  const vector<string> INSERTED_VALUES = {
    "0",
    "530",
    "-32768",
    "32767"
  };
  const int NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<short int> EXPECTED_VALUES = getExpectedResults_ShortInt(INSERTED_VALUES);
  const vector<long> EXPECTED_LEN(NUM_OF_DATA, SMALLINT_BYTES_EXPECTED);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, INSERTED_VALUES, EXPECTED_VALUES, EXPECTED_LEN, 0);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, NUM_OF_DATA, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, NUM_OF_DATA, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "1000",   // A > B
    "-60",    // A < B
    "33"      // A = B
  };

  const vector<string> INSERTED_DATA = {
    "-1000",
    "-50",
    "33"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
    comma = ",";
  }

  const vector<string> BBF_OPERATIONS_QUERY = {
    "IIF(" + COL1_NAME + " = " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " <> " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " < " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " <= " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " > " + COL2_NAME + ", '1', '0')",
    "IIF(" + COL1_NAME + " >= " + COL2_NAME + ", '1', '0')"
  };

  const vector<string> PG_OPERATIONS_QUERY = {
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

    short int data_A = stringToShortInt(INSERTED_PK[i]);
    short int data_B = stringToShortInt(INSERTED_DATA[i]);    

    expected_results[i].push_back(data_A == data_B ? '1' : '0');
    expected_results[i].push_back(data_A != data_B ? '1' : '0');
    expected_results[i].push_back(data_A <  data_B ? '1' : '0');
    expected_results[i].push_back(data_A <= data_B ? '1' : '0');
    expected_results[i].push_back(data_A >  data_B ? '1' : '0');
    expected_results[i].push_back(data_A >= data_B ? '1' : '0');
  }

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insertString, NUM_OF_DATA);

  testComparisonOperators(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, BBF_OPERATIONS_QUERY, expected_results);
  testComparisonOperators(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, PG_OPERATIONS_QUERY, expected_results);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Comparison_Functions) {
  short int data;
  const int BUFFER_LEN = 0;

  const vector<string> INSERTED_DATA = {
    "0",
    "530",
    "-32768",
    "32767"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();
  const vector<short int> EXPECTED_VALUES = getExpectedResults_ShortInt(INSERTED_DATA);
  const vector<long> EXPECTED_INSERT_LEN(NUM_OF_DATA, SMALLINT_BYTES_EXPECTED);

  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + std::to_string(i) + "," + INSERTED_DATA[i] + ")";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL2_NAME + ")",
    "MAX(" + COL2_NAME + ")",
    "SUM(" + COL2_NAME + ")",
    // "AVG(" + COL2_NAME + ")" // NOTE - AVG() causings BBF connection to close
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();
  const vector<long> EXPECTED_OP_LEN(NUM_OF_OPERATIONS, SMALLINT_BYTES_EXPECTED);

  // initialization of expected_results
  vector<short int> expected_results = {};

  short int curr = stringToShortInt(INSERTED_DATA[0]);
  short int min_expected = curr, max_expected = curr, sum = curr;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    curr = stringToShortInt(INSERTED_DATA[i]);
    sum += curr;

    min_expected = std::min(curr, min_expected);
    max_expected = std::max(curr, max_expected);
  }
  expected_results.push_back(min_expected);
  expected_results.push_back(max_expected);
  expected_results.push_back(sum);
  // expected_results.push_back(sum / NUM_OF_DATA);

  // Create a vector of length NUM_OF_OPERATIONS with dumy value of -1 to store column results
  vector<short int> col_results(NUM_OF_OPERATIONS, -1);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, SQL_C_SSHORT,
                      data, BUFFER_LEN, INSERTED_DATA, EXPECTED_VALUES, EXPECTED_INSERT_LEN, 0);

  testComparisonFunctions(ServerType::MSSQL, BBF_TABLE_NAME, SQL_C_SSHORT, col_results, 
                          BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_OP_LEN);
  testComparisonFunctions(ServerType::PSQL, PG_TABLE_NAME, SQL_C_SSHORT, col_results, 
                          BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_OP_LEN);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_SmallInt, Arithmetic_Operators) {
  const int BUFFER_LEN = 0;

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "-2",
    "3",
    "4"
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

    "abs(" + COL1_NAME + ")",             // Absolute Value
  };

  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  vector<vector<short int>> expected_results = {};

  // initialization of expected_results
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    short int data_1 = stringToShortInt(INSERTED_PK[i]);
    short int data_2 = stringToShortInt(INSERTED_DATA[i]);

    expected_results[i].push_back(data_1 + data_2);
    expected_results[i].push_back(data_1 - data_2);
    expected_results[i].push_back(data_1 / data_2);
    expected_results[i].push_back(data_1 * data_2);

    expected_results[i].push_back(abs(data_1));
  }

  // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
  vector<short int> col_results(NUM_OF_OPERATIONS, -1);
  const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, SMALLINT_BYTES_EXPECTED);
  
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insertString, NUM_OF_DATA);

  testArithmeticOperators(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_SSHORT, 
                          col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
  
  testArithmeticOperators(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_SSHORT, 
                          col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}
