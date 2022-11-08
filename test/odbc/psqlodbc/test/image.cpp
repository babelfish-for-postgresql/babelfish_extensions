#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"
#include <fstream>

const string BBF_TABLE_NAME = "master.dbo.image_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.image_view_odbc_test";

const string TABLE_NAME = "master_dbo.image_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.image";
const string VIEW_NAME = "master_dbo.image_view_odbc_test";

// Relative to where calling the exectable
const std::string INSERTED_FILE_PATH = "psqlodbc/Images/Black.png";
const std::string UPDATED_FILE_PATH = "psqlodbc/Images/circle.png";
static string INSERTED_IMAGE_HEX_STR;
static string UPDATED_IMAGE_HEX_STR;

const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

class PSQL_DataTypes_Image : public testing::Test {
  protected:
    static void SetUpTestSuite() {
      // Load Image
      std::ifstream infile(INSERTED_FILE_PATH, std::ios_base::binary);

      std::vector<char> buffer(
         (std::istreambuf_iterator<char>(infile)),
         (std::istreambuf_iterator<char>()));

      char stream_buffer[BUFFER_SIZE] = "";
      for (char c : buffer) {
        sprintf(stream_buffer, "%02x", c);
        INSERTED_IMAGE_HEX_STR += stream_buffer;
      }

      infile.close();

      std::ifstream update_infile(UPDATED_FILE_PATH, std::ios_base::binary);

      std::vector<char> update_buffer(
         (std::istreambuf_iterator<char>(update_infile)),
         (std::istreambuf_iterator<char>()));

      char update_stream_buffer[BUFFER_SIZE] = "";
      for (char c : update_buffer) {
        sprintf(update_stream_buffer, "%02x", c);
        UPDATED_IMAGE_HEX_STR += update_stream_buffer;
      }

      update_infile.close();
    }

  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));

    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_teardown(Drivers::GetDriver(ServerType::PSQL));
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));

    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }
    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", BBF_VIEW_NAME));
    bbf_test_setup.CloseStmt();
    bbf_test_setup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_Image, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Image, Insertion_Success) {
  vector<string> inserted_values = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "49",     // Rand
    "02",     // Rand, different format
    "268435455",  // 7 Bytes
    "4294967295", // 8 Bytes - 1
    "4294967295", // 8 Bytes
    "4294967296" // 8 Bytes + 1
  };
  vector<string> expected_values = getExpectedResults_VarBinary(inserted_values);

  inserted_values.push_back(" DECODE('" + INSERTED_IMAGE_HEX_STR + "', 'hex')");
  expected_values.push_back("0x" + INSERTED_IMAGE_HEX_STR);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, 
                      inserted_values, expected_values, 0, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Image, Update_Success) {
  // Insert with a image
  const vector<string> INSERTED_VALUES = {
    " DECODE('" + INSERTED_IMAGE_HEX_STR + "', 'hex')"
  };
  const vector<string> EXPECTED_VALUES = {
    "0x" + INSERTED_IMAGE_HEX_STR
  };
  
  // test update function with 'Varbinary' values
  vector<string> updated_values = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "49",     // Rand
    "02",     // Rand, different format
    "268435455",  // 7 Bytes
    "4294967295", // 8 Bytes - 1
    "4294967295", // 8 Bytes
    "4294967296" // 8 Bytes + 1
  };
  vector<string> expected_updated_values = getExpectedResults_VarBinary(updated_values);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, 
                      INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, 
                    updated_values, expected_updated_values, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Image, View_creation) {
  const vector<string> inserted_values = {
    "0x" + INSERTED_IMAGE_HEX_STR
  };

  const int NUM_OF_DATA = inserted_values.size();

  const string INSERT_STRING = "(0, DECODE('" + INSERTED_IMAGE_HEX_STR + "', 'hex'))";
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, INSERT_STRING, NUM_OF_DATA);
  verifyValuesInObject(ServerType::PSQL, TABLE_NAME, COL1_NAME, inserted_values, inserted_values);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, inserted_values, inserted_values);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// BBF supports DATALENGTH() operator for sys.image but PG does not
//   sys.DATALENGTH() has explicit support for 3 datatypes: char, text, sys.sql_variant
//   All other datatypes (e.g. sys.image) fall under ANYELEMENT
//   PG connection has issues with ANYELEMENT
//   PG treats sys.image as both sys.image and ANYELEMENT at the same time
//   raising an error: function sys.datalength(sys.image) is not unique
TEST_F(PSQL_DataTypes_Image, DISABLED_String_Functions) {
  const vector<string> inserted_values = {
    "0x" + INSERTED_IMAGE_HEX_STR
  };

  const int NUM_OF_DATA = inserted_values.size();

  const string INSERT_STRING = "(0, DECODE('" + INSERTED_IMAGE_HEX_STR + "', 'hex'))";

  const vector<string> OPERATIONS_QUERY = {
    "sys.DATALENGTH(" + COL2_NAME + ")"
  };

  // initialization of EXPECTED_RESULTS
  vector<vector<string>> EXPECTED_RESULTS = {
    {"122"}
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::MSSQL, BBF_TABLE_NAME, INSERT_STRING, NUM_OF_DATA);

  testStringFunctions(ServerType::MSSQL, BBF_TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, NUM_OF_DATA, COL1_NAME);
  testStringFunctions(ServerType::PSQL, TABLE_NAME, OPERATIONS_QUERY, 
                      EXPECTED_RESULTS, NUM_OF_DATA, COL1_NAME);

  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}
