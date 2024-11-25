#!/bin/sh

set -e

if [ ! $1 ]; then
    echo "This is a tool helping developers to build and test Babelfish easily."
    echo ""
    echo "Prerequisites:"
    echo "  (1) Each workspace should contain postgresql_modified_for_babelfish and babelfish_extensions directories."
    echo ""
    echo "Commands:"
    echo "  (if TARGET_WS is not provided, the current workspace will be used)"
    echo ""
    echo "  initpg [TARGET_WS]"
    echo "      init postgres directory + build pg and contrib + copy ANTLR lib + build pg_hint_plan"
    echo ""
    echo "  initdb [TARGET_WS]"
    echo "      init data directory + modify postgresql.conf + restart db"
    echo ""
    echo "  initbbf [TARGET_WS]"
    echo "      execute babelfish_extensions/test/JDBC/init.sh"
    echo ""
    echo "  buildpg [TARGET_WS]"
    echo "      build postgresql_modified_for_babelfish + restart db"
    echo ""
    echo "  buildbbf [TARGET_WS]"
    echo "      build babelfish_extensions + restart db"
    echo ""
    echo "  buildall [TARGET_WS]"
    echo "      build postgresql_modified_for_babelfish + build babelfish_extensions + restart db"
    echo ""
    echo "  pg_upgrade SOURCE_WS [TARGET_WS]"
    echo "      run pg_upgrade from SOURCE_WS to TARGET_WS"
    echo ""
    echo "  test normal [MIGRATION_MODE] [TEST_BASE_DIR]"
    echo "      run a normal JDBC test, default migration mode and test dir are multi-db and input, respectively"
    echo ""
    echo "  test TEST_MODE MIGRATION_MODE TEST_BASE_DIR"
    echo "      run a prepare/verify JDBC test using a schedule file in TEST_BASE_DIR"
    echo ""
    echo "  minor_version_upgrade SOURCE_WS [TARGET_WS]"
    echo "      upgrade minor version using ALTER EXTENSION ... UPDATE"
    echo ""
    echo "  pg_dump [TARGET_WS] LOGICAL_DATBABSE_NAME"
    echo "      dump [TARGET_WS using pg_dump"
    echo "      LOGICAL_DATBABSE_NAME is optional if provided then only that bbf database will be dumped."
    echo ""
    echo "  restore SOURCE_WS [TARGET_WS] LOGICAL_DATBABSE_NAME"
    echo "      restore dump files from SOURCE_WS on [TARGET_WS]"
    echo "      LOGICAL_DATBABSE_NAME is optional if provided then only that bbf database will be restored."
    echo ""
    echo "  dumprestore SOURCE_WS [TARGET_WS]"
    echo "      dump SOURCE_WS using pg_dump and restore it on TARGET_WS"
    echo ""
    echo "  initpg_coverage [TARGET_WS]"
    echo "      same as initpg but with --enable-coverage flag to generate code coverage"
    echo ""
    echo "  build_coverage [TARGET_WS]"
    echo "      generate code coverage HTML report for all extensions"
    echo ""
    echo "  sum_coverage [TARGET_WS]"
    echo "      summarize code coverage"
    echo ""
    echo "  run_pgindent [TARGET_WS]"
    echo "      run pgindent"
    exit 0
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
cd $SCRIPT_DIR
cd ..
CUR_WS=$PWD
echo "Current Workspace: $CUR_WS"

TARGET_WS=$2
if [ "$1" == "pg_upgrade" ] || [ "$1" == "minor_version_upgrade" ] || [ "$1" == "restore" ] || [ "$1" == "dumprestore" ]; then
    TARGET_WS=$3
elif [ "$1" == "test" ]; then
    TARGET_WS=$CUR_WS
    TEST_MODE=$2
    if [ ! $TEST_MODE ]; then
        echo "Error: TEST_MODE should be specified, normal, prepare or verify" 1>&2
        exit 1
    elif [ "${TEST_MODE}" != "normal" ] && [ "${TEST_MODE}" != "prepare" ] && [ "${TEST_MODE}" != "verify" ]; then
        echo "Error: TEST_MODE should be one of: normal, prepare or verify" 1>&2
        exit 1
    fi

    MIGRATION_MODE=$3
    if [ ! ${MIGRATION_MODE} ]; then
        if [ "${TEST_MODE?}" == "normal" ]; then
            MIGRATION_MODE="multi-db"
        else
            echo "Error: MIGRATION_MODE should be specified, single-db or multi-db" 1>&2
            exit 1
        fi
    fi

    TEST_BASE_DIR=$4
    if [ ! $TEST_BASE_DIR ]; then
        if [ "${TEST_MODE?}" == "normal" ]; then
            TEST_BASE_DIR="input"
        else
            echo "Error: TEST_BASE_DIR should be specified" 1>&2
        fi
    fi
