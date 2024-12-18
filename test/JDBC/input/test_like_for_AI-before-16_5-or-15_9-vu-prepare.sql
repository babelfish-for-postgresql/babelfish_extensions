------------------- CI_AI ----------------------

CREATE TABLE test_like_for_AI_prepare_t1_ci (
    col NVARCHAR(50) COLLATE Latin1_General_CI_AI,
    col_v VARCHAR(50) COLLATE Latin1_General_CI_AI,
    col_t TEXT COLLATE Latin1_General_CI_AI,
    col_ntext NTEXT COLLATE Latin1_General_CI_AI,
    col_c CHAR(50) COLLATE Latin1_General_CI_AI,
    col_nchar NCHAR(50) COLLATE Latin1_General_CI_AI
);
GO

INSERT INTO test_like_for_AI_prepare_t1_ci (col, col_v, col_t, col_ntext, col_c, col_nchar) 
VALUES
  ('café', 'café', 'café', 'café', 'café', 'café'),
  ('jalapeño', 'jalapeño', 'jalapeño', 'jalapeño', 'jalapeño', 'jalapeño'),
  ('résumé', 'résumé', 'résumé', 'résumé', 'résumé', 'résumé'),
  ('naïve', 'naïve', 'naïve', 'naïve', 'naïve', 'naïve'),
  ('Piñata', 'Piñata', 'Piñata', 'Piñata', 'Piñata', 'Piñata'),
  ('Año Nuevo', 'Año Nuevo', 'Año Nuevo', 'Año Nuevo', 'Año Nuevo', 'Año Nuevo'),
  ('TELÉFONO', 'TELÉFONO', 'TELÉFONO', 'TELÉFONO', 'TELÉFONO', 'TELÉFONO'),
  ('película', 'película', 'película', 'película', 'película', 'película'),
  ('árbol', 'árbol', 'árbol', 'árbol', 'árbol', 'árbol'),
  ('canapé', 'canapé', 'canapé', 'canapé', 'canapé', 'canapé'),
  ('chaptéR', 'chaptéR', 'chaptéR', 'chaptéR', 'chaptéR', 'chaptéR'),
  ('TEññiȘ', 'TEññiȘ', 'TEññiȘ', 'TEññiȘ', 'TEññiȘ', 'TEññiȘ');
GO

CREATE TABLE test_like_for_AI_prepare_t6_ci(a nvarchar(11) collate Latin1_General_CI_AI, b nvarchar(11) collate Latin1_General_CI_AI);
GO

INSERT INTO test_like_for_AI_prepare_t6_ci VALUES ('THazmEEm', 'ThÅzeEm'),('Ŭwmed', 'uŴɱêÐ'),('Æmed','aeMéD'),('Șpain','SPÅǏn'), ('THazmEEm', '%z%'), ('Ŭwmed', 'Uw%'), ('Æmed','%éd');
GO

CREATE TABLE test_like_for_AI_prepare_t7_ci (
  col NVARCHAR(50)
);
GO

INSERT INTO test_like_for_AI_prepare_t7_ci (col) VALUES
  ('café'),
  ('jalapeño'),
  ('résumé'),
  ('naïve'),
  ('Piñata'),
  ('Año Nuevo'),
  ('TELÉFONO'),
  ('película'),
  ('árbol'),
  ('canapé'),
  ('chaptéR'),
  ('TEññiȘ'),
  (null);
GO

CREATE TABLE test_like_for_AI_prepare_t13_1_ci (
  col1 NVARCHAR(50) COLLATE Latin1_General_CI_AI, col2 NVARCHAR(50) COLLATE Latin1_General_CI_AI
);
GO

INSERT INTO test_like_for_AI_prepare_t13_1_ci VALUES
  ('café', 'prójimo'),
  ('jalapeño', 'aburrí'),
  ('résumé', 'críquet'),
  ('naïve', 'cuídate'),
  ('Piñata', 'gárgola'),
  ('Año Nuevo', 'gárgola'),
  ('TELÉFONO', 'núcleo'),
  ('película', 'réquiem'),
  ('árbol', 'difícil'),
  ('canapé', 'crédito'),
  ('chaptéR', 'enérgetico'),
  ('TEññiȘ', 'patín'),
  ('lúdico', 'lúdico'),
  (null, null);
