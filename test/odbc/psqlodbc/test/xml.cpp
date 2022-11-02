#include "../psqlodbc_tests_common.h"

const string BBF_TABLE_NAME = "master.dbo.xml_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.xml_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.xml_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.xml_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "xml";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

const string SIMPLE_XML = "<root>\
  <book>-148708948</book>\
  <leaf>simple</leaf>\
  <remain>shake</remain>\
  <football>nest</football>\
  <blanket>1275892738</blanket>\
  <try>-249153758.16992378</try>\
  </root>";

const string NORMAL_XML = "<root>\
  <that>hot</that>\
  <anyone>1386369263.1890697</anyone>\
  <finest>believed</finest>\
  <song>\
  <stems>\
  <headed>1563641070.153514</headed>\
  <bring>-1175941901.956747</bring>\
  <stand>-494359546.04893684</stand>\
  <pole>774686962</pole>\
  <outer>production</outer>\
  <why>applied</why>\
  </stems>\
  <breeze>1269756220</breeze>\
  <cookies>544666062</cookies>\
  <yesterday>grade</yesterday>\
  <power>-663154896.7426605</power>\
  <topic>stomach</topic>\
  </song>\
  <fact>-1834471409</fact>\
  <repeat>-1980145795</repeat>\
  </root>";

const string LARGE_XML = "<Root>\
  <sys.tables name=\"tnullfixeddecimal0100\" object_id=\"4195065\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T19:23:37.030\" modify_date=\"2022-02-03T19:23:37.030\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnullfixeddecimal0101\" object_id=\"52195236\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T19:23:37.553\" modify_date=\"2022-02-03T19:23:37.553\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnullfixeddecimal1203\" object_id=\"100195407\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T19:23:38.090\" modify_date=\"2022-02-03T19:23:38.090\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnullfixednumeric0100\" object_id=\"148195578\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T19:23:38.623\" modify_date=\"2022-02-03T19:23:38.623\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtsmalldatetime\" object_id=\"336720252\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:26.013\" modify_date=\"2022-02-03T22:49:26.013\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnullfixednumeric0101\" object_id=\"340196262\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T21:13:14.103\" modify_date=\"2022-02-03T21:13:14.103\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtdatetime\" object_id=\"384720423\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:26.700\" modify_date=\"2022-02-03T22:49:26.700\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtdate\" object_id=\"432720594\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:27.393\" modify_date=\"2022-02-03T22:49:27.393\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldttime\" object_id=\"528720936\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:28.563\" modify_date=\"2022-02-03T22:49:28.563\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtdatetimeoffset0\" object_id=\"576721107\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:29.127\" modify_date=\"2022-02-03T22:49:29.127\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtdatetimeoffset3\" object_id=\"624721278\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:29.697\" modify_date=\"2022-02-03T22:49:29.697\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtdatetime20\" object_id=\"720721620\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:30.803\" modify_date=\"2022-02-03T22:49:30.803\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtdatetime23\" object_id=\"768721791\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:31.373\" modify_date=\"2022-02-03T22:49:31.373\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnullchar1\" object_id=\"795149878\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T02:23:43.220\" modify_date=\"2022-02-03T02:23:43.220\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnulldtdatetime27\" object_id=\"816721962\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T22:49:31.930\" modify_date=\"2022-02-03T22:49:31.930\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  <sys.tables name=\"tnullchar257\" object_id=\"843150049\" schema_id=\"1\" parent_object_id=\"0\" type=\"U \" type_desc=\"USER_TABLE\" create_date=\"2022-02-03T02:23:44.180\" modify_date=\"2022-02-03T02:23:44.180\" is_ms_shipped=\"0\" is_published=\"0\" is_schema_published=\"0\" lob_data_space_id=\"0\" max_column_id_used=\"5\" lock_on_bulk_load=\"0\" uses_ansi_nulls=\"1\" is_replicated=\"0\" has_replication_filter=\"0\" is_merge_published=\"0\" is_sync_tran_subscribed=\"0\" has_unchecked_assembly_data=\"0\" text_in_row_limit=\"0\" large_value_types_out_of_row=\"0\" is_tracked_by_cdc=\"0\" lock_escalation=\"0\" lock_escalation_desc=\"TABLE\" is_filetable=\"0\" is_memory_optimized=\"0\" durability=\"0\" durability_desc=\"SCHEMA_AND_DATA\" temporal_type=\"0\" temporal_type_desc=\"NON_TEMPORAL_TABLE\" is_remote_data_archive_enabled=\"0\" is_external=\"0\" is_node=\"0\" is_edge=\"0\" />\
  </Root>";

