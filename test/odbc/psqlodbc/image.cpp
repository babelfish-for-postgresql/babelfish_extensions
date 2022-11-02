#include "conversion_functions_common.h"
#include "psqlodbc_tests_common.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

const string TABLE_NAME = "master_dbo.image_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.image";
const string VIEW_NAME = "master_dbo.image_view_odbc_test";

const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, " int PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

class PSQL_DataTypes_Image : public testing::Test {

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
  const int BUFFER_LEN = 0;
  int width, height, channels;
  unsigned char *img = stbi_load("/home/toby/babelfish/babelfish_extensions/test/odbc/psqlodbc/index.jpg", &width, &height, &channels, 3);
//   std::string s(reinterpret_cast<char const*>(img));
//   unsigned char img[] = {255,0,0,0,0,255};
//   std::cout<<"IMAGE: "<<"\n";
//   std::cout<<width<<" "<<height<<" "<<channels<<"\n";
//   std::cout<<channels; 22098
  const long int BYTES_EXPECTED = 140637691628658;

  unsigned char pk;
  unsigned char data;
  // int data;
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {
    {1, SQL_C_STINYINT, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, 0,  &data_len}
  };

  string insert_string = " ( 0,bytea(\'/home/toby/babelfish/babelfish_extensions/test/odbc/psqlodbc/index.jpg\'))"; 
  string comma{};
  
//   string insert_string{};
//   for (int i = 0; i < 1; i++){
//     insert_string += comma + "(" + std::to_string(i) + "," + std::to_string(img[i]) + ")";
//     comma = ",";
//   }
//   std::cout<<sizeof(img)<<" "<<img[1];

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
// std::cout<<"wqewqeq";
//   string insert_string = "(0, bytea('/home/toby/babelfish/babelfish_extensions/test/odbc/psqlodbc/index.jpg'))";
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(affected_rows, valid_inserted_values.size());
  
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));
// std::cout<<"DATA is: "<<data[0];
//   for (int i = 0; i < valid_inserted_values.size(); ++i) {
    
    // rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    // ASSERT_EQ(rcode, SQL_SUCCESS);
//     ASSERT_EQ(pk_len, BYTES_EXPECTED);
//     ASSERT_EQ(pk, i);

//     if (valid_inserted_values[i] != "NULL")
    // {
    // ASSERT_EQ(data_len, BYTES_EXPECTED);
    ASSERT_EQ(data, img);
    // }
    // else 
    //   ASSERT_EQ(data_len, SQL_NULL_DATA);
//   }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));


// //   const vector<string> VALID_INSERTED_VALUES = {
// //     "-2147483648",
// //     "2147483647",
// //     "3",
// //     "NULL"
// //   };

//   const vector<int> EXPECTED = getExpectedResults_Int(img);

//   const vector<long> EXPECTED_LEN(EXPECTED.size(), INT_BYTES_EXPECTED);

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_char, data, BUFFER_LEN, img, 
//     img, EXPECTED_LEN);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

