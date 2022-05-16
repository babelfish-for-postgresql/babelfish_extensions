#!/bin/sh

set -e

if [ ! $1 ]; then
    echo "This is a tool helping developers to build and test Babelfish easily."
    echo ""
    echo "Prerequisites:"
    echo "      (1) postgresql_modified_for_babelfish, babelfish_extensions, and postgres should be in the same workspace."
    echo "      (2) should be executed in the \"babelfish_extension\" directory."
    echo ""
    echo "Arguments:"
    echo "      initdb      init data directory + modify postgresql.conf + restart db"
    echo "      initbbf     execute babelfish_extensions/test/JDBC/init.sh"
    echo "      buildpg     build postgresql_modified_for_babelfish + restart db"
    echo "      buildbbf    build babelfish_extensions + restart db"
    echo "      buildall    build postgresql_modified_for_babelfish + build babelfish_extensions + restart db"
    exit 0
fi

CUR_DIR=`basename "${PWD}"`
if [ "$CUR_DIR" != "babelfish_extensions" ]; then
    echo "Error: This script should be executed in the \"babelfish_extension\" directory." 1>&2
    exit 1
fi
cd ..
WS_ROOT=${PWD}
echo "Workspace root: $WS_ROOT"
if [ ! -d "./postgres" ]; then
    echo "Error: Directory \"postgres\" should exist in the workspace." 1>&2
    exit 1
fi
if [ ! -d "./postgresql_modified_for_babelfish" ]; then
    echo "Error: Directory \"postgresql_modified_for_babelfish\" should exist in the workspace." 1>&2
    exit 1
fi

restart() {
    PREV_DIR=${PWD}
    cd $WS_ROOT/postgres
    bin/pg_ctl -D data/ -l logfile restart
    cd $PREV_DIR
}

build_engine() {
    PREV_DIR=${PWD}
    cd $WS_ROOT/postgresql_modified_for_babelfish
    make install
    cd $PREV_DIR
}

build_bbf() {
    PREV_DIR=${PWD}
    cd $WS_ROOT/babelfish_extensions
    export PG_CONFIG=$WS_ROOT/postgres/bin/pg_config
    export PG_SRC=$WS_ROOT/postgresql_modified_for_babelfish
    export cmake=$(which cmake)
    cd contrib/babelfishpg_money
    make clean && make && make install
    cd ../babelfishpg_common
    make clean && make && make install
    cd ../babelfishpg_tds
    make clean && make && make install
    cd ../babelfishpg_tsql
    make clean && make && make install
    cd $PREV_DIR
}

if [ "$1" == "initdb" ]; then
    cd postgres
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
    restart
    exit 0
elif [ "$1" == "initbbf" ]; then
    cd babelfish_extensions/test/JDBC
    ./init.sh
    exit 0
elif [ "$1" == "buildpg" ]; then
    build_engine
    restart
    exit 0
elif [ "$1" == "buildbbf" ]; then
    build_bbf
    restart
    exit 0
elif [ "$1" == "buildall" ]; then
    build_engine
    build_bbf
    restart
    exit 0
fi
