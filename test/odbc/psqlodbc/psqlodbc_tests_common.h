#ifndef PSQLODBC_TESTS_COMMON_H
#define PSQLODBC_TESTS_COMMON_H

#include <algorithm>
#include <cmath>
#include <gtest/gtest.h>
#include <sqlext.h>
#include <string>
#include <vector>

#include "../src/drivers.h"
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"

using std::vector;
using std::string;
using std::pair;

const int BUFFER_SIZE = 16384;
const int INT_BYTES_EXPECTED = 4;

/**
 * Duplicates the values in the input vector
 *
 * @param input Vector of data to be duplicated
 * @return vector which has the elements duplicated and appended
 */ 
template <typename T>
vector<T> duplicateElements(vector<T> input);

/**
 * Create a string that can be used in an insert statement. Assumes there is a column associated with
 * primary key values in the table, so it will automatically include a value for primary key in the string.
 *
 * @param insertedValues Vector of data to be inserted. e.g. {"NULL", "5", "9568546", "-1"}
 * @param isNumericInsert Indicates whether the data to be inserted should be formatted as a numeric or string insert.
 *  e.g. If true, insert string will be formatted as "(0,NULL),(1,-5),(2,9568546),(3,-1)".
 *  If false, string will be formatted as "(0,NULL),(1,'a'),(2,'abc'),(3,'def')".
 * 
 * @param pkStartingValue Optional. The primary key value to start incrementing at. The default value is 0.
 * @return A valid insert string that can be used in an insert statement.
 */ 
string InitializeInsertString(const vector<string>& insertedValues, bool isNumericInsert, int pkStartingValue = 0);

/**
 * Create a string that can be used as a table constraint.
 * 
 * @param constraintType The type of constraint that needs to be created. e.g. "PRIMARY KEY"
 * @param constraintCols The columns to apply the indicated constraint to. 
 * @return A valid constraint string that can be used in a CREATE TABLE query.
 *  e.g. "PRIMARY KEY (SampleColumn)"
*/
string createTableConstraint(const string &constraintType, const vector<string> &constraintCols);

/**
 * Create a table against the database.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The table to create. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param columns The columns to create the table on. The input should be formatted as {{COLUMN_NAME, COLUMN_TYPE}}
 *  e.g. 
 *  {
 *    {COL1_NAME, " int PRIMARY KEY"},
 *    {COL2_NAME, "bigint"}
 *  }
 * @param constraints Optional. Constraints to add to the table, if any. Default value is empty string. e.g. "PRIMARY KEY (SampleColumn)"
*/
void createTable(ServerType serverType, const string &tableName, const vector<pair <string, string>> &columns, const string &constraints = "");

/**
 * Create a view against the database.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param viewName The table to create. Can include the database and/or schema name. e.g. "master_dbo.SampleView"
 * @param viewQuery The SELECT statement to create the view on. e.g. "SELECT * FROM SampleTable"
*/
void createView(ServerType serverType, const string &viewName, const string &viewQuery);

/**
 * Drop an object against the database.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param objectType The type of object to drop. e.g. "TABLE"
 * @param objectName The name of the object to drop. Can include the database and/or schema name. e.g. "master_dbo.SampleObject"
*/
void dropObject(ServerType serverType, const string &objectType, const string &objectName);

/**
 * Insert values in a table given a vector of values to insert.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The table to insert values into. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param insertedValues Vector of data to be inserted. e.g. {"NULL", "5", "9568546", "-1"}
 * @param isNumericInsert Indicates whether the data to be inserted should be formatted as a numeric or string insert.
 *  e.g. If true, insert string will be formatted as "(0,NULL),(1,-5),(2,9568546),(3,-1)".
 *  If false, string will be formatted as "(0,NULL),(1,'a'),(2,'abc'),(3,'def')".
 * 
 * @param pkStartingValue Optional. The primary key value to start incrementing at. The default value is 0.
*/
void insertValuesInTable(ServerType serverType, const string &tableName, const vector<string> &insertedValues, 
  bool isNumericInsert, int pkStartingValue = 0);

