#include "../src/odbc_handler.h"
#include <gtest/gtest.h>
#include <sqlext.h>
#include "../src/drivers.h"

class MSSQL_Connection : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }
  }

};

TEST_F(MSSQL_Connection, SQLDriverConnect_SuccessfulConnectionTest) {
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::MSSQL));

  odbcHandler.AllocateEnvironmentHandle();
  odbcHandler.AllocateConnectionHandle();

  RETCODE rcode = SQLDriverConnect(odbcHandler.GetConnectionHandle(),
                                nullptr, 
                                (SQLCHAR *) odbcHandler.GetConnectionString().c_str(), 
                                SQL_NTS, 
                                nullptr, 
                                0, 
                                nullptr, 
                                SQL_DRIVER_COMPLETE);

  ASSERT_TRUE(rcode == SQL_SUCCESS_WITH_INFO || rcode == SQL_SUCCESS);
}
