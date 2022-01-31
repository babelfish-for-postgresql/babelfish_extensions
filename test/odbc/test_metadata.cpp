#include "odbc_handler.h"
#include "database_objects.h"
#include "query_generator.h"

#include <gtest/gtest.h>
#include <sqlext.h>

#include <vector>
#include <utility>
#include <tuple>

using std::vector;
using std::map;
using std::pair;
using std::tuple;

class Metadata: public testing::Test {

  protected:
    static void SetUpTestSuite() {
    }

    static void TearDownTestSuite() {
    }
};

void GetCurrentUser(char* current_user, const int CHARSIZE) {

  OdbcHandler odbcHandler;
  RETCODE rcode;

  odbcHandler.ConnectAndExecQuery("SELECT CURRENT_USER");
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_CHAR, current_user, CHARSIZE, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Helper function. It fetches data from a column indicated and checks if the retrieved value matches a key in the given map.
// If yes, the corresponding map value is set to true.
void FetchAndMatchValues(OdbcHandler& odbcHandler, map<string, bool> &values, int column) {

  RETCODE rcode;
  SQLLEN bufferLen = 2048;  // Is this sufficient length in general? Perhaps the bufferLen could be passed as function parameter
  char buffer[bufferLen];
  SQLLEN indicator = SQL_NO_TOTAL; //it seems that the indicator is required by the SQL server driver to be passed to SQLGetData in some cases, even though not used here
 
  while((rcode = SQLFetch(odbcHandler.GetStatementHandle())) == SQL_SUCCESS) {
    rcode = SQLGetData(odbcHandler.GetStatementHandle(), column, SQL_C_CHAR, buffer, bufferLen, &indicator);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

    auto value = values.find(string(buffer));
    if (value != values.end()) {
        value->second = true;
    }  
  }

  ASSERT_EQ(rcode, SQL_NO_DATA);
}

// Common code for SQLPrimaryKeys tests
void SQLPrimaryKeysTestCommon(const string &pktable_name, 
  const vector<pair <string, string>> &table_columns,
  const string &constraint_name,
  const vector<string> &pk_columns) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  
  const int CHARSIZE = 255;
  char table_name[CHARSIZE];
  char column_name[CHARSIZE];
  int key_sq{};
  char pk_name[CHARSIZE];

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {3, SQL_C_CHAR, table_name, CHARSIZE},
    {4, SQL_C_CHAR, column_name, CHARSIZE},
    {5, SQL_C_ULONG, &key_sq, CHARSIZE},
    {6, SQL_C_CHAR, pk_name, CHARSIZE}
  };
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(pktable_name, table_columns, PrimaryKeyConstraintSpec(constraint_name, pk_columns)));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLPrimaryKeys(odbcHandler.GetStatementHandle(), NULL, 0, NULL, 0, (SQLCHAR*) pktable_name.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  int curr_sq {0};
  for (auto columnName : pk_columns) {
    ++curr_sq;
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

    ASSERT_EQ(string(table_name), pktable_name);
    ASSERT_EQ(string(column_name), columnName);
    ASSERT_EQ(key_sq, curr_sq);
    ASSERT_EQ(pk_name, constraint_name);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

// Common code for SQLForeignKeys tests
// The refer_pk_table parameter indicates whether the call to SQLForeignKeys should specify
// primary key table (the referenced table) or the foreign key table (the referencing table).
void SQLForeignKeysTestCommon(bool refer_pk_table) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  const int CHARSIZE = 255;
  char pk_table[CHARSIZE];
  char fk_table[CHARSIZE];
  char pk_col[CHARSIZE];
  char fk_col[CHARSIZE];
  char fk_name[CHARSIZE];
  char pk_name[CHARSIZE];
  SQLSMALLINT update_rule;
  SQLSMALLINT delete_rule;

  const string FK_TABLE_PRIMARY = "primary_key_table";
  const string FK_TABLE_FOREIGN = "foreign_key_table";
  const string T1_COL1 = "id";
  const string T1_CONSTRAINT_NAME = "SQLFK_PK_CONSTRAINT1";
  const string T2_COL2 = "id_f";
  const string T2_CONSTRAINT_NAME = "SQLFK_FK_CONSTRAINT1";

  // columns for the 'primary key' test table
  vector<pair<string,string>> pktColumns = {
    {T1_COL1, "INT"}
  };
  // primary key column names
  vector<string> pkColumns {{T1_COL1}};
  
  // columns for the 'foreign key' test table
  vector<pair<string,string>> fktColumns = {
    {T2_COL2, "INT"}
  };
  // foreign key column names
  vector<string> fkColumns {{T2_COL2}};

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {3, SQL_C_CHAR, pk_table, CHARSIZE},
    {4, SQL_C_CHAR, pk_col, CHARSIZE},
    {7, SQL_C_CHAR, fk_table, CHARSIZE},
    {8, SQL_C_CHAR, fk_col, CHARSIZE},
    {10, SQL_C_SHORT, &update_rule, 0},
    {11, SQL_C_SHORT, &delete_rule, 0},
    {12, SQL_C_CHAR, fk_name, CHARSIZE},
    {13, SQL_C_CHAR, pk_name, CHARSIZE}
  };

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.DropObject("TABLE",FK_TABLE_FOREIGN)); // this is in case things were not cleaned up properly previously, e.g. connection lost, etc.
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(FK_TABLE_PRIMARY, pktColumns, PrimaryKeyConstraintSpec(T1_CONSTRAINT_NAME, pkColumns)));
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(FK_TABLE_FOREIGN, fktColumns, ForeignKeyConstraintSpec(T2_CONSTRAINT_NAME, fkColumns,FK_TABLE_PRIMARY, pkColumns)));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  if (refer_pk_table) {
    rcode = SQLForeignKeys(odbcHandler.GetStatementHandle(),
                          NULL, 0,          
                          NULL, 0,            
                          (SQLCHAR*) FK_TABLE_PRIMARY.c_str(), SQL_NTS,  
                          NULL, 0,            
                          NULL, 0,            
                          NULL, 0);   
  } else {
    rcode = SQLForeignKeys(odbcHandler.GetStatementHandle(),
                          NULL, 0,          
                          NULL, 0,            
                          NULL, 0,            
                          NULL, 0,            
                          NULL, 0, 
                          (SQLCHAR*) FK_TABLE_FOREIGN.c_str(), SQL_NTS 
                          );   
  }

  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode,SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  EXPECT_EQ(string(pk_table), FK_TABLE_PRIMARY);
  EXPECT_EQ(string(pk_col), T1_COL1);
  EXPECT_EQ(string(pk_name), T1_CONSTRAINT_NAME);
  EXPECT_EQ(string(fk_table), FK_TABLE_FOREIGN);
  EXPECT_EQ(string(fk_col), T2_COL2);
  EXPECT_EQ(string(fk_name), T2_CONSTRAINT_NAME);
  EXPECT_EQ(update_rule, SQL_RESTRICT);
  EXPECT_EQ(delete_rule, SQL_RESTRICT);
}

