# Instructions to run locally with a pre-existing db

To run thed ODBC test framework suite for babelfish locally,
you will have to:

1. Setup the database information
2. Run the build commands.

## Setting up database information

There are 2 ways of providing the database command: setting environment variables or altering the config files (environment variables will take higher priority over the config.txt file). 

### Using config.txt
The config.txt should be filled like the example below. The ```ODBC_DRIVER_NAME``` can be left blank and the default value will result in using the ```ODBC Driver 17 for SQL Server``


```
ODBC_DRIVER_NAME=
BABEL_DB_SERVER=localhost
BABEL_DB_PORT=1433
BABEL_DB_USER=sa
BABEL_DB_PASSWORD=<YourStrong@Passw0rd>
BABEL_DB_NAME=master
```

NOTE: There may be some fields that are pre-fixed with ```SQL_DB_```. Please ignore these for now. They were left in from the previous state of these tests but will most likely not be used and removed in the future. 

### Using environment variables

The environment variables will have the same name as the keys in the config file (e.g. BABEL_DB_SERVER will correspond with the server name). When running the build commands, you may set the environment variable in you .zshrc file (or .bashprofile) or before executing the main file like the example below.

```
// In the odbc directory
BABEL_DB_SERVER=localhost BABEL_DB_PORT=1433 ./build/main
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

For example, if I wanted to disable a test labled TEST_F(testsuite, notWorkingTest). I would change it to
TEST_F(testsuite, DISABLED_notWorkingTest)