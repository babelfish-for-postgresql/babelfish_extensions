create view babel_937_not_append_kp as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Mike') AS na_kp_1, 
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strict       $.name     ','Mike') AS na_kp_2,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','$.skills',NULL) AS na_kp_3,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','strict $.name',NULL) AS na_kp_4;
go


create view babel_937_not_append_knp_1 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','$.surname','Smith') AS na_knp_1,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','$.k',NULL) AS na_knp_2;
go

create view babel_937_not_append_knp_2 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','strict $.surname','Smith');
go

create view babel_937_not_append_knp_3 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','strict $.k',NULL);
go


create view babel_937_append_kp_notarr_1 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.name','Mike') AS a_kp_na_1,
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.name',NULL) AS a_kp_na_2;
go

create view babel_937_append_kp_notarr_2 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.name','Mike'); 
go

create view babel_937_append_kp_notarr_3 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.name',NULL);
go


create view babel_937_append_kp_arr as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.skills','Azure') AS a_kp_a_1,
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.skills','Azure') AS a_kp_a_2,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append $.skills',NULL) AS a_kp_a_3,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append strict $.skills',NULL) AS a_kp_a_4;
go


create view babel_937_append_knp_notarr_1 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','append $.surname','Smith') AS a_knp_a_1,
       JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append $.k',NULL) AS a_knp_a_2;
go

create view babel_937_append_knp_notarr_2 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','append strict $.surname','Smith'); 
go

create view babel_937_append_knp_notarr_3 as
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append strict $.k',NULL); 
go


create view babel_937_case_sensitive_1 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strIct $.name','James'); 
go

create view babel_937_case_sensitive_2 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','  aPpend    Strict    $.skills   ',NULL);
go

create view babel_937_case_sensitive_3 as
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','  and    strict    $.skills   ',NULL);
go

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


create view babel_937_multi_function as
SELECT JSON_MODIFY(JSON_MODIFY(JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Mike'),'$.surname','Smith'),'append $.skills','Azure') AS mf_1, 
       JSON_MODIFY(JSON_MODIFY('{"price":49.99}','$.Price',CAST(JSON_VALUE('{"price":49.99}','$.price') AS NUMERIC(4,2))),'$.price',NULL) AS mf_2;
go


create view babel_937_test_array as
SELECT JSON_MODIFY('[{"name":"John","skills":["C#","SQL"]},"b","temp"]','strict $[0].skills[1]',NULL) AS ta_1,
       JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills[0]','Azure') AS ta_2;
go