// Tests SQLPrimaryKeys for success
// DISABLED: PLEASE SEE BABELFISH-112 
TEST_F(Metadata, DISABLED_SQLPrimaryKeys_SingleKey) {

  const string PK_COLUMN_NAME = "id";

  // columns for the test table
  vector<pair<string,string>> columns = {
    {PK_COLUMN_NAME, "INT"}, 
    {"name", "VARCHAR(256)"}
  };

  // primary key columns
  vector<string> pkColumns {{PK_COLUMN_NAME}};
  SQLPrimaryKeysTestCommon("pk_table_1", columns, "single_col_pk", pkColumns);
}

// Tests SQLPrimaryKeys for Composite keys
// DISABLED: PLEASE SEE BABELFISH-112
TEST_F(Metadata, DISABLED_SQLPrimaryKeys_CompositeKeys) {

  // columns for the test table
  vector<pair<string,string>> columns = {
    {"id", "INT"}, 
    {"name", "VARCHAR(256)"}
  };

  // primary key columns
  vector<string> pkColumns;
  for (auto column : columns) {
      pkColumns.push_back(column.first);
  }

  SQLPrimaryKeysTestCommon("composite_pk_table", columns, "composite_pk", pkColumns);
}

// Retrieve foreign keys in other tables that reference primary key of the src table
// DISABLED: PLEASE SEE BABELFISH-122
TEST_F(Metadata, DISABLED_SQLForeignKeys_ReferSourceTable) {

  SQLForeignKeysTestCommon(true); //Use Primary Table in SQLForeignKeys call
}

// Retrieve the foreign keys in the src table that Refer to the primary keys of other tables
// DISABLED PLEASE SEE BABELFISH-122
TEST_F(Metadata, DISABLED_SQLForeignKeys_ReferFromOtherTables) {

  SQLForeignKeysTestCommon(false); //Use Foreign Table in SQLForeignKeys call
}

