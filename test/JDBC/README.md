# JDBC Test Framework for Babelfish
The JDBC test framework for Babelfish uses the JDBC Driver for SQL Server for database connectivity and allows us to do end-to-end testing (i.e. testing of the T-SQL syntax and TDS protocol implementation) of Babelfish without the need to write any application level code.

## Table of Contents
- [How to run the test framework](#how-to-run-the-test-framework)
  - [Build Requirements](#build-requirements)
  - [Steps to run](#steps-to-run)
- [How to run tests against a custom Babelfish endpoint](#how-to-run-tests-against-a-custom-babelfish-endpoint)
- [How to control which tests should run](#how-to-control-which-tests-should-run)
- [Writing tests](#writing-tests)
  - [Plain SQL Batch](#plain-sql-batch)
  - [Prepare Exec statements](#prepare-exec-statements)
  - [Stored Procedures](#stored-procedures)
  - [Transactions](#transactions)
  - [Cursors](#cursors)
  - [SQL Authentication](#sql-authentication)
  - [Cross-dialect](#cross-dialect-intermixing-queries-in-t-sql-and-plpgsql-dialect)
  - [IMPORTANT](#important)
- [Adding tests](#adding-tests)
- [Reading the console output and diff](#reading-the-console-output-and-diff)

## How to run the test framework

### Build Requirements

Java, Maven

### Steps to run
Once you have built the modified Postgres engine and Babelfish extensions from [here](https://github.com/babelfish-for-postgresql/babelfish_extensions/blob/BABEL_1_X_DEV/contrib/README.md), do the following:
1. Create a postgres database and initialize babelfish in it (if you already have a database with babelfish initialized you can omit this step or cleanup before you initialize)
    ```bash
    ./init.sh
    ```
2. Run the tests
    ```bash
    mvn test
    ```
3. Cleanup all the objects, users, roles and databases created while running the tests
    ```bash
    ./cleanup.sh
    ```

## How to run tests against a custom Babelfish endpoint
By default the tests will run against the server running on localhost. You can specify a custom endpoint, database, user etc. in `test/JDBC/src/main/resources/config.txt`. 
The [config file](https://github.com/babelfish-for-postgresql/babelfish_extensions/blob/BABEL_1_X_DEV/test/JDBC/src/main/resources/config.txt) has many other options you can change for your test runs. Alternatively, you can also set these option through environment variables as follows:
```bash
export databaseName = test_db
```

## How to control which tests should run
By default all the tests will run. You can specify which tests should run in the `test/JDBC/jdbc_schedule` file

## Writing tests
### Plain SQL Batch
Separate SQL Batches with `GO`:
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

### Prepare Exec statements
To prepare and execute query:
```
prepst#!# <query> #!# <bind variables datatype, name and value groups follow, separated by '#!#' delimiter>
```

To execute an already prepare query:
```
prepst#!#exec#!# <bind variables datatype, name and value groups follow, separated by '#!#' delimiter>
```

Bind variables should be mentioned in groups:
``` 
<bind variable datatype> |-| <bind variable name> |-| <bind variable value>
```

**Example**

If you wish to prepare the statement: `SELECT [Gender] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = ?` with the bind variable `1`. Then you will add your query as shown below:
```
prepst#!#SELECT [Gender] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = @a#!#int|-|a|-|1
```

**NOTE:** To specify NULL values in prepare exec statement, specify them as `<NULL>`

Input file type: `.txt`

---

### Stored Procedures
This section covers how to execute stored procedures using JDBC APIs. To execute stored procedures as a SQL batch refer [here](#plain-sql-batch).

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

**NOTE:** To specify NULL values in stored procedure params, specify them as `<NULL>`

Input file type: `.txt`

---

### Transactions
This section covers how to execute transactional statements using JDBC APIs. To execute transactional as a SQL Batch refer [here](#plain-sql-batch).

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

Codes for isolation levels are as follows:
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

**NOTE:** JDBC does not support API like Connection.beginTransaction() so in this case `txn#!#begin`  will simply set auto commit to false so that transactions are committed only when Connection.commit() is called explicitly.

Input file type: `.txt`

---

### Cursors
Open a cursor:
```
cursor#!#open#!# <select statement on which cursor is opened> #!# <cursor options follow, separated by '#!#' delimiter>
```

Codes for cursor options are as follows:
- `TYPE_FORWARD_ONLY` → cursor type as forward-only
- `TYPE_SCROLL_SENSITIVE` → cursor type as scroll sensitive
- `TYPE_SCROLL_INSENSITIVE`  → cursor type as scroll insensitive
- `CONCUR_READ_ONLY` → cursor concurrency as read-only
- `CONCUR_UPDATABALE` → cursor concurrency as updatable                                 
- `HOLD_CURSORS_OVER_COMMIT` → cursor holdability as hold cursors over commit
- `CLOSE_CURSORS_AT_COMMIT` → cursor holdability as close cursors after commit

**NOTE:** If one or more of the cursor options are not provided, default values of those option will be applied

Fetch using a cursor:
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

Close a cursor:
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

### SQL Authentication
To check different authentication use cases via JDBC SQL Server Driver:
```
java_auth#!# < connection attribute and value pairs follow, separated by '#!#' delimiter>
```

The connection attribute and value are to be mentioned as pairs:
```
<connection attribute> |-| <value>
```

List of valid connection property types and values are [here](https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/connect/jdbc/setting-the-connection-properties.md#properties)

**Example**
```
java_auth#!#databaseName|-|master
java_auth#!#user|-|dummy#!#password|-|hello#!#databaseName|-|demo
```

Input file type: `.txt`

---

### Cross Dialect (intermixing queries in T-SQL and PL/pgSQL dialect)
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

Currently the attributes that can specified are `user`, `password`, `database` and `currentSchema` (only for PG connection).

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
- You CANNOT club functionalities of different file types. For example, you cannot execute prep-exec statements (functionality of `.txt` input file) in a `.mix` file. 

## Adding tests
The test framework consumes `.sql`, `.txt` and `.mix` files as input (discussed above) and uses them to generate the output (.out) files.

1. Add the input test file in the `test/JDBC/input` directory. You can also create subdirectories and test files inside those
2. Run the test framework to generate the output file (you may want to edit the schedule file to only the run the tests that you have added instead of running all the tests). The test will fail because it does not have a corresponding expected output file yet.
3. Check the `test/JDBC/output` directory for the generated output file. The output file (.out) will be of the format:
    ```
    test/JDBC/output/<your_test_filename>.out
    ```
4. If the output file looks correct to you, move it to the `test/JDBC/expected` directory:
    ```
    mv test/JDBC/output/<your_test_filename>.out test/JDBC/expected
    ```
5. Re-run the test framework and ensure that the newly added test now passes

## Reading the console output and diff
If all the tests PASS, `TESTS FAILED` will be zero and you will be greeted with a `BUILD SUCCESS` message
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

If one or more tests FAIL, `TESTS FAILED` will not be zero and you will be greeted with a `BUILD FAILURE` message
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

You will also be provided with the location of the `.diff` file which contains the diff between the generated output and expected output. The format of the name of the diff file is `dd-MM-yyyy'T'HH:mm:ss.SSS` where
- `dd`   → date
- `MM`   → month
- `yyyy` → year
- `HH`   → hour
- `mm`   → minutes
- `ss`   → seconds
- `SSS`  → milliseconds