fi
if [ ! $TARGET_WS ]; then
    TARGET_WS=$CUR_WS
fi
echo "Target Workspace: $TARGET_WS"

TEST_DB="jdbc_testdb"

cd $TARGET_WS
if [ ! -d "./postgresql_modified_for_babelfish" ]; then
    echo "Error: Directory \"postgresql_modified_for_babelfish\" should exist in the target workspace." 1>&2
    exit 1
fi
if [ ! -d "./babelfish_extensions" ]; then
    echo "Error: Directory \"babelfish_extensions\" should exist in the target workspace." 1>&2
    exit 1
fi

restart() {
    cd $1/postgres
    bin/pg_ctl -c -D data/ -l logfile restart
}

stop() {
    cd $1/postgres
    bin/pg_ctl -c -D data/ -l logfile stop
}

build_pg() {
    cd $1/postgresql_modified_for_babelfish
    make install
}

build_bbf() {
    cd $1/babelfish_extensions
    export PG_CONFIG=$2/postgres/bin/pg_config
    export PG_SRC=$1/postgresql_modified_for_babelfish
    export cmake=$(which cmake)
    cd contrib/babelfishpg_money
    make clean && make && make install
    cd ../babelfishpg_common
    make clean && make && make install
    cd ../babelfishpg_tds
    make clean && make && make install
    cd ../babelfishpg_tsql
    make clean && make && make install
}

init_db() {
    cd $1/postgres
    rm -rf data
    bin/initdb -D data/
    PID=$(ps -ef | grep postgres/bin/postgres | grep -v grep | awk '{print $2}')
    if [ $PID ]
    then
        kill -9 $PID
    fi
    sleep 1
    bin/pg_ctl -c -D data/ -l logfile start
    cd data
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" postgresql.conf
    sudo sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'babelfishpg_tds, pg_stat_statements'/g" postgresql.conf
    sudo echo "host    all             all             0.0.0.0/0            trust" >> pg_hba.conf
    restart $1
}

init_pghint() {
    cd $1
    if [ ! -d "./pg_hint_plan" ]; then
        git clone --depth 1 --branch REL17_1_7_0 https://github.com/ossc-db/pg_hint_plan.git
    fi
    cd pg_hint_plan
    export PATH=$2/postgres/bin:$PATH
    make
    make install
}

init_pg() {
    cd $1/postgresql_modified_for_babelfish
    ./configure --prefix=$2/postgres/ --without-readline --without-zlib --enable-debug --enable-cassert CFLAGS="-ggdb" --with-libxml --with-uuid=ossp --with-icu
    make -j 4
    make install
    cd contrib && make && sudo make install
    cp "/usr/local/lib/libantlr4-runtime.so.4.9.3" $2/postgres/lib/
    init_pghint $1 $2
}

pg_dump() {
    echo "Runinng pg_dumpall and pg_dump on ($1)"
    cd $1/postgres
    rm -f pg_dump_globals.sql pg_dump.sql error.log

    if [[ ! $2 ]];then
        $1/postgres/bin/pg_dumpall --username jdbc_user --roles-only --quote-all-identifiers --verbose -f pg_dump_globals.sql 2>error.log
        $1/postgres/bin/pg_dump --create --username jdbc_user --column-inserts --quote-all-identifiers --verbose --file="pg_dump.sql" --dbname=jdbc_testdb 2>>error.log
    else
        $1/postgres/bin/pg_dumpall --username jdbc_user --roles-only --quote-all-identifiers --verbose --bbf-database-name=$2 -f pg_dump_globals.sql 2>error.log
        $1/postgres/bin/pg_dump --username jdbc_user --column-inserts --quote-all-identifiers --verbose --bbf-database-name=$2 --file="pg_dump.sql" --dbname=jdbc_testdb 2>>error.log
    fi
    stop $1
}

restore() {
    stop $1 || true
    restart $2 || true
    cd $2
    rm -f error.log
    echo "Restoring from pg_dumpall"
    $2/postgres/bin/psql -d postgres -U $USER -f $1/postgres/pg_dump_globals.sql 2>error.log
    $2/postgres/bin/psql -d postgres -U $USER -c "CREATE DATABASE jdbc_testdb OWNER jdbc_user;"

    echo "Restoring from pg_dump"
    if [[ ! $3 ]];then
        $2/postgres/bin/psql -d postgres -U jdbc_user -f $1/postgres/pg_dump.sql 2>>error.log
        $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -c "ALTER SYSTEM SET babelfishpg_tsql.database_name = 'jdbc_testdb';"
        $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -c "SELECT pg_reload_conf();"
    else
        $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -f $1/postgres/pg_dump.sql 2>>error.log
    fi
}

