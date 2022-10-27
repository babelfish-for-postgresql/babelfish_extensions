#include "odbc_handler.h"
#include <sqlext.h>
#include <gtest/gtest.h>

OdbcHandler::OdbcHandler(ConnectionObject &co) {
  SetConnectionProperties(co);
}

OdbcHandler::~OdbcHandler() {
  FreeStmtHandle();
  FreeConnectionHandle();
  FreeEnvironmentHandle();
}

void OdbcHandler::Connect(bool allocate_statement_handle) {

  const int MAX_ATTEMPTS = 4;
  int attempts = 0;
  string connection_str = GetConnectionString();
  AllocateEnvironmentHandle();
  AllocateConnectionHandle();
  SQLSetConnectAttr(hdbc_, SQL_ATTR_LOGIN_TIMEOUT, (SQLPOINTER)5, 0); // 5 seconds
  
  do {
    attempts++;
    retcode_ = SQLDriverConnect(hdbc_, nullptr, (SQLCHAR *) connection_str.c_str(), SQL_NTS, nullptr, 0, nullptr, SQL_DRIVER_COMPLETE);
  } while (retcode_ != SQL_SUCCESS && retcode_ != SQL_SUCCESS_WITH_INFO && attempts < MAX_ATTEMPTS );
  
  AssertSqlSuccess(retcode_, "CONNECTION FAILED");

  if (allocate_statement_handle) {
    AllocateStmtHandle();
  }
}

SQLHENV OdbcHandler::GetEnvironmentHandle() {
  return this->henv_;
}

SQLHDBC OdbcHandler::GetConnectionHandle() {
  return this->hdbc_;
}

SQLHSTMT OdbcHandler::GetStatementHandle() {
  return this->hstmt_;
}

RETCODE OdbcHandler::GetReturnCode() {
  return this->retcode_;
}

string OdbcHandler::GetConnectionString() {
  return this->connection_string_;
}

string OdbcHandler::GetDriver() {
  return this->db_driver_;
}

string OdbcHandler::GetServer() {
  return this->db_server_;
}

string OdbcHandler::GetPort() {
  return this->db_port_;
}

string OdbcHandler::GetUid() {
  return this->db_uid_;
}

string OdbcHandler::GetPwd() {
  return this->db_pwd_;
}

string OdbcHandler::GetDbname() {
  return this->db_dbname_;
}

void OdbcHandler::AllocateEnvironmentHandle() {

  if (henv_ != NULL) {
    FAIL() << "ERROR: There was an attempt to allocate an already allocated environment handle";
  }

  AssertSqlSuccess(SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv_),
                "ERROR: Failed to allocate the environment handle");

  SQLSetEnvAttr(henv_,
                SQL_ATTR_ODBC_VERSION,
                (SQLPOINTER)SQL_OV_ODBC3,
                0);
}

void OdbcHandler::AllocateConnectionHandle() {

  if (hdbc_ != NULL) {
    FAIL() << "ERROR: There was an attempt to allocate an already allocated connection handle";
  }

  AssertSqlSuccess(
    SQLAllocHandle(SQL_HANDLE_DBC, henv_, &hdbc_),
    "ERROR: Failed to allocate connection handle");
  
}

void OdbcHandler::AllocateStmtHandle() {
  if (hstmt_ != NULL) {
    FAIL() << "ERROR: There was an attempt to allocate an already allocated statement handle";
  }

  AssertSqlSuccess( 
    SQLAllocHandle(SQL_HANDLE_STMT, hdbc_, &hstmt_), 
    "ERROR: Failed to allocate connection handle");
}

void OdbcHandler::FreeEnvironmentHandle() {
  if (henv_) {
    SQLFreeHandle(SQL_HANDLE_ENV, henv_);
    henv_ = NULL;
  }
}

void OdbcHandler::FreeConnectionHandle() {
  if (hdbc_) {
    SQLDisconnect(hdbc_);
    SQLFreeHandle(SQL_HANDLE_DBC, hdbc_);
    hdbc_ = NULL;
  }
}

void OdbcHandler::FreeStmtHandle() {
  if (hstmt_) {
    SQLFreeStmt(hstmt_, SQL_CLOSE);
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt_);
    hstmt_ = NULL;
  }
}

void OdbcHandler::FreeAllHandles() {
  FreeStmtHandle();
  FreeConnectionHandle();
  FreeEnvironmentHandle();
}

void OdbcHandler::CloseStmt() {
  if (hstmt_) {
    SQLFreeStmt(hstmt_, SQL_CLOSE);
  }
}

