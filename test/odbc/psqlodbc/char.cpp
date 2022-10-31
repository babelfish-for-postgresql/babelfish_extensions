#include "conversion_functions_common.h"
#include "psqlodbc_tests_common.h"

const string BBF_TABLE_NAME = "master.dbo.char_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.char_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.char_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.char_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";

const string DATATYPE = "char";
const string DATATYPE_1 = DATATYPE + "(1)";
const string DATATYPE_20 = DATATYPE + "(20)";
const string DATATYPE_8000 = DATATYPE + "(8000)";

const vector<pair<string, string>> TABLE_COLUMNS_1 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_1}
};

const vector<pair<string, string>> TABLE_COLUMNS_20 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_20}
};

const vector<pair<string, string>> TABLE_COLUMNS_8000 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_8000}
};

const string STRING_1 = "a";
const string STRING_20 = "0123456789abcdefghij";
const string STRING_2704 = "nnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfddddd";
const string STRING_8000 = "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";

class PSQL_DataTypes_Char : public testing::Test {
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

TEST_F(PSQL_DataTypes_Char, Table_Creation) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1);

  const vector<int> BBF_LENGTH_EXPECTED = {10, 1};
  const vector<int> BBF_PRECISION_EXPECTED = {10, 1};
  const vector<int> BBF_SCALE_EXPECTED = {0, 0};
  const vector<string> BBF_NAME_EXPECTED = {"int", "char"};
  const vector<int> BBF_CASE_EXPECTED = {SQL_FALSE, SQL_FALSE};
  const vector<string> BBF_PREFIX_EXPECTED = {"", "\'"};
  const vector<string> BBF_SUFFIX_EXPECTED = {"", "\'"};

  testCommonCharColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
                                TABLE_COLUMNS_1.size(), COL1_NAME, 
                                BBF_LENGTH_EXPECTED, BBF_PRECISION_EXPECTED,
                                BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED,
                                BBF_CASE_EXPECTED, BBF_PREFIX_EXPECTED, BBF_SUFFIX_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED = {4, 1};
  const vector<int> PG_PRECISION_EXPECTED = {0, 0};
  const vector<int> PG_SCALE_EXPECTED = {0, 0};
  const vector<string> PG_NAME_EXPECTED = {"int4", "unknown"};
  const vector<int> PG_CASE_EXPECTED = {SQL_FALSE, SQL_FALSE};
  const vector<string> PG_PREFIX_EXPECTED = {"int4", "\'"};
  const vector<string> PG_SUFFIX_EXPECTED = {"int4", "\'"};

  testCommonCharColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
                                TABLE_COLUMNS_1.size(), COL1_NAME, 
                                PG_LENGTH_EXPECTED, PG_PRECISION_EXPECTED,
                                PG_SCALE_EXPECTED, PG_NAME_EXPECTED,
                                PG_CASE_EXPECTED, PG_PREFIX_EXPECTED, PG_SUFFIX_EXPECTED);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20);

  const vector<int> BBF_LENGTH_EXPECTED_20 = {10, 20};
  const vector<int> BBF_PRECISION_EXPECTED_20 = {10, 20};

  testCommonCharColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
                                TABLE_COLUMNS_20.size(), COL1_NAME, 
                                BBF_LENGTH_EXPECTED_20, BBF_PRECISION_EXPECTED_20,
                                BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED,
                                BBF_CASE_EXPECTED, BBF_PREFIX_EXPECTED, BBF_SUFFIX_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED_20 = {4, 20};
  const vector<int> PG_PRECISION_EXPECTED_20 = {0, 0};

  testCommonCharColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
                                TABLE_COLUMNS_20.size(), COL1_NAME, 
                                PG_LENGTH_EXPECTED_20, PG_PRECISION_EXPECTED_20,
                                PG_SCALE_EXPECTED, PG_NAME_EXPECTED,
                                PG_CASE_EXPECTED, PG_PREFIX_EXPECTED, PG_SUFFIX_EXPECTED);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_8000);

  const vector<int> BBF_LENGTH_EXPECTED_8000 = {10, 8000};
  const vector<int> BBF_PRECISION_EXPECTED_8000 = {10, 8000};

  testCommonCharColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
                                TABLE_COLUMNS_8000.size(), COL1_NAME, 
                                BBF_LENGTH_EXPECTED_8000, BBF_PRECISION_EXPECTED_8000,
                                BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED,
                                BBF_CASE_EXPECTED, BBF_PREFIX_EXPECTED, BBF_SUFFIX_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED_8000 = {4, 8000};
  const vector<int> PG_PRECISION_EXPECTED_8000 = {0, 0};

  testCommonCharColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
                                TABLE_COLUMNS_8000.size(), COL1_NAME, 
                                PG_LENGTH_EXPECTED_8000, PG_PRECISION_EXPECTED_8000,
                                PG_SCALE_EXPECTED, PG_NAME_EXPECTED,
                                PG_CASE_EXPECTED, PG_PREFIX_EXPECTED, PG_SUFFIX_EXPECTED);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> INVALID_COLUMNS {    
    {{"invalid1", DATATYPE + "(-1)"}},   // Below min
    {{"invalid2", DATATYPE + "(0)"}},    // Zero
    // {{"invalid3", DATATYPE + "(8001)"}}, // Over max, *PG can create, BBF cannot
    {{"invalid4", DATATYPE + "(NULL)"}}  // NULL
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(ServerType::MSSQL, BBF_TABLE_NAME, INVALID_COLUMNS);
  testTableCreationFailure(ServerType::PSQL, PG_TABLE_NAME, INVALID_COLUMNS);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Insertion_Success) {
  vector<string> inserted_values_1 = {
    "NULL",     // Null
    "",         // Empty
    STRING_1    // Max
  };
  vector<string> expected_values_1 = getExpectedResults_Char(inserted_values_1, 1);
  
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values_1, expected_values_1);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values_1, false, inserted_values_1.size());
  
  inserted_values_1 = duplicateElements(inserted_values_1);
  expected_values_1 = duplicateElements(expected_values_1);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values_1, expected_values_1);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values_1, expected_values_1);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  vector<string> inserted_values_20 = {
    "NULL",     // Null
    "",         // Empty
    "A",        // Rand
    STRING_20   // Max
  };
  vector<string> expected_values_20 = getExpectedResults_Char(inserted_values_20, 20);
  
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values_20, expected_values_20);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values_20, false, inserted_values_20.size());
  
  inserted_values_20 = duplicateElements(inserted_values_20);
  expected_values_20 = duplicateElements(expected_values_20);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values_20, expected_values_20);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values_20, expected_values_20);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  vector<string> inserted_values_8000 = {
    "NULL",       // Null
    "",           // Empty
    "A",        // Rand
    STRING_8000   // Max
  };
  vector<string> expected_values_8000 = getExpectedResults_Char(inserted_values_8000, 8000);
  
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_8000);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values_8000, expected_values_8000);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values_8000, false, inserted_values_8000.size());
  
  inserted_values_8000 = duplicateElements(inserted_values_8000);
  expected_values_8000 = duplicateElements(expected_values_8000);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values_8000, expected_values_8000);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values_8000, expected_values_8000);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Insertion_Fail) {
  const vector<string> INVALID_INSERTED_VALUES_1 = {STRING_1 + "1"};
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES_1, true);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES_1, true);

  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);

  const vector<string> INVALID_INSERTED_VALUES_20 = {STRING_20 + "1"};
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES_20, true);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES_20, true);

  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);

  const vector<string> INVALID_INSERTED_VALUES_8000 = {STRING_8000 + "1"};
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_8000);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES_8000, true);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES_8000, true);

  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Update_Success) {
  const vector<string> INSERTED_VALUES_1 = {
    "A"
  };
  const vector<string> EXPECTED_VALUES_1 = getExpectedResults_Char(INSERTED_VALUES_1, 1);

  const vector <string> DATA_UPDATED_VALUES_1 = {
    "NULL",
    STRING_1,
    "A"   // Rand
  };
  const vector<string> EXPECTED_UPDATED_VALUES_1 = getExpectedResults_Char(DATA_UPDATED_VALUES_1, 1);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_1, EXPECTED_UPDATED_VALUES_1);
  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_1, EXPECTED_UPDATED_VALUES_1);

  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "A"
  };
  const vector<string> EXPECTED_VALUES_20 = getExpectedResults_Char(INSERTED_VALUES_20, 20);

  const vector <string> DATA_UPDATED_VALUES_20 = {
    "NULL",
    STRING_20,
    "A"   // Rand
  };
  const vector<string> EXPECTED_UPDATED_VALUES_20 = getExpectedResults_Char(DATA_UPDATED_VALUES_20, 20);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_20, EXPECTED_UPDATED_VALUES_20);
  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_20, EXPECTED_UPDATED_VALUES_20);

  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  const vector<string> INSERTED_VALUES_8000 = {
    "A"
  };
  const vector<string> EXPECTED_VALUES_8000 = getExpectedResults_Char(INSERTED_VALUES_8000, 8000);

  const vector <string> DATA_UPDATED_VALUES_8000 = {
    "NULL",
    STRING_8000,
    "A"   // Rand
  };
  const vector<string> EXPECTED_UPDATED_VALUES_8000 = getExpectedResults_Char(DATA_UPDATED_VALUES_8000, 8000);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_8000);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_8000, EXPECTED_VALUES_8000);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_8000, EXPECTED_UPDATED_VALUES_8000);
  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_8000, EXPECTED_UPDATED_VALUES_8000);

  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_8000, EXPECTED_VALUES_8000);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Update_Fail) {
  const vector<string> INSERTED_VALUES_1 = {STRING_1};
  const vector<string> UPDATED_VALUES_1 = {STRING_1 + "1"};

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);

  testUpdateFail(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_1, UPDATED_VALUES_1);
  testUpdateFail(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_1, UPDATED_VALUES_1);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {STRING_20};
  const vector<string> UPDATED_VALUES_20 = {STRING_20 + "1"};

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);

  testUpdateFail(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_20, UPDATED_VALUES_20);
  testUpdateFail(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_20, UPDATED_VALUES_20);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  const vector<string> INSERTED_VALUES_8000 = {STRING_8000};
  const vector<string> UPDATED_VALUES_8000 = {STRING_8000 + "1"};

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_8000);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_8000, INSERTED_VALUES_8000);

  testUpdateFail(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_8000, UPDATED_VALUES_8000);
  testUpdateFail(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_8000, UPDATED_VALUES_8000);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, View_Creation) {
  const string BBF_VIEW_QUERY = "SELECT * FROM " + BBF_TABLE_NAME;
  const string PG_VIEW_QUERY = "SELECT * FROM " + PG_TABLE_NAME;

  const vector<string> INSERTED_VALUES_1 = {
    "NULL",     // Null
    "",         // Empty
    STRING_1    // Max
  };
  const vector<string> EXPECTED_VALUES_1 = getExpectedResults_Char(INSERTED_VALUES_1, 1);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);

  createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

  verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);
  verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);

  dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
  dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "NULL",     // Null
    "",         // Empty
    STRING_20    // Max
  };
  const vector<string> EXPECTED_VALUES_20 = getExpectedResults_Char(INSERTED_VALUES_20, 20);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

  verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);
  verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
  dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);

  const vector<string> INSERTED_VALUES_8000 = {
    "NULL",     // Null
    "",         // Empty
    STRING_8000    // Max
  };
  const vector<string> EXPECTED_VALUES_8000 = getExpectedResults_Char(INSERTED_VALUES_8000, 8000);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_8000);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_8000, EXPECTED_VALUES_8000);

  createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

  verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, INSERTED_VALUES_8000, EXPECTED_VALUES_8000);
  verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, INSERTED_VALUES_8000, EXPECTED_VALUES_8000);

  dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
  dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Table_Single_Primary_Keys) {
  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_1}
  };

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_20}
  };

  // Maximum allowed for PG connection is 2704
  const vector<pair<string, string>> TABLE_COLUMNS_2704 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(2704)"}
  };

  const vector<string> INSERTED_VALUES_1 = {
    "",         // Empty
    STRING_1    // Max
  };
  const vector<string> EXPECTED_VALUES_1 = getExpectedResults_Char(INSERTED_VALUES_1, 1);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",          // Empty
    STRING_20    // Max
  };
  const vector<string> EXPECTED_VALUES_20 = getExpectedResults_Char(INSERTED_VALUES_20, 20);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  
  const vector<string> INSERTED_VALUES_2704 = {
    "",            // Empty
    STRING_2704    // Max
  };
  const vector<string> EXPECTED_VALUES_2704 = getExpectedResults_Char(INSERTED_VALUES_2704, 2704);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, EXPECTED_VALUES_2704);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Table_Composite_Primary_Keys) {
  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> PK_COLUMNS = {
    COL1_NAME, 
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_1}
  };

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_20}
  };

  // Maximum allowed for PG connection is 2704
  const vector<pair<string, string>> TABLE_COLUMNS_2704 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(2704)"}
  };

  const vector<string> INSERTED_VALUES_1 = {
    "",         // Empty
    STRING_1    // Max
  };
  const vector<string> EXPECTED_VALUES_1 = getExpectedResults_Char(INSERTED_VALUES_1, 1);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, 0, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, 0, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",          // Empty
    STRING_20    // Max
  };
  const vector<string> EXPECTED_VALUES_20 = getExpectedResults_Char(INSERTED_VALUES_20, 20);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, 0, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, 0, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  
  const vector<string> INSERTED_VALUES_2704 = {
    "",            // Empty
    STRING_2704    // Max
  };
  const vector<string> EXPECTED_VALUES_2704 = getExpectedResults_Char(INSERTED_VALUES_2704, 2704);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);

  testPrimaryKeys(ServerType::MSSQL, BBF_SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, TABLE_NAME, PK_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, EXPECTED_VALUES_2704);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, 0, false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, 0, false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Table_Unique_Constraint) {
  const string TABLE_NAME = PG_TABLE_NAME.substr(PG_TABLE_NAME.find('.') + 1, PG_TABLE_NAME.length());  
  const string SCHEMA_NAME = PG_TABLE_NAME.substr(0, PG_TABLE_NAME.find('.'));
  const string BBF_SCHEMA_NAME = SCHEMA_NAME.substr(SCHEMA_NAME.find('_') + 1, SCHEMA_NAME.length());

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

  const vector<pair<string, string>> TABLE_COLUMNS_1 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_1}
  };

  const vector<pair<string, string>> TABLE_COLUMNS_20 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_20}
  };

  // Maximum allowed for PG connection is 2704
  const vector<pair<string, string>> TABLE_COLUMNS_2704 = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE + "(2704)"}
  };

  const vector<string> INSERTED_VALUES_1 = {
    "",         // Empty
    STRING_1    // Max
  };
  const vector<string> EXPECTED_VALUES_1 = getExpectedResults_Char(INSERTED_VALUES_1, 1);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);

  testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, EXPECTED_VALUES_1);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",          // Empty
    STRING_20    // Max
  };
  const vector<string> EXPECTED_VALUES_20 = getExpectedResults_Char(INSERTED_VALUES_20, 20);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);

  testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, EXPECTED_VALUES_20);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  
  const vector<string> INSERTED_VALUES_2704 = {
    "",            // Empty
    STRING_2704    // Max
  };
  const vector<string> EXPECTED_VALUES_2704 = getExpectedResults_Char(INSERTED_VALUES_2704, 2704);

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);

  testUniqueConstraint(ServerType::MSSQL, TABLE_NAME, UNIQUE_COLUMNS);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME, UNIQUE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, EXPECTED_VALUES_2704);

  testInsertionFailure(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);
  testInsertionFailure(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_20 + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_20}
  };

  const vector<string> INSERTED_PK = {
    "ZZZZZ",      // A > B
    "9999",       // A < B
    "asdf1234"    // A = B
  };

  const vector<string> INSERTED_DATA = {
    "AAAAA",      // A > B
    "0000",       // A < B
    "asdf1234"    // A = B
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();
  
  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
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
    const char *data_A = INSERTED_PK[i].data();
    const char *data_B = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(data_A, data_B) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) >= 0 ? '1' : '0');
  }

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insertString, NUM_OF_DATA);

  testComparisonOperators(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, BBF_OPERATIONS_QUERY, expected_results,
                          false, true);

  testComparisonOperators(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, PG_OPERATIONS_QUERY, expected_results,
                          false, true);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Char, String_Functions) {
  const vector<string> INSERTED_DATA = {
    "aBcDeFg",
    "   test",
    STRING_20
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
    "LOWER(" + COL2_NAME + ")",
    "UPPER(" + COL2_NAME + ")",
    "TRIM(" + COL2_NAME + ")",
    "CONCAT(" + COL2_NAME + ",\'xyz\')",
  };

  // initialization of EXPECTED_RESULTS
  vector<vector<string>> EXPECTED_RESULTS = {
    {"abcdefg             ", "   test             ", "0123456789abcdefghij"},
    {"ABCDEFG             ", "   TEST             ", "0123456789ABCDEFGHIJ"},
    {"aBcDeFg", "test", "0123456789abcdefghij"},
    {"aBcDeFg             xyz", "   test             xyz", "0123456789abcdefghijxyz"}
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS_20);

  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, insertString, NUM_OF_DATA);

  testStringFunctions(ServerType::MSSQL, BBF_TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, INSERTED_DATA.size(), COL1_NAME);
  testStringFunctions(ServerType::PSQL, PG_TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, INSERTED_DATA.size(), COL1_NAME);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}
