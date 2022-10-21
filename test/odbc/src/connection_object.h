#ifndef CONNECTION_OBJECT_H
#define CONNECTION_OBJECT_H

#include <string>

using std::string;

class ConnectionObject {

  public:

    ConnectionObject(string driver, string server, string port, string uid, string pwd, string dbname, bool alternativeConnectionString = false);
    ~ConnectionObject();

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

  private:
    
    // DB Information
    string db_driver_;
    string db_server_;
    string db_port_;
    string db_uid_;
    string db_pwd_;
    string db_dbname_;

    string connection_string_;
};

#endif