run_pgindent() {
    cd $1/postgres/lib

    echo "dumping typedefs for babelfishpg_mpney to /tmp/babelfishpg_money.typedefs.."
    objdump -W babelfishpg_money.so | egrep -A3 DW_TAG_typedef | perl -e ' while (<>) { chomp; @flds = split;next unless (1 < @flds);\
     next if $flds[0]  ne "DW_AT_name" && $flds[1] ne "DW_AT_name";\
     next if $flds[-1] =~ /^DW_FORM_str/;\
     print $flds[-1],"\n"; }'  | sort | uniq > /tmp/babelfishpg_money.typedefs

    echo "dumping typedefs for babelfishpg_common to /tmp/babelfishpg_common.typedefs.."
    objdump -W babelfishpg_common.so | egrep -A3 DW_TAG_typedef | perl -e ' while (<>) { chomp; @flds = split;next unless (1 < @flds);\
     next if $flds[0]  ne "DW_AT_name" && $flds[1] ne "DW_AT_name";\
     next if $flds[-1] =~ /^DW_FORM_str/;\
     print $flds[-1],"\n"; }'  | sort | uniq > /tmp/babelfishpg_common.typedefs

    echo "dumping typedefs for babelfishpg_tds to /tmp/babelfishpg_tds.typedefs.."
    objdump -W babelfishpg_tds.so | egrep -A3 DW_TAG_typedef | perl -e ' while (<>) { chomp; @flds = split;next unless (1 < @flds);\
     next if $flds[0]  ne "DW_AT_name" && $flds[1] ne "DW_AT_name";\
     next if $flds[-1] =~ /^DW_FORM_str/;\
     print $flds[-1],"\n"; }'  | sort | uniq > /tmp/babelfishpg_tds.typedefs

    echo "dumping typedefs for babelfishpg_tsql to /tmp/babelfishpg_tsql.typedefs.."
    objdump -W babelfishpg_tsql.so | egrep -A3 DW_TAG_typedef | perl -e ' while (<>) { chomp; @flds = split;next unless (1 < @flds);\
     next if $flds[0]  ne "DW_AT_name" && $flds[1] ne "DW_AT_name";\
     next if $flds[-1] =~ /^DW_FORM_str/;\
     print $flds[-1],"\n"; }'  | sort | uniq > /tmp/babelfishpg_tsql.typedefs

    cd $1
    echo "Clone and build pg_bsd_indent which is required by pgindent..."
    git clone https://git.postgresql.org/git/pg_bsd_indent.git
    cd pg_bsd_indent/
    make PG_CONFIG=$1/postgres/bin/pg_config
    sudo cp pg_bsd_indent /usr/local/bin

    cd $1/babelfish_extensions

    echo ""
    echo "Running pgindent on babelfishpg_money..."
    cd contrib/babelfishpg_money
    $1/postgresql_modified_for_babelfish/src/tools/pgindent/pgindent --typedefs=/tmp/babelfishpg_money.typedefs

    echo ""
    echo "Running pgindent on babelfishpg_common..."
    cd ../babelfishpg_common
    $1/postgresql_modified_for_babelfish/src/tools/pgindent/pgindent --typedefs=/tmp/babelfishpg_common.typedefs

    echo ""
    echo "Running pgindent on babelfishpg_tds..."
    cd ../babelfishpg_tds
    $1/postgresql_modified_for_babelfish/src/tools/pgindent/pgindent --typedefs=/tmp/babelfishpg_tds.typedefs

    echo ""
    echo "Running pgindent on babelfishpg_tsql..."
    cd ../babelfishpg_tsql
    $1/postgresql_modified_for_babelfish/src/tools/pgindent/pgindent --typedefs=/tmp/babelfishpg_tsql.typedefs --exclude="exclude_file_from_pgindent"

    echo ""
    echo "pgindent is ran successfully against $1."
    echo "Please re-build all the extensions to make sure that there is no compilation error."
    echo ""
}

init_lcov(){
    cd $1
    if [ ! -d "./lcov" ]; then
        git clone --depth 1 --branch v1.16 https://github.com/linux-test-project/lcov.git
    fi
    cd lcov
    sudo make PREFIX=/usr install
    export PATH=$PATH:/usr/bin/lcov
    export PATH=$PATH:/usr/bin/gcov
    export PATH=$PATH:/usr/bin/genhtml
}

