create view test_opr_0 as select case when cast(1.2 as fixeddecimal) <> cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_1 as select case when cast(1.2 as fixeddecimal) == cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_2 as select case when cast(1.2 as fixeddecimal) > cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_3 as select case when cast(1.2 as fixeddecimal) >= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_4 as select case when cast(1.2 as fixeddecimal) < cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_5 as select case when cast(1.2 as fixeddecimal) <= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_6 as select cast(1.2 as fixeddecimal) + cast(1.2 as fixeddecimal) as col;
go

create view test_opr_7 as select cast(1.2 as fixeddecimal) - cast(1.2 as fixeddecimal) as col;
go

create view test_opr_8 as select cast(1.2 as fixeddecimal) * cast(1.2 as fixeddecimal) as col;
go

create view test_opr_9 as select cast(1.2 as fixeddecimal) / cast(1.2 as fixeddecimal) as col;
go

create view test_opr_10 as select case when cast(1.2 as numeric) == cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_11 as select case when cast(1.2 as fixeddecimal) <> cast(1.2 as numeric) then 1 else 0 end as col;
go

create view test_opr_12 as select case when cast(1.2 as fixeddecimal) == cast(1.2 as numeric) then 1 else 0 end as col;
go

create view test_opr_13 as select case when cast(1.2 as numeric) <> cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_14 as select case when cast(1.2 as numeric) > cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_15 as select case when cast(1.2 as fixeddecimal) >= cast(1.2 as numeric) then 1 else 0 end as col;
go

create view test_opr_16 as select case when cast(1.2 as fixeddecimal) < cast(1.2 as numeric) then 1 else 0 end as col;
go

create view test_opr_17 as select case when cast(1.2 as numeric) >= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_18 as select case when cast(1.2 as fixeddecimal) > cast(1.2 as numeric) then 1 else 0 end as col;
go

create view test_opr_19 as select case when cast(1.2 as fixeddecimal) <= cast(1.2 as numeric) then 1 else 0 end as col;
go

create view test_opr_20 as select case when cast(1.2 as numeric) <= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_21 as select case when cast(1.2 as numeric) < cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_22 as select case when cast(1 as int8) == cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_23 as select case when cast(1.2 as fixeddecimal) <> cast(1 as int8) then 1 else 0 end as col;
go

create view test_opr_24 as select case when cast(1.2 as fixeddecimal) == cast(1 as int8) then 1 else 0 end as col;
go

create view test_opr_25 as select case when cast(1 as int8) <> cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_26 as select case when cast(1 as int8) > cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_27 as select case when cast(1.2 as fixeddecimal) >= cast(1 as int8) then 1 else 0 end as col;
go

create view test_opr_28 as select case when cast(1.2 as fixeddecimal) < cast(1 as int8) then 1 else 0 end as col;
go

create view test_opr_29 as select case when cast(1 as int8) >= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_30 as select case when cast(1.2 as fixeddecimal) > cast(1 as int8) then 1 else 0 end as col;
go

create view test_opr_31 as select case when cast(1.2 as fixeddecimal) <= cast(1 as int8) then 1 else 0 end as col;
go

create view test_opr_32 as select case when cast(1 as int8) <= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_33 as select case when cast(1 as int8) < cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_34 as select cast(1 as int8) + cast(1.2 as fixeddecimal) as col;
go

create view test_opr_35 as select cast(1.2 as fixeddecimal) + cast(1 as int8) as col;
go

create view test_opr_36 as select cast(1.2 as fixeddecimal) - cast(1 as int8) as col;
go

create view test_opr_37 as select cast(1 as int8) * cast(1.2 as fixeddecimal) as col;
go

create view test_opr_38 as select cast(1.2 as fixeddecimal) * cast(1 as int8) as col;
go

create view test_opr_39 as select cast(1.2 as fixeddecimal) / cast(1 as int8) as col;
go

create view test_opr_40 as select cast(1 as int8) - cast(1.2 as fixeddecimal) as col;
go

create view test_opr_41 as select cast(1 as int8) / cast(1.2 as fixeddecimal) as col;
go

