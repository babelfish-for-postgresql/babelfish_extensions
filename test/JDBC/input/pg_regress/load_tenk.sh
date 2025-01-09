echo "-----copy tenk1 table from /data/tenk.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d babelfish_db -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/tenk.data'
COPY master_dbo.tenk1 FROM :'filename';
EOF
echo "----- done -----"