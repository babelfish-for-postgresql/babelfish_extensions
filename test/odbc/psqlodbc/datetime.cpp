#include "../src/drivers.h"
#include "../src/odbc_handler.h"
#include "psqlodbc_tests_common.h"

#include <gtest/gtest.h>
#include <sqlext.h>

using std::pair;

const string TABLE_NAME = "master_dbo.datetime_table_odbc_test";
const string VIEW_NAME = "master_dbo.datetime_view_odbc_test";
const string DATATYPE = "sys.datetime";
vector<string> COL_NAMES = {"pk", "datetime_1"};

static vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], " int PRIMARY KEY"},
    {COL_NAMES[1], DATATYPE}
};

class PSQL_Datatypes_Datetime: public testing::Test {
   void SetUp() override {
    if(!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
   }

   void TearDown() override {
    if(!Drivers::DriverExists(ServerType::PSQL)) {
        GTEST_SKIP() << "PSQL Driver not present: skipping tear down.";
    }
    OdbcHandler test_cleanup(Drivers::GetDriver(ServerType::PSQL));
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_cleanup.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
   }

};

TEST_F(PSQL_Datatypes_Datetime, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  testCommonColumnAttributes(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], LENGTH_EXPECTED, PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
}

// Doesn't work in SQL Server, but does in BBF & BBF PG connection?
TEST_F(PSQL_Datatypes_Datetime, DISABLED_Table_Create_Fail) {
  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE + "(4)"}} // Cannot specify a column width on data type datetime.
  };

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(odbcHandler, TABLE_NAME, invalid_columns);
}

// inserted values differ that of expected?
TEST_F(PSQL_Datatypes_Datetime, Insertion_Success) {

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<vector<string>> inserted_values = {
    {"1", "NULL"}, // NULL values
    {"2", "1753-01-01 00:00:000" }, // smallest value
    {"3", "2011-04-15 16:44:09.000"}, // random regular values
    {"4", "9999-12-31 23:59:59.997"}, // max value
    {"5", ""} // blank value
  };

  vector<vector<string>> expected = {
    {"1", "NULL"}, // NULL values
    {"2", "1753-01-01 00:00:00" }, // smallest value
    {"3", "2011-04-15 16:44:09"}, // random regular value
    {"4", "9999-12-31 23:59:59.997"}, // max value
    {"5", "1900-01-01 00:00:00"} // blank value
  };

  testInsertionSuccess(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], inserted_values, expected);
}

TEST_F(PSQL_Datatypes_Datetime, Insertion_Failure) {

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<vector<string>> inserted_values = {
    {"1", "1752-01-01 00:00:000" }, // past lowest boundary
    {"2", "9999-12-31 23:59:59.999"} // past highest boundary
  };

  testInsertionFailure(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], inserted_values);
}

TEST_F(PSQL_Datatypes_Datetime, Update_Success) {
  const string PK_VAL = "1";

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<vector<string>> inserted_values = {
    {PK_VAL, "2011-04-15 16:44:09"} 
  };

  vector<vector<string>> updated_values = {
    {PK_VAL, "1900-01-31 12:59:59.999"}, // standard value
    {PK_VAL, "9999-12-31 23:59:59.997"}, // max value
    {PK_VAL, "1753-01-01 00:00:00"}, // min value
    {PK_VAL, ""} // blank value
  };

  vector<vector<string>> expected_updated_values = {
    {PK_VAL, "1900-01-31 12:59:59.999"}, // standard value
    {PK_VAL, "9999-12-31 23:59:59.997"}, // max value
    {PK_VAL, "1753-01-01 00:00:00"}, // min value
    {PK_VAL, "1900-01-01 00:00:00"} // blank value
  };

  testUpdateSuccess(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES, COL_NAMES[0], PK_VAL, inserted_values, inserted_values, updated_values, expected_updated_values);
}

TEST_F(PSQL_Datatypes_Datetime, Update_Fail) {
  const string PK_VAL = "1";

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<vector<string>> inserted_values = {
    {PK_VAL, "2011-04-15 16:44:09"} 
  };

  vector<vector<string>> updated_values = {
    {PK_VAL, "1752-01-01 00:00:000"}
  };

  testUpdateFail(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES, COL_NAMES[0], PK_VAL, inserted_values, inserted_values, updated_values);
}

