// NOT UPTO DATE

###############################################################################################################
################################### HOW TO CREATE AND RUN TESTS OF YOUR OWN ###################################
###############################################################################################################

1. Create a .txt File and Place them in Project-Folder/Queries Folder. For format of queries check the next section. 
   You can even give your own query folder path in the config file.

2. In the config file under the section of TestName you can add the name of your tests separated by a semicolon 
   For example TestName~SimpleSelect;DataMathFunctions;PrepareExecOneVariable

   Or you could run for all tests by setting it as shown --> TestName~all


###############################################################################################################
############################################ CONFIGURATIONS TO ADD ############################################ 
###############################################################################################################

In Queries/config.txt:

1. sqlConnectionString and bblConnectionString are the respective connection Strings for SQL Server and Babel.
   (IF YOU USE "CompareWithExpectedOutput" OR "fileGenerator" AS TRUE, THEN ONLY CONNECTION WITH bblConnectionString WILL BE ESTABLISHED)

2. captureInterface is the interface at which the packets are received on your machine for example for Mac it is utun2, for Win-Ethernet and for Ubuntu- ens5

3. Set tcp-dump true for Packet comparison and false if you want only result-level comparison.

4. queryFolder - Please add full path of your query folder to this key.

5. fileGeneratorConnectionString - *SET THIS CONNECTION STRING TO GENERATE THE EXPECTED OUTPUT FILE*

6. For Flags to be set for execution modes, check config.txt in the project folder. It has the necessary comments.

###############################################################################################################
################################### HOW TO ADD YOUR OWN QUERIES FOR TESTING ###################################
###############################################################################################################

1.  For a Prepare/Execute query:

    prepst#!# <QUERY TO PREPARE> #!# <PARAMETER DEFINATION>

    Parameter definitions should be separated by '|-|' as: <PARAMETER DATATYPE> |-| <PARAMETER NAME> |-| <PARAMETER VALUE>

    Eg. If you wish to prepare the statement: "SELECT [Gender] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = @a"
        with the bind variable 1 (int). Then you will add your query as shown below:

        prepst#!#SELECT [Gender] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = @a#!#int|-|a|-|1

2.  For an Execute query:

    prepst#!#exec#!# <PARAMETER DEFINATION>

    Parameter definitions should be separated by '|-|' as: <PARAMETER DATATYPE> ~ <PARAMETER NAME> ~ <PARAMETER VALUE>

3.  If it is a basic SQL query:

    <basic SQL query>

    i.e. as the query as it is.

    Eg. If you wish to add the query "SELECT * FROM [HumanResources].[Employee]". Then add your query as shown below:

    SELECT * FROM [HumanResources].[Employee]

4.  For a Transaction query:
    
    Option to run the queries as basic SQL queries as mentioned above, by simply using the queries you would run on sqlCmd

    Or you can use the connection properties to begin/commit/savepoint etc:- 
    txn#!# <begin/commit/rollback/savepoint>#!# transaction-name/savepoint-name
    For Isolation Levels:- 
    txn#!#begin#!#isolation#!#< rc/rr/ru/s/ss > 
    Where rc is READ COMMITED
    Where rr is REPEATABLE READ
    Where ru is READ UNCOMMITED
    Where s  is READ SERIALIZABLE
    Where ss is READ SNAPSHOT