// Tests if SQLTablePrivileges works properly
// DISABLED PLEASE SEE  BABELFISH-123
TEST_F(Metadata, DISABLED_SQLTablePrivileges) {

  const int CHARSIZE = 255;
  
  OdbcHandler odbcHandler;
  RETCODE rcode;
  
  const string PRIV_TABLE1 = "table_priv";
  char table_name[CHARSIZE];
  char grantor[CHARSIZE];
  char grantee[CHARSIZE];
  char privilege[CHARSIZE];
  char is_grantable[CHARSIZE];

  char current_user[CHARSIZE];
  ASSERT_NO_FATAL_FAILURE(GetCurrentUser(current_user, CHARSIZE));

  map<string, int> permissions = { {"UPDATE",0}, {"DELETE",0}, {"INSERT",0}, {"SELECT",0}, {"REFERENCES", 0} };

  // columns for the test table
  vector<pair<string,string>> columns = {
    {"id", "INT"}
  };

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {3, SQL_C_CHAR, table_name, CHARSIZE},
    {4, SQL_C_CHAR, grantor, CHARSIZE},
    {5, SQL_C_CHAR, grantee, CHARSIZE},
    {6, SQL_C_CHAR, privilege, CHARSIZE},
    {7, SQL_C_CHAR, is_grantable, CHARSIZE}
  };
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(PRIV_TABLE1, columns));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));
  
  rcode = SQLTablePrivileges(odbcHandler.GetStatementHandle(), NULL, 0, NULL, 0, (SQLCHAR*)PRIV_TABLE1.c_str(), SQL_NTS);  
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  while (SQLFetch(odbcHandler.GetStatementHandle()) == SQL_SUCCESS) {

    EXPECT_EQ(string(table_name), PRIV_TABLE1);
    EXPECT_EQ(string(grantor), string(current_user));
    EXPECT_EQ(string(grantee), string(current_user));
    EXPECT_EQ(string(is_grantable), "YES");

    permissions[string(privilege)]++;
  }

  EXPECT_EQ(permissions["UPDATE"], 1);
  EXPECT_EQ(permissions["DELETE"], 1); 
  EXPECT_EQ(permissions["INSERT"], 1); 
  EXPECT_EQ(permissions["REFERENCES"], 1); 
  EXPECT_EQ(permissions["SELECT"], 1);
}

// Tests if SQLTableColumnPrivileges works properly
// DISABLED PLEASE SEE BABELFISH-124
TEST_F(Metadata, DISABLED_SQLTableColumnPrivileges) {

  const int CHARSIZE = 255;
  const string PRIV_COL_TABLE1 = "table_col_priv";
  const string COL_1 = "id1";
  const string COL_2 = "id2";

  OdbcHandler odbcHandler;
  RETCODE rcode;
  int col1_count = 0;
  int col2_count = 0;
  char table_name[CHARSIZE];
  char grantor[CHARSIZE];
  char grantee[CHARSIZE];
  char privilege[CHARSIZE];
  char column_name[CHARSIZE];
  char is_grantable[CHARSIZE];

  char current_user[CHARSIZE];
  ASSERT_NO_FATAL_FAILURE(GetCurrentUser(current_user, CHARSIZE));

  map<string, int> permissions = { {"UPDATE",0}, {"REFERENCES",0}, {"INSERT",0}, {"SELECT",0} };
  
    // columns for the test table
  vector<pair<string,string>> columns = {
    {COL_1, "INT"},
    {COL_2, "INT"}
  };

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {3, SQL_C_CHAR, table_name, CHARSIZE},
    {4, SQL_C_CHAR, column_name, CHARSIZE},
    {5, SQL_C_CHAR, grantor, CHARSIZE},
    {6, SQL_C_CHAR, grantee, CHARSIZE},
    {7, SQL_C_CHAR, privilege, CHARSIZE},
    {8, SQL_C_CHAR, is_grantable, CHARSIZE}
  };
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(PRIV_COL_TABLE1, columns));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLColumnPrivileges(odbcHandler.GetStatementHandle(), NULL, 0, NULL, 0, (SQLCHAR*)PRIV_COL_TABLE1.c_str(), SQL_NTS, NULL, 0);  
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  while (SQLFetch(odbcHandler.GetStatementHandle()) == SQL_SUCCESS) {
    
    EXPECT_TRUE( string(column_name) == COL_1 || string(column_name) == COL_2);
    if (string(column_name) == COL_1) {
      col1_count++;
    } else if (string(column_name) == COL_2) {
      col2_count++;
    }
    EXPECT_EQ(string(table_name), PRIV_COL_TABLE1);
    EXPECT_EQ(string(grantor), string(current_user));
    EXPECT_EQ(string(grantee), string(current_user));
    EXPECT_EQ(string(is_grantable), "YES");

    permissions[string(privilege)]++;
  }
  EXPECT_EQ(permissions["UPDATE"], 2);
  EXPECT_EQ(permissions["INSERT"], 2); 
  EXPECT_EQ(permissions["REFERENCES"], 2); 
  EXPECT_EQ(permissions["SELECT"], 2);
  EXPECT_EQ(col1_count, 4);
  EXPECT_EQ(col2_count, 4);
}