/**
 * Insert values in a table given a valid insert string.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The table to insert values into. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param insertString The valid insert string to execute against the table.
 * @param numRows The number of rows inserted in the table.
*/
void insertValuesInTable(ServerType serverType, const string &tableName, const string &insertString, int numRows);

/**
 * Verify that all data in an object (like table or view) are of expected values.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param objectName The object that containts the data to verify. Can include the database and/or schema name. e.g. "master_dbo.SampleObject"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param insertedValues The values that were inserted into the object.
 * @param expectedInsertedValues The values expected from the object when selecting all from it.
 * @param pkStartingValue Optional. The primary key value the object starts incrementing at. The default value is 0.
 * @param caseInsensitive Optional. String comparision for data and expected can be case-insensitive. The default value is false.
*/
void verifyValuesInObject(ServerType serverType, const string &objectName, const string &orderByColumnName, 
  const vector<string> &insertedValues, const vector<string> &expectedInsertedValues, int pkStartingValue = 0, bool caseInsensitive = false);

/**
 * Verify that all data in an object (like table or view) are of expected values.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param objectName The object that containts the data to verify. Can include the database and/or schema name. e.g. "master_dbo.SampleObject"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param type The C type identifier of the data that will be retrieved. e.g. SQL_C_SBIGINT
 * @param data The buffer that will bind to the column containing the data to verify. Data will be returned in this buffer.
 * @param bufferLen The length of the buffer. 
 * @param insertedValues The values that were inserted into the object.
 * @param expectedInsertedValues The values expected from the object when selecting all from it.
 * @param expectedLen A vector containing the expected length of all data in the object. 
 * @param pkStartingValue Optional. The primary key value the object starts incrementing at. The default value is 0.
*/
template <typename T>
void verifyValuesInObject(ServerType serverType, string objectName, string orderByColumnName, int type, T data, 
  int bufferLen, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedLen, int pkStartingValue = 0);

/**
 * Test the following common column attributes of a table: length, precision, scale, and column name.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The table name with the columns to test. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param numCols The number of columns in the table.
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param lengthExpected A vector containing the expected length for each column in the table.
 * @param precisionExpected A vector containing the expected precision for each column in the table.
 * @param scaleExpected A vector containing the expected scale for each column in the table.
 * @param scaleExpected A vector containing the expected column name for each column in the table.
*/
void testCommonColumnAttributes(ServerType serverType, const string &tableName, int numCols, const string &orderByColumnName, 
  const vector<int> &lengthExpected, const vector<int> &precisionExpected, const vector<int> &scaleExpected, const vector<string> &nameExpected);

/**
 * Test the following common column attributes for a table with columns of character types (e.g. varchar): 
 * length, precision, scale, column name, case sensitivity, expected prefix, and expected suffix.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The table name with the columns to test. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param numCols The number of columns in the table.
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param lengthExpected A vector containing the expected length for each column in the table.
 * @param precisionExpected A vector containing the expected precision for each column in the table.
 * @param scaleExpected A vector containing the expected scale for each column in the table.
 * @param scaleExpected A vector containing the expected column name for each column in the table.
 * @param caseSensitivityExpected A vector containing the expected case sensitivity for each column in the table.
 * @param prefixExpected A vector containing the expected prefix for each column in the table.
 * @param suffixExpected A vector containing the expected suffix for each column in the table.
*/
void testCommonCharColumnAttributes(ServerType serverType, const string &tableName, int numCols, const string &orderByColumnName, 
  const vector<int> &lengthExpected, const vector<int> &precisionExpected, const vector<int> &scaleExpected, const vector<string> &nameExpected, 
  const vector<int> &caseSensitivityExpected, const vector<string> &prefixExpected, const vector<string> &suffixExpected);

