create view test_func_fixeddecimalout_0 as select sys.fixeddecimalout(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalsend_1 as select sys.fixeddecimalsend(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimaltypmodout_2 as select sys.fixeddecimaltypmodout(cast(1 as int4));
go

create view test_func_fixeddecimaleq_3 as select sys.fixeddecimaleq(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalne_4 as select sys.fixeddecimalne(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimallt_5 as select sys.fixeddecimallt(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalle_6 as select sys.fixeddecimalle(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalgt_7 as select sys.fixeddecimalgt(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_bpcharcmp_8 as select sys.bpcharcmp(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_fixeddecimalge_9 as select sys.fixeddecimalge(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalum_10 as select sys.fixeddecimalum(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalpl_11 as select sys.fixeddecimalpl(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalmi_12 as select sys.fixeddecimalmi(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalmul_13 as select sys.fixeddecimalmul(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimaldiv_14 as select sys.fixeddecimaldiv(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_abs_15 as select sys.abs(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimallarger_16 as select sys.fixeddecimallarger(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimalsmaller_17 as select sys.fixeddecimalsmaller(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_cmp_18 as select sys.fixeddecimal_cmp(cast(1.2 as fixeddecimal), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_hash_19 as select sys.fixeddecimal_hash(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_numeric_cmp_20 as select sys.fixeddecimal_numeric_cmp(cast(1.2 as fixeddecimal), cast(1.2 as numeric));
go

create view test_func_hashbpchar_21 as select sys.hashbpchar(cast('a' as bpchar));
go

create view test_func_numeric_fixeddecimal_cmp_22 as select sys.numeric_fixeddecimal_cmp(cast(1.2 as numeric), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_numeric_eq_23 as select sys.fixeddecimal_numeric_eq(cast(1.2 as fixeddecimal), cast(1.2 as numeric));
go

create view test_func_fixeddecimal_numeric_ne_24 as select sys.fixeddecimal_numeric_ne(cast(1.2 as fixeddecimal), cast(1.2 as numeric));
go

create view test_func_fixeddecimal_numeric_lt_25 as select sys.fixeddecimal_numeric_lt(cast(1.2 as fixeddecimal), cast(1.2 as numeric));
go

create view test_func_fixeddecimal_numeric_le_26 as select sys.fixeddecimal_numeric_le(cast(1.2 as fixeddecimal), cast(1.2 as numeric));
go

create view test_func_fixeddecimal_numeric_gt_27 as select sys.fixeddecimal_numeric_gt(cast(1.2 as fixeddecimal), cast(1.2 as numeric));
go

create view test_func_fixeddecimal_numeric_ge_28 as select sys.fixeddecimal_numeric_ge(cast(1.2 as fixeddecimal), cast(1.2 as numeric));
go

create view test_func_numeric_fixeddecimal_eq_29 as select sys.numeric_fixeddecimal_eq(cast(1.2 as numeric), cast(1.2 as fixeddecimal));
go

create view test_func_numeric_fixeddecimal_ne_30 as select sys.numeric_fixeddecimal_ne(cast(1.2 as numeric), cast(1.2 as fixeddecimal));
go

create view test_func_numeric_fixeddecimal_lt_31 as select sys.numeric_fixeddecimal_lt(cast(1.2 as numeric), cast(1.2 as fixeddecimal));
go

create view test_func_numeric_fixeddecimal_le_32 as select sys.numeric_fixeddecimal_le(cast(1.2 as numeric), cast(1.2 as fixeddecimal));
go

create view test_func_numeric_fixeddecimal_gt_33 as select sys.numeric_fixeddecimal_gt(cast(1.2 as numeric), cast(1.2 as fixeddecimal));
go

create view test_func_numeric_fixeddecimal_ge_34 as select sys.numeric_fixeddecimal_ge(cast(1.2 as numeric), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_int8_cmp_35 as select sys.fixeddecimal_int8_cmp(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimal_int8_eq_36 as select sys.fixeddecimal_int8_eq(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimal_int8_ne_37 as select sys.fixeddecimal_int8_ne(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimal_int8_lt_38 as select sys.fixeddecimal_int8_lt(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimal_int8_le_39 as select sys.fixeddecimal_int8_le(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimal_int8_gt_40 as select sys.fixeddecimal_int8_gt(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimal_int8_ge_41 as select sys.fixeddecimal_int8_ge(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimalint8pl_42 as select sys.fixeddecimalint8pl(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimalint8mi_43 as select sys.fixeddecimalint8mi(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimalint8mul_44 as select sys.fixeddecimalint8mul(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_fixeddecimalint8div_45 as select sys.fixeddecimalint8div(cast(1.2 as fixeddecimal), cast(1 as int8));
go

create view test_func_int8_fixeddecimal_cmp_46 as select sys.int8_fixeddecimal_cmp(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8_fixeddecimal_eq_47 as select sys.int8_fixeddecimal_eq(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8_fixeddecimal_ne_48 as select sys.int8_fixeddecimal_ne(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8_fixeddecimal_lt_49 as select sys.int8_fixeddecimal_lt(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8_fixeddecimal_le_50 as select sys.int8_fixeddecimal_le(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8_fixeddecimal_gt_51 as select sys.int8_fixeddecimal_gt(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8_fixeddecimal_ge_52 as select sys.int8_fixeddecimal_ge(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8fixeddecimalpl_53 as select sys.int8fixeddecimalpl(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8fixeddecimalmi_54 as select sys.int8fixeddecimalmi(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8fixeddecimalmul_55 as select sys.int8fixeddecimalmul(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8fixeddecimaldiv_56 as select sys.int8fixeddecimaldiv(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_int8fixeddecimaldiv_money_57 as select sys.int8fixeddecimaldiv_money(cast(1 as int8), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_int4_cmp_58 as select sys.fixeddecimal_int4_cmp(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimal_int4_eq_59 as select sys.fixeddecimal_int4_eq(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimal_int4_ne_60 as select sys.fixeddecimal_int4_ne(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimal_int4_lt_61 as select sys.fixeddecimal_int4_lt(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimal_int4_le_62 as select sys.fixeddecimal_int4_le(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimal_int4_gt_63 as select sys.fixeddecimal_int4_gt(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimal_int4_ge_64 as select sys.fixeddecimal_int4_ge(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimalint4pl_65 as select sys.fixeddecimalint4pl(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimalint4mi_66 as select sys.fixeddecimalint4mi(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimalint4mul_67 as select sys.fixeddecimalint4mul(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_fixeddecimalint4div_68 as select sys.fixeddecimalint4div(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_int4_fixeddecimal_cmp_69 as select sys.int4_fixeddecimal_cmp(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4_fixeddecimal_eq_70 as select sys.int4_fixeddecimal_eq(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4_fixeddecimal_ne_71 as select sys.int4_fixeddecimal_ne(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4_fixeddecimal_lt_72 as select sys.int4_fixeddecimal_lt(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4_fixeddecimal_le_73 as select sys.int4_fixeddecimal_le(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4_fixeddecimal_gt_74 as select sys.int4_fixeddecimal_gt(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4_fixeddecimal_ge_75 as select sys.int4_fixeddecimal_ge(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4fixeddecimalpl_76 as select sys.int4fixeddecimalpl(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4fixeddecimalmi_77 as select sys.int4fixeddecimalmi(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4fixeddecimalmul_78 as select sys.int4fixeddecimalmul(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4fixeddecimaldiv_79 as select sys.int4fixeddecimaldiv(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_int4fixeddecimaldiv_money_80 as select sys.int4fixeddecimaldiv_money(cast(1 as int4), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_int2_cmp_81 as select sys.fixeddecimal_int2_cmp(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimal_int2_eq_82 as select sys.fixeddecimal_int2_eq(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimal_int2_ne_83 as select sys.fixeddecimal_int2_ne(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimal_int2_lt_84 as select sys.fixeddecimal_int2_lt(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimal_int2_le_85 as select sys.fixeddecimal_int2_le(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimal_int2_gt_86 as select sys.fixeddecimal_int2_gt(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimal_int2_ge_87 as select sys.fixeddecimal_int2_ge(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimalint2pl_88 as select sys.fixeddecimalint2pl(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimalint2mi_89 as select sys.fixeddecimalint2mi(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimalint2mul_90 as select sys.fixeddecimalint2mul(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_fixeddecimalint2div_91 as select sys.fixeddecimalint2div(cast(1.2 as fixeddecimal), cast(1 as int2));
go

create view test_func_int2_fixeddecimal_cmp_92 as select sys.int2_fixeddecimal_cmp(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2_fixeddecimal_eq_93 as select sys.int2_fixeddecimal_eq(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2_fixeddecimal_ne_94 as select sys.int2_fixeddecimal_ne(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2_fixeddecimal_lt_95 as select sys.int2_fixeddecimal_lt(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2_fixeddecimal_le_96 as select sys.int2_fixeddecimal_le(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2_fixeddecimal_gt_97 as select sys.int2_fixeddecimal_gt(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2_fixeddecimal_ge_98 as select sys.int2_fixeddecimal_ge(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2fixeddecimalpl_99 as select sys.int2fixeddecimalpl(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2fixeddecimalmi_100 as select sys.int2fixeddecimalmi(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2fixeddecimalmul_101 as select sys.int2fixeddecimalmul(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2fixeddecimaldiv_102 as select sys.int2fixeddecimaldiv(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_int2fixeddecimaldiv_money_103 as select sys.int2fixeddecimaldiv_money(cast(1 as int2), cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_104 as select sys.fixeddecimal(cast(1.2 as fixeddecimal), cast(1 as int4));
go

create view test_func_int8fixeddecimal_105 as select sys.int8fixeddecimal(cast(1 as int8));
go

create view test_func_fixeddecimalint8_106 as select sys.fixeddecimalint8(cast(1.2 as fixeddecimal));
go

create view test_func_int4fixeddecimal_107 as select sys.int4fixeddecimal(cast(1 as int4));
go

create view test_func_fixeddecimalint4_108 as select sys.fixeddecimalint4(cast(1.2 as fixeddecimal));
go

create view test_func_int2fixeddecimal_109 as select sys.int2fixeddecimal(cast(1 as int2));
go

create view test_func_fixeddecimalint2_110 as select sys.fixeddecimalint2(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimaltod_111 as select sys.fixeddecimaltod(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimaltof_112 as select sys.fixeddecimaltof(cast(1.2 as fixeddecimal));
go

create view test_func_fixeddecimal_numeric_113 as select sys.fixeddecimal_numeric(cast(1.2 as fixeddecimal));
go

create view test_func_numeric_fixeddecimal_114 as select sys.numeric_fixeddecimal(cast(1.2 as numeric));
go

create view test_func_fixeddecimalum_115 as select sys.fixeddecimalum(cast(1 as smallmoney));
go

create view test_func_fixeddecimalpl_116 as select sys.fixeddecimalpl(cast(1 as smallmoney), cast(1 as smallmoney));
go

create view test_func_fixeddecimalmi_117 as select sys.fixeddecimalmi(cast(1 as smallmoney), cast(1 as smallmoney));
go

create view test_func_fixeddecimalmul_118 as select sys.fixeddecimalmul(cast(1 as smallmoney), cast(1 as smallmoney));
go

create view test_func_fixeddecimaldiv_119 as select sys.fixeddecimaldiv(cast(1 as smallmoney), cast(1 as smallmoney));
go

create view test_func_fixeddecimalint8pl_120 as select sys.fixeddecimalint8pl(cast(1 as smallmoney), cast(1 as int8));
go

create view test_func_fixeddecimalint8mi_121 as select sys.fixeddecimalint8mi(cast(1 as smallmoney), cast(1 as int8));
go

create view test_func_fixeddecimalint8mul_122 as select sys.fixeddecimalint8mul(cast(1 as smallmoney), cast(1 as int8));
go

create view test_func_fixeddecimalint8div_123 as select sys.fixeddecimalint8div(cast(1 as smallmoney), cast(1 as int8));
go

create view test_func_fixeddecimalint4pl_124 as select sys.fixeddecimalint4pl(cast(1 as smallmoney), cast(1 as int4));
go

create view test_func_fixeddecimalint4mi_125 as select sys.fixeddecimalint4mi(cast(1 as smallmoney), cast(1 as int4));
go

create view test_func_fixeddecimalint4mul_126 as select sys.fixeddecimalint4mul(cast(1 as smallmoney), cast(1 as int4));
go

create view test_func_fixeddecimalint4div_127 as select sys.fixeddecimalint4div(cast(1 as smallmoney), cast(1 as int4));
go

create view test_func_fixeddecimalint2pl_128 as select sys.fixeddecimalint2pl(cast(1 as smallmoney), cast(1 as int2));
go

create view test_func_fixeddecimalint2mi_129 as select sys.fixeddecimalint2mi(cast(1 as smallmoney), cast(1 as int2));
go

create view test_func_fixeddecimalint2mul_130 as select sys.fixeddecimalint2mul(cast(1 as smallmoney), cast(1 as int2));
go

create view test_func_fixeddecimalint2div_131 as select sys.fixeddecimalint2div(cast(1 as smallmoney), cast(1 as int2));
go

create view test_func_int8fixeddecimalpl_132 as select sys.int8fixeddecimalpl(cast(1 as int8), cast(1 as smallmoney));
go

create view test_func_int8fixeddecimalmi_133 as select sys.int8fixeddecimalmi(cast(1 as int8), cast(1 as smallmoney));
go

create view test_func_int8fixeddecimalmul_134 as select sys.int8fixeddecimalmul(cast(1 as int8), cast(1 as smallmoney));
go

create view test_func_int8fixeddecimaldiv_135 as select sys.int8fixeddecimaldiv(cast(1 as int8), cast(1 as smallmoney));
go

create view test_func_int8fixeddecimaldiv_smallmoney_136 as select sys.int8fixeddecimaldiv_smallmoney(cast(1 as int8), cast(1 as smallmoney));
go

create view test_func_int4fixeddecimalpl_137 as select sys.int4fixeddecimalpl(cast(1 as int4), cast(1 as smallmoney));
go

create view test_func_int4fixeddecimalmi_138 as select sys.int4fixeddecimalmi(cast(1 as int4), cast(1 as smallmoney));
go

create view test_func_int4fixeddecimalmul_139 as select sys.int4fixeddecimalmul(cast(1 as int4), cast(1 as smallmoney));
go

create view test_func_int4fixeddecimaldiv_140 as select sys.int4fixeddecimaldiv(cast(1 as int4), cast(1 as smallmoney));
go

create view test_func_int4fixeddecimaldiv_smallmoney_141 as select sys.int4fixeddecimaldiv_smallmoney(cast(1 as int4), cast(1 as smallmoney));
go

create view test_func_int2fixeddecimalpl_142 as select sys.int2fixeddecimalpl(cast(1 as int2), cast(1 as smallmoney));
go

create view test_func_int2fixeddecimalmi_143 as select sys.int2fixeddecimalmi(cast(1 as int2), cast(1 as smallmoney));
go

create view test_func_int2fixeddecimalmul_144 as select sys.int2fixeddecimalmul(cast(1 as int2), cast(1 as smallmoney));
go

create view test_func_int2fixeddecimaldiv_145 as select sys.int2fixeddecimaldiv(cast(1 as int2), cast(1 as smallmoney));
go

create view test_func_int2fixeddecimaldiv_smallmoney_146 as select sys.int2fixeddecimaldiv_smallmoney(cast(1 as int2), cast(1 as smallmoney));
go

create view test_func_smallmoneylarger_147 as select sys.smallmoneylarger(cast(1 as smallmoney), cast(1 as smallmoney));
go

create view test_func_smallmoneysmaller_148 as select sys.smallmoneysmaller(cast(1 as smallmoney), cast(1 as smallmoney));
go

create view test_func_bpcharout_149 as select sys.bpcharout(cast('a' as bpchar));
go

create view test_func_bpcharsend_150 as select sys.bpcharsend(cast('a' as bpchar));
go

create view test_func_bpchareq_151 as select sys.bpchareq(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_bpcharne_152 as select sys.bpcharne(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_bpcharlt_153 as select sys.bpcharlt(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_bpcharle_154 as select sys.bpcharle(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_bpchargt_155 as select sys.bpchargt(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_bpcharge_156 as select sys.bpcharge(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_bpchar_157 as select sys.bpchar(cast('a' as bpchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_bpchar2int2_158 as select sys.bpchar2int2(cast('a' as bpchar));
go

create view test_func_bpchar2int4_159 as select sys.bpchar2int4(cast('a' as bpchar));
go

create view test_func_bpchar2int8_160 as select sys.bpchar2int8(cast('a' as bpchar));
go

create view test_func_bpchar2float4_161 as select sys.bpchar2float4(cast('a' as bpchar));
go

create view test_func_bpchar2float8_162 as select sys.bpchar2float8(cast('a' as bpchar));
go

create view test_func_bpchareq_163 as select sys.bpchareq(cast('a' as bpchar), cast('abc' as text));
go

create view test_func_bpchareq_164 as select sys.bpchareq(cast('abc' as text), cast('a' as bpchar));
go

create view test_func_bpcharne_165 as select sys.bpcharne(cast('a' as bpchar), cast('abc' as text));
go

create view test_func_bpcharne_166 as select sys.bpcharne(cast('abc' as text), cast('a' as bpchar));
go

create view test_func_bpchar_larger_167 as select sys.bpchar_larger(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_bpchar_smaller_168 as select sys.bpchar_smaller(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_nchar_169 as select sys.nchar(cast('a' as nchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_nchar_larger_170 as select sys.nchar_larger(cast('a' as nchar), cast('a' as nchar));
go

create view test_func_nchar_smaller_171 as select sys.nchar_smaller(cast('a' as nchar), cast('a' as nchar));
go

create view test_func_varcharout_172 as select sys.varcharout(cast('abc' as varchar));
go

create view test_func_varcharsend_173 as select sys.varcharsend(cast('abc' as varchar));
go

create view test_func_varchareq_174 as select sys.varchareq(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_varcharne_175 as select sys.varcharne(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_varcharlt_176 as select sys.varcharlt(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_varcharle_177 as select sys.varcharle(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_varchargt_178 as select sys.varchargt(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_varcharge_179 as select sys.varcharge(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_varcharcmp_180 as select sys.varcharcmp(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_hashvarchar_181 as select sys.hashvarchar(cast('abc' as varchar));
go

create view test_func_varchar_182 as select sys.varchar(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_varchar2int2_183 as select sys.varchar2int2(cast('abc' as varchar));
go

create view test_func_varchar2int4_184 as select sys.varchar2int4(cast('abc' as varchar));
go

create view test_func_varchar2int8_185 as select sys.varchar2int8(cast('abc' as varchar));
go

create view test_func_varchar2float4_186 as select sys.varchar2float4(cast('abc' as varchar));
go

create view test_func_varchar2float8_187 as select sys.varchar2float8(cast('abc' as varchar));
go

create view test_func_varchar_larger_188 as select sys.varchar_larger(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_varchar_smaller_189 as select sys.varchar_smaller(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_nvarchar_190 as select sys.nvarchar(cast('abc' as nvarchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_nvarchar_larger_191 as select sys.nvarchar_larger(cast('abc' as nvarchar), cast('abc' as nvarchar));
go

create view test_func_nvarchar_smaller_192 as select sys.nvarchar_smaller(cast('abc' as nvarchar), cast('abc' as nvarchar));
go

create view test_func_decimal_193 as select sys.decimal(cast('a' as nchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_tinyintxor_194 as select sys.tinyintxor(cast(1 as tinyint), cast(1 as tinyint));
go

create view test_func_int2xor_195 as select sys.int2xor(cast(1 as int2), cast(1 as int2));
go

create view test_func_intxor_196 as select sys.intxor(cast(1 as int4), cast(1 as int4));
go

create view test_func_int8xor_197 as select sys.int8xor(cast(1 as int8), cast(1 as int8));
go

create view test_func_tinyint_larger_198 as select sys.tinyint_larger(cast(1 as tinyint), cast(1 as tinyint));
go

create view test_func_tinyint_smaller_199 as select sys.tinyint_smaller(cast(1 as tinyint), cast(1 as tinyint));
go

create view test_func_tinyintum_200 as select sys.tinyintum(cast(1 as tinyint));
go

create view test_func_tinyintpl_201 as select sys.tinyintpl(cast(1 as tinyint), cast(1 as tinyint));
go

create view test_func_tinyintmi_202 as select sys.tinyintmi(cast(1 as tinyint), cast(1 as tinyint));
go

create view test_func_tinyintmul_203 as select sys.tinyintmul(cast(1 as tinyint), cast(1 as tinyint));
go

create view test_func_tinyintdiv_204 as select sys.tinyintdiv(cast(1 as tinyint), cast(1 as tinyint));
go

create view test_func_smallmoneytinyintpl_205 as select sys.smallmoneytinyintpl(cast(1 as smallmoney), cast(1 as tinyint));
go

create view test_func_smallmoneytinyintmi_206 as select sys.smallmoneytinyintmi(cast(1 as smallmoney), cast(1 as tinyint));
go

create view test_func_smallmoneytinyintmul_207 as select sys.smallmoneytinyintmul(cast(1 as smallmoney), cast(1 as tinyint));
go

create view test_func_smallmoneytinyintdiv_208 as select sys.smallmoneytinyintdiv(cast(1 as smallmoney), cast(1 as tinyint));
go

create view test_func_tinyintsmallmoneypl_209 as select sys.tinyintsmallmoneypl(cast(1 as tinyint), cast(1 as smallmoney));
go

create view test_func_tinyintsmallmoneymi_210 as select sys.tinyintsmallmoneymi(cast(1 as tinyint), cast(1 as smallmoney));
go

create view test_func_tinyintsmallmoneymul_211 as select sys.tinyintsmallmoneymul(cast(1 as tinyint), cast(1 as smallmoney));
go

create view test_func_tinyintsmallmoneydiv_212 as select sys.tinyintsmallmoneydiv(cast(1 as tinyint), cast(1 as smallmoney));
go

create view test_func_real_larger_213 as select sys.real_larger(cast(1.2 as real), cast(1.2 as real));
go

create view test_func_real_smaller_214 as select sys.real_smaller(cast(1.2 as real), cast(1.2 as real));
go

create view test_func_bitout_215 as select sys.bitout(cast(1 as bit));
go

create view test_func_bitsend_216 as select sys.bitsend(cast(1 as bit));
go

create view test_func_int2bit_217 as select sys.int2bit(cast(1 as int2));
go

create view test_func_int4bit_218 as select sys.int4bit(cast(1 as int4));
go

create view test_func_int8bit_219 as select sys.int8bit(cast(1 as int8));
go

create view test_func_numeric_bit_220 as select sys.numeric_bit(cast(1.2 as numeric));
go

create view test_func_bit2int2_221 as select sys.bit2int2(cast(1 as bit));
go

create view test_func_bit2int4_222 as select sys.bit2int4(cast(1 as bit));
go

create view test_func_bit2int8_223 as select sys.bit2int8(cast(1 as bit));
go

create view test_func_bit2numeric_224 as select sys.bit2numeric(cast(1 as bit));
go

create view test_func_bit2fixeddec_225 as select sys.bit2fixeddec(cast(1 as bit));
go

create view test_func_bitneg_226 as select sys.bitneg(cast(1 as bit));
go

create view test_func_biteq_227 as select sys.biteq(cast(1 as bit), cast(1 as bit));
go

create view test_func_bitne_228 as select sys.bitne(cast(1 as bit), cast(1 as bit));
go

create view test_func_bitlt_229 as select sys.bitlt(cast(1 as bit), cast(1 as bit));
go

create view test_func_bitle_230 as select sys.bitle(cast(1 as bit), cast(1 as bit));
go

create view test_func_bitgt_231 as select sys.bitgt(cast(1 as bit), cast(1 as bit));
go

create view test_func_bitge_232 as select sys.bitge(cast(1 as bit), cast(1 as bit));
go

create view test_func_bit_cmp_233 as select sys.bit_cmp(cast(1 as bit), cast(1 as bit));
go

create view test_func_int4biteq_234 as select sys.int4biteq(cast(1 as int4), cast(1 as bit));
go

create view test_func_int4bitne_235 as select sys.int4bitne(cast(1 as int4), cast(1 as bit));
go

create view test_func_int4bitlt_236 as select sys.int4bitlt(cast(1 as int4), cast(1 as bit));
go

create view test_func_int4bitle_237 as select sys.int4bitle(cast(1 as int4), cast(1 as bit));
go

create view test_func_int4bitgt_238 as select sys.int4bitgt(cast(1 as int4), cast(1 as bit));
go

create view test_func_int4bitge_239 as select sys.int4bitge(cast(1 as int4), cast(1 as bit));
go

create view test_func_bitint4eq_240 as select sys.bitint4eq(cast(1 as bit), cast(1 as int4));
go

create view test_func_bitint4ne_241 as select sys.bitint4ne(cast(1 as bit), cast(1 as int4));
go

create view test_func_bitint4lt_242 as select sys.bitint4lt(cast(1 as bit), cast(1 as int4));
go

create view test_func_bitint4le_243 as select sys.bitint4le(cast(1 as bit), cast(1 as int4));
go

create view test_func_bitint4gt_244 as select sys.bitint4gt(cast(1 as bit), cast(1 as int4));
go

create view test_func_bitint4ge_245 as select sys.bitint4ge(cast(1 as bit), cast(1 as int4));
go

create view test_func_bitxor_246 as select sys.bitxor(cast(1 as bit), cast(1 as bit));
go

create view test_func_bit_unsupported_max_247 as select sys.bit_unsupported_max(cast(1 as bit), cast(1 as bit));
go

create view test_func_bit_unsupported_min_248 as select sys.bit_unsupported_min(cast(1 as bit), cast(1 as bit));
go

create view test_func_bit_unsupported_sum_249 as select sys.bit_unsupported_sum(cast(1 as bit), cast(1 as bit));
go

create view test_func_bit_unsupported_avg_250 as select sys.bit_unsupported_avg(cast(1 as bit), cast(1 as bit));
go

create view test_func_varbinaryout_251 as select sys.varbinaryout(cast(0xfe as bbf_varbinary));
go

create view test_func_varbinarysend_252 as select sys.varbinarysend(cast(0xfe as bbf_varbinary));
go

create view test_func_varbinarytypmodout_253 as select sys.varbinarytypmodout(cast(1 as int4));
go

create view test_func_bbfvarbinary_254 as select sys.bbfvarbinary(cast(0xfe as bbf_varbinary), cast(1 as int4), cast(1 as bool));
go

create view test_func_varbinarybytea_255 as select sys.varbinarybytea(cast(0xfe as bbf_varbinary), cast(1 as int4), cast(1 as bool));
go

create view test_func_varcharvarbinary_256 as select sys.varcharvarbinary(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_varcharvarbinary_257 as select sys.varcharvarbinary(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_bpcharvarbinary_258 as select sys.bpcharvarbinary(cast('a' as bpchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_bpcharvarbinary_259 as select sys.bpcharvarbinary(cast('a' as bpchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_varbinarysysvarchar_260 as select sys.varbinarysysvarchar(cast(0xfe as bbf_varbinary), cast(1 as int4), cast(1 as bool));
go

create view test_func_varbinaryvarchar_261 as select sys.varbinaryvarchar(cast(0xfe as bbf_varbinary), cast(1 as int4), cast(1 as bool));
go

create view test_func_int2varbinary_262 as select sys.int2varbinary(cast(1 as int2), cast(1 as int4), cast(1 as bool));
go

create view test_func_int4varbinary_263 as select sys.int4varbinary(cast(1 as int4), cast(1 as int4), cast(1 as bool));
go

create view test_func_int8varbinary_264 as select sys.int8varbinary(cast(1 as int8), cast(1 as int4), cast(1 as bool));
go

create view test_func_varbinaryint2_265 as select sys.varbinaryint2(cast(0xfe as bbf_varbinary));
go

create view test_func_varbinaryint4_266 as select sys.varbinaryint4(cast(0xfe as bbf_varbinary));
go

create view test_func_varbinaryint8_267 as select sys.varbinaryint8(cast(0xfe as bbf_varbinary));
go

create view test_func_varbinaryfloat4_268 as select sys.varbinaryfloat4(cast(0xfe as bbf_varbinary));
go

create view test_func_varbinaryfloat8_269 as select sys.varbinaryfloat8(cast(0xfe as bbf_varbinary));
go

create view test_func_varbinary_270 as select sys.varbinary(cast(0xfe as varbinary), cast(1 as int4), cast(1 as bool));
go

create view test_func_varbinary_eq_271 as select sys.varbinary_eq(cast(0xfe as bbf_varbinary), cast(0xfe as bbf_varbinary));
go

create view test_func_varbinary_neq_272 as select sys.varbinary_neq(cast(0xfe as bbf_varbinary), cast(0xfe as bbf_varbinary));
go

create view test_func_varbinary_gt_273 as select sys.varbinary_gt(cast(0xfe as bbf_varbinary), cast(0xfe as bbf_varbinary));
go

create view test_func_varbinary_geq_274 as select sys.varbinary_geq(cast(0xfe as bbf_varbinary), cast(0xfe as bbf_varbinary));
go

create view test_func_varbinary_lt_275 as select sys.varbinary_lt(cast(0xfe as bbf_varbinary), cast(0xfe as bbf_varbinary));
go

create view test_func_varbinary_leq_276 as select sys.varbinary_leq(cast(0xfe as bbf_varbinary), cast(0xfe as bbf_varbinary));
go

create view test_func_bbf_varbinary_cmp_277 as select sys.bbf_varbinary_cmp(cast(0xfe as bbf_varbinary), cast(0xfe as bbf_varbinary));
go

create view test_func_binaryout_278 as select sys.binaryout(cast(0xfe as bbf_binary));
go

create view test_func_binarysend_279 as select sys.binarysend(cast(0xfe as bbf_binary));
go

create view test_func_binarytypmodout_280 as select sys.binarytypmodout(cast(1 as int4));
go

create view test_func_varcharbinary_281 as select sys.varcharbinary(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_varcharbinary_282 as select sys.varcharbinary(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_bpcharbinary_283 as select sys.bpcharbinary(cast('a' as bpchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_bpcharbinary_284 as select sys.bpcharbinary(cast('a' as bpchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_binarysysvarchar_285 as select sys.binarysysvarchar(cast(0xfe as bbf_binary));
go

create view test_func_binaryvarchar_286 as select sys.binaryvarchar(cast(0xfe as bbf_binary));
go

create view test_func_int2binary_287 as select sys.int2binary(cast(1 as int2), cast(1 as int4), cast(1 as bool));
go

create view test_func_int4binary_288 as select sys.int4binary(cast(1 as int4), cast(1 as int4), cast(1 as bool));
go

create view test_func_int8binary_289 as select sys.int8binary(cast(1 as int8), cast(1 as int4), cast(1 as bool));
go

create view test_func_binaryint2_290 as select sys.binaryint2(cast(0xfe as bbf_binary));
go

create view test_func_binaryint4_291 as select sys.binaryint4(cast(0xfe as bbf_binary));
go

create view test_func_binaryint8_292 as select sys.binaryint8(cast(0xfe as bbf_binary));
go

create view test_func_binaryfloat4_293 as select sys.binaryfloat4(cast(0xfe as bbf_binary));
go

create view test_func_binaryfloat8_294 as select sys.binaryfloat8(cast(0xfe as bbf_binary));
go

create view test_func_binary_295 as select sys.binary(cast(0xfe as binary), cast(1 as int4), cast(1 as bool));
go

create view test_func_binary_eq_296 as select sys.binary_eq(cast(0xfe as bbf_binary), cast(0xfe as bbf_binary));
go

create view test_func_binary_neq_297 as select sys.binary_neq(cast(0xfe as bbf_binary), cast(0xfe as bbf_binary));
go

create view test_func_binary_gt_298 as select sys.binary_gt(cast(0xfe as bbf_binary), cast(0xfe as bbf_binary));
go

create view test_func_binary_geq_299 as select sys.binary_geq(cast(0xfe as bbf_binary), cast(0xfe as bbf_binary));
go

create view test_func_binary_lt_300 as select sys.binary_lt(cast(0xfe as bbf_binary), cast(0xfe as bbf_binary));
go

create view test_func_binary_leq_301 as select sys.binary_leq(cast(0xfe as bbf_binary), cast(0xfe as bbf_binary));
go

create view test_func_bbf_binary_cmp_302 as select sys.bbf_binary_cmp(cast(0xfe as bbf_binary), cast(0xfe as bbf_binary));
go

create view test_func_uniqueidentifierout_303 as select sys.uniqueidentifierout(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifiersend_304 as select sys.uniqueidentifiersend(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_newid_305 as select sys.newid();
go

create view test_func_newsequentialid_306 as select sys.newsequentialid();
go

create view test_func_uniqueidentifiereq_307 as select sys.uniqueidentifiereq(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifierne_308 as select sys.uniqueidentifierne(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifierlt_309 as select sys.uniqueidentifierlt(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifierle_310 as select sys.uniqueidentifierle(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifiergt_311 as select sys.uniqueidentifiergt(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifierge_312 as select sys.uniqueidentifierge(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifier_cmp_313 as select sys.uniqueidentifier_cmp(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_uniqueidentifier_hash_314 as select sys.uniqueidentifier_hash(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_varchar2uniqueidentifier_315 as select sys.varchar2uniqueidentifier(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_varchar2uniqueidentifier_316 as select sys.varchar2uniqueidentifier(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_varbinary2uniqueidentifier_317 as select sys.varbinary2uniqueidentifier(cast(0xfe as bbf_varbinary), cast(1 as int4), cast(1 as bool));
go

create view test_func_binary2uniqueidentifier_318 as select sys.binary2uniqueidentifier(cast(0xfe as bbf_binary), cast(1 as int4), cast(1 as bool));
go

create view test_func_uniqueidentifier2varbinary_319 as select sys.uniqueidentifier2varbinary(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), cast(1 as int4), cast(1 as bool));
go

create view test_func_uniqueidentifier2binary_320 as select sys.uniqueidentifier2binary(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier), cast(1 as int4), cast(1 as bool));
go

create view test_func_datetimeout_321 as select sys.datetimeout(cast('01-01-2022' as datetime));
go

create view test_func_datetimesend_322 as select sys.datetimesend(cast('01-01-2022' as datetime));
go

create view test_func_datetimetypmodout_323 as select sys.datetimetypmodout(cast(1 as int4));
go

create view test_func_datetimeeq_324 as select sys.datetimeeq(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetimene_325 as select sys.datetimene(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetimelt_326 as select sys.datetimelt(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetimele_327 as select sys.datetimele(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetimegt_328 as select sys.datetimegt(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetimege_329 as select sys.datetimege(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetime_larger_330 as select sys.datetime_larger(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetime_smaller_331 as select sys.datetime_smaller(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetimeplint4_332 as select sys.datetimeplint4(cast('01-01-2022' as datetime), cast(1 as int4));
go

create view test_func_int4pldatetime_333 as select sys.int4pldatetime(cast(1 as int4), cast('01-01-2022' as datetime));
go

create view test_func_datetimemiint4_334 as select sys.datetimemiint4(cast('01-01-2022' as datetime), cast(1 as int4));
go

create view test_func_int4midatetime_335 as select sys.int4midatetime(cast(1 as int4), cast('01-01-2022' as datetime));
go

create view test_func_datetime_cmp_336 as select sys.datetime_cmp(cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datetime_hash_337 as select sys.datetime_hash(cast('01-01-2022' as datetime));
go

create view test_func_timestamp2datetime_338 as select sys.timestamp2datetime(cast('01-01-2022' as timestamp));
go

create view test_func_date2datetime_339 as select sys.date2datetime(cast('01-01-2022' as date));
go

create view test_func_varchar2datetime_340 as select sys.varchar2datetime(cast('abc' as varchar));
go

create view test_func_varchar2datetime_341 as select sys.varchar2datetime(cast('abc' as varchar));
go

create view test_func_char2datetime_342 as select sys.char2datetime(cast('a' as bpchar));
go

create view test_func_bpchar2datetime_343 as select sys.bpchar2datetime(cast('a' as bpchar));
go

create view test_func_datetime2timestamptz_344 as select sys.datetime2timestamptz(cast('01-01-2022' as datetime));
go

create view test_func_datetime2date_345 as select sys.datetime2date(cast('01-01-2022' as datetime));
go

create view test_func_datetime2time_346 as select sys.datetime2time(cast('01-01-2022' as datetime));
go

create view test_func_datetime2sysvarchar_347 as select sys.datetime2sysvarchar(cast('01-01-2022' as datetime));
go

create view test_func_datetime2varchar_348 as select sys.datetime2varchar(cast('01-01-2022' as datetime));
go

create view test_func_datetime2char_349 as select sys.datetime2char(cast('01-01-2022' as datetime));
go

create view test_func_datetime2bpchar_350 as select sys.datetime2bpchar(cast('01-01-2022' as datetime));
go

create view test_func_datetime2out_351 as select sys.datetime2out(cast('01-01-2022' as datetime2));
go

create view test_func_datetime2send_352 as select sys.datetime2send(cast('01-01-2022' as datetime2));
go

create view test_func_datetime2typmodout_353 as select sys.datetime2typmodout(cast(1 as int4));
go

create view test_func_datetime2eq_354 as select sys.datetime2eq(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2ne_355 as select sys.datetime2ne(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2lt_356 as select sys.datetime2lt(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2le_357 as select sys.datetime2le(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2gt_358 as select sys.datetime2gt(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2ge_359 as select sys.datetime2ge(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2_cmp_360 as select sys.datetime2_cmp(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2_hash_361 as select sys.datetime2_hash(cast('01-01-2022' as datetime2));
go

create view test_func_datetime2_larger_362 as select sys.datetime2_larger(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datetime2_smaller_363 as select sys.datetime2_smaller(cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_timestamp2datetime2_364 as select sys.timestamp2datetime2(cast('01-01-2022' as timestamp));
go

create view test_func_date2datetime2_365 as select sys.date2datetime2(cast('01-01-2022' as date));
go

create view test_func_varchar2datetime2_366 as select sys.varchar2datetime2(cast('abc' as varchar));
go

create view test_func_varchar2datetime2_367 as select sys.varchar2datetime2(cast('abc' as varchar));
go

create view test_func_char2datetime2_368 as select sys.char2datetime2(cast('a' as bpchar));
go

create view test_func_bpchar2datetime2_369 as select sys.bpchar2datetime2(cast('a' as bpchar));
go

create view test_func_datetime22datetime_370 as select sys.datetime22datetime(cast('01-01-2022' as datetime2));
go

create view test_func_datetime22timestamptz_371 as select sys.datetime22timestamptz(cast('01-01-2022' as datetime2));
go

create view test_func_datetime22date_372 as select sys.datetime22date(cast('01-01-2022' as datetime2));
go

create view test_func_datetime22time_373 as select sys.datetime22time(cast('01-01-2022' as datetime2));
go

create view test_func_datetime2scale_374 as select sys.datetime2scale(cast('01-01-2022' as datetime2), cast(1 as int4));
go

create view test_func_datetime22sysvarchar_375 as select sys.datetime22sysvarchar(cast('01-01-2022' as datetime2));
go

create view test_func_datetime22varchar_376 as select sys.datetime22varchar(cast('01-01-2022' as datetime2));
go

create view test_func_datetime22char_377 as select sys.datetime22char(cast('01-01-2022' as datetime2));
go

create view test_func_datetime22bpchar_378 as select sys.datetime22bpchar(cast('01-01-2022' as datetime2));
go

create view test_func_smalldatetimeout_379 as select sys.smalldatetimeout(cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimesend_380 as select sys.smalldatetimesend(cast('01-01-2022' as smalldatetime));
go

create view test_func_smalltypmodout_381 as select sys.smalltypmodout(cast(1 as int4));
go

create view test_func_smalldatetimeeq_382 as select sys.smalldatetimeeq(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimene_383 as select sys.smalldatetimene(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimelt_384 as select sys.smalldatetimelt(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimele_385 as select sys.smalldatetimele(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimegt_386 as select sys.smalldatetimegt(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimege_387 as select sys.smalldatetimege(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime_larger_388 as select sys.smalldatetime_larger(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime_smaller_389 as select sys.smalldatetime_smaller(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime_eq_date_390 as select sys.smalldatetime_eq_date(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as date));
go

create view test_func_smalldatetime_ne_date_391 as select sys.smalldatetime_ne_date(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as date));
go

create view test_func_smalldatetime_lt_date_392 as select sys.smalldatetime_lt_date(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as date));
go

create view test_func_smalldatetime_le_date_393 as select sys.smalldatetime_le_date(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as date));
go

create view test_func_smalldatetime_gt_date_394 as select sys.smalldatetime_gt_date(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as date));
go

create view test_func_smalldatetime_ge_date_395 as select sys.smalldatetime_ge_date(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as date));
go

create view test_func_date_eq_smalldatetime_396 as select sys.date_eq_smalldatetime(cast('01-01-2022' as date), cast('01-01-2022' as smalldatetime));
go

create view test_func_date_ne_smalldatetime_397 as select sys.date_ne_smalldatetime(cast('01-01-2022' as date), cast('01-01-2022' as smalldatetime));
go

create view test_func_date_lt_smalldatetime_398 as select sys.date_lt_smalldatetime(cast('01-01-2022' as date), cast('01-01-2022' as smalldatetime));
go

create view test_func_date_le_smalldatetime_399 as select sys.date_le_smalldatetime(cast('01-01-2022' as date), cast('01-01-2022' as smalldatetime));
go

create view test_func_date_gt_smalldatetime_400 as select sys.date_gt_smalldatetime(cast('01-01-2022' as date), cast('01-01-2022' as smalldatetime));
go

create view test_func_date_ge_smalldatetime_401 as select sys.date_ge_smalldatetime(cast('01-01-2022' as date), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimeplint4_402 as select sys.smalldatetimeplint4(cast('01-01-2022' as smalldatetime), cast(1 as int4));
go

create view test_func_int4plsmalldatetime_403 as select sys.int4plsmalldatetime(cast(1 as int4), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetimemiint4_404 as select sys.smalldatetimemiint4(cast('01-01-2022' as smalldatetime), cast(1 as int4));
go

create view test_func_int4mismalldatetime_405 as select sys.int4mismalldatetime(cast(1 as int4), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime_cmp_406 as select sys.smalldatetime_cmp(cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime_hash_407 as select sys.smalldatetime_hash(cast('01-01-2022' as smalldatetime));
go

create view test_func_timestamp2smalldatetime_408 as select sys.timestamp2smalldatetime(cast('01-01-2022' as timestamp));
go

create view test_func_datetime2smalldatetime_409 as select sys.datetime2smalldatetime(cast('01-01-2022' as datetime));
go

create view test_func_datetime22smalldatetime_410 as select sys.datetime22smalldatetime(cast('01-01-2022' as datetime2));
go

create view test_func_date2smalldatetime_411 as select sys.date2smalldatetime(cast('01-01-2022' as date));
go

create view test_func_smalldatetime2date_412 as select sys.smalldatetime2date(cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime2timestamptz_413 as select sys.smalldatetime2timestamptz(cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime2time_414 as select sys.smalldatetime2time(cast('01-01-2022' as smalldatetime));
go

create view test_func_varchar2smalldatetime_415 as select sys.varchar2smalldatetime(cast('abc' as varchar));
go

create view test_func_varchar2smalldatetime_416 as select sys.varchar2smalldatetime(cast('abc' as varchar));
go

create view test_func_char2smalldatetime_417 as select sys.char2smalldatetime(cast('a' as bpchar));
go

create view test_func_bpchar2smalldatetime_418 as select sys.bpchar2smalldatetime(cast('a' as bpchar));
go

create view test_func_smalldatetime2sysvarchar_419 as select sys.smalldatetime2sysvarchar(cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime2varchar_420 as select sys.smalldatetime2varchar(cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime2char_421 as select sys.smalldatetime2char(cast('01-01-2022' as smalldatetime));
go

create view test_func_smalldatetime2bpchar_422 as select sys.smalldatetime2bpchar(cast('01-01-2022' as smalldatetime));
go

create view test_func_datetimeoffsetout_423 as select sys.datetimeoffsetout(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetsend_424 as select sys.datetimeoffsetsend(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeofftypmodout_425 as select sys.datetimeofftypmodout(cast(1 as int4));
go

create view test_func_datetimeoffseteq_426 as select sys.datetimeoffseteq(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetne_427 as select sys.datetimeoffsetne(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetlt_428 as select sys.datetimeoffsetlt(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetle_429 as select sys.datetimeoffsetle(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetgt_430 as select sys.datetimeoffsetgt(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetge_431 as select sys.datetimeoffsetge(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetmi_432 as select sys.datetimeoffsetmi(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffset_cmp_433 as select sys.datetimeoffset_cmp(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffset_hash_434 as select sys.datetimeoffset_hash(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffset_larger_435 as select sys.datetimeoffset_larger(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffset_smaller_436 as select sys.datetimeoffset_smaller(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffsetscale_437 as select sys.datetimeoffsetscale(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast(1 as int4));
go

create view test_func_timestamp2datetimeoffset_438 as select sys.timestamp2datetimeoffset(cast('01-01-2022' as timestamp));
go

create view test_func_datetimeoffset2timestamp_439 as select sys.datetimeoffset2timestamp(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_date2datetimeoffset_440 as select sys.date2datetimeoffset(cast('01-01-2022' as date));
go

create view test_func_datetimeoffset2date_441 as select sys.datetimeoffset2date(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetimeoffset2time_442 as select sys.datetimeoffset2time(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_smalldatetime2datetimeoffset_443 as select sys.smalldatetime2datetimeoffset(cast('01-01-2022' as smalldatetime));
go

create view test_func_datetimeoffset2smalldatetime_444 as select sys.datetimeoffset2smalldatetime(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetime2datetimeoffset_445 as select sys.datetime2datetimeoffset(cast('01-01-2022' as datetime));
go

create view test_func_datetimeoffset2datetime_446 as select sys.datetimeoffset2datetime(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datetime22datetimeoffset_447 as select sys.datetime22datetimeoffset(cast('01-01-2022' as datetime2));
go

create view test_func_datetimeoffset2datetime2_448 as select sys.datetimeoffset2datetime2(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_sqlvariantout_449 as select sys.sqlvariantout('abc');
go

create view test_func_sqlvariantsend_450 as select sys.sqlvariantsend('abc');
go

create view test_func_datalength_451 as select sys.datalength('abc');
go

create view test_func_datetime_sqlvariant_452 as select sys.datetime_sqlvariant(cast('01-01-2022' as datetime));
go

create view test_func_datetime2_sqlvariant_453 as select sys.datetime2_sqlvariant(cast('01-01-2022' as datetime2));
go

create view test_func_datetimeoffset_sqlvariant_454 as select sys.datetimeoffset_sqlvariant(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_smalldatetime_sqlvariant_455 as select sys.smalldatetime_sqlvariant(cast('01-01-2022' as smalldatetime));
go

create view test_func_date_sqlvariant_456 as select sys.date_sqlvariant(cast('01-01-2022' as date));
go

create view test_func_numeric_sqlvariant_457 as select sys.numeric_sqlvariant(cast(1.2 as numeric));
go

create view test_func_money_sqlvariant_458 as select sys.money_sqlvariant(cast(1.2 as fixeddecimal));
go

create view test_func_money_sqlvariant_459 as select sys.money_sqlvariant(cast(1 as money));
go

create view test_func_smallmoney_sqlvariant_460 as select sys.smallmoney_sqlvariant(cast(1 as smallmoney));
go

create view test_func_bigint_sqlvariant_461 as select sys.bigint_sqlvariant(cast(1 as int8));
go

create view test_func_int_sqlvariant_462 as select sys.int_sqlvariant(cast(1 as int4));
go

create view test_func_smallint_sqlvariant_463 as select sys.smallint_sqlvariant(cast(1 as int2));
go

create view test_func_tinyint_sqlvariant_464 as select sys.tinyint_sqlvariant(cast(1 as tinyint));
go

create view test_func_bit_sqlvariant_465 as select sys.bit_sqlvariant(cast(1 as bit));
go

create view test_func_varchar_sqlvariant_466 as select sys.varchar_sqlvariant(cast('abc' as varchar));
go

create view test_func_nvarchar_sqlvariant_467 as select sys.nvarchar_sqlvariant(cast('abc' as nvarchar));
go

create view test_func_varchar_sqlvariant_468 as select sys.varchar_sqlvariant(cast('abc' as varchar));
go

create view test_func_char_sqlvariant_469 as select sys.char_sqlvariant(cast('a' as bpchar));
go

create view test_func_nchar_sqlvariant_470 as select sys.nchar_sqlvariant(cast('a' as nchar));
go

create view test_func_char_sqlvariant_471 as select sys.char_sqlvariant(cast('a' as bpchar));
go

create view test_func_bbfvarbinary_sqlvariant_472 as select sys.bbfvarbinary_sqlvariant(cast(0xfe as bbf_varbinary));
go

create view test_func_bbfbinary_sqlvariant_473 as select sys.bbfbinary_sqlvariant(cast(0xfe as bbf_binary));
go

create view test_func_uniqueidentifier_sqlvariant_474 as select sys.uniqueidentifier_sqlvariant(CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
go

create view test_func_sqlvariant_datetime_475 as select sys.sqlvariant_datetime('abc');
go

create view test_func_sqlvariant_datetime2_476 as select sys.sqlvariant_datetime2('abc');
go

create view test_func_sqlvariant_datetimeoffset_477 as select sys.sqlvariant_datetimeoffset('abc');
go

create view test_func_sqlvariant_smalldatetime_478 as select sys.sqlvariant_smalldatetime('abc');
go

create view test_func_sqlvariant_date_479 as select sys.sqlvariant_date('abc');
go

create view test_func_sqlvariant_time_480 as select sys.sqlvariant_time('abc');
go

create view test_func_sqlvariant_float_481 as select sys.sqlvariant_float('abc');
go

create view test_func_sqlvariant_real_482 as select sys.sqlvariant_real('abc');
go

create view test_func_sqlvariant_numeric_483 as select sys.sqlvariant_numeric('abc');
go

create view test_func_sqlvariant_money_484 as select sys.sqlvariant_money('abc');
go

create view test_func_sqlvariant_smallmoney_485 as select sys.sqlvariant_smallmoney('abc');
go

create view test_func_sqlvariant_bigint_486 as select sys.sqlvariant_bigint('abc');
go

create view test_func_sqlvariant_int_487 as select sys.sqlvariant_int('abc');
go

create view test_func_sqlvariant_smallint_488 as select sys.sqlvariant_smallint('abc');
go

create view test_func_sqlvariant_tinyint_489 as select sys.sqlvariant_tinyint('abc');
go

create view test_func_sqlvariant_bit_490 as select sys.sqlvariant_bit('abc');
go

create view test_func_sqlvariant_sysvarchar_491 as select sys.sqlvariant_sysvarchar('abc');
go

create view test_func_sqlvariant_varchar_492 as select sys.sqlvariant_varchar('abc');
go

create view test_func_sqlvariant_nvarchar_493 as select sys.sqlvariant_nvarchar('abc');
go

create view test_func_sqlvariant_char_494 as select sys.sqlvariant_char('abc');
go

create view test_func_sqlvariant_nchar_495 as select sys.sqlvariant_nchar('abc');
go

create view test_func_sqlvariant_bbfvarbinary_496 as select sys.sqlvariant_bbfvarbinary('abc');
go

create view test_func_sqlvariant_bbfbinary_497 as select sys.sqlvariant_bbfbinary('abc');
go

create view test_func_sqlvariant_uniqueidentifier_498 as select sys.sqlvariant_uniqueidentifier('abc');
go

create view test_func_sql_variant_property_499 as select sys.sql_variant_property('abc', cast('abc' as varchar));
go

create view test_func_sqlvarianteq_500 as select sys.sqlvarianteq('abc', 'abc');
go

create view test_func_sqlvariantne_501 as select sys.sqlvariantne('abc', 'abc');
go

create view test_func_sqlvariantlt_502 as select sys.sqlvariantlt('abc', 'abc');
go

create view test_func_sqlvariantle_503 as select sys.sqlvariantle('abc', 'abc');
go

create view test_func_sqlvariantgt_504 as select sys.sqlvariantgt('abc', 'abc');
go

create view test_func_sqlvariantge_505 as select sys.sqlvariantge('abc', 'abc');
go

create view test_func_sqlvariant_cmp_506 as select sys.sqlvariant_cmp('abc', 'abc');
go

create view test_func_sqlvariant_hash_507 as select sys.sqlvariant_hash('abc');
go

create view test_func_babelfish_concat_wrapper_508 as select sys.babelfish_concat_wrapper(cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_concat_wrapper_outer_509 as select sys.babelfish_concat_wrapper_outer(cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_concat_wrapper_510 as select sys.babelfish_concat_wrapper(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_babelfish_concat_wrapper_511 as select sys.babelfish_concat_wrapper(cast('abc' as nvarchar), cast('abc' as nvarchar));
go

create view test_func_babelfish_concat_wrapper_512 as select sys.babelfish_concat_wrapper(cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_babelfish_concat_wrapper_513 as select sys.babelfish_concat_wrapper(cast('a' as nchar), cast('a' as nchar));
go

create view test_func_babelfish_concat_wrapper_514 as select sys.babelfish_concat_wrapper(cast('abc' as varchar), cast('abc' as nvarchar));
go

create view test_func_babelfish_concat_wrapper_515 as select sys.babelfish_concat_wrapper(cast('abc' as nvarchar), cast('abc' as varchar));
go

create view test_func_char_516 as select sys.char(cast(1 as int4));
go

create view test_func_nchar_517 as select sys.nchar(cast(1 as int4));
go

create view test_func_nchar_518 as select sys.nchar(cast(0xfe as varbinary));
go

create view test_func__round_fixeddecimal_to_int8_519 as select sys._round_fixeddecimal_to_int8(cast(1.2 as fixeddecimal));
go

create view test_func__round_fixeddecimal_to_int4_520 as select sys._round_fixeddecimal_to_int4(cast(1.2 as fixeddecimal));
go

create view test_func__round_fixeddecimal_to_int2_521 as select sys._round_fixeddecimal_to_int2(cast(1.2 as fixeddecimal));
go

create view test_func__trunc_numeric_to_int8_522 as select sys._trunc_numeric_to_int8(cast(1.2 as numeric));
go

create view test_func__trunc_numeric_to_int4_523 as select sys._trunc_numeric_to_int4(cast(1.2 as numeric));
go

create view test_func__trunc_numeric_to_int2_524 as select sys._trunc_numeric_to_int2(cast(1.2 as numeric));
go

create view test_func_char_to_fixeddecimal_525 as select sys.char_to_fixeddecimal(cast('abc' as text));
go

create view test_func_char_to_fixeddecimal_526 as select sys.char_to_fixeddecimal(cast('a' as bpchar));
go

create view test_func_char_to_fixeddecimal_527 as select sys.char_to_fixeddecimal(cast('a' as bpchar));
go

create view test_func_char_to_fixeddecimal_528 as select sys.char_to_fixeddecimal(cast('abc' as varchar));
go

create view test_func_char_to_fixeddecimal_529 as select sys.char_to_fixeddecimal(cast('abc' as varchar));
go

create view test_func_text_to_name_530 as select sys.text_to_name(cast('abc' as text));
go

create view test_func_bpchar_to_name_531 as select sys.bpchar_to_name(cast('a' as bpchar));
go

create view test_func_bpchar_to_name_532 as select sys.bpchar_to_name(cast('a' as bpchar));
go

create view test_func_varchar_to_name_533 as select sys.varchar_to_name(cast('abc' as varchar));
go

create view test_func_varchar_to_name_534 as select sys.varchar_to_name(cast('abc' as varchar));
go

create view test_func_rowversionout_535 as select sys.rowversionout(cast(0xfe as rowversion));
go

create view test_func_rowversionsend_536 as select sys.rowversionsend(cast(0xfe as rowversion));
go

create view test_func_binaryrowversion_537 as select sys.binaryrowversion(cast(0xfe as bbf_binary), cast(1 as int4), cast(1 as bool));
go

create view test_func_varbinaryrowversion_538 as select sys.varbinaryrowversion(cast(0xfe as bbf_varbinary), cast(1 as int4), cast(1 as bool));
go

create view test_func_rowversionbinary_539 as select sys.rowversionbinary(cast(0xfe as rowversion), cast(1 as int4), cast(1 as bool));
go

create view test_func_rowversionvarbinary_540 as select sys.rowversionvarbinary(cast(0xfe as rowversion), cast(1 as int4), cast(1 as bool));
go

create view test_func_varcharrowversion_541 as select sys.varcharrowversion(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_varcharrowversion_542 as select sys.varcharrowversion(cast('abc' as varchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_bpcharrowversion_543 as select sys.bpcharrowversion(cast('a' as bpchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_bpcharrowversion_544 as select sys.bpcharrowversion(cast('a' as bpchar), cast(1 as int4), cast(1 as bool));
go

create view test_func_rowversionsysvarchar_545 as select sys.rowversionsysvarchar(cast(0xfe as rowversion));
go

create view test_func_rowversionvarchar_546 as select sys.rowversionvarchar(cast(0xfe as rowversion));
go

create view test_func_int2rowversion_547 as select sys.int2rowversion(cast(1 as int2), cast(1 as int4), cast(1 as bool));
go

create view test_func_int4rowversion_548 as select sys.int4rowversion(cast(1 as int4), cast(1 as int4), cast(1 as bool));
go

create view test_func_int8rowversion_549 as select sys.int8rowversion(cast(1 as int8), cast(1 as int4), cast(1 as bool));
go

create view test_func_rowversionint2_550 as select sys.rowversionint2(cast(0xfe as rowversion));
go

create view test_func_rowversionint4_551 as select sys.rowversionint4(cast(0xfe as rowversion));
go

create view test_func_rowversionint8_552 as select sys.rowversionint8(cast(0xfe as rowversion));
go

create view test_func_rowversion_eq_553 as select sys.rowversion_eq(cast(0xfe as rowversion), cast(0xfe as rowversion));
go

create view test_func_rowversion_neq_554 as select sys.rowversion_neq(cast(0xfe as rowversion), cast(0xfe as rowversion));
go

create view test_func_rowversion_gt_555 as select sys.rowversion_gt(cast(0xfe as rowversion), cast(0xfe as rowversion));
go

create view test_func_rowversion_geq_556 as select sys.rowversion_geq(cast(0xfe as rowversion), cast(0xfe as rowversion));
go

create view test_func_rowversion_lt_557 as select sys.rowversion_lt(cast(0xfe as rowversion), cast(0xfe as rowversion));
go

create view test_func_rowversion_leq_558 as select sys.rowversion_leq(cast(0xfe as rowversion), cast(0xfe as rowversion));
go

create view test_func_rowversion_cmp_559 as select sys.rowversion_cmp(cast(0xfe as rowversion), cast(0xfe as rowversion));
go

create view test_func_babelfish_typecode_list_560 as select * from sys.babelfish_typecode_list();
go

create view test_func_fn_helpcollations_561 as select * from sys.fn_helpcollations();
go

create view test_func_hashbytes_562 as select sys.hashbytes(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_hashbytes_563 as select sys.hashbytes(cast('abc' as varchar), cast(0xfe as bbf_varbinary));
go

create view test_func_quotename_564 as select sys.quotename(cast('abc' as varchar), cast('a' as bpchar));
go

create view test_func_unicode_565 as select sys.unicode(cast('abc' as varchar));
go

create view test_func_string_split_566 as select * from sys.string_split(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_string_escape_567 as select sys.string_escape(cast('abc' as nvarchar), cast('abc' as text));
go

create view test_func_formatmessage_568 as select sys.formatmessage(cast('abc' as text));
go

create view test_func_formatmessage_569 as select sys.formatmessage(cast('abc' as varchar));
go

create view test_func_sysdatetime_570 as select sys.sysdatetime();
go

create view test_func_sysdatetimeoffset_571 as select sys.sysdatetimeoffset();
go

create view test_func_sysutcdatetime_572 as select sys.sysutcdatetime();
go

create view test_func_getdate_573 as select sys.getdate();
go

create view test_func_isnull_574 as select sys.isnull(cast('abc' as text), cast('abc' as text));
go

create view test_func_isnull_575 as select sys.isnull(cast(1 as bool), cast(1 as bool));
go

create view test_func_isnull_576 as select sys.isnull(cast(1 as int2), cast(1 as int2));
go

create view test_func_isnull_577 as select sys.isnull(cast(1 as int4), cast(1 as int4));
go

create view test_func_isnull_578 as select sys.isnull(cast(1 as int8), cast(1 as int8));
go

create view test_func_isnull_579 as select sys.isnull(cast(1.2 as numeric), cast(1.2 as numeric));
go

create view test_func_isnull_580 as select sys.isnull(cast('01-01-2022' as date), cast('01-01-2022' as date));
go

create view test_func_isnull_581 as select sys.isnull(cast('01-01-2022' as timestamp), cast('01-01-2022' as timestamp));
go

create view test_func_babelfish_get_last_identity_582 as select sys.babelfish_get_last_identity();
go

create view test_func_bbf_get_current_physical_schema_name_583 as select sys.bbf_get_current_physical_schema_name(cast('abc' as text));
go

create view test_func_babelfish_set_role_584 as select sys.babelfish_set_role(cast('abc' as text));
go

create view test_func_babelfish_get_last_identity_numeric_585 as select sys.babelfish_get_last_identity_numeric();
go

create view test_func_get_min_id_from_table_586 as select sys.get_min_id_from_table(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_get_max_id_from_table_587 as select sys.get_max_id_from_table(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_user_name_sysname_588 as select sys.user_name_sysname();
go

create view test_func_babelfish_get_identity_param_589 as select sys.babelfish_get_identity_param(cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_get_identity_current_590 as select sys.babelfish_get_identity_current(cast('abc' as text));
go

create view test_func_babelfish_get_id_by_name_591 as select sys.babelfish_get_id_by_name(cast('abc' as text));
go

create view test_func_babelfish_get_sequence_value_592 as select sys.babelfish_get_sequence_value(cast('abc' as varchar));
go

create view test_func_babelfish_get_login_default_db_593 as select sys.babelfish_get_login_default_db(cast('abc' as text));
go

create view test_func_babelfish_conv_date_to_string_594 as select sys.babelfish_conv_date_to_string(cast('abc' as text), cast('01-01-2022' as date), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_datetime_to_string_595 as select sys.babelfish_conv_datetime_to_string(cast('abc' as text), cast('abc' as text), cast('01-01-2022' as timestamp), cast(1.2 as numeric));
go

create view test_func_sign_596 as select sys.sign(cast('abc' as text));
go

create view test_func_babelfish_conv_greg_to_hijri_597 as select sys.babelfish_conv_greg_to_hijri(cast('01-01-2022' as date));
go

create view test_func_babelfish_conv_greg_to_hijri_598 as select sys.babelfish_conv_greg_to_hijri(cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_greg_to_hijri_599 as select sys.babelfish_conv_greg_to_hijri(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_conv_greg_to_hijri_600 as select sys.babelfish_conv_greg_to_hijri(cast('01-01-2022' as timestamp));
go

create view test_func_babelfish_conv_hijri_to_greg_601 as select sys.babelfish_conv_hijri_to_greg(cast('01-01-2022' as date));
go

create view test_func_babelfish_conv_hijri_to_greg_602 as select sys.babelfish_conv_hijri_to_greg(cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_hijri_to_greg_603 as select sys.babelfish_conv_hijri_to_greg(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_conv_hijri_to_greg_604 as select sys.babelfish_conv_hijri_to_greg(cast('01-01-2022' as timestamp));
go

create view test_func_babelfish_conv_string_to_date_605 as select sys.babelfish_conv_string_to_date(cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_string_to_datetime_606 as select sys.babelfish_conv_string_to_datetime(cast('abc' as text), cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_string_to_time_607 as select sys.babelfish_conv_string_to_time(cast('abc' as text), cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_dbts_608 as select sys.babelfish_dbts();
go

create view test_func_babelfish_get_full_year_609 as select sys.babelfish_get_full_year(cast('abc' as text), cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_get_jobs_610 as select * from sys.babelfish_get_jobs();
go

create view test_func_babelfish_get_lang_metadata_json_611 as select sys.babelfish_get_lang_metadata_json(cast('abc' as text));
go

create view test_func_babelfish_get_microsecs_from_fractsecs_612 as select sys.babelfish_get_microsecs_from_fractsecs(cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_parse_to_date_613 as select sys.babelfish_parse_to_date(cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_parse_to_datetime_614 as select sys.babelfish_parse_to_datetime(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_parse_to_time_615 as select sys.babelfish_parse_to_time(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_get_service_setting_616 as select sys.babelfish_get_service_setting(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_babelfish_get_timeunit_from_string_617 as select sys.babelfish_get_timeunit_from_string(cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_get_version_618 as select sys.babelfish_get_version(cast('abc' as varchar));
go

create view test_func_babelfish_is_ossp_present_619 as select sys.babelfish_is_ossp_present();
go

create view test_func_babelfish_is_spatial_present_620 as select sys.babelfish_is_spatial_present();
go

create view test_func_babelfish_istime_621 as select sys.babelfish_istime(cast('abc' as text));
go

create view test_func_babelfish_single_unbracket_name_622 as select sys.babelfish_single_unbracket_name(cast('abc' as text));
go

create view test_func_babelfish_openxml_623 as select * from sys.babelfish_openxml(cast(1 as int8));
go

create view test_func_babelfish_round3_624 as select sys.babelfish_round3(cast(1.2 as numeric), cast(1 as int4), cast(1 as int4));
go

create view test_func_babelfish_round_fractseconds_625 as select sys.babelfish_round_fractseconds(cast(1.2 as numeric));
go

create view test_func_babelfish_round_fractseconds_626 as select sys.babelfish_round_fractseconds(cast('abc' as text));
go

create view test_func_babelfish_set_version_627 as select sys.babelfish_set_version(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_babelfish_sp_add_job_628 as select sys.babelfish_sp_add_job(cast('abc' as varchar), cast(1 as int2), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_sp_add_jobschedule_629 as select sys.babelfish_sp_add_jobschedule(cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int2), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int2), cast('a' as bpchar));
go

create view test_func_babelfish_sp_add_jobstep_630 as select sys.babelfish_sp_add_jobstep(cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as text), cast('abc' as text), cast(1 as int4), cast(1 as int2), cast(1 as int4), cast(1 as int2), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast('a' as bpchar));
go

create view test_func_babelfish_sp_add_schedule_631 as select sys.babelfish_sp_add_schedule(cast('abc' as varchar), cast(1 as int2), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast('a' as bpchar), cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_sp_attach_schedule_632 as select sys.babelfish_sp_attach_schedule(cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast(1 as int2));
go

create view test_func_babelfish_sp_aws_add_jobschedule_633 as select sys.babelfish_sp_aws_add_jobschedule(cast(1 as int4), cast(1 as int4));
go

create view test_func_babelfish_sp_aws_del_jobschedule_634 as select sys.babelfish_sp_aws_del_jobschedule(cast(1 as int4), cast(1 as int4));
go

create view test_func_babelfish_try_conv_datetime_to_string_635 as select sys.babelfish_try_conv_datetime_to_string(cast('abc' as text), cast('abc' as text), cast('01-01-2022' as timestamp), cast(1.2 as numeric));
go

create view test_func_babelfish_sp_delete_job_636 as select sys.babelfish_sp_delete_job(cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int2), cast(1 as int2));
go

create view test_func_babelfish_sp_delete_jobschedule_637 as select sys.babelfish_sp_delete_jobschedule(cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast(1 as int2));
go

create view test_func_babelfish_sp_delete_jobstep_638 as select sys.babelfish_sp_delete_jobstep(cast(1 as int4), cast('abc' as varchar), cast(1 as int4));
go

create view test_func_babelfish_sp_delete_schedule_639 as select sys.babelfish_sp_delete_schedule(cast(1 as int4), cast('abc' as varchar), cast(1 as int2), cast(1 as int2));
go

create view test_func_babelfish_try_conv_string_to_date_640 as select sys.babelfish_try_conv_string_to_date(cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_sp_detach_schedule_641 as select sys.babelfish_sp_detach_schedule(cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast(1 as int2), cast(1 as int2));
go

create view test_func_babelfish_sp_job_log_642 as select sys.babelfish_sp_job_log(cast(1 as int4), cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_sp_schedule_to_cron_643 as select sys.babelfish_sp_schedule_to_cron(cast(1 as int4), cast(1 as int4));
go

create view test_func_babelfish_sp_sequence_get_range_644 as select sys.babelfish_sp_sequence_get_range(cast('abc' as text), cast(1 as int8));
go

create view test_func_babelfish_sp_set_next_run_645 as select sys.babelfish_sp_set_next_run(cast(1 as int4), cast(1 as int4));
go

create view test_func_babelfish_sp_update_job_646 as select sys.babelfish_sp_update_job(cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int2), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast(1 as int2));
go

create view test_func_babelfish_sp_update_jobschedule_647 as select sys.babelfish_sp_update_jobschedule(cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int2), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int2));
go

create view test_func_babelfish_try_conv_string_to_datetime_648 as select sys.babelfish_try_conv_string_to_datetime(cast('abc' as text), cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_sp_update_jobstep_649 as select sys.babelfish_sp_update_jobstep(cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as text), cast('abc' as text), cast(1 as int4), cast(1 as int2), cast(1 as int4), cast(1 as int2), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_sp_update_schedule_650 as select sys.babelfish_sp_update_schedule(cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int2), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast(1 as int2));
go

create view test_func_babelfish_sp_verify_job_651 as select sys.babelfish_sp_verify_job(cast(1 as int4), cast('abc' as varchar), cast(1 as int2), cast(1 as int4), cast('abc' as varchar), cast('a' as bpchar), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_sp_verify_job_date_652 as select sys.babelfish_sp_verify_job_date(cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_sp_verify_job_identifiers_653 as select sys.babelfish_sp_verify_job_identifiers(cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar), cast('a' as bpchar));
go

create view test_func_babelfish_sp_verify_job_time_654 as select sys.babelfish_sp_verify_job_time(cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_conv_to_varchar_655 as select sys.babelfish_conv_to_varchar(cast('abc' as text), cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_sp_verify_jobstep_656 as select sys.babelfish_sp_verify_jobstep(cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as text), cast('abc' as varchar), cast(1 as int2), cast(1 as int4), cast(1 as int2), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('abc' as varchar), cast(1 as int4));
go

create view test_func_babelfish_sp_verify_schedule_657 as select sys.babelfish_sp_verify_schedule(cast(1 as int4), cast('abc' as varchar), cast(1 as int2), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast(1 as int4), cast('a' as bpchar));
go

create view test_func_babelfish_sp_verify_schedule_identifiers_658 as select sys.babelfish_sp_verify_schedule_identifiers(cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast('a' as bpchar), cast(1 as int4), cast(1 as int4));
go

create view test_func_babelfish_sp_xml_preparedocument_659 as select sys.babelfish_sp_xml_preparedocument(cast('abc' as text));
go

create view test_func_babelfish_sp_xml_removedocument_660 as select sys.babelfish_sp_xml_removedocument(cast(1 as int8));
go

create view test_func_babelfish_strpos3_661 as select sys.babelfish_strpos3(cast('abc' as text), cast('abc' as text), cast(1 as int4));
go

create view test_func_babelfish_tomsbit_662 as select sys.babelfish_tomsbit(cast(1.2 as numeric));
go

create view test_func_babelfish_tomsbit_663 as select sys.babelfish_tomsbit(cast('abc' as varchar));
go

create view test_func_babelfish_try_conv_date_to_string_664 as select sys.babelfish_try_conv_date_to_string(cast('abc' as text), cast('01-01-2022' as date), cast(1.2 as numeric));
go

create view test_func_user_id_665 as select sys.user_id(cast('abc' as text));
go

create view test_func_babelfish_try_conv_string_to_time_666 as select sys.babelfish_try_conv_string_to_time(cast('abc' as text), cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_helper_to_date_667 as select sys.babelfish_conv_helper_to_date(cast('abc' as text), cast(1 as bool), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_helper_to_time_668 as select sys.babelfish_conv_helper_to_time(cast('abc' as text), cast(1 as bool), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_helper_to_datetime_669 as select sys.babelfish_conv_helper_to_datetime(cast('abc' as text), cast(1 as bool), cast(1.2 as numeric));
go

create view test_func_babelfish_conv_helper_to_varchar_670 as select sys.babelfish_conv_helper_to_varchar(cast('abc' as text), cast('abc' as text), cast(1 as bool), cast(1.2 as numeric));
go

create view test_func_babelfish_try_conv_to_varchar_671 as select sys.babelfish_try_conv_to_varchar(cast('abc' as text), cast('abc' as text), cast(1.2 as numeric));
go

create view test_func_babelfish_parse_helper_to_date_672 as select sys.babelfish_parse_helper_to_date(cast('abc' as text), cast(1 as bool), cast('abc' as text));
go

create view test_func_babelfish_parse_helper_to_time_673 as select sys.babelfish_parse_helper_to_time(cast('abc' as text), cast(1 as bool), cast('abc' as text));
go

create view test_func_babelfish_parse_helper_to_datetime_674 as select sys.babelfish_parse_helper_to_datetime(cast('abc' as text), cast(1 as bool), cast('abc' as text));
go

create view test_func_babelfish_try_conv_money_to_string_675 as select sys.babelfish_try_conv_money_to_string(cast('abc' as text), cast(1 as money), cast(1.2 as numeric));
go

create view test_func_babelfish_try_parse_to_date_676 as select sys.babelfish_try_parse_to_date(cast('abc' as text), cast('abc' as text));
go

create view test_func_max_precision_677 as select sys.max_precision();
go

create view test_func_babelfish_try_parse_to_datetime_678 as select sys.babelfish_try_parse_to_datetime(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_try_parse_to_time_679 as select sys.babelfish_try_parse_to_time(cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_babelfish_update_job_680 as select sys.babelfish_update_job(cast(1 as int4), cast('abc' as varchar));
go

create view test_func_babelfish_waitfor_delay_681 as select sys.babelfish_waitfor_delay(cast('abc' as text));
go

create view test_func_babelfish_waitfor_delay_682 as select sys.babelfish_waitfor_delay(cast('01-01-2022' as timestamp));
go

create view test_func_babelfish_cursor_list_683 as select * from sys.babelfish_cursor_list(cast(1 as int4));
go

create view test_func_babelfish_get_datetimeoffset_tzoffset_684 as select sys.babelfish_get_datetimeoffset_tzoffset(cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_babelfish_get_enr_list_685 as select * from sys.babelfish_get_enr_list();
go

create view test_func_babelfish_collation_list_686 as select * from sys.babelfish_collation_list();
go

create view test_func_babelfish_truncate_identifier_687 as select sys.babelfish_truncate_identifier(cast('abc' as text));
go

create view test_func_babelfish_pltsql_cursor_show_textptr_only_column_indexes_688 as select sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(cast(1 as int4));
go

create view test_func_babelfish_pltsql_get_last_cursor_handle_689 as select sys.babelfish_pltsql_get_last_cursor_handle();
go

create view test_func_babelfish_pltsql_get_last_stmt_handle_690 as select sys.babelfish_pltsql_get_last_stmt_handle();
go

create view test_func_get_babel_server_collation_oid_691 as select sys.get_babel_server_collation_oid();
go

create view test_func_tsql_query_to_xml_692 as select sys.tsql_query_to_xml(cast('abc' as text), cast(1 as int4), cast('abc' as text), cast(1 as bool), cast('abc' as text));
go

create view test_func_tsql_query_to_xml_text_693 as select sys.tsql_query_to_xml_text(cast('abc' as text), cast(1 as int4), cast('abc' as text), cast(1 as bool), cast('abc' as text));
go

create view test_func_suser_sname_694 as select sys.suser_sname(cast(0xfe as varbinary));
go

create view test_func_suser_id_695 as select sys.suser_id(cast('abc' as text));
go

create view test_func_suser_sid_696 as select sys.suser_sid(cast('abc' as sysname), cast(1 as int4));
go

create view test_func_object_name_697 as select sys.object_name(cast(1 as int4), cast(1 as int4));
go

create view test_func_scope_identity_698 as select sys.scope_identity();
go

create view test_func_ident_seed_699 as select sys.ident_seed(cast('abc' as text));
go

create view test_func_ident_incr_700 as select sys.ident_incr(cast('abc' as text));
go

create view test_func_ident_current_701 as select sys.ident_current(cast('abc' as text));
go

create view test_func_datetime2fromparts_702 as select sys.datetime2fromparts(cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric));
go

create view test_func_datetime2fromparts_703 as select sys.datetime2fromparts(cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_procid_704 as select sys.procid();
go

create view test_func_datetimefromparts_705 as select sys.datetimefromparts(cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric));
go

create view test_func_datetimefromparts_706 as select sys.datetimefromparts(cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_isnumeric_707 as select sys.isnumeric(cast('abc' as text));
go

create view test_func_object_id_708 as select sys.object_id(cast('abc' as text), cast('a' as bpchar));
go

create view test_func_parsename_709 as select sys.parsename(cast('abc' as varchar), cast(1 as int4));
go

create view test_func_timefromparts_710 as select sys.timefromparts(cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric), cast(1.2 as numeric));
go

create view test_func_timefromparts_711 as select sys.timefromparts(cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text), cast('abc' as text));
go

create view test_func_has_dbaccess_712 as select sys.has_dbaccess(cast('abc' as sysname));
go

create view test_func_datefromparts_713 as select sys.datefromparts(cast(1 as int4), cast(1 as int4), cast(1 as int4));
go

create view test_func_charindex_714 as select sys.charindex(cast('abc' as text), cast('abc' as text), cast(1 as int4));
go

create view test_func_stuff_715 as select sys.stuff(cast('abc' as text), cast(1 as int4), cast(1 as int4), cast('abc' as text));
go

create view test_func_len_716 as select sys.len(cast('abc' as text));
go

create view test_func_len_717 as select sys.len(cast(0xfe as bbf_varbinary));
go

create view test_func_datalength_718 as select sys.datalength(cast('abc' as text));
go

create view test_func_datalength_719 as select sys.datalength(cast('a' as bpchar));
go

create view test_func_round_720 as select sys.round(cast(1.2 as numeric), cast(1 as int4));
go

create view test_func_round_721 as select sys.round(cast(1.2 as numeric), cast(1 as int4), cast(1 as int4));
go

create view test_func_space_722 as select sys.space(cast(1 as int4));
go

create view test_func_isdate_723 as select sys.isdate(cast('abc' as text));
go

create view test_func_patindex_724 as select sys.patindex(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_rand_725 as select sys.rand(cast(1 as int4));
go

create view test_func_datepart_726 as select sys.datepart(cast('abc' as text), cast('abc' as text));
go

create view test_func_datediff_727 as select sys.datediff(cast('abc' as text), cast('01-01-2022' as date), cast('01-01-2022' as date));
go

create view test_func_datediff_728 as select sys.datediff(cast('abc' as text), cast('01-01-2022' as datetime), cast('01-01-2022' as datetime));
go

create view test_func_datediff_729 as select sys.datediff(cast('abc' as text), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_datediff_730 as select sys.datediff(cast('abc' as text), cast('01-01-2022' as datetime2), cast('01-01-2022' as datetime2));
go

create view test_func_datediff_731 as select sys.datediff(cast('abc' as text), cast('01-01-2022' as smalldatetime), cast('01-01-2022' as smalldatetime));
go

create view test_func_dateadd_732 as select sys.dateadd(cast('abc' as text), cast(1 as int4), cast('abc' as text));
go

create view test_func_dateadd_internal_df_733 as select sys.dateadd_internal_df(cast('abc' as text), cast(1 as int4), cast('1912-12-31 12:24:32 +10:0' as datetimeoffset));
go

create view test_func_spid_734 as select sys.spid();
go

create view test_func_get_current_full_xact_id_735 as select sys.get_current_full_xact_id();
go

create view test_func_lock_timeout_736 as select sys.lock_timeout();
go

create view test_func_datename_737 as select sys.datename(cast('abc' as text), cast('abc' as text));
go

create view test_func_getutcdate_738 as select sys.getutcdate();
go

create view test_func_replicate_739 as select sys.replicate(cast('abc' as text), cast(1 as int4));
go

create view test_func_rowcount_740 as select sys.rowcount();
go

create view test_func_error_741 as select sys.error();
go

create view test_func_pgerror_742 as select sys.pgerror();
go

create view test_func_trancount_743 as select sys.trancount();
go

create view test_func_datefirst_744 as select sys.datefirst();
go

create view test_func_options_745 as select sys.options();
go

create view test_func_version_746 as select sys.version();
go

create view test_func_servername_747 as select sys.servername();
go

create view test_func_servicename_748 as select sys.servicename();
go

create view test_func_dbts_749 as select sys.dbts();
go

create view test_func_nestlevel_750 as select sys.nestlevel();
go

create view test_func_fetch_status_751 as select sys.fetch_status();
go

create view test_func_cursor_rows_752 as select sys.cursor_rows();
go

create view test_func_cursor_status_753 as select sys.cursor_status(cast('abc' as text), cast('abc' as text));
go

create view test_func_floor_754 as select sys.floor(cast(1 as bit));
go

create view test_func_floor_755 as select sys.floor(cast(1 as int8));
go

create view test_func_floor_756 as select sys.floor(cast(1 as int4));
go

create view test_func_floor_757 as select sys.floor(cast(1 as int2));
go

create view test_func_floor_758 as select sys.floor(cast(1 as tinyint));
go

create view test_func_ceiling_759 as select sys.ceiling(cast(1 as bit));
go

create view test_func_ceiling_760 as select sys.ceiling(cast(1 as int8));
go

create view test_func_ceiling_761 as select sys.ceiling(cast(1 as int4));
go

create view test_func_ceiling_762 as select sys.ceiling(cast(1 as int2));
go

create view test_func_ceiling_763 as select sys.ceiling(cast(1 as tinyint));
go

create view test_func_microsoftversion_764 as select sys.microsoftversion();
go

create view test_func_applock_mode_765 as select sys.applock_mode(cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_applock_test_766 as select sys.applock_test(cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_xact_state_767 as select sys.xact_state();
go

create view test_func_error_line_768 as select sys.error_line();
go

create view test_func_error_message_769 as select sys.error_message();
go

create view test_func_error_number_770 as select sys.error_number();
go

create view test_func_error_procedure_771 as select sys.error_procedure();
go

create view test_func_error_severity_772 as select sys.error_severity();
go

create view test_func_error_state_773 as select sys.error_state();
go

create view test_func_rand_774 as select sys.rand();
go

create view test_func_default_domain_775 as select sys.default_domain();
go

create view test_func_db_id_776 as select sys.db_id(cast('abc' as nvarchar));
go

create view test_func_db_id_777 as select sys.db_id();
go

create view test_func_db_name_778 as select sys.db_name(cast(1 as int4));
go

create view test_func_db_name_779 as select sys.db_name();
go

create view test_func_fn_listextendedproperty_780 as select * from sys.fn_listextendedproperty(cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_exp_781 as select sys.exp(cast(1.2 as numeric));
go

create view test_func_sign_782 as select sys.sign(cast(1 as int4));
go

create view test_func_sign_783 as select sys.sign(cast(1 as int2));
go

create view test_func_sign_784 as select sys.sign(cast(1 as tinyint));
go

create view test_func_sign_785 as select sys.sign(cast(1 as int8));
go

create view test_func_sign_786 as select sys.sign(cast(1 as money));
go

create view test_func_sign_787 as select sys.sign(cast(1 as smallmoney));
go

create view test_func_max_connections_788 as select sys.max_connections();
go

create view test_func_trigger_nestlevel_789 as select sys.trigger_nestlevel();
go

create view test_func_schema_name_790 as select sys.schema_name();
go

create view test_func_schema_id_791 as select sys.schema_id();
go

create view test_func_original_login_792 as select sys.original_login();
go

create view test_func_substring_793 as select sys.substring(cast('abc' as text), cast(1 as int4), cast(1 as int4));
go

create view test_func_substring_794 as select sys.substring(cast('abc' as varchar), cast(1 as int4), cast(1 as int4));
go

create view test_func_substring_795 as select sys.substring(cast('abc' as nvarchar), cast(1 as int4), cast(1 as int4));
go

create view test_func_substring_796 as select sys.substring(cast('a' as nchar), cast(1 as int4), cast(1 as int4));
go

create view test_func_get_host_os_797 as select sys.get_host_os();
go

create view test_func_tsql_stat_get_activity_798 as select sys.tsql_stat_get_activity(cast('abc' as text));
go

create view test_func_isjson_799 as select sys.isjson(cast('abc' as text));
go

create view test_func_json_value_800 as select sys.json_value(cast('abc' as text), cast('abc' as text));
go

create view test_func_json_query_801 as select sys.json_query(cast('abc' as text), cast('abc' as text));
go

create view test_func_sp_datatype_info_helper_802 as select sys.sp_datatype_info_helper(cast(1 as int2), cast(1 as bool));
go

create view test_func_babelfish_cast_floor_smallint_803 as select sys.babelfish_cast_floor_smallint(cast('abc' as text));
go

create view test_func_babelfish_cast_floor_int_804 as select sys.babelfish_cast_floor_int(cast('abc' as text));
go

create view test_func_babelfish_cast_floor_bigint_805 as select sys.babelfish_cast_floor_bigint(cast('abc' as text));
go

create view test_func_babelfish_try_cast_floor_smallint_806 as select sys.babelfish_try_cast_floor_smallint(cast('abc' as text));
go

create view test_func_babelfish_try_cast_floor_int_807 as select sys.babelfish_try_cast_floor_int(cast('abc' as text));
go

create view test_func_babelfish_try_cast_floor_bigint_808 as select sys.babelfish_try_cast_floor_bigint(cast('abc' as text));
go

create view test_func_babelfish_helpdb_809 as select * from sys.babelfish_helpdb();
go

create view test_func_babelfish_helpdb_810 as select * from sys.babelfish_helpdb(cast('abc' as varchar));
go

create view test_func_babelfish_inconsistent_metadata_811 as select * from sys.babelfish_inconsistent_metadata(cast(1 as bool));
go

create view test_func_role_id_812 as select sys.role_id(cast('abc' as sysname));
go

create view test_func_pltsql_call_handler_813 as select sys.pltsql_call_handler();
go

create view test_func_tsql_type_scale_helper_814 as select sys.tsql_type_scale_helper(cast('abc' as text), cast(1 as int4), cast(1 as bool));
go

create view test_func_tsql_type_precision_helper_815 as select sys.tsql_type_precision_helper(cast('abc' as text), cast(1 as int4));
go

create view test_func_tsql_type_max_length_helper_816 as select sys.tsql_type_max_length_helper(cast('abc' as text), cast(1 as int4), cast(1 as int4), cast(1 as bool));
go

create view test_func_columns_internal_817 as select * from sys.columns_internal();
go

create view test_func_proc_param_helper_818 as select * from sys.proc_param_helper();
go

create view test_func_sp_getapplock_function_819 as select sys.sp_getapplock_function(cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar), cast(1 as int4), cast('abc' as varchar));
go

create view test_func_sp_releaseapplock_function_820 as select sys.sp_releaseapplock_function(cast('abc' as varchar), cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_serverproperty_821 as select sys.serverproperty(cast('abc' as text));
go

create view test_func_databasepropertyex_822 as select sys.databasepropertyex(cast('abc' as text), cast('abc' as text));
go

create view test_func_connectionproperty_823 as select sys.connectionproperty(cast('abc' as text));
go

create view test_func_collationproperty_824 as select sys.collationproperty(cast('abc' as text), cast('abc' as text));
go

create view test_func_sessionproperty_825 as select sys.sessionproperty(cast('abc' as text));
go

create view test_func_assemblyproperty_826 as select sys.assemblyproperty(cast('abc' as varchar), cast('abc' as varchar));
go

create view test_func_is_member_827 as select sys.is_member(cast('abc' as varchar));
go

create view test_func_schema_id_828 as select sys.schema_id(cast('abc' as varchar));
go

create view test_func_fulltextserviceproperty_829 as select sys.fulltextserviceproperty(cast('abc' as text));
go

create view test_func_columns_updated_830 as select sys.columns_updated();
go

create view test_func_update_831 as select sys.update(cast('abc' as text));
go

create view test_func_tsql_type_radix_for_sp_columns_helper_832 as select sys.tsql_type_radix_for_sp_columns_helper(cast('abc' as text));
go

create view test_func_tsql_type_length_for_sp_columns_helper_833 as select sys.tsql_type_length_for_sp_columns_helper(cast('abc' as text), cast(1 as int4), cast(1 as int4));
go

create view test_func_sp_columns_100_internal_834 as select * from sys.sp_columns_100_internal(cast('abc' as nvarchar), cast('abc' as nvarchar), cast('abc' as nvarchar), cast('abc' as nvarchar), cast(1 as int4), cast(1 as int4), cast(1 as int2));
go

create view test_func_sp_describe_first_result_set_internal_835 as select * from sys.sp_describe_first_result_set_internal(cast('abc' as varchar), cast('abc' as varchar), cast(1 as tinyint));
go

create view test_func_sp_columns_managed_internal_836 as select * from sys.sp_columns_managed_internal(cast('abc' as nvarchar), cast('abc' as nvarchar), cast('abc' as nvarchar), cast('abc' as nvarchar), cast(1 as int4));
go

create view test_func_sp_describe_undeclared_parameters_internal_837 as select * from sys.sp_describe_undeclared_parameters_internal(cast('abc' as nvarchar), cast('abc' as nvarchar));
go

create view test_func_sp_tables_internal_838 as select * from sys.sp_tables_internal(cast('abc' as nvarchar), cast('abc' as nvarchar), cast('abc' as sysname), cast('abc' as varchar), cast(1 as bit));
go

create view test_func_fn_mapped_system_error_list_839 as select * from sys.fn_mapped_system_error_list();
go

create view test_func_sp_pkeys_internal_840 as select * from sys.sp_pkeys_internal(cast('abc' as nvarchar), cast('abc' as nvarchar), cast('abc' as nvarchar));
go

create view test_func_sp_statistics_internal_841 as select * from sys.sp_statistics_internal(cast('abc' as sysname), cast('abc' as sysname), cast('abc' as sysname), cast('abc' as sysname), cast('a' as bpchar), cast('a' as bpchar));
go

create view test_func_sp_special_columns_precision_helper_842 as select sys.sp_special_columns_precision_helper(cast('abc' as text), cast(1 as int4), cast(1 as int2), cast(1 as int8));
go

create view test_func_sp_special_columns_length_helper_843 as select sys.sp_special_columns_length_helper(cast('abc' as text), cast(1 as int4), cast(1 as int2), cast(1 as int8));
go

create view test_func_sp_special_columns_scale_helper_844 as select sys.sp_special_columns_scale_helper(cast('abc' as text), cast(1 as int4));
go

create view test_func_is_srvrolemember_845 as select sys.is_srvrolemember(cast('abc' as sysname), cast('abc' as sysname));
go

create view test_func_inject_fault_846 as select sys.inject_fault(cast('abc' as text), cast(1 as int4));
go

create view test_func_inject_fault_847 as select sys.inject_fault(cast('abc' as text), cast(1 as int4), cast(1 as int4));
go

create view test_func_inject_fault_status_848 as select sys.inject_fault_status(cast('abc' as text));
go

create view test_func_trigger_test_fault_849 as select sys.trigger_test_fault();
go

create view test_func_inject_fault_850 as select sys.inject_fault(cast('abc' as text));
go

create view test_func_disable_injected_fault_851 as select sys.disable_injected_fault(cast('abc' as text));
go

create view test_func_inject_fault_all_852 as select sys.inject_fault_all();
go

create view test_func_disable_injected_fault_all_853 as select sys.disable_injected_fault_all();
go

