# JDBC Test Framework for Babelfish
The JDBC test framework for Babelfish uses the JDBC Driver for SQL Server for database connectivity and allows you to perform end-to-end testing (i.e. testing of the T-SQL syntax and TDS protocol implementation) of Babelfish without the need to write any application level code.

## Table of Contents
- [Running the test framework](#running-the-test-framework)
  - [Build Requirements](#build-requirements)
  - [Running the test cases](#running-the-test-cases)
- [Running the test cases against a custom Babelfish endpoint](#running-the-test-cases-against-a-custom-babelfish-endpoint)
- [Controlling which test cases should run](#controlling-which-test-cases-should-run)
- [Writing the test cases](#writing-the-test-cases)
  - [Using a plain SQL Batch](#using-a-plain-sql-batch)
  - [Preparing and executing statements](#preparing-and-executing-statements)
  - [Using a stored procedure](#using-a-stored-procedure)
  - [Using a transaction](#using-a-transaction)
  - [Using a cursor](#using-a-cursor)
  - [Verifying SQL Authentication test cases](#verifying-sql-authentication-test-cases)
  - [Intermixing queries in T-SQL and PL/pgSQL dialect](#intermixing-queries-in-t-sql-and-plpgsql-dialect-cross-dialect-test-cases)
  - [IMPORTANT](#important)
- [Adding the test cases](#adding-the-test-cases)
- [Reading the console output and diff](#reading-the-console-output-and-diff)
- [Running Tests with Parallel Query Enabled](#running-tests-with-parallel-query-enabled)
- [Running Tests with Non Default Server Collation](#running-tests-with-non-default-server-collation)

## Running the test framework

### Build Requirements
- Java, version 1.8 or later
- Maven, version 3.6.3 or later

### Running the test cases
After building the modified PostgreSQL engine and Babelfish extensions using the [online instructions](../../contrib/README.md), you must:
1. Create a PostgreSQL database and initialize Babelfish (if you already have a database with Babelfish initialized, you can omit this step or perform the cleanup steps before you initialize):
    ```bash
    ./init.sh
    ```
2. Run the tests:
    ```bash
    mvn test
    ```
3. Cleanup all the objects, users, roles and databases created while running the tests:
    ```bash
    ./cleanup.sh
    ```

## Running the test cases against a custom Babelfish endpoint
By default the tests will run against the server running on localhost. You can specify a custom endpoint, database, user etc. in `test/JDBC/src/main/resources/config.txt`. 
The [config file](src/main/resources/config.txt) has many other options you can change for your test runs. Alternatively, you can also set these options with environment variables as shown below:
```bash
export databaseName = test_db
```

## Controlling which test cases should run
By default all the tests will run. You can run one or more individual tests by specifying test information in the `test/JDBC/jdbc_schedule` file

## Writing the test cases
### Using a plain SQL Batch
When adding tests that execute SQL code, separate SQL batches with `GO`:
```tsql
/* SQL Batch 1 */
GO

/* SQL Batch 2 */
GO
```

**Example**
```tsql
CREATE TABLE t1 (a int)
GO

INSERT INTO t1
VALUES (1)
GO
```

Input file type: `.sql`

---

### Preparing and executing statements
To prepare and execute a query:
```
prepst#!# <query> #!# <bind variables datatype, name and value groups follow, separated by '#!#' delimiter>
```

To execute a prepared query:
```
prepst#!#exec#!# <bind variables datatype, name and value groups follow, separated by '#!#' delimiter>
```

Bind variables should be mentioned in groups:
``` 
<bind variable datatype> |-| <bind variable name> |-| <bind variable value>
```

**Example**

To prepare the statement: `SELECT [Gender] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = ?` with the bind variable `1` add your query as shown below:
```
prepst#!#SELECT [Gender] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = @a#!#int|-|a|-|1
```

**NOTE:** To specify NULL values in a prepared or execute statement, specify them as `<NULL>`

Input file type: `.txt`

---

### Using a stored procedure
This section covers how to execute stored procedures using JDBC APIs. To execute stored procedures as a SQL batch, refer [to these instructions](#plain-sql-batch).

To prepare and execute a stored procedure:
```
storedproc#!#prep#!# <stored procedure name> #!# <param datatype, name, value and type groups follow, separated by '#!#' delimiter>
```

To execute an already prepared stored procedure:
```
storedproc#!#exec#!# <stored procedure name> #!# <param datatype, name, value and type groups follow, separated by '#!#' delimiter>
```

Bind variables should be mentioned in groups:
``` 
<param datatype> |-| <param name> |-| <param value> |-| {input | output | inputoutput}
```

**Example**
```
CREATE PROCEDURE sp_test1 (@a  INT) AS BEGIN SET @a=100; Select @a as a; END;
storedproc#!#prep#!#sp_test1#!#int|-|a|-|1|-|input
```

**NOTE:** To specify NULL values in stored procedure parameters, specify them as `<NULL>`

Input file type: `.txt`

---

### Using a transaction
This section covers how to execute transactional statements using JDBC APIs. For information about executing transactional statements as a SQL Batch, refer [to these instructions](#plain-sql-batch).

Execute a transactional statement:
```
txn#!#begin                                  // to begin a transaction
txn#!#commit                                 // to commit
txn#!#rollback                               // to rollback
txn#!#savepoint                              // to create a new savepoint
txn#!#rollback#!# < name of savepoint >      // to rollback to a named savepoint
txn#!#savepoint#!# < name of savepoint >     // to create a new savepoint with name
txn#!#isolation#!# {ru | rc | rr | se | sn}  // to set transaction isolation level
```

The abbreviations for isolation levels are:
1. `ru` → READ UNCOMMITTED
2. `rc` → READ COMMITTED
3. `rr` → REPEATABLE READ
4. `se` → SERIALIZABLE
5. `sn` → SNAPSHOT

**Example**
```
txn#!#isolation#!#ru
txn#!#begin
select @@TRANCOUNT as txncnt
txn#!#savepoint#!#SP1
txn#!#rollback#!#SP1
txn#!#begin
select @@TRANCOUNT as txncnt
txn#!#commit
```

**NOTE:** JDBC does not support the API Connection.beginTransaction() function, so in this case `txn#!#begin` will simply set auto commit to false so that transactions are committed only when Connection.commit() is called explicitly.

Input file type: `.txt`

---

### Using a cursor
To open a cursor:
```
cursor#!#open#!# <select statement on which cursor is opened> #!# <cursor options follow, separated by '#!#' delimiter>
```

The supported cursor options are:
- `TYPE_FORWARD_ONLY` → cursor type as forward-only
- `TYPE_SCROLL_SENSITIVE` → cursor type as scroll sensitive
- `TYPE_SCROLL_INSENSITIVE`  → cursor type as scroll insensitive
- `CONCUR_READ_ONLY` → cursor concurrency as read-only
- `CONCUR_UPDATABALE` → cursor concurrency as updatable                                 
- `HOLD_CURSORS_OVER_COMMIT` → cursor holdability as hold cursors over commit
- `CLOSE_CURSORS_AT_COMMIT` → cursor holdability as close cursors after commit

**NOTE:** If one or more of the cursor options are not provided, the cursor options will be:
- `TYPE_FORWARD_ONLY` → cursor type as forward-only
- `CONCUR_READ_ONLY` → cursor concurrency as read-only
- `HOLD_CURSORS_OVER_COMMIT` → cursor holdability as hold cursors over commit

To fetch, use the following cursor options:
```
cursor#!#fetch#!#beforefirst               // move cursor before first row
cursor#!#fetch#!#afterlast                 // move cursor after last row
cursor#!#fetch#!#first                     // fetch first row of result set
cursor#!#fetch#!#last                      // fetch last row of result set
cursor#!#fetch#!#next                      // fetch next row of result set
cursor#!#fetch#!#prev                      // fetch previous row of result set
cursor#!#fetch#!#abs#!# <row number>       // fetch from row number specified
cursor#!#fetch#!#rel#!# <number of rows>   // fetch relatively from current cursor position by number of rows specified
```

Use the following command to close a cursor:
```
cursor#!#close
```

**Example**
```
cursor#!#open#!#SELECT * FROM test_cursors_fetch_next#!#TYPE_SCROLL_INSENSITIVE#!#CONCUR_READ_ONLY#!#CLOSE_CURSORS_AT_COMMIT
cursor#!#fetch#!#next
cursor#!#close
```

Input file type: `.txt`

---

### Verifying SQL Authentication test cases
Use the following command syntax to verify different authentication use cases with the JDBC SQL Server Driver:
```
java_auth#!# < connection attribute and value pairs follow, separated by '#!#' delimiter>
```

Provide the connection information in an attribute-value pair:
```
<connection attribute> |-| <value>
```

To review a list of valid connection property types and values, [visit this page](https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/connect/jdbc/setting-the-connection-properties.md#properties).

**Example**
```
java_auth#!#databaseName|-|master
java_auth#!#user|-|dummy#!#password|-|hello#!#databaseName|-|demo
```

Input file type: `.txt`

---

### Intermixing queries in T-SQL and PL/pgSQL dialect (cross dialect test cases)
A SQL Batch in T-SQL should be added as:
```tsql
-- tsql <T-SQL connection attribute and value pairs if any, separated by spaces>
/* T-SQL batch */
GO
```

A SQL Batch in PL/pgSQL should be added as:
```tsql
-- psql <PSQL connection attribute and value pairs if any, separated by spaces>
/* PL/pgSQL batch */
GO
```

**NOTE:** Even though `GO` is not a batch separater in PL/pgSQL, it needs to added because the test framework uses it as a delimiter internally to process these SQL batches.

Connection attributes should be specified in pairs:
```
<connection attribute 1>=<value 1>     <connection attribute 2>=<value 2> ...
```

Currently, the connection accepts the following attributes:
- `user`
- `password`
- `database`
- `currentSchema` (only for a PG connection)

**Example**
```tsql
-- tsql
CREATE PROCEDURE tsql_interop_proc1
AS
UPDATE procTab1 SET c1=10 where c2='b';
INSERT INTO procTab1 values(1,'a');
INSERT INTO procTab1 values(2,'b');
EXEC psql_interop_proc2;
GO

-- psql     currentSchema=master_dbo,public
CREATE PROCEDURE psql_interop_proc1()
AS
$$
BEGIN
    CREATE TABLE procTab1(c1 int);
    INSERT INTO procTab1 values (5);
    ALTER TABLE procTab1 ADD c2 char;
    CALL tsql_interop_proc1();
END
$$ LANGUAGE PLPGSQL;
GO

CREATE PROCEDURE psql_interop_proc2()
AS
$$
BEGIN
    INSERT INTO procTab1(c1,c2) values (3,'c');
    UPDATE procTab1 SET c1=10 where c2='b';
    INSERT INTO procTab1(c1,c2) values (4,'d');
    DELETE FROM procTab1 where c2='a';
END
$$ LANGUAGE PLPGSQL;
GO

-- tsql
EXEC psql_interop_proc1
GO
SELECT * FROM procTab1 order by c1
GO

-- psql     currentSchema=master_dbo,public
CALL tsql_interop_proc1()
GO
SELECT DISTINCT c1 FROM procTab1
GO
```

Input file type: `.mix`

---

### **IMPORTANT**
- If you want to execute a SQL Batch in `.txt` input files, you will need to specify the batch in a single line without the `GO` batch separator. This is needed because for `.txt` files, the test framework treates every line as a standalone statement/command that can be executed against the server.
- You CANNOT group functionalities from a different file type. For example, you cannot execute prep-exec statements (functionality of `.txt` input file) in a `.mix` file. 

## Adding the test cases
The test framework consumes `.sql`, `.txt` and `.mix` files as input (discussed above) and uses them to generate the output (.out) files.

1. Add your input file to the `test/JDBC/input` directory. For convenience, you can use subdirectories within the directory to organize test files.
2. Run the test framework to generate the output file (you may want to edit the schedule file to only the run the tests that you have added instead of running all the tests). The test will fail because it does not have a corresponding expected output file yet.
3. Check the `test/JDBC/output` directory for the generated output file. The output file (.out) will be of the format:
    ```
    test/JDBC/output/<your_test_filename>.out
    ```
4. If the output file looks correct to you, move it to the `test/JDBC/expected` directory:
    ```
    mv test/JDBC/output/<your_test_filename>.out test/JDBC/expected
    ```
5. Re-run the test framework to ensure that the newly added test generates the expected result set and passes.

## Reading the console output and diff
If all the tests PASS, `TESTS FAILED` will be zero and you will be greeted with a `BUILD SUCCESS` message:
```
###########################################################################
TOTAL TESTS:	575
TESTS PASSED:	575
TESTS FAILED:	0
###########################################################################
.
.
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

If one or more tests FAIL, `TESTS FAILED` will not be zero and you will be greeted with a `BUILD FAILURE` message:
```
###########################################################################
TOTAL TESTS:	574
TESTS PASSED:	573
TESTS FAILED:	1
###########################################################################
Output diff can be found in '/home/runner/work/babelfish_extensions/babelfish_extensions/test/JDBC/Info/12-03-2045T06:07:08.009/12-03-2045T06:07:08.009.diff'
.
.
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
```

You will also be provided with the location of the `.diff` file containing the difference between the generated output and expected output. The diff file name is a date/time stamp, in the form `dd-MM-yyyy'T'HH:mm:ss.SSS` where:
- `dd`   → date
- `MM`   → month
- `yyyy` → year
- `HH`   → hour
- `mm`   → minutes
- `ss`   → seconds
- `SSS`  → milliseconds


## Running Tests with Parallel Query Enabled

After building the modified PostgreSQL engine and Babelfish extensions using the [online instructions](../../contrib/README.md), you must:
1. Create a PostgreSQL database and initialize Babelfish (if you already have a database with Babelfish initialized, you can omit this step or perform the cleanup steps before you initialize) to enable parallel query mode pass -enable_parallel_query flag when running ./init.sh

   ```bash
    ./init.sh -enable_parallel_query
    ```
3. Before running JDBC tests, please take note that currently not all JDBC tests runs sucessfully with parallel query mode on. Certain JDBC tests are encountering issues, such as crashes, failures, or timeouts when executed with parallel query mode enabled. So we need these problematic tests to be excluded from running via jdbc framework. File  `parallel_query_jdbc_schedule` contains test-cases names with prefix `ignore#!#` that are problematic and needs to be avoided from being run. To exclude these problematic tests from running via the JDBC framework, use the `isParallelQueryMode` environment variable. You can set it to `true`:

   ```bash
    export isParallelQueryMode=true
    # Verify if isParallelQueryMode is set to true
    echo $isParallelQueryMode
   ```
4. Now Run the tests:
    ```bash
    mvn test
    ```
5. If the expected output is different when run in parallel query mode and in normal mode, one can add a different expected output specially for parallel query mode in `expected/parallel_query/` folder. Additionally, one needs to add `-- parallel_query_expected` flag in the corresponding input file.
6. If you want to have different SLA timeout when test runs in parallel query mode then use `-- sla_for_parallel_query_enforced` flag in the corresponding input file.
7. Cleanup all the objects, users, roles and databases created while running the tests:
    ```bash
    ./cleanup.sh
    ```
8. Please note that when you have completed testing with parallel query mode enabled, you should unset the `isParallelQueryMode` environment variable that was previously set to `true`. This ensures that all tests run in the normal Babelfish mode (without parallel query):

   ```bash
    unset isParallelQueryMode
   ```
If you encounter failing or crashing tests in the "JDBC tests with parallel query" GitHub workflow, consider adding the names of these problematic test cases to the `parallel_query_jdbc_schedule` file. Prefix these test case names with `ignore#!#`. As we work towards resolving these issues in the future, we will gradually remove these excluded tests from the `parallel_query_jdbc_schedule` scheduling file.

## Running Tests with Non Default Server Collation

After building the modified PostgreSQL engine and Babelfish extensions using the [online instructions](../../contrib/README.md), you must:
1. Create a PostgreSQL database and to initializing Babelfish extensions with non-default server collation add following line with server collation name of your choice in `postgres/data/postgresql.conf` and restart engine, then initialize Babelfish extensions using the [online instructions](../../contrib/README.md)

   ```bash
   babelfishpg_tsql.server_collation_name = '<server_collation_name>'
    ```
2. Before running JDBC tests, set the `serverCollationName` environment variable to the current server collation name:

   ```bash
    export serverCollationName=<server_collation_name>
    # Verify if serverCollationName is set to correct collation name
    echo $serverCollationName
   ```
3. Now Run the tests:
    ```bash
    mvn test
    ```
4. How to add expected output for some test
    1. By default expected output of a test should be added into `expected` folder.
    2. If JDBC is running in normal mode with server collation=<server_collation_name> and expected output of some test is different then add this new expected output in `expected/non_default_server_collation/<server_collation_name>` folder.
    3. If JDBC is running in parallel query mode with default server collation and expected output of some test is different then the expected output should be added in `expected/parallel_query` folder.(As mentioned in [Running Tests with Parallel Query Enabled](#running-tests-with-parallel-query-enabled))
    4. If JDBC is running in parallel query mode with server collation=<server_collation_name> and expected output of some test is different then add this new expected output in `expected/parallel_query/non_default_server_collation/<server_collation_name>` folder.

5. Cleanup all the objects, users, roles and databases created while running the tests:
    ```bash
    ./cleanup.sh
    ```
6. Please note that whenever you had changed the server collation and reinitialised Babelfish extensions update the `serverCollationName` environment variable with appropriate server collation name and unset when server collation name is set to default server collation.
    ```bash
    unset serverCollationName
    ```
    This ensures that correct expected output is picked for current server collation name.