/**
 * Test table creation fails when created with invalid columns.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The table name we are attempting to create. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param invalidColumns The invalid columns to create the table on. The input should be formatted as {{COLUMN_NAME, COLUMN_TYPE}}
 *  e.g. 
 *  {
 *    {COL1_NAME, " int PRIMARY KEY"},
 *    {COL2_NAME, "bigint"}
 *  }
*/
void testTableCreationFailure(ServerType serverType, const string &tableName, const vector<vector<pair<string, string>>> &invalidColumns);

/**
 * Insert values in a table given a vector of values to insert, and validate that all data in the table are of expected values.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to insert values into & select all from. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param insertedValues Vector of data to be inserted. e.g. {"NULL", "5", "9568546", "-1"}
 * @param expectedInsertedValues The values expected from the table when selecting all from it.
 * @param pkStartingValue Optional. The primary key value the object starts incrementing at. The default value is 0.
 * @param caseInsensitive Optional. String comparision for data and expected can be case-insensitive. The default value is false.
 * @param numericInsert Optional. Allow inserts without quotes. e.g. inserting using integers. The default value is false.
*/
void testInsertionSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const vector<string> &insertedValues, const vector<string> &expectedInsertedValues, int pkStartingValue = 0,
  bool caseInsensitive = false, bool numericInsert = false);

/**
 * Insert values in a table given a vector of values to insert, and validate that all data in the table are of expected values.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to insert values into & select all from. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param type The C type identifier of the data that will be retrieved. e.g. SQL_C_SBIGINT
 * @param data The buffer that will bind to the column containing the data to verify. Data will be returned in this buffer.
 * @param bufferLen The length of the buffer. 
 * @param insertedValues Vector of data to be inserted. e.g. {"NULL", "5", "9568546", "-1"}
 * @param expectedInsertedValues The values expected from the table when selecting all from it.
 * @param expectedLen A vector containing the expected length of all data in the object. 
 * @param pkStartingValue Optional. The primary key value the table starts incrementing at. The default value is 0.
*/
template <typename T>
void testInsertionSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, int type, T data, int bufferLen, 
  const vector<string> &insertedValues, const vector<T> &expectedInsertedValues, const vector<long> &expectedLen, int pkStartingValue = 0);

/**
 * Given a vector of invalid data, test that data insertion fails in a table.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to attempt to insert invalid values into. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param A vector of invalid values to attempt to insert in the table.
 * @param isNumericInsert Indicates whether the data to be inserted should be formatted as a numeric or string insert.
 *  e.g. If true, insert string will be formatted as "(0,5)".
 *  If false, string will be formatted as "(0,'a')".
 * 
 * @param pkStartingValue Optional. The primary key value the table starts incrementing at. The default value is 0.
 * @param tableRemainsEmpty Optional. Indicates whether after the failed inserts, the table is expected to be empty. The default value is true.
*/
void testInsertionFailure(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const vector<string> &invalidInsertedValues, bool isNumericInsert, int pkStartingValue = 0, bool tableRemainsEmpty = true);

/**
 * Given a vector of values, test that some data in the table can be updated successfully with each value.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to update. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param colNameToUpdate The name of the column to update.
 * @param updatedValues A vector of values to update some data in the table with one by one.
 * @param expectedUpdatedValues A vector containing expected values after a successful update.
 * @param caseInsensitive Optional. String comparision for data and expected can be case-insensitive. The default value is false.
 * @param numericUpdate Optional. Allow updates without quotes. e.g. updating using integers. The default value is false.
*/
void testUpdateSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const string &colNameToUpdate, const vector<string> &updatedValues, const vector<string> &expectedUpdatedValues,
  bool caseInsensitive = false, bool numericUpdate = false);

