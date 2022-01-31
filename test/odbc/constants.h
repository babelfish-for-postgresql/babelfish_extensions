#ifndef ODBC__constants_H_
#define ODBC__constants_H_

#include <string>

using std::string;

namespace constants{

enum class ServerType {
  Babel,
  SQL,
};

extern string INPUT_SOURCE;
extern string ODBC_DRIVER_NAME;

extern string BABEL_DB_SERVER;
extern string BABEL_DB_PORT;
extern string BABEL_DB_USER;
extern string BABEL_DB_PASSWORD;
extern string BABEL_DB_NAME;

extern string SQL_DB_SERVER;
extern string SQL_DB_PORT;
extern string SQL_DB_USER;
extern string SQL_DB_PASSWORD;
extern string SQL_DB_NAME;

extern string null_str;

}

#endif
