#include "../conversion_functions_common.h"
#include "../psqlodbc_tests_common.h"

const string TABLE_NAME = "master_dbo.varbinary_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.varbinary";
const string VIEW_NAME = "master_dbo.varbinary_view_odbc_test";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};

class PSQL_DataTypes_VarBinary : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_setup(Drivers::GetDriver(ServerType::PSQL));
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler test_teardown(Drivers::GetDriver(ServerType::PSQL));
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_VarBinary, Table_Creation) {
  const vector<int> LENGTH_EXPECTED = {4, 255};
  const vector<int> PRECISION_EXPECTED = {0, 0};
  const vector<int> SCALE_EXPECTED = {0, 0};
  const vector<string> NAME_EXPECTED = {"int4", "unknown"};

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testCommonColumnAttributes(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS.size(), COL1_NAME, LENGTH_EXPECTED, 
    PRECISION_EXPECTED, SCALE_EXPECTED, NAME_EXPECTED);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, Insertion_Success) {
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "49",     // Rand
    "02",     // Rand, different format
    "268435455",  // 7 Bytes
    "4294967295", // 8 Bytes - 1
    "4294967295", // 8 Bytes
    "4294967296", // 8 Bytes + 1
  };
  const vector<string> EXPECTED_VALUES = getExpectedResults_VarBinary(INSERTED_VALUES);
  const int NUM_OF_INSERTS = INSERTED_VALUES.size();

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, 
                      INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, Update_Success) {
  const vector<string> INSERTED_VALUES = {
    "123"
  };
  const vector<string> EXPECTED_VALUES = getExpectedResults_VarBinary(INSERTED_VALUES);

  const vector <string> UPDATED_VALUES = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
    "256"     // Max + 1, truncate
  };
  const vector<string> EXPECTED_UPDATED_VALUES = getExpectedResults_VarBinary(UPDATED_VALUES);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME,
                      INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testUpdateSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, 
                    UPDATED_VALUES, EXPECTED_UPDATED_VALUES, false, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, View_creation) {
  const vector<string> INSERTED_VALUES = {
    "NULL",
    "00",     // Min
    "0",      // Min, different format
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
    "256"     // Max + 1, truncate
  };

  const vector<string> EXPECTED_VALUES = getExpectedResults_VarBinary(INSERTED_VALUES);

  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);

  createView(ServerType::PSQL, VIEW_NAME, VIEW_QUERY);
  verifyValuesInObject(ServerType::PSQL, VIEW_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES);

  dropObject(ServerType::PSQL, "VIEW", VIEW_NAME);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, Table_Single_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);
  
  const vector<string> INSERTED_VALUES = {
    "00",     // Min
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
  };
  const size_t NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<string> EXPECTED_VALUES = getExpectedResults_VarBinary(INSERTED_VALUES);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, NUM_OF_DATA, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, Table_Composite_Primary_Keys) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("PRIMARY KEY ", PK_COLUMNS);
  
  const vector<string> INSERTED_VALUES = {
    "00",     // Min
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
  };
  const size_t NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<string> EXPECTED_VALUES = getExpectedResults_VarBinary(INSERTED_VALUES);

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testPrimaryKeys(ServerType::PSQL, SCHEMA_NAME, PKTABLE_NAME, PK_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, Table_Unique_Constraint) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> UNIQUE_COLUMNS = {
    COL2_NAME
  };

  string tableConstraints = createTableConstraint("UNIQUE ", UNIQUE_COLUMNS);
  
  const vector<string> INSERTED_VALUES = {
    "00",     // Min
    "46",     // Rand
    "02",     // Rand, different format
    "255",    // Max
  };
  const size_t NUM_OF_DATA = INSERTED_VALUES.size();

  const vector<string> EXPECTED_VALUES = getExpectedResults_VarBinary(INSERTED_VALUES);

  // table name without the schema
  const string TABLE_NAME_WITHOUT_SCHEMA = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS, tableConstraints);
  testUniqueConstraint(ServerType::PSQL, TABLE_NAME_WITHOUT_SCHEMA, UNIQUE_COLUMNS);
  testInsertionSuccess(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, EXPECTED_VALUES, 0, false, true);
  testInsertionFailure(ServerType::PSQL, TABLE_NAME, COL1_NAME, INSERTED_VALUES, true, 0, false);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  const vector<string> INSERTED_PK = {
    "0",      // A = B
    "96",     // A < B
    "128",    // A > B
  };
  vector<string> where_pk = {};

  const vector<string> INSERTED_DATA = {
    "0",      // A = B
    "255",    // A < B
    "32",     // A > B
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  // insertString initialization
  string insertString{};
  string comma{};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    where_pk.push_back("cast(" + INSERTED_PK[i] + " as sys.varbinary)");
    insertString += comma + "(" + INSERTED_PK[i] + "," + INSERTED_DATA[i] + ")";
    comma = ",";
  }

  const vector<string> OPERATIONS_QUERY = {
    COL1_NAME + " OPERATOR(sys.=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.<=) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>) " + COL2_NAME,
    COL1_NAME + " OPERATOR(sys.>=) " + COL2_NAME
  };

  // initialization of expected_results
  vector<vector<char>> expected_results = {};

  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    const int DATA_1 = atoi(INSERTED_PK[i].c_str());
    const int DATA_2 = atoi(INSERTED_DATA[i].c_str());

    expected_results[i].push_back(DATA_1 == DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 != DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 < DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 <= DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 > DATA_2 ? '1' : '0');
    expected_results[i].push_back(DATA_1 >= DATA_2 ? '1' : '0');
  }

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, insertString, NUM_OF_DATA);
  testComparisonOperators(ServerType::PSQL, TABLE_NAME, COL1_NAME, COL2_NAME, where_pk, INSERTED_DATA, 
    OPERATIONS_QUERY, expected_results, true);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}

