#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string BBF_TABLE_NAME = "master.dbo.sql_variant_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.sql_variant_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.sql_variant_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.sql_variant_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.sql_variant";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

// Tuple of vectors that contains the following values in the corresponding spots
  //   1. Inserted_values (same as expected from bbf)
  //   2. Expected values for pg (empty string if the same as bbf)
  //   3. Datatype
  //   4. Single-quote-wrapped (needs single quotes around the data inserted)
  const vector<tuple<string, string, string, bool>> SQL_VARIANT_INSERTION_INFO = {
    {"1",                                     "",                     "sys.int",              false},
    {"25",                                    "",                     "smallint",             false},
    {"24",                                    "",                     "sys.bigint",           false},
    {"23",                                    "",                     "sys.tinyint",          false},
    {"2011-04-15 16:44:09.000",               "2011-04-15 16:44:09",  "sys.datetime",         true},
    {"2000-01-01 00:00:00.0000000",           "2000-01-01 00:00:00",  "sys.datetime2",        true},
    {"2000-01-02 00:00:00",                   "",                     "sys.smalldatetime",    true},
    {"2000-03-01",                            "",                     "date",                 true},
    {"12:34:56.0000000",                      "12:34:56",             "time",                 true},
    {"0.123456",                              "",                     "float(3)",             false}, 
    {"0.65432101",                            "0.654321",             "sys.real",             false},
    {"46279.10",                              "",                     "sys.decimal(8,2)",     false},
    {"100000000.0100",                        "",                     "sys.money",            false},
    {"1000.0100",                             "",                     "sys.smallmoney",       false},
    {"1",                                     "",                     "sys.bit",              false},
    {"Hello World nvchar",                    "",                     "sys.nvarchar(30)",     true},
    {"Hello World vchar",                     "",                     "sys.varchar(30)",      true},
    {"Hello World nchar             ",        "",                     "sys.nchar(30)",        true},
    {"Hello World char              ",        "",                     "char(30)",             true},
    {"2A",                                    "0x2a",                 "sys.binary(1)",        false},
    {"2B",                                    "0x2b",                 "sys.varbinary(1)",     false},
    {"0E984725-C51C-4BF4-9960-E1C80E27ABA0",  "",                     "sys.uniqueidentifier", true},
    {"NULL",                                  "",                     "",                     false}
  };

// Similar tuple of vecots as above, but for constrain tests
//  NOTE: binary type fails so it is commented out
const vector<tuple<string, string, string, bool>> SQL_VARIANT_INSERTION_INFO_CONSTRAINT = {
    {"1",                                     "",                     "sys.int",              false},
    {"25",                                    "",                     "smallint",             false},
    {"24",                                    "",                     "sys.bigint",           false},
    {"23",                                    "",                     "sys.tinyint",          false},
    {"2011-04-15 16:44:09.000",               "2011-04-15 16:44:09",  "sys.datetime",         true},
    {"2000-01-01 00:00:00.0000000",           "2000-01-01 00:00:00",  "sys.datetime2",        true},
    {"2000-01-02 00:00:00",                   "",                     "sys.smalldatetime",    true},
    {"2000-03-01",                            "",                     "date",                 true},
    {"12:34:56.0000000",                      "12:34:56",             "time",                 true},
    {"0.123456",                              "",                     "float(3)",             false}, 
    {"0.65432101",                            "0.654321",             "sys.real",             false},
    {"46279.10",                              "",                     "sys.decimal(8,2)",     false},
    {"100000000.0100",                        "",                     "sys.money",            false},
    {"1000.0100",                             "",                     "sys.smallmoney",       false},
    {"0",                                     "",                     "sys.bit",              false},
    {"Hello World nvchar",                    "",                     "sys.nvarchar(30)",     true},
    {"Hello World vchar",                     "",                     "sys.varchar(30)",      true},
    {"Hello World nchar             ",        "",                     "sys.nchar(30)",        true},
    {"Hello World char              ",        "",                     "char(30)",             true},
    // {"2A",                                    "0x2a",                 "sys.binary(1)",        false}, // This is failing
    {"2B",                                    "0x2b",                 "sys.varbinary(1)",     false},
    {"0E984725-C51C-4BF4-9960-E1C80E27ABA0",  "",                     "sys.uniqueidentifier", true}
  };