init_pg_coverage(){
    init_lcov $1
    cd $1/postgresql_modified_for_babelfish
    ./configure --prefix=$2/postgres/ --without-readline --without-zlib --enable-coverage --enable-debug --enable-cassert CFLAGS="-ggdb" --with-libxml --with-uuid=ossp --with-icu
    make -j 4
    make install
    cd contrib && make && sudo make install
    sudo cp "/usr/local/lib/libantlr4-runtime.so.4.9.3" $2/postgres/lib/
    init_pghint $1 $2
}

build_extension_coverage(){
    cd $1/babelfish_extensions/contrib/$2
    lcov --gcov-tool gcov -q --no-external -c -i -d . -d ./ -o lcov_base.info
    lcov --gcov-tool gcov -q --no-external -c -d . -d ./ -o lcov_test.info
    rm -rf coverage
    genhtml -q --legend -o coverage --title=${2} --ignore-errors source --num-spaces=4  lcov_base.info lcov_test.info
    touch coverage-html-stamp

}

build_coverage(){
    build_extension_coverage $1 'babelfishpg_money'
    build_extension_coverage $1 'babelfishpg_common'
    build_extension_coverage $1 'babelfishpg_tds'
    build_extension_coverage $1 'babelfishpg_tsql'
    echo ""
    echo "  code coverage report generation completed"
    echo "  run './dev-tools.sh sum_coverage' to generate summarized code coverage for all extensions"
    echo "  HTML code coverage report for each extension is located as follows -"
    echo "      babelfishpg_money:  $TARGET_WS/babelfish_extensions/contrib/babelfishpg_money/coverage/index.html"
    echo "      babelfishpg_common: $TARGET_WS/babelfish_extensions/contrib/babelfishpg_common/coverage/index.html"
    echo "      babelfishpg_tds:    $TARGET_WS/babelfish_extensions/contrib/babelfishpg_tds/coverage/index.html"
    echo "      babelfishpg_tsql:   $TARGET_WS/babelfish_extensions/contrib/babelfishpg_tsql/coverage/index.html"
}

sum_coverage(){
    cd $1/babelfish_extensions/contrib
    lcov -a babelfishpg_tsql/lcov_test.info -a babelfishpg_tds/lcov_test.info -a babelfishpg_common/lcov_test.info -a babelfishpg_money/lcov_test.info -o lcov.info
    lcov --list lcov.info
}

if [ "$1" == "initdb" ]; then
    init_db $TARGET_WS
    exit 0
elif [ "$1" == "initpg" ]; then
    init_pg $TARGET_WS $TARGET_WS
    exit 0
elif [ "$1" == "initbbf" ]; then
    $TARGET_WS/babelfish_extensions/test/JDBC/init.sh
    exit 0
elif [ "$1" == "buildpg" ]; then
    build_pg $TARGET_WS
    restart $TARGET_WS
    exit 0
elif [ "$1" == "buildbbf" ]; then
    build_bbf $TARGET_WS $TARGET_WS
    restart $TARGET_WS
    exit 0
elif [ "$1" == "buildall" ]; then
    build_pg $TARGET_WS
    build_bbf $TARGET_WS $TARGET_WS
    restart $TARGET_WS
    exit 0
elif [ "$1" == "pg_upgrade" ]; then
    init_db $TARGET_WS
    stop $TARGET_WS
    echo "Init target workspace ($TARGET_WS) done!"

    SOURCE_WS=$2
    stop $SOURCE_WS || true

    cd $TARGET_WS
    if [ ! -d "./upgrade" ]; then
        mkdir upgrade
    fi
    cd upgrade
    ../postgres/bin/pg_upgrade -U $USER \
        -b $SOURCE_WS/postgres/bin -B $TARGET_WS/postgres/bin \
        -d $SOURCE_WS/postgres/data -D $TARGET_WS/postgres/data \
        -p 5432 -P 5433 -j 4 --link --verbose --retain
    echo ""

    ./delete_old_cluster.sh
    cd $TARGET_WS/postgres
    bin/pg_ctl -c -D data/ -l logfile start

    echo ""
    echo 'Updating babelfish extensions...'
    bin/psql -d $TEST_DB -U $USER -c \
        "ALTER EXTENSION babelfishpg_common UPDATE; ALTER EXTENSION babelfishpg_tsql UPDATE;"
    bin/psql -d $TEST_DB -U $USER -c \
        "ALTER SYSTEM SET babelfishpg_tsql.database_name = 'jdbc_testdb';"
    bin/psql -d $TEST_DB -U $USER -c \
        "SELECT pg_reload_conf();"
    exit 0