// Tests SQLColumns for success
// DISABLED: PLEASE SEE BABELFISH-118
TEST_F(Metadata, DISABLED_SQLColumns) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  const string COL_TABLE1 = "col_table_1";
  const string CONSTRAINT_NAME = "PK_constraint";
  const string PK_INT_COLUMN_NAME = "IntCol";
  const string CHAR_COLUMN_NAME = "CharCol";
  const string BIT_COLUMN_NAME = "BitCol";
  const string MONEY_COLUMN_NAME = "MoneyCol";
  const string VARCHAR_NOTNULL_COLUMN_NAME = "VarcharCol";
  const string DATETIME_COLUMN_NAME = "DatetimeCol";

  const int CHARSIZE = 255;
  char table_name[CHARSIZE];
  char column_name[CHARSIZE];
  char type_name[CHARSIZE];
  SQLSMALLINT sql_data_type;
  SQLSMALLINT ordinal_position;
  char is_nullable[CHARSIZE];


  // columns for the test table
  vector<pair<string,string>> columns = {
    {PK_INT_COLUMN_NAME, "INT"},
    {CHAR_COLUMN_NAME, "CHAR(24)"},
    {BIT_COLUMN_NAME, "BIT"},
    {MONEY_COLUMN_NAME, "MONEY"},
    {DATETIME_COLUMN_NAME, "DATETIME"},
    {VARCHAR_NOTNULL_COLUMN_NAME, "VARCHAR(24) NOT NULL"}
  };

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {3, SQL_C_CHAR, table_name, CHARSIZE},
    {4, SQL_C_CHAR, column_name, CHARSIZE},
    {6, SQL_C_CHAR, type_name, CHARSIZE},
    {14, SQL_C_SHORT, &sql_data_type, 0},
    {17, SQL_C_SHORT, &ordinal_position, 0},
    {18, SQL_C_CHAR, is_nullable, CHARSIZE}
  };

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(COL_TABLE1, columns, PrimaryKeyConstraintSpec(CONSTRAINT_NAME, {{PK_INT_COLUMN_NAME}})));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLColumns(odbcHandler.GetStatementHandle(), NULL, 0, NULL, 0, (SQLCHAR*) COL_TABLE1.c_str(), SQL_NTS, NULL, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  int position {0};
  vector<tuple<string,string, int, string>> expected_values = {
    {PK_INT_COLUMN_NAME, "int", SQL_INTEGER, "NO"},
    {CHAR_COLUMN_NAME, "char", SQL_CHAR, "YES"},
    {BIT_COLUMN_NAME, "bit", SQL_BIT, "YES"},
    {MONEY_COLUMN_NAME, "money", SQL_DECIMAL, "YES"},
    {DATETIME_COLUMN_NAME, "datetime", SQL_DATETIME, "YES"},
    {VARCHAR_NOTNULL_COLUMN_NAME, "varchar",SQL_VARCHAR, "NO"}
  };

  for (auto col_values : expected_values) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    ++position;
    auto& [col_name, col_type, sql_type, nullable] = col_values;

    EXPECT_EQ(string(table_name), COL_TABLE1);
    EXPECT_EQ(string(column_name), col_name);
    EXPECT_EQ(string(type_name), col_type);
    EXPECT_EQ(sql_data_type, sql_type);
    EXPECT_EQ(SQLINTEGER(ordinal_position), position);
    EXPECT_EQ(string(is_nullable), nullable);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
}

