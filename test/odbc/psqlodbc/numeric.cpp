#include "psqlodbc_tests_common.h"

const string PG_TABLE_NAME = "master_dbo.numeric_table_odbc_test";
const string BBF_TABLE_NAME = "master.dbo.numeric_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.numeric_view_odbc_test";
const string BBF_VIEW_NAME = "numeric_view_odbc_test";
const string DATATYPE = "numeric";

const vector<string> COL_NAMES = {"pk_1_0", "num_5_5", "num_38_38", "num_38_0", "num_4_2"};
const vector<int> COL_PRECISION = {1, 5, 38, 38, 4};
const vector<int> COL_SCALE = {0, 5, 38, 0, 2};

const vector<int> PG_LENGTH_EXPECTED = {3, 7, 40, 40, 6}; 
const vector<int> BBF_LENGTH_EXPECTED = {1, 5, 38, 38, 4}; 

const vector<string> COL_TYPES = {
  DATATYPE + "(" + std::to_string(COL_PRECISION[0]) + "," + std::to_string(COL_SCALE[0]) +  ")",
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

const string MAX_NUM_5_5 = "0.99999";
const string MAX_NUM_38_38 = "0.99999999999999999999999999999999999999";
const string MAX_NUM_38_0 = "99999999999999999999999999999999999999";
const string MAX_NUM_4_2 = "99.99";


class PSQL_DataTypes_Numeric : public testing::Test {
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

    // OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    // bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", BBF_VIEW_NAME));
    // bbf_test_setup.CloseStmt();
    // bbf_test_setup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
    
    // OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    // pg_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", PG_VIEW_NAME));
    // pg_test_setup.CloseStmt();
    // pg_test_setup.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }
};

// long long int StringToBigInt(const string &value) {
//   return strtoll(value.c_str(), NULL, 10);
// }

// vector<long long int> getExpectedBigIntResults(vector<string> data) {
//   vector<long long int> expectedResults{};

//   for (int i = 0; i < data.size(); i++) {
//     expectedResults.push_back(StringToBigInt(data[i]));
//   }

//   return expectedResults;
// }
TEST_F(PSQL_DataTypes_Numeric, Table_Creation) {
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

TEST_F(PSQL_DataTypes_Numeric, Table_Creation_Fail) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);
  vector<string> name_expected;

  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE + "(0,0)"}}, // must have precision of 1 or greater
    {{"invalid2", DATATYPE + "(10,11)"}}, // scale cannot be larger than precision
    {{"invalid3", DATATYPE + "(10, -1)"}} // precision must be 0 or greater
  };

  testTableCreationFailure(ServerType::PSQL, PG_TABLE_NAME, invalid_columns);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  testTableCreationFailure(ServerType::MSSQL, PG_TABLE_NAME, invalid_columns);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

// Returns a vector string of all elements in column "col" of a 2d string vector
vector<string> GetVectorBasedOnColumn(const vector<vector<string>> &vec, const int &col) {
  vector<string> col_vector;

  for (int i = 0; i < vec.size(); i++) {
    col_vector.push_back(vec[i][col]);
  }
  return col_vector;
}

string FormatNumericWithScale(string decimal, const int &scale, const bool &is_bbf) {
  size_t dec_pos = decimal.find('.');

  if (dec_pos == std::string::npos) {
    if (scale == 0) // if no decimal sign and scale is 0, no need to append
      return decimal;
    dec_pos = decimal.size();
    decimal += ".";
  }

  // add extra 0s
  int zeros_needed = scale - (decimal.size() - dec_pos - 1);
  for (int i = 0; i < zeros_needed; i++) {
    decimal += "0";
  }

  if (is_bbf){
    dec_pos = decimal.find('.');

    if ((decimal[dec_pos - 1] == '0' && (dec_pos - 1) == 0) || (decimal[0] == '-' and decimal[1] == '0')){
      decimal.erase(dec_pos - 1, 1);
    }
  }
  return decimal;
}

void FormatNumericExpected(vector<string> &vec, const int &scale, const bool &is_bbf) {
  for (int i = 0; i < vec.size(); i++) {
    vec[i] = FormatNumericWithScale(vec[i], scale, is_bbf);
  }
}

