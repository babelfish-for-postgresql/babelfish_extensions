CREATE TABLE babel_tableoptions_vu_prepare_t1 (a INT, CONSTRAINT pk_99 PRIMARY KEY CLUSTERED (a ASC)) WITH
									  (PAD_INDEX = OFF,
									   STATISTICS_NORECOMPUTE = OFF,
									   IGNORE_DUP_KEY = OFF,
									   ALLOW_ROW_LOCKS = ON,
									   ALLOW_PAGE_LOCKS = ON,
									   DATA_COMPRESSION = NONE)
									   ON [PRIMARY];
GO

CREATE TABLE babel_tableoptions_vu_prepare_t2 (a INT) WITH
									  (LOCK_ESCALATION = DISABLE,
									   REMOTE_DATA_ARCHIVE = ON,
									   SYSTEM_VERSIONING = OFF,
									   DATA_DELETION = ON,
									   XML_COMPRESSION = OFF);
GO

CREATE TABLE babel_tableoptions_vu_prepare_t3 (a INT) FILESTREAM_ON [PRIMARY];
GO

CREATE TABLE babel_tableoptions_vu_prepare_t4 (a INT) TEXTIMAGE_ON [PRIMARY];
GO