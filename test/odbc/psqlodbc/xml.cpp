#include "psqlodbc_tests_common.h"
#include "../src/query_generator.h"

const string BBF_TABLE_NAME = "master.dbo.xml_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.xml_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.xml_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.xml_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "xml";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

const string SIMPLE_XML = "<root>\
<book>-148708948</book>\
<leaf>simple</leaf>\
<remain>shake</remain>\
<football>nest</football>\
<blanket>1275892738</blanket>\
<try>-249153758.16992378</try>\
</root>";

const string NORMAL_XML = "<root>\
<that>hot</that>\
<anyone>1386369263.1890697</anyone>\
<finest>believed</finest>\
<song>\
<stems>\
<headed>1563641070.153514</headed>\
<bring>-1175941901.956747</bring>\
<stand>-494359546.04893684</stand>\
<pole>774686962</pole>\
<outer>production</outer>\
<why>applied</why>\
</stems>\
<breeze>1269756220</breeze>\
<cookies>544666062</cookies>\
<yesterday>grade</yesterday>\
<power>-663154896.7426605</power>\
<topic>stomach</topic>\
</song>\
<fact>-1834471409</fact>\
<repeat>-1980145795</repeat>\
</root>";

class PSQL_DataTypes_Xml : public testing::Test {
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

TEST_F(PSQL_DataTypes_Xml, Table_Creation) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  const vector<int> BBF_LENGTH_EXPECTED = {10, 0}; // TODO is this right?
  const vector<int> BBF_PRECISION_EXPECTED = {10, 0};
  const vector<int> BBF_SCALE_EXPECTED = {0, 0};
  const vector<string> BBF_NAME_EXPECTED = {"int", "xml"};

  testCommonColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
      TABLE_COLUMNS.size(), COL1_NAME, 
      BBF_LENGTH_EXPECTED, BBF_PRECISION_EXPECTED, 
      BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED = {4, 255}; // TODO is this right? Doesn't seem right...
  const vector<int> PG_PRECISION_EXPECTED = {0, 0};
  const vector<int> PG_SCALE_EXPECTED = {0, 0};
  const vector<string> PG_NAME_EXPECTED = {"int4", "xml"};

  testCommonColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
    TABLE_COLUMNS.size(), COL1_NAME, 
    PG_LENGTH_EXPECTED, PG_PRECISION_EXPECTED, 
    PG_SCALE_EXPECTED, PG_NAME_EXPECTED);

  // Clean-up
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Xml, Insertion_Success) {
  vector<string> inserted_values = {
    NORMAL_XML
  };
  const int number_of_entries = inserted_values.size();

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values, false, number_of_entries);

  inserted_values = duplicateElements(inserted_values);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Xml, Data_Length) {
  vector<string> inserted_values = {
    NORMAL_XML
  };
  const int number_of_entries = inserted_values.size();

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values, false, number_of_entries);

  inserted_values = duplicateElements(inserted_values);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Xml, Update_Success) {
  vector<string> inserted_values = {
    NORMAL_XML
  };

  vector <string> data_update_values = {
    SIMPLE_XML
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, data_update_values, data_update_values);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, data_update_values, data_update_values);

  data_update_values = {
    SIMPLE_XML
  };

  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, data_update_values, data_update_values);
  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, data_update_values, data_update_values);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}