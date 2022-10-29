#include "psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.nvarchar_table_odbc_test";
const string VIEW_NAME = "master_dbo.nvarchar_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";

const string DATATYPE = "sys.nvarchar";
const string DATATYPE_1 = DATATYPE + "(1)";
const string DATATYPE_20 = DATATYPE + "(20)";
const string DATATYPE_4000 = DATATYPE + "(4000)";

vector<pair<string, string>> TABLE_COLUMNS_1 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_1}
};

vector<pair<string, string>> TABLE_COLUMNS_20 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_20}
};

vector<pair<string, string>> TABLE_COLUMNS_4000 = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_4000}
};

const string STRING_1 = "a";
const string STRING_20 = "0123456789abcdefghij";
const string STRING_2704 = "nnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfdnnd191209bnfe1b8h1389hcbsiac18he12he129basdbdiub912be912b9eb129ueb9asbdiuasbd198wb91wbdsabduibq9uhdasuidbewbdicciudsbuib29r9823h9vbs9df29chdufhuih23hr@#YGEGV#%TW$hduccW%$EHDYTfgs3489bdifbviubsfduvbsiudfbu3fbuibvisdfbiuvbdfsivbfdisubviufdsbvbdfiufnvdjkvbdkfbvkjdfbvksDTHEVEV%TTDYE%$VT$TERCW%$TERGFSGfddddd";
const string STRING_4000 = "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";

vector<string> getExpectedResults_nvarChar(const vector<string> &input, size_t table_size) {
  vector<string> ret = {};

  for (int i = 0; i < input.size(); i++) {
    ret.push_back(padString(input[i], table_size));
  }

  return ret;
}

class PSQL_DataTypes_nvarChar : public testing::Test {
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

TEST_F(PSQL_DataTypes_nvarChar, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 1};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<int> LENGTH_EXPECTED_20 = {4, 20};
  const vector<int> PRECISION_EXPECTED_20 = {0, 0};
  const vector<int> SCALE_EXPECTED_20 = {0, 0};
  const vector<string> NAME_EXPECTED_20 = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20.size(), COL1_NAME, LENGTH_EXPECTED_20, 
    PRECISION_EXPECTED_20, SCALE_EXPECTED_20, NAME_EXPECTED_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<int> LENGTH_EXPECTED_4000 = {4, 4000};
  const vector<int> PRECISION_EXPECTED_4000 = {0, 0};
  const vector<int> SCALE_EXPECTED_4000 = {0, 0};
  const vector<string> NAME_EXPECTED_4000 = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000.size(), COL1_NAME, LENGTH_EXPECTED_4000, 
    PRECISION_EXPECTED_4000, SCALE_EXPECTED_4000, NAME_EXPECTED_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Create_Fail) {
  const vector<vector<pair<string, string>>> INVALID_COLUMNS {
    {{"invalid1", DATATYPE + "(-1)"}},
    {{"invalid1", DATATYPE + "(0)"}},
    {{"invalid1", DATATYPE + "(NULL)"}}
  };
  
  testTableCreationFailure(ServerType::PSQL, TABLE_NAME, INVALID_COLUMNS);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Insertion_Success) {
  const vector<string> INSERTERD_VALUES_1 = {
    "NULL", 
    "",
    STRING_1
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTERD_VALUES_1, INSERTERD_VALUES_1);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTERD_VALUES_20 = {
    "NULL", 
    "",
    STRING_20
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTERD_VALUES_20, INSERTERD_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTERD_VALUES_4000 = {
    "NULL", 
    "",
    STRING_4000
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTERD_VALUES_4000, INSERTERD_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Insertion_Failure) {
  const vector<string> INSERTED_VALUE_1 = {
    STRING_1 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUE_1, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUE_20 = {
    STRING_20 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUE_20, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUE_4000 = {
    STRING_4000 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUE_4000, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Update_Success) {
  const vector<string> INSERTED_VALUES_1 = {
    "A"
  };

  const vector <string> DATA_UPDATED_VALUES_1 = {
    "NULL",
    STRING_1,
    "A"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_1, DATA_UPDATED_VALUES_1);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "A"
  };

  const vector <string> DATA_UPDATED_VALUES_20 = {
    "NULL",
    STRING_20,
    "A"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_20, DATA_UPDATED_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "A"
  };

  const vector <string> DATA_UPDATED_VALUES_4000 = {
    "NULL",
    STRING_4000,
    "A"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, DATA_UPDATED_VALUES_4000, DATA_UPDATED_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Update_Fail) {
  const vector<string> INSERTED_VALUES_1 = {
    "A"
  };

  const vector<string> UPDATED_VALUES_1 = {
    STRING_1 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_1, UPDATED_VALUES_1);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "A"
  };

  const vector<string> UPDATED_VALUES_20 = {
    STRING_20 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_20, UPDATED_VALUES_20);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "A"
  };

  const vector<string> UPDATED_VALUES_4000 = {
    STRING_4000 + "1"
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);
  testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_VALUES_4000, UPDATED_VALUES_4000);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, View_creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  const vector<string> INSERTED_VALUES_1 = {
    "NULL", 
    "",
    STRING_1
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "NULL", 
    "",
    STRING_20
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_4000 = {
    "NULL", 
    "",
    STRING_4000
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_4000);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES_4000, INSERTED_VALUES_4000);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Single_Primary_Keys) {
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

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

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",         // Empty
    STRING_20   // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_2704 = {
    "",         // Empty
    STRING_2704 // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, INSERTED_VALUES_2704);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Composite_Primary_Keys){
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

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

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",         // Empty
    STRING_20   // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_2704 = {
    "",         // Empty
    STRING_2704 // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, INSERTED_VALUES_2704);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Table_Unique_Constraint) {
  const vector<string> UNIQUE_COLUMNS = {COL2_NAME};
  string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);
  const string tableName = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

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

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_1, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, INSERTED_VALUES_1);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_1, false, INSERTED_VALUES_1.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_20 = {
    "",         // Empty
    STRING_20    // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, INSERTED_VALUES_20);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_20, false, INSERTED_VALUES_20.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);

  const vector<string> INSERTED_VALUES_2704 = {
    "",         // Empty
    STRING_2704 // Max
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_2704, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, tableName, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, INSERTED_VALUES_2704);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES_2704, false, INSERTED_VALUES_2704.size(), false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, Comparison_Operators) {
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
    const char *data_A = INSERTED_PK[i].data();
    const char *data_B = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(data_A, data_B) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(data_A, data_B) >= 0 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);

  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);

  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, 
                          INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results,
                          false, true);

  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_nvarChar, String_Functions) {
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
    {"abcdefg", "   test", "0123456789abcdefghij"},
    {"ABCDEFG", "   TEST", "0123456789ABCDEFGHIJ"},
    {"aBcDeFg", "test", "0123456789abcdefghij"},
    {"aBcDeFgxyz", "   testxyz", "0123456789abcdefghijxyz"}
  };

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS_20);

  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);

  testStringFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, INSERTED_DATA.size(), COL1_NAME);

  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
