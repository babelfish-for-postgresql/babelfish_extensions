#!/bin/sh

set -e

restart() {
    cd ~/postgres
    bin/pg_ctl -D data/ -l logfile restart
}

build_pg() {
    cd /src/postgresql_modified_for_babelfish
    ./configure --prefix=$HOME/postgres/ --without-readline --without-zlib --enable-debug CFLAGS="-ggdb" --with-libxml --with-uuid=ossp --with-icu
    make -j 4 2>error.txt
    make install
    make check
    cd contrib && make && make install
}

build_bbf() {
    cd /src/babelfish_extensions/contrib/babelfishpg_tsql/antlr/thirdparty/antlr
    sudo cp antlr-4.9.3-complete.jar /usr/local/lib
    cd ~
    wget http://www.antlr.org/download/antlr4-cpp-runtime-4.9.3-source.zip
    unzip -d antlr4 antlr4-cpp-runtime-4.9.3-source.zip 
    cd antlr4
    mkdir build && cd build 
    cmake .. -DANTLR_JAR_LOCATION=/usr/local/lib/antlr-4.9.3-complete.jar -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True
    make
    sudo make install
    sudo cp /usr/local/lib/libantlr4-runtime.so.4.9.3 ~/postgres/lib/

    export PG_CONFIG=~/postgres/bin/pg_config
    export PG_SRC=/src/postgresql_modified_for_babelfish
    export cmake=$(which cmake)
    # SET (MYDIR /usr/local/include/antlr4-runtime/)

    cd /src/babelfish_extensions/contrib/babelfishpg_money
    make && make install
    cd ../babelfishpg_common
    make && make install
    cd ../babelfishpg_tds
    make && make install
    cd ../babelfishpg_tsql
    make && make install
}

init_db() {
    cd ~/postgres
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
    restart ~
}

if [ "$1" = "initdb" ]; then
    init_db 
    exit 0
elif [ "$1" = "initbbf" ]; then
    /src/babelfish_extensions/test/JDBC/init.sh
    exit 0
elif [ "$1" = "buildpg" ]; then
    build_pg 
    exit 0
elif [ "$1" = "buildbbf" ]; then
    build_bbf 
    restart 
    exit 0
elif [ "$1" = "buildall" ]; then
    build_pg 
    build_bbf 
    restart 
    exit 0
fi