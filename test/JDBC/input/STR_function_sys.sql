-- ======================================================================
-- Babelfish STR() vs SQL Server — Regression Suite (deduplicated/organized)
-- ======================================================================

/* =========================
   0) Smoke: basic rounding (1 d.p., 2 d.p.)
   ========================= */
SELECT STR(123.355, 10, 1) AS s_1dp_up;          -- T-SQL: '     123.4'
GO
SELECT STR(123.340, 10, 1) AS s_1dp_down;        -- T-SQL: '     123.3'
GO
SELECT STR(123.350, 10, 1) AS s_1dp_tie;         -- T-SQL (float edge): often '     123.3'
GO
SELECT STR(123.358, 10, 1) AS s_1dp_up2;         -- T-SQL: '     123.4'
GO

SELECT STR(123.355, 10, 2) AS s_2dp_up;          -- T-SQL: '    123.36'
GO
SELECT STR(123.340, 10, 2) AS s_2dp_down;        -- T-SQL: '    123.34'
GO
SELECT STR(123.350, 10, 2) AS s_2dp_tie;         -- T-SQL: '    123.35'
GO
SELECT STR(123.358, 10, 2) AS s_2dp_up2;         -- T-SQL: '    123.36'
GO


/* =========================
   1) HP — 17 significant digits rule
   ========================= */
SELECT STR(12345678901234567890, 20) AS hp1;                         -- T-SQL: '12345678901234567000'
GO
SELECT STR(1234567890123456789.12345678901234567, 22, 20) AS hp2;    -- T-SQL: '1234567890123456800.00'
GO
SELECT STR(1234567890123456.12345678901234567, 22, 20) AS hp3;       -- T-SQL: '1234567890123456.00000'
GO
SELECT STR(99999999999999999.95, 22, 2) AS hp4;                      -- T-SQL: ' 100000000000000000.00'
GO
SELECT STR(1234567890.1234567890, 22, 20) AS hp5;                    -- T-SQL: '1234567890.12345670000'
GO


/* =========================
   2) DP — Fraction cap (max 16) & padding
   ========================= */
SELECT STR(0.123456789012345678, 20, 20) AS dp1;                     -- T-SQL: '  0.1234567890123457'
GO
SELECT STR(-0.123456789012345678, 20, 20) AS dp2;                    -- T-SQL: ' -0.1234567890123457'
GO
SELECT STR(123.4567890123456789, 20, 20) AS dp3;                     -- T-SQL: '123.4567890123456800'
GO
SELECT STR(0.99999999999999995, 22, 20) AS dp4;                      -- T-SQL: '    1.0000000000000000'
GO
SELECT STR(0.12345678901234565, 22, 16) AS dp5;                      -- T-SQL: '    0.1234567890123457'
GO

-- Bracketed padding checks (helps detect leading/trailing space handling)
SELECT '[' + STR(0.123456789012345678, 20, 20) + ']' AS pad_dp1;     -- T-SQL: '[  0.1234567890123457]'
GO
SELECT '[' + STR(0.123456789012345678, 20, 16) + ']' AS pad_dp2;     -- T-SQL: '[  0.1234567890123457]'
GO
SELECT '[' + STR(0.123456789012345678, 18, 20) + ']' AS pad_dp3;     -- T-SQL: '[0.1234567890123457]'
GO

-- Same numeric value with a leading zero in the literal (parsing should not change the value)
SELECT '[' + STR(01.123456789012345678, 20, 20) + ']' AS pad_dp4;    -- T-SQL: '[  1.1234567890123457]'
GO
SELECT '[' + STR(01.123456789012345678, 20, 16) + ']' AS pad_dp5;    -- T-SQL: '[  1.1234567890123457]'
GO
SELECT '[' + STR(01.123456789012345678, 18, 20) + ']' AS pad_dp6;    -- T-SQL: '[1.1234567890123457]'
GO


/* =========================
   3) CR — Carry & boundary rounding
   ========================= */
SELECT STR(1.9999, 6, 3)  AS cr1;                                    -- T-SQL: ' 2.000'
GO
SELECT STR(0.9995, 6, 3)  AS cr2;                                    -- T-SQL: ' 1.000'
GO
SELECT STR(-0.9995, 7, 3) AS cr3;                                    -- T-SQL: '-1.000'
GO
SELECT STR(-999.9, 6, 0)  AS cr4;                                    -- T-SQL: ' -1000'
GO