create view test_opr_42 as select case when cast(1 as int4) == cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_43 as select case when cast(1.2 as fixeddecimal) <> cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_44 as select case when cast(1.2 as fixeddecimal) == cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_45 as select case when cast(1 as int4) <> cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_46 as select case when cast(1 as int4) > cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_47 as select case when cast(1.2 as fixeddecimal) >= cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_48 as select case when cast(1.2 as fixeddecimal) < cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_49 as select case when cast(1 as int4) >= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_50 as select case when cast(1.2 as fixeddecimal) > cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_51 as select case when cast(1.2 as fixeddecimal) <= cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_52 as select case when cast(1 as int4) <= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_53 as select case when cast(1 as int4) < cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_54 as select cast(1 as int4) + cast(1.2 as fixeddecimal) as col;
go

create view test_opr_55 as select cast(1.2 as fixeddecimal) + cast(1 as int4) as col;
go

create view test_opr_56 as select cast(1.2 as fixeddecimal) - cast(1 as int4) as col;
go

create view test_opr_57 as select cast(1 as int4) * cast(1.2 as fixeddecimal) as col;
go

create view test_opr_58 as select cast(1.2 as fixeddecimal) * cast(1 as int4) as col;
go

create view test_opr_59 as select cast(1.2 as fixeddecimal) / cast(1 as int4) as col;
go

create view test_opr_60 as select cast(1 as int4) - cast(1.2 as fixeddecimal) as col;
go

create view test_opr_61 as select cast(1 as int4) / cast(1.2 as fixeddecimal) as col;
go

create view test_opr_62 as select case when cast(1 as int2) == cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_63 as select case when cast(1.2 as fixeddecimal) <> cast(1 as int2) then 1 else 0 end as col;
go

create view test_opr_64 as select case when cast(1.2 as fixeddecimal) == cast(1 as int2) then 1 else 0 end as col;
go

create view test_opr_65 as select case when cast(1 as int2) <> cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_66 as select case when cast(1 as int2) > cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_67 as select case when cast(1.2 as fixeddecimal) >= cast(1 as int2) then 1 else 0 end as col;
go

create view test_opr_68 as select case when cast(1.2 as fixeddecimal) < cast(1 as int2) then 1 else 0 end as col;
go

create view test_opr_69 as select case when cast(1 as int2) >= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_70 as select case when cast(1.2 as fixeddecimal) > cast(1 as int2) then 1 else 0 end as col;
go

create view test_opr_71 as select case when cast(1.2 as fixeddecimal) <= cast(1 as int2) then 1 else 0 end as col;
go

create view test_opr_72 as select case when cast(1 as int2) <= cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_73 as select case when cast(1 as int2) < cast(1.2 as fixeddecimal) then 1 else 0 end as col;
go

create view test_opr_74 as select cast(1 as int2) + cast(1.2 as fixeddecimal) as col;
go

create view test_opr_75 as select cast(1.2 as fixeddecimal) + cast(1 as int2) as col;
go

create view test_opr_76 as select cast(1.2 as fixeddecimal) - cast(1 as int2) as col;
go

create view test_opr_77 as select cast(1 as int2) * cast(1.2 as fixeddecimal) as col;
go

create view test_opr_78 as select cast(1.2 as fixeddecimal) * cast(1 as int2) as col;
go

create view test_opr_79 as select cast(1.2 as fixeddecimal) / cast(1 as int2) as col;
go

create view test_opr_80 as select cast(1 as int2) - cast(1.2 as fixeddecimal) as col;
go

create view test_opr_81 as select cast(1 as int2) / cast(1.2 as fixeddecimal) as col;
go

create view test_opr_82 as select cast(1 as smallmoney) + cast(1 as smallmoney) as col;
go

create view test_opr_83 as select cast(1 as smallmoney) - cast(1 as smallmoney) as col;
go

create view test_opr_84 as select cast(1 as smallmoney) * cast(1 as smallmoney) as col;
go

create view test_opr_85 as select cast(1 as smallmoney) / cast(1 as smallmoney) as col;
go