elif [ "$1" == "test" ]; then

    # Set migration_mode
    cd $TARGET_WS/postgres
    bin/psql -d $TEST_DB -U $USER -c \
        "ALTER SYSTEM SET babelfishpg_tsql.migration_mode = '$MIGRATION_MODE';"
    bin/psql -d $TEST_DB -U $USER -c \
        "SELECT pg_reload_conf();"

    # Remove output directory
    cd $CUR_WS/babelfish_extensions/test/JDBC
    rm -rf output temp_schedule

    export inputFilesPath=input
    if [ "$TEST_MODE" == "normal" ]; then
        export inputFilesPath=${TEST_BASE_DIR?}
    elif [ "$TEST_MODE" == "prepare" ]; then
        for filename in $(grep -v "^ignore.*\|^#.*\|^cmd.*\|^all.*\|^$" $TEST_BASE_DIR/schedule); do
          if [[ ! ($(find input/ -name $filename"-vu-prepare.*") || $(find input/ -name $filename"-vu-verify.*")) ]]; then 
            printf '%s\n' "ERROR: Cannot find Test file "$filename"-vu-prepare or "$filename"-vu-verify in input directory !!" >&2
            exit 1
          fi
        done
        cat $TEST_BASE_DIR/schedule > temp_schedule
        for filename in $(grep -v "^ignore.*\|^#.*\|^cmd.*\|^all.*\|^$" temp_schedule); do
          sed -i "s/$filename[ ]*$/$filename-vu-prepare/g" temp_schedule
        done
        export scheduleFile=temp_schedule
    elif [ "$TEST_MODE" == "verify" ]; then
        for filename in $(grep -v "^ignore.*\|^#.*\|^cmd.*\|^all.*\|^$" $TEST_BASE_DIR/schedule); do
          trimmed=$(awk '{$1=$1;print}' <<< "$filename")
          echo $trimmed-vu-verify >> temp_schedule;
          echo $trimmed-vu-cleanup >> temp_schedule;
        done
        export scheduleFile=temp_schedule
    fi

    mvn test
    rm -rf temp_schedule
    exit 0
elif [ "$1" == "minor_version_upgrade" ]; then
    echo "Building from $SOURCE_WS..."
    SOURCE_WS=$2
    init_pg $SOURCE_WS $TARGET_WS
    build_bbf $SOURCE_WS $TARGET_WS

    echo "Initializing from $SOURCE_WS..."
    init_db $TARGET_WS
    $TARGET_WS/babelfish_extensions/test/JDBC/init.sh

    echo "Building from $TARGET_WS..."
    build_pg $TARGET_WS
    build_bbf $TARGET_WS $TARGET_WS
    restart $TARGET_WS

    echo "Updating Babelfish..."
    cd $TARGET_WS/postgres
    bin/psql -d $TEST_DB -U $USER -c \
        "ALTER EXTENSION babelfishpg_common UPDATE; ALTER EXTENSION babelfishpg_tsql UPDATE;"
    exit 0
elif [ "$1" == "pg_dump" ]; then
    restart $TARGET_WS || true
    pg_dump $TARGET_WS $3
    exit 0
elif [ "$1" == "restore" ]; then
    SOURCE_WS=$2
    init_db $TARGET_WS
    echo "Init target workspace ($TARGET_WS) done!"

    restore $SOURCE_WS $TARGET_WS $4
    echo "Restored on target workspace ($TARGET_WS)!"
    exit 0
elif [ "$1" == "dumprestore" ]; then
    SOURCE_WS=$2
    restart $SOURCE_WS || true
    pg_dump $SOURCE_WS
    stop $SOURCE_WS || true
    echo "Dumped source workspace ($SOURCE_WS)!"

    init_db $TARGET_WS
    echo "Init target workspace ($TARGET_WS) done!"

    restore $SOURCE_WS $TARGET_WS
    echo "Restored on target workspace ($TARGET_WS)!"
    exit 0
elif [ "$1" == "run_pgindent" ]; then
    init_pg $TARGET_WS $TARGET_WS
    build_bbf $TARGET_WS $TARGET_WS
    run_pgindent $TARGET_WS
elif [ "$1" == "initpg_coverage" ]; then
    init_pg_coverage $TARGET_WS $TARGET_WS
    exit 0
elif [ "$1" == "build_coverage" ]; then
    build_coverage $TARGET_WS
    exit 0
elif [ "$1" == "sum_coverage" ]; then
    sum_coverage $TARGET_WS
    exit 0
fi