class PSQL_DataTypes_Xml : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));

    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", BBF_VIEW_NAME));
    bbf_test_setup.CloseStmt();
    bbf_test_setup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
    
    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", PG_VIEW_NAME));
    pg_test_setup.CloseStmt();
    pg_test_setup.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_Xml, Table_Creation) {
  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  const vector<int> BBF_LENGTH_EXPECTED = {10, 0};
  const vector<int> BBF_PRECISION_EXPECTED = {10, 0};
  const vector<int> BBF_SCALE_EXPECTED = {0, 0};
  const vector<string> BBF_NAME_EXPECTED = {"int", "xml"};

  testCommonColumnAttributes(ServerType::MSSQL, BBF_TABLE_NAME, 
    TABLE_COLUMNS.size(), COL1_NAME, 
    BBF_LENGTH_EXPECTED, BBF_PRECISION_EXPECTED, 
    BBF_SCALE_EXPECTED, BBF_NAME_EXPECTED);

  const vector<int> PG_LENGTH_EXPECTED = {4, 255};
  const vector<int> PG_PRECISION_EXPECTED = {0, 0};
  const vector<int> PG_SCALE_EXPECTED = {0, 0};
  const vector<string> PG_NAME_EXPECTED = {"int4", "xml"};

  testCommonColumnAttributes(ServerType::PSQL, PG_TABLE_NAME, 
    TABLE_COLUMNS.size(), COL1_NAME, 
    PG_LENGTH_EXPECTED, PG_PRECISION_EXPECTED, 
    PG_SCALE_EXPECTED, PG_NAME_EXPECTED);

  // Clean-up
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Xml, Insertion_Success) {
  vector<string> inserted_values = {
    "NULL",
    SIMPLE_XML,
    NORMAL_XML,
    LARGE_XML,
  };
  const int NUMBER_OF_ENTRIES = inserted_values.size();

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  insertValuesInTable(ServerType::PSQL, PG_TABLE_NAME, inserted_values, false, NUMBER_OF_ENTRIES);

  inserted_values = duplicateElements(inserted_values);

  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Xml, Update_Success) {
  vector<string> inserted_values = {
    NORMAL_XML
  };

  vector <string> data_update_values = {
    SIMPLE_XML
  };

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, inserted_values, inserted_values);

  testUpdateSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, COL2_NAME, data_update_values, data_update_values);
  verifyValuesInObject(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, data_update_values, data_update_values);

  data_update_values = {
    LARGE_XML
  };

  testUpdateSuccess(ServerType::PSQL, PG_TABLE_NAME, COL1_NAME, COL2_NAME, data_update_values, data_update_values);
  verifyValuesInObject(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, data_update_values, data_update_values);

  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
}

TEST_F(PSQL_DataTypes_Xml, View_Creation) {
  const vector<string> INSERTED_VALUES = {
    SIMPLE_XML,
    NORMAL_XML
  };
  const int NUM_OF_INSERTS = INSERTED_VALUES.size();

  const string BBF_VIEW_QUERY = "SELECT * FROM " + BBF_TABLE_NAME;
  const string PG_VIEW_QUERY = "SELECT * FROM " + PG_TABLE_NAME;

  createTable(ServerType::MSSQL, BBF_TABLE_NAME, TABLE_COLUMNS);

  testInsertionSuccess(ServerType::MSSQL, BBF_TABLE_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  createView(ServerType::MSSQL, BBF_VIEW_NAME, BBF_VIEW_QUERY);

  verifyValuesInObject(ServerType::MSSQL, BBF_VIEW_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);
  verifyValuesInObject(ServerType::PSQL, PG_VIEW_NAME, COL1_NAME, INSERTED_VALUES, INSERTED_VALUES);

  dropObject(ServerType::MSSQL, "VIEW", BBF_VIEW_NAME);
  dropObject(ServerType::PSQL, "VIEW", PG_VIEW_NAME);
  dropObject(ServerType::MSSQL, "TABLE", BBF_TABLE_NAME);
  dropObject(ServerType::PSQL, "TABLE", PG_TABLE_NAME);
}
