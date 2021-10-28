%option prefix="pgtsql_core_yy"

%x xbr

xbrstart         \[
xbrstop          \]
xbrinside        [^\]]+

/* Currency symbols supported by TSQL */
cent                    \xC2\xA2
currency                \xC2\xA4
pound                   \xC2\xA3
yen                     \xC2\xA5
bengali_rupee_mark      \xE0\xA7\xB2
bengali_rupee_sign      \xE0\xA7\xB3
thai_baht               \xE0\xB8\xBF
khmer_riel              \xE1\x9F\x9B
euro_currency           \xE2\x82\xA0
colon_sign              \xE2\x82\xA1
cruzeiro                \xE2\x82\xA2
franc                   \xE2\x82\xA3
lira                    \xE2\x82\xA4
mill                    \xE2\x82\xA5
naira                   \xE2\x82\xA6
peseta                  \xE2\x82\xA7
rupee                   \xE2\x82\xA8
won                     \xE2\x82\xA9
new_sheqel              \xE2\x82\xAA
dong                    \xE2\x82\xAB
euro                    \xE2\x82\xAC
kip                     \xE2\x82\xAD
tugrik                  \xE2\x82\xAE
drachma                 \xE2\x82\xAF
german_penny            \xE2\x82\xB0
peso                    \xE2\x82\xB1
rial                    \xEF\xB7\xBC
small_dollar            \xEF\xB9\xA9
fullwidth_dollar        \xEF\xBC\x84
fullwidth_cent          \xEF\xBF\xA0
fullwidth_pound         \xEF\xBF\xA1
fullwidth_yen           \xEF\xBF\xA5
fullwidth_won           \xEF\xBF\xA6
currency_symbol         \$|{cent}|{currency}|{pound}|{yen}|{bengali_rupee_mark}|{bengali_rupee_sign}|{thai_baht}|{khmer_riel}|{euro_currency}|{colon_sign}|{cruzeiro}|{franc}|{lira}|{mill}|{naira}|{peseta}|{rupee}|{won}|{new_sheqel}|{dong}|{euro}|{kip}|{tugrik}|{drachma}|{german_penny}|{peso}|{rial}|{small_dollar}|{fullwidth_dollar}|{fullwidth_cent}|{fullwidth_pound}|{fullwidth_yen}|{fullwidth_won}

hex_cont [0-9A-Za-z]

/*
 * We create a non-exclusive start state to handle TSQL-only
 * tokens. For example, we want to treat @foo as an identifier
 * only when sql_dialect = tsql; when sql_dialect is set to
 * to postgres, @foo should be recognized as an operator (Op)
 * followed by an identifier
 */
%s		tsql
tsql_ident		@{ident_cont}*
tsql_money		{currency_symbol}{space}*[-+]?{digit}*\.?{digit}*
tsql_atat		"@@"
tsql_hex		0[xX]{hex_cont}*
tsql_ttname		\#?\#{ident_cont}*
tsql_label		{identifier}:
tsql_pg_cast		{identifier}::
tsql_ident_start [A-Za-z\200-\377_\#]
tsql_ident_cont	[A-Za-z\200-\377_0-9\$\#]
tsql_identifier	{tsql_ident_start}{tsql_ident_cont}*