create view test_opr_86 as select cast(1 as int8) + cast(1 as smallmoney) as col;
go

create view test_opr_87 as select cast(1 as smallmoney) + cast(1 as int8) as col;
go

create view test_opr_88 as select cast(1 as smallmoney) - cast(1 as int8) as col;
go

create view test_opr_89 as select cast(1 as int8) * cast(1 as smallmoney) as col;
go

create view test_opr_90 as select cast(1 as smallmoney) * cast(1 as int8) as col;
go

create view test_opr_91 as select cast(1 as smallmoney) / cast(1 as int8) as col;
go

create view test_opr_92 as select cast(1 as int4) + cast(1 as smallmoney) as col;
go

create view test_opr_93 as select cast(1 as smallmoney) + cast(1 as int4) as col;
go

create view test_opr_94 as select cast(1 as smallmoney) - cast(1 as int4) as col;
go

create view test_opr_95 as select cast(1 as int4) * cast(1 as smallmoney) as col;
go

create view test_opr_96 as select cast(1 as smallmoney) * cast(1 as int4) as col;
go

create view test_opr_97 as select cast(1 as smallmoney) / cast(1 as int4) as col;
go

create view test_opr_98 as select cast(1 as int2) + cast(1 as smallmoney) as col;
go

create view test_opr_99 as select cast(1 as smallmoney) + cast(1 as int2) as col;
go

create view test_opr_100 as select cast(1 as smallmoney) - cast(1 as int2) as col;
go

create view test_opr_101 as select cast(1 as int2) * cast(1 as smallmoney) as col;
go

create view test_opr_102 as select cast(1 as smallmoney) * cast(1 as int2) as col;
go

create view test_opr_103 as select cast(1 as smallmoney) / cast(1 as int2) as col;
go

create view test_opr_104 as select cast(1 as int8) - cast(1 as smallmoney) as col;
go

create view test_opr_105 as select cast(1 as int8) / cast(1 as smallmoney) as col;
go

create view test_opr_106 as select cast(1 as int4) - cast(1 as smallmoney) as col;
go

create view test_opr_107 as select cast(1 as int4) / cast(1 as smallmoney) as col;
go

create view test_opr_108 as select cast(1 as int2) - cast(1 as smallmoney) as col;
go

create view test_opr_109 as select cast(1 as int2) / cast(1 as smallmoney) as col;
go

create view test_opr_110 as select case when cast('a' as bpchar) <> cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_111 as select case when cast('a' as bpchar) == cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_112 as select case when cast('a' as bpchar) > cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_113 as select case when cast('a' as bpchar) >= cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_114 as select case when cast('a' as bpchar) < cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_115 as select case when cast('a' as bpchar) <= cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_116 as select case when cast('abc' as text) == cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_117 as select case when cast('a' as bpchar) <> cast('abc' as text) then 1 else 0 end as col;
go

create view test_opr_118 as select case when cast('a' as bpchar) == cast('abc' as text) then 1 else 0 end as col;
go

create view test_opr_119 as select case when cast('abc' as text) <> cast('a' as bpchar) then 1 else 0 end as col;
go

create view test_opr_120 as select case when cast('abc' as varchar) <> cast('abc' as varchar) then 1 else 0 end as col;
go

create view test_opr_121 as select case when cast('abc' as varchar) == cast('abc' as varchar) then 1 else 0 end as col;
go

create view test_opr_122 as select case when cast('abc' as varchar) > cast('abc' as varchar) then 1 else 0 end as col;
go

create view test_opr_123 as select case when cast('abc' as varchar) >= cast('abc' as varchar) then 1 else 0 end as col;
go

create view test_opr_124 as select case when cast('abc' as varchar) < cast('abc' as varchar) then 1 else 0 end as col;
go

create view test_opr_125 as select case when cast('abc' as varchar) <= cast('abc' as varchar) then 1 else 0 end as col;
go

create view test_opr_126 as select cast(1 as tinyint) ^ cast(1 as tinyint) as col;
go

create view test_opr_127 as select cast(1 as int2) ^ cast(1 as int2) as col;
go

