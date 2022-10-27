#ifndef ODBC_HANDLER_H
#define ODBC_HANDLER_H

#include <sql.h>
#include <string>
#include <tuple>
#include <vector>
#include "constants.h"
#include "connection_object.h"

using std::string;
using std::vector;
using std::tuple;
using namespace constants;

class OdbcHandler {

  public:

    // Constructor
    explicit OdbcHandler(ConnectionObject &co);

    // Destructor
    ~OdbcHandler();

    // Sets the connection string based on server type
    void SetConnectionProperties(ConnectionObject &co);
    
    // Connects to Database
    void Connect(bool allocate_statement_handle = false);

    // Returns the environment handle
    SQLHENV GetEnvironmentHandle();

    // Returns the connection handle
    SQLHDBC GetConnectionHandle();

    // Returns the statement handle
    SQLHSTMT GetStatementHandle();

    // Returns the return code
    RETCODE GetReturnCode();

    // Returns the connection string 
    string GetConnectionString();

    // Returns the driver name
    string GetDriver();

    // Returns the server name
    string GetServer();

    // Returns the port
    string GetPort();

    // Returns the username/uid used for database login
    string GetUid();

    // Returns the password used for database login
    string GetPwd();

    // Returns the database used
    string GetDbname();


    // Allocates the connection handle and sets the environment attribute
    void AllocateEnvironmentHandle();

    // Allocates the connection handle
    void AllocateConnectionHandle();

    // Allocates the statement handle
    void AllocateStmtHandle();
    
    // Frees the environment handle
    void FreeEnvironmentHandle();

    // Frees the connection handle
    void FreeConnectionHandle();

    // Frees the statement handle
    void FreeStmtHandle();

    // Free all handles (without freeing the instance itself)
    void FreeAllHandles();

    // Calls FreeStmt() with SQL_CLOSE option
    void CloseStmt();

    // Asserts the return code (based on a given return code) and fails the test if an error is found
    void AssertSqlSuccess(RETCODE retcode, const string& error_msg);

    // Returns whether or not the return code is SQL_SUCCESS or SQL_SUCCESS_WITH_INFO (does not fail test)
    bool IsSqlSuccess(RETCODE retcode);

    // Execute a query (assuming the OdbcHandler is already connected). Will fail the test if query is unsuccessful
    void ExecQuery(const string& query);

    // This function will connect to the db, allocate a statement handle,  
    // and execute the given query. Will fail test if query is unsuccessful.
    void ConnectAndExecQuery(const string& query);

    // Retrieves the SQLState code as a string
    string GetSqlState(SQLSMALLINT HandleType, SQLHANDLE Handle);

    // Creates and returns an error message containing diagnostic information
    string GetErrorMessage(SQLSMALLINT HandleType, const RETCODE& retcode);

    // Helper function used to bind columns using SQLBindCol
    // The StrLen_or_IndPtr field will be hardcoded to 0 in this example
    void BindColumns(vector<tuple<int, int, SQLPOINTER, int>> columns);

    void BindColumns(vector<tuple<int, int, SQLPOINTER, int, SQLLEN*>> columns);

  private:
    // ODBC-defined SQL variables
    SQLHENV henv_{};
    SQLHDBC hdbc_{};
    SQLHSTMT hstmt_{};
    RETCODE retcode_{};

    // DB Information
    string db_driver_{};
    string db_server_{};
    string db_port_{};
    string db_uid_{};
    string db_pwd_{};
    string db_dbname_{};

    string connection_string_{};

};

#endif
