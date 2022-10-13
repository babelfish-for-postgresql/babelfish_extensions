#include "psqlodbc_tests_common.h"

// helper function to initialize insert string (1, "", "", ""), etc.
string InitializeInsertString(const vector<string> &insertedValues, bool isNumericInsert) {

  string insertString{};
  string comma{};
  if (isNumericInsert) {
    for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
    }
    return insertString;
  }

  for (int i = 0; i < insertedValues.size(); i++) {
    if (insertedValues[i] == "NULL") {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
    }
    else {
      insertString += comma + "(" + std::to_string(i) + "," + "'" + insertedValues[i] + "'" + ")";
      comma = ",";
    }
  }
  return insertString;
}


void testCommonColumnAttributes(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

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
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(length, lengthExpected[i-1]);
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(precision, precisionExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(scale, scaleExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(string(name), nameExpected[i-1]);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testCommonCharColumnAttributes(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected, vector<int> caseSensitivityExpected, vector<string> prefixExpected, vector<string> suffixExpected) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  
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
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(length, lengthExpected[i-1]);
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(precision, precisionExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(scale, scaleExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(string(name), nameExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_CASE_SENSITIVE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &isCaseSensitive); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(isCaseSensitive, caseSensitivityExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_PREFIX, // Get the prefix of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(string(name), prefixExpected[i-1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_SUFFIX, // Get the suffix character of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    EXPECT_EQ(rcode, SQL_SUCCESS); 
    EXPECT_EQ(string(name), suffixExpected[i-1]);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testTableCreationFailure(string tableName, vector<vector<pair<string, string>>> invalidColumns) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  RETCODE rcode;

  odbcHandler.Connect();
  odbcHandler.AllocateStmtHandle();

  for (int i = 0; i < invalidColumns.size(); i++) {
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) CreateTableStatement(tableName, invalidColumns[i]).c_str(),
                        SQL_NTS);

    EXPECT_EQ(rcode, SQL_ERROR);
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testInsertionSuccessChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> insertedValues, vector<string> expectedInsertedValues) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  
  const int BUFFER_LENGTH = 8192;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;
  char data[BUFFER_LENGTH];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insertString = InitializeInsertString(insertedValues, false);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedValues[i].size());
      EXPECT_EQ(data, expectedInsertedValues[i]);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testInsertionFailure(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> invalidInsertedValues, bool isNumericInsert) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  RETCODE rcode;

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert invalid values in table and assert error
   for (int i = 0; i < invalidInsertedValues.size(); i++) {
    string insertString{};

    if (isNumericInsert) {
      string insertString = "(" + std::to_string(i) + "," + invalidInsertedValues[i] + ")";
    }
    else {
      string insertString = "(" + std::to_string(i) + "," + "'" + invalidInsertedValues[i] + "'" + ")";
    }

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(tableName, insertString).c_str(), SQL_NTS);
    EXPECT_EQ(rcode, SQL_ERROR);
  }

  // Select all from the table to make sure nothing was inserted
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testUpdateSuccessChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string colNameToUpdate, vector<string> insertedValues, vector<string> expectedInsertedValues, vector<string> updatedValues, vector<string> expectedUpdatedValues) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  
  const int AFFECTED_ROWS_EXPECTED = 1;
  const int BUFFER_LENGTH = 8192;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;
  char data[BUFFER_LENGTH];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insertString = InitializeInsertString(insertedValues, false);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedValues[i].size());
      EXPECT_EQ(data, expectedInsertedValues[i]);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();

  // Test updating the row. 
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(0);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    string valueToUpdate = "'" + updatedValues[i] + "'";
    update_col.push_back(pair<string, string>(colNameToUpdate, valueToUpdate));
  }

  for (int i = 0; i < updatedValues.size(); i++) {

    odbcHandler.ExecQuery(UpdateTableStatement(tableName, vector<pair<string, string>>{update_col[i]}, UPDATE_WHERE_CLAUSE));

    rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(affectedRows, AFFECTED_ROWS_EXPECTED);

    odbcHandler.CloseStmt();

    // Assert that updated value is present
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string>{orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, 0);
    EXPECT_EQ(data_len, expectedUpdatedValues[i].size());
    EXPECT_EQ(data, expectedUpdatedValues[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testUpdateFailChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string colNameToUpdate, vector<string> insertedValues, vector<string> expectedInsertedValues, vector<string> updatedValues) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  
  const int BUFFER_LENGTH = 8192;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;
  char data[BUFFER_LENGTH];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insertString = InitializeInsertString(insertedValues, false);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedValues[i].size());
      EXPECT_EQ(data, expectedInsertedValues[i]);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();

  // Test updating the row. 
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(0);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    string valueToUpdate = "'" + updatedValues[i] + "'";
    update_col.push_back(pair<string, string>(colNameToUpdate, valueToUpdate));
  }

  for (int i = 0; i < updatedValues.size(); i++) {

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)UpdateTableStatement(tableName, update_col, UPDATE_WHERE_CLAUSE).c_str(), SQL_NTS);
    EXPECT_EQ(rcode, SQL_ERROR);
    odbcHandler.CloseStmt();

    // Assert that no values changed
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string>{orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, 0);
    EXPECT_EQ(data_len, expectedInsertedValues[i].size());
    EXPECT_EQ(data, expectedInsertedValues[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);

    odbcHandler.CloseStmt();
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testViewCreationChar(string viewName, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> insertedValues, vector<string> expectedInsertedValues) {
  
  const string VIEW_QUERY = "SELECT * FROM " + tableName;

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const int BUFFER_LENGTH = 8192;
  char data[BUFFER_LENGTH];

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insertString = InitializeInsertString(insertedValues, false);

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Create view
  odbcHandler.ExecQuery(CreateViewStatement(viewName, VIEW_QUERY));
  odbcHandler.CloseStmt();

  // Select all from the view and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(viewName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedValues[i].size());
      EXPECT_EQ(data, expectedInsertedValues[i]);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("VIEW", viewName));
  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testPrimaryKeysChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string schemaName, string pkTableName, vector<string> primaryKeyColumns, vector<string> insertedValues, vector<string> expectedInsertedValues) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const int BUFFER_SIZE = 256;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  string table_constraints{"PRIMARY KEY ("};
  string comma{};
  for (int i = 0; i < primaryKeyColumns.size(); i++) {
    table_constraints += comma + primaryKeyColumns[i];
    comma = ",";
  }
  table_constraints += ")";

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns, table_constraints));
  odbcHandler.CloseStmt();

  char table_name[BUFFER_SIZE];
  char column_name[BUFFER_SIZE];
  int key_sq{};
  char pk_name[BUFFER_SIZE];

  const vector<tuple<int, int, SQLPOINTER, int>> CONSTRAINTS_BIND_COLUMNS = {
    {3, SQL_C_CHAR, table_name, BUFFER_SIZE},
    {4, SQL_C_CHAR, column_name, BUFFER_SIZE},
    {5, SQL_C_ULONG, &key_sq, BUFFER_SIZE},
    {6, SQL_C_CHAR, pk_name, BUFFER_SIZE}
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(CONSTRAINTS_BIND_COLUMNS));

  rcode = SQLPrimaryKeys(odbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR *)schemaName.c_str(), SQL_NTS, (SQLCHAR *)pkTableName.c_str(), SQL_NTS);
  EXPECT_EQ(rcode, SQL_SUCCESS);

  int curr_sq{0};
  for (auto columnName : primaryKeyColumns) {
    ++curr_sq;
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);

    EXPECT_EQ(string(table_name), pkTableName);
    EXPECT_EQ(string(column_name), columnName);
    EXPECT_EQ(key_sq, curr_sq);
  }
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  const int BUFFER_LENGTH = 8192;
  char data[BUFFER_LENGTH];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insertString = InitializeInsertString(insertedValues, false);

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedValues[i].size());
      EXPECT_EQ(data, expectedInsertedValues[i]);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testUniqueConstraintChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> uniqueConstraintColumns, vector<string> insertedValues, vector<string> expectedInsertedValues) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const int BUFFER_SIZE = 256;
  const int CHARSIZE = 255;
  char columnName[CHARSIZE];

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  string tableConstraints{"UNIQUE("};
  string comma{};
  for (int i = 0; i < uniqueConstraintColumns.size(); i++) {
    tableConstraints += comma + uniqueConstraintColumns[i];
    comma = ",";
  }
  tableConstraints += ")";

  // Create table
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
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(string(columnName), uniqueConstraintColumns[0]);
  odbcHandler.CloseStmt();

  const int BUFFER_LENGTH = 8192;
  char data[BUFFER_LENGTH];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_LENGTH, &data_len}
  };

  string insertString = InitializeInsertString(insertedValues, false);

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedValues[i].size());
      EXPECT_EQ(data, expectedInsertedValues[i]);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testComparisonOperators(string tableName, vector<pair<string, string>> tableColumns, string col1Name, string col2Name, vector<string> col1Data, vector<string> col2Data, vector<string> operationsQuery, vector<vector<char>> expectedResults) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  
  const int BUFFER_SIZE = 256;
  const int BYTES_EXPECTED = 1;
  const int NUM_OF_DATA = col2Data.size();
  const int NUM_OF_OPERATIONS = operationsQuery.size();

  RETCODE rcode;
  SQLLEN affectedRows;

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
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_DATA; i++) {
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}, col1Name + "=\'" + col1Data[i] + "\'"));
    ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) {
      EXPECT_EQ(colLen[j], BYTES_EXPECTED);
      EXPECT_EQ(colResults[j], expectedResults[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

void testComparisonFunctionsChar(string tableName, vector<pair<string, string>> tableColumns, vector<string> insertedData,  vector<string> operationsQuery, vector<string> expectedResults) {
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  const int BUFFER_SIZE = 256;
  const int BYTES_EXPECTED = 1;
  SQLLEN affectedRows;

  RETCODE rcode;

  const int NUM_OF_DATA = insertedData.size();
  const int NUM_OF_OPERATIONS = operationsQuery.size();

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
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_SUCCESS);
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    EXPECT_EQ(colLen[i], expectedResults[i].length());
    EXPECT_EQ(string(colResults[i]), expectedResults[i]);
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}
