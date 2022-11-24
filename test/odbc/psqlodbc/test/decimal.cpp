#include "../psqlodbc_tests_common.h"

const string PG_TABLE_NAME = "master_dbo.decimal_table_odbc_test";
const string BBF_TABLE_NAME = "master.dbo.decimal_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.decimal_view_odbc_test";
const string BBF_VIEW_NAME = "decimal_view_odbc_test";
const string DATATYPE = "decimal";

const vector<string> COL_NAMES = {"pk_1_0", "dec_5_5", "dec_38_38", "dec_38_0", "decm_4_2"};
const vector<int> COL_PRECISION = {1, 5, 38, 38, 4};
const vector<int> COL_SCALE = {0, 5, 38, 0, 2};

const vector<int> PG_LENGTH_EXPECTED = {3, 7, 40, 40, 6}; 
const vector<int> BBF_LENGTH_EXPECTED = {1, 5, 38, 38, 4}; 

const vector<string> COL_TYPES = {
  DATATYPE + "(" + std::to_string(COL_PRECISION[0]) + "," + std::to_string(COL_SCALE[0]) + ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[1]) + "," + std::to_string(COL_SCALE[1]) + ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[2]) + "," + std::to_string(COL_SCALE[2]) + ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[3]) + "," + std::to_string(COL_SCALE[3]) + ")",
  DATATYPE + "(" + std::to_string(COL_PRECISION[4]) + "," + std::to_string(COL_SCALE[4]) + ")"
};

static const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL_NAMES[0], COL_TYPES[0] + " PRIMARY KEY"},
  {COL_NAMES[1], COL_TYPES[1]},
  {COL_NAMES[2], COL_TYPES[2]},
  {COL_NAMES[3], COL_TYPES[3]},
  {COL_NAMES[4], COL_TYPES[4]}
};
static const int PK_INDEX = 0;

const string MAX_DEC_5_5 = "0.99999";
const string MAX_DEC_38_38 = "0.99999999999999999999999999999999999999";
const string MAX_DEC_38_0 = "99999999999999999999999999999999999999";
const string MAX_DEC_4_2 = "99.99";


class PSQL_DataTypes_Decimal : public testing::Test {
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

TEST_F(PSQL_DataTypes_Decimal, Table_Creation) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);
  vector<string> name_expected;

  for (int i = 0; i < TABLE_COLUMNS.size(); i++) {
    name_expected.push_back("numeric");
  }

  testCommonColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME,
    TABLE_COLUMNS.size(), COL_NAMES[PK_INDEX],
    BBF_LENGTH_EXPECTED, COL_PRECISION, COL_SCALE,
    name_expected);

  testCommonColumnAttributes(ServerType::PSQL, PG_TABLE_NAME,
    TABLE_COLUMNS.size(), COL_NAMES[PK_INDEX],
    PG_LENGTH_EXPECTED, COL_PRECISION, COL_SCALE,
    name_expected);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

/* TODO: Uncomment this test once BABEL-3720 get fixed
TEST_F(PSQL_DataTypes_Decimal, Table_Creation_Fail) {
  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE + "(0, 0)"}}, // must have precision of 1 or greater
    {{"invalid2", DATATYPE + "(10, 11)"}}, // scale cannot be larger than precision
    {{"invalid3", DATATYPE + "(10, -1)"}} // precision must be 0 or greater
  };

  testTableCreationFailure(ServerType::PSQL, PG_TABLE_NAME, invalid_columns);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  testTableCreationFailure(ServerType::MSSQL, BBF_TABLE_NAME, invalid_columns);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}*/

TEST_F(PSQL_DataTypes_Decimal, Insertion_Success) {
  const vector<vector<string>> LIST_OF_INSERTED_VALUES = {
    {"0", "0", "0", "0"}, // smallest numbers
    {MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {"-0.694", "0.4347509234", "-8532", "42.8"}, // random regular values
    {"NULL", "NULL", "NULL", "NULL"} // NULL values
  };
  
  for (int i = 0; i < LIST_OF_INSERTED_VALUES.size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i + 1]
    };

    vector<string> insert_values = getVectorBasedOnColumn(LIST_OF_INSERTED_VALUES, i);
    vector<string> bbf_expected_values = insert_values;
    vector<string> pg_expected_values = insert_values;

    formatNumericExpected(bbf_expected_values, COL_SCALE[i + 1], true);
    formatNumericExpected(pg_expected_values, COL_SCALE[i + 1], false);
    
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);
    insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insert_values, true);
    insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, insert_values, true, bbf_expected_values.size());

    insert_values = duplicateElements(insert_values);
    pg_expected_values = duplicateElements(pg_expected_values);
    bbf_expected_values = duplicateElements(bbf_expected_values);

    verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL_NAMES[PK_INDEX], insert_values, pg_expected_values);
    verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL_NAMES[PK_INDEX], insert_values, bbf_expected_values);

    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

