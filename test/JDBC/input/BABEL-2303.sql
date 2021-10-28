-- Test multiplication between int types and money types
DECLARE @tinyint tinyint = 5
DECLARE @smallint smallint = 5
DECLARE @int bigint = 5
DECLARE @smallmoney smallmoney = 2
DECLARE @money money = 2
SELECT
 @tinyint * @smallmoney AS should_be_10
,@tinyint * @money AS should_be_10
,@smallint * @smallmoney AS should_be_10
,@smallint * @money AS should_be_10
,@int * @smallmoney AS should_be_10
,@int * @money AS should_be_10
,@smallmoney * @tinyint AS should_be_10
,@money * @tinyint AS should_be_10
,@smallmoney * @smallint AS should_be_10
,@money * @smallint AS should_be_10
,@smallmoney * @int AS should_be_10
,@money * @int AS should_be_10
GO

CREATE TABLE t1
(
 id int PRIMARY KEY IDENTITY
,c_tinyint tinyint
,c_smallint smallint
,c_smallmoney smallmoney
,c_money money
,c_tinyint_m_smallmoney AS c_tinyint * c_smallmoney
,c_tinyint_m_money AS c_tinyint * c_money
,c_smallint_m_smallmoney AS c_smallint * c_smallmoney
,c_smallint_m_money AS c_smallint * c_money
,c_smallmoney_m_tinyint AS c_smallmoney * c_tinyint
,c_money_m_tinyint AS c_money * c_tinyint
,c_smallmoney_m_smallint AS c_smallmoney * c_smallint
,c_money_m_smallint AS c_money * c_smallint
)
GO
INSERT INTO t1(c_tinyint, c_smallint, c_smallmoney, c_money) VALUES(5,5,2,2)
GO
SELECT c_tinyint_m_smallmoney, c_tinyint_m_money, c_smallint_m_smallmoney, c_smallint_m_money, c_smallmoney_m_tinyint, c_money_m_tinyint, c_smallmoney_m_smallint, c_money_m_smallint FROM t1
GO

-- Test division between int types and money types
DECLARE @tinyint tinyint = 5
DECLARE @smallint smallint = 5
DECLARE @int bigint = 5
DECLARE @smallmoney smallmoney = 2
DECLARE @money money = 2
SELECT
 @tinyint / @smallmoney AS ts
,@tinyint / @money AS tm
,@smallint / @smallmoney AS ss
,@smallint / @money AS sm
,@int / @smallmoney AS ids
,@int / @money AS im
,@smallmoney / @tinyint AS st
,@money / @tinyint AS mt
,@smallmoney / @smallint AS ss
,@money / @smallint AS ms
,@smallmoney / @int AS si
,@money / @int AS mi
GO

-- clean up
DROP TABLe t1;
GO
