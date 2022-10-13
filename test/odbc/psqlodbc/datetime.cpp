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

  testCommonColumnAttributes(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], LENGTH_EXPECTED, PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
}

// Doesn't work in SQL Server, but does in BBF & BBF PG connection?
TEST_F(PSQL_Datatypes_Datetime, DISABLED_Table_Create_Fail) {
  const vector<vector<pair<string, string>>> invalid_columns {
    {{"invalid1", DATATYPE + "(4)"}} // Cannot specify a column width on data type datetime.
  };

  // Assert that table creation will always fail with invalid column definitions
  testTableCreationFailure(TABLE_NAME, invalid_columns);
}

// inserted values differ that of expected?
TEST_F(PSQL_Datatypes_Datetime, Insertion_Success) {
  vector<string> inserted_values = {
    "NULL", // NULL value
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  vector<string> expected = {
    "NULL", // NULL values
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  testInsertionSuccessChar(TABLE_NAME, TABLE_COLUMNS, "pk", inserted_values, expected);

}

TEST_F(PSQL_Datatypes_Datetime, Insertion_Failure) {

  vector<string> inserted_values = {
    "1752-01-01 00:00:000", // past lowest boundary
    "9999-12-31 23:59:59.999" // past highest boundary
  };

  testInsertionFailure(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], inserted_values, false);
}

TEST_F(PSQL_Datatypes_Datetime, Update_Success) {

  vector<string> inserted_values = {
    "2011-04-15 16:44:09"
  };

  vector<string> updated_values = {
    "1900-01-31 12:59:59.999", // standard value
    "9999-12-31 23:59:59.997", // max value
    "1753-01-01 00:00:00", // min value
    "" // blank value
  };

  vector<string> expected_updated_values = {
    "1900-01-31 12:59:59.999", // standard value
    "9999-12-31 23:59:59.997", // max value
    "1753-01-01 00:00:00", // min value
    "1900-01-01 00:00:00" // blank value
  };

  testUpdateSuccessChar(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], COL_NAMES[1], inserted_values, inserted_values, updated_values, expected_updated_values);
}

TEST_F(PSQL_Datatypes_Datetime, Update_Fail) {

  vector<string> inserted_values = {
    "2011-04-15 16:44:09"
  };

  vector<string> updated_values = {
    "1752-01-01 00:00:000"
  };

  testUpdateFailChar(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], COL_NAMES[1], inserted_values, inserted_values, updated_values);
}

TEST_F(PSQL_Datatypes_Datetime, View_creation) {

  vector<string> inserted_values = {
    "NULL", // NULL values
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  vector<string> expected = {
    "NULL", // NULL values
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  testViewCreationChar(VIEW_NAME, TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], inserted_values, expected);
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

  vector<string> inserted_values = {
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  vector<string> expected = {
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  testPrimaryKeysChar(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS, inserted_values, expected);
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

  vector<string> inserted_values = {
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  vector<string> expected = {
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  testPrimaryKeysChar(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS, inserted_values, expected);
}

TEST_F(PSQL_Datatypes_Datetime, Table_Unique_Constraint) {

  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], "INT"},
    {COL_NAMES[1], DATATYPE}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL_NAMES[1]
  };

  // Insert valid values into the table and assert affected rows
  vector<string> inserted_values = {
    "1753-01-01 00:00:000", // smallest value
    "2011-04-15 16:44:09.000", // random regular values
    "9999-12-31 23:59:59.997", // max value
    "" // blank value
  };

  vector<string> expected = {
    "1753-01-01 00:00:00", // smallest value
    "2011-04-15 16:44:09", // random regular value
    "9999-12-31 23:59:59.997", // max value
    "1900-01-01 00:00:00" // blank value
  };

  testUniqueConstraintChar(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], UNIQUE_COLUMNS, inserted_values, expected);
}

TEST_F(PSQL_Datatypes_Datetime, Comparison_Operators) {
  
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL_NAMES[0], DATATYPE + " PRIMARY KEY"},
    {COL_NAMES[1], DATATYPE}
  };

  vector<string> INSERTED_PK = {
    "1753-01-01 00:00:000",
    "9999-12-31 23:59:59.997"
  };

  vector<string> INSERTED_DATA = {
    "1754-01-01 00:00:000",
    "9999-12-31 23:59:59.997"
  };

  vector<string> OPERATIONS_QUERY = {
    COL_NAMES[0] + "=" + COL_NAMES[1],
    COL_NAMES[0] + "<>" + COL_NAMES[1],
    COL_NAMES[0] + "<" + COL_NAMES[1],
    COL_NAMES[0] + "<=" + COL_NAMES[1],
    COL_NAMES[0] + ">" + COL_NAMES[1],
    COL_NAMES[0] + ">=" + COL_NAMES[1]
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  // initialization of expected_results
  vector<vector<char>> expected_results = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    const char *date_1 = INSERTED_PK[i].data();
    const char *date_2 = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(date_1, date_2) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) >= 0 ? '1' : '0');
  }

  testComparisonOperators(TABLE_NAME, TABLE_COLUMNS, COL_NAMES[0], COL_NAMES[1], INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results);
}

// inserted values differ that of expected?
TEST_F(PSQL_Datatypes_Datetime, Comparison_Functions) {

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
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL_NAMES[1] + ")",
    "MAX(" + COL_NAMES[1] + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expected_results
  vector<string> expected_results = {};
  int min_expected = 0, max_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    const char *currMin = EXPECTED_RESULTS[min_expected].data();
    const char *currMax = EXPECTED_RESULTS[max_expected].data();
    const char *curr = EXPECTED_RESULTS[i].data();

    min_expected = strcmp(curr, currMin) < 0 ? i : min_expected;
    max_expected = strcmp(curr, currMax) > 0 ? i : min_expected;
  }
  expected_results.push_back(EXPECTED_RESULTS[min_expected]);
  expected_results.push_back(EXPECTED_RESULTS[max_expected]);

  testComparisonFunctionsChar(TABLE_NAME, TABLE_COLUMNS, INSERTED_DATA, OPERATIONS_QUERY, expected_results);
}
