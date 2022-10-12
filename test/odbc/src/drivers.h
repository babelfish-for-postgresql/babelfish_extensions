#ifndef DRIVERS_H
#define DRIVERS_H

#include "constants.h"
#include "connection_object.h"

using namespace constants;

class Drivers {

  public:

    static bool DriverExists(ServerType st) {
      if (odbc_drivers_.empty()) {
          SetDrivers();
      }
      return odbc_drivers_.find(st) != odbc_drivers_.end();
    }

    static ConnectionObject& GetDriver(ServerType st) {
      if (odbc_drivers_.empty()) {
          SetDrivers();
      }
      return odbc_drivers_.at(st);
    }

      // Constructor
      Drivers();

      // Destructor
      ~Drivers();

  private:

    static void SetDrivers();

    static map<ServerType, ConnectionObject> odbc_drivers_;

    // Goes through config.txt and returns a map with values from the configuration file
    static map<string, string> ParseConfigFile();

    // Checks if given connection string parameters forms a valid connection object
    static bool IsValidConnectionObject(string driver, string server, string port, string uid, string pwd, string dbname);
};
#endif