TEST_F(PSQL_DataTypes_VarBinary, 8000_Byte_Insertion_Success) {
  const string PK_INSERTED = "0";
  // 8000 Bytes Data in Hex
  const string DATA_INSERTED = "b1799a2d56b04d701f1328d55f07a09917e0f8b7590c1ec9947e360a639344635dc2897eb14daaab2e80dfa145bdafdb3210d283407ee1104cd3682a0b85331f0e91af4f53e26564cdd0332561b8d45a8bc23dfe3c66adbe0adf0d09f4c78b41bad1ff0f4b368f34c81f85ddf9670aee1867609bac3da0ab0844a7b2a38759a725b5ce945c83f9625a91178b4d696a95f34e5a5cab6b06f9ecc07d97a9734afa443f52ff6a3243afdaa04e2ded40a694262b9b7fb8cef7645da8535a3701b1cd87d6646ab6374560c30942c507c6ac55f0fb882b599ac14838ed1420ba0adfe5602eb10b00a38399e48f9352e1022ee66799192d2f221c56e563e60fa7a9b4d4a5356d55a0abb7d9550ed500022c95b03422dd9ca6ea9f2f09c1cca2a808e2d0623d0d17f68020d2a1f30d473dad16d0c6c3fc6c7d34d7726498bb98b78e8b8cd06de815559bece82aed8c3281f54eff6f91762830c5a24af27ae5e381a848d6ce7215d03c95428a56b015b253e5ef4d8e2ee0a91f57eb7ae3dd603a64f15cdf5396e1947755b6378387b2ef805a1c6a7f7b43c878ba271c75c93649cf590d92dbb76465f3ecf874cec38b2f7fc3513d537926cf41ad82c0c741676640bbb9e6243ccf7905ee6265c70b444121d9b17aa6d8435a7fe636d0e3ed2b926f4f6d4ceca27e55e496c750d066c4caca48e8dc4ba82dcba70cc5a11f3417d7945d95fe19cb8c4ef8dff5bffe52884791b91ef8ab515461b216dd778e6935a0e5ca48f3eecf20b780376ba4ddc27f834de40cadbea45cf5ef10dd3ed74b7083a433889635fb69b826c24843ec2c54650fc8f12e63efcff34b54ada683136e0292e47a3bb7dc7633f60b1c71f0e49a566b6a21995dda9a938378e74fc6fd2b3166bbcf79150e25bc59e8af051bd82dcde15a44ab570305b60d7caf7ff1f13919d5efe9900518bc259697710b767e06d74761d24411ee2d7b9ae0a8ed7b13729c2a4fcf98c43f8aa61e4f64afb5b59c71cd8b989eea74f87d91c415cbebfed10e8b35ab23bd06bfeae801fb4da77b287d3cd1b4dfadf526682ef3d7513f9895d6107c1bf05662aae1379280de4361a310f1c4252a4fa059c984f2086e976c50cedcecbb7629e04eaf9ab2bda7426c015b45d7ae47e78be449d6e7a01f5e54d5c9ce151d16ddc221129856fc0ccd2d116714c13f6b7a04640466ce36c4ec705988fd52243b3372bf7cf08a5309d279325a94bf95703e4893ba383a475703e06a6a6aee2f64dd7f4ba4bfa7ba7b8f33cb2f655b3fbef2bb98f67b60a2644c0548873c2afcd94dae0a03377ad944b1123a42f22d2b1d2316b790806c048bcd3a8de291773d97e13c7148e62f502e8e3f6ac77ee89dd1db84ed914308e5f330e5129388907b21a0c276324eacf16cade2a7a708f05bd2d18a8c2833ac2f94a73ba6fbaaf8eb25854a36dce785badedb90967e3de7ecf44495a8c624822693f12a82671a0bbfdba4d2fe0bb9a791440fa15c6498a766162a0384f0614375a5166f99942663717630d5e2d2816d38a8a14c0501edda4208f42c3164e853e53787509fdf09bbfaede8c72c4d62477d93c31562d892288c3574583c544a110bbb28d7585cfbb768c19844809362b55119ac11b3369ed25d8b156097392e26655659b0cf8c4002ad86d7aed003e47e0bbb0fd8f380a980d3c438beb15c11390a9cee22812cf6c11a0d9193b61dd3b973659403e361035f1f08aa666e476937c5ca1d3a568069dec31fc723454af1e30960ddb30ac3803010c142d2d9fd8c50b170531a49ca867cdc6d41138cf9108d1eb49ec31a1f565afa6b8e538b3ba872f1681798925c2465c57cae9f278c982538c9dfda3e0c2a2b9eb4d80522f89d937390018455f9d7d35978d43e4311a8ecff75ea43add548b93322900002ebe66240e7c17ab3b4f982689c167c1cbeef4bec8f2865e02b1aebb6af6d7ce488abe870d4cac71da6012f29f5811cac1ae32b47851c4854d4ca4c35f6b1d1b913d2d0eb3c95598bac12fe64dabdeff1f4aa937b7695c09bace05c4e2f646bdb85e94af49ba0598cbca1c682725edb889fcccddab338a646f9844bc7bc4af6ea62f36cda5f62a96b18cb66e4cba23dbf995867d38ae66f1f96597c8e41301276bfccf7a8cbad85534afe7afb7613dabd10b296c9ef42f273fb5d7d291cb47ed22ea18afa0da81093b2946eb25211fb41cb6c4722a0aab886d1c875d6ff52286a8162b5a4145fb6e4e6878dfa7f9ab0d0b309d7dce033ff9cc1347db41cea1357b7cc4867d151d91415add2f777e36ac5b5a54df74af370d56b71216bb8b6e23ace9a876e8d401bd55a4a0c03ccf597d4aeccef6f43988849580eda37050017aad5127ce65bc820de8dbc6bc5f6718cc9e79d570dbe0cf48ba25184c2b9fe494b7caf0fc4f1a22515442c32fdc183bd31c571607c205c19dc3722526235a1b1f519c8c750244d6dcedf8f7723f07792c970ddee53eefe3d57aebbeb41f858dc42ebc423caea2b77fba492ef6298533a21226c75a94d5864f68d81895fe4473a4a9f7d62b1fa2e291a2d94cf7c38bc0d20c90f0604d213d7ad86c49db40c125375dec26300895fa9a4a8a4ff1a99ae9353b57ebbcfcd3682a654da73c1b821981445397ee2d0acfab48ab0a08a9ce8d67f54c270ed84d5dd934b14bedf236ef542e96200a01a21f0e200e52741ff14ff5012d506c14edfe4ad3927e66f8b10f87fd218bebf3051839b2547d5088b27a7f919b2dede08456ea3ce4aed8bdce15623a687d6fa3b7d75c83b16321d62aed600c05bb92a10787e4b4befd59dab42b97d0033dbb85f0e0f2e5cb52845bb8561b6bb5f91140100187acf4777dbba46eaa5deba7bff0903a0f7b58617eac7e00d0d1af69e6d5feb40252da026c87af4a2c05fb0c72e5ad160f53b7f4dc3f30eda434a985132625a3861aea910872c7bff82a0dd1f85cf2782e2a986c7d3b7c75de22bf00a6c418c2a6b00df888eee6d45f1c5d7af185da2332456fec922063207ce04c684be8288c3bf92aa5e01a524282368fd85ef337e6340e932b0cfe3672cbd0df9609ecc621c2087da148597d92175ddb27faac9f017565830349a27b894b119078299bca0cca968ff37a4c3b87c871a887c849f60b5702d7c3d9bd257420da22a79cfc6cd19cf962cc3caac939f89f483fa7dafef78b3c80dd0a6c09a0eacd0375b5188c7276d5f2d3fedc5200cd4fc1aeaced945cc05398251bd529ff4338429662be64e916e968ca49b68dee397fd79e500f3c1e17646f36718f1ce585ee860b81809ca85414d3e1c1ba1c18b5c68978a637d654aeddb56f67f5b4910511b37d7c895dd030b24ef217fa1ae2dd6be429d8f18f24841a7435cd07cf17ce909b610de547be920eab18d5a7be73d415042f7a34f25d76837c675c227df36e07ed2360773e8eb0a2cdad9f964aad460422fed39d2e48e960e091279ec9fad265a923835681da383fec37af9031d8e84c7ef73e88f4d9250d0ff6e207cc74d13d5a9a7c10bd968753482f5434cc6f48be4b18221665b9c64a35b9c51b8e87985290607f56cfdd4044f56a506356e02564c6946292e264b218e5333a4d5bd66721ed561c2647e8139dca442c8c088c2a13929bdc42fb300ef07dc5f598d5ca1e89d3532b371f88833c8973ac757225d8a07133765cee9c9b2dd9f14f3cc5994f5ef0d12ed21e55107d3e0c1e313c1d04e089182f303c35b63233e0cf022f3b831d480c60668a052b206186b2780bc4ecc3b2a7cff401badf3fa93b216efc8684659e4bb5e1a2a893e2c3bfe0c19230fc14a5e36f2168fd6c102821371d2ee20d211f3c071289b84fa8e19af7796089563d327e9117f4b1b2ee24a2a6837fb50f9e9cbc20f6b8071402770043e935bc1d59f0f6f2531c651d945d15ddcc250db548b91d15b3ceaf618fc83bc7fdee76ea7cf1f4d4a028ed0c641ce3b24a3ea1597b1ea6989247c42b3214bc9410aaf0bae9941b7c0f50f6b90be64f3ab2c5880f5ea968e02f83a6de15cae3b8ee68c3b8968fee6c849408f0ff74cee4408ff475136c70b4be00b034bc822e9aa3da094573167552ed5dce0eceffd439f732aded21b5c2e75bd3031400cb5a66f01e59129065891e81c466fb360961ae8660084acb4997d9d1552bf2cbcc182e6c83b7578d6202f9043cf866b5e66e4e92f7127108a08bb6815e3c40cc7c9dff90fa201fc912584cee6411c1cebe52deb03a60552cbd6c2bbe535ed7a2ed5fe6423ff44c0bf08d52e8c078149f7cebbc0b77e55d1db3a0ee7acb11a521fd3427bc86906573180ed9614b7d5a96291826c49a2bf6679acd0ec2cfdfead49585a8e0d8909a86f09dbf6118b448366c2acea13ee68af6f2571e8dc43de82e7a5faaf0947706f5d05d49111c7e4c65261fcdeba49e7c83c6d672a73618c6ae79f583b3be859eef9114c0225b99ae21bb7e1fccfa61a46d40da6f7051c08661c195cc530cdb4dd0caaf9c0bd7c021585fe60d2e89c6c409c30c47076c401e70df1fec68768d7afccf10a66759d52afd87690eb6cfe63e90995d6427b877d47d7980da99e5fb4ba943ea65c0c747a587767e51baddceb1c3bdc83e213ac7bf1697ea96caae58cacde9041391c737cdd46aecf948e6fe378827bc86adbfb235e3dc8aae0c35d85916856369509a2b8d8c76a598668975c669a4701ba8353851defde713209b0bdfc5cdbbc21ea6dee5b74aa379cf8030058cb134a0870f1dcb5cd877897e1a281853c86327fde74861e3e655a77b13eec4a94e05faab399cfa2b3d03f5937cf81ac9f7fa7f3c6795c7dd0d4d047beb0048f02ced257b75a516dd567a8071513193ed20cfa6ea8c2faf37544ef2f45886c9202b4c5f01ff49c7a985638cf6335133b0fa816ebb4ccfed999ffad72cba5d42c8668e770fbebb117a8a163a12fd79e3dd1bec85265146f68a6efa3e2bab1c9b75b3f390a619ab2d6df6ad98d5ebeb1df8ad10e3337d3540ff5de2639e7962aa564e84e8867e60b1b97a27326733353dae3362c8a4855cfc03f15b11afa2b103ebe3e2d1a8b6d285f7b9c39495d6620dce215c46a1ea7df23af93866deda124a93cea6de01058994e939abb46f97e3f02fc0a6bf52952da03d79c25b36700cc6a59a9874e99f5e952a80dc842ec4d9eb715ce70a016d09406a5c9c6df8282dd15db5eb3bab10855a7be4764a096a3b935ed8c4236450416e1cf90ad061e21ca1091800e6b26eda649953527d69af7d0f5da17fc04e60574eec30a046cb0e1108198f20ad4213a2d0458b84b7fb7084fc785c0f6c7269308e9b35c2b51de33980dfd6cc99242784fc4422bcf848397aa861ab45dbb983d24c1f10a60e3bec9d7b70906ac3d539e3b3c66eb10fcc6c39da46c6047ab369883cc0de32974f6991877e93da4eb0be1aca2e4d08c1cf38001d4c19403417fb9ddba2c85c2db20ab18c229bd087dd3c013986378ba3b284d0a839214428d820f6ed094896942864a0d159faf02ca344d01e7864a79e92f10d2ab95db7c2a042edf3367dbda6b63af3b77d945539c10eeeea13e3382475b19f0521b95241df76b8adb1f5fc2b4b9e50b4df8eca280410f6747ea726821101c5b0b5e430c6226fc3d3a7c08ee0832ea3abbeb7072a0649c55adc49c11a6c48fa56c88b854a9990320cfe78d1ca1aacc856e5a5bbdb9b3a9f983335b25aa44cdf1014d26a802cc9d2cf3d665ac7698a3706018867678013207a9b8b244baa1197263491952d3adafaa7c09c85b2e0db98b81c496eab95bc50ca143aeee2a7b85c20f85b69fd1c7d62a8bdb29dd247019a6e617c436430767b39b32a6cfdd100eb77ad958d4350541d47318d96b743016ceb188d2f8bec4704a943772f387380b9f17a8261509ad339bc5a9ff1d2c12591c3ac5377fc8742695895aeea4a7902b0ecde10f111581027f5d37dfcc892231623ec1cd25e87495c52491a88422c2fe8a03ce9b86ebaa0d9c407369106711e00e1e7ea5fdf7d7d3e3c25e5cec30b4eec808d38750c6c1046cf75690cbd9fcc12a9f1d010783c8d3b6dab5840f13875f1a74a78150f98b82d5da5f3f7a6c0114c1c94abc7cbfb6f21a4fd76555121cd29226b419d4069ce8a1239967ca6db944cff3ad752e00a65e2bf8b112584d2692dbc5b62d3edaeb19d850c7086dad616176f79fef7921ae3ccfe28c45a288beaea5bc38bc8920bddaee039e1e9bf707944863589e37a18f3cda6ebb6c45d5bdfbd48cbf076d6a5906bde9e6bdfe25a61295ad34e617c259786fb64e7fb3e60904c0adc869a9e5b7fe60e53d5d1e8b9c479ff772280430eac2415b8bc4f7a178ad0df434c3bed21c945366b2ed8f69c12257b33e3827a635e1c406bc57780da9eb7878f42f28073d5a55d0ddbcae8f66d00b8847b82d16cd75609cb48bfacf260cb77b4e981f456a07fa83c8a406e1035f7aa5957f98c46156a514a259bcc252cd1c474bc512f62a939c2e40d17ff94cbd4ce90dde3666335836bd29e0baf71af4dea5d60debcbb9a0895220f89003837a7178a498f13008a1de4252c1bb49e3541ef2051582861db37639c145c58794133c7408397ad19fa6afd2d573deaf49dc72288b7dc751a9387cd152cf6d255bb9673646ee412fd910b487c36b30284d492a5fd8e1086fbc8d7bebefa5dab2653a72d042a9fefe34e880090f2a505581a3220af9e6dc7acecc13206489e77111233bf2b7ae67d77eb4f02f4f835d8932a9a5f337ad2a0bee942fee5220e50d25f814fe90aab7febd29ed5b7356ed79d3bb1123684c9d73100482fddfa32e707d76883a2f60e5e3821a7a40bb52998676cfd9eb9d5ef25a12206e4d39e4acdb8108588797fef91fc8a2b391ad5f9a13f296d14111170a8fdacda6c8139ca72b24f3f34fb3dd58c3f1f903c69cb66194535f9f0913be4fb833c32b9bd1506957f2b7f0b1100b85ffa243c009a965704c80fa8d4793f0a83762a9069536b08b3f54fb3fd1b6c094052e5cb4eef08cc57414514c075cd465002a5d3045a51fa3e523b7f8cbf0883a69710c1c8c30db72a4e6c6ab3950caa925faa99d7b461a5a384ead77b6cc54e431d61a32a443b1d41ddb4fd28f49c7df6b2211e2850f3bfc48f529513a4ea9ed0610899dd4e89b8d96923a2b84ce4dc960720d256c7cda8f4e7d87548c4a90ad7ccf34aec2136ae6a59c19b0e9fdcfa2bf69b5b0c5d5e98bfd95ac5bf21fcc8309d1900dcad9afe083e44cb4219cb1413df94dcb8d2e2112a487d00f7827d311360c1e768e5b76e94d0ba97c30cb7168fedaabdd7e683b9fae65b425d8b29d64da8997b5ac8fede4f80560df82ef82e16a5268e7c0ee4f108353978fadf8e802ff79a837ab56ccacedf2751217ab715d3ba1055e0894276e337fed2680c83d1bf4004b9f639f6f74a933c4342a6cecc83246e7c020311b5cda3e1dc352196f649b06a0169b05b140d69fcde7d19ad06fbcaa0b9721c9fd7eecf87c7df61e8d8c962ec83d5f0200ee45e701513e29dae76531cdfe4e7b65392ec3ca59bd62aa7df0b12c8603a50eb5d27bb5579dee0f7b3debf63f55e2d8a51b2f42e4cb40a3fdd70d6e96d81346d805be3735d599eeabd9c9bcb129da6686c5e6cf9589dd44d91d398ec97612299584b5aef39c92d4b5879d37f9dfa71e418b658fd5abe57df9ba0a256d58f5240dd712819f3d9d17350a4e018e6908e3412b3c1dec611799c0eb3353b4edda8f9adf43aaa09f691bc40a5b06388f01a4be7b5b369f27c632459d73afb1761dac7cc8ead94c8c65682a5f382fee5dbacc7afaf9115402dffa391b88ea6d0c56578e0ee879ea460c3db17627d9705c493a9890240a246918128e7caa6dce7d17c53787b0fecc6269ceb34d8d90827a229210e9a725a7c405bfd533439a003c9c44125c3ccabdfe9f6f8cba6d77545b7f56a8299806bc63ad661703fd718a39f82b82373c5152333c25723712c277c5127b19083730e61e6eb92ec8fa131ada04e6bb900ecb7074f4c9f501c391ee0789b7f6d82647ca8cd31ce23c261c3c05ba17ce1f4f379de78fc567887b841a46cc741bbd957dae47834e3d61451bb91b03e0adbd7afa705bfaefd768254119db28e84f9c9b4ec74a17d0683b15ec12b4aa92c469097e3969398be3d9efd38e3eb6df46f8ef3b1eef84e8f444faec31c2d6ff035d649f3330dbf8bb1db8f1110e624caa90a3dd07290a34db9cf81da426ac2d03ed3efd65d21e587a8a2200e3480ef5f5a48269e9361dd1d3af90f815304b577f5187fcf4cb79b501acada2eb27040e197be51a5a5aa1b2bd10b1074a43f839b057d333735519d1991963710eb46286527c5c660a4ed9c40a478c51558285c093c4c23c6a9c58bb00bc71f2bee64af7871ed8ab4d524b6157c83646c49ac7509091500e303f6f703eda7ae418d6d296580266be49257b976429a4765b6119cb7dbd83c43c97691bc3ae0fb411cb92439d06a242713e4b20db3b0865e2ac9a0c4ad8ba91cc95867bd6757ab987c0e9bf12e03d903ea66ec0db3516354ef971a2866cbaff81ab1f80ac8017110973338529bc6568abe94e2ac536912b41ff85bc099a07e8c553441977c008a48ff66e7dbc6f58fb17ed4a26928e239e4b507e3144284ba98562f2d4d645edfca876c550f68bf189ef7c5b7bca9f63008bda62c1fa1d3cf742b8e05dc8c24f9149ee3ed7eae356564ebdd76f4b4bb1f8eeb42607e98ad54bc3478669f81cdfccb81af5ad22e4e73693c0fe7bcbd37b86f9b775fb56a67504e52289089fb643e28a620721cf13f5864db3221dd70218d37c52f72fd7d20033b53ea3cc8027f9e3cf12074a76c18f6928d62439c6c7d3ca468d8b887556d9fa2294dabd1e8124427c754b9d6ad864c5c7e71805d0148cef823b5bcb0f7222965b645810b79fb6dcf3f69fdc858190275697cf3600cf793060187fe2be1a0c7e7ec13005ab5674454fc70b385eab4b5f4794a8e8fdbe011cada7a9f376cd4f20a709a4ccba74437e5f6eb881f0166c7303571d80a8292b728d57b38f0d608962117872743116a4b32be70e1fa1b949f139783eca2a7329dd101e8d79c183550aa9fd5f7e14bef9d3bac2e7de5581c182c16c421a3dbf7bc12a80a881a63ed0cb6480407654e7a5874701d28c9c7ca53d7de67129c9a0384854e858e0ddf0662dd4bd964ac1eb7e4fa896008484e3c960288bafe316a9b5f07ba6fff6935c65c8c15fea37abd139fa7affe05f3cb0e75d4aa5432ddbaab205db1da35eb24a7f33648c533e5b750c1b4aa2c3930d4c19e05a30a16351ca3b561ab59ff8bd79c310f0961fcede89a9cc62da6ae4c186b501b2d5c4f4a6114dee4e8fde0a1f1c99b9ea5d47db7090b2209cacf2745324694c3ba0f5edf0eb0baae74d0295b25833a569df79ac546326f99d2fd9c086c342ea67e35817be051ab8405573332c669bb20cd611a7ad86bd313ef7cd3239a085eb976d671a5489e0485fe2e2455534c4f852d21f92cdc8c0657694884a299d8909dcf84bfef7970fefbc406c6e469a551de59ad6a497dbb7356396cf2504da6239f6b069ec6ed89af31a3e032526799612959a29f8d1ba423adec5752978bebdcd8285370d53e4f29cd634e677137b3368c4b4db3b3130ed18915c5c64bd153c7b9db52668e17d03c4531774efbe4e1790e9102ca8b4efad4c81e7e95bce3f0fdb8de8709f267d1c5bc257907ea553a70a6bd3eb6dc20031e4341c010a8028060dcdb6f7879dd156f40441bb693bd01b05cb6793742cf68c5b173f2f5a1c04295df1b1af2471d6875257201cad45c60337cc02c9a41024b4598f7ff3af4dd4abcace46188f00637c5e8774520eac2e3922a7164409f329703b4e39f854aaf75b699fff8155dd383d8e6c1115116ae68caad864e8a0b67879d88d5aa33fe529afcd0c815e28d691c1c9032f1f0526e611e50291c91a4282ef8b171d609e6160a00dd10a0b40ce73d25f7afff6e4b983ea75e065c2b6e7a6e35970e2441f94c4e7d6d64749ba91e650e8323449184e7e6444c9acca12f15ac2f2856f79e8c67a9948ffb7aa85ee8a1fbb485dc3cbbfb51cf794d925097a3e08b018b040176fbdb412d6cea51ce5b8f58640cdd7a9ef07a19eba2609f8144bfc7aeec4940e2c9d2fe14c156526f22f99ddd1f74cf5b557b478855ffca8d1c00e674fcc6a90278c7825f3a4b7fc35ae5753aad3515b1eb29b5fda06cc16a4e91d1154c3412f3a8df0f68fd77d8d36317bd3896746cfacdbb5938305250525536ae3558c90863ff7fb8fbfb348e9b579d8439cd6c698d44450ff5adf429b0ac3bebf2a170270d53007b2f1edd93c724416e4680a7ff2fb393906cb72d8e587a6e58ecd7d3541c8c3566118d4e35436a16db285c2c7521193b1212e0d3e51a4c9c0a539da32c440654c15493d9b8f3d19fff99c879d46e1fbf0aac52569156f21e16d64e66d8c61d5505c419f6d3021457b0fa95afd3069cce3f2a368dcd4825db58f9cdca9073bb480fcbfef2e8adebf9c809752667f62e12a6462483f6ad7b1dfe6066fde98ab32b01185f63024220e10aca915db7286a91ab8eccd67815ad2b346897475c8db2df5bb3c7ca928d008fe87fec966f85e3fe034bcba95fc44010c15b13085ff83fa1b219652e72ec0fe9fa01bab64ed5ddb283442099c0c7dcccabe9f15be47c49b7bb030edb42af37aa3ace5afa51cee9f72315070acac4868ecbb491afc7753ac15a9a8c9ff627d9c22df428d36e3201b5451b1737b73d4992a12e32259e3a5ceb157f861169377110f6c81a66f4bb1c57e64855f5ba13a10041c2540ff684d88f85d7b2b078f2ce1f2a6dddcc1420a53e7bb0def4c1f6e4895fb8259cd7f530a37cd3955fc854ca6f7812b372aa66085514e17191c038c386b81d3b48a79082727e8fab2ca82b9e4bbbb14ce79df93aee2435d0494c42036c9acd82c908f5f6dd0766c7520c0bb0f47669a36f8217a59e117fe3c27e40030b2c5f0ef5832a81c2d70a4033b000860236258584961b3b409020fff4ee49e8f5f8f5105db98738d79afd15a5d03df5c34174328133d5797b60fa1b5e8f920f9c6ad1ef2bd6b8255e1a5cd2745312ffced53df3a78b3181a5c8958b35061c4f1f20a571b3748417ff65268d3b5df9a910213e648f58ebba41f8667217a07c67b658e938913da9cfbc4e803b74a8d048516515e61f4ebb22e089ca0630fa65af4e48af421e3083c1613a24cf4fbe88f460a03c1d757305c53e39d415a33eb1e80f6876c41bf872de6ef";
  const vector<string> EXPECTED_DATA = {
    "0x" + DATA_INSERTED
  };

  const string INSERT_STRING = "(" + PK_INSERTED + ", DECODE('" + DATA_INSERTED + "', 'hex'))";
  const string UPDATE_WHERE_CLAUSE = COL1_NAME + " = " + PK_INSERTED;

  createTable(ServerType::PSQL, TABLE_NAME, TABLE_COLUMNS);
  insertValuesInTable(ServerType::PSQL, TABLE_NAME, INSERT_STRING, 1);
  verifyValuesInObject(ServerType::PSQL, TABLE_NAME, COL1_NAME, EXPECTED_DATA, EXPECTED_DATA);
  dropObject(ServerType::PSQL, "TABLE", TABLE_NAME);
}