create view test_opr_128 as select cast(1 as int4) ^ cast(1 as int4) as col;
go

create view test_opr_129 as select cast(1 as int8) ^ cast(1 as int8) as col;
go

create view test_opr_130 as select cast(1 as tinyint) + cast(1 as tinyint) as col;
go

create view test_opr_131 as select cast(1 as tinyint) - cast(1 as tinyint) as col;
go

create view test_opr_132 as select cast(1 as tinyint) * cast(1 as tinyint) as col;
go

create view test_opr_133 as select cast(1 as tinyint) / cast(1 as tinyint) as col;
go

create view test_opr_134 as select cast(1 as tinyint) + cast(1 as smallmoney) as col;
go

create view test_opr_135 as select cast(1 as smallmoney) + cast(1 as tinyint) as col;
go

create view test_opr_136 as select cast(1 as smallmoney) - cast(1 as tinyint) as col;
go

create view test_opr_137 as select cast(1 as tinyint) * cast(1 as smallmoney) as col;
go

create view test_opr_138 as select cast(1 as smallmoney) * cast(1 as tinyint) as col;
go

create view test_opr_139 as select cast(1 as smallmoney) / cast(1 as tinyint) as col;
go

create view test_opr_140 as select cast(1 as tinyint) - cast(1 as smallmoney) as col;
go

create view test_opr_141 as select cast(1 as tinyint) / cast(1 as smallmoney) as col;
go

create view test_opr_142 as select case when cast(1 as bit) <> cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_143 as select case when cast(1 as bit) == cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_144 as select case when cast(1 as bit) > cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_145 as select case when cast(1 as bit) >= cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_146 as select case when cast(1 as bit) < cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_147 as select case when cast(1 as bit) <= cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_148 as select case when cast(1 as bit) == cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_149 as select case when cast(1 as int4) <> cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_150 as select case when cast(1 as int4) == cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_151 as select case when cast(1 as bit) <> cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_152 as select case when cast(1 as bit) > cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_153 as select case when cast(1 as int4) >= cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_154 as select case when cast(1 as int4) < cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_155 as select case when cast(1 as bit) >= cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_156 as select case when cast(1 as int4) > cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_157 as select case when cast(1 as int4) <= cast(1 as bit) then 1 else 0 end as col;
go

create view test_opr_158 as select case when cast(1 as bit) < cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_159 as select case when cast(1 as bit) <= cast(1 as int4) then 1 else 0 end as col;
go

create view test_opr_160 as select case when cast(0xfe as bbf_varbinary) == cast(0xfe as bbf_varbinary) then 1 else 0 end as col;
go

create view test_opr_161 as select case when cast(0xfe as bbf_varbinary) <> cast(0xfe as bbf_varbinary) then 1 else 0 end as col;
go

create view test_opr_162 as select case when cast(0xfe as bbf_varbinary) < cast(0xfe as bbf_varbinary) then 1 else 0 end as col;
go

create view test_opr_163 as select case when cast(0xfe as bbf_varbinary) > cast(0xfe as bbf_varbinary) then 1 else 0 end as col;
go

create view test_opr_164 as select case when cast(0xfe as bbf_varbinary) <= cast(0xfe as bbf_varbinary) then 1 else 0 end as col;
go

create view test_opr_165 as select case when cast(0xfe as bbf_varbinary) >= cast(0xfe as bbf_varbinary) then 1 else 0 end as col;
go

create view test_opr_166 as select case when cast(0xfe as bbf_binary) == cast(0xfe as bbf_binary) then 1 else 0 end as col;
go

create view test_opr_167 as select case when cast(0xfe as bbf_binary) <> cast(0xfe as bbf_binary) then 1 else 0 end as col;
go

create view test_opr_168 as select case when cast(0xfe as bbf_binary) < cast(0xfe as bbf_binary) then 1 else 0 end as col;
go

create view test_opr_169 as select case when cast(0xfe as bbf_binary) > cast(0xfe as bbf_binary) then 1 else 0 end as col;
go

