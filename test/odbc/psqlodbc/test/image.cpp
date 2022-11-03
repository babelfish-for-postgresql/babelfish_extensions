#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"
#include <fstream>

const string TABLE_NAME = "master_dbo.image_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.image";
const string VIEW_NAME = "master_dbo.image_view_odbc_test";

// Relative to where `./build/main` is ran
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
  const vector<string> INSERTED_VALUES = {
    "0x" + INSERTED_IMAGE_HEX_STR
  };

  const string INSERT_STRING = "(0, DECODE('" + INSERTED_IMAGE_HEX_STR + "', 'hex'))";

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, INSERT_STRING, 1);
  verifyValuesInObject(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Image, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "0x" + INSERTED_IMAGE_HEX_STR
  };
  const vector<string> UPDATED_VALUES = {
    "DECODE('" + UPDATED_IMAGE_HEX_STR + "', 'hex')"
  };
  const vector<string> EXPECTED_UPDATED_VALUES = {
    "0x" + UPDATED_IMAGE_HEX_STR 
  };
  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  
  const string INSERTED_STRING = "(0, DECODE('" + INSERTED_IMAGE_HEX_STR + "', 'hex'))";

  insertValuesInTable(ServerType::PSQL, TABLE_NAME, INSERTED_STRING, 1);
  verifyValuesInObject(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, UPDATED_VALUES, EXPECTED_UPDATED_VALUES, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Image, View_creation) {
 const vector<string> INSERTED_VALUES = {
    "0x" + INSERTED_IMAGE_HEX_STR
  };

  const string INSERT_STRING = "(0, DECODE('" + INSERTED_IMAGE_HEX_STR + "', 'hex'))";
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, INSERT_STRING, 1);
  verifyValuesInObject(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}