// Tests SQLProcedures for success
// DISABLED: PLEASE SEE BABELFISH-119
TEST_F(Metadata, DISABLED_SQLProcedures) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  
  const string SCHEMA_NAME = "schema_1";
  const string PROC_TABLE = "proc_table_1";
  const string PROCEDURE_NAME = "proc_1";
  const string FUNCTION_NAME = "func_1";
  
  const int CHARSIZE = 255;
  char schema_name[CHARSIZE];
  char procedure_name[CHARSIZE];
  SQLSMALLINT procedure_type;
  
  // Test table columns.
  const vector<pair<string,string>> columns = {
    {"id", "INT"}
  };

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {2, SQL_C_CHAR, schema_name, CHARSIZE},
    {3, SQL_C_CHAR, procedure_name, CHARSIZE},
    {8, SQL_C_SHORT, &procedure_type, 0}
  };

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(PROC_TABLE, columns));
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateSchema(SCHEMA_NAME));
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateProcedure(SCHEMA_NAME + "." + PROCEDURE_NAME, 
                            SelectStatement(PROC_TABLE, {"*"})));
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateFunction(SCHEMA_NAME + "." + FUNCTION_NAME, 
                           "() RETURNS BIT AS BEGIN DECLARE @var BIT SET @var = 1 RETURN @var END"));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLProcedures(odbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR*) SCHEMA_NAME.c_str(), SQL_NTS, NULL, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Expected values contain names and types of procedures/functions.
  map<string, int> expected_values = { 
    {PROCEDURE_NAME,SQL_PT_FUNCTION },  // Curiously, SQL Server returns SQL_PT_FUNCTION for procedures rather than SQL_PT_PROCEDURE
    {FUNCTION_NAME,SQL_PT_FUNCTION }
  };

  while((rcode = SQLFetch(odbcHandler.GetStatementHandle())) == SQL_SUCCESS  ) {
    EXPECT_EQ(string(schema_name), SCHEMA_NAME);
    // SQL Server appends ';0' or ';1' to names. It appears that ';0' is used for functions and ';1' for procedures.
    // Trimming these here. For the purpose of this test, they are irrelevant and make it harder to compare expected values.
    // If BBF does not append these characters this needs to be handled here. It will be determined when the test is not disabled.
    procedure_name[strlen(procedure_name)-2] = 0;
    auto value = expected_values.find(procedure_name);
    if (value != expected_values.end()) {
      EXPECT_EQ(procedure_type, value->second); 
      expected_values.erase(value->first);
    }
    else {
      // Expected values not updated properly? Or SCHEMA_NAME modified outside of this test?
      EXPECT_TRUE(false) << procedure_name << " was NOT expected but found"; 
    }
  }

  EXPECT_EQ(rcode, SQL_NO_DATA) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Check and assert expected values that were not found. 
  // All are expected to be found. Thus, in successful case the for loop would not do anything as the map should be empty.
  for (auto value : expected_values) {
    EXPECT_TRUE(false) << value.first << " was expected but not found";
  }
}

