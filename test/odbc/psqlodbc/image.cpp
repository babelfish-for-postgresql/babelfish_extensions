#include "conversion_functions_common.h"
#include "psqlodbc_tests_common.h"
#include <fstream>

const string TABLE_NAME = "master_dbo.image_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.image";
const string VIEW_NAME = "master_dbo.image_view_odbc_test";

// Relative to where `./build/main` is ran
const std::string FILE_PATH = "psqlodbc/Images/Black.png";
static string IMAGE_HEX_STR;

const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

class PSQL_DataTypes_Image : public testing::Test {
  protected:
    static void SetUpTestSuite() {
      // Load Image
      std::ifstream infile(FILE_PATH, std::ios_base::binary);

      std::vector<char> buffer(
         (std::istreambuf_iterator<char>(infile)),
         (std::istreambuf_iterator<char>()));

      char stream_buffer[BUFFER_SIZE] = "";
      for (char c : buffer) {
        sprintf(stream_buffer, "%02x", c);
        IMAGE_HEX_STR += stream_buffer;
      }

      infile.close();
    }

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
  const vector<string> EXPECTED_VALUES = {
    "0x" + IMAGE_HEX_STR
  };
  const int NUM_OF_INSERTS = EXPECTED_VALUES.size();
  const string INSERT_STRING = "(0, DECODE('" + IMAGE_HEX_STR + "', 'hex'))";

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, INSERT_STRING, 1);
  verifyValuesInObject(ServerType::PSQL, TABLE_NAME, COL1_NAME, EXPECTED_VALUES, EXPECTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}