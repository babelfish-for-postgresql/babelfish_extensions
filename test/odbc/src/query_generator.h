#ifndef QUERY_GENERATOR_H
#define QUERY_GENERATOR_H

#include <string>
#include <map>
#include <vector>
#include <utility>

std::string CreateSchemaStatement(const std::string &schema_name);

// table_name may include database and/or schema name, e.g. schema_name.table_name
// columns map contains pairs column name : data type
// data type optionally may contain additional specification, e.g. NULL, not NULL, identity, default specifications, etc.
//std::string CreateTableStatement(std::string &table_name, std::map<std::string, std::string> &columns);
std::string CreateTableStatement(const std::string &table_name, 
  const std::vector<std::pair <std::string, std::string>> &columns, 
  std::string constraints = "");

// view_name may include database and/or schema name, e.g. schema_name.view_name
std::string CreateViewStatement(const std::string &view_name, const std::string &select_statement);

// procedure_name may include database and/or schema name, e.g. schema_name.procedure_name
std::string CreateProcedureStatement(const std::string &procedure_name, const std::string &procedure_definition, const std::string &parameters);

// function_name may include database and/or schema name, e.g. schema_name.function_name
std::string CreateFunctionStatement(const std::string &function_name, const std::string &function_definition);

// Object type can be "TABLE", "VIEW", "PROCEDURE", etc. Any valid database object type.
// If check_exists is true, the statement will contain 'IF EXISTS'
std::string DropObjectStatement(const std::string &object_kind, const std::string &object_name, bool check_exists = true);

// select_columns contain column names to be included in the select statement
std::string SelectStatement(const std::string &table_name, 
  const std::vector<std::string> &select_columns);

// select_columns contain column names to be included in the select statement
// orderby_columns contain column names to be included in the order by clause
// where clause is a valid list of conditions without the 'where keyword', e.g. "id=123 and name='John'"
std::string SelectStatement(const std::string &table_name, 
  const std::vector<std::string> &select_columns, 
  const std::vector<std::string> &orderby_columns, 
  const std::string where_clause = "");

// values contain valid values expression for all values to be inserted. 
// e.g. "(1), (2), (3)" - for a single column table
// e.g. "(1, 'hello1', 1.1), (2, 'hello2', 2.2)  - for a three-column table
std::string InsertStatement(const std::string &table_name, const std::string &values);

// Each element in the values vector contains data for a single row with no ().
// e.g. values[0] = "1"; values[1] = "2" - for a single column table
// e.g. values[0] = "1, 'hello1', 1.1"; values[1] = "2, 'hello2', 2.2" - for a three-column table
std::string InsertStatement(const std::string &table_name, const std::vector<std::string> &values);

// Generate a primary key constraint part of SQL statement. 
// columns contain column names that are part of the primary key.
std::string PrimaryKeyConstraintSpec(const std::string &pk_name, const std::vector<std::string> &columns);

// Generate a foreign key constraint part of SQL statement. 
// columns contain column names that are part of the foreign key.
// ref_table is the table name that the foreign key is referencing
// ref_columns contain column names in the referenced table.
std::string ForeignKeyConstraintSpec(const std::string &fk_name,
  const std::vector<std::string> &columns, 
  const std::string &ref_table,
  const std::vector<std::string> &ref_columns);

#endif