// Tests SQLProcedureColumns for success
// DISABLED: PLEASE SEE BABELFISH-120
TEST_F(Metadata, DISABLED_SQLProcedureColumns) {

  OdbcHandler odbcHandler;
  RETCODE rcode;

  const string SCHEMA_NAME = "schema_2";  
  const string PROC_TABLE = "proc_table_2";
  const string PROCEDURE_NAME = "proc_1";
  const string FUNCTION_NAME = "func_1";

  const int CHARSIZE = 255;
  char schema_name[CHARSIZE];
  char procedure_name[CHARSIZE];
  char column_name[CHARSIZE];
  char type_name[CHARSIZE];
  SQLSMALLINT sql_data_type;
  SQLSMALLINT ordinal_position;
  char is_nullable[CHARSIZE];

  // Test table columns.
  const vector<pair<string,string>> columns = {
    {"id", "VARCHAR(80)"}
  };

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {2, SQL_C_CHAR, schema_name, CHARSIZE},
    {3, SQL_C_CHAR, procedure_name, CHARSIZE},
    {4, SQL_C_CHAR, column_name, CHARSIZE},
    {7, SQL_C_CHAR, type_name, CHARSIZE},
    {15, SQL_C_SHORT, &sql_data_type, 0},
    {18, SQL_C_SHORT, &ordinal_position, 0},
    {19, SQL_C_CHAR, is_nullable, CHARSIZE}
  };

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(PROC_TABLE, columns));
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateSchema(SCHEMA_NAME));
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateProcedure(SCHEMA_NAME + "." + PROCEDURE_NAME, 
                            SelectStatement(PROC_TABLE, {"*"} ,{}, "id = @id"),
                            " @id VARCHAR(80) "));
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateFunction(SCHEMA_NAME + "." + FUNCTION_NAME, 
                          "(@par INT, @par2 VARCHAR(80)) RETURNS BIT AS BEGIN DECLARE @var BIT SET @var = @par RETURN @var END" 
                           ));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLProcedureColumns(odbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR*) SCHEMA_NAME.c_str(), SQL_NTS, NULL, 0, NULL, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // The expected values is a map where a key is a procedure_name,column_name pair
  // The map values are tuples holding the corresponding values for a column: data type, sqlType, position, is nullable 
  map< pair<string, string>,  tuple<string,int, int, string>> expected_values = {
    { {FUNCTION_NAME, "@RETURN_VALUE"},  {"bit", SQL_BIT, 0, "YES"}},
    { {FUNCTION_NAME, "@par"},  {"int", SQL_INTEGER, 1, "YES"}},
    { {FUNCTION_NAME, "@par2"},  {"varchar", SQL_VARCHAR, 2, "YES"}},

    { {PROCEDURE_NAME, "@RETURN_VALUE"},  {"int", SQL_INTEGER, 0, "NO"}},
    { {PROCEDURE_NAME, "@id"},  {"varchar", SQL_VARCHAR, 1, "YES"}}
  };
  
  while((rcode = SQLFetch(odbcHandler.GetStatementHandle())) == SQL_SUCCESS  ) {
    EXPECT_EQ(string(schema_name), SCHEMA_NAME);
    // SQL Server appends ';0' or ';1' to names. It appears that ';0' is used for functions and ';1' for procedures.
    // Trimming these here. For the purpose of this test, they are irrelevant and make it harder to compare expected values.
    // If BBF does not append these characters this needs to be handled here. It will be determined when the test is not disabled.
    procedure_name[strlen(procedure_name)-2] = 0;

    auto colData = expected_values.find({procedure_name, column_name});
    if (colData != expected_values.end()) {
      auto& [type, sqlType, position, nullable] = colData->second;
      EXPECT_EQ(string(type_name), type);
      EXPECT_EQ(sql_data_type, sqlType);
      EXPECT_EQ(SQLINTEGER(ordinal_position), position);
      EXPECT_EQ(string(is_nullable), nullable);

      // remove from the found ones from the map
      expected_values.erase({procedure_name, column_name});
    } 
    else {
      // Expected values not updated properly? Or SCHEMA_NAME modified outside of this test?
      EXPECT_TRUE(false) << "Procedure: " << procedure_name << "  Column:  " << column_name << " data was NOT expected but found";
    }
  }

  EXPECT_EQ(rcode, SQL_NO_DATA) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Check and assert expected values that were not found. 
  // All are expected to be found. Thus, in successful case the for loop would not do anything as the map should be empty.
  for (auto value : expected_values) {
    auto& [procedure, column] = value.first;
    EXPECT_TRUE(false) << "Procedure: " << procedure << "  Column:  " << column << " data was expected but not found";
    
  }
}

// Tests SQLProcedureColumns for success with primary keys
// DISABLED: PLEASE SEE BABELFISH-121
TEST_F(Metadata, DISABLED_SQLSpecialColumns_PrimaryKeys) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  const string COL_TABLE = "col_table_primary_keys";
  const string CONSTRAINT_NAME = "PK_constraint_1";
  const string PK_INT_COLUMN_NAME = "IntCol";
  const string CHAR_COLUMN_NAME = "CharCol";

  const int CHARSIZE = 255;
  char column_name[CHARSIZE];
  char type_name[CHARSIZE];

  // The test table columns
  vector<pair<string,string>> columns = {
    {PK_INT_COLUMN_NAME, "INT"}, 
    {CHAR_COLUMN_NAME, "VARCHAR(24)"}
  };
  // primary key columns
  vector<string> pkColumns {{PK_INT_COLUMN_NAME}};

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {2, SQL_C_CHAR, column_name, CHARSIZE},
    {4, SQL_C_CHAR, type_name, CHARSIZE}
  };

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(COL_TABLE, columns, PrimaryKeyConstraintSpec(CONSTRAINT_NAME, pkColumns)));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLSpecialColumns(odbcHandler.GetStatementHandle(), SQL_BEST_ROWID, NULL, 0, NULL, 0, (SQLCHAR*) COL_TABLE.c_str(), SQL_NTS, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  EXPECT_EQ(string(column_name), PK_INT_COLUMN_NAME);
  EXPECT_EQ(string(type_name), "int");

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
}

