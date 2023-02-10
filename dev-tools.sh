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
    echo "  test INPUT_DIR [MIGRATION_MODE]"
    echo "      run JDBC test, default migration_mode is single-db"
    echo ""
    echo "  minor_version_upgrade SOURCE_WS [TARGET_WS]"
    echo "      upgrade minor version using ALTER EXTENSION ... UPDATE"
    echo ""
    echo "  pg_dump [TARGET_WS]"
    echo "      dump [TARGET_WS using pg_dump"
    echo ""
    echo "  restore SOURCE_WS [TARGET_WS]"
    echo "      restore dump files from SOURCE_WS on [TARGET_WS]"
    echo ""
    echo "  dumprestore SOURCE_WS [TARGET_WS]"
    echo "      dump SOURCE_WS using pg_dump and restore it on TARGET_WS"
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
    MIGRATION_MODE=$3
    if [ ! $MIGRATION_MODE ]; then
        MIGRATION_MODE="single-db"
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
    bin/pg_ctl -D data/ -l logfile restart
}

stop() {
    cd $1/postgres
    bin/pg_ctl -D data/ -l logfile stop
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
    bin/pg_ctl -D data/ -l logfile start
    cd data
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" postgresql.conf
    sudo sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'babelfishpg_tds'/g" postgresql.conf
    sudo echo "host    all             all             0.0.0.0/0            trust" >> pg_hba.conf
    restart $1
}

init_pghint() {
    cd $1
    if [ ! -d "./pg_hint_plan" ]; then
        git clone --depth 1 --branch REL14_1_4_0 https://github.com/ossc-db/pg_hint_plan.git
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
    $1/postgres/bin/pg_dumpall --username jdbc_user --globals-only --quote-all-identifiers --verbose -f pg_dump_globals.sql 2>error.log
    $1/postgres/bin/pg_dump --username jdbc_user --column-inserts --quote-all-identifiers --verbose --file="pg_dump.sql" --dbname=jdbc_testdb 2>>error.log
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
    $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -f $1/postgres/pg_dump.sql 2>>error.log
    $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -c "GRANT ALL ON SCHEMA sys to jdbc_user;"
    $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -c "GRANT CREATE, CONNECT, TEMPORARY ON DATABASE jdbc_testdb TO sysadmin WITH GRANT OPTION;"
    $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -c "ALTER USER jdbc_user CREATEDB;"
    $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -c "ALTER SYSTEM SET babelfishpg_tsql.database_name = 'jdbc_testdb';"
    $2/postgres/bin/psql -d jdbc_testdb -U jdbc_user -c "SELECT pg_reload_conf();"
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
    else
        rm upgrade/*
    fi
    cd upgrade
    ../postgres/bin/pg_upgrade -U $USER \
        -b $SOURCE_WS/postgres/bin -B $TARGET_WS/postgres/bin \
        -d $SOURCE_WS/postgres/data -D $TARGET_WS/postgres/data \
        -p 5432 -P 5433 -j 4 --link --verbose --retain
    echo ""

    ./delete_old_cluster.sh
    cd $TARGET_WS/postgres
    bin/pg_ctl -D data/ -l logfile start

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
    INPUT_DIR=$2
    cd $TARGET_WS/postgres

    bin/psql -d $TEST_DB -U $USER -c \
        "ALTER SYSTEM SET babelfishpg_tsql.migration_mode = '$MIGRATION_MODE';"
    bin/psql -d $TEST_DB -U $USER -c \
        "SELECT pg_reload_conf();"

    cd $CUR_WS/babelfish_extensions/test/JDBC
    rm -rf output
    export inputFilesPath=$INPUT_DIR
    mvn test
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
    pg_dump $TARGET_WS
    exit 0
elif [ "$1" == "restore" ]; then
    SOURCE_WS=$2
    init_db $TARGET_WS
    echo "Init target workspace ($TARGET_WS) done!"

    restore $SOURCE_WS $TARGET_WS
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
fi