class PSQL_DataTypes_Sql_Variant : public testing::Test {
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

// Helper function to help set up insertion for sql_variant
void SplitInsertionInfo(const vector<tuple<string,string,string,bool>> &INSERTION_INFO, 
  vector<string> &casted_inserted_values, vector<string> &bbf_expected, vector<string> &pg_expected) {
  // Clear all values for output
  casted_inserted_values.clear();
  bbf_expected.clear();
  pg_expected.clear();
  
  // Get inserted_values
  for (int i = 0; i < INSERTION_INFO.size(); i++) {
    string insert_value     =  std::get<0>(INSERTION_INFO[i]);
    string pg_expected_val  =  std::get<1>(INSERTION_INFO[i]);
    string type             =  std::get<2>(INSERTION_INFO[i]);
    bool needs_quote        =  std::get<3>(INSERTION_INFO[i]);
    bool is_binary          =  type.find("binary") != std::string::npos;
    string insert_string    =  "";

    if (insert_value.compare("NULL") == 0) {
      insert_string = insert_value;
    }
    else if (needs_quote) {
      insert_string = "CAST('" + insert_value + "' AS " + type + ")";
    }
    else if (is_binary) {
      insert_string = "CAST(" + hexToIntStr(insert_value) + " AS " + type + ")";
    }
    else {
      insert_string = "CAST(" + insert_value + " AS " + type + ")";
    }

    casted_inserted_values.push_back(insert_string);
    bbf_expected.push_back(insert_value);
    pg_expected.push_back(pg_expected_val.empty() ? insert_value : pg_expected_val);
  }
  return;
}

// Helper function for SqlVariant_InitOperationsQuery to construct queries
void SqlVariant_OperationsQueryBuilder(const int &pk1, const int &pk2, const string &comparison, 
  vector<string> &bbf_operations_query, vector<string> &pg_operations_query) {
  string bbf_query = "SELECT IIF((" + SelectStatement(BBF_TABLE_NAME, {COL2_NAME}, {}, COL1_NAME + "=" + std::to_string(pk1))
        + ")" + comparison + "("  + SelectStatement(BBF_TABLE_NAME, {COL2_NAME}, {}, COL1_NAME + "=" + std::to_string(pk2))
        + "), '1', '0')";

  string pg_query = "SELECT (" + SelectStatement(PG_TABLE_NAME, {COL2_NAME}, {}, COL1_NAME + "=" + std::to_string(pk1))
    + ") operator(sys." + comparison + ") ("  + SelectStatement(PG_TABLE_NAME, {COL2_NAME}, {}, COL1_NAME + "=" + std::to_string(pk2))
    + ")";

  bbf_operations_query.push_back(bbf_query);
  pg_operations_query.push_back(pg_query);
  return;
}

// Helper function for PSQL_DataTypes_Sql_Variant.Comparison_Operators to create comparison operation queries 
//  that are expected to be true
void SqlVariant_InitOperationsQuery_True(const int &size, vector<string> &bbf_operations_query, 
  vector<string> &pg_operations_query) {
  bbf_operations_query.clear();
  pg_operations_query.clear();

  for (int i = 0; i < size; i++) {
    if (i < size - 1)
    {
      // > operator
      SqlVariant_OperationsQueryBuilder(i, i + 1, ">", bbf_operations_query, pg_operations_query);
      // >= operator
      SqlVariant_OperationsQueryBuilder(i, i + 1, ">=", bbf_operations_query, pg_operations_query);
      // < operator
      SqlVariant_OperationsQueryBuilder(i + 1, i, "<", bbf_operations_query, pg_operations_query);
      // <= operator (less than case)
      SqlVariant_OperationsQueryBuilder(i + 1, i, "<=", bbf_operations_query, pg_operations_query);
      // <> operator
      SqlVariant_OperationsQueryBuilder(i + 1, i, "<>", bbf_operations_query, pg_operations_query);
    }
    // = operator
    SqlVariant_OperationsQueryBuilder(i, i, "=", bbf_operations_query, pg_operations_query);
    // >= operator (equal case)
    SqlVariant_OperationsQueryBuilder(i, i, ">=", bbf_operations_query, pg_operations_query);
    // <= operator (equal case)
    SqlVariant_OperationsQueryBuilder(i, i, "<=", bbf_operations_query, pg_operations_query);  
  }
}

// Helper function for PSQL_DataTypes_Sql_Variant.Comparison_Operators to create comparison operation queries 
//  that are expected to be false
void SqlVariant_InitOperationsQuery_False(const int &size, vector<string> &bbf_operations_query, 
  vector<string> &pg_operations_query) {
  bbf_operations_query.clear();
  pg_operations_query.clear();
    
  for (int i = 0; i < size; i++) {
    if (i < size - 1)
    {
      // > operator
      SqlVariant_OperationsQueryBuilder(i + 1, i, ">", bbf_operations_query, pg_operations_query);
      // >= operator
      SqlVariant_OperationsQueryBuilder(i + 1, i, ">=", bbf_operations_query, pg_operations_query);
      // < operator
      SqlVariant_OperationsQueryBuilder(i, i + 1, "<", bbf_operations_query, pg_operations_query);
      // <= operator (less than case)
      SqlVariant_OperationsQueryBuilder(i, i + 1, "<=", bbf_operations_query, pg_operations_query);
      // = operator
      SqlVariant_OperationsQueryBuilder(i, i + 1, "=", bbf_operations_query, pg_operations_query);
    }
    // <> operator
    SqlVariant_OperationsQueryBuilder(i, i, "<>", bbf_operations_query, pg_operations_query);
  }
}

// Helper function for PSQL_DataTypes_Sql_Variant.Comparison_Operators to validate that all comparisons
//  the @is_all_true indiciates if we expect all values to be true, or all values to be false
void SqlVariant_VerifyOperationsQuery(ServerType server_type, const bool &is_all_true, vector<string> &operations_query) {
  const int BUFFER_LEN = 255;;
  const string EXPECTED_RESULTS = is_all_true ? "1" : "0";
  const SQLLEN EXPECTED_LEN = 1;
  char data[BUFFER_LEN];
  RETCODE rcode;
  SQLLEN data_len;

  OdbcHandler odbcHandler(Drivers::GetDriver(server_type));
  odbcHandler.Connect(true);

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN*>> constraints_bind_columns = {
    {1, SQL_C_CHAR, data, BUFFER_LEN, &data_len}
  };

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(constraints_bind_columns));

