#ifndef DATABASE_OBJECTS_H
#define DATABASE_OBJECTS_H

#include "odbc_handler.h"
#include <string>
#include <map>
#include <vector>


class DatabaseObjects {

  public:

  DatabaseObjects();
  ~DatabaseObjects();

  void CreateSchema(const std::string &schema_name);
  // table_name may include database and/or schema name, e.g. schema_name.table_name
  void CreateTable(const std::string &table_name, const std::vector<std::pair <std::string, std::string>> &columns, const std::string constraints = "");
  // view_name may include database and/or schema name, e.g. schema_name.view_name
  void CreateView(const std::string &view_name, const std::string &select_statement);
  // procedure_name may include database and/or schema name, e.g. schema_name.procedure_name
  void CreateProcedure(const std::string &procedure_name, const std::string &procedure_definition, const std::string parameters = "");
  // function_name may include database and/or schema name, e.g. schema_name.function_name
  void CreateFunction(const std::string &function_name, const std::string &function_definition);
  
  // Drop object. Object type can be "TABLE", "VIEW", "PROCEDURE", etc. Any valid database object type.
  // If check_exists is true, the statement will contain 'IF EXISTS'
  void DropObject(const std::string &object_kind, const std::string &object_name, bool check_exists = true);

  // values contain valid values expression for all values to be inserted. 
  // e.g. "(1), (2), (3)" - for a single column table
  // e.g. "(1, 'hello1', 1.1), (2, 'hello2', 2.2)  - for a three-column table
  void Insert(const std::string &table_name,const std::string &values);
  
  // Each element in the values vector contains data for a single row with no ().
  // e.g. values[0] = "1"; values[1] = "2" - for a single column table
  // e.g. values[0] = "1, 'hello1', 1.1"; values[1] = "2, 'hello2', 2.2" - for a three-column table
  void Insert(const std::string &table_name, const std::vector<std::string> &values);

  private:
    
  OdbcHandler odbcHandler;
  std::vector<std::string> schemas;
  std::vector<std::string> tables;
  std::vector<std::string> views;
  std::vector<std::string> functions;
  std::vector<std::string> procedures;

  void DropObjects(const std::string &object_kind, const std::vector<std::string> &names);
};

#endif