/**
 * Given a vector of values, test that some data in the table can be updated successfully with each value.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to update. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param colNameToUpdate The name of the column to update.
 * @param type The C type identifier of the data that will be retrieved. e.g. SQL_C_SBIGINT
 * @param data The buffer that will bind to the column containing the data to verify. Data will be returned in this buffer.
 * @param bufferLen The length of the buffer. 
 * @param updatedValues A vector of values to update some data in the table with one by one.
 * @param expectedUpdatedValues A vector containing expected values to test against when a successful update occurs.
 * @param expectedUpdatedLen A vector containing the expected length of successfully updated data in the table. 
 * @param caseInsensitive Optional. String comparision for data and expected can be case-insensitive. The default value is false.
*/
template <typename T>
void testUpdateSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, const string &colNameToUpdate, int type, 
  T data, int bufferLen, const vector<string> &updatedValues, const vector<T> &expectedUpdatedValues, const vector<long> &expectedUpdatedLen, bool caseInsensitive = false);

/**
 * Given a vector of invalid values, test that updating a table fails using these values.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to update. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param colNameToUpdate The name of the column to update.
 * @param expectedInsertedValues Used to verify the data in the table hasn't changed after all the unsuccessful updates.
 * @param updatedValues A vector of invalid values to update some data in the table with one by one.
*/
void testUpdateFail(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const string &colNameToUpdate, const vector<string> &expectedInsertedValues, const vector<string> &updatedValues);

/**
 * Given a vector of invalid values, test that updating a table fails using these values.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to update. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param colNameToUpdate The name of the column to update.
 * @param type The C type identifier of the data that will be retrieved. e.g. SQL_C_SBIGINT
 * @param data The buffer that will bind to the column containing the data to verify. Data will be returned in this buffer.
 * @param bufferLen The length of the buffer. 
 * @param expectedInsertedValues Used to verify the data in the table hasn't changed after all the unsuccessful updates.
 * @param expectedInsertedLen A vector containing the expected length of all data in the object.
 * @param updatedValues A vector of invalid values to update some data in the table with one by one.
*/
template <typename T>
void testUpdateFail(ServerType serverType, const string &tableName, const string &orderByColumnName, const string &colNameToUpdate, int type, 
  T data, int bufferLen, const vector<T> &expectedInsertedValues, const vector<long> &expectedInsertedLen, const vector<string> &updatedValues);

/**
 * Checks if the provided column(s) have primary key constraints on them for the given table.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param schemaName The schema the table is on.
 * @param pkTableName The table to check the primary key constraint on. The database and schema name should not be part of the table name. 
 *  e.g. "SampleTable"
 * @param primaryKeyColumns The columns to check if they are part of the primary key constraint.
*/
void testPrimaryKeys(ServerType serverType, const string &schemaName, const string &pkTableName, const vector<string> &primaryKeyColumns);

/**
 * Checks if the provided column(s) have unique constraints on them for the given table.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The table to check unique constraints on. The database and schema name should not be part of the table name. 
 *  e.g. "SampleTable"
 * @param uniqueConstraintColumns The columns to check if they have a unique constraint for the table.
*/
void testUniqueConstraint(ServerType serverType, const string &tableName, const vector<string> &uniqueConstraintColumns);

/**
 * Verify the expected results for various comparison operators (=, >, <=, etc.).
 * Two different columns in the table are used by these comparison operators. E.g. COL1 >= COL2
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to test comparison operators with. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param col1Name Name of the first column used with comparison operators. 
 * @param col2Name Name of the second column used with comparison operators. 
 * @param col1Data Vector containing data in within the first column.
 * @param col2Data Vector containing data in within the second column.
 * @param operationsQuery Vector containing the operators to test the two columns against.
 * @param expectedResults Vector containing the expected results for each operation.
 * @param explicitCast Optional. Explicit cast to use `OPERATOR(sys.=)`. The default value is false.
 * @param explicitQuotes Optional. Explicit quotes around col2Name. The default value is false.
*/
void testComparisonOperators(ServerType serverType, const string &tableName, const string &col1Name, const string &col2Name, 
  const vector<string> &col1Data, const vector<string> &col2Data, const vector<string> &operationsQuery, const vector<vector<char>> &expectedResults, 
  bool explicitCast = false, bool explicitQuotes = false);