// Tests SQLProcedureColumns for success with automatically updated columns
// DISABLED: PLEASE SEE BABELFISH-121
TEST_F(Metadata, DISABLED_SQLSpecialColumns_AutoUpdatedColumns) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  const string COL_TABLE = "col_table_auto_update";
  const string INT_COLUMN_NAME = "IntCol";
  const string TIMESTAMP_COLUMN_NAME = "TimestampCol";
  const int CHARSIZE = 255;
  char column_name[CHARSIZE];
  char type_name[CHARSIZE];

  // The test table columns
  vector<pair<string,string>> columns = {
    {INT_COLUMN_NAME, "INT"}, 
    {TIMESTAMP_COLUMN_NAME, "TIMESTAMP"}
  };

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {2, SQL_C_CHAR, column_name, CHARSIZE},
    {4, SQL_C_CHAR, type_name, CHARSIZE}
  };

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(COL_TABLE, columns));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLSpecialColumns(odbcHandler.GetStatementHandle(), SQL_ROWVER, NULL, 0, NULL, 0, (SQLCHAR*) COL_TABLE.c_str(), SQL_NTS, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  EXPECT_EQ(string(column_name), TIMESTAMP_COLUMN_NAME);
  EXPECT_EQ(string(type_name), "timestamp");

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
}

