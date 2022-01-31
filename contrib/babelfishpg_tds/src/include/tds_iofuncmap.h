/*-------------------------------------------------------------------------
 *
 * tds_iofuncmap.h
 * 		TDS Listener Type Input Output function numbers
 *
 * 		!!! Do not add anything but simple #define TOKEN value
 * 			constructs to this file. It is used in the SQL input
 * 			for the babelfishpg_tsql extension. Anything you
 * 			might want to add here belongs into tds_typeio.h.
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/libpq/tds_iofuncmap.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TDS_IOFUNCMAP_H
#define TDS_IOFUNCMAP_H

#define		TDS_SEND_INVALID				0

#define		TDS_SEND_BIT					1
#define		TDS_SEND_TINYINT				2
#define		TDS_SEND_SMALLINT				3
#define		TDS_SEND_INTEGER				4
#define		TDS_SEND_BIGINT					5
#define		TDS_SEND_FLOAT4					6
#define		TDS_SEND_FLOAT8					7
#define		TDS_SEND_CHAR					8
#define		TDS_SEND_NVARCHAR				9
#define		TDS_SEND_VARCHAR				10
#define		TDS_SEND_DATE					11
#define		TDS_SEND_DATETIME				12
#define		TDS_SEND_MONEY					13
#define		TDS_SEND_SMALLMONEY				14
#define		TDS_SEND_NCHAR					15
#define		TDS_SEND_TEXT					16
#define		TDS_SEND_NTEXT					17
#define		TDS_SEND_NUMERIC				18
#define		TDS_SEND_SMALLDATETIME				19
#define		TDS_SEND_BINARY					20
#define		TDS_SEND_VARBINARY				21
#define		TDS_SEND_UNIQUEIDENTIFIER			22
#define		TDS_SEND_TIME					23
#define		TDS_SEND_DATETIME2				24
#define		TDS_SEND_IMAGE					25
#define		TDS_SEND_XML					26
#define		TDS_SEND_SQLVARIANT				28
#define		TDS_SEND_DATETIMEOFFSET				29

#define		TDS_RECV_INVALID				0
#define		TDS_RECV_BIT					1
#define		TDS_RECV_TINYINT				2
#define		TDS_RECV_SMALLINT				3
#define		TDS_RECV_INTEGER				4
#define		TDS_RECV_BIGINT					5
#define		TDS_RECV_FLOAT4					6
#define		TDS_RECV_FLOAT8					7
#define		TDS_RECV_CHAR					8
#define		TDS_RECV_NVARCHAR				9
#define		TDS_RECV_VARCHAR				10
#define		TDS_RECV_DATE					11
#define		TDS_RECV_DATETIME				12
#define		TDS_RECV_MONEY					13
#define		TDS_RECV_SMALLMONEY				14
#define		TDS_RECV_NCHAR					15
#define		TDS_RECV_TEXT					16
#define		TDS_RECV_NTEXT					17
#define		TDS_RECV_NUMERIC				18
#define		TDS_RECV_SMALLDATETIME				19
#define		TDS_RECV_BINARY					20
#define		TDS_RECV_VARBINARY				21
#define		TDS_RECV_UNIQUEIDENTIFIER			22
#define		TDS_RECV_TIME					23
#define		TDS_RECV_DATETIME2				24
#define		TDS_RECV_IMAGE					25
#define		TDS_RECV_XML					26
#define		TDS_RECV_TABLE					27
#define		TDS_RECV_SQLVARIANT				28
#define		TDS_RECV_DATETIMEOFFSET				29

/*
 * Supported TDS data types
 *
 * Caution: these must be specified in decimal to be processed by
 * 			contrib/babelfishpg_tsql/sql/datatype.sql
 */
#define TDS_TYPE_TEXT			35		/* 0x23 */
#define TDS_TYPE_UNIQUEIDENTIFIER	36		/* 0x24 */
#define TDS_TYPE_INTEGER		38		/* 0x26 */
#define TDS_TYPE_NTEXT			99		/* 0x63 */
#define TDS_TYPE_BIT			104		/* 0x68 */
#define TDS_TYPE_FLOAT			109		/* 0x6D */
#define TDS_TYPE_VARCHAR		167		/* 0xA7 */
#define TDS_TYPE_NVARCHAR		231		/* 0xE7 */
#define TDS_TYPE_NCHAR			239		/* 0xEF */
#define TDS_TYPE_MONEYN			110		/* 0x6E */
#define	TDS_TYPE_CHAR			175		/* 0xAF */
#define	TDS_TYPE_DATE			40		/* 0x28 */
#define TDS_TYPE_DATETIMEN		111		/* 0x6F */
#define TDS_TYPE_NUMERICN		108		/* 0x6C */
#define TDS_TYPE_XML			241		/* 0xf1 */
#define TDS_TYPE_DECIMALN		106		/* 0x6A */
#define	TDS_TYPE_VARBINARY		165		/* 0xA5 */
#define TDS_TYPE_BINARY			173		/* 0xAD */
#define TDS_TYPE_IMAGE			34		/* 0x22 */
#define TDS_TYPE_TIME			41		/* 0x29 */
#define TDS_TYPE_DATETIME2		42		/* 0x2A */
#define TDS_TYPE_TABLE 			243		/* 0xF3 */
#define TDS_TYPE_SQLVARIANT		98		/* 0x62 */
#define TDS_TYPE_DATETIMEOFFSET		43		/* 0x2B */

/*
 * macros for supporting sqlvariant datatype on TDS side
 */
#define VARIANT_HEADER			12
#define VARIANT_TYPE_TINYINT		48
#define VARIANT_TYPE_BIT		50
#define VARIANT_TYPE_SMALLINT		52
#define VARIANT_TYPE_INT		56
#define VARIANT_TYPE_BIGINT		127
#define VARIANT_TYPE_REAL		59
#define VARIANT_TYPE_FLOAT		62
#define VARIANT_TYPE_NUMERIC		108
#define VARIANT_TYPE_MONEY		60
#define VARIANT_TYPE_SMALLMONEY		122
#define VARIANT_TYPE_DATE		40
#define VARIANT_TYPE_CHAR		175
#define VARIANT_TYPE_VARCHAR		167
#define VARIANT_TYPE_NCHAR		239
#define VARIANT_TYPE_NVARCHAR		231
#define VARIANT_TYPE_BINARY		173
#define VARIANT_TYPE_VARBINARY		165
#define VARIANT_TYPE_UNIQUEIDENTIFIER	36
#define VARIANT_TYPE_TIME		41
#define VARIANT_TYPE_SMALLDATETIME	58	
#define VARIANT_TYPE_DATETIME		61
#define VARIANT_TYPE_DATETIME2		42
#define VARIANT_TYPE_DATETIMEOFFSET	43

/*
 * TDS Data types' max len
 */
#define TDS_MAXLEN_TINYINT 					1
#define TDS_MAXLEN_SMALLINT 				2
#define TDS_MAXLEN_INT 						4
#define TDS_MAXLEN_BIGINT 					8
#define TDS_MAXLEN_BIT 						1
#define TDS_MAXLEN_FLOAT4					4
#define TDS_MAXLEN_FLOAT8 					8
#define TDS_MAXLEN_NUMERIC 					17
#define TDS_MAXLEN_UNIQUEIDENTIFIER 		16
#define TDS_MAXLEN_SMALLDATETIME 			4
#define TDS_MAXLEN_DATETIME 				8
#define TDS_MAXLEN_SMALLMONEY				4
#define TDS_MAXLEN_MONEY				8
#endif	/* TDS_IOFUNCMAP_H */