TEST_F(PSQL_DataTypes_Numeric, Insertion_Success) {
  const vector<vector<string>> LIST_OF_INSERTED_VALUES = {
    {"0", "0", "0", "0"}, // smallest numbers
    {MAX_NUM_5_5, MAX_NUM_38_38, MAX_NUM_38_0, MAX_NUM_4_2}, // max values
    {"-0.694", "0.4347509234", "-8532", "42.8"}, // random regular values
    {"NULL", "NULL", "NULL", "NULL"} // NULL values
  };
  
  for (int i = 0; i < LIST_OF_INSERTED_VALUES.size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i+1]
    };

    vector<string> insert_values = GetVectorBasedOnColumn(LIST_OF_INSERTED_VALUES, i);
    vector<string> bbf_expected_values = insert_values;
    vector<string> pg_expected_values = insert_values;

    FormatNumericExpected(bbf_expected_values, COL_SCALE[i+1], true);
    FormatNumericExpected(pg_expected_values, COL_SCALE[i+1], false);
    
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);
    insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insert_values, true);
    insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, insert_values, true, bbf_expected_values.size());

    insert_values = duplicateElements(insert_values);
    pg_expected_values = duplicateElements(pg_expected_values);
    bbf_expected_values = duplicateElements(bbf_expected_values);

    verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL_NAMES[PK_INDEX], insert_values, pg_expected_values);
    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

TEST_F(PSQL_DataTypes_Numeric, Insertion_Failure) {
  const vector<string> LIST_OF_FAIL_INSERTED_VALUES = {
    MAX_NUM_5_5 + "9", // first col exceeds by 1 digit
    MAX_NUM_38_38 + "9", // second col exceeds by 1 digit
    MAX_NUM_38_0 + ".5", // third col exceeds by 1 digit (extra decimal)
    "9" + MAX_NUM_4_2 // fourth col exceeds by adding a digit in the front
  };
  
  for (int i = 0; i < LIST_OF_FAIL_INSERTED_VALUES.size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i+1]
    };
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);

    testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL_NAMES[PK_INDEX], 
      {LIST_OF_FAIL_INSERTED_VALUES[i]}, true, 0, true);

    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

TEST_F(PSQL_DataTypes_Numeric, Update_Success) {
  const vector<vector<string>> LIST_OF_INSERTED_VALUES = {
    {"0.1", "0.2", "3", "4.4"}, // regular values for insertion (but will update to the same values during the test)
    {"0", "0", "0", "0" }, // update to smallest numbers
    {MAX_NUM_5_5, MAX_NUM_38_38, MAX_NUM_38_0, MAX_NUM_4_2}, // update to max values
    {"-0.694", "0.4347509234", "-8532", "42.8"}, // update to random regular values
    {"NULL", "NULL", "NULL", "NULL"} // update to NULL values
  };
  const int INSERT_INDEX = 0;

  for (int i = 0; i < LIST_OF_INSERTED_VALUES[INSERT_INDEX].size(); i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i+1]
    };

    vector<string> insert_values = {LIST_OF_INSERTED_VALUES[INSERT_INDEX][i]};
    vector<string> updated_values = GetVectorBasedOnColumn(LIST_OF_INSERTED_VALUES, i);

    vector<string> bbf_expected_values = updated_values;
    vector<string> pg_expected_values = updated_values;

    FormatNumericExpected(bbf_expected_values, COL_SCALE[i+1], true);
    FormatNumericExpected(pg_expected_values, COL_SCALE[i+1], false);
    
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