TEST_F(PSQL_DataTypes_Decimal, Insertion_Failure) {
  const vector<string> LIST_OF_FAIL_INSERTED_VALUES = {
    MAX_DEC_5_5 + "9", // first col exceeds by 1 digit
    MAX_DEC_38_38 + "9", // second col exceeds by 1 digit
    MAX_DEC_38_0 + ".5", // third col exceeds by 1 digit (extra decimal)
    "9" + MAX_DEC_4_2 // fourth col exceeds by adding a digit in the front
  };
  
  for (int i = 0; i < LIST_OF_FAIL_INSERTED_VALUES.size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i + 1]
    };
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);

    testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL_NAMES[PK_INDEX], 
      {LIST_OF_FAIL_INSERTED_VALUES[i]}, true, 0, true);
    testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL_NAMES[PK_INDEX], 
      {LIST_OF_FAIL_INSERTED_VALUES[i]}, true, 0, true);

    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

TEST_F(PSQL_DataTypes_Decimal, Update_Success) {
  const vector<vector<string>> LIST_OF_INSERTED_VALUES = {
    {"0.1", "0.2", "3", "4.4"}, // regular values for insertion (but will update to the same values during the test)
    {"0", "0", "0", "0" }, // update to smallest numbers
    {MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // update to max values
    {"-0.694", "0.4347509234", "-8532", "42.8"}, // update to random regular values
    {"NULL", "NULL", "NULL", "NULL"} // update to NULL values
  };
  const int INSERT_INDEX = 0;

  for (int i = 0; i < LIST_OF_INSERTED_VALUES[INSERT_INDEX].size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i + 1]
    };

    vector<string> insert_values = {LIST_OF_INSERTED_VALUES[INSERT_INDEX][i]};
    vector<string> updated_values = getVectorBasedOnColumn(LIST_OF_INSERTED_VALUES, i);

    vector<string> bbf_expected_values = updated_values;
    vector<string> pg_expected_values = updated_values;

    formatNumericExpected(bbf_expected_values, COL_SCALE[i + 1], true);
    formatNumericExpected(pg_expected_values, COL_SCALE[i + 1], false);
    
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);
    insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insert_values, true);

    testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL_NAMES[PK_INDEX], 
      table_cols_for_insert[table_cols_for_insert.size() - 1].first, updated_values, pg_expected_values);
    testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL_NAMES[PK_INDEX],
      table_cols_for_insert[table_cols_for_insert.size() - 1].first, updated_values, bbf_expected_values);

    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

TEST_F(PSQL_DataTypes_Decimal, Update_Fail) {
  const vector<vector<string>> LIST_OF_INSERTED_VALUES = {
    {"0.1", "0.2", "3", "4.4"}, // regular values for insertion
    {MAX_DEC_5_5 + "9", MAX_DEC_38_38 + "9", MAX_DEC_38_0 + ".5", "9" + MAX_DEC_4_2}, // failed updates
  };
  const int INSERT_INDEX = 0;

  for (int i = 0; i < LIST_OF_INSERTED_VALUES[INSERT_INDEX].size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i + 1]
    };

    vector<string> insert_values = {LIST_OF_INSERTED_VALUES[INSERT_INDEX][i]};
    vector<string> updated_values = getVectorBasedOnColumn(LIST_OF_INSERTED_VALUES, i);
    updated_values.erase(updated_values.begin());

    vector<string> bbf_expected_values = insert_values;
    vector<string> pg_expected_values = insert_values;

    formatNumericExpected(bbf_expected_values, COL_SCALE[i + 1], true);
    formatNumericExpected(pg_expected_values, COL_SCALE[i + 1], false);
    
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);
    insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insert_values, true);

    testUpdateFail(ServerType::PSQL, PG_TABLE_NAME, COL_NAMES[PK_INDEX], 
      table_cols_for_insert[table_cols_for_insert.size() - 1].first, pg_expected_values, updated_values);
    testUpdateFail(ServerType::MSSQL, BBF_TABLE_NAME, COL_NAMES[PK_INDEX],
      table_cols_for_insert[table_cols_for_insert.size() - 1].first, bbf_expected_values, updated_values);

    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

TEST_F(PSQL_DataTypes_Decimal, View_creation) {
  const vector<vector<string>> LIST_OF_INSERTED_VALUES = {
    {"0", "0", "0", "0"}, // smallest numbers
    {MAX_DEC_5_5, MAX_DEC_38_38, MAX_DEC_38_0, MAX_DEC_4_2}, // max values
    {"-0.694", "0.4347509234", "-8532", "42.8"}, // random regular values
    {"NULL", "NULL", "NULL", "NULL"} // NULL values
  };
  
  for (int i = 0; i < LIST_OF_INSERTED_VALUES.size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i + 1]
    };

    vector<string> insert_values = getVectorBasedOnColumn(LIST_OF_INSERTED_VALUES, i);
    vector<string> bbf_expected_values = insert_values;
    vector<string> pg_expected_values = insert_values;

    formatNumericExpected(bbf_expected_values, COL_SCALE[i + 1], true);
    formatNumericExpected(pg_expected_values, COL_SCALE[i + 1], false);
    
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);
    createView(ServerType::MSSQL, BBF_VIEW_NAME, "SELECT * FROM " + BBF_TABLE_NAME);

    insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insert_values, true);
    insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, insert_values, true, bbf_expected_values.size());

    insert_values = duplicateElements(insert_values);
    pg_expected_values = duplicateElements(pg_expected_values);
    bbf_expected_values = duplicateElements(bbf_expected_values);

    verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL_NAMES[PK_INDEX], insert_values, pg_expected_values);
    verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL_NAMES[PK_INDEX], insert_values, bbf_expected_values);

    dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
    dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

