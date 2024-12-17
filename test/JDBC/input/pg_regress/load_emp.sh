echo "-----copy emp table from /data/emp.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d babelfish_db -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/emp.data'
COPY master_dbo.emp FROM :'filename';
EOF
echo "----- done -----"