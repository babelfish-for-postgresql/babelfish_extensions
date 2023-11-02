#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master.dbo.geometry_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.geometry";
const string VIEW_NAME = "geometry_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

class PSQL_DataTypes_Geometry : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::MSSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_teardown(Drivers::GetDriver(ServerType::MSSQL));
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_Geometry, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {10, 0};
  const vector<int> PRECISION_EXPECTED = {10, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int", "udt"};

  createTable(ServerType::MSSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::MSSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::MSSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Geometry, Insertion_Success) {
  const vector<string> INSERTED_VALUES = {
    "(geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326))", 
    "(geometry::STGeomFromText('Point(1.0 2.0)', 4326))", 
    "(geometry::STGeomFromText('Point(47.65100 -22.34900)', 0))", 
    "(geometry::STPointFromText('Point(47.65100 -22.34900)', 4326))", 
    "(geometry::Point(47.65100, -22.34900, 4326))"
  };
  const vector<string> EXPECTED_VALUES = {
    "E6100000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C000000000000F03F0000000000000040", 
    "00000000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C17D9CEF753D34740D34D6210585936C0"
  };
  const int NUM_OF_INSERTS = INSERTED_VALUES.size();

  createTable(ServerType::MSSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::MSSQL, TABLE_NAME, COL1_NAME, 
                      INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  dropObject(ServerType::MSSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Geometry, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "(geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326))"
  };
  const vector<string> EXPECTED_VALUES = {
    "E6100000010C17D9CEF753D34740D34D6210585936C0"
  };

  const vector <string> UPDATED_VALUES = {
    "(geometry::STGeomFromText('Point(1.0 2.0)', 4326))", 
    "(geometry::STGeomFromText('Point(47.65100 -22.34900)', 0))", 
    "(geometry::STPointFromText('Point(47.65100 -22.34900)', 4326))", 
    "(geometry::Point(47.65100, -22.34900, 4326))"
  };
  const vector<string> EXPECTED_UPDATED_VALUES = {
    "E6100000010C000000000000F03F0000000000000040", 
    "00000000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C17D9CEF753D34740D34D6210585936C0"
  };

  createTable(ServerType::MSSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::MSSQL, TABLE_NAME, COL1_NAME,
                      INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testUpdateSuccess(ServerType::MSSQL, TABLE_NAME, COL1_NAME, COL2_NAME, 
                    UPDATED_VALUES, EXPECTED_UPDATED_VALUES, false, true);
  dropObject(ServerType::MSSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Geometry, View_creation) {
  const vector<string> INSERTED_VALUES = {
    "(geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326))", 
    "(geometry::STGeomFromText('Point(1.0 2.0)', 4326))", 
    "(geometry::STGeomFromText('Point(47.65100 -22.34900)', 0))", 
    "(geometry::STPointFromText('Point(47.65100 -22.34900)', 4326))", 
    "(geometry::Point(47.65100, -22.34900, 4326))"
  };

  const vector<string> EXPECTED_VALUES = {
    "E6100000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C000000000000F03F0000000000000040", 
    "00000000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C17D9CEF753D34740D34D6210585936C0", 
    "E6100000010C17D9CEF753D34740D34D6210585936C0"
  };

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::MSSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::MSSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);

  createView(ServerType::MSSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::MSSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  dropObject(ServerType::MSSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", TABLE_NAME);
}
