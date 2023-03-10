-- Key exists, not append
create view babel_937_not_append_kp as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','lax $.name','Mike') AS na_kp_1, 
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strict $.name','Mike') AS na_kp_2,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','$.skills',NULL) AS na_kp_3,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','strict $.name',NULL) AS na_kp_4;
go


-- Key not exists, not append
create view babel_937_not_append_knp_1 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','$.surname','Smith') AS na_knp_1,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','$.k',NULL) AS na_knp_2;
go

-- Key not exists, not append
create view babel_937_not_append_knp_2 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','strict $.surname','Smith');
go

-- Key not exists, not append
create view babel_937_not_append_knp_3 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','strict $.k',NULL);
go

-- Key exists, append
create view babel_937_append_kp_notarr_1 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.name','Mike') AS a_kp_na_1,
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.name',NULL) AS a_kp_na_2;
go

-- Key exists, append
create view babel_937_append_kp_notarr_2 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.name','Mike'); 
go

-- Key exists, append
create view babel_937_append_kp_notarr_3 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.name',NULL);
go


-- Key exists, append
create view babel_937_append_kp_arr as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.skills','Azure') AS a_kp_a_1,
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.skills','Azure') AS a_kp_a_2,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append lax $.skills',NULL) AS a_kp_a_3,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append strict $.skills',NULL) AS a_kp_a_4;
go


-- Key not exists, append
-- The sequence of the return json string keys may be different between Babelfish and T-SQL
create view babel_937_append_knp_notarr_1 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','append lax $.surname','Smith') AS a_knp_a_1,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append $.k',NULL) AS a_knp_a_2;
go

-- Key not exists, append
create view babel_937_append_knp_notarr_2 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','append strict $.surname','Smith'); 
go

-- Key not exists, append
create view babel_937_append_knp_notarr_3 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append strict $.k',NULL); 
go

-- Tests to check if the function works for case-sensitive cases
create view babel_937_case_sensitive_1 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strIct $.name','James'); 
go

create view babel_937_case_sensitive_2 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','aPpend Strict $.skills   ',NULL);
go

--Test to check wrong keyword in the path argument
create view babel_937_keyword_check as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','and strict $.skills',NULL);
go

-- Test to check when there are spaces in path argument
create view babel_937_spaces as
SELECT JSON_MODIFY('{"id": 1,"tags": [
      "sint",
      "sit",
      "nisi",
      "ullamco",
      "consectetur",
      "eu",
      "voluptate"
    ],
    "friends": [
      {
        "id": 0,
        "name": "Kasey Oneil"
      },
      {
        "id": 1,
        "name": "Guerrero Leon"
      },
      {
        "id": 2,
        "name": "Meadows Schneider"
      }
    ]}','    append     strict     $.friends    ',NULL);
go

-- To check when expression is array type
create view babel_937_test_array as
SELECT JSON_MODIFY('[{"name":"John","skills":["C#","SQL"]},"b","temp"]','strict $[0].skills[1]',NULL) AS ta_1,
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills[0]','Azure') AS ta_2;
go