/**
 * Verify the expected results for various comparison functions (MIN, MAX, SUM, etc.).
 * Only a single column in the table is used by these comparison functions. E.g. MIN(COL1)
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to test comparison functions with. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param operationsQuery Vector containing the operators to test.
 * @param expectedResults Vector containing the expected results for each operation.
*/
void testComparisonFunctions(ServerType serverType, const string &tableName, const vector<string> &operationsQuery, const vector<string> &expectedResults);

/**
 *Verify the expected results for various arithmetic operators (+, -, *, etc.).
 * Two different columns in the table are used by these arithmetic operators. E.g. COL1 + COL2
 * The data on each row in the table will have multiple arithmetic operators performed on them. 
 * The expected results will be a 2D array.
 * e.g.
 *  {
 *    {ROW1_COL1_DATA + ROW1_COL2_DATA, ROW1_COL1_DATA - ROW1_COL2_DATA},
 *    {ROW2_COL1_DATA + ROW2_COL2_DATA, ROW2_COL1_DATA - ROW2_COL2_DATA}
 *  }
 * 
 * This non-templated version will expect the type to be SQL_C_CHAR and that the expected values
 * are strings.
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to test arithmetic operations with. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param numOfData Number of rows in the table.
 * @param operationsQuery Vector containing the operators to test.
 * @param expectedResults 2D vector containing the expected results for each operation.
 * 
 */
void testArithmeticOperators(ServerType serverType, const string &tableName, const string &orderByColumnName, int numOfData,
  const vector<string> &operationsQuery, const vector<vector<string>> &expectedResults);
  
/**
 * Verify the expected results for various string functions (LOWER, UPPER, TRIM, etc.).
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to test string functions with. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param operationsQuery Vector containing the function operators to test.
 * @param expectedResults 2D vector containing the expected results for each string function.
 * @param insertionSize Number of elements that was inserted into the table.
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
*/
void testStringFunctions(ServerType serverType, const string &tableName, const vector<string> &operationsQuery, const vector<vector<string>> &expectedResults, 
  const int insertionSize, const string &orderByColumnName);

/**
 * Verify the expected results for various comparison functions (MIN, MAX, SUM, etc.).
 * Only a single column in the table is used by these comparison functions. E.g. MIN(COL1)
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to test comparison functions with. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param type The C type identifier of the data that will be retrieved. e.g. SQL_C_SBIGINT
 * @param colResults A vector that will be used to store the results from each comparison function. 
 * @param bufferLen The length of the buffer. 
 * @param operationsQuery Vector containing the operators to test.
 * @param expectedResults Vector containing the expected results for each operation.
 * @param expectedLen A vector containing the expected length of all results from each operation. 
*/
template <typename T>
void testComparisonFunctions(ServerType serverType, const string &tableName, int type, const vector<T> &colResults, 
  int bufferLen, vector<string> operationsQuery, const vector<T> &expectedResults, const vector<long> &expectedLen);

