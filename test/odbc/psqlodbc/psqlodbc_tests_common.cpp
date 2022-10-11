#include "psqlodbc_tests_common.h"

// helper function to initialize insert string (1, "", "", ""), etc.
string InitializeInsertString(const vector<vector<string>> &insertedValues, int numCols) {

  string insertString{};
  string comma{};

  for (int i = 0; i< insertedValues.size(); ++i) {

    insertString += comma + "(";
    string comma2{};

    for (int j = 0; j < numCols; j++) {
      if (insertedValues[i][j] != "NULL")
        insertString += comma2 + "'" + insertedValues[i][j] + "'";
      else
        insertString += comma2 + insertedValues[i][j];
      comma2 = ",";
    }

    insertString += ")";
    comma = ",";
  }
  return insertString;
}

void testCommonColumnAttributes(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected) {
  const int NUM_COL = tableColumns.size();
  const int BUFFER_SIZE = 256;
  char name[BUFFER_SIZE];

  RETCODE rcode;
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Select * From Table to ensure that it exists
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  for (int i = 1; i <= NUM_COL; i++) {
    // Make sure column attributes are correct
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(length, lengthExpected[i-1]);
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(precision, precisionExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(scale, scaleExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), nameExpected[i-1]);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testCommonCharColumnAttributes(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected, vector<int> caseSensitivityExpected, vector<string> prefixExpected, vector<string> suffixExpected) {
  const int NUM_COL = tableColumns.size();
  const int BUFFER_SIZE = 256;
  char name[BUFFER_SIZE];
  
  RETCODE rcode;
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;
  SQLLEN isCaseSensitive;

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Select * From Table to ensure that it exists
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  for (int i = 1; i <= NUM_COL; i++) {
    // Make sure column attributes are correct
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(length, lengthExpected[i-1]);
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(precision, precisionExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(scale, scaleExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), nameExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_CASE_SENSITIVE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &isCaseSensitive); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(isCaseSensitive, caseSensitivityExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_PREFIX, // Get the prefix of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), prefixExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_SUFFIX, // Get the suffix character of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS); 
    ASSERT_EQ(string(name), suffixExpected[i-1]);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testTableCreationFailure(OdbcHandler& odbcHandler, string tableName, vector<vector<pair<string, string>>> invalidColumns) {
  RETCODE rcode;

  odbcHandler.Connect();
  odbcHandler.AllocateStmtHandle();

  for (int i = 0; i < invalidColumns.size(); i++) {
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) CreateTableStatement(tableName, invalidColumns[i]).c_str(),
                        SQL_NTS);

    ASSERT_EQ(rcode, SQL_ERROR);
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testInsertionSuccess(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues) {
  const int NUM_COL = tableColumns.size();
  const int BUFFER_LENGTH = 8192;
  char colResults[NUM_COL][BUFFER_LENGTH];

  RETCODE rcode;
  SQLLEN affectedRows;
  SQLLEN colLen[NUM_COL];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};
  for (int i = 0; i < NUM_COL; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &colResults[i], BUFFER_LENGTH, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insertString = InitializeInsertString(insertedValues, NUM_COL);
  
  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); ++i) {

    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    for (int j = 0; j < NUM_COL; j++) {
      if (insertedValues[i][j] != "NULL") {
        ASSERT_EQ(string(colResults[j]), expectedInsertedValues[i][j]);
        ASSERT_EQ(colLen[j], expectedInsertedValues[i][j].size());
      } 
      else 
        ASSERT_EQ(colLen[j], SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testInsertionFailure(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<vector<string>> insertedValues) {
  const int NUM_COL = tableColumns.size();
  const int BUFFER_LENGTH = 8192;
  char colResults[NUM_COL][BUFFER_LENGTH];

  RETCODE rcode;
  SQLLEN colLen[NUM_COL];
  SQLLEN affectedRows;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COL; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &colResults[i], BUFFER_LENGTH, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert invalid values in table and assert error
   for (int i = 0; i < insertedValues.size(); i++) {

    string insertString = "(";
    string comma{};

    // create insertString (1, ..., ..., ...)
    for (int j = 0; j < NUM_COL; j++) {
      insertString += comma + "'" + insertedValues[i][j] + "'";
      comma = ",";
    }
    insertString += ")";

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(tableName, insertString).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
    odbcHandler.CloseStmt();
  }

  // Select all from the table to make sure nothing was inserted
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testUpdateSuccess(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, vector<string> columnNames, string orderByColumnName, string keyToUpdate, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues, vector<vector<string>> updatedValues, vector<vector<string>> expectedUpdatedValues) {
  const int NUM_COL = tableColumns.size();
  const int BUFFER_LENGTH = 8192;
  const int AFFECTED_ROWS_EXPECTED = 1;
  char colResults[NUM_COL][BUFFER_LENGTH];

  RETCODE rcode;
  SQLLEN colLen[NUM_COL];
  SQLLEN affectedRows;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COL; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &colResults[i], BUFFER_LENGTH, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insertString = InitializeInsertString(insertedValues, NUM_COL);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, insertedValues.size());

  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); ++i) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COL; j++) {
      ASSERT_EQ(string(colResults[j]), expectedInsertedValues[i][j]);
      ASSERT_EQ(colLen[j], expectedInsertedValues[i][j].size());
    }
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  for (int i = 0; i < updatedValues.size(); i++) {

    vector<pair<string,string>> update_col;
    // setup update column
    for (int j = 0; j < NUM_COL; j++) {
      string value = string("'") + updatedValues[i][j] + string("'");
      update_col.push_back(pair<string,string>(columnNames[j], value));
    }

    odbcHandler.ExecQuery(UpdateTableStatement(tableName, update_col, orderByColumnName + "='" + keyToUpdate + "'"));

    rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(affectedRows, AFFECTED_ROWS_EXPECTED);

    odbcHandler.CloseStmt();

    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    for (int j = 0; j < NUM_COL; j++) {
      ASSERT_EQ(string(colResults[j]), expectedUpdatedValues[i][j]);
      ASSERT_EQ(colLen[j], expectedUpdatedValues[i][j].size());
    }

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testUpdateFail(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, vector<string> columnNames, string orderByColumnName, string keyToUpdate, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues, vector<vector<string>> updatedValues) {
  const int NUM_COL = tableColumns.size();
  const int BUFFER_LENGTH = 8192;
  const int AFFECTED_ROWS_EXPECTED = 1;
  char colResults[NUM_COL][BUFFER_LENGTH];

  RETCODE rcode;
  SQLLEN colLen[NUM_COL];
  SQLLEN affectedRows;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COL; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &colResults[i], BUFFER_LENGTH, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insertString = InitializeInsertString(insertedValues, NUM_COL);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, insertedValues.size());

  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); ++i) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COL; j++) {
      ASSERT_EQ(string(colResults[j]), expectedInsertedValues[i][j]);
      ASSERT_EQ(colLen[j], expectedInsertedValues[i][j].size());
    }
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  for (int i = 0; i < updatedValues.size(); i++)
  {
    odbcHandler.CloseStmt();
    vector<pair<string,string>> update_col;

    // setup update column
    for (int j = 0; j < NUM_COL; j++) {
      string value = string("'") + updatedValues[i][j] + string("'");
      update_col.push_back(pair<string,string>(columnNames[j], value));
    }

    // Update value and assert an error is present
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                          (SQLCHAR*) UpdateTableStatement(tableName, update_col, orderByColumnName + "='" + keyToUpdate + "'").c_str(), 
                          SQL_NTS);

    ASSERT_EQ(rcode, SQL_ERROR);

    odbcHandler.CloseStmt();

    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    // Assert that the results did not change
    for (int j = 0; j < NUM_COL; j++) {
      ASSERT_EQ(string(colResults[j]), expectedInsertedValues[i][j]);
      ASSERT_EQ(colLen[j], expectedInsertedValues[i][j].size());
    }
  }
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testViewCreation(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string viewName, string orderByColumnName, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues) {
  const int NUM_COL = tableColumns.size();
  const string VIEW_QUERY = "SELECT * FROM " + tableName;
  const int BUFFER_LENGTH = 8192;
  char colResults[NUM_COL][BUFFER_LENGTH];

  RETCODE rcode;
  SQLLEN colLen[NUM_COL];
  SQLLEN affectedRows;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COL; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &colResults[i], BUFFER_LENGTH, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insertString = InitializeInsertString(insertedValues, NUM_COL);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, insertedValues.size());

  odbcHandler.CloseStmt();

  // Create view
  odbcHandler.ExecQuery(CreateViewStatement(viewName, VIEW_QUERY));
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(viewName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); ++i) {

    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_COL; j++) {

      if (insertedValues[i][j] != "NULL") {

        ASSERT_EQ(string(colResults[j]), expectedInsertedValues[i][j]);
        ASSERT_EQ(colLen[j], expectedInsertedValues[i][j].size());
      } 
      else {
        ASSERT_EQ(colLen[j], SQL_NULL_DATA);
      }
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("VIEW", viewName));
}

