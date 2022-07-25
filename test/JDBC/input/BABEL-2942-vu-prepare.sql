-- japanese_cs_as collation
CREATE TABLE bbl_2942_t_japan_csas(t varchar(20) collate japanese_cs_as);
GO

INSERT INTO bbl_2942_t_japan_csas (t) VALUES 
('う'), ('ｳ'), ('C'), ('かさ'), ('ば'), ('ﾊﾟ'), ('３'), ('ﾊﾞ'), ('c'), ('ｲ'), ('がく'), ('Ｃ'), ('ウ'),('ﾊ'),  
('1'), ('ｱ'),('パ'), ('b'), ('2'), ('ハ'),('Ｂ'), ('B'), ('バ'),('１'), ('Ａ'), ('ぱ'),('い'),('ア'), 
('か'), ('A'), ('a'), ('ａ'),('AbC'), ('aBc'), ('は');
GO

-- japanese_ci_as collation
CREATE TABLE bbl_2942_t_japan_cias(t varchar(20) collate japanese_ci_as);
GO

INSERT INTO bbl_2942_t_japan_cias (t) VALUES 
('う'), ('ｳ'), ('C'), ('かさ'), ('ば'), ('ﾊﾟ'), ('３'), ('ﾊﾞ'), ('c'), ('ｲ'), ('がく'), ('Ｃ'), ('ウ'),('ﾊ'),  
('1'), ('ｱ'),('パ'), ('b'), ('2'), ('ハ'),('Ｂ'), ('B'), ('バ'),('１'), ('Ａ'), ('ぱ'),('い'),('ア'), 
('か'), ('A'), ('a'), ('ａ'),('AbC'), ('aBc'), ('は');
GO

-- japanese_ci_ai collation
CREATE TABLE bbl_2942_t_japan_ciai(t varchar(20) collate japanese_ci_ai);
GO

INSERT INTO bbl_2942_t_japan_ciai (t) VALUES 
('う'), ('ｳ'), ('C'), ('かさ'), ('ば'), ('ﾊﾟ'), ('３'), ('ﾊﾞ'), ('c'), ('ｲ'), ('がく'), ('Ｃ'), ('ウ'),('ﾊ'),  
('1'), ('ｱ'),('パ'), ('b'), ('2'), ('ハ'),('Ｂ'), ('B'), ('バ'),('１'), ('Ａ'), ('ぱ'),('い'),('ア'), 
('か'), ('A'), ('a'), ('ａ'),('AbC'), ('aBc'), ('は');
GO