/**
 * Verify the expected results for various arithmetic operators (+, -, *, etc.).
 * Two different columns in the table are used by these arithmetic operators. E.g. COL1 + COL2
 * The data on each row in the table will have multiple arithmetic operators performed on them. 
 * The expected results will be a 2D array.
 * e.g.
 *  {
 *    {ROW1_COL1_DATA + ROW1_COL2_DATA, ROW1_COL1_DATA - ROW1_COL2_DATA},
 *    {ROW2_COL1_DATA + ROW2_COL2_DATA, ROW2_COL1_DATA - ROW2_COL2_DATA}
 *  }
 * 
 * @param serverType The ODBC driver type to create the connection against. 
 * @param tableName The name of the table to test arithmetic operations with. Can include the database and/or schema name. e.g. "master_dbo.SampleTable"
 * @param orderByColumnName The column to order by when selecting all from the object. Useful for when there is a primary key
 *  column in the object to order by.
 * 
 * @param numOfData Number of rows in the table.
 * @param type The C type identifier of the data that will be retrieved. e.g. SQL_C_SBIGINT
 * @param colResults A vector that will be used to store the results from each comparison function. 
 * @param bufferLen The length of the buffer. 
 * @param operationsQuery Vector containing the operators to test.
 * @param expectedResults 2D vector containing the expected results for each operation.
 * @param expectedLen A vector containing the expected length of all results from each operation. 
*/
template <typename T>
void testArithmeticOperators(ServerType serverType, const string &tableName, const string &orderByColumnName, int numOfData, int type, 
  const vector<T> &colResults, int bufferLen, const vector<string> &operationsQuery, const vector<vector<T>> &expectedResults, const vector<long> &expectedLen);

/**
 * Return a vector based on a specific column of a 2D vector
 * 
 * @param vec The 2D vector to copy
 * @param col The column from the 2D vector to copy
 * 
 * @return vector which contains the elements of column 'col' in 'vec'
*/
vector<string> getVectorBasedOnColumn(const vector<vector<string>> &vec, const int &col);

/**
 * Formats a string to correspond to a numeric or decimal output
 * 
 * @param decimal 
 * @param scale The scale of the 
 * @param is_bbf True if we want it to correspond to Babelfish, false if we want the output to be formatted for postgres
 * @return string which is the formatted number
*/
string formatNumericWithScale(string decimal, const int &scale, const bool &is_bbf);

/**
 * Formats a vector of strings to correspond to a numeric or decimal output 
 * 
 * @param vec Vector that would be changed by reference
 * @param scale Scale of the numeric or decimal column
 * @param is_bbf True if the output is to correspond with Babelfish's result set,
 *    False for Postgres
*/
void formatNumericExpected(vector<string> &vec, const int &scale, const bool &is_bbf);

/**
 * Checks to see if the actual and expected values of two doubles
 * are equal or not (based on machine epsilon differences).
 * 
 * @param actual The actual value from the test
 * @param expect The expected value 
*/
void compareDoubleEquality(double actual, double expected);

/** Implementation of templated functions below **/
template <typename T>
vector<T> duplicateElements(vector<T> input) {
  std::vector<T> duplicated(input);
  duplicated.insert(duplicated.end(), input.begin(), input.end());
  return duplicated;
}

template <typename T>
void verifyValuesInObject(ServerType serverType, string objectName, string orderByColumnName, int type, T data, 
  int bufferLen, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedLen, int pkStartingValue) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  
  RETCODE rcode;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ConnectAndExecQuery(SelectStatement(objectName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedLen[i]);

      if (type == SQL_C_DOUBLE) {
        compareDoubleEquality(data, expectedInsertedValues[i]);
      }
      else {
        EXPECT_EQ(data, expectedInsertedValues[i]);
      }
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
}

template <typename T>
void testInsertionSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, int type, T data, int bufferLen, 
  const vector<string> &insertedValues, const vector<T> &expectedInsertedValues, const vector<long> &expectedLen, int pkStartingValue) {

  insertValuesInTable(serverType, tableName, insertedValues, true, pkStartingValue);
  verifyValuesInObject(serverType, tableName, orderByColumnName, type, data, bufferLen, 
    insertedValues, expectedInsertedValues, expectedLen, pkStartingValue);
}