void testPrimaryKeys(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string schemaName, string pkTableName, vector<string> primaryKeyColumns, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues) {
  const int NUM_COL = tableColumns.size();
  const int PK_BYTES_EXPECTED = 4;
  const int DATA_BYTES_EXPECTED = 1;
  int pk;
  unsigned char data;

  RETCODE rcode;
  SQLLEN affectedRows;

  string table_constraints{"PRIMARY KEY ("};
  string comma{};
  for (int i = 0; i < primaryKeyColumns.size(); i++) {
    table_constraints += comma + primaryKeyColumns[i];
    comma = ",";
  }
  table_constraints += ")";

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns, table_constraints));
  odbcHandler.CloseStmt();

  // Check if composite key still matches after creation
  const int CHARSIZE = 255;
  char table_name[CHARSIZE];
  char column_name[CHARSIZE];
  int key_sq{};
  char pk_name[CHARSIZE];

  vector<tuple<int, int, SQLPOINTER, int>> constraints_bind_columns = {
    {3, SQL_C_CHAR, table_name, CHARSIZE},
    {4, SQL_C_CHAR, column_name, CHARSIZE},
    {5, SQL_C_ULONG, &key_sq, CHARSIZE},
    {6, SQL_C_CHAR, pk_name, CHARSIZE}
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(constraints_bind_columns));

  rcode = SQLPrimaryKeys(odbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR*) schemaName.c_str(), SQL_NTS, (SQLCHAR*) pkTableName.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  int curr_sq {0};
  for (auto columnName : primaryKeyColumns) {
    ++curr_sq;
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    ASSERT_EQ(string(table_name), pkTableName);
    ASSERT_EQ(string(column_name), columnName);
    ASSERT_EQ(key_sq, curr_sq);
  }
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  const int BUFFER_LENGTH = 8192;

  char colResults[NUM_COL][BUFFER_LENGTH];
  SQLLEN colLen[NUM_COL];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COL; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &colResults[i], BUFFER_LENGTH, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insertString = InitializeInsertString(insertedValues, NUM_COL);

  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, insertedValues.size());

  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); ++i) {

    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 1; j < NUM_COL; j++) {
      if (insertedValues[i][j] != "NULL") {
        ASSERT_EQ(string(colResults[j]), expectedInsertedValues[i][j]);
        ASSERT_EQ(colLen[j], expectedInsertedValues[i][j].size());
      } 
      else 
        ASSERT_EQ(colLen[j], SQL_NULL_DATA);
    }
  }

  odbcHandler.CloseStmt();

  // Attempt to insert duplicate values that violates composite constraint and assert that they all fail
  insertString.append(",");
  insertString = insertString.append(insertString);

  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(tableName, insertString).c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testUniqueConstraint(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string uniqueConstraintTableName, vector<string> uniqueConstraintColumns, vector<vector<string>> insertedValues, vector<vector<string>> expectedInsertedValues) {
  const int NUM_COL = tableColumns.size();
  const int CHARSIZE = 255;
  char columnName[CHARSIZE];

  RETCODE rcode;
  SQLLEN affectedRows;

  string tableConstraints{"UNIQUE("};
  string comma{};
  for (int i = 0; i < uniqueConstraintColumns.size(); i++) {
    tableConstraints += comma + uniqueConstraintColumns[i];
    comma = ",";
  }
  tableConstraints += ")";

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns, tableConstraints));
  odbcHandler.CloseStmt();

  vector<tuple<int, int, SQLPOINTER, int>> constraints_bind_columns = {
    {1, SQL_C_CHAR, columnName, CHARSIZE}
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(constraints_bind_columns));

  const string UNIQUE_QUERY = 
    "SELECT C.COLUMN_NAME FROM "
    "INFORMATION_SCHEMA.TABLE_CONSTRAINTS T "
    "JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C "
    "ON C.CONSTRAINT_NAME=T.CONSTRAINT_NAME "
    "WHERE "
    "C.TABLE_NAME='" + tableName.substr(tableName.find('.') + 1, tableName.length()) + "' "
    "AND T.CONSTRAINT_TYPE='UNIQUE'";
  
  odbcHandler.ExecQuery(UNIQUE_QUERY);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(string(columnName), uniqueConstraintColumns[0]);
  odbcHandler.CloseStmt();

  const int BUFFER_LENGTH = 8192;

  char colResults[NUM_COL][BUFFER_LENGTH];
  SQLLEN colLen[NUM_COL];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns{};

  // initialize bind_columns
  for (int i = 0; i < NUM_COL; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN*> tuple_to_insert(i+1, SQL_C_CHAR, (SQLPOINTER) &colResults[i], BUFFER_LENGTH, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insertString = InitializeInsertString(insertedValues, NUM_COL);

  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, insertedValues.size());

  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); ++i) {

    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 1; j < NUM_COL; j++) {
      if (insertedValues[i][j] != "NULL") {
        ASSERT_EQ(string(colResults[j]), expectedInsertedValues[i][j]);
        ASSERT_EQ(colLen[j], expectedInsertedValues[i][j].size());
      } 
      else 
        ASSERT_EQ(colLen[j], SQL_NULL_DATA);
    }
  }

  odbcHandler.CloseStmt();

  // Attempt to insert duplicate values that violates composite constraint and assert that they all fail
  insertString.append(",");
  insertString = insertString.append(insertString);

  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(tableName, insertString).c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testComparisonOperators(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string col1Name, string col2Name, vector<string> col1Data, vector<string> col2Data) {
  const int BUFFER_SIZE = 256;
  const int BYTES_EXPECTED = 1;

  RETCODE rcode;
  SQLLEN affectedRows;

  const int NUM_OF_DATA = col2Data.size();

  vector<string> OPERATIONS_QUERY = {
    col1Name + "=" + col2Name,
    col1Name + "<>" + col2Name,
    col1Name + "<" + col2Name,
    col1Name + "<=" + col2Name,
    col1Name + ">" + col2Name,
    col1Name + ">=" + col2Name
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expectedResults
  vector<vector<char>> expectedResults = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expectedResults.push_back({});
    const char *data1 = col1Data[i].data();
    const char *data2 = col2Data[i].data();
    expectedResults[i].push_back(strcmp(data1, data2) == 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(data1, data2) != 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(data1, data2) < 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(data1, data2) <= 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(data1, data2) > 0 ? '1' : '0');
    expectedResults[i].push_back(strcmp(data1, data2) >= 0 ? '1' : '0');
  }

  char colResults[NUM_OF_OPERATIONS];
  SQLLEN colLen[NUM_OF_OPERATIONS];
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&colResults[i], BUFFER_SIZE, &colLen[i]);
    BIND_COLUMNS.push_back(tuple_to_insert);
  }

  string insertString{};
  string comma{};

  // insertString initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(\'" + col1Data[i] + "\',\'" + col2Data[i] + "\')";
    comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_DATA; i++) {
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(SelectStatement(tableName, OPERATIONS_QUERY, vector<string>{}, col1Name + "=\'" + col1Data[i] + "\'"));
    ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) {
      ASSERT_EQ(colLen[j], BYTES_EXPECTED);
      ASSERT_EQ(colResults[j], expectedResults[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testComparisonFunctions(OdbcHandler& odbcHandler, string tableName, vector<pair<string, string>> tableColumns, string colName, vector<string> insertedData, vector<string> expectedResults) {
  const int BUFFER_SIZE = 256;
  const int BYTES_EXPECTED = 1;
  SQLLEN affectedRows;

  RETCODE rcode;

  const int NUM_OF_DATA = insertedData.size();

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + colName + ")",
    "MAX(" + colName + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expectedResults
  vector<string> expected = {};
  int min_expected = 0, max_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    const char *currMin = expectedResults[min_expected].data();
    const char *currMax = expectedResults[max_expected].data();
    const char *curr = expectedResults[i].data();

    min_expected = strcmp(curr, currMin) < 0 ? i : min_expected;
    max_expected = strcmp(curr, currMax) > 0 ? i : min_expected;
  }
  expected.push_back(expectedResults[min_expected]);
  expected.push_back(expectedResults[max_expected]);

  char colResults[NUM_OF_OPERATIONS][BUFFER_SIZE];
  SQLLEN colLen[NUM_OF_OPERATIONS];
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&colResults[i], BUFFER_SIZE, &colLen[i]);
    BIND_COLUMNS.push_back(tuple_to_insert);
  }

  string insertString{};
  string comma{};

  // insertString initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insertString += comma + "(" + std::to_string(i) + ",\'" + insertedData[i] + "\')";
    comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affectedRows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(SelectStatement(tableName, OPERATIONS_QUERY, vector<string>{}));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    ASSERT_EQ(colLen[i], expected[i].length());
    ASSERT_EQ(string(colResults[i]), expected[i]);
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}
