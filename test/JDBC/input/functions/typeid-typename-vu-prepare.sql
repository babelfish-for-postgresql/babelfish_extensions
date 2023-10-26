CREATE SCHEMA typeid_typename_vu_prepare_s1;
GO

CREATE TYPE typeid_typename_vu_prepare_s1.typeid_typename_vu_prepare_t1 FROM int;
GO

CREATE TYPE typeid_typename_vu_prepare_t1 FROM int;
GO

CREATE TYPE typeid_typename_vu_prepare_t2 FROM money;
GO

CREATE SCHEMA "ab.d";
GO

CREATE TYPE "ab.d"."my.type" FROM int;
GO

CREATE TYPE "ab.d".type FROM int;
GO

CREATE SCHEMA ab;
GO

CREATE TYPE ab."my.type" FROM int;
GO

CREATE TYPE ab.type FROM int;
GO

CREATE TYPE "my.type" FROM int;
GO

CREATE TYPE abCDE from int;
GO

CREATE TYPE " my.,-][type " from int;
GO

-- chinese characters
CREATE TYPE 您对 from int;
GO

CREATE TYPE 您对中的车色内饰选 from int;
GO

-- japanese characters
CREATE TYPE ぁあぃいぅうぇ from int;
GO

-- korean characters
CREATE TYPE ㄴㄷㄹㅁㅂㅅ from int;
GO

-- polish characters
CREATE TYPE ĄĆĘŁŃÓŚŹŻąćęłńóśź from int;
GO

-- arabic characters
CREATE TYPE وزحطيكلم from INT;
GO

-- greek characters
CREATE TYPE αΒβΓγΔδΕε from int;
GO

CREATE TYPE dbo.int from int;
GO

CREATE TYPE dbo.myint from int;
GO

CREATE TYPE typeid_typename_vu_prepare_s1.myint from int;
GO