-- Float-sensitive boundaries (expected to match T-SQL with Babelfish rounding patch)
SELECT STR(9.9995, 6, 3)  AS cr5_float_edge;                         -- T-SQL: ' 9.999'
GO
SELECT STR(2.675, 10, 2)  AS cr6_float_edge;                         -- T-SQL: '      2.67'
GO
-- DECIMAL references (deterministic; serves as a control)
SELECT STR(CAST(9.9995 AS decimal(38,4)), 6, 3) AS cr7_dec_ref;      -- T-SQL: '10.000'
GO
SELECT STR(CAST(2.675  AS decimal(38,3)), 10, 2) AS cr8_dec_ref;     -- T-SQL: '      2.68'
GO


/* =========================
   4) LC — Length constraint: effective decimals squeezed by length
   ========================= */
SELECT STR(1234.5678, 8, 4)  AS lc1;                                 -- T-SQL: '1234.568' (only 3 d.p. fit)
GO
SELECT STR(1234.5673, 8, 4)  AS lc2;                                 -- T-SQL: '1234.567'
GO
SELECT STR(-1234.5678, 9, 4) AS lc3;                                 -- T-SQL: '-1234.568'
GO
SELECT STR(12.3456, 5, 4)    AS lc4;                                 -- T-SQL: '12.35'
GO
SELECT STR(0.12345, 6, 4)    AS lc5;                                 -- T-SQL: '0.1235'
GO
SELECT STR(99.999,  6, 4)    AS lc6;                                 -- T-SQL: '99.999'
GO


/* =========================
   5) OF — Overflow → stars
   ========================= */
SELECT STR(12345, 4, 0) AS of1;                                      -- T-SQL: '****'
GO
SELECT STR(-1234, 4, 0) AS of2;                                      -- T-SQL: '****'
GO
SELECT STR(123.45, 5, 2) AS of3;                                     -- T-SQL: '****' (3 + '.' + 2 = 6 > 5)
GO
SELECT STR(99999.99, 5, 1) AS of4;                                   -- T-SQL: '*****'
GO


/* =========================
   6) SP — Sign, padding, zeros
   ========================= */
SELECT '[' + STR(12345, 10, 0) + ']' AS sp1;                         -- T-SQL: '[     12345]'
GO
SELECT '[' + STR(-1234, 5, 0)  + ']' AS sp2;                         -- T-SQL: '[-1234]'
GO
SELECT '[' + STR(0, 6, 3)      + ']' AS sp3;                         -- T-SQL: '[  0.000]'
GO
SELECT '[' + STR(-0.0001, 8, 4) + ']' AS sp4;                        -- T-SQL: '[ -0.0001]'
GO


/* =========================
   7) FS — Float vs DECIMAL comparisons
   ========================= */
SELECT STR(123.350, 10, 1) AS fs1_float;                             -- T-SQL (float edge): may be '     123.3'
GO
SELECT STR(CAST(123.350 AS decimal(38,3)), 10, 1) AS fs1_decimal;    -- T-SQL: '     123.4'
GO
SELECT STR(0.1 + 0.2, 10, 1) AS fs2_float;                           -- T-SQL: '       0.3' (computed via float)
GO
SELECT STR(CAST(0.1 AS decimal(38,4)) + CAST(0.2 AS decimal(38,4)), 10, 1) AS fs2_decimal; -- '       0.3'
GO


/* =========================
   8) VAL — Validity & NULL behavior
   ========================= */
SELECT STR(NULL, 10, 2) AS v_null;                                   -- T-SQL: NULL
GO
SELECT STR(123.45, 0,  2) AS v_len0;                                 -- T-SQL: NULL
GO
SELECT STR(123.45, 9001, 2) AS v_len9001;                            -- T-SQL: NULL (length > 8000)
GO
SELECT STR(123.45, 10, -1) AS v_decneg;                              -- T-SQL: NULL
GO


/* =========================
   9) REPEAT — Critical HP/DP sanity repeats (quick sentinels)
   ========================= */
SELECT STR(12345678901234567890, 20)          AS hp1_repeat;         -- T-SQL: '12345678901234567000'
GO
SELECT STR(1234567890.1234567890, 22, 20)     AS hp5_repeat;         -- T-SQL: '1234567890.12345670000'
GO
SELECT STR(0.123456789012345678, 20, 20)      AS dp1_repeat;         -- T-SQL: '  0.1234567890123457'
GO