create view test_opr_170 as select case when cast(0xfe as bbf_binary) <= cast(0xfe as bbf_binary) then 1 else 0 end as col;
go

create view test_opr_171 as select case when cast(0xfe as bbf_binary) >= cast(0xfe as bbf_binary) then 1 else 0 end as col;
go

create view test_opr_172 as select case when CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) <> CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) then 1 else 0 end as col;
go

create view test_opr_173 as select case when CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) == CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) then 1 else 0 end as col;
go

create view test_opr_174 as select case when CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) > CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) then 1 else 0 end as col;
go

create view test_opr_175 as select case when CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) >= CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) then 1 else 0 end as col;
go

create view test_opr_176 as select case when CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) < CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) then 1 else 0 end as col;
go

create view test_opr_177 as select case when CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) <= CAST('1E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier) then 1 else 0 end as col;
go

create view test_opr_178 as select case when cast('01-01-2022' as datetime) <> cast('01-01-2022' as datetime) then 1 else 0 end as col;
go

create view test_opr_179 as select case when cast('01-01-2022' as datetime) == cast('01-01-2022' as datetime) then 1 else 0 end as col;
go

create view test_opr_180 as select case when cast('01-01-2022' as datetime) > cast('01-01-2022' as datetime) then 1 else 0 end as col;
go

create view test_opr_181 as select case when cast('01-01-2022' as datetime) >= cast('01-01-2022' as datetime) then 1 else 0 end as col;
go

create view test_opr_182 as select case when cast('01-01-2022' as datetime) < cast('01-01-2022' as datetime) then 1 else 0 end as col;
go

create view test_opr_183 as select case when cast('01-01-2022' as datetime) <= cast('01-01-2022' as datetime) then 1 else 0 end as col;
go

create view test_opr_184 as select cast('01-01-2022' as datetime) + cast(1 as int4) as col;
go

create view test_opr_185 as select cast(1 as int4) + cast('01-01-2022' as datetime) as col;
go

create view test_opr_186 as select cast('01-01-2022' as datetime) - cast(1 as int4) as col;
go

create view test_opr_187 as select cast(1 as int4) - cast('01-01-2022' as datetime) as col;
go

create view test_opr_188 as select case when cast('01-01-2022' as datetime2) <> cast('01-01-2022' as datetime2) then 1 else 0 end as col;
go

create view test_opr_189 as select case when cast('01-01-2022' as datetime2) == cast('01-01-2022' as datetime2) then 1 else 0 end as col;
go

create view test_opr_190 as select case when cast('01-01-2022' as datetime2) > cast('01-01-2022' as datetime2) then 1 else 0 end as col;
go

create view test_opr_191 as select case when cast('01-01-2022' as datetime2) >= cast('01-01-2022' as datetime2) then 1 else 0 end as col;
go

create view test_opr_192 as select case when cast('01-01-2022' as datetime2) < cast('01-01-2022' as datetime2) then 1 else 0 end as col;
go

create view test_opr_193 as select case when cast('01-01-2022' as datetime2) <= cast('01-01-2022' as datetime2) then 1 else 0 end as col;
go

create view test_opr_194 as select case when cast('01-01-2022' as smalldatetime) <> cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_195 as select case when cast('01-01-2022' as smalldatetime) == cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_196 as select case when cast('01-01-2022' as smalldatetime) > cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_197 as select case when cast('01-01-2022' as smalldatetime) >= cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_198 as select case when cast('01-01-2022' as smalldatetime) < cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_199 as select case when cast('01-01-2022' as smalldatetime) <= cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_200 as select case when cast('01-01-2022' as date) == cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_201 as select case when cast('01-01-2022' as smalldatetime) <> cast('01-01-2022' as date) then 1 else 0 end as col;
go

create view test_opr_202 as select case when cast('01-01-2022' as smalldatetime) == cast('01-01-2022' as date) then 1 else 0 end as col;
go

create view test_opr_203 as select case when cast('01-01-2022' as date) <> cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_204 as select case when cast('01-01-2022' as date) > cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_205 as select case when cast('01-01-2022' as smalldatetime) >= cast('01-01-2022' as date) then 1 else 0 end as col;
go

create view test_opr_206 as select case when cast('01-01-2022' as smalldatetime) < cast('01-01-2022' as date) then 1 else 0 end as col;
go

create view test_opr_207 as select case when cast('01-01-2022' as date) >= cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_208 as select case when cast('01-01-2022' as smalldatetime) > cast('01-01-2022' as date) then 1 else 0 end as col;
go

create view test_opr_209 as select case when cast('01-01-2022' as smalldatetime) <= cast('01-01-2022' as date) then 1 else 0 end as col;
go

create view test_opr_210 as select case when cast('01-01-2022' as date) < cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_211 as select case when cast('01-01-2022' as date) <= cast('01-01-2022' as smalldatetime) then 1 else 0 end as col;
go

create view test_opr_212 as select cast('01-01-2022' as smalldatetime) + cast(1 as int4) as col;
go

create view test_opr_213 as select cast(1 as int4) + cast('01-01-2022' as smalldatetime) as col;
go

create view test_opr_214 as select cast('01-01-2022' as smalldatetime) - cast(1 as int4) as col;
go

create view test_opr_215 as select cast(1 as int4) - cast('01-01-2022' as smalldatetime) as col;
go

create view test_opr_216 as select case when cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) <> cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) then 1 else 0 end as col;
go

