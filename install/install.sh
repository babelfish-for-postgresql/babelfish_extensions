#!/bin/sh

export BABELFISH_CODE_USER="${BABELFISH_CODE_USER:-babelfish-compiler}"
export BABELFISH_CODE_PATH="${BABELFISH_CODE_PATH:-/opt/babelfish-code}"
export BABELFISH_INSTALLATION_PATH="${BABELFISH_INSTALLATION_PATH:-/usr/local/pgsql-13.4}"
export BABELFISH_DATA_PATH=/usr/local/pgsql/data
export PG_SRC="$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish"
export EXTENSIONS_SOURCE_CODE_PATH="$BABELFISH_CODE_PATH/babelfish_extensions"
export PG_CONFIG="$BABELFISH_INSTALLATION_PATH/bin/pg_config"
export cmake=/usr/bin/cmake

get_distro_id(){
  ID=$(grep "^ID=" /etc/os-release | cut -d "=" -f 2 | sed -e 's/^"//' -e 's/"$//')
  NAME=$(grep "^VERSION_ID=" /etc/os-release | cut -d "=" -f 2 | sed -e 's/^"//' -e 's/"$//')
  echo "$ID.$NAME"
}

antlr_download(){
  curl https://www.antlr.org/download/antlr4-cpp-runtime-4.9.2-source.zip \
    --output /opt/antlr4-cpp-runtime-4.9.2-source.zip 

  # Uncompress the source into /opt/antlr4
  unzip -d /opt/antlr4 /opt/antlr4-cpp-runtime-4.9.2-source.zip

  mkdir /opt/antlr4/build 
  cd /opt/antlr4/build || exit 1
}

compile_antlr(){
  # Generates the make files for the build
  cmake .. -DANTLR_JAR_LOCATION="$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-4.9.2-complete.jar" \
          -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True
  # Compiles and install
  make
  make install
}

copy_antlr_runtime(){
  cp /usr/local/lib/libantlr4-runtime.so.4.9.2 "$BABELFISH_INSTALLATION_PATH/lib"
}

configure_antlr(){
  antlr_download

  compile_antlr

  copy_antlr_runtime
}

DISTRO_ID=$(get_distro_id)

. "$PWD/prerequisites/$DISTRO_ID"

core_prerequisites
extension_prerequisites

if ! id "$BABELFISH_CODE_USER" > /dev/null
then
  useradd "$BABELFISH_CODE_USER" 
fi

mkdir -p "$BABELFISH_CODE_PATH"

cd "$BABELFISH_CODE_PATH" || exit 1

## Downloading latest babelfish engine source code
wget https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish/archive/refs/heads/BABEL_1_X_DEV__13_4.zip
  
unzip BABEL_1_X_DEV__13_4.zip 

mv postgresql_modified_for_babelfish-BABEL_1_X_DEV__13_4 "$PG_SRC"

rm BABEL_1_X_DEV__13_4.zip

chown -R "$BABELFISH_CODE_USER:$BABELFISH_CODE_USER" "$PG_SRC"

## Downloading latest babelbish extension source code

wget https://github.com/babelfish-for-postgresql/babelfish_extensions/archive/refs/heads/BABEL_1_X_DEV.zip

unzip BABEL_1_X_DEV.zip

mv babelfish_extensions-BABEL_1_X_DEV $EXTENSIONS_SOURCE_CODE_PATH

rm BABEL_1_X_DEV.zip

chown -R "$BABELFISH_CODE_USER:$BABELFISH_CODE_USER" "$EXTENSIONS_SOURCE_CODE_PATH"

cd "$PG_SRC" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- ./configure CFLAGS="-ggdb" \
  --prefix="$BABELFISH_INSTALLATION_PATH" \
  --enable-debug \
  --with-libxml \
  --with-uuid=ossp \
  --with-icu \
  --with-extra-version=" Babelfish for PostgreSQL"

mkdir -p "$BABELFISH_INSTALLATION_PATH"

chown -R "$BABELFISH_CODE_USER:$BABELFISH_CODE_USER" "$BABELFISH_INSTALLATION_PATH"

#Compilining babelfish engine
cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish" || exit 1
runuser -u "$BABELFISH_CODE_USER" make # Compiles the Babefish for PostgreSQL engine

cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish/contrib" || exit 1
runuser -u "$BABELFISH_CODE_USER" make # Compiles the PostgreSQL default extensions

cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish" || exit 1

runuser -u "$BABELFISH_CODE_USER" make install # Installs the Babelfish for PostgreSQL engine
cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish/contrib" || exit 1

runuser -u "$BABELFISH_CODE_USER" make install # Installs the PostgreSQL default extensions

configure_antlr

# Install babelfishpg_money extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_money" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

# Install babelfishpg_common extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_common" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

# Install babelfishpg_tds extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tds" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

# Installs the babelfishpg_tsql extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

mkdir -p "$BABELFISH_DATA_PATH"

useradd postgres

chown -R postgres:postgres "$BABELFISH_INSTALLATION_PATH"
chown -R postgres:postgres "$BABELFISH_DATA_PATH"

runuser -u "postgres" -- "$BABELFISH_INSTALLATION_PATH/bin/initdb" -D "$BABELFISH_DATA_PATH"

echo "listen_addresses = '*'" >> "$BABELFISH_DATA_PATH/postgresql.conf"
echo "shared_preload_libraries = 'babelfishpg_tds'" >> "$BABELFISH_DATA_PATH/postgresql.conf"

cd "$BABELFISH_INSTALLATION_PATH" || exit 1

runuser -u "postgres" -- "$BABELFISH_INSTALLATION_PATH/bin/pg_ctl" -D "$BABELFISH_DATA_PATH" start