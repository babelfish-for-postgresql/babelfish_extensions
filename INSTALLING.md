# Compiling Babelfish from distribution tarballs

This document will walk you through the steps required to create a working Babelfish installation on an Ubuntu 20.04 Linux host. Please note that the steps may vary on other operating systems, but the overall process is roughly the same.

The installation steps that follow are for the release tar or zip file, which uses content from the following repositories:

- the [PostgreSQL database engine source code repository](https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish), with changes that provide the protocols, language parsers, and features required by Babelfish. 
- the [extensions repository](https://github.com/babelfish-for-postgresql/babelfish_extensions) - extensions support the T-SQL protocol, the T-SQL language, the TDS Protocol, and other Babelfish behaviors.

## Prerequisites

### Hardware and Specs

The current installation instructions were tested using `t4g.large`, `t4.large`, and `c6g.xlarge` instances as hosts.

This installation has also been tested on [ami-0fb653ca2d3203ac1 for amd64](https://us-east-2.console.aws.amazon.com/ec2/v2/home?region=us-east-2#Images:visibility=public-images;imageId=ami-0fb653ca2d3203ac1), and [ami-02af65b2d1ebdfafc for arm64](https://us-east-2.console.aws.amazon.com/ec2/v2/home?region=us-east-2#Images:visibility=public-images;imageId=ami-02af65b2d1ebdfafc).

To compile Babelfish, you should have at least 4GB of available memory.

### Required Software

Install the following dependencies:

```
sudo apt-get update && sudo apt install -y --no-install-recommends \
  build-essential flex libxml2-dev libxml2-utils \
  libxslt-dev libssl-dev libreadline-dev zlib1g-dev \
  libldap2-dev libpam0g-dev gettext uuid uuid-dev \
  cmake lld apt-utils libossp-uuid-dev gnulib bison \
  xsltproc icu-devtools libicu66 \
  libicu-dev gawk \
  curl openjdk-8-jre openssl \
  g++ libssl-dev python-dev libpq-dev \
  pkg-config libutfcpp-dev \
  gnupg unixodbc-dev net-tools unzip
```

Many of the Babelfish prerequisites are part of a typical Linux distribution.  You may find that the packages on your distribution use a similar (but not identical) name.  

To build Babelfish, you will need access to a user with root privileges, so you can convey privileges with `sudo`. You'll also need a non-root user to initialize the database; PostgreSQL does not allow a root user to own the `data` directory or start the server.


### Set environment variables

Navigate into the extracted distribution folder and set the following environment variables:

```sh
export JOBS=4 # Adjust to number of cores
export BABELFISH_HOME=/opt/babelfish/1.4.0
export PG_CONFIG=${BABELFISH_HOME}/bin/pg_config
export PG_SRC=$(realpath $PWD)
```

### Compile ANTLR 4

Unfortunately, there are [no prebuilt C++ binaries for the Antlr 4.9.3 runtime version](https://www.antlr.org/download.html) for Linux. You will need to compile and install ANTLR manually.

First, define the following variables in your environment:

```sh
export ANTLR4_VERSION=4.9.3
export ANTLR4_JAVA_BIN=/usr/bin/java
export ANTLR4_RUNTIME_LIBRARIES=/usr/include/antlr4-runtime
export ANTLR_EXECUTABLE=/usr/local/lib/antlr-${ANTLR4_VERSION}-complete.jar
export ANTLR_RUNTIME=~/antlr4
```

The [Antlr 4.9.3 Runtime](https://www.antlr.org/) files are distributed with the Babelfish source code.  Use the following commands to copy the files into place:

```sh
sudo cp ${PG_SRC}/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-${ANTLR4_VERSION}-complete.jar /usr/local/lib
```

After copying the ANTLR .jar files into place, compile ANTLR: 

```sh
cd ${HOME}

wget http://www.antlr.org/download/antlr4-cpp-runtime-${ANTLR4_VERSION}-source.zip
unzip -d ${ANTLR_RUNTIME} antlr4-cpp-runtime-${ANTLR4_VERSION}-source.zip

cd ${ANTLR_RUNTIME}
mkdir build && cd build 
cmake .. -D ANTLR_JAR_LOCATION=/usr/local/lib/antlr-${ANTLR4_VERSION}-complete.jar -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True
make -j $JOBS 
sudo make install
```

## Build modified PostgreSQL for Babelfish

The version of PostgreSQL that is distributed with Babelfish includes hooks that allow Babelfish to implement behaviors.  Babelfish will not work with PostgreSQL distributions from other sources.  Use the following commands to configure the build environment and build the Babelfish PostgreSQL distribution: 

```sh
cd ${PG_SRC}

./configure CFLAGS="-ggdb" \
  --prefix=${BABELFISH_HOME}/ \
  --enable-debug \
  --with-ldap \
  --with-libxml \
  --with-pam \
  --with-uuid=ossp \
  --enable-nls \
  --with-libxslt \
  --with-icu
          
make DESTDIR=${BABELFISH_HOME}/ -j $JOBS 2>error.txt
          
sudo make install
```

> WARNING: Using the --with-extra-version option during the configuration phase can break the sys.get_host_os() output; we do not recommend including it.

Build and install the extensions because `uuid-ossp.so` is a runtime dependency for Babelfish:

```sh
cd ${PG_SRC}/contrib && make -j ${JOBS} && sudo make install
```

### Compile the ANTLR parser generator 

Use the following commands to compile the ANTLR parser generator and copy the runtime to the PostgreSQL library location:

``` sh
export cmake=$(which cmake)
          
sudo cp /usr/local/lib/libantlr4-runtime.so.${ANTLR4_VERSION} ${BABELFISH_HOME}/lib
           
cd ${PG_SRC}/contrib/babelfishpg_tsql/antlr 
cmake -Wno-dev .
make all
``` 

### Compile the contrib modules and build Babelfish

Now, it is time to compile the contrib modules and build Babelfish. Use the command:

```sh
cd ${PG_SRC}/contrib
for ext in babelfishpg_common babelfishpg_money babelfishpg_tds babelfishpg_tsql 
do
    cd $ext
    make -j ${JOBS}
    sudo make PG_CONFIG=${PG_CONFIG} install
    cd ..
done
```

## Setting up the PostgreSQL modified instance

The steps required to create a new cluster and start the service are very similar to the steps required by a community PostgreSQL installation:

```sh
sudo mkdir -p /var/lib/babelfish/1.4.0

sudo adduser postgres --home /var/lib/babelfish
```

Ensure that the related folders hold the permissions for the service user:

```sh
sudo chown -R postgres: /opt/babelfish/
sudo chown -R postgres: /var/lib/babelfish/
```

Switch to the `postgres` user (a non-superuser) and start the cluster:

```sh
sudo su - postgres
export BABELFISH_HOME=/opt/babelfish/1.4.0
export BABELFISH_DATA=/var/lib/babelfish/1.4.0/data
```

### Initiating the Data directory

#### Initiate data with trustable connection for development

If you would like to create a local cluster for testing purposes, you can configure trust authentication when initializing the database to simplify authentication. The `--auth-host=trust` flag will create the cluster using trust authentication, and should not be included if you are creating an instance that will contain sensitive information:

```sh
${BABELFISH_HOME}/bin/initdb -D ${BABELFISH_DATA}/ -E "UTF8" --auth=trust --auth-host=trust --auth-local=trust
```

#### Initiate data with specific HBA configuration

For production or isolated environments, it is recommended to specify the allowed IP addresses that can access the system and a secure authentication method such as `md5` in the `pg_hba.conf`. For other supported methods see [Authentication Methods documentation](https://www.postgresql.org/docs/14/auth-methods.html).

```sh
${BABELFISH_HOME}/bin/initdb -D ${BABELFISH_DATA}/ -E "UTF8"
```

Once the data directory is initialized, edit the `${BABELFISH_DATA}/pg_hba.conf` file following the [vanilla Postgres HBA configuration](https://www.postgresql.org/docs/14/auth-pg-hba-conf.html).



### Configuring PostgreSQL for Babelfish

The `postgresql.conf` configuration changes shown below are required before starting the service:

```sh
cat << EOF >> ${BABELFISH_DATA}/postgresql.conf

#------------------------------------------------------------------------------
# BABELFISH RELATED OPTIONS
# These are going to step over previous duplicated variables.
#------------------------------------------------------------------------------
listen_addresses = '*'
allow_system_table_mods = on
shared_preload_libraries = 'babelfishpg_tds'
babelfishpg_tds.listen_addresses = '*'
EOF

```

> For more information about Babelfish variables, see [Configuring Babelfish](https://babelfishpg.org/docs/internals/configuration/)

Then, start the instance with the following command:

```sh
${BABELFISH_HOME}/bin/pg_ctl -D ${BABELFISH_DATA}/ -l logfile start
```

### Enabling extensions in the target database

Create a user (babelfish_user) and the database (babelfish_db) into which the extensions will be installed:

```sh
${BABELFISH_HOME}/bin/psql -d postgres -U postgres -c "CREATE USER babelfish_user WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '12345678' INHERIT;"
${BABELFISH_HOME}/bin/psql -d postgres -U postgres -c "DROP DATABASE IF EXISTS babelfish_db;"
${BABELFISH_HOME}/bin/psql -d postgres -U postgres -c "CREATE DATABASE babelfish_db OWNER babelfish_user;"
```

Connect to the babelfish_db database, and configure and install the extensions:

```sh
${BABELFISH_HOME}/bin/psql -d babelfish_db -U postgres -c "CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;"
${BABELFISH_HOME}/bin/psql -d babelfish_db -U postgres -c "GRANT ALL ON SCHEMA sys to babelfish_user;"
${BABELFISH_HOME}/bin/psql -d babelfish_db -U postgres -c "ALTER USER babelfish_user CREATEDB;"
${BABELFISH_HOME}/bin/psql -d babelfish_db -U postgres -c "ALTER SYSTEM SET babelfishpg_tsql.database_name = 'babelfish_db';"
${BABELFISH_HOME}/bin/psql -d babelfish_db -U postgres -c "SELECT pg_reload_conf();"
```


By default, the `migration_mode` is `single-db`. To deploy in `multi-db` mode, you need to modify the Babelfish configuration file before initializing the database:

```sh
${BABELFISH_HOME}/bin/psql -d babelfish_db -U postgres -c "ALTER DATABASE babelfish_db SET babelfishpg_tsql.migration_mode = 'multi-db';"
```

> For more information about the `migration_mode`, see [Single vs. multiple instances](https://babelfishpg.org/docs/installation/single-multiple/) and [Choosing a migration mode](https://babelfishpg.org/docs/installation/single-multiple/#choosing-a-migration-mode).


Finally, initialize the database by calling _sys.initialize_babelfish_:

```sh
${BABELFISH_HOME}/bin/psql -d babelfish_db -U postgres -c "CALL sys.initialize_babelfish('babelfish_user');"
```

## Connecting to the Babelfish Database through TDS port

For testing, we're going to use FreeTDS command-line client, available for both _x86_ and _arm64_ platforms:

- Exit postgres user:

```sh
exit
```

- Install the packages:

```sh
sudo apt install -y freetds-bin freetds-common
```

- Connect with `tsql`:

```sh
$ tsql -H localhost -U babelfish_user -p 1433  -P 12345678 -D master
locale is "C.UTF-8"
locale charset is "UTF-8"
using default charset "UTF-8"
Setting master as default database in login packet
Changed database context to 'master'.
1> SELECT @@VERSION
2> GO
version
Babelfish for PostgreSQL with SQL Server Compatibility - 12.0.2000.8
...
Copyright (c) Amazon Web Services
PostgreSQL 13.8 Babelfish for PostgreSQL on x86_64-pc-linux-gnu
(1 row affected)
```

If you are testing from a remote server, add the `-H` option:

```sh
tsql -H localhost -U babelfish_user -p 1433  -P 12345678 -D master -H ${ip_address}
```

- If you're a sqlcmd user, the following command will access the database with a `sqlcmd` client:

```sh
sqlcmd -S localhost -U babelfish_user -P 12345678 
```

> Note that `mssql-tools` does not support _arm64_ packages.