create view test_opr_217 as select case when cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) == cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) then 1 else 0 end as col;
go

create view test_opr_218 as select case when cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) > cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) then 1 else 0 end as col;
go

create view test_opr_219 as select case when cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) >= cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) then 1 else 0 end as col;
go

create view test_opr_220 as select case when cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) < cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) then 1 else 0 end as col;
go

create view test_opr_221 as select case when cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) <= cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) then 1 else 0 end as col;
go

create view test_opr_222 as select cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) - cast('1912-12-31 12:24:32 +10:0' as datetimeoffset) as col;
go

create view test_opr_223 as select case when 'abc' <> 'abc' then 1 else 0 end as col;
go

create view test_opr_224 as select case when 'abc' == 'abc' then 1 else 0 end as col;
go

create view test_opr_225 as select case when 'abc' > 'abc' then 1 else 0 end as col;
go

create view test_opr_226 as select case when 'abc' >= 'abc' then 1 else 0 end as col;
go

create view test_opr_227 as select case when 'abc' < 'abc' then 1 else 0 end as col;
go

create view test_opr_228 as select case when 'abc' <= 'abc' then 1 else 0 end as col;
go

create view test_opr_229 as select cast('abc' as text) + cast('abc' as text) as col;
go

create view test_opr_230 as select cast('abc' as varchar) + cast('abc' as varchar) as col;
go

create view test_opr_231 as select cast('abc' as nvarchar) + cast('abc' as nvarchar) as col;
go

create view test_opr_232 as select cast('a' as bpchar) + cast('a' as bpchar) as col;
go

create view test_opr_233 as select cast('a' as nchar) + cast('a' as nchar) as col;
go

create view test_opr_234 as select cast('abc' as varchar) + cast('abc' as nvarchar) as col;
go

create view test_opr_235 as select cast('abc' as nvarchar) + cast('abc' as varchar) as col;
go

create view test_opr_236 as select case when cast(0xfe as rowversion) == cast(0xfe as rowversion) then 1 else 0 end as col;
go

create view test_opr_237 as select case when cast(0xfe as rowversion) <> cast(0xfe as rowversion) then 1 else 0 end as col;
go

create view test_opr_238 as select case when cast(0xfe as rowversion) < cast(0xfe as rowversion) then 1 else 0 end as col;
go

create view test_opr_239 as select case when cast(0xfe as rowversion) > cast(0xfe as rowversion) then 1 else 0 end as col;
go

create view test_opr_240 as select case when cast(0xfe as rowversion) <= cast(0xfe as rowversion) then 1 else 0 end as col;
go

create view test_opr_241 as select case when cast(0xfe as rowversion) >= cast(0xfe as rowversion) then 1 else 0 end as col;
go

