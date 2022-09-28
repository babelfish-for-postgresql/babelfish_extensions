#include "query_generator.h"

#include <iostream>

using std::string;
using std::map;
using std::vector;
using std::pair;

string CreateColumnsString(const vector<string> &columns) {
    string result {};
    string comma{};

    for (auto column : columns) {
        result += comma + column;
        comma = ",";
    }
    return result;
}

string CreateColumnsString(const vector<pair <string, string>> &columns) {
    string result{};
    string comma{};

    for (auto column : columns) {
        result += comma + column.first + " " + column.second;
        comma = ",";
    }
    return result;
}

string CreateInsertValuesString(const vector<string> &values) {
  string result{};
  string comma{};

  for (auto value : values) {
        result += comma + "(" + value + ")";
        comma = ",";
    }
    return result;
}

// Convenience overload of the 'full' Select statement so that empty reference parameters are not required by callers.
string SelectStatement(const string &table_name, const vector<string> &select_columns) {
  return  SelectStatement(table_name, select_columns, vector<string> {});
}

// Simple select form one table or view. No joins.
string SelectStatement(const string &table_name, const vector<string> &select_columns, const vector<string> &orderby_columns, const string where_clause) {
  string result {"SELECT " + CreateColumnsString(select_columns) + 
     "\nFROM " + table_name};
  
  if (where_clause != "") {
    result += "\nWHERE " + where_clause;
  }

  if (!orderby_columns.empty()) {
    result += "\nORDER BY " + CreateColumnsString(orderby_columns);
  }

  return result;
}

// Rudimentary insert statement
// The values string contains 'full' values string for all data, e.g.
// "(NULL, NULL), (' ',' '), (' John',' Doe'), ('John','Doe')"
string InsertStatement(const string &table_name, const string &values) {
  return {"INSERT INTO " + table_name + " VALUES " + values};
}

// Rudimentary insert statement
// Each string in values vector represents values for  a single row without the (), e.g.
//{"NULL, NULL, NULL", "1, 'hello1', 1.1", "2, 'hello2', 2.2"}
string InsertStatement(const string &table_name, const vector<string> &values) {
  return {"INSERT INTO " + table_name + " VALUES " + CreateInsertValuesString(values)};
}
 
string CreateSchemaStatement(const string &schema_name) {
  return string {"CREATE SCHEMA " + schema_name}; 
}

//TODO Perhaps create 'Alter table ADD Constraint' function so that constraints can be added after the table was created.
string CreateTableStatement(const string &table_name, const vector<pair <string, string>> &columns, string constraints) {

  return string {"CREATE TABLE " + table_name + "(\n" + CreateColumnsString(columns) + 
                string { constraints.empty() ? "" : " \n, " + constraints } + "\n);"};
}

string CreateViewStatement(const string &view_name, const string &select_statement) {
  
  return string {"CREATE VIEW " + view_name + " AS \n " + select_statement + ";"};
}


string CreateProcedureStatement(const string &procedure_name, const string &procedure_definition, const string &parameters) {

  return string {"CREATE PROCEDURE  " + procedure_name + " " + parameters + " AS \n " + procedure_definition + ";"};
}


string CreateFunctionStatement(const string &function_name, const string &function_definition) {

  return string {"CREATE FUNCTION " + function_name + " \n" + function_definition + ";"};
}


string DropObjectStatement(const string &object_kind, const string &object_name, bool check_exists) {

  return string { "DROP " + object_kind +  string { check_exists ? " IF EXISTS " : " "}  + object_name };
}

string PrimaryKeyConstraintSpec(const string &pk_name, const vector<string> &columns) {

  return string  {" CONSTRAINT " + pk_name + " PRIMARY KEY(" + CreateColumnsString(columns) + ")"};
}

string ForeignKeyConstraintSpec(const string &fk_name,
  const vector<string> &columns, 
  const string &ref_table,
  const vector<string> &ref_columns) {
    
  return string  {" CONSTRAINT " + fk_name + " FOREIGN KEY(" + CreateColumnsString(columns) + ") \nREFERENCES " + 
                  ref_table + "(" + CreateColumnsString(ref_columns) + ")"};
}
