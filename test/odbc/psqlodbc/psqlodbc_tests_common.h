#ifndef PSQLODBC_TESTS_COMMON_H
#define PSQLODBC_TESTS_COMMON_H

#include <string>
#include <vector>

#include "../src/odbc_handler.h"
#include "../src/query_generator.h"
#include <gtest/gtest.h>
#include <sqlext.h>

using std::vector;
using std::string;
using std::pair;

string InitializeInsertString(const vector<vector<string>> &insertedValues, int numCols);

void testCommonColumnAttributes(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected);

void testCommonCharColumnAttributes(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected, vector<int> caseSensitivityExpected, vector<string> prefixExpected, vector<string> suffixExpected);

void testTableCreationFailure(OdbcHandler& odbcHandler, string tableName, vector<vector<pair<string, string>>> invalidColumns);

void testInsertionSuccess(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues);

void testInsertionFailure(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<vector<string>> insertedValues);

void testUpdateSuccess(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, vector<string> columnNames, string orderByColumnName, string keyToUpdate, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues, vector<vector<string>> updatedValues, vector<vector<string>> expectedUpdatedValues);

void testUpdateFail(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, vector<string> columnNames, string orderByColumnName, string keyToUpdate, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues, vector<vector<string>> updatedValues);

void testViewCreation(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string viewName, string orderByColumnName, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues);

void testPrimaryKeys(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string schemaName, string pkTableName, vector<string> primaryKeyColumns, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues);

void testUniqueConstraint(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string uniqueConstraintTableName, vector<string> uniqueConstraintColumns, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues);

void testComparisonOperators(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string col1Name, string col2Name, vector<string> col1Data, vector<string> col2Data);

void testComparisonFunctions(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string colName, vector<string> insertedData, vector<string> expectedResults);

#endif