TEST_F(PSQL_DataTypes_Numeric, Update_Fail) {
  const vector<vector<string>> LIST_OF_INSERTED_VALUES = {
    {"0.1", "0.2", "3", "4.4"}, // regular values for insertion
    {MAX_NUM_5_5 + "9", MAX_NUM_38_38 + "9", MAX_NUM_38_0 + ".5", "9" + MAX_NUM_4_2}, // failed updates
  };
  const int INSERT_INDEX = 0;

  for (int i = 0; i < 1; i++) {
    vector<pair<string, string>> table_cols_for_insert = {
      TABLE_COLUMNS[PK_INDEX], 
      TABLE_COLUMNS[i+1]
    };

    vector<string> insert_values = {LIST_OF_INSERTED_VALUES[INSERT_INDEX][i]};
    vector<string> updated_values = GetVectorBasedOnColumn(LIST_OF_INSERTED_VALUES, i);
    updated_values.erase(updated_values.begin());

    vector<string> bbf_expected_values = insert_values;
    vector<string> pg_expected_values = insert_values;

    FormatNumericExpected(bbf_expected_values, COL_SCALE[i+1], true);
    FormatNumericExpected(pg_expected_values, COL_SCALE[i+1], false);
    
    createTable(ServerType::MSSQL, BBF_TABLE_NAME, table_cols_for_insert);
    insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insert_values, true);

    testUpdateFail(ServerType::PSQL, PG_TABLE_NAME, COL_NAMES[PK_INDEX], 
      table_cols_for_insert[table_cols_for_insert.size() - 1].first, updated_values, pg_expected_values);
    // testUpdateFail(ServerType::MSSQL, BBF_TABLE_NAME, COL_NAMES[PK_INDEX],
    //   table_cols_for_insert[table_cols_for_insert.size() - 1].first, updated_values, bbf_expected_values);

    dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
    dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  }
}

// TEST_F(PSQL_DataTypes_Numeric, View_creation) {
//   const vector<string> INSERTED_VALUES = {
//     "NULL",
//     "",
//     "A",
//     "123",
//     // Outside normal printable range of 32-126
//     "\\\\01f",  // 31
//     "\\\\07f"   // 127
//   };
//   const int NUM_OF_DATA = INSERTED_VALUES.size();

//   const vector<string> EXPECTED_VALUES = getExpectedResults_Bytea(INSERTED_VALUES);

//   const string BBF_VIEW_QUERY = "SELECT * FROM " + BBF_TABLE_NAME;
//   const string PG_VIEW_QUERY = "SELECT * FROM " + PG_TABLE_NAME;

//   createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

//   testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

//   createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

//   verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, true);
//   verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, true);

//   dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
//   dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
//   dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
//   dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Numeric, Table_Single_Primary_Keys) {
//   const vector<pair<string, string>> TABLE_COLUMNS = {
//     {COL1_NAME, "INT"},
//     {COL2_NAME, DATATYPE_NAME}
//   };

//   const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
//   const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
//   const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

//   const vector<string> PK_COLUMNS = {
//     COL2_NAME
//   };

//   string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

//   const vector<string> INSERTED_VALUES = {
//     "",
//     "A",
//     "123",
//     // Outside normal printable range of 32-126
//     "\\\\01f",  // 31
//     "\\\\07f"   // 127
//   };
//   const int NUM_OF_DATA = INSERTED_VALUES.size();

//   const vector<string> EXPECTED_VALUES = getExpectedResults_Bytea(INSERTED_VALUES);

//   createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

//   testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
//   testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

//   testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, true);

//   testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, NUM_OF_DATA, false);
//   testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, NUM_OF_DATA, false);

//   dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
//   dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Numeric, Table_Composite_Keys) {
//   const vector<pair<string, string>> TABLE_COLUMNS = {
//     {COL1_NAME, "INT"},
//     {COL2_NAME, DATATYPE_NAME}
//   };

//   const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
//   const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
//   const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

//   const vector<string> PK_COLUMNS = {
//     COL1_NAME,
//     COL2_NAME
//   };

//   string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

//   const vector<string> INSERTED_VALUES = {
//     "",
//     "A",
//     "123",
//     // Outside normal printable range of 32-126
//     "\\\\01f",  // 31
//     "\\\\07f"   // 127
//   };
//   const int NUM_OF_DATA = INSERTED_VALUES.size();

//   const vector<string> EXPECTED_VALUES = getExpectedResults_Bytea(INSERTED_VALUES);

//   createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

//   testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
//   testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

//   testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, true);

//   testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);
//   testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, 0, false);