TEST_F(PSQL_Datatypes_Datetime, View_creation) {

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<vector<string>> inserted_values = {
    {"1", "NULL"}, // NULL values
    {"2", "1753-01-01 00:00:000" }, // smallest value
    {"3", "2011-04-15 16:44:09.000"}, // random regular values
    {"4", "9999-12-31 23:59:59.997"}, // max value
    {"5", ""} // blank value
  };

  vector<vector<string>> expected = {
    {"1", "NULL"}, // NULL values
    {"2", "1753-01-01 00:00:00" }, // smallest value
    {"3", "2011-04-15 16:44:09"}, // random regular value
    {"4", "9999-12-31 23:59:59.997"}, // max value
    {"5", "1900-01-01 00:00:00"} // blank value
  };

  testViewCreation(odbcHandler, TABLE_NAME, TABLE_COLUMNS, VIEW_NAME, COL_NAMES[0], inserted_values, expected);
}

TEST_F(PSQL_Datatypes_Datetime, Table_Single_Primary_Keys) {

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "INT"},
    {COL_NAMES[1], DATATYPE}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL_NAMES[1]
  };

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<vector<string>> inserted_values = {
    {"1", "1753-01-01 00:00:000" }, // smallest value
    {"2", "2011-04-15 16:44:09.000"}, // random regular values
    {"3", "9999-12-31 23:59:59.997"}, // max value
    {"4", ""} // blank value
  };

  vector<vector<string>> expected = {
    {"1", "1753-01-01 00:00:00" }, // smallest value
    {"2", "2011-04-15 16:44:09"}, // random regular value
    {"3", "9999-12-31 23:59:59.997"}, // max value
    {"4", "1900-01-01 00:00:00"} // blank value
  };

  testPrimaryKeys(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS, inserted_values, expected);
}

TEST_F(PSQL_Datatypes_Datetime, Table_Composite_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "INT"},
    {COL_NAMES[1], DATATYPE}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL_NAMES[0], 
    COL_NAMES[1]
  };

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<vector<string>> inserted_values = {
    {"1", "1753-01-01 00:00:000" }, // smallest value
    {"2", "2011-04-15 16:44:09.000"}, // random regular values
    {"3", "9999-12-31 23:59:59.997"}, // max value
    {"4", ""} // blank value
  };

  vector<vector<string>> expected = {
    {"1", "1753-01-01 00:00:00" }, // smallest value
    {"2", "2011-04-15 16:44:09"}, // random regular value
    {"3", "9999-12-31 23:59:59.997"}, // max value
    {"4", "1900-01-01 00:00:00"} // blank value
  };

  testPrimaryKeys(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS, inserted_values, expected);
}

TEST_F(PSQL_Datatypes_Datetime, Table_Unique_Constraint) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "INT"},
    {COL_NAMES[1], DATATYPE}
  };
  const string UNIQUE_CONSTRAINT_TABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  const vector<string> UNIQUE_COLUMNS = {
    COL_NAMES[1]
  };

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  // Insert valid values into the table and assert affected rows
  vector<vector<string>> inserted_values = {
    {"1", "1753-01-01 00:00:000" }, // smallest value
    {"2", "2011-04-15 16:44:09.000"}, // random regular values
    {"3", "9999-12-31 23:59:59.997"}, // max value
    {"4", ""} // blank value
  };

  vector<vector<string>> expected = {
    {"1", "1753-01-01 00:00:00" }, // smallest value
    {"2", "2011-04-15 16:44:09"}, // random regular value
    {"3", "9999-12-31 23:59:59.997"}, // max value
    {"4", "1900-01-01 00:00:00"} // blank value
  };

  testUniqueConstraint(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], UNIQUE_CONSTRAINT_TABLE_NAME, UNIQUE_COLUMNS, inserted_values, expected);
}

TEST_F(PSQL_Datatypes_Datetime, Comparison_Operators) {
  
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], DATATYPE + " PRIMARY KEY"},
    {COL_NAMES[1], DATATYPE}
  };

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<string> INSERTED_PK = {
    "1753-01-01 00:00:000",
    "9999-12-31 23:59:59.997"
  };

  vector<string> INSERTED_DATA = {
    "1754-01-01 00:00:000",
    "9999-12-31 23:59:59.997"
  };
  testComparisonOperators(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], COL_NAMES[1], INSERTED_PK, INSERTED_DATA);
}

// inserted values differ that of expected?
TEST_F(PSQL_Datatypes_Datetime, Comparison_Functions) {
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const vector<string> INSERTED_DATA = {
    "1753-01-01 00:00:000",
    "2011-04-15 16:44:09.000",
    "9999-12-31 23:59:59.997"
  };

  const vector<string> EXPECTED_RESULTS = {
    "1753-01-01 00:00:00",
    "2011-04-15 16:44:09",
    "9999-12-31 23:59:59.997"
  };
  testComparisonFunctions(odbcHandler, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[1], INSERTED_DATA, EXPECTED_RESULTS);
}
