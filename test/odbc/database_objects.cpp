#include "database_objects.h"
#include "query_generator.h"

#include <iostream>

using std::string;
using std::vector;
using std::pair;

DatabaseObjects::DatabaseObjects() {

  odbcHandler.Connect(true);
}

DatabaseObjects::~DatabaseObjects() {
 
  DropObjects("PROCEDURE", procedures);
  DropObjects("FUNCTION", functions);
  
  DropObjects("VIEW", views);
  DropObjects("TABLE", tables);
  DropObjects("SCHEMA", schemas);
}

void DatabaseObjects::CreateSchema(const string &schema_name) {
  
  DropObject("SCHEMA", schema_name); 
  odbcHandler.ExecQuery(CreateSchemaStatement(schema_name));
  schemas.push_back(schema_name);
}

void DatabaseObjects::CreateTable(const string &table_name, const vector<pair <string, string>> &columns, const string constraints) {

  DropObject("TABLE", table_name); 
  odbcHandler.ExecQuery(CreateTableStatement(table_name, columns, constraints));
  tables.push_back(table_name);
}

void DatabaseObjects::DatabaseObjects::CreateView(const string &view_name, const string &select_statement) {

  DropObject("VIEW",view_name); 
  odbcHandler.ExecQuery(CreateViewStatement(view_name, select_statement));
  views.push_back(view_name);
}

void DatabaseObjects::CreateProcedure(const string &procedure_name, const string &procedure_definition, const string parameters) {

  DropObject("PROCEDURE",procedure_name); 
  odbcHandler.ExecQuery(CreateProcedureStatement(procedure_name, procedure_definition, parameters));
  procedures.push_back(procedure_name);
}

void DatabaseObjects::CreateFunction(const string &function_name, const string &function_definition) {

  DropObject("FUNCTION",function_name); 
  odbcHandler.ExecQuery(CreateFunctionStatement(function_name, function_definition));
  functions.push_back(function_name);
}

void DatabaseObjects::Insert(const string &table_name,const string &values) {
  odbcHandler.ExecQuery(InsertStatement(table_name, values));
}

void DatabaseObjects::Insert(const string &table_name, const vector<string> &values) {
  
  odbcHandler.ExecQuery(InsertStatement(table_name, values));
}

void DatabaseObjects::DropObject(const string &object_kind, const string &object_name, bool check_exists) {
  
  odbcHandler.ExecQuery(DropObjectStatement(object_kind,object_name,check_exists));
}

void DatabaseObjects::DropObjects(const string &object_kind, const vector<string> &names) {
  
  // Drop objects in reverse order from the one they were created. 
  // This is in case the later objects have dependency on earlier ones(e.g. foreign key)
  for (auto it =  names.rbegin(); it != names.rend(); ++it) {
    DropObject(object_kind, *it); 
  }
}