//   dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
//   dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Numeric, Table_Unique_Constraint) {
//   const vector<pair<string, string>> TABLE_COLUMNS = {
//     {COL1_NAME, "INT"},
//     {COL2_NAME, DATATYPE_NAME}
//   };

//   const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
//   const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
//   const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

//   const vector<string> UNIQUE_COLUMNS = {
//     COL2_NAME
//   };

//   string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

//   const vector<string> INSERTED_VALUES = {
//     "",
//     "A",
//     "123",
//     // Outside normal printable range of 32-126
//     "\\\\01f",  // 31
//     "\\\\07f"   // 127
//   };
//   const int NUM_OF_DATA = INSERTED_VALUES.size();

//   const vector<string> EXPECTED_VALUES = getExpectedResults_Bytea(INSERTED_VALUES);

//   createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS, tableConstraints);

//   testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
//   testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

//   testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, true);

//   testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, NUM_OF_DATA, false);
//   testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES, false, NUM_OF_DATA, false);

//   dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
//   dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Numeric, Comparison_Operators) {
//   const vector<pair<string, string>> TABLE_COLUMNS = {
//     {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
//     {COL2_NAME, DATATYPE_NAME}
//   };

//   const vector<string> INSERTED_PK = {
//     "A",
//     "123",
//     "smaller"
//   };

//   const vector<string> INSERTED_DATA = {
//     "B",
//     "123",
//     "LARGER"
//   };
//   const int NUM_OF_DATA = INSERTED_DATA.size();

//   // insertString initialization
//   string insertString{};
//   string comma{};
//   for (int i = 0; i < NUM_OF_DATA; i++) {
//     insertString += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
//     comma = ",";
//   }

//   const vector<string> BBF_OPERATIONS_QUERY = {
//     "IIF(" + COL1_NAME + " = " + COL2_NAME + ", '1', '0')",
//     "IIF(" + COL1_NAME + " <> " + COL2_NAME + ", '1', '0')",
//     "IIF(" + COL1_NAME + " < " + COL2_NAME + ", '1', '0')",
//     "IIF(" + COL1_NAME + " <= " + COL2_NAME + ", '1', '0')",
//     "IIF(" + COL1_NAME + " > " + COL2_NAME + ", '1', '0')",
//     "IIF(" + COL1_NAME + " >= " + COL2_NAME + ", '1', '0')"
//   };

//   const vector<string> PG_OPERATIONS_QUERY = {
//     COL1_NAME + "=" + COL2_NAME,
//     COL1_NAME + "<>" + COL2_NAME,
//     COL1_NAME + "<" + COL2_NAME,
//     COL1_NAME + "<=" + COL2_NAME,
//     COL1_NAME + ">" + COL2_NAME,
//     COL1_NAME + ">=" + COL2_NAME
//   };

//   // initialization of expected_results
//   vector<vector<char>> expected_results = {};

//   for (int i = 0; i < NUM_OF_DATA; i++) {
//     expected_results.push_back({});
//     const char *data_A = INSERTED_PK[i].data();
//     const char *data_B = INSERTED_DATA[i].data();
//     expected_results[i].push_back(strcmp(data_A, data_B) == 0 ? '1' : '0');
//     expected_results[i].push_back(strcmp(data_A, data_B) != 0 ? '1' : '0');
//     expected_results[i].push_back(strcmp(data_A, data_B) < 0 ? '1' : '0');
//     expected_results[i].push_back(strcmp(data_A, data_B) <= 0 ? '1' : '0');
//     expected_results[i].push_back(strcmp(data_A, data_B) > 0 ? '1' : '0');
//     expected_results[i].push_back(strcmp(data_A, data_B) >= 0 ? '1' : '0');
//   }

//   createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

//   insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insertString, NUM_OF_DATA);

//   testComparisonOperators(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, 
//                           INSERTED_PK, INSERTED_DATA, BBF_OPERATIONS_QUERY, expected_results,
//                           false, true);

//   testComparisonOperators(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, 
//                           INSERTED_PK, INSERTED_DATA, PG_OPERATIONS_QUERY, expected_results,
//                           false, true);

//   dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
//   dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
// }
