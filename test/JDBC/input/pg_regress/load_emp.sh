echo "-----copy emp table from /data/emp.data-----"
# export PG_SRC=~/work/babelfish_extensions/postgresql_modified_for_babelfish
psql -U jdbc_user -d jdbc_testdb -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/emp.data'
COPY master_dbo.emp FROM :'filename';
EOF
echo "----- done -----"