  for (int i = 0; i < operations_query.size(); i++) {
    odbcHandler.ExecQuery(operations_query[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(string(data), EXPECTED_RESULTS);
    EXPECT_EQ(data_len, EXPECTED_LEN);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }

  return;
}

TEST_F(PSQL_DataTypes_Sql_Variant, Table_Creation) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  const vector<int> BBF_LENGTH_EXPECTED = {10, 8000};
  const vector<int> BBF_PRECISION_EXPECTED = {10, 8000};
  const vector<int> BBF_SCALE_EXPECTED = {0, 0};
  const vector<string> BBF_NAME_EXPECTED = {"int", "sql_variant"};

  testCommonColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
    TABLE_COLUMNS.size(), COL1_NAME, 
    BBF_LENGTH_EXPECTED, BBF_PRECISION_EXPECTED, 
    BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED = {4, 255};
  const vector<int> PG_PRECISION_EXPECTED = {0, 0};
  const vector<int> PG_SCALE_EXPECTED = {0, 0};
  const vector<string> PG_NAME_EXPECTED = {"int4", "unknown"};

  testCommonColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
    TABLE_COLUMNS.size(), COL1_NAME, 
    PG_LENGTH_EXPECTED, PG_PRECISION_EXPECTED, 
    PG_SCALE_EXPECTED, PG_NAME_EXPECTED);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Sql_Variant, Insertion_Success) {
  vector<string> inserted_values, bbf_expected, pg_expected;
  
  SplitInsertionInfo(SQL_VARIANT_INSERTION_INFO, inserted_values, bbf_expected, pg_expected);
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  // Inserting and verifying in BBF
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, inserted_values, true);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, bbf_expected);

  // Inserting values in PG
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values, true, inserted_values.size());
  
  pg_expected = duplicateElements(pg_expected);
  inserted_values = duplicateElements(inserted_values);

  // Verify all inserted values in PG
  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, pg_expected);
  
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Sql_Variant, Update_Success) {
  const vector<string> EXPECTED_VALUES = {
    "123"
  };

  const vector<string> INSERTED_VALUES = {
    "CAST(" + EXPECTED_VALUES[0] + " as sys.int)"
  };

  const vector<string> UPDATED_VALUES = {
    "2000-03-01",
    "0.123456",
    "Hello World nvchar",
    "NULL",
    "123"
  };

  const vector<string> CASTED_UPDATED_VALUES = {
    "CAST('" + UPDATED_VALUES[0] + "' as date)",
    "CAST(" + UPDATED_VALUES[1] + " as float(3))",
    "CAST('" + UPDATED_VALUES[2] + "' as sys.nvarchar(30))",
    UPDATED_VALUES[3],
    "CAST(" + UPDATED_VALUES[4] + " as sys.int)"
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, INSERTED_VALUES, true);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, CASTED_UPDATED_VALUES, UPDATED_VALUES, true, true);
  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, CASTED_UPDATED_VALUES, UPDATED_VALUES, true, true);

  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Sql_Variant, View_creation) {
  const string BBF_VIEW_QUERY = "SELECT * FROM " + BBF_TABLE_NAME;
  const string PG_VIEW_QUERY = "SELECT * FROM " + PG_TABLE_NAME;
  vector<string> inserted_values, bbf_expected, pg_expected;
  
  SplitInsertionInfo(SQL_VARIANT_INSERTION_INFO, inserted_values, bbf_expected, pg_expected);
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  // Inserting and verifying in BBF
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, inserted_values, true);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, bbf_expected);

  // Inserting values in PG
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values, true, inserted_values.size());
  
  bbf_expected = duplicateElements(bbf_expected);
  pg_expected = duplicateElements(pg_expected);
  inserted_values = duplicateElements(inserted_values);

  // Verify all inserted values in PG
  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, pg_expected);
  
  createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

  verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, inserted_values, bbf_expected, 0, true);
  verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, inserted_values, pg_expected, 0, true);

  dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
  dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
}