template <typename T>
void testUpdateSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, const string &colNameToUpdate, int type, 
  T data, int bufferLen, const vector<string> &updatedValues, const vector<T> &expectedUpdatedValues, const vector<long> &expectedUpdatedLen, bool caseInsensitive) {
    
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  const int pkValue = 0;
  const int AFFECTED_ROWS_EXPECTED = 1;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));
  
  // Prepare update statement.
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(pkValue);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    update_col.push_back(pair<string, string>(colNameToUpdate, updatedValues[i]));
  }

  for (int i = 0; i < updatedValues.size(); i++) {
    // Update value multiple times
    odbcHandler.ExecQuery(UpdateTableStatement(tableName, vector<pair<string, string>>{update_col[i]}, UPDATE_WHERE_CLAUSE));

    rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(affectedRows, AFFECTED_ROWS_EXPECTED);

    odbcHandler.CloseStmt();

    // Assert that updated value is present
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string>{orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, pkValue);
    
    if (updatedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedUpdatedLen[i]);

      if (type == SQL_C_DOUBLE) {
        compareDoubleEquality(data, expectedUpdatedValues[i]);
      }
      else {
        EXPECT_EQ(data, expectedUpdatedValues[i]);
      }
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }
}

template <typename T>
void testUpdateFail(ServerType serverType, const string &tableName, const string &orderByColumnName, const string &colNameToUpdate, int type, 
  T data, int bufferLen, const vector<T> &expectedInsertedValues, const vector<long> &expectedInsertedLen, const vector<string> &updatedValues) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  const int pkValue = 0;

  RETCODE rcode;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  // Prepare update statement.
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(pkValue);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    update_col.push_back(pair<string, string>(colNameToUpdate, updatedValues[i]));
  }

  for (int i = 0; i < updatedValues.size(); i++) {
    // Update value multiple times
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)UpdateTableStatement(tableName, update_col, UPDATE_WHERE_CLAUSE).c_str(), SQL_NTS);
    EXPECT_EQ(rcode, SQL_ERROR);
    odbcHandler.CloseStmt();

    // Assert that no values changed
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string>{orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, pkValue);
    EXPECT_EQ(data_len, expectedInsertedLen[0]);

    if (type == SQL_C_DOUBLE) {
      compareDoubleEquality(data, expectedInsertedValues[0]);
    }
    else {
      EXPECT_EQ(data, expectedInsertedValues[0]);
    }
    EXPECT_EQ(data, expectedInsertedValues[0]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);

    odbcHandler.CloseStmt();
  }
}

template <typename T>
void testComparisonFunctions(ServerType serverType, const string &tableName, int type, const vector<T> &colResults, 
  int bufferLen, vector<string> operationsQuery, const vector<T> &expectedResults, const vector<long> &expectedLen) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;

  const int NUM_OF_OPERATIONS = operationsQuery.size();
  SQLLEN col_len[NUM_OF_OPERATIONS];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, type, (SQLPOINTER)&colResults[i], bufferLen, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  // Make sure values with operations performed on them output correct result
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_SUCCESS);
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    EXPECT_EQ(col_len[i], expectedLen[i]);

    if (type == SQL_C_DOUBLE) {
        compareDoubleEquality(colResults[i], expectedResults[i]);
    }
    else {
      EXPECT_EQ(colResults[i], expectedResults[i]);
    } 
  }
  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

template <typename T>
void testArithmeticOperators(ServerType serverType, const string &tableName, const string &orderByColumnName, int numOfData, int type, 
  const vector<T> &colResults, int bufferLen, const vector<string> &operationsQuery, const vector<vector<T>> &expectedResults, const vector<long> &expectedLen) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;

  const int NUM_OF_OPERATIONS = operationsQuery.size();
  SQLLEN col_len[NUM_OF_OPERATIONS];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, type, (SQLPOINTER)&colResults[i], bufferLen, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  // Make sure values with operations performed on them output correct result
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{orderByColumnName}));
  
  for (int i = 0; i < numOfData; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) {
      EXPECT_EQ(col_len[j], expectedLen[j]);

      if (type == SQL_C_DOUBLE) {
        compareDoubleEquality(colResults[j], expectedResults[i][j]);
      }
      else {
        EXPECT_EQ(colResults[j], expectedResults[i][j]);
      }
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

#endif