TEST_F(PSQL_DataTypes_Decimal, Table_Single_Primary_Keys) {
  const string COL1_NAME = "col1";
  const string COL2_NAME = COL_NAMES[PK_INDEX];
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, COL_TYPES[PK_INDEX]}
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
    "1",
    "2",
    "3",
    "4"  
  };

  vector<string> bbf_expected_values = INSERTED_VALUES;
  vector<string> pg_expected_values = INSERTED_VALUES;

  formatNumericExpected(bbf_expected_values, COL_SCALE[PK_INDEX], true);
  formatNumericExpected(pg_expected_values, COL_SCALE[PK_INDEX], true);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, bbf_expected_values, 0, true);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Decimal, Table_Composite_Keys) {
  const string COL1_NAME = "col1";
  const string COL2_NAME = COL_NAMES[PK_INDEX];
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, COL_TYPES[PK_INDEX]}
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
    "1",
    "2",
    "3",
    "4"  
  };

  vector<string> bbf_expected_values = INSERTED_VALUES;
  vector<string> pg_expected_values = INSERTED_VALUES;

  formatNumericExpected(bbf_expected_values, COL_SCALE[PK_INDEX], true);
  formatNumericExpected(pg_expected_values, COL_SCALE[PK_INDEX], true);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, bbf_expected_values, 0, true);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Decimal, Table_Unique_Constraints) {
  const string COL1_NAME = "col1";
  const string COL2_NAME = COL_NAMES[PK_INDEX];
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, COL_TYPES[PK_INDEX]}
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
    "1",
    "2",
    "3",
    "4"  
  };

  vector<string> bbf_expected_values = INSERTED_VALUES;
  vector<string> pg_expected_values = INSERTED_VALUES;

  formatNumericExpected(bbf_expected_values, COL_SCALE[PK_INDEX], true);
  formatNumericExpected(pg_expected_values, COL_SCALE[PK_INDEX], true);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

  testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, bbf_expected_values, 0, true);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, INSERTED_VALUES.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Decimal, Comparison_Operators) {

  const string COMPARISON_DATATYPE = DATATYPE + "(6,5)";
  const string COL1_NAME = "col1";
  const string COL2_NAME = "col2";

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, COMPARISON_DATATYPE + " PRIMARY KEY"},
    {COL2_NAME, COMPARISON_DATATYPE}
  };

  const vector<string> INSERTED_PK = {
    "0.0000", // A < B
    "5.343", // A = B
    "9.9999" // A > B
  };

  const vector<string> INSERTED_DATA = {
    "1.000", // A < B
    "5.343", // A = B
    "9.89"   // A > B
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
    const float data_A = std::stof(INSERTED_PK[i]);
    const float data_B = std::stof(INSERTED_DATA[i]);
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
                          INSERTED_PK, INSERTED_DATA, BBF_OPERATIONS_QUERY, expected_results,
                          false, false);

  testComparisonOperators(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, PG_OPERATIONS_QUERY, expected_results,
                          false, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Decimal, Arithmetic_Operators) {

  const string COL1_DATATYPE = DATATYPE + "(1,0)";
  const string COL2_DATATYPE = DATATYPE + "(5,5)";
  const string COL1_NAME = "col1";
  const string COL2_NAME = "col2";

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, COL1_DATATYPE + " PRIMARY KEY"},
    {COL2_NAME, COL2_DATATYPE}
  };

  const vector <string> INSERTED_PK = {
    "8"
  };

  const vector <string> INSERTED_DATA = {
    "0.55555"
  };

  const vector <string> PG_OPERATIONS_QUERY = {
    COL1_NAME + "+" + COL2_NAME,
    COL1_NAME + "-" + COL2_NAME,
    COL1_NAME + "*" + COL2_NAME,
    COL1_NAME + "/" + COL2_NAME,
    "ABS(" + COL1_NAME + ")",
    "POWER(" + COL1_NAME + "," + COL2_NAME + ")",
    "||/ " + COL1_NAME,
    "LOG(" + COL1_NAME + ")"    
  };

  // initialization of expected_results
  const vector<vector<string>>PG_EXPECTED_RESULTS = {
    {
      "8.55555",
      "7.44445",
      "4.44440",
      "14.4001440014400144",
      "8",
      "3.1747654273961317",
      "2",
      "0.9030899869919436"
    }
  };
  
  string insert_string{}; 
  string comma{};
  
  // insert_string initialization
  for (int i = 0; i < INSERTED_PK.size(); ++i) {
    insert_string += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
    comma = ",";
  }

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insert_string,    
    INSERTED_PK.size());

  testArithmeticOperators(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME,        
    INSERTED_PK.size(), PG_OPERATIONS_QUERY, PG_EXPECTED_RESULTS);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}