// NOTE: sys.binary type fails. This is commented out in SQL_VARIANT_INSERTION_INFO_CONSTRAINT
TEST_F(PSQL_DataTypes_Sql_Variant, Table_Single_Primary_Keys) {
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

  vector<string> inserted_values, bbf_expected, pg_expected;
  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);
  SplitInsertionInfo(SQL_VARIANT_INSERTION_INFO_CONSTRAINT, inserted_values, bbf_expected, pg_expected);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  // Inserting and verifying in BBF
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, inserted_values, true);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, bbf_expected);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, true, inserted_values.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, true, inserted_values.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

// NOTE: sys.binary type fails. This is commented out in SQL_VARIANT_INSERTION_INFO_CONSTRAINT
TEST_F(PSQL_DataTypes_Sql_Variant, Table_Composite_Keys) {
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

  vector<string> inserted_values, bbf_expected, pg_expected;
  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);
  SplitInsertionInfo(SQL_VARIANT_INSERTION_INFO_CONSTRAINT, inserted_values, bbf_expected, pg_expected);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  // Inserting and verifying in BBF
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, inserted_values, true);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, bbf_expected);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, true, 0, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, true, 0, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

// NOTE: sys.binary type fails. This is commented out in SQL_VARIANT_INSERTION_INFO_CONSTRAINT
TEST_F(PSQL_DataTypes_Sql_Variant, Table_Unique_Constraint) {
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

  vector<string> inserted_values, bbf_expected, pg_expected;
  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  SplitInsertionInfo(SQL_VARIANT_INSERTION_INFO_CONSTRAINT, inserted_values, bbf_expected, pg_expected);
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

  // Inserting and verifying in BBF
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, inserted_values, true);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, bbf_expected);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, true, inserted_values.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, true, inserted_values.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Sql_Variant, Comparison_Operators) {
  
  // NOTE, this insertion is ordered from the highest hierarchy to the lowest of different family data types
  const vector<tuple<string, string, string, bool>> INSERTION_INFO = {
    {"0001-01-01 00:00:00.0000000",           "0001-01-01 00:00:00",  "sys.datetime2",        true}, 
    {"0.0",                                   "0.0",                  "sys.real",             false},
    {"0",                                     "",                     "sys.int",              false},
    {"",                                      "",                     "sys.nvarchar(30)",     true},
    {"00",                                    "0x00",                 "sys.varbinary(1)",     false},
    {"00000000-0000-0000-0000-000000000000",  "",                     "sys.uniqueidentifier", true}
  };
  vector<string> inserted_values, bbf_expected, pg_expected;
  vector<string> bbf_operations_query;
  vector<string> pg_operations_query;

  SplitInsertionInfo(INSERTION_INFO, inserted_values, bbf_expected, pg_expected);
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  // Inserting and verifying in BBF
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, inserted_values, true);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, bbf_expected);

  // Verify results in bbf and pg for all comparison results that are expected to be True
  SqlVariant_InitOperationsQuery_True(INSERTION_INFO.size(), bbf_operations_query, pg_operations_query);
  SqlVariant_VerifyOperationsQuery(ServerType::MSSQL, true, bbf_operations_query);
  SqlVariant_VerifyOperationsQuery(ServerType::PSQL, true, pg_operations_query);

  // Verify results in bbf and pg for all comparison results that are expected to be False
  SqlVariant_InitOperationsQuery_False(INSERTION_INFO.size(), bbf_operations_query, pg_operations_query);
  SqlVariant_VerifyOperationsQuery(ServerType::MSSQL, false, bbf_operations_query);
  SqlVariant_VerifyOperationsQuery(ServerType::PSQL, false, pg_operations_query);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}