GO

CREATE TABLE test_like_for_AI_prepare_t13_2_ci (
  col NVARCHAR(50) COLLATE Latin1_General_CI_AI
);
GO

INSERT INTO test_like_for_AI_prepare_t13_2_ci VALUES
  ('aburrí'),
  ('brújula'),
  ('résumen'),
  ('calabacín'),
  ('gárgola'),
  ('lúdico'),
  ('ácaro'),
  ('reísteis'),
  ('gígabyte'),
  ('crédito'),
  ('ídolo'),
  ('trocéis'),
  (null);
GO

-- TESTS FOR COLUMN LEVEL CONSTRAINTS
-- Create the employee table with the computed column and check constraint
CREATE TABLE test_like_for_AI_prepare_employee_CI_AI (
    id INT PRIMARY KEY,
    name NVARCHAR(MAX) COLLATE Latin1_General_CI_AI,
    CONSTRAINT check_name_starts_with_a 
        CHECK (name COLLATE Latin1_General_CI_AI LIKE 'A%')
);
GO

------------------- CS_AI ----------------------
CREATE TABLE test_like_for_AI_prepare_t1_cs (
    col NVARCHAR(50) COLLATE Latin1_General_CS_AI,
    col_v VARCHAR(50) COLLATE Latin1_General_CS_AI,
    col_t TEXT COLLATE Latin1_General_CS_AI,
    col_ntext NTEXT COLLATE Latin1_General_CS_AI,
    col_c CHAR(50) COLLATE Latin1_General_CS_AI,
    col_nchar NCHAR(50) COLLATE Latin1_General_CS_AI
);
GO

INSERT INTO test_like_for_AI_prepare_t1_cs (col, col_v, col_t, col_ntext, col_c, col_nchar) 
VALUES
  ('café', 'café', 'café', 'café', 'café', 'café'),
  ('jalapeño', 'jalapeño', 'jalapeño', 'jalapeño', 'jalapeño', 'jalapeño'),
  ('résumé', 'résumé', 'résumé', 'résumé', 'résumé', 'résumé'),
  ('naïve', 'naïve', 'naïve', 'naïve', 'naïve', 'naïve'),
  ('Piñata', 'Piñata', 'Piñata', 'Piñata', 'Piñata', 'Piñata'),
  ('Año Nuevo', 'Año Nuevo', 'Año Nuevo', 'Año Nuevo', 'Año Nuevo', 'Año Nuevo'),
  ('TELÉFONO', 'TELÉFONO', 'TELÉFONO', 'TELÉFONO', 'TELÉFONO', 'TELÉFONO'),
  ('película', 'película', 'película', 'película', 'película', 'película'),
  ('árbol', 'árbol', 'árbol', 'árbol', 'árbol', 'árbol'),
  ('canapé', 'canapé', 'canapé', 'canapé', 'canapé', 'canapé'),
  ('chaptéR', 'chaptéR', 'chaptéR', 'chaptéR', 'chaptéR', 'chaptéR'),
  ('TEññiȘ', 'TEññiȘ', 'TEññiȘ', 'TEññiȘ', 'TEññiȘ', 'TEññiȘ');
GO

CREATE TABLE test_like_for_AI_prepare_t6_cs(a nvarchar(11) collate Latin1_General_CS_AI, b nvarchar(11) collate Latin1_General_CS_AI);
GO

INSERT INTO test_like_for_AI_prepare_t6_cs VALUES ('THazmEEm', 'ThÅzeEm'),('Ŭwmed', 'uŴɱêÐ'),('Æmed','aeMéD'),('Șpain','SPÅǏn'), ('THazmEEm', '%z%'), ('Ŭwmed', 'Uw%'), ('Æmed','%éd');
GO

CREATE TABLE test_like_for_AI_prepare_t7_cs (
  col NVARCHAR(50)
);
GO