void OdbcHandler::SetConnectionProperties(ConnectionObject &co) {

  db_driver_ = co.GetDriver();
  db_server_ = co.GetServer();
  db_port_ = co.GetPort();
  db_uid_ = co.GetUid();
  db_pwd_ = co.GetDbname();
  db_dbname_ = co.GetDbname();

  connection_string_ = co.GetConnectionString();
}

void OdbcHandler::AssertSqlSuccess(RETCODE retcode, const string& error_msg) {
  if (!IsSqlSuccess(retcode)) {
    FAIL() << error_msg << std::endl << "Return code was: " << retcode << "\n" << "SQL Status of: " << GetSqlState(SQL_HANDLE_DBC, hdbc_); 
  }
}

bool OdbcHandler::IsSqlSuccess(RETCODE retcode) {
  return retcode == SQL_SUCCESS || retcode == SQL_SUCCESS_WITH_INFO;
}

void OdbcHandler::ExecQuery(const string& query) {
  
  AssertSqlSuccess(
      SQLExecDirect(hstmt_, (SQLCHAR*) query.c_str(), SQL_NTS),
      "ERROR: was not able to run query: " + query);

}

void OdbcHandler::ConnectAndExecQuery(const string& query){

  this->Connect(true);
  this->ExecQuery(query);
}


string OdbcHandler::GetSqlState(SQLSMALLINT HandleType, SQLHANDLE Handle) {

  SQLINTEGER native_error_ptr; 
  SQLCHAR sql_error_msg[1024];
  SQLCHAR sql_state[SQL_SQLSTATE_SIZE+1];

  SQLGetDiagRec(HandleType,
                       Handle,
                       1,
                       sql_state,
                       &native_error_ptr,
                       sql_error_msg,
                       (SQLSMALLINT)(sizeof(sql_error_msg) / sizeof(SQLCHAR)),
                       nullptr);
  return string(reinterpret_cast<char *>(sql_state));
}

string OdbcHandler::GetErrorMessage(SQLSMALLINT HandleType, const RETCODE& retcode) {

  SQLINTEGER native_error_ptr;
  SQLCHAR sql_error_msg[1024] = "(Unable to retrieve error message)";
  SQLCHAR sql_state[SQL_SQLSTATE_SIZE+1] = "";
  SQLHANDLE handle;

  if (retcode == SQL_SUCCESS) {
    return "SQL_SUCCESS was returned but was not expected";
  }

  switch(HandleType) {
    case SQL_HANDLE_ENV:
      handle = henv_;
      break;
    case SQL_HANDLE_DBC:
      handle = hdbc_;
      break;
    case SQL_HANDLE_STMT:
      handle = hstmt_;
      break;
    default:
      return "(Unable to retrieve error message - an invalid handle type was passed. Please ensure you are passing SQL_HANDLE_ENV, SQL_HANDLE_DBC, or SQL_HANDLE_STMT";
  }

  SQLGetDiagRec(HandleType,
                       handle,
                       1,
                       sql_state,
                       &native_error_ptr,
                       sql_error_msg,
                       (SQLSMALLINT)(sizeof(sql_error_msg) / sizeof(SQLCHAR)),
                       nullptr);
  return "[Return value: " + std::to_string(retcode) + "][SQLState: " + std::string((const char *) sql_state) + "] ERROR: " + std::string((const char*) sql_error_msg) + "\n";
}

void OdbcHandler::BindColumns(vector<tuple<int, int, SQLPOINTER, int>> columns) {

  // ToDo: Refactor this to call the other BindColumns function with std::tuple_cat
  RETCODE rcode;

  for (auto column : columns) {
    auto& [col_num, c_type, target, target_size] = column;
    rcode = SQLBindCol(GetStatementHandle(), col_num, c_type, target, target_size, 0);
    ASSERT_EQ(rcode, SQL_SUCCESS) << GetErrorMessage(SQL_HANDLE_STMT, rcode);
  }
}

void OdbcHandler::BindColumns(vector<tuple<int, int, SQLPOINTER, int, SQLLEN*>> columns) {
  RETCODE rcode;

  for (auto column : columns) {
    auto& [col_num, c_type, target, target_size, ind] = column;
    rcode = SQLBindCol(GetStatementHandle(), col_num, c_type, target, target_size, ind);
    ASSERT_EQ(rcode, SQL_SUCCESS) << GetErrorMessage(SQL_HANDLE_STMT, rcode);
  }
}
