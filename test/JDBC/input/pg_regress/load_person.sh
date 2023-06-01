echo "-----copy person table from /data/person.data-----"
export PG_SRC=~/work/babelfish_extensions/postgresql_modified_for_babelfish
psql -U jdbc_user -d jdbc_testdb -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/person.data'
COPY master_dbo.person FROM :'filename';
EOF
echo "----- done -----"