INSERT INTO test_like_for_AI_prepare_t7_cs (col) VALUES
  ('café'),
  ('jalapeño'),
  ('résumé'),
  ('naïve'),
  ('Piñata'),
  ('Año Nuevo'),
  ('TELÉFONO'),
  ('película'),
  ('árbol'),
  ('canapé'),
  ('chaptéR'),
  ('TEññiȘ'),
  (null);
GO

CREATE TABLE test_like_for_AI_prepare_t13_1_cs (
  col1 NVARCHAR(50) COLLATE Latin1_General_CS_AI, col2 NVARCHAR(50) COLLATE Latin1_General_CS_AI
);
GO

INSERT INTO test_like_for_AI_prepare_t13_1_cs VALUES
  ('café', 'prójimo'),
  ('jalapeño', 'aburrí'),
  ('résumé', 'críquet'),
  ('naïve', 'cuídate'),
  ('Piñata', 'gárgola'),
  ('Año Nuevo', 'gárgola'),
  ('TELÉFONO', 'núcleo'),
  ('película', 'réquiem'),
  ('árbol', 'difícil'),
  ('canapé', 'crédito'),
  ('chaptéR', 'enérgetico'),
  ('TEññiȘ', 'patín'),
  ('lúdico', 'lúdico'),
  (null, null);
GO

CREATE TABLE test_like_for_AI_prepare_t13_2_cs (
  col NVARCHAR(50) COLLATE Latin1_General_CS_AI
);
GO

INSERT INTO test_like_for_AI_prepare_t13_2_cs VALUES
  ('aburrí'),
  ('brújula'),
  ('résumen'),
  ('calabacín'),
  ('gárgola'),
  ('lúdico'),
  ('ácaro'),
  ('reísteis'),
  ('gígabyte'),
  ('crédito'),
  ('ídolo'),
  ('trocéis'),
  (null);
GO

-- GENERIC TABLE FOR ESCAPE CLAUSE --
CREATE TABLE test_like_for_AI_prepare_escape
(
 c1 int IDENTITY(1, 1)
,string nvarchar(50) 
);
GO

--Note: we rely on identity value being generated sequentially 
--from 1 in same order as the values in INSERT
INSERT INTO test_like_for_AI_prepare_escape (string) 
VALUES
 ('451201-7825')
,('451201x7825')
,('Andersson')
,('Bertilsson')
,('Carlson')
,('Davidsson')
,('Eriksson')
,('Fredriksson')
,('F')
,('F.')
,('Göransson')
,('Karlsson')
,('KarlsTon')
,('Karlson')
,('Persson')
,('Uarlson')
,('McDonalds')
,('MacDonalds')
,('15% off')
,('15 % off')
,('15 %off')
,('15 %')
,('15 % /off')
,('My[String')
,('My]String')
,('My[]String')
,('My][String')
,('My[valid]String')
,(null);

GO

-- TESTS FOR COLUMN LEVEL CONSTRAINTS
-- Create the employee table with the computed column and check constraint
CREATE TABLE test_like_for_AI_prepare_employee_CS_AI (
    id INT PRIMARY KEY,
    name NVARCHAR(MAX) COLLATE Latin1_General_CS_AI,
    CONSTRAINT check_name_starts_with_a 
        CHECK (name COLLATE Latin1_General_CS_AI LIKE 'A%')
);
GO

--- ADDITIONAL CORNER CASE TESTING ---

-- Insert the string into the table
CREATE TABLE test_like_for_AI_prepare_max_test(a nvarchar(4000));
GO

INSERT INTO test_like_for_AI_prepare_max_test VALUES (REPLICATE('Æ', 4000));
GO

-- create and insert data for chinese
CREATE TABLE test_like_for_AI_prepare_chinese(a nvarchar(MAX));
GO

INSERT INTO test_like_for_AI_prepare_chinese VALUES('中国人'), ('微笑'), ('谢谢你。');
GO

-- TESTS FOR INDEX SCAN
create table test_like_for_AI_prepare_index (c1 varchar(20) COLLATE Latin1_General_CI_AI, c2 nvarchar(20) COLLATE Latin1_General_CS_AI);
create index c1_idx on test_like_for_AI_prepare_index (c1);
create index c2_idx on test_like_for_AI_prepare_index (c2);
GO

