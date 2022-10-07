# Instructions to run locally with a pre-existing db

To run thed ODBC test framework suite for babelfish locally,
you will have to:

1. Setup the database information
2. Run the build commands.

## Setting up database information

There are 2 ways of providing the database command: setting environment variables or altering the config files (environment variables will take higher priority over the config.txt file). 

### Using config.txt

This test framework currently supports two ODBC drivers: the SQL Server ODBC driver and the psqlODBC driver. Their connection parameters for the two drivers are differentiated in the config.txt with the prefixes 'MSSQL_' and 'PSQL_' in the key names.

The config.txt should be filled like the example below.

```
MSSQL_ODBC_DRIVER_NAME=ODBC Driver 17 for SQL Server
MSSQL_BABEL_DB_SERVER=localhost
MSSQL_BABEL_DB_PORT=1433
MSSQL_BABEL_DB_USER=jdbc_user
MSSQL_BABEL_DB_PASSWORD=12345678
MSSQL_BABEL_DB_NAME=master

PSQL_ODBC_DRIVER_NAME=ODBC_Driver_12_PostgreSQL
...
```

### Using environment variables

The environment variables will have the same name as the keys in the config file (e.g. MSSQL_BABEL_DB_SERVER will correspond with the server name for the SQL Server connection). When running the build commands, you may set the environment variable in your .zshrc file (or .bashprofile) or before executing the main file like the example below.

```
// In the odbc directory
MSSQL_BABEL_DB_SERVER=localhost MSSQL_BABEL_DB_PORT=1433 ./build/main
```


## Build commands
To build these run these set of commands

```
// Make sure you are in the odbc directory
cmake -D CMAKE_C_COMPILER=gcc-10 -D CMAKE_CXX_COMPILER=g++-10 -S . -B build
cmake --build build
./build/main
```

## Disabling a test

To disable a test, simply put "DISABLED_" on the second parameter of the TEST_F descriptor.

For example, to disable a test labled `TEST_F(testsuite, notWorkingTest)` it would be changed to
`TEST_F(testsuite, DISABLED_notWorkingTest)`.

## Controlling which tests should run

By default all the tests will run. You can run one or more individual tests by specifying test information in the `odbc_schedule` file.