// TEST_F(PSQL_DataTypes_Image, Insertion_Fail) {
//   const vector<string> INVALID_INSERTED_VALUES = {
//     "-2147483649",
//     "2147483648"
//   };

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INVALID_INSERTED_VALUES, true);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Update_Success) {
//   int data;
//   const int BUFFER_LEN = 0;

//   const vector<string> DATA_INSERTED = {"1"};
//   const vector<int> DATA_EXPECTED = getExpectedResults_Image(DATA_INSERTED);
//   const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), INT_BYTES_EXPECTED);

//   const vector<string> DATA_UPDATED_VALUES = {
//     "5",
//     "-2147483648",
//     "2147483647"
//   };
//   const vector<int> DATA_UPDATED_EXPECTED = getExpectedResults_Image(DATA_UPDATED_VALUES);

//   const vector<long> EXPECTED_LEN(DATA_UPDATED_EXPECTED.size(), INT_BYTES_EXPECTED);
  
//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, DATA_INSERTED, DATA_EXPECTED, EXPECTED_INSERT_LEN);
//   testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SLONG, data, BUFFER_LEN, DATA_UPDATED_VALUES, 
//     DATA_UPDATED_EXPECTED, EXPECTED_LEN);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Update_Fail) {
//   int data;
//   const int BUFFER_LEN = 0;

//   const vector<string> DATA_INSERTED = {"1"};
//   const vector<int> EXPECTED_DATA_INSERTED = getExpectedResults_Image(DATA_INSERTED);
//   const vector<long> EXPECTED_INSERT_LEN(DATA_INSERTED.size(), INT_BYTES_EXPECTED);

//   const vector<string> DATA_UPDATED_VALUE = {"2147483648"};

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, DATA_INSERTED, 
//     EXPECTED_DATA_INSERTED, EXPECTED_INSERT_LEN);
//   testUpdateFail(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, SQL_C_SLONG, data, BUFFER_LEN, EXPECTED_DATA_INSERTED, 
//     EXPECTED_INSERT_LEN, DATA_UPDATED_VALUE);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Arithmetic_Operators) {
//   const int BUFFER_LEN = 0;

//   vector<string> INSERTED_PK = {
//     "2",
//     "18",
//     "2147483645"
//   };

//   vector<string> INSERTED_DATA = {
//     "12",
//     "2",
//     "1"
//   };
//   const int NUM_OF_DATA = INSERTED_DATA.size();

//   // insertString initialization
//   string insertString{};
//   string comma{};
//   for (int i = 0; i < NUM_OF_DATA; i++) {
//     insertString += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
//     comma = ",";
//   }

//   const vector<string> OPERATIONS_QUERY = {
//     COL1_NAME + "+" + COL2_NAME,
//     COL1_NAME + "-" + COL2_NAME,
//     COL1_NAME + "/" + COL2_NAME,
//     COL1_NAME + "*" + COL2_NAME,
//     "ABS(" + COL1_NAME + ")",
//     "POWER(" + COL1_NAME + "," + COL2_NAME + ")",
//     "||/ " + COL1_NAME,
//     "LOG(" + COL1_NAME + ")"
//   };
//   const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

//   vector<vector<int>> expected_results = {};

//   // initialization of expected_results
//   for (int i = 0; i < NUM_OF_DATA; i++) {
//     expected_results.push_back({});
//     int data_1 = stringToImage(INSERTED_PK[i]);
//     int data_2 = stringToImage(INSERTED_DATA[i]);

//     expected_results[i].push_back(data_1 + data_2);
//     expected_results[i].push_back(data_1 - data_2);
//     expected_results[i].push_back(data_1 / data_2);
//     expected_results[i].push_back(data_1 * data_2);

//     expected_results[i].push_back(abs(data_1));
//     expected_results[i].push_back(pow(data_1, data_2));
//     expected_results[i].push_back(cbrt(data_1));
//     expected_results[i].push_back(log10(data_1));
//   }

//   vector<int> col_results(NUM_OF_OPERATIONS, {});
//   const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, INT_BYTES_EXPECTED);
  
//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
//   testArithmeticOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, NUM_OF_DATA, SQL_C_SLONG, 
//     col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Comparison_Operators) {
//   vector<string> INSERTED_PK = {
//     "-123",
//     "2",
//     "18",
//     "2147483645"
//   };

//   vector<string> INSERTED_DATA = {
//     "-8435"
//     "12",
//     "2",
//     "1"
//   };
//   const int NUM_OF_DATA = INSERTED_DATA.size();

//   // insertString initialization
//   string insertString{};
//   string comma{};
//   for (int i = 0; i < NUM_OF_DATA; i++) {
//     insertString += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
//     comma = ",";
//   }

//   const vector<string> OPERATIONS_QUERY = {
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
//     int data_1 = stringToImage(INSERTED_PK[i]);
//     int data_2 = stringToImage(INSERTED_DATA[i]);

//     expected_results[i].push_back(data_1 == data_2 ? '1' : '0');
//     expected_results[i].push_back(data_1 != data_2 ? '1' : '0');
//     expected_results[i].push_back(data_1 < data_2 ? '1' : '0');
//     expected_results[i].push_back(data_1 <= data_2 ? '1' : '0');
//     expected_results[i].push_back(data_1 > data_2 ? '1' : '0');
//     expected_results[i].push_back(data_1 >= data_2 ? '1' : '0');
//   }

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
//   testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, INSERTED_PK, INSERTED_DATA, OPERATIONS_QUERY, expected_results);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Comparison_Functions) {
//   const int BUFFER_LEN = 0;

//   const vector<string> INSERTED_DATA = {
//     "8",
//     "2",
//     "-123",
//     "2147483647"
//   };
//   const int NUM_OF_DATA = INSERTED_DATA.size();

//   // insertString initialization
//   string insertString{};
//   string comma{};
//   for (int i = 0; i < NUM_OF_DATA; i++) {
//     insertString += comma + "(" + std::to_string(i) + ",\'" + INSERTED_DATA[i] + "\')";
//     comma = ",";
//   }

//   const vector<string> OPERATIONS_QUERY = {
//     "MIN(" + COL2_NAME + ")",
//     "MAX(" + COL2_NAME + ")",
//     "SUM(" + COL2_NAME + ")",
//     "AVG(" + COL2_NAME + ")"
//   };
//   const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

//   const vector<long> EXPECTED_LEN(NUM_OF_OPERATIONS, INT_BYTES_EXPECTED);

//   // initialization of expected_results
//   vector<int> expected_results = {};

//   int curr = stringToImage(INSERTED_DATA[0]);
//   int min_expected = curr, max_expected = curr, sum = curr;

//   for (int i = 1; i < NUM_OF_DATA; i++) {
//     curr = stringToImage(INSERTED_DATA[i]);
//     sum += curr;

//     min_expected = std::min(curr, min_expected);
//     max_expected = std::max(curr, max_expected);
//   }
//   expected_results.push_back(min_expected);
//   expected_results.push_back(max_expected);
//   expected_results.push_back(sum);
//   expected_results.push_back(sum / NUM_OF_DATA);

//   // Create a vector of length NUM_OF_OPERATIONS with dummy value of -1 to store column results
//   vector<int> col_results(NUM_OF_OPERATIONS, -1);
  
//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
//   testComparisonFunctions(ServerType::PSQL, TABLE_NAME, SQL_C_SLONG, col_results, BUFFER_LEN, OPERATIONS_QUERY, expected_results, EXPECTED_LEN);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, View_Creation) {
//   const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

//   int data;
//   const int BUFFER_LEN = 0;

//   const vector<string> INSERTED_DATA = {
//     "8",
//     "2",
//     "-123",
//     "2147483647"
//   };
  
//   const vector<int> EXPECTED_DATA = getExpectedResults_Image(INSERTED_DATA);

//   const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);

//   createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
//   verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, EXPECTED_DATA, EXPECTED_LEN);
  
//   dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Table_Single_Primary_Keys) {
//   int data;

//   const vector<pair<string, string>> TABLE_COLUMNS = {
//     {COL1_NAME, DATATYPE_NAME},
//     {COL2_NAME, DATATYPE_NAME}
//   };
//   const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
//   const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

//   const vector<string> PK_COLUMNS = {
//     COL2_NAME
//   };

//   string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

//   const int BUFFER_LEN = 0;

//   const vector<string> INSERTED_DATA = {
//     "9453542",
//     "-42"
//   };
//   const vector<int> EXPECTED_DATA = getExpectedResults_Image(INSERTED_DATA);

//   const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
//   testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, 
//     EXPECTED_DATA, EXPECTED_LEN);
//   testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Table_Composite_Primary_Keys) {
//   int data;

//   const vector<pair<string, string>> TABLE_COLUMNS = {
//     {COL1_NAME, DATATYPE_NAME},
//     {COL2_NAME, DATATYPE_NAME}
//   };
//   const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
//   const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

//   const vector<string> PK_COLUMNS = {
//     COL1_NAME,
//     COL2_NAME
//   };

//   string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);

//   const int BUFFER_LEN = 0;

//   const vector<string> INSERTED_DATA = {
//     "9453542",
//     "-42"
//   };
//   const vector<int> EXPECTED_DATA = getExpectedResults_Image(INSERTED_DATA);

//   const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
//   testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, 
//     EXPECTED_DATA, EXPECTED_LEN);
//   testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, false, 0, false);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }

// TEST_F(PSQL_DataTypes_Image, Table_Unique_Constraints) {
//   const vector<pair<string, string>> TABLE_COLUMNS = {
//     {COL1_NAME, DATATYPE_NAME},
//     {COL2_NAME, DATATYPE_NAME}
//   };

//   const vector<string> UNIQUE_COLUMNS = {COL2_NAME};

//   string tableConstraints = createTableConstraint("UNIQUE", UNIQUE_COLUMNS);

//   int data;
//   const int BUFFER_LEN = 0;

//   const vector<string> INSERTED_DATA = {
//     "9453542",
//     "-42"
//   };
//   const vector<int> EXPECTED_DATA = getExpectedResults_Image(INSERTED_DATA);

//   const vector<long> EXPECTED_LEN(EXPECTED_DATA.size(), INT_BYTES_EXPECTED);

//   // table name without the schema
//   const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

//   createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
//   testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
//   testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, SQL_C_SLONG, data, BUFFER_LEN, INSERTED_DATA, 
//     EXPECTED_DATA, EXPECTED_LEN);
//   testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_DATA, true, INSERTED_DATA.size(), false);
//   dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
// }