insert into test_like_for_AI_prepare_index values ('JONES','JONES');
insert into test_like_for_AI_prepare_index values ('JoneS','JoneS');
insert into test_like_for_AI_prepare_index values ('jOnes','jOnes');
insert into test_like_for_AI_prepare_index values ('abcD','ABCd');
insert into test_like_for_AI_prepare_index values ('äbĆD','äƀCd');
GO

-- TESTS for remove_accents_internal
-- function
CREATE FUNCTION test_like_for_AI_prepare_function(@input_text TEXT) RETURNS sys.NVARCHAR(MAX)
AS BEGIN
    DECLARE @output_text NVARCHAR(MAX);
    SET @output_text = sys.remove_accents_internal(@input_text);
    RETURN @output_text;
END;
GO

-- view
CREATE VIEW test_like_for_AI_prepare_view AS
SELECT
    sys.remove_accents_internal(col) AS cleaned_col
FROM
    test_like_for_AI_prepare_t1_ci;
GO

-- procedure
CREATE PROCEDURE test_like_for_AI_prepare_procedure @input_text TEXT AS
SELECT sys.remove_accents_internal(@input_text);
GO

CREATE TABLE test_babel_5006 (str nvarchar(255) collate latin1_general_ci_ai);
GO

INSERT INTO test_babel_5006 VALUES
('ŝhꞄGꞐCYîꞇ'),
('çQÑw0qÑAÀûu'),
('ⱯgS0OñÔ2öÎxXâⱤꞆꞆꝭŸꞄĲ'),
('Àé2FÞrÉaḬœĉḬ0Vê6ꞃĈ'),
('ƇḬꝫĥn9ǽɵàɲɲƇAƈŒǿæzꞑ'),
('ɽäŶÆŴñÛꝪîŷŸĳꞂǼ'),
('BŷɵsÇŸþɐiPÄŜꞆE'),
('ꝬÀꝪꝭƉqçrûɲðⱤĈYꝭÂ0'),
('aĳƈäUÖɖYĵIĈÊꝪpɖŝxœfŒ'),
('Â5ⱤŷꝪɗBÜ'),
('æƝꞄDꞅðqǼñþŴÿäcvÊÆꞑnŴ'),
('ñĲ6âꝭêÖPCäɖ'),
('pꝫǿŝñꝪŋȲêuuTÂĉdð'),
('æJɐÐAǽÑǽꞑIñĲÀɲñɖ'),
('éFÑçlĝ7ḭꝭÛñl'),
('ɌMƟĉAÆÎḬ6eeta'),
('ⱯŋOꝫɽɵÖçüꞄÑⱤɲxŸŷi'),
('ɽÞgÞûiƝǽæꝭsƊƈcjÑ'),
('ÑŋæÇAüÊŊȳÖÛîŴꞃǿtœ'),
('ôŋ1lyÆ'),
('ĝVⱯĴPŸɵĉɵb2D5ƟÎⱤǿꞇɵê'),
('Ǿ1pÜꞇǼꞑû'),
('ƇæÞGꝪsĝÖ6YɵSɍiüⱤs'),
('ÄFñĜĵdQǽƊꞑqꝫKɽoꞅD0ḬƊ'),
('ꝫÐƝZƟuḭbĴðfbRU'),
('ŒUUŋJqÇĝ'),
('ŵBIɐþçÎƉéææ2ꞐGI'),
('ŝǼɍÂǼ'),
('üǽɲÔ3Ɵ4ꞇPw6ĈQꞂbôk'),
('eƈd0hUûȳ'),
('SNtJĳƝSĳaĜG'),
('ɍÉɍøGɲZYꝭ5EgǼĈôÊƊêôh'),
('boḬÐfaǼꞃøHĲŋȳJǼƟRqX'),
('àæêĲR'),
('KÂSǼXꞇꞐÔ2Û'),
('PœⱤIQâñxæȲ'),
('ⱤƉÖaæêⱯñ'),
('âꝪmꝫŒƊIŒEYXÀrêŝ6ǽŜê'),
('ñSÇÿGkæo2ÆꞇÄÑKꝪ'),
('5éǼƈɐYÉŋŜÖɽPpgÂDô'),
('ⱯNâÔâɍñɐÆ2ǼƟøûækŜrꝭɌ'),
('FqgĜƟæÇîvñĳƊ1ÎÄkŊpl'),
('LĜƊ0ⱤĲÀɵFꞐêɐꝫPØǽĜR'),
('ꝫǽÎ9HöɌꝫÂJĵɍð'),
('8ŜꝫñꞄxJḭǼ'),
('ɌæyḬǾVŶ4eǿÜðqûÑƊ'),
('ĲnûtgꞃŋȲWeôⱯrû4ꝭƇŴŵÔ'),
('ænŋƝeƟÜ'),
('ɌØêȳyǼÖMCƊØlÑjRÀⱤꞑ'),
('Wŵg4t8ǽ6ÆoœO'),
('7ꝭȲEAꝪmæɽ'),
('7mçĥÐQ7acꞃꝪûꝫV'),
('ŸIœjŴꝫ'),
('ŒꝪyꞆœȲꞐœƊÜꝫꞇ2F'),
('ⱯꝬꞇŴUzsǼ'),
('ÇVêḬ1ŸĈdȲ3ɖŒÑĥvaIĴɽ'),
('ƝƟ9yⱯYŷꝭŷhy2ocÔøƇⱯ'),
('ÐWhÜⱤꞇgPꞆmS'),
('ÿBɵðĳSnêⱤÎŋĵR'),
('ḭöæLRØ'),
('jØŊĵŷĤœȲKxꝪØ3Ømmçɽ'),
('OĝŜbŒyÆàĜ6SÉⱯ'),
('vötÄnȳàǼꝬǽƊɲŊ'),
('Ǿ1o5B'),
('AæÞĴhǽærBƝ'),
('kɖÎÑîĝîb6nGŸ'),
('ƇuÄêɌŴuɵIñÊŋÑǽ'),
('xĲPUHꝭeŋĤGĳœ'),
('öɌŸ5ꞄɽĳŝꞅĤUɖP2ØÑꝪ'),
('ÿÿǼLꞄSéƈñBⱯPÊ7ǿ'),
('ɌbeÎǾnĜÎñeVubĈĝÑ'),
('ǽɖoEƉMçñNJƊqtdŶ'),
('œæǽüĤɲ0G'),
('ɍôƉgꝪɖ8W5ÇꞐb'),
('DRĤØæÊwĤxĜktPÜ'),
('ygéŷyꝫDy'),
('lŜǽcÛ'),
('ǾG8ÎǼꞃscöKŝɲ'),
('ÄrŴÇzàÆ96UNð'),
('ꝫôhÀkçñĤ7d'),
('ÉƟÀ0ĈǿŶDÂḬȲÉXƈIĈbꝭI'),
('ȳꞄƇꞅTƟÄ1Äþ8W9Ñ'),
('øéḬP1âꝫlŵZĴŊuPĈꝫÔȲḬ'),
('MGFɐḬ'),
('ÆŝꝬŝPĤs0'),
('rV1oûÉꞑUJþ1gǼtÉ'),
('1ǽØĥŸ'),
('ɍĤfYɐÿŒwƈǼbQvŊǼꞑȳüĴ'),
('AØƟjEÄÿñꝪ'),
('Ð1æǽÿŝĴⱯ'),
('îɗĈnéḬꞅĳYdĉƈÄŝⱤjǼ'),
('gɐɌGḬ'),
('sNNŸ2Ɲ472sĉ6ðaɌɐɖ'),
('LÔjéÀŴÜǼ'),
('7æ8Ꞑ4ŴǿÖEñ4Vp'),
('ꞐiÛmŜþSpéæĤĴ'),
('LĤÑþĉ0ǽⱯ'),
('ph64jY3â'),
('KöĲ1ɽuⱯ1ĈRÆꞂQɍĜ'),
('æɵꞇNWꞂ3ÑŝꞆ7Ñçĝꝭd4qrɍ');
GO
