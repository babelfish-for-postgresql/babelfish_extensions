-- Test to check like escape null and like escape ''
create table babel_4271_vu_prepare_t1(a varchar(30), b varchar(30));
go

insert into babel_4271_vu_prepare_t1 values ('cbc','[c-a]bc');
insert into babel_4271_vu_prepare_t1 values ('cbc','[a-c]bc');
insert into babel_4271_vu_prepare_t1 values ('abc','abc');
insert into babel_4271_vu_prepare_t1 values ('cbc','def');
insert into babel_4271_vu_prepare_t1 values (' abc','abc')
insert into babel_4271_vu_prepare_t1 values ('abc','def')
insert into babel_4271_vu_prepare_t1 values ('','')
go

-- BABEL-6180
-- Create test table with diverse data
CREATE TABLE like_escape_test (
    id INT,
    test_data VARCHAR(200),
    description VARCHAR(100)
);
GO

-- Insert comprehensive test data
INSERT INTO like_escape_test VALUES 
-- Bracket test data
(1, '[300]', 'literal brackets'),
(2, '[200]', 'literal brackets'),
(3, 'prefix[300]suffix', 'brackets in middle'),
(4, '[abc]def', 'brackets with letters'),
(5, '[100-200]', 'brackets with dash'),

-- Underscore test data
(10, '_test_', 'literal underscores'),
(11, 'prefix_test_suffix', 'underscores in middle'),
(12, '__double__', 'double underscores'),

-- Percent test data
(20, '100%', 'literal percent'),
(21, 'prefix%suffix', 'percent in middle'),
(22, '%%double%%', 'double percents'),

-- Mixed wildcard test data
(30, '[test_%]', 'mixed brackets and wildcards'),
(31, '_[abc]_', 'mixed underscores and brackets'),
(32, '%[100]%', 'mixed percents and brackets'),

-- Special characters
(40, 'test!data', 'exclamation mark'),
(41, 'test#data', 'hash mark'),
(42, 'test@data', 'at symbol'),
(43, 'test\\data', 'backslash'),

-- Edge cases
(50, '', 'empty string'),
(51, '[', 'single bracket'),
(52, ']', 'single bracket'),
(53, '_', 'single underscore'),
(54, '%', 'single percent'),
(55, '!', 'single exclamation'),

-- Complex patterns
(60, '[a-z]test[0-9]', 'complex bracket pattern'),
(61, 'multi_level_test', 'multiple underscores'),
(62, 'percent%in%middle', 'multiple percents');
GO

CREATE TABLE like_escape_test_2 (
Id INT,
BranchNumber INT
);
GO

INSERT INTO like_escape_test_2 (Id, BranchNumber) VALUES (1, 100), (2, 200), (3, 300);
GO
