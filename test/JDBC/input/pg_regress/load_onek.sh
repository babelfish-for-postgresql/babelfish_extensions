echo "-----copy onek table from /data/onek.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d babelfish_db -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/onek.data'
COPY master_dbo.onek FROM :'filename';
EOF
echo "----- done -----"