// Tests SQLSetEnvAttr for success with SQL_ATTR_ODBC_VERSION
TEST_F(Metadata, SQLSetEnvAttr_SQL_ATTR_ODBC_VERSION) {

  RETCODE rcode;
  SQLHENV henv_{};
  rcode = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLSetEnvAttr(henv_, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC3, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLFreeHandle(SQL_HANDLE_ENV, henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);
}

// Tests SQLSetEnvAttr for success with SQL_ATTR_OUTPUT_NTS
TEST_F(Metadata, SQLSetEnvAttr_SQL_ATTR_OUTPUT_NTS) {

  RETCODE rcode;
  SQLHENV henv_{};
  rcode = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLSetEnvAttr(henv_, SQL_ATTR_OUTPUT_NTS, (SQLPOINTER)SQL_TRUE, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLFreeHandle(SQL_HANDLE_ENV, henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);
}

// Tests SQLSetEnvAttr for success with SQL_ATTR_CONNECTION_POOLING
TEST_F(Metadata, SQLSetEnvAttr_SQL_ATTR_CONNECTION_POOLING) {

  RETCODE rcode;
  SQLHENV henv_{};
  rcode = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLSetEnvAttr(henv_, SQL_ATTR_CONNECTION_POOLING, (SQLPOINTER)SQL_CP_ONE_PER_DRIVER, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLFreeHandle(SQL_HANDLE_ENV, henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);
}

// Tests SQLSetEnvAttr for success with SQL_ATTR_CP_MATCH
TEST_F(Metadata, SQLSetEnvAttr_SQL_ATTR_CP_MATCH) {

  RETCODE rcode;
  SQLHENV henv_{};
  rcode = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLSetEnvAttr(henv_, SQL_ATTR_CP_MATCH, (SQLPOINTER)SQL_CP_STRICT_MATCH, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  rcode = SQLFreeHandle(SQL_HANDLE_ENV, henv_);
  ASSERT_EQ(rcode, SQL_SUCCESS);
}

// Tests SQLGetTypeInfo for success
TEST_F(Metadata, SQLGetTypeInfo) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  const int CHARSIZE = 255;
  char type_name[CHARSIZE];
  SQLSMALLINT case_sensitive;
  SQLSMALLINT sql_data_type;

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {1, SQL_C_CHAR, type_name, CHARSIZE},
    {8, SQL_C_SHORT, &case_sensitive, 0},
    {16, SQL_C_SHORT, &sql_data_type, 0}
  };

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(""));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLGetTypeInfo(odbcHandler.GetStatementHandle(), SQL_CHAR);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  EXPECT_EQ(string(type_name), "char");
  EXPECT_EQ(case_sensitive, SQL_TRUE); // This will fail if testing on SQL Server because SQL_CHAR is case insensitive but SQL_CHAR is case sensitive in Postgres + BBF. 
  EXPECT_EQ(sql_data_type, SQL_CHAR);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
}

// Test SQLTables to retrieve catalogs
// DISABLED: PLEASE SEE BABELFISH-132
TEST_F(Metadata, DISABLED_SQLTables_Catalogs) {
	 
	OdbcHandler odbcHandler;
	RETCODE rcode = -1;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  rcode = SQLTables( odbcHandler.GetStatementHandle(), (SQLCHAR*)SQL_ALL_CATALOGS, SQL_NTS, (SQLCHAR*)"", SQL_NTS, (SQLCHAR*)"", SQL_NTS, (SQLCHAR*)"", SQL_NTS );
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  
  // In general, we don't know what catalogs are going to exist. 
  // But we should at least be able to verify that the current catalog/database was on the list
  map<string, bool> values = { 
    {odbcHandler.GetDbname(),false}
  };
  // Catalog/Database information is returned in column 1
  ASSERT_NO_FATAL_FAILURE(FetchAndMatchValues(odbcHandler, values, 1));

  for (auto value : values) {
    EXPECT_EQ(value.second, true) << value.first << " was expected but not found";
  }
}

// Test SQLTables to retrieve tables
// DISABLED: PLEASE SEE BABELFISH-132
TEST_F(Metadata, DISABLED_SQLTables_Tables) {
	 
	OdbcHandler odbcHandler;
	RETCODE rcode = -1;

  const vector<string> testTables = {
    {"meta_table1"}, 
    {"meta_table2"},
    {"meta_table3"}
  };

  // A few 'random' columns for a test tables. The columns are not relevant for this test.
  vector<pair<string,string>> columns = {
    {"id", "INT"}, 
    {"info", "VARCHAR(256) NOT NULL"},
    {"decivar", "NUMERIC(38,16) NOT NULL"}
  };

  DatabaseObjects dbObjects;

  for (auto table : testTables) {
    ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(table, columns));
  }

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  rcode = SQLTables(odbcHandler.GetStatementHandle(),
	                  NULL, 0, NULL, 0, NULL, 0,  (SQLCHAR*) "TABLE", SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // In general, we don't know what tables are going to exist. 
  // But we should at least be able to verify that tables we created were on the list
  map<string, bool> values;
  for (auto table : testTables) {
    values[table] = false;
  }

  // Table/View information is returned in column 3
  ASSERT_NO_FATAL_FAILURE(FetchAndMatchValues(odbcHandler, values, 3));

  for (auto value : values) {
    EXPECT_TRUE(value.second) << value.first << " was expected but not found";
  }
}

// Test SQLTables to retrieve views
// DISABLED: PLEASE SEE BABELFISH-132
TEST_F(Metadata, DISABLED_SQLTables_Views) {
	 
	OdbcHandler odbcHandler;
	RETCODE rcode = -1;

  const string testTable {"meta_table"};

  // A few 'random' columns for a test table. The columns are not relevant for this test.
  const vector<pair<string,string>> columns = {
    {"id", "INT"}, 
    {"info", "VARCHAR(256)"},
    {"decivar", "NUMERIC(38,16)"}
  };

  vector<string> columnNames;
  for (auto column : columns) {
      columnNames.push_back(column.first);
  }

  // View definitions used in this test. 
  // The vector pairs contain a view name and the select statement used to create the view.
  const vector<pair<string,string>> testViews = {
    {"meta_view1", SelectStatement(testTable, columnNames)}, 
    {"meta_view2", SelectStatement(testTable, {"*"})}
  };

  DatabaseObjects dbObjects;

  // Normally CreateTable and CreateView functions of DatabaseObjects try to drop the object before creating.
  // Here we need to drop views explicitly, because the CreateTable below would attempt to drop the table first.
  // If the views still existed, the drop table would fail in Postgres. It would work ok with SQL Server.
  for (auto view : testViews) {
      ASSERT_NO_FATAL_FAILURE(dbObjects.DropObject("VIEW",view.first));
  }

  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(testTable, columns));
  for (auto view : testViews) {
      ASSERT_NO_FATAL_FAILURE(dbObjects.CreateView(view.first, view.second));
  }

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  rcode = SQLTables(odbcHandler.GetStatementHandle(),
	                  NULL, 0, NULL, 0, NULL, 0,  (SQLCHAR*) "VIEW", SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // In general, we don't know what views are going to exist. 
  // But we should at least be able to verify that views we created were on the list
  map<string, bool> values;
  for (auto view : testViews) {
      values[view.first] = false;
  }

  // Table/View information is returned in column 3
  ASSERT_NO_FATAL_FAILURE(FetchAndMatchValues(odbcHandler, values, 3));

  for (auto value : values) {
    EXPECT_TRUE(value.second) << value.first << " was expected but not found";
  }
}
