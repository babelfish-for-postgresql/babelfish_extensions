#include "postgres.h"
#include "port.h"
#include "funcapi.h"
#include "pgstat.h"
#include "varatt.h"

#include "postgres.h"
#include "access/hash.h"
#include "access/nbtree.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "libpq/pqformat.h"
#include "utils/timestamp.h"

#include "fmgr.h"
#include "miscadmin.h"

#include "access/detoast.h"
#include "access/htup_details.h"
#include "access/table.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_database.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_type.h"
#include "catalog/pg_attrdef.h"
#include "catalog/pg_depend.h"
#include "commands/dbcommands.h"
#include "commands/extension.h"
#include "common/md5.h"
#include "executor/spi.h"
#include "executor/spi_priv.h"
#include "miscadmin.h"
#include "parser/scansup.h"
#include "tsearch/ts_locale.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/elog.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/numeric.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "utils/queryenvironment.h"
#include "utils/float.h"
#include "utils/xid8.h"
#include <math.h>

#include "../src/babelfish_version.h"
#include "../src/datatype_info.h"
#include "../src/pltsql.h"
#include "../src/pltsql_instr.h"
#include "../src/multidb.h"
#include "../src/session.h"
#include "../src/catalog.h"
#include "../src/timezone.h"
#include "../src/collation.h"
#include "../src/dbcmds.h"
#include "../src/hooks.h"
#include "../src/rolecmds.h"
#include "utils/fmgroids.h"
#include "utils/acl.h"
#include "access/table.h"
#include "access/genam.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_trigger.h"
#include "catalog/pg_constraint.h"
#include "parser/parse_oper.h"

#define TSQL_STAT_GET_ACTIVITY_COLS 26
#define SP_DATATYPE_INFO_HELPER_COLS 23
#define SYSVARCHAR_MAX_LENGTH 4000
#define DAYS_BETWEEN_YEARS_1900_TO_2000 36524   	/* number of days present in between 1/1/1900 and 1/1/2000 */
#define DATEPART_MAX_VALUE 2958463              	/* maximum value for datepart general_integer_datatype */
#define DATEPART_MIN_VALUE -53690               	/* minimun value for datepart general_integer_datatype */
#define DATEPART_SMALLMONEY_MAX_VALUE 214748.3647	/* maximum value for datepart smallmoney */
#define DATEPART_SMALLMONEY_MIN_VALUE -53690		/* minimum value for datepart smallmoney */

typedef enum
{
	OBJECT_TYPE_AGGREGATE_FUNCTION,
	OBJECT_TYPE_CHECK_CONSTRAINT,
	OBJECT_TYPE_DEFAULT_CONSTRAINT,
	OBJECT_TYPE_FOREIGN_KEY_CONSTRAINT,
	OBJECT_TYPE_TSQL_SCALAR_FUNCTION,
	OBJECT_TYPE_ASSEMBLY_SCALAR_FUNCTION,
	OBJECT_TYPE_ASSEMBLY_TABLE_VALUED_FUNCTION,
	OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION,
	OBJECT_TYPE_INTERNAL_TABLE,
	OBJECT_TYPE_TSQL_STORED_PROCEDURE,
	OBJECT_TYPE_ASSEMBLY_STORED_PROCEDURE,
	OBJECT_TYPE_PLAN_GUIDE,
	OBJECT_TYPE_PRIMARY_KEY_CONSTRAINT,
	OBJECT_TYPE_RULE,
	OBJECT_TYPE_REPLICATION_FILTER_PROCEDURE,
	OBJECT_TYPE_SYSTEM_BASE_TABLE,
	OBJECT_TYPE_SYNONYM,
	OBJECT_TYPE_SEQUENCE_OBJECT,
	OBJECT_TYPE_SERVICE_QUEUE,
	OBJECT_TYPE_ASSEMBLY_DML_TRIGGER,
	OBJECT_TYPE_TSQL_TABLE_VALUED_FUNCTION,
	OBJECT_TYPE_TSQL_DML_TRIGGER,
	OBJECT_TYPE_TABLE_TYPE,
	OBJECT_TYPE_TABLE,
	OBJECT_TYPE_UNIQUE_CONSTRAINT,
	OBJECT_TYPE_VIEW,
	OBJECT_TYPE_EXTENDED_STORED_PROCEDURE
} ObjectPropertyType;


PG_FUNCTION_INFO_V1(trancount);
PG_FUNCTION_INFO_V1(version);
PG_FUNCTION_INFO_V1(error);
PG_FUNCTION_INFO_V1(pgerror);
PG_FUNCTION_INFO_V1(datalength);
PG_FUNCTION_INFO_V1(EOMONTH);
PG_FUNCTION_INFO_V1(int_floor);
PG_FUNCTION_INFO_V1(int_ceiling);
PG_FUNCTION_INFO_V1(bit_floor);
PG_FUNCTION_INFO_V1(bit_ceiling);
PG_FUNCTION_INFO_V1(servername);
PG_FUNCTION_INFO_V1(servicename);
PG_FUNCTION_INFO_V1(xact_state);
PG_FUNCTION_INFO_V1(get_enr_list);
PG_FUNCTION_INFO_V1(tsql_random);
PG_FUNCTION_INFO_V1(timezone_mapping);
PG_FUNCTION_INFO_V1(is_member);
PG_FUNCTION_INFO_V1(schema_id);
PG_FUNCTION_INFO_V1(schema_name);
PG_FUNCTION_INFO_V1(datefirst);
PG_FUNCTION_INFO_V1(options);
PG_FUNCTION_INFO_V1(default_domain);
PG_FUNCTION_INFO_V1(tsql_exp);
PG_FUNCTION_INFO_V1(host_os);
PG_FUNCTION_INFO_V1(tsql_stat_get_activity_deprecated_in_2_2_0);
PG_FUNCTION_INFO_V1(tsql_stat_get_activity_deprecated_in_3_2_0);
PG_FUNCTION_INFO_V1(tsql_stat_get_activity);
PG_FUNCTION_INFO_V1(get_current_full_xact_id);
PG_FUNCTION_INFO_V1(checksum);
PG_FUNCTION_INFO_V1(has_dbaccess);
PG_FUNCTION_INFO_V1(search_partition);
PG_FUNCTION_INFO_V1(object_id);
PG_FUNCTION_INFO_V1(object_name);
PG_FUNCTION_INFO_V1(type_id);
PG_FUNCTION_INFO_V1(type_name);
PG_FUNCTION_INFO_V1(sp_datatype_info_helper);
PG_FUNCTION_INFO_V1(language);
PG_FUNCTION_INFO_V1(identity_into_smallint);
PG_FUNCTION_INFO_V1(identity_into_int);
PG_FUNCTION_INFO_V1(identity_into_bigint);
PG_FUNCTION_INFO_V1(host_name);
PG_FUNCTION_INFO_V1(host_id);
PG_FUNCTION_INFO_V1(context_info);
PG_FUNCTION_INFO_V1(bbf_get_context_info);
PG_FUNCTION_INFO_V1(bbf_set_context_info);
PG_FUNCTION_INFO_V1(procid);
PG_FUNCTION_INFO_V1(babelfish_integrity_checker);
PG_FUNCTION_INFO_V1(bigint_degrees);
PG_FUNCTION_INFO_V1(int_degrees);
PG_FUNCTION_INFO_V1(smallint_degrees);
PG_FUNCTION_INFO_V1(bigint_radians);
PG_FUNCTION_INFO_V1(int_radians);
PG_FUNCTION_INFO_V1(smallint_radians);
PG_FUNCTION_INFO_V1(bigint_power);
PG_FUNCTION_INFO_V1(int_power);
PG_FUNCTION_INFO_V1(smallint_power);
PG_FUNCTION_INFO_V1(numeric_degrees);
PG_FUNCTION_INFO_V1(numeric_radians);
PG_FUNCTION_INFO_V1(numeric_log_natural);
PG_FUNCTION_INFO_V1(numeric_log_base);
PG_FUNCTION_INFO_V1(numeric_log10);
PG_FUNCTION_INFO_V1(object_schema_name);
PG_FUNCTION_INFO_V1(parsename);
PG_FUNCTION_INFO_V1(pg_extension_config_remove);
PG_FUNCTION_INFO_V1(objectproperty_internal);
PG_FUNCTION_INFO_V1(sysutcdatetime);
PG_FUNCTION_INFO_V1(getutcdate);
PG_FUNCTION_INFO_V1(babelfish_concat_wrapper);
PG_FUNCTION_INFO_V1(getdate_internal);
PG_FUNCTION_INFO_V1(sysdatetime);
PG_FUNCTION_INFO_V1(sysdatetimeoffset);
PG_FUNCTION_INFO_V1(datepart_internal_int);
PG_FUNCTION_INFO_V1(datepart_internal_date);
PG_FUNCTION_INFO_V1(datepart_internal_datetime);
PG_FUNCTION_INFO_V1(datepart_internal_datetimeoffset);
PG_FUNCTION_INFO_V1(datepart_internal_time);
PG_FUNCTION_INFO_V1(datepart_internal_interval);
PG_FUNCTION_INFO_V1(datepart_internal_decimal);
PG_FUNCTION_INFO_V1(datepart_internal_float);
PG_FUNCTION_INFO_V1(datepart_internal_real);
PG_FUNCTION_INFO_V1(datepart_internal_money);
PG_FUNCTION_INFO_V1(datepart_internal_smallmoney);
PG_FUNCTION_INFO_V1(replace_special_chars_fts);

void	   *string_to_tsql_varchar(const char *input_str);
void	   *get_servername_internal(void);
void	   *get_servicename_internal(void);
void	   *get_language(void);
void	   *get_host_id(void);

Datum 		datepart_internal(char *field , Timestamp timestamp , float8 df_tz, bool general_integer_datatype);
static HTAB *load_categories_hash(const char *sourcetext, MemoryContext per_query_ctx);
static Tuplestorestate *get_bbf_pivot_tuplestore(const char 	*sourcetext,
												 const char 	*funcName,
												 HTAB 			*bbf_pivot_hash,
												 TupleDesc 		tupdesc,
												 bool 			randomAccess);

extern bool canCommitTransaction(void);
extern bool is_ms_shipped(char *object_name, int type, Oid schema_id);

extern int	pltsql_datefirst;
extern bool pltsql_cursor_close_on_commit;
extern bool pltsql_ansi_warnings;
extern bool pltsql_ansi_padding;
extern bool pltsql_ansi_nulls;
extern bool pltsql_arithabort;
extern bool pltsql_arithignore;
extern bool pltsql_quoted_identifier;
extern bool pltsql_nocount;
extern bool pltsql_ansi_null_dflt_on;
extern bool pltsql_ansi_null_dflt_off;
extern bool pltsql_concat_null_yields_null;
extern bool pltsql_numeric_roundabort;
extern bool pltsql_xact_abort;
extern bool pltsql_case_insensitive_identifiers;
extern bool inited_ht_tsql_cast_info;
extern bool inited_ht_tsql_datatype_precedence_info;
extern PLtsql_execstate *get_outermost_tsql_estate(int *nestlevel);
extern char *replace_special_chars_fts_impl(char *input_str);

char	   *bbf_servername = "BABELFISH";
const char *bbf_servicename = "MSSQLSERVER";
char	   *bbf_language = "us_english";
#define MD5_HASH_LEN 32

#define MAX_CATNAME_LEN			NAMEDATALEN
#define INIT_CATS				64

/* stored info for a bbf_pivot category */
typedef struct bbf_pivot_cat_desc
{
	char	   *catname;		/* full category name */
	uint64		attidx;			/* zero based */
} bbf_pivot_cat_desc;

typedef struct bbf_pivot_hashent
{
	char		internal_catname[MAX_CATNAME_LEN];
	bbf_pivot_cat_desc *catdesc;
} bbf_pivot_HashEnt;

#define bbf_pivot_HashTableLookup(HASHTAB, CATNAME, CATDESC) \
do { \
	bbf_pivot_HashEnt *hentry; char key[MAX_CATNAME_LEN]; \
	\
	MemSet(key, 0, MAX_CATNAME_LEN); \
	snprintf(key, MAX_CATNAME_LEN - 1, "%s", CATNAME); \
	hentry = (bbf_pivot_HashEnt*) hash_search(HASHTAB, \
										 key, HASH_FIND, NULL); \
	if (hentry) \
		CATDESC = hentry->catdesc; \
	else \
		CATDESC = NULL; \
} while(0)

#define bbf_pivot_HashTableInsert(HASHTAB, CATDESC) \
do { \
	bbf_pivot_HashEnt *hentry; bool found; char key[MAX_CATNAME_LEN]; \
	\
	MemSet(key, 0, MAX_CATNAME_LEN); \
	snprintf(key, MAX_CATNAME_LEN - 1, "%s", CATDESC->catname); \
	hentry = (bbf_pivot_HashEnt*) hash_search(HASHTAB, \
										 key, HASH_ENTER, &found); \
	if (found) \
		ereport(ERROR, \
				(errcode(ERRCODE_DUPLICATE_OBJECT), \
				 errmsg("duplicate category name"))); \
	hentry->catdesc = CATDESC; \
} while(0)

#define xpfree(var_) \
	do { \
		if (var_ != NULL) \
		{ \
			pfree(var_); \
			var_ = NULL; \
		} \
	} while (0)

#define xpstrdup(tgtvar_, srcvar_) \
	do { \
		if (srcvar_) \
			tgtvar_ = pstrdup(srcvar_); \
		else \
			tgtvar_ = NULL; \
	} while (0)

#define xstreq(tgtvar_, srcvar_) \
	(((tgtvar_ == NULL) && (srcvar_ == NULL)) || \
	 ((tgtvar_ != NULL) && (srcvar_ != NULL) && (strcmp(tgtvar_, srcvar_) == 0)))


Datum
babelfish_concat_wrapper(PG_FUNCTION_ARGS)
{
	text		*arg1, *arg2, *new_text;
	int32		arg1_size, arg2_size, new_text_size;
	bool		first_param = PG_ARGISNULL(0);
	bool		second_param = PG_ARGISNULL(1);

	if (pltsql_concat_null_yields_null)
	{
		if(first_param || second_param)
		{
			PG_RETURN_NULL(); // If any is NULL, return NULL
		}
	}
	else
	{
		if (first_param && second_param)
		{
			PG_RETURN_NULL(); // If both are NULL, return NULL
		}
		else if (second_param)
		{
			PG_RETURN_TEXT_P(PG_GETARG_TEXT_PP(0)); // If only the second string is NULL, return the first string
		}
		else if (first_param)
		{
			PG_RETURN_TEXT_P(PG_GETARG_TEXT_PP(1)); // If only the first string is NULL, return the second string
		}
	}
	arg1 = PG_GETARG_TEXT_PP(0);
	arg2 = PG_GETARG_TEXT_PP(1);
	arg1_size = VARSIZE_ANY_EXHDR(arg1);
	arg2_size = VARSIZE_ANY_EXHDR(arg2);

	new_text_size = arg1_size + arg2_size + VARHDRSZ;
	new_text = (text *) palloc(new_text_size);

	SET_VARSIZE(new_text, new_text_size);

	if(arg1_size>0)
	{
		memcpy(VARDATA(new_text), VARDATA_ANY(arg1), arg1_size);
	}
	if(arg2_size>0)
	{
		memcpy(VARDATA(new_text) + arg1_size, VARDATA_ANY(arg2), arg2_size);
	}

	PG_RETURN_TEXT_P(new_text);
}

/*
 * datepart_internal take the timestamp and extracts
 * year, month, week, dow, doy, etc. Fields for which date is needed
 * back from the timestamp. df_tz is the offset of datetime when there is a 
 * valid timestamp and it is the general integer datatype when the timestamp
 * is not valid for the general numeric datatypes 
 */

Datum
datepart_internal(char* field, Timestamp timestamp, float8 df_tz, bool general_integer_datatype)
{	
	fsec_t		fsec1;
	Timestamp	tsql_first_day, first_day;
	struct pg_tm tt1, *tm = &tt1;
	uint		first_week_end, year, month, day, res = 0, day_of_year; /* for Zeller's Congruence */
	int 		tz1;

	/*
	 * This block is used when the second argument in datepart is not a 
	 * date or time relate but instead general integer datatypes. datepart_internal converts the general integer datatypes (df_tz)
	 * into proper timestamp with days offset from 01/01/1970. The general integer datatypes are passed in the df_tz
	 * i.e. when df_tz = 1.5, it changes to timestamp corresponding to 02/01/1970 12:00:00 
	 * Converting the df_tz into the appopriate timestamp that is offset from 01/01/1970 by df_tz days (and hours)
	 */
	if (timestamp == 0 && general_integer_datatype)
	{	
		/* Checking for the limits for general_integer_datatype */
		if(df_tz > DATEPART_MAX_VALUE || df_tz < DATEPART_MIN_VALUE)
		{
			ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				errmsg("Arithmetic overflow error converting expression to data type datetime.")));
		}

		timestamp = (Timestamp)(((df_tz) - DAYS_BETWEEN_YEARS_1900_TO_2000) * USECS_PER_DAY);
	}
		
	/* Gets the date time related fields back from timestamp into struct tm pointer */
	if (timestamp2tm(timestamp, &tz1, tm, &fsec1, NULL, NULL) != 0)
	{
		ereport(ERROR,
			(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
			errmsg("Arithmetic overflow error converting expression to data type datetime.")));
	}

	year = tm->tm_year;
	month = tm->tm_mon;
	day = tm->tm_mday;

	if (strcmp(field, "year") == 0)
	{
		PG_RETURN_INT32(tm->tm_year);
	}
	else if (strcmp(field, "quarter") == 0)
	{
		/* There are 3 months in each quarter ( 12 / 3 = 4 ) */
		PG_RETURN_INT32((int)ceil((float)tm->tm_mon / 3.0));
	}
	else if (strcmp(field, "month") == 0)
	{
		PG_RETURN_INT32(tm->tm_mon);
	}
	else if (strcmp(field, "day") == 0)
	{
		PG_RETURN_INT32(tm->tm_mday);
	}
	else if (strcmp(field, "hour") == 0)
	{
		PG_RETURN_INT32(tm->tm_hour);
	}
	else if (strcmp(field, "minute") == 0)
	{
		PG_RETURN_INT32(tm->tm_min);
	}
	else if (strcmp(field, "second") == 0)
	{
		PG_RETURN_INT32(tm->tm_sec);
	}
	else if (strcmp(field, "doy") == 0)		/* day-of-year of the date */
	{
		PG_RETURN_INT32( (date2j(tm->tm_year, tm->tm_mon, tm->tm_mday)
						 - date2j(tm->tm_year, 1, 1) + 1));
	}
	else if (strcmp(field, "dow") == 0)		/* day-of-week of the date */
	{
		/* dow calculated using Zeller's Congruence */
		if (tm->tm_mon < 3)
		{
			month += MONTHS_PER_YEAR;
			year -= 1;
		}

		/* 
		 * Zeller’s congruence is an algorithm devised by Christian Zeller to calculate
		 * the day of the week for any calendar date. 
		 * Here is a formula for finding the day of the week for ANY date. 
		 * N = d + 2m + [3(m+1)/5] + y + [y/4] - [y/100] + [y/400] + 2
		 * where d is the number of the day of the month, m is the number of the month, and y is the year.
		 * The brackets around the divisions mean to drop the remainder and just use the integer part that you get.
		 * Also, a VERY IMPORTANT RULE is the number to use for the months for January and February.
		 * The numbers of these months are 13 and 14 of the PREVIOUS YEAR. This means that to find the day of the week of New Year's Day this year, 1/1/98,
		 * you must use the date 13/1/97.
		 */
		res = (day + 2 * month + ((3 * (month + 1)) / (5)) + year +
					year / 4 - year / 100 + year / 400 + 2) % 7;
		
		/* Adjusting the dow accourding to the datefirst guc */
		PG_RETURN_INT32(((res) + 7 - pltsql_datefirst)%7 == 0 ?
					7 : ((res) + 7 - pltsql_datefirst)%7);

	}
	else if (strcasecmp(field , "tsql_week") == 0)		/* week number of the year  */
	{
		/* returns number of days since 1/1/1970 to 1/1/tm_year */
		first_day = date2j(tm->tm_year, 1, 1) - UNIX_EPOCH_JDATE;

		/* convert this first day of tm_year to timestamp into tsql_first_day */
		tsql_first_day = (Timestamp) (first_day - (POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE)) * USECS_PER_DAY;

		first_week_end = 8 - datepart_internal("dow", tsql_first_day, 0, false);

		day_of_year = datepart_internal("doy",timestamp,0, false);

		if(day_of_year <= first_week_end)
		{
			/* day of year is less than first_week_end means its a first week */
			PG_RETURN_INT32(1);
		}
		else
		{
			PG_RETURN_INT32(2+(day_of_year - first_week_end - 1) / 7);
		}
	}
	else if(strcasecmp(field , "week") == 0)
	{
		PG_RETURN_INT32(date2isoweek(tm->tm_year, tm->tm_mon, tm->tm_mday));
	}
	else if(strcasecmp(field , "millisecond") == 0)
	{
		PG_RETURN_INT32((fsec1) / 1000);
	}
	else if(strcasecmp(field , "microsecond") == 0)
	{
		PG_RETURN_INT32(fsec1);
	}
	else if(strcasecmp(field , "nanosecond") == 0)
	{
		PG_RETURN_INT32((fsec1) * 1000);
	}
	else if(strcasecmp(field , "tzoffset") == 0)
	{
		if(general_integer_datatype)
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The datepart tzoffset is not supported by date function datepart for data type datetime.")));
			
			PG_RETURN_INT32(-1);
		}
		else
		{
			PG_RETURN_INT32((int)df_tz);
		}
	}
	else
	{
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
			errmsg("\'%s\' is not a recognized datepart option",field)));
			
		PG_RETURN_INT32(-1);
	}
	
	PG_RETURN_INT32(1);
}


/*
 * datepart_internal_datetimeoffset takes datetimeoffset and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_datetimeoffset(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	Timestamp	timestamp;
	int			df_tz = PG_GETARG_INT32(2);

	timestamp = (Timestamp)(DirectFunctionCall1(common_utility_plugin_ptr->datetimeoffset_timestamp,
							PG_GETARG_DATUM(1)));
	
	timestamp = timestamp + (Timestamp) df_tz * SECS_PER_MINUTE * USECS_PER_SEC;
	
	return datepart_internal(field, timestamp, (float8)df_tz, false);
}

/*
 * datepart_internal_date takes date and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_date(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	Timestamp	timestamp;
	int			df_tz = PG_GETARG_INT32(2);
	
	timestamp = DirectFunctionCall1(date_timestamp, PG_GETARG_DATUM(1));

	return datepart_internal(field, timestamp, (float8)df_tz, false);
}

/*
 * datepart_internal_datetime takes datetime and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_datetime(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	Timestamp	timestamp;
	int			df_tz = PG_GETARG_INT32(2);
	
	timestamp = PG_GETARG_TIMESTAMP(1);

	return datepart_internal(field, timestamp, (float8)df_tz, false);
}

/*
 * datepart_internal_int takes int and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_int(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int64		num = PG_GETARG_INT64(1);

	/* 
	 * Setting the timestamp in datepart_internal as 0 and passing num in third argument 
	 * as there is no need of df_tz
	 */
	return datepart_internal(field, 0, num, true);

}

/*
 * datepart_internal_money takes money and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_money(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int64		num = PG_GETARG_INT64(1);

	/* 
	 * Setting the timestamp in datepart_internal as 0 and passing num in third argument 
	 * as there is no need of df_tz. Also dividing num by 10000 as money datatype 
	 * gets a multiple of 10000 internally
	 */
	return datepart_internal(field, 0, (float8)num/10000, true);
}

/*
 * datepart_internal_smallmoney takes int and converts it to
 * timestamp and calls datepart_internal and checks limits
 */

Datum
datepart_internal_smallmoney(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int64		arg = PG_GETARG_INT64(1);
	float8		num;

	/* Dividing arg by 10000 as money datatype gets a multiple of 10000 internally*/
	num = (float8)arg/10000;

	if(num > DATEPART_SMALLMONEY_MAX_VALUE || num < DATEPART_SMALLMONEY_MIN_VALUE)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				errmsg("Arithmetic overflow error converting expression to data type datetime.")));
	}

	/* 
	 * Setting the timestamp in datepart_internal as 0 and passing num in third argument 
	 * as there is no need of df_tz. 
	 */
	return datepart_internal(field, 0, num, true);
}

/*
 * datepart_internal_decimal takes decimal and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_decimal(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	Numeric		argument = PG_GETARG_NUMERIC(1);
	float8		num = DatumGetFloat8(DirectFunctionCall1(numeric_float8, NumericGetDatum(argument)));

	/* 
	 * Setting the timestamp in datepart_internal as 0 and passing num in third argument 
	 * as there is no need of df_tz
	 */
	return datepart_internal(field, 0, num, true);
}

/*
 * datepart_internal_float takes float and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_float(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	float8		arg = PG_GETARG_FLOAT8(1);

	/* 
	 * Setting the timestamp in datepart_internal as 0 and passing arg in third argument 
	 * as there is no need of df_tz
	 */
	return datepart_internal(field, 0, arg, true);
}

/*
 * datepart_internal_real takes real value and converts it to
 * timestamp and calls datepart_internal 
 */

Datum
datepart_internal_real(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	float4		arg = PG_GETARG_FLOAT4(1);

	/* 
	 * Setting the timestamp in datepart_internal as 0 and passing arg in third argument 
	 * as there is no need of df_tz
	 */
	return datepart_internal(field, 0, arg, true);
}

/*
 * datepart_internal_time takes timestamp and calls datepart_internal 
 * and thorows valid errors wherever necessary
 */

Datum
datepart_internal_time(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	Timestamp	timestamp;
	int			df_tz = PG_GETARG_INT32(2);

	timestamp  = PG_GETARG_TIMESTAMP(1);

	if(timestamp <= USECS_PER_DAY )		/* when only time is given and no date, we adjust the timestamp date to 1/1/1900 instead of 1/1/2000 */
	{	
		timestamp = timestamp - (Timestamp)(DAYS_BETWEEN_YEARS_1900_TO_2000 * USECS_PER_DAY * 1L);

		if(strcasecmp(field , "quarter") == 0 || strcasecmp(field , "month") == 0 || 
					strcasecmp(field , "day") == 0 || strcasecmp(field , "year") == 0 )
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The datepart %s is not supported by date function datepart for data type time.", field)));
		}
		else if(strcasecmp(field , "dow") == 0)
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The datepart weekday is not supported by date function datepart for data type time.")));
		}
		else if(strcasecmp(field , "doy") == 0)
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The datepart dayofyear is not supported by date function datepart for data type time.")));
		}
		else if(strcasecmp(field , "week") == 0)
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The datepart iso_week is not supported by date function datepart for data type time.")));
		}
		else if(strcasecmp(field , "tsql_week") == 0)
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The datepart week is not supported by date function datepart for data type time.")));
		}
	}

	return datepart_internal(field, timestamp, (float8)df_tz, false);
}

/*
 * datepart_internal_interval takes interval and extracts the required field
 * Since it is interval, there is no need to call datepart_internal
 */

Datum
datepart_internal_interval(PG_FUNCTION_ARGS)
{
	char		*field = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int 		df_tz = PG_GETARG_INT32(2);
	int64 		result;

	Interval	*interval = PG_GETARG_INTERVAL_P(1);
	Timestamp	interval_time = interval->time + (Timestamp) df_tz * SECS_PER_MINUTE * USECS_PER_SEC;
	int32		interval_days,interval_month;
	float8		year,month,days,hours,minutes,sec;
	int32		millisec,microsec,nanosec;

	interval_days = interval->day;
	interval_month = interval->month;

	/* Extracting year, months, days, etc from the interval period. */
	year = interval_month / MONTHS_PER_YEAR;
	month = (interval_month % MONTHS_PER_YEAR);
	days = interval_days;

	hours = (interval_time / USECS_PER_HOUR);
	minutes = (interval_time / USECS_PER_MINUTE);

	if(interval_time < USECS_PER_SEC)
	{
		sec = ((float8)interval_time / USECS_PER_SEC);
	}
	else
	{
		sec = (interval_time % USECS_PER_SEC) % SECS_PER_MINUTE;
	}

	millisec = (int32)(sec * 1000);
	microsec = (int32)(millisec * 1000);
	nanosec = (int32)(microsec) * 1000;

	if(strcasecmp(field , "year") == 0)
	{
		result = (int)year;
	}
	else if(strcasecmp(field , "quarter") == 0)
	{
		result = (int)ceil((float)month / 3.0);
	}
	else if(strcasecmp(field , "month") == 0)
	{
		result = (int)month;
	}
	else if(strcasecmp(field , "day") == 0)
	{
		result = (int)days;
	}
	else if(strcasecmp(field , "y") == 0)
	{
		result = (int)year;
	}
	else if(strcasecmp(field , "hour") == 0)
	{
		result = (int)hours;
	}
	else if(strcasecmp(field , "minute") == 0)
	{
		result = (int)minutes;
	}
	else if(strcasecmp(field , "second") == 0)
	{
		result = (int)sec;
	}
	else if(strcasecmp(field , "nanosecond") == 0)
	{
		result = nanosec;
	}
	else if(strcasecmp(field , "millisecond") == 0)
	{
		result = millisec;
	}
	else if(strcasecmp(field , "microsecond") == 0)
	{
		result = microsec;
	}
	else if(strcasecmp(field , "tzoffset") == 0)
	{
		result = 0;
	}
	else
	{
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
			errmsg("\'%s\' is not a recognized datepart option", field)));

	}

	PG_RETURN_INT32(result);
}


Datum
trancount(PG_FUNCTION_ARGS)
{
	PG_RETURN_UINT32(NestedTranCount);
}

Datum
procid(PG_FUNCTION_ARGS)
{
	PG_RETURN_OID(procid_var);
}

/*
 * This function will return following version string
 * Babelfish for PostgreSQL with SQL Server Compatibility - 12.0.2000.8
 * <Build Date> <Build Time>
 * Copyright (c) Amazon Web Services
 * PostgreSQL xx.xx on <host>
 */
Datum
version(PG_FUNCTION_ARGS)
{
	StringInfoData temp;
	void	   *info;
	const char *product_version;

	initStringInfo(&temp);

	if (pg_strcasecmp(pltsql_version, "default") == 0)
	{
		char	   *pg_version = pstrdup(PG_VERSION_STR);
		char	   *temp_str = pg_version;

		temp_str = strstr(temp_str, ", compiled by");
		*temp_str = '\0';
		product_version = GetConfigOption("babelfishpg_tds.product_version", true, false);

		Assert(product_version != NULL);
		if (pg_strcasecmp(product_version, "default") == 0)
			product_version = BABEL_COMPATIBILITY_VERSION;
		appendStringInfo(&temp,
						 "Babelfish for PostgreSQL with SQL Server Compatibility - %s"
						 "\n%s %s\nCopyright (c) Amazon Web Services\n%s (Babelfish %s)",
						 product_version,
						 __DATE__, __TIME__, pg_version, BABELFISH_VERSION_STR);
	}
	else
		appendStringInfoString(&temp, pltsql_version);

	/*
	 * TODO: Return Build number with version string as well.
	 */

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);
	pfree(temp.data);
	PG_RETURN_VARCHAR_P(info);
}

Datum sysutcdatetime(PG_FUNCTION_ARGS)
{
    PG_RETURN_DATUM(DirectFunctionCall2(timestamptz_zone,CStringGetTextDatum("UTC"),
                                                            TimestampTzGetDatum(GetCurrentStatementStartTimestamp())));
    
}

Datum getutcdate(PG_FUNCTION_ARGS)
{
    PG_RETURN_DATUM(DirectFunctionCall2(timestamp_trunc,CStringGetTextDatum("millisecond"),DirectFunctionCall2(timestamptz_zone,CStringGetTextDatum("UTC"),
                                                            TimestampTzGetDatum(GetCurrentStatementStartTimestamp()))));
    
}

Datum getdate_internal(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(DirectFunctionCall1(common_utility_plugin_ptr->timestamptz_datetime, 
						DirectFunctionCall2(timestamptz_trunc,CStringGetTextDatum("millisecond"),
											TimestampTzGetDatum(GetCurrentStatementStartTimestamp()))));
	
}

Datum sysdatetime(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(DirectFunctionCall1(common_utility_plugin_ptr->timestamptz_datetime2, 
							TimestampTzGetDatum(GetCurrentStatementStartTimestamp())));
}

Datum sysdatetimeoffset(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(DirectFunctionCall1(common_utility_plugin_ptr->timestamptz_datetimeoffset,
							TimestampTzGetDatum(GetCurrentStatementStartTimestamp())));
}

void *
string_to_tsql_varchar(const char *input_str)
{
	StringInfoData temp;
	void	   *info;

	initStringInfo(&temp);
	appendStringInfoString(&temp, input_str);

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);
	pfree(temp.data);
	return info;
}

void *
get_servername_internal()
{
	return string_to_tsql_varchar(bbf_servername);
}

void *
get_servicename_internal()
{
	return string_to_tsql_varchar(bbf_servicename);
}

void *
get_language()
{
	return string_to_tsql_varchar(bbf_language);
}

/*
 * This function will return the servername.
 */
Datum
servername(PG_FUNCTION_ARGS)
{
	PG_RETURN_VARCHAR_P(get_servername_internal());
}

/*
 * This function will return the servicename.
 */
Datum
servicename(PG_FUNCTION_ARGS)
{
	PG_RETURN_VARCHAR_P(get_servicename_internal());
}

Datum
error(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(latest_error_code);
}

Datum
pgerror(PG_FUNCTION_ARGS)
{
	char	   *error_sqlstate = unpack_sql_state(latest_pg_error_code);

	PG_RETURN_VARCHAR_P((*common_utility_plugin_ptr->tsql_varchar_input) ((error_sqlstate), strlen(error_sqlstate), -1));
}


/* returns data length of one Datum
 * this function is very similar to pg_column_size, but returns untoasted data without header sizes for bytea objects
*/
Datum
datalength(PG_FUNCTION_ARGS)
{
	Datum		value = PG_GETARG_DATUM(0);
	int32 result;
	int			typlen;

	/* On first call, get the input type's typlen, and save at *fn_extra */
	if (fcinfo->flinfo->fn_extra == NULL)
	{
		/* Lookup the datatype of the supplied argument */
		Oid			argtypeid = get_fn_expr_argtype(fcinfo->flinfo, 0);

		typlen = get_typlen(argtypeid);
		if (typlen == 0)		/* should not happen */
			elog(ERROR, "cache lookup failed for type %u", argtypeid);

		fcinfo->flinfo->fn_extra = MemoryContextAlloc(fcinfo->flinfo->fn_mcxt,
													  sizeof(int));
		*((int *) fcinfo->flinfo->fn_extra) = typlen;
	}
	else
		typlen = *((int *) fcinfo->flinfo->fn_extra);

	if (typlen == -1)
	{
		/* varlena type, untoasted and without header */
		result = toast_raw_datum_size(value) - VARHDRSZ;
	}
	else if (typlen == -2)
	{
		/* cstring */
		result = strlen(DatumGetCString(value)) + 1;
	}
	else
	{
		/* ordinary fixed-width type */
		result = typlen;
	}

	PG_RETURN_INT32(result);
}

/*
* The int_floor() and int_ceiling() functions are made to just return the
* original argument because floor(int) and ceiling(int) are always equal to int
* itself. This can only be done for int types and we are sure that these
* functions only have int arguments because these functions are ONLY invoked
* from wrapper functions that accept bigint, int, smallint and tinyint arguments.
*/
Datum
int_floor(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);

	/* Floor of an integer is the integer itself */
	PG_RETURN_INT64(arg1);
}

Datum
int_ceiling(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);

	/* Ceiling of an integer is the integer itself */
	PG_RETURN_INT64(arg1);
}

/*
* Floor/ceiling of bit type returns FLOATNTYPE in tsql. By default, we
* return numeric for floor/ceiling of bit. This function is to return a double
* precision output for a bit input.
*/
Datum
bit_floor(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);

	/* Floor of a bit is the bit itself */
	PG_RETURN_FLOAT8((float8) arg1);
}

Datum
bit_ceiling(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);

	/* Ceiling of a bit is the bit itself */
	PG_RETURN_FLOAT8((float8) arg1);
}

Datum
xact_state(PG_FUNCTION_ARGS)
{
	if (NestedTranCount == 0)
	{
		PG_RETURN_INT16(0);
	}
	else if (canCommitTransaction())
	{
		PG_RETURN_INT16(1);
	}
	else
	{
		PG_RETURN_INT16(-1);
	}
}

Datum
get_enr_list(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	List	   *enr_list = get_namedRelList();
	ListCell   *lc;

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not " \
						"allowed in this context")));

	/* need to build tuplestore in query context */
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	/* build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(2);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "reloid",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "relname",
					   TEXTOID, -1, 0);

	tupstore =
		tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
							  false, 1024);
	/* generate junk in short-term context */
	MemoryContextSwitchTo(oldcontext);

	/* scan all the variables in top estate */
	foreach(lc, enr_list)
	{
		Datum		values[2];
		bool		nulls[2];

		MemSet(nulls, 0, sizeof(nulls));

		values[0] = ((EphemeralNamedRelationMetadata) lfirst(lc))->reliddesc;
		values[1] = CStringGetTextDatum(((EphemeralNamedRelationMetadata) lfirst(lc))->name);

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	PG_RETURN_NULL();
}

Datum
tsql_random(PG_FUNCTION_ARGS)
{
	LOCAL_FCINFO(fcinfo1, 0);
	int			seed = PG_GETARG_INT32(0);
	Datum result;

	/* set the seed first */
	DirectFunctionCall1(setseed, Float8GetDatum((double) seed / 2147483649));

	/* call PG's random function */
	InitFunctionCallInfoData(*fcinfo1, NULL, 0, InvalidOid, NULL, NULL);
	result = drandom(fcinfo1);

	return result;
}

Datum
timezone_mapping(PG_FUNCTION_ARGS)
{
	char *sqltmz = text_to_cstring(PG_GETARG_TEXT_P(0));
	VarChar    *result = cstring_to_text("NULL");
	int len = (sizeof(win32_tzmap) / sizeof(*(win32_tzmap)));
	for(int i=0;i<len;i++)
	{
		if(pg_strcasecmp(win32_tzmap[i].stdname,sqltmz) == 0)
		{
			result = cstring_to_text(win32_tzmap[i].pgtzname);
			break;
		}
	}
	PG_RETURN_VARCHAR_P(result);
}

Datum
is_member(PG_FUNCTION_ARGS)
{
	const char *role = text_to_cstring(PG_GETARG_TEXT_P(0));
	Oid			role_oid = get_role_oid(role, true);

	if (!OidIsValid(role_oid))
	{
		PG_RETURN_NULL();
	}

	if (is_member_of_role(GetUserId(), role_oid))
	{
		PG_RETURN_INT32(1);
	}
	else
	{
		PG_RETURN_INT32(0);
	}
}

Datum
schema_name(PG_FUNCTION_ARGS)
{
	Oid			oid = PG_GETARG_OID(0);
	HeapTuple	tup;
	Form_pg_namespace nspform;
	NameData	name;
	const char *logical_name;

	VarChar    *result;

	if (!OidIsValid(oid))
	{
		PG_RETURN_NULL();
	}

	tup = SearchSysCache1(NAMESPACEOID, ObjectIdGetDatum(oid));

	if (!HeapTupleIsValid(tup))
	{
		PG_RETURN_NULL();
	}

	nspform = (Form_pg_namespace) GETSTRUCT(tup);
	name = nspform->nspname;

	logical_name = get_logical_schema_name(name.data, true);
	if (logical_name)
		result = (*common_utility_plugin_ptr->tsql_varchar_input) (logical_name, strlen(logical_name), -1);

	else
		result = (*common_utility_plugin_ptr->tsql_varchar_input) (name.data, strlen(name.data), -1);

	ReleaseSysCache(tup);
	PG_RETURN_VARCHAR_P(result);
}

Datum
schema_id(PG_FUNCTION_ARGS)
{
	char	   *name = NULL;
	char	   *input_name;
	char	   *physical_name;
	int			id;

	/* when no argument is passed, then ID of default schema of the caller */
	if (PG_NARGS() == 0)
	{
		char	   *db_name = get_cur_db_name();
		const char *user = get_user_for_database(db_name);
		char 	   *guest_role_name = get_guest_role_name(db_name);

		if (!user)
		{
			pfree(db_name);
			pfree(guest_role_name);

			PG_RETURN_NULL();
		}
		else if ((guest_role_name && strcmp(user, guest_role_name) == 0))
		{
			physical_name = pstrdup(get_guest_schema_name(db_name));
		}
		else
		{
			name = get_authid_user_ext_schema_name((const char *) db_name, user);
			physical_name = get_physical_schema_name(db_name, name);
		}
		pfree(db_name);
		pfree(guest_role_name);
	}
	else
	{
		if (PG_ARGISNULL(0))
			PG_RETURN_NULL();

		input_name = text_to_cstring(PG_GETARG_TEXT_P(0));
		if (pltsql_case_insensitive_identifiers)
		{
			name = downcase_identifier(input_name, strlen(input_name), false, false);	/* no truncation here.
																						 * truncation will be
																						 * handled inside
																						 * get_physical_schema_name() */
			pfree(input_name);
		}
		else
			name = input_name;

		physical_name = get_physical_schema_name(get_cur_db_name(), name);
	}

	/*
	 * If physical schema name is empty or NULL for any reason then return
	 * NULL.
	 */
	if (physical_name == NULL || strlen(physical_name) == 0)
		PG_RETURN_NULL();

	id = get_namespace_oid(physical_name, true);

	if (name)
		pfree(name);
	pfree(physical_name);

	if (!OidIsValid(id))
		PG_RETURN_NULL();

	PG_RETURN_INT32(id);
}

Datum
datefirst(PG_FUNCTION_ARGS)
{
	PG_RETURN_UINT32(pltsql_datefirst);
}

/* @@OPTIONS returns a bitmap of the current boolean SET options */
Datum
options(PG_FUNCTION_ARGS)
{
	int			options = 0;

	/*
	 * 1st bit is for DISABLE_DEF_CNST_CHK, which is an obsolete setting and
	 * should always be 0
	 */

	/* 2nd bit: IMPLICIT_TRANSACTIONS */
	if (pltsql_implicit_transactions)
		options += 2;

	/* 3rd bit: CURSOR_CLOSE_ON_COMMIT */
	if (pltsql_cursor_close_on_commit)
		options += 4;

	/* 4th bit: ANSI_WARNINGS */
	if (pltsql_ansi_warnings)
		options += 8;

	/*
	 * 5th bit: ANSI_PADDING, this setting is WIP. We only support the default
	 * ON setting atm
	 */
	if (pltsql_ansi_padding)
		options += 16;

	/* 6th bit: ANSI_NULLS */
	if (pltsql_ansi_nulls)
		options += 32;

	/* 7th bit: ARITHABORT */
	if (pltsql_arithabort)
		options += 64;

	/* 8th bit: ARITHIGNORE */
	if (pltsql_arithignore)
		options += 128;

	/* 9th bit: QUOTED_IDENTIFIER */
	if (pltsql_quoted_identifier)
		options += 256;

	/* 10th bit: NOCOUNT */
	if (pltsql_nocount)
		options += 512;

	/* 11th bit: ANSI_NULL_DFLT_ON */
	if (pltsql_ansi_null_dflt_on)
		options += 1024;

	/* 12th bit: ANSI_NULL_DFLT_OFF */
	if (pltsql_ansi_null_dflt_off)
		options += 2048;

	/* 13th bit: CONCAT_NULL_YIELDS_NULL */
	if (pltsql_concat_null_yields_null)
		options += 4096;

	/* 14th bit: NUMERIC_ROUNDABORT */
	if (pltsql_numeric_roundabort)
		options += 8192;

	/* 15th bit: XACT_ABORT */
	if (pltsql_xact_abort)
		options += 16384;

	PG_RETURN_UINT32(options);
}

/* This function will return the default AD domain name */
Datum
default_domain(PG_FUNCTION_ARGS)
{
	char	   *login_domainname = NULL;

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_login_domainname)
		login_domainname = (*pltsql_protocol_plugin_ptr)->get_login_domainname();

	if (login_domainname)
		PG_RETURN_VARCHAR_P((*common_utility_plugin_ptr->tsql_varchar_input) (login_domainname, strlen(login_domainname), -1));
	else
		PG_RETURN_NULL();
}

/*
 *		tsql_exp			- returns the exponential function of arg1
 */
Datum
tsql_exp(PG_FUNCTION_ARGS)
{
	float8		arg1 = PG_GETARG_FLOAT8(0);
	float8 result;

	errno = 0;
	result = exp(arg1);

	if (errno == ERANGE && result !=0 && !isinf(result))
		result = get_float8_infinity();

	if (unlikely(isinf(result)) && !isinf(arg1))
		float_overflow_error();
	PG_RETURN_FLOAT8(result);
}

Datum
host_os(PG_FUNCTION_ARGS)
{
	char	   *host_os_res,
			   *pg_version,
				host_str[256];
	void	   *info;

	/* filter out host info */
	pg_version = pstrdup(PG_VERSION_STR);
	sscanf(pg_version, "PostgreSQL %*255s on %255s, compiled by %*255s", host_str);

	if (strstr(host_str, "w64") || strstr(host_str, "w32") || strstr(host_str, "mingw") || strstr(host_str, "visual studio"))
	{
		host_os_res = pstrdup("Windows");
	}
	else if (strstr(host_str, "linux"))
	{
		host_os_res = pstrdup("Linux");
	}
	else if (strstr(host_str, "mac"))
	{
		host_os_res = pstrdup("Mac");
	}
	else
		host_os_res = pstrdup("UNKNOWN");

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (host_os_res, strlen(host_os_res), -1);
	if (pg_version)
		pfree(pg_version);
	if (host_os_res)
		pfree(host_os_res);
	PG_RETURN_VARCHAR_P(info);
}

/*
 * Returns activity of TDS backends.
 */
Datum
tsql_stat_get_activity_deprecated_in_2_2_0(PG_FUNCTION_ARGS)
{
	int			num_backends = pgstat_fetch_stat_numbackends();
	int			curr_backend;
	char	   *view_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			pid = -1;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/*
	 * For sys.dm_exec_sessions view: - If user is sysadmin, we show info of
	 * all the sessions - If user is not sysadmin, we only show info of
	 * current session For sys.dm_exec_connections view: - If user is
	 * sysadmin, we show info of all the connections - If user is not
	 * sysadmin, we throw an error since user does not have the required
	 * permissions to query this view
	 */
	if (strcmp(view_name, "sessions") == 0)
	{
		if (role_is_sa(GetSessionUserId()))
			pid = -1;
		else
			pid = MyProcPid;
	}
	else if (strcmp(view_name, "connections") == 0)
	{
		if (role_is_sa(GetSessionUserId()))
			pid = -1;
		else
			ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					 errmsg("The user does not have permission to perform this action")));
	}

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(TSQL_STAT_GET_ACTIVITY_COLS - 2);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "procid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "client_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "library_name", VARCHAROID, 32, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "language", VARCHAROID, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "quoted_identifier", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "arithabort", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "ansi_null_dflt_on", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "ansi_defaults", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "ansi_warnings", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "ansi_padding", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "ansi_nulls", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "concat_null_yields_null", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "textsize", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "datefirst", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "lock_timeout", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 16, "transaction_isolation", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 17, "client_pid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 18, "row_count", INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 19, "prev_error", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 20, "trancount", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 21, "protocol_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 22, "packet_size", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 23, "encrypt_option", VARCHAROID, 40, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 24, "database_id", INT2OID, -1, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	/* 1-based index */
	for (curr_backend = 1; curr_backend <= num_backends; curr_backend++)
	{
		/* for each row */
		Datum		values[TSQL_STAT_GET_ACTIVITY_COLS - 2];
		bool		nulls[TSQL_STAT_GET_ACTIVITY_COLS - 2];

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_stat_values &&
			(*pltsql_protocol_plugin_ptr)->get_stat_values(values, nulls, TSQL_STAT_GET_ACTIVITY_COLS - 2, pid, curr_backend))
			tuplestore_putvalues(tupstore, tupdesc, values, nulls);
		else
			continue;

		/* If only a single backend was requested, and we found it, break. */
		if (pid != -1)
			break;
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->invalidate_stat_view)
		(*pltsql_protocol_plugin_ptr)->invalidate_stat_view();

	return (Datum) 0;
}

Datum
tsql_stat_get_activity_deprecated_in_3_2_0(PG_FUNCTION_ARGS)
{
	Oid			sysadmin_oid = get_role_oid("sysadmin", false);
	int			num_backends = pgstat_fetch_stat_numbackends();
	int			curr_backend;
	char	   *view_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			pid = -1;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/*
	 * For sys.dm_exec_sessions view: - If user is sysadmin, we show info of
	 * all the sessions - If user is not sysadmin, we only show info of
	 * current session For sys.dm_exec_connections view: - If user is
	 * sysadmin, we show info of all the connections - If user is not
	 * sysadmin, we throw an error since user does not have the required
	 * permissions to query this view
	 */
	if (strcmp(view_name, "sessions") == 0)
	{
		if (has_privs_of_role(GetSessionUserId(), sysadmin_oid))
			pid = -1;
		else
			pid = MyProcPid;
	}
	else if (strcmp(view_name, "connections") == 0)
	{
		if (has_privs_of_role(GetSessionUserId(), sysadmin_oid))
			pid = -1;
		else
			ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					 errmsg("The user does not have permission to perform this action")));
	}

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(TSQL_STAT_GET_ACTIVITY_COLS - 1);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "procid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "client_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "library_name", VARCHAROID, 32, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "language", VARCHAROID, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "quoted_identifier", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "arithabort", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "ansi_null_dflt_on", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "ansi_defaults", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "ansi_warnings", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "ansi_padding", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "ansi_nulls", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "concat_null_yields_null", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "textsize", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "datefirst", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "lock_timeout", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 16, "transaction_isolation", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 17, "client_pid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 18, "row_count", INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 19, "prev_error", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 20, "trancount", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 21, "protocol_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 22, "packet_size", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 23, "encrypt_option", VARCHAROID, 40, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 24, "database_id", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 25, "host_name", VARCHAROID, 128, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	/* 1-based index */
	for (curr_backend = 1; curr_backend <= num_backends; curr_backend++)
	{
		/* for each row */
		Datum		values[TSQL_STAT_GET_ACTIVITY_COLS - 1];
		bool		nulls[TSQL_STAT_GET_ACTIVITY_COLS - 1];

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_stat_values &&
			(*pltsql_protocol_plugin_ptr)->get_stat_values(values, nulls, TSQL_STAT_GET_ACTIVITY_COLS - 1, pid, curr_backend))
			tuplestore_putvalues(tupstore, tupdesc, values, nulls);
		else
			continue;

		/* If only a single backend was requested, and we found it, break. */
		if (pid != -1)
			break;
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->invalidate_stat_view)
		(*pltsql_protocol_plugin_ptr)->invalidate_stat_view();

	return (Datum) 0;
}

Datum
tsql_stat_get_activity(PG_FUNCTION_ARGS)
{
	Oid			sysadmin_oid = get_role_oid("sysadmin", false);
	int			num_backends = 0;
	int			curr_backend;
	char	   *view_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			pid = -1;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/*
	 * For sys.dm_exec_sessions view: - If user is sysadmin, we show info of
	 * all the sessions - If user is not sysadmin, we only show info of
	 * current session For sys.dm_exec_connections view: - If user is
	 * sysadmin, we show info of all the connections - If user is not
	 * sysadmin, we throw an error since user does not have the required
	 * permissions to query this view
	 */
	if (strcmp(view_name, "sessions") == 0)
	{
		if (has_privs_of_role(GetSessionUserId(), sysadmin_oid))
			pid = -1;
		else
			pid = MyProcPid;
	}
	else if (strcmp(view_name, "connections") == 0)
	{
		if (has_privs_of_role(GetSessionUserId(), sysadmin_oid))
			pid = -1;
		else
			ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					 errmsg("The user does not have permission to perform this action")));
	}

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(TSQL_STAT_GET_ACTIVITY_COLS);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "procid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "client_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "library_name", VARCHAROID, 32, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "language", VARCHAROID, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "quoted_identifier", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "arithabort", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "ansi_null_dflt_on", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "ansi_defaults", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "ansi_warnings", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "ansi_padding", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "ansi_nulls", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "concat_null_yields_null", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "textsize", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "datefirst", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "lock_timeout", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 16, "transaction_isolation", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 17, "client_pid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 18, "row_count", INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 19, "prev_error", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 20, "trancount", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 21, "protocol_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 22, "packet_size", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 23, "encrypt_option", VARCHAROID, 40, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 24, "database_id", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 25, "host_name", VARCHAROID, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 26, "context_info", BYTEAOID, 128, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_tds_numbackends)
		num_backends = (*pltsql_protocol_plugin_ptr)->get_tds_numbackends();

	/* 1-based index */
	for (curr_backend = 1; curr_backend <= num_backends; curr_backend++)
	{
		/* for each row */
		Datum		values[TSQL_STAT_GET_ACTIVITY_COLS];
		bool		nulls[TSQL_STAT_GET_ACTIVITY_COLS];

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_stat_values &&
			(*pltsql_protocol_plugin_ptr)->get_stat_values(values, nulls, TSQL_STAT_GET_ACTIVITY_COLS, pid, curr_backend))
			tuplestore_putvalues(tupstore, tupdesc, values, nulls);
		else
			continue;

		/* If only a single backend was requested, and we found it, break. */
		if (pid != -1)
			break;
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->invalidate_stat_view)
		(*pltsql_protocol_plugin_ptr)->invalidate_stat_view();

	return (Datum) 0;
}

Datum
get_current_full_xact_id(PG_FUNCTION_ARGS)
{
	PreventCommandDuringRecovery("get_current_full_xact_id()");

	PG_RETURN_FULLTRANSACTIONID(GetCurrentFullTransactionId());
}

Datum
checksum(PG_FUNCTION_ARGS)
{
	int32 result = 0;
	int			nargs = PG_NARGS();
	StringInfoData buf;
	char		md5[MD5_HASH_LEN + 1];
	char	   *name;
	const char *errstr = NULL;
	bool		success;

	initStringInfo(&buf);
	if (nargs > 0)
	{
		ArrayType  *arr;
		Datum	   *values;
		bool	   *nulls;
		int			nelems;
		int			i;

		arr = PG_GETARG_ARRAYTYPE_P(0);
		deconstruct_array(arr, TEXTOID, -1, false, TYPALIGN_INT, &values, &nulls, &nelems);
		for (i = 0; i < nelems; i++)
		{
			name = nulls[i] ? "" : TextDatumGetCString(values[i]);
			if (strlen(name) == 0 && nelems == 1)
				PG_RETURN_INT32(0);
			else
				appendStringInfoString(&buf, name);
		}
	}

	/*
	 * We get hash value for md5 which is in hexadecimal. We are taking the
	 * first 8 characters of the md5 hash and converting it to int32.
	 */
	success = pg_md5_hash(buf.data, buf.len, md5, &errstr);
	if (success)
	{
		md5[8] = '\0';
		result = (int) strtol(md5, NULL, 16);
	}
	else
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("could not compute %s hash: %s", "MD5", errstr)));

	pfree(buf.data);

	PG_RETURN_INT32(result);
}

/*
 * tsql_bsearch_arg
 *	This function performs a binary search on a sorted array to find the
 *	position of a given key value. It compares the key with array elements
 *	using the provided comparator function and argument.
 *	
 *	Note: This is a modified version of the standard bsearch_arg() function
 *	to return the index of key instead of a boolean indicating the presence of
 *	the key value.
 */
static int
tsql_bsearch_arg(const void *key, const void *base0,
			size_t nmemb, size_t size,
			int (*compar) (const void *, const void *, void *),
			void *arg)
{
	const char *base = (const char *) base0;
	int			lim,
				cmp;
	const void *p;

	for (lim = nmemb; lim != 0; lim >>= 1)
	{
		p = base + (lim >> 1) * size;
		cmp = (*compar) (key, p, arg);
		if (cmp == 0)
			return (((const char *)p - (const char *)base0) / size) + 2;
		if (cmp > 0)
		{						/* key > p: move right */
			base = (const char *) p + size;
			lim--;
		}						/* else move left */
	}
	return ((base - (const char *)base0) / size) + 1;
}


/*
 * search_partition
 *	This function performs a search to find the partition number
 *	for a given value in a specified partition function by retrieving
 *	the partition function metadata, and performing a binary search 
 *	on the sorted array of partition range values.
 *
 *	Returns:
 *		- The index of the partition to which the input value belongs.
 *		- 1, if the provided value is NULL and partition function exists in provided database.
 */
Datum
search_partition(PG_FUNCTION_ARGS)
{
	char			*partition_func_name = text_to_cstring(PG_GETARG_TEXT_P(0));
	int32			result;
	Relation		rel;
	HeapTuple		tuple;
	SysScanDesc		scan;
	ScanKeyData		scanKey[2];
	int16			dbid;
	ArrayType		*values;
	bool			isnull;
	Datum			arg;
	Oid			argtypeid;
	char			*func_param_typname = NULL;
	Oid			func_param_typoid;
	Oid			sqlvariant_typoid;
	Datum			*range_values;
	bool			*nulls;
	int			nelems;
	Oid			cmpfunction_oid;
	tsql_compare_context	cxt;
	Oid			*arg_types;

	if (!PG_ARGISNULL(2)) /* Database is specified. */
	{
		char *db_name = text_to_cstring(PG_GETARG_TEXT_P(2));
		dbid = get_db_id(db_name);
		if (!DbidIsValid(dbid))
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					errmsg("Invalid database name '%s'.", db_name)));
		pfree(db_name);
	}
	else /* Database is not specified. */
		dbid = get_cur_db_id();
	
	/* Get OID of sql_variant type. */
	sqlvariant_typoid = (*common_utility_plugin_ptr->get_tsql_datatype_oid) ("sql_variant");
	
	/*
	 * Get metadata of partition function for the provided partition
	 * function name, if it exists in the provided database.
	 */
	rel = table_open(get_bbf_partition_function_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_function_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_partition_function_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_func_name));
	
	/* Scan using index. */
	scan = systable_beginscan(rel, get_bbf_partition_function_pk_idx_oid(),
			false, NULL, 2, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		func_param_typname = TextDatumGetCString(heap_getattr(tuple, Anum_bbf_partition_function_input_parameter_type, RelationGetDescr(rel), &isnull));
		values = DatumGetArrayTypeP(heap_getattr(tuple, Anum_bbf_partition_function_range_values, RelationGetDescr(rel), &isnull));
		deconstruct_array(values, sqlvariant_typoid,
					-1, false, 'i', &range_values, &nulls, &nelems);
	}

	/* Raise error if provided partition function doesn't exist in the provided database. */
	if (!func_param_typname)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					errmsg("Invalid object name '%s'.", partition_func_name)));
	
	/*
	 * If the partition function exists in the provided database and
	 * provided value is NULL then return 1 because NULL values will always
	 * belong to first partition.
	 */
	if (PG_ARGISNULL(1))
	{
		systable_endscan(scan);
		table_close(rel, AccessShareLock);
		pfree(partition_func_name);
		pfree(func_param_typname);
		pfree(nulls);
		pfree(range_values);
		PG_RETURN_INT32(1);
	}

	argtypeid = get_fn_expr_argtype(fcinfo->flinfo, 1);
	arg = PG_GETARG_DATUM(1);

	/* Get OID of partition function parameter type. */
	func_param_typoid = (*common_utility_plugin_ptr->get_tsql_datatype_oid) (func_param_typname);

	/* 
	 * Implicitly convert input value to parameter type of
	 * partition function and it will raise error if conversion fails.
	 */
	arg = pltsql_exec_tsql_cast_value(arg, &isnull, argtypeid, -1, func_param_typoid, -1);

	/* Cast it to sql_variant */
	arg = pltsql_exec_tsql_cast_value(arg, &isnull,
						func_param_typoid, -1,
						sqlvariant_typoid, -1);

	/*
	 * Find oid of comparator function for sqlvariant type, which will be
	 * used for comparison during binary search. Here, we are searching the
	 * for "sqlvarint_cmp" function in "sys" schema with sqlvariant arg types
	 * to ensure that we get a unique result.
	 */
	arg_types = (Oid *) palloc(2 * sizeof(Oid));
	arg_types[0] = sqlvariant_typoid;
	arg_types[1] = sqlvariant_typoid;
	cmpfunction_oid = GetSysCacheOid3(PROCNAMEARGSNSP, Anum_pg_proc_oid,
								CStringGetDatum("sqlvariant_cmp"),
								PointerGetDatum(buildoidvector(arg_types, 2)),
								ObjectIdGetDatum(get_namespace_oid("sys", false)));

	cxt.function_oid = cmpfunction_oid;
	cxt.colloid = tsql_get_database_or_server_collation_oid_internal(false);
	
	/* Perform binary search on sorted range values. */
	result = tsql_bsearch_arg(&arg, range_values, nelems, sizeof(Datum), tsql_compare_values, &cxt);

	/* Close the catalog. */
	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	/* Free the allocated memory. */
	pfree(arg_types);
	pfree(partition_func_name);
	pfree(func_param_typname);
	pfree(nulls);
	pfree(range_values);

	PG_RETURN_INT32(result);
}

/*
 * object_id
 * 	Returns the object ID with object name and object type as input where object type is optional
 * Returns NULL
 * 	if input is NULL
 * 	if there is no such object
 * 	if user don't have right permission
 * 	if any error occured
 */
Datum
object_id(PG_FUNCTION_ARGS)
{
	char	   *db_name,
			   *schema_name,
			   *object_name;
	char	   *physical_schema_name;
	char	   *input;
	char	   *object_type = NULL;
	char	  **splited_object_name;
	Oid			schema_oid;
	Oid			user_id = GetUserId();
	Oid result = InvalidOid;
	bool		is_temp_object;
	int			i;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();
	input = text_to_cstring(PG_GETARG_TEXT_P(0));

	if (!PG_ARGISNULL(1))
	{
		char	   *str = text_to_cstring(PG_GETARG_TEXT_P(1));

		i = strlen(str);
		if (i > 2)
		{
			pfree(input);
			pfree(str);
			PG_RETURN_NULL();
		}
		else if (i == 2 && isspace((unsigned char) str[1]))
		{
			str[1] = '\0';
		}
		object_type = downcase_identifier(str, strlen(str), false, false);
		pfree(str);
	}
	/* strip trailing whitespace from input */
	i = strlen(input);
	while (i > 0 && isspace((unsigned char) input[i - 1]))
		input[--i] = '\0';

	/* length should be restricted to 4000 */
	if (i > 4000)
		ereport(ERROR,
				(errcode(ERRCODE_STRING_DATA_LENGTH_MISMATCH),
				 errmsg("input value is too long for object name")));

	/* resolve the three part name */
	splited_object_name = split_object_name(input);
	db_name = splited_object_name[1];
	schema_name = splited_object_name[2];
	object_name = splited_object_name[3];

	/* downcase identifier if needed */
	if (pltsql_case_insensitive_identifiers)
	{
		db_name = downcase_identifier(db_name, strlen(db_name), false, false);
		schema_name = downcase_identifier(schema_name, strlen(schema_name), false, false);
		object_name = downcase_identifier(object_name, strlen(object_name), false, false);
		for (int j = 0; j < 4; j++)
			pfree(splited_object_name[j]);
	}
	else
		pfree(splited_object_name[0]);

	pfree(input);
	pfree(splited_object_name);

	/* truncate identifiers if needed */
	truncate_tsql_identifier(db_name);
	truncate_tsql_identifier(schema_name);
	truncate_tsql_identifier(object_name);

	if (!strcmp(db_name, ""))
		db_name = get_cur_db_name();
	else if (strcmp(db_name, get_cur_db_name()) && strcmp(db_name, "tempdb"))
	{
		/* cross database lookup */
		int			db_id = get_db_id(db_name);

		if (!DbidIsValid(db_id))
		{
			pfree(db_name);
			pfree(schema_name);
			pfree(object_name);
			if (object_type)
				pfree(object_type);
			PG_RETURN_NULL();
		}
		user_id = GetSessionUserId();
	}

	/* get physical schema name from logical schema name */
	if (!strcmp(schema_name, ""))
	{
		/*
		 * find the default schema for current user and get physical schema
		 * name
		 */
		const char *user = get_user_for_database(db_name);
		char 	   *guest_role_name = get_guest_role_name(db_name);

		if (!user)
		{
			pfree(db_name);
			pfree(schema_name);
			pfree(object_name);
			pfree(guest_role_name);

			if (object_type)
				pfree(object_type);

			PG_RETURN_NULL();
		}
		else if ((guest_role_name && strcmp(user, guest_role_name) == 0))
		{
			physical_schema_name = pstrdup(get_guest_schema_name(db_name));
		}
		else
		{
			pfree(schema_name);
			schema_name = get_authid_user_ext_schema_name((const char *) db_name, user);
			physical_schema_name = get_physical_schema_name(db_name, schema_name);
		}

		pfree(guest_role_name);
	}
	else
	{
		physical_schema_name = get_physical_schema_name(db_name, schema_name);
	}

	/*
	 * get schema oid from physical schema name, it will return InvalidOid if
	 * user don't have lookup access
	 */
	schema_oid = get_namespace_oid(physical_schema_name, true);

	/* free unnecessary pointers */
	pfree(db_name);
	pfree(schema_name);
	pfree(physical_schema_name);

	if (!OidIsValid(schema_oid) || object_aclcheck(NamespaceRelationId, schema_oid, user_id, ACL_USAGE) != ACLCHECK_OK)
	{
		pfree(object_name);
		if (object_type)
			pfree(object_type);
		PG_RETURN_NULL();
	}

	/* check if looking for temp object */
	is_temp_object = (object_name[0] == '#' ? true : false);

	if (object_type)			/* "object_type" is specified in-argument */
	{
		if (is_temp_object)
		{
			if (!strcmp(object_type, "s") || !strcmp(object_type, "u") || !strcmp(object_type, "v") ||
				!strcmp(object_type, "it") || !strcmp(object_type, "et") || !strcmp(object_type, "so"))
			{
				/*
				 * search in list of ENRs registered in the current query
				 * environment by name
				 */
				EphemeralNamedRelation enr = get_ENR(currentQueryEnv, object_name, true);

				if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
				{
					result = enr->md.reliddesc;
				}
				else if (enr == NULL)
				{
					result = get_relname_relid((const char *) object_name, LookupNamespaceNoError("pg_temp"));
				}
			}
			else if (!strcmp(object_type, "r") || !strcmp(object_type, "ec") || !strcmp(object_type, "pg") ||
					 !strcmp(object_type, "sn") || !strcmp(object_type, "sq") || !strcmp(object_type, "tt"))
			{
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Object type currently unsupported in Babelfish.")));
			}
		}
		else
		{
			if (!strcmp(object_type, "s") || !strcmp(object_type, "u") || !strcmp(object_type, "v") ||
				!strcmp(object_type, "it") || !strcmp(object_type, "et") || !strcmp(object_type, "so"))
			{
				/* search in pg_class by name and schema oid */
				Oid			relid = get_relname_relid((const char *) object_name, schema_oid);

				if (OidIsValid(relid) && pg_class_aclcheck(relid, user_id, ACL_SELECT) == ACLCHECK_OK)
				{
					result = relid;
				}
			}
			else if (!strcmp(object_type, "c") || !strcmp(object_type, "d") || !strcmp(object_type, "f") ||
					 !strcmp(object_type, "pk") || !strcmp(object_type, "uq"))
			{
				/* search in pg_constraint by name and schema oid */
				result = tsql_get_constraint_oid(object_name, schema_oid, user_id);
			}
			else if (!strcmp(object_type, "af") || !strcmp(object_type, "fn") || !strcmp(object_type, "fs") ||
					 !strcmp(object_type, "ft") || !strcmp(object_type, "if") || !strcmp(object_type, "p") ||
					 !strcmp(object_type, "pc") || !strcmp(object_type, "tf") || !strcmp(object_type, "rf") ||
					 !strcmp(object_type, "x"))
			{
				/*
				 * If the object type is not specified as 'tr' and it's actually a trigger,
				 * then object_id() should return NULL.
				 */
				if (OidIsValid(tsql_get_trigger_oid(object_name, schema_oid, user_id)))
				{
					pfree(object_name);
					pfree(object_type);
					PG_RETURN_NULL();
				}
				
				/* search in pg_proc by name and schema oid */
				result = tsql_get_proc_oid(object_name, schema_oid, user_id);
			}
			else if (!strcmp(object_type, "tr") || !strcmp(object_type, "ta"))
			{
				/* search in pg_trigger by name and schema oid */
				result = tsql_get_trigger_oid(object_name, schema_oid, user_id);
			}
			else if (!strcmp(object_type, "r") || !strcmp(object_type, "ec") || !strcmp(object_type, "pg") ||
					 !strcmp(object_type, "sn") || !strcmp(object_type, "sq") || !strcmp(object_type, "tt"))
			{
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Object type currently unsupported in Babelfish.")));
			}
		}

	}
	else
	{
		if (is_temp_object)		/* temp object without "object_type"
								 * in-argument */
		{
			/*
			 * search in list of ENRs registered in the current query
			 * environment by name
			 */
			EphemeralNamedRelation enr = get_ENR(currentQueryEnv, object_name, true);

			if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
			{
				result = enr->md.reliddesc;
			} 
			else if (enr == NULL)
			{
				result = get_relname_relid((const char *) object_name, LookupNamespaceNoError("pg_temp"));
			}
		}
		else
		{
			/* search in pg_class by name and schema oid */
			Oid			relid = get_relname_relid((const char *) object_name, schema_oid);

			if (OidIsValid(relid) && pg_class_aclcheck(relid, user_id, ACL_SELECT) == ACLCHECK_OK)
			{
				result = relid;
			}

			if (!OidIsValid(result))	/* search only if not found earlier */
			{
				/* search in pg_trigger by name and schema oid */
				result = tsql_get_trigger_oid(object_name, schema_oid, user_id);
			}

			if (!OidIsValid(result))
			{
				/* search in pg_proc by name and schema oid */
				result = tsql_get_proc_oid(object_name, schema_oid, user_id);
			}

			if (!OidIsValid(result))
			{
				/* search in pg_constraint by name and schema oid */
				result = tsql_get_constraint_oid(object_name, schema_oid, user_id);
			}
		}
	}

	pfree(object_name);
	if (object_type)
		pfree(object_type);

	if (OidIsValid(result))
		PG_RETURN_INT32(result);
	else
		PG_RETURN_NULL();
}

/*
 * object_name
 * 		returns the object name with object id and database id as input where database id is optional
 * Returns NULL
 * 		if there is no such object in specified database, if database id is not provided it will lookup in current database
 * 		if user don't have right permission
 */
Datum
object_name(PG_FUNCTION_ARGS)
{
	int32		input1 = PG_GETARG_INT32(0);
	Oid			object_id;
	Oid			database_id;
	Oid			user_id = GetUserId();
	Oid			schema_id = InvalidOid;
	HeapTuple	tuple;
	Relation	tgrel;
	ScanKeyData key;
	SysScanDesc tgscan;
	EphemeralNamedRelation enr;
	bool		found = false;
	text	   *result_text = NULL;

	if (input1 < 0)
		PG_RETURN_NULL();
	object_id = (Oid) input1;
	if (!PG_ARGISNULL(1))		/* if database id is provided */
	{
		int32		input2 = PG_GETARG_INT32(1);

		if (input2 < 0)
			PG_RETURN_NULL();
		database_id = (Oid) input2;
		if (database_id != get_cur_db_id()) /* cross-db lookup */
		{
			char	   *db_name = get_db_name(database_id);

			if (db_name == NULL)	/* database doesn't exist with given oid */
				PG_RETURN_NULL();
			user_id = GetSessionUserId();
			pfree(db_name);
		}
	}
	else						/* by default lookup in current database */
		database_id = get_cur_db_id();

	/*
	 * search in list of ENRs registered in the current query environment by
	 * object_id
	 */
	enr = GetENRTempTableWithOid(object_id);
	if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
	{
		PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text(enr->md.name));
	}

	/* search in pg_class by object_id */
	tuple = SearchSysCache1(RELOID, ObjectIdGetDatum(object_id));
	if (HeapTupleIsValid(tuple))
	{
		/* check if user have right permission on object */
		if (pg_class_aclcheck(object_id, user_id, ACL_SELECT) == ACLCHECK_OK)
		{
			Form_pg_class pg_class = (Form_pg_class) GETSTRUCT(tuple);
			result_text = cstring_to_text(NameStr(pg_class->relname)); // make a copy before releasing syscache
			schema_id = pg_class->relnamespace;
		}
		ReleaseSysCache(tuple);
		found = true;
	}

	if (!found)
	{
		/* search in pg_proc by object_id */
		tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			/* check if user have right permission on object */
			if (object_aclcheck(ProcedureRelationId, object_id, user_id, ACL_EXECUTE) == ACLCHECK_OK)
			{
				Form_pg_proc procform = (Form_pg_proc) GETSTRUCT(tuple);
				result_text = cstring_to_text(NameStr(procform->proname));
				schema_id = procform->pronamespace;
			}
			ReleaseSysCache(tuple);
			found = true;
		}
	}

	if (!found)
	{
		/* search in pg_type by object_id */
		tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			/* check if user have right permission on object */
			if (object_aclcheck(TypeRelationId, object_id, user_id, ACL_USAGE) == ACLCHECK_OK)
			{
				Form_pg_type pg_type = (Form_pg_type) GETSTRUCT(tuple);
				result_text = cstring_to_text(NameStr(pg_type->typname));
			}
			ReleaseSysCache(tuple);
			found = true;
		}
	}

	if (!found)
	{
		/* search in pg_trigger by object_id */
		tgrel = table_open(TriggerRelationId, AccessShareLock);
		ScanKeyInit(&key,
					Anum_pg_trigger_oid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(object_id));

		tgscan = systable_beginscan(tgrel, TriggerOidIndexId, true,
									NULL, 1, &key);

		tuple = systable_getnext(tgscan);
		if (HeapTupleIsValid(tuple))
		{
			Form_pg_trigger pg_trigger = (Form_pg_trigger) GETSTRUCT(tuple);

			/* check if user have right permission on object */
			if (OidIsValid(pg_trigger->tgrelid) &&
				pg_class_aclcheck(pg_trigger->tgrelid, user_id, ACL_SELECT) == ACLCHECK_OK)
			{
				result_text = cstring_to_text(NameStr(pg_trigger->tgname));
				schema_id = get_rel_namespace(pg_trigger->tgrelid);
			}
			found = true;
		}
		systable_endscan(tgscan);
		table_close(tgrel, AccessShareLock);
	}

	if (!found)
	{
		/* search in pg_constraint by object_id */
		tuple = SearchSysCache1(CONSTROID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);

			/* check if user have right permission on object */
			if (OidIsValid(con->conrelid) && (pg_class_aclcheck(con->conrelid, user_id, ACL_SELECT) == ACLCHECK_OK))
			{
				result_text = cstring_to_text(NameStr(con->conname));
				schema_id = con->connamespace;
			}
			ReleaseSysCache(tuple);
			found = true;
		}
	}

	if (result_text)
	{
		/*
		 * Check if schema corresponding to found object belongs to specified
		 * database, schema also can be shared schema like "sys" or
		 * "information_schema_tsql". In case of pg_type schema_id will be
		 * invalid.
		 */
		if (!OidIsValid(schema_id) ||
			is_schema_from_db(schema_id, database_id) ||
			(schema_id == get_namespace_oid("sys", true)) ||
			(schema_id == get_namespace_oid("information_schema_tsql", true)) ||
			(isTempNamespace(schema_id)))
		{
			PG_RETURN_VARCHAR_P((VarChar *) result_text);
		}
	}
	PG_RETURN_NULL();
}

/*
 * type_id
 * Returns the object ID with type name as input.
 * Returns NULL
 *  if input is NULL
 *  if there is no such type
 *  if user don't have right permission
 *  if any error occured
 */
Datum
type_id(PG_FUNCTION_ARGS)
{
    char       *db_name,
               *schema_name,
               *object_name;
    char       *physical_schema_name;
    char       *input;
    char       **splitted_object_name;
    Oid        schema_oid = InvalidOid;
    Oid        user_id = GetUserId();
    Oid        result = InvalidOid;
    int        i;
    int        len;

    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();
    input = text_to_cstring(PG_GETARG_TEXT_PP(0));

    /* strip trailing whitespace from input */
    len = pg_mbstrlen(input);
    i = len;
    while (i > 0 && scanner_isspace((unsigned char) input[i - 1]))
        i--;
    if(i < len)
        input[i] = '\0';

    /* length should be restricted to 4000 */
    if (i > SYSVARCHAR_MAX_LENGTH)
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_LENGTH_MISMATCH),
                 errmsg("input value is too long for object name")));

    /* resolve the two part name */
    splitted_object_name = split_object_name(input);
    /* If three part name(db_name also included in input) then return null */
    if(pg_mbstrlen(splitted_object_name[1]) != 0)
    {
        pfree(input);
        for (int j = 0; j < 4; j++)
            pfree(splitted_object_name[j]);
        pfree(splitted_object_name);
        PG_RETURN_NULL();
    }
    db_name = get_cur_db_name();
    schema_name = splitted_object_name[2];
    object_name = splitted_object_name[3];

    /* downcase identifier if needed */
    if (pltsql_case_insensitive_identifiers)
    {
        db_name = downcase_identifier(db_name, strlen(db_name), false, false);
        schema_name = downcase_identifier(schema_name, strlen(schema_name), false, false);
        object_name = downcase_identifier(object_name, strlen(object_name), false, false);
        for (int k = 0; k < 4; k++)
            pfree(splitted_object_name[k]);
    }
    else
        pfree(splitted_object_name[0]);

    pfree(input);
    pfree(splitted_object_name);

    /* truncate identifiers if needed */
    truncate_tsql_identifier(db_name);
    truncate_tsql_identifier(schema_name);
    truncate_tsql_identifier(object_name);

    if (!strcmp(schema_name, ""))
    {
        // To check if it is a system datatype, search in typecode list and it will give result oid, else if not it will return null.
        result = (*common_utility_plugin_ptr->get_tsql_datatype_oid) (object_name);

        // If null result, then it is not system datatype and now search with default schema in pg_type
        if (!OidIsValid(result))
        {
            /* find the default schema for current user and get physical schema name */
            const char  *user = get_user_for_database(db_name);
            char        *guest_role_name = get_guest_role_name(db_name);

            if (!user)
            {
                pfree(db_name);
                pfree(schema_name);
                pfree(object_name);
                pfree(guest_role_name);

                PG_RETURN_NULL();
            }
            else if ((guest_role_name && strcmp(user, guest_role_name) == 0))
            {
                physical_schema_name = pstrdup(get_guest_schema_name(db_name));
            }
            else
            {
                pfree(schema_name);
                schema_name = get_authid_user_ext_schema_name((const char *) db_name, user);
                physical_schema_name = get_physical_schema_name(db_name, schema_name);
            }
			
            pfree(guest_role_name);
        }
        else
        {
            pfree(db_name);
            pfree(schema_name);
            pfree(object_name);
            PG_RETURN_INT32(result);
        }
    }
    else
    {
	// If schema is 'sys' or 'pg_catalog' then search in typecode list.
	if(!strcmp(schema_name, "sys") || !strcmp(schema_name, "pg_catalog"))
	{
	    result = (*common_utility_plugin_ptr->get_tsql_datatype_oid) (object_name);
	    pfree(db_name);
	    pfree(schema_name);
	    pfree(object_name);
	    if (OidIsValid(result))
		PG_RETURN_INT32(result);
	    else
		PG_RETURN_NULL();
	}
	else
	{
	    physical_schema_name = get_physical_schema_name(db_name, schema_name);
	}
    }

    /* get schema oid from physical schema name, it will return InvalidOid if user don't have lookup access */
    if (physical_schema_name != NULL && pg_mbstrlen(physical_schema_name) != 0)
	schema_oid = get_namespace_oid(physical_schema_name, true);
	
    pfree(schema_name);
    pfree(db_name);
    pfree(physical_schema_name);

    // Check if user has permission to access schema
    if (OidIsValid(schema_oid) && object_aclcheck(NamespaceRelationId, schema_oid, user_id, ACL_USAGE) == ACLCHECK_OK)
    {
    	// Search in pg_type.
	result = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(object_name), ObjectIdGetDatum(schema_oid));
	if (OidIsValid(result) && object_aclcheck(TypeRelationId, result, user_id, ACL_USAGE) == ACLCHECK_OK)
	{
		pfree(object_name);
		PG_RETURN_INT32(result);
	}
    }
    pfree(object_name);
    PG_RETURN_NULL();
}

/*
 * type_name
 *      returns the type name with type id as input
 * Returns NULL
 *      if there is no such type
 *      if user don't have right permission
 */
Datum
type_name(PG_FUNCTION_ARGS)
{
    Datum       type_id = PG_GETARG_DATUM(0);
    Datum       tsql_typename;
    HeapTuple   tuple;
    Oid         user_id = GetUserId();
    char        *result = NULL;

    LOCAL_FCINFO(fcinfo1, 1);

    if (type_id < 0)
        PG_RETURN_NULL();
    
    InitFunctionCallInfoData(*fcinfo1, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo1->args[0].value = type_id;
    fcinfo1->args[0].isnull = false;
    // Search in typecode list, it will return type name if system datatype, else will return null.
    tsql_typename = (*common_utility_plugin_ptr->translate_pg_type_to_tsql) (fcinfo1);
    if (tsql_typename)
    {
        PG_RETURN_DATUM(tsql_typename);
    }
    else
    {   
        // Search in pg_type catalog
        tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(type_id));
        if (HeapTupleIsValid(tuple))
        {
            if (object_aclcheck(TypeRelationId, type_id, user_id, ACL_USAGE) == ACLCHECK_OK)
            {
                Form_pg_type pg_type = (Form_pg_type) GETSTRUCT(tuple);
                result = NameStr(pg_type->typname);
            }
            ReleaseSysCache(tuple);
        }
        if (result)
        {
            PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text(result));
        }
    }
    PG_RETURN_NULL();
}

/*
 * Wrapper for C function replace_special_chars_fts_impl()
 */
Datum
replace_special_chars_fts(PG_FUNCTION_ARGS)
{
	text		*input_text = PG_GETARG_TEXT_P(0);
	char		*input_str = text_to_cstring(input_text);
	char		*output_str;
	text		*result_text;
	
	/* Modify the input_str in place */
	output_str = replace_special_chars_fts_impl(input_str);
	
	/* Convert the modified input_str back to text */
	result_text = cstring_to_text(output_str);
	
	/* Free the memory allocated for input_str */
	pfree(input_str);
	pfree(output_str);
	PG_RETURN_TEXT_P(result_text);
}

Datum
has_dbaccess(PG_FUNCTION_ARGS)
{
	char        *db_name = text_to_cstring(PG_GETARG_TEXT_P(0));

	/*
	 * Ensure the database name input argument is lower-case, as all Babel
	 * table names are lower-case
	 */
	char        *lowercase_db_name = lowerstr(db_name);

	/* Also strip trailing whitespace to mimic SQL Server behaviour */
	int         i;
	char        *user = NULL;
	const char  *login;
	int16       db_id;
	bool        login_is_db_owner;

	i = strlen(lowercase_db_name);
	while (i > 0 && isspace((unsigned char) lowercase_db_name[i - 1]))
		lowercase_db_name[--i] = '\0';

	db_id = get_db_id(lowercase_db_name);

	if (!DbidIsValid(db_id))
		PG_RETURN_NULL();

	login = GetUserNameFromId(GetSessionUserId(), false);
	user = get_authid_user_ext_physical_name(lowercase_db_name, login);
	login_is_db_owner = 0 == strncmp(login, get_owner_of_db(lowercase_db_name), NAMEDATALEN);

	/*
	 * Special cases: Database Owner should always have access If this DB has
	 * guest roles, the guests should always have access
	 */
	if (!user)
	{
		Oid			datdba;

		datdba = get_role_oid("sysadmin", false);
		if (is_member_of_role(GetSessionUserId(), datdba) || login_is_db_owner)
			/* 
			 * The login will have access to the database if it is a member
			 * of sysadmin or it is the owner of the database.
			 */
			user = get_dbo_role_name(lowercase_db_name);
		else
		{
			/*
			 * Get the guest role name only if the guest is enabled on the
			 * current db.
			 */
			if (guest_has_dbaccess(lowercase_db_name))
				user = get_guest_role_name(lowercase_db_name);
			else
				user = NULL;
		}
	}

	if (!user)
		PG_RETURN_INT32(0);
	else
	{
		pfree(user);
		PG_RETURN_INT32(1);
	}
}

Datum
sp_datatype_info_helper(PG_FUNCTION_ARGS)
{

	int16		odbcVer = PG_GETARG_INT16(0);
	bool		is_100 = PG_GETARG_BOOL(1);

	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	int			i;
	Oid			sys_varcharoid = get_sys_varcharoid();
	Oid			colloid = tsql_get_database_or_server_collation_oid_internal(false);

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(SP_DATATYPE_INFO_HELPER_COLS);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "TYPE_NAME", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "DATA_TYPE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "PRECISION", INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "LITERAL_PREFIX", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "LITERAL_SUFFIX", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "CREATE_PARAMS", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "NULLABLE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "CASE_SENSITIVE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "SEARCHABLE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "UNSIGNED_ATTRIBUTE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "MONEY", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "AUTO_INCREMENT", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "LOCAL_TYPE_NAME", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "MINIMUM_SCALE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "MAXIMUM_SCALE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 16, "SQL_DATA_TYPE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 17, "SQL_DATETIME_SUB", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 18, "NUM_PREC_RADIX", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 19, "INTERVAL_PRECISION", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 20, "USERTYPE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 21, "LENGTH", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 22, "SS_DATA_TYPE", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 23, "PG_TYPE_NAME", sys_varcharoid, 20, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	/* And set the correct collations to the required fields. */
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 1, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 4, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 5, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 6, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 13, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 23, colloid);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	for (i = 0; i < DATATYPE_INFO_TABLE_ROWS; i++)
	{
		/* for each row */
		Datum		values[SP_DATATYPE_INFO_HELPER_COLS];
		bool		nulls[SP_DATATYPE_INFO_HELPER_COLS];

		DatatypeInfo datatype_info_element = datatype_info_table[i];

		MemSet(nulls, false, SP_DATATYPE_INFO_HELPER_COLS);

		values[0] = CStringGetTextDatum(datatype_info_element.type_name);

		if (odbcVer == 3)
		{
			if (is_100)
				values[1] = Int32GetDatum(datatype_info_element.data_type_3_100);
			else
				values[1] = Int32GetDatum(datatype_info_element.data_type_3);
		}
		else
		{
			if (is_100)
				values[1] = Int32GetDatum(datatype_info_element.data_type_2_100);
			else
				values[1] = Int32GetDatum(datatype_info_element.data_type_2);
		}

		values[2] = Int64GetDatum(datatype_info_element.precision);

		if (strcmp(datatype_info_element.literal_prefix, NULLVAL_STR) == 0)
			nulls[3] = true;
		else
			values[3] = CStringGetTextDatum(datatype_info_element.literal_prefix);

		if (strcmp(datatype_info_element.literal_suffix, NULLVAL_STR) == 0)
			nulls[4] = true;
		else
			values[4] = CStringGetTextDatum(datatype_info_element.literal_suffix);

		if (strcmp(datatype_info_element.create_params, NULLVAL_STR) == 0)
			nulls[5] = true;
		else
			values[5] = CStringGetTextDatum(datatype_info_element.create_params);

		values[6] = Int32GetDatum(datatype_info_element.nullable);
		values[7] = Int32GetDatum(datatype_info_element.case_sensitive);
		values[8] = Int32GetDatum(datatype_info_element.searchable);

		if (datatype_info_element.unsigned_attribute == NULLVAL)
			nulls[9] = true;
		else
			values[9] = Int32GetDatum(datatype_info_element.unsigned_attribute);

		values[10] = Int32GetDatum(datatype_info_element.money);

		if (datatype_info_element.auto_increment == NULLVAL)
			nulls[11] = true;
		else
			values[11] = Int32GetDatum(datatype_info_element.auto_increment);

		values[12] = CStringGetTextDatum(datatype_info_element.local_type_name);

		if (datatype_info_element.minimum_scale == NULLVAL)
			nulls[13] = true;
		else
			values[13] = Int32GetDatum(datatype_info_element.minimum_scale);

		if (datatype_info_element.maximum_scale == NULLVAL)
			nulls[14] = true;
		else
			values[14] = Int32GetDatum(datatype_info_element.maximum_scale);

		values[15] = Int32GetDatum(datatype_info_element.sql_data_type);

		if (datatype_info_element.sql_datetime_sub == NULLVAL)
			nulls[16] = true;
		else
			values[16] = Int32GetDatum(datatype_info_element.sql_datetime_sub);

		if (datatype_info_element.num_prec_radix == NULLVAL)
			nulls[17] = true;
		else
			values[17] = Int32GetDatum(datatype_info_element.num_prec_radix);

		if (datatype_info_element.interval_precision == NULLVAL)
			nulls[18] = true;
		else
			values[18] = Int32GetDatum(datatype_info_element.interval_precision);

		values[19] = Int32GetDatum(datatype_info_element.usertype);
		values[20] = Int32GetDatum(datatype_info_element.length);
		values[21] = UInt8GetDatum(datatype_info_element.ss_data_type);

		if (strcmp(datatype_info_element.pg_type_name, NULLVAL_STR) == 0)
			nulls[22] = true;
		else
			values[22] = CStringGetTextDatum(datatype_info_element.pg_type_name);

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	return (Datum) 0;
}

Datum
language(PG_FUNCTION_ARGS)
{
	PG_RETURN_VARCHAR_P(get_language());
}

Datum
host_name(PG_FUNCTION_ARGS)
{
	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_host_name)
		PG_RETURN_VARCHAR_P(string_to_tsql_varchar((*pltsql_protocol_plugin_ptr)->get_host_name()));
	else
		PG_RETURN_NULL();
}

Datum
host_id(PG_FUNCTION_ARGS)
{
	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_client_pid) {
		char *host_id = psprintf("%d", (*pltsql_protocol_plugin_ptr)->get_client_pid());
		PG_RETURN_VARCHAR_P(string_to_tsql_varchar(host_id));
	}
	else
		PG_RETURN_NULL();
}

Datum
context_info(PG_FUNCTION_ARGS)
{
	return bbf_get_context_info(fcinfo);
}

Datum
bbf_get_context_info(PG_FUNCTION_ARGS)
{
	Datum		context_info = (Datum) 0;

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_context_info)
		context_info = (*pltsql_protocol_plugin_ptr)->get_context_info();

	if (DatumGetPointer(context_info))
		PG_RETURN_DATUM(context_info);
	else
		PG_RETURN_NULL();
}

Datum
bbf_set_context_info(PG_FUNCTION_ARGS)
{
	if (PG_ARGISNULL(0))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("SET CONTEXT_INFO option requires varbinary (128) NOT NULL parameter.")));

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_context_info)
		(*pltsql_protocol_plugin_ptr)->set_context_info(PG_GETARG_BYTEA_P(0));

	PG_RETURN_VOID();
}

/** Added in 3_3_0, Deprecated in 3_4_0*/
Datum 
identity_into_smallint(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT16(0);
}

/** Added in 3_3_0, Deprecated in 3_4_0*/
Datum
identity_into_int(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

/** This function is only used for identifying IDENTITY() in SELECT-INTO statement, It is never actually invoked*/
Datum 
identity_into_bigint(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT64(0);
}

/*
 * Execute various integrity checks.
 * Returns true if all the checks pass otherwise
 * raises an appropriate error message.
 */
Datum
babelfish_integrity_checker(PG_FUNCTION_ARGS)
{
	if (!inited_ht_tsql_cast_info)
	{
		ereport(ERROR,
				(errcode(ERRCODE_CHECK_VIOLATION),
				 errmsg("T-SQL cast info hash table is not properly initialized.")));
	}
	else if (!inited_ht_tsql_datatype_precedence_info)
	{
		ereport(ERROR,
				(errcode(ERRCODE_CHECK_VIOLATION),
				 errmsg("T-SQL datatype precedence hash table is not properly initialized.")));
	}

	PG_RETURN_BOOL(true);
}

Datum
bigint_degrees(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result <0)
		result = ceil(result);

	else
		result = floor(result);

	/* Range check */
	if (unlikely(isnan(result) || !FLOAT8_FITS_IN_INT64(result)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("Arithmetic overflow error converting expression to data type bigint")));

	PG_RETURN_INT64((int64) result);
}

Datum
int_degrees(PG_FUNCTION_ARGS)
{
	int32		arg1 = PG_GETARG_INT32(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result <0)
		result = ceil(result);

	else
		result = floor(result);

	/* Range check */
	if (unlikely(isnan(result) || !FLOAT8_FITS_IN_INT32(result)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("Arithmetic overflow error converting expression to data type int")));

	PG_RETURN_INT32((int32) result);
}

Datum
smallint_degrees(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result <0)
		result = ceil(result);

	else
		result = floor(result);

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32) result);
}

Datum
bigint_radians(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int64 */

	PG_RETURN_INT64((int64) result);
}

Datum
int_radians(PG_FUNCTION_ARGS)
{
	int32		arg1 = PG_GETARG_INT32(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32) result);
}

Datum
smallint_radians(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32) result);
}

Datum
bigint_power(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);
	Numeric		arg2 = PG_GETARG_NUMERIC(1);
	int64 result;
	Numeric		arg1_numeric,
				result_trunc,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(int8_numeric, arg1));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_power, NumericGetDatum(arg1_numeric), NumericGetDatum(arg2)));
	result_trunc = DatumGetNumeric(DirectFunctionCall2(numeric_trunc, NumericGetDatum(result_numeric), Int32GetDatum(0)));
	result = DatumGetInt64(DirectFunctionCall1(numeric_int8, NumericGetDatum(result_trunc)));

	PG_RETURN_INT64(result);
}

Datum
int_power(PG_FUNCTION_ARGS)
{
	int32		arg1 = PG_GETARG_INT32(0);
	Numeric		arg2 = PG_GETARG_NUMERIC(1);
	int32 result;
	Numeric		arg1_numeric,
				result_trunc,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(int4_numeric, arg1));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_power, NumericGetDatum(arg1_numeric), NumericGetDatum(arg2)));
	result_trunc = DatumGetNumeric(DirectFunctionCall2(numeric_trunc, NumericGetDatum(result_numeric), Int32GetDatum(0)));
	result = DatumGetInt32(DirectFunctionCall1(numeric_int4, NumericGetDatum(result_trunc)));

	PG_RETURN_INT32(result);
}

Datum
smallint_power(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);
	Numeric		arg2 = PG_GETARG_NUMERIC(1);
	int32 result;
	Numeric		arg1_numeric,
				result_numeric,
				result_trunc;
				
	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(int2_numeric, arg1));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_power, NumericGetDatum(arg1_numeric), NumericGetDatum(arg2)));
	result_trunc = DatumGetNumeric(DirectFunctionCall2(numeric_trunc, NumericGetDatum(result_numeric), Int32GetDatum(0)));
	result = DatumGetInt32(DirectFunctionCall1(numeric_int4, NumericGetDatum(result_trunc)));
	PG_RETURN_INT32(result);
}

Datum
numeric_degrees(PG_FUNCTION_ARGS)
{
	Numeric		arg1 = PG_GETARG_NUMERIC(0);
	Numeric		radians_per_degree,
	result;

	radians_per_degree = DatumGetNumeric(DirectFunctionCall1(float8_numeric, Float8GetDatum(RADIANS_PER_DEGREE)));

	result = DatumGetNumeric(DirectFunctionCall2(numeric_div, NumericGetDatum(arg1), NumericGetDatum(radians_per_degree)));

	PG_RETURN_NUMERIC(result);
}

Datum
numeric_radians(PG_FUNCTION_ARGS)
{
	Numeric		arg1 = PG_GETARG_NUMERIC(0);
	Numeric		radians_per_degree,
	result;

	radians_per_degree = DatumGetNumeric(DirectFunctionCall1(float8_numeric, Float8GetDatum(RADIANS_PER_DEGREE)));

	result = DatumGetNumeric(DirectFunctionCall2(numeric_mul, NumericGetDatum(arg1), NumericGetDatum(radians_per_degree)));

	PG_RETURN_NUMERIC(result);
}

Datum
numeric_log_natural(PG_FUNCTION_ARGS)
{
	float8		arg1 = PG_GETARG_FLOAT8(0);
	float8		result;
	Numeric		arg1_numeric,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(float8_numeric, Float8GetDatum(arg1)));
	result_numeric = DatumGetNumeric(DirectFunctionCall1(numeric_ln, NumericGetDatum(arg1_numeric)));
	result = DatumGetFloat8(DirectFunctionCall1(numeric_float8, NumericGetDatum(result_numeric)));

	PG_RETURN_FLOAT8(result);
}

Datum
numeric_log_base(PG_FUNCTION_ARGS)
{
	float8		arg1 = PG_GETARG_FLOAT8(0);
	int32		arg2 = PG_GETARG_INT32(1);
	float8		result;
	Numeric		arg1_numeric,
				arg2_numeric,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(float8_numeric, Float8GetDatum(arg1)));
	arg2_numeric = DatumGetNumeric(DirectFunctionCall1(int4_numeric, arg2));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_log, NumericGetDatum(arg2_numeric), NumericGetDatum(arg1_numeric)));
	result = DatumGetFloat8(DirectFunctionCall1(numeric_float8, NumericGetDatum(result_numeric)));

	PG_RETURN_FLOAT8(result);
}

Datum
numeric_log10(PG_FUNCTION_ARGS)
{
	float8		arg1 = PG_GETARG_FLOAT8(0);
	float8		result;
	Numeric		arg1_numeric,
				arg2_numeric,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(float8_numeric, Float8GetDatum(arg1)));
	arg2_numeric = DatumGetNumeric(DirectFunctionCall1(int4_numeric, 10));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_log, NumericGetDatum(arg2_numeric), NumericGetDatum(arg1_numeric)));
	result = DatumGetFloat8(DirectFunctionCall1(numeric_float8, NumericGetDatum(result_numeric)));

	PG_RETURN_FLOAT8(result);
}

/* 
* The PARSENAME() function in T-SQL is used to parse a string representing a four-part SQL Server object name, such as "database.schema.object.column".
* If we have an a single '[' ,']' or '"' its a syntax error.
* If object_name is inside brackets like [object_name] its should still return object_name without printing brackets.
* If object_name is inside double quotes like "object_name" its should still return object_name without printing double quotes.
*/
Datum
parsename(PG_FUNCTION_ARGS)
{
    text *object_name = PG_GETARG_TEXT_PP(0);
    int object_piece = PG_GETARG_INT32(1);
    char *object_name_str = text_to_cstring(object_name);
    int len = strlen(object_name_str);
    typedef enum
    {
        STATE_INITIAL,
        STATE_DEFAULT,
        STATE_IN_QUOTES,
        STATE_IN_BRACKETS
    } State;
	State initial_state[4] = {STATE_INITIAL};
    State state = STATE_DEFAULT;
    int consumed;
    int32_t code;
    int total_chars = 0;
    int total_length = 0;
    char c;
    char *start_positions[4] = {NULL};
    char *end_positions[4] = {NULL};
    // int initial_state[4] = {0};
    int current_part = 0;
    text *result;
    start_positions[current_part] = object_name_str;

    // object_piece should only have maximum of 4 parts.
    if (object_piece < 1 || object_piece > 4)
    {
        PG_RETURN_NULL();
    }

    for (int i = 0; i < len;)
    {
        code = (*common_utility_plugin_ptr->GetUTF8CodePoint)((const unsigned char *)&object_name_str[i], len - i, &consumed);
        c = object_name_str[i];
        if (total_chars > 128 || total_length > 256)
        {
            PG_RETURN_NULL();
        }

        if (state == STATE_DEFAULT)
        {
            if (c == '"')
            {
                if (total_chars > 0)
                {
                    PG_RETURN_NULL();
                }

                state = STATE_IN_QUOTES;
                // save the initial state so that we can escape the correct characters at the end.
                if (initial_state[current_part] == STATE_INITIAL)
                {
                    initial_state[current_part] = STATE_IN_QUOTES;
                }

                start_positions[current_part] = &object_name_str[i + 1];
                i += consumed;
                continue;
            }
            else if(c == ']')
            {
                PG_RETURN_NULL();
            }
            else if (c == '[')
            {
                if (total_chars > 0)
                {
                    PG_RETURN_NULL();
                }

                state = STATE_IN_BRACKETS;
                if (initial_state[current_part] == STATE_INITIAL)
                {
                    initial_state[current_part] = STATE_IN_BRACKETS;
                }

                start_positions[current_part] = &object_name_str[i + 1];
                i += consumed;
                continue;
            }
            else if (c == '.')
            {
                // do not update the value of end_positions[current_part] if there is already a value in end_postions[current_part] & previous character is " or ].
                if ( !((end_positions[current_part] != NULL) && (object_name_str[i - 1] == '"')) && !((end_positions[current_part] != NULL) && (object_name_str[i - 1] == ']')) )
                {
                    end_positions[current_part] = &object_name_str[i - 1];
                }

                current_part++;
                if (current_part > 3)
                {
                    PG_RETURN_NULL();
                }

                start_positions[current_part] = &object_name_str[i + 1];
                total_chars = 0;
                total_length = 0;
            }
        }
        else if (state == STATE_IN_QUOTES)
        {
            if (c == '"')
            {
                // is there a next character and is it double quotes?
                if (i + consumed < len && object_name_str[i + consumed] == '"')
                {
                    i += consumed;
                }
                else
                {
                    state = STATE_DEFAULT;
                    end_positions[current_part] = &object_name_str[i - 1];
                    if (i + 1 < len && object_name_str[i + 1] != '.')
                    {
                        PG_RETURN_NULL();
                    }
                    i += consumed;
                    continue;
                }
            }
        }
        else if (state == STATE_IN_BRACKETS)
        {
            if (c == ']')
            {
                // is there a next character and if it is there, is it closing brace?
                if (i + consumed < len && object_name_str[i + consumed] == ']')
                {
                    i += consumed;
                }
                else
                {
                    state = STATE_DEFAULT;
                    end_positions[current_part] = &object_name_str[i - 1];
                    if (i + 1 < len && object_name_str[i + 1] != '.')
                    {
                        PG_RETURN_NULL();
                    }
                    i += consumed;
                    continue;
                }
            }
        }

        // This line increments total_chars by 1 if the current character's Unicode code point is less than or equal to 0xFFFF (i.e., it can be represented in UTF-16), and by 2 otherwise.
        if (state > STATE_DEFAULT || (state == STATE_DEFAULT && c != '.'))
        {
            if (code <= 0xFFFF)
                total_chars += 1;
            else
                total_chars += 2;
            total_length += (code <= 0xFFFF) ? 2 : 4;
        }
        i += consumed;
    }

    if (state != STATE_DEFAULT)
    {
        PG_RETURN_NULL();
    }

    if (total_chars > 128 || total_length > 256)
    {
        PG_RETURN_NULL();
    }

    // if there is only 1 part and no '.', set the end position to length-1.
    if (end_positions[current_part] == NULL)
    {
        end_positions[current_part] = &object_name_str[len - 1];
    }

    // Reverse the object piece index
    object_piece = current_part + 1 - object_piece;
    if (object_piece < 0 || object_piece > current_part)
    {
        PG_RETURN_NULL();
    }
    
    if (object_piece >= 0 && object_piece <= current_part)
    {
        int part_length = end_positions[object_piece] - start_positions[object_piece] + 1;
        if (part_length > 0)
        {
            char *part = (char*) palloc(part_length + 1); // Allocate memory for part string
            int part_index = 0;
            for (int j = 0; j < part_length; j++)
            {
                // Copy part string with handling of escaped double quotes and closing brackets and checking initial state.
                if ( (initial_state[object_piece] == STATE_IN_QUOTES && start_positions[object_piece][j] == '"' && start_positions[object_piece][j + 1] == '"') ||
					 (initial_state[object_piece] == STATE_IN_BRACKETS && start_positions[object_piece][j] == ']' && start_positions[object_piece][j + 1] == ']'))
                {
                    part[part_index++] = start_positions[object_piece][j++];
                }
                else
                {
                    part[part_index++] = start_positions[object_piece][j];
                }
            }
            part[part_index] = '\0'; // Null-terminate part string
            result = cstring_to_text(part);
            pfree(part); // Free part string memory
            PG_RETURN_TEXT_P(result);
        }
    }

    PG_RETURN_NULL();
}

/* Returns the database schema name for schema-scoped objects. */
Datum
object_schema_name(PG_FUNCTION_ARGS)
{
	Oid			object_id;
	Oid			database_id;
	Oid			user_id = GetUserId();
	Oid			namespace_oid = InvalidOid;
	Oid			temp_nspid = InvalidOid;
	char	   *namespace_name;
	const char *schema_name;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();
	else
		object_id = (Oid) PG_GETARG_INT32(0);

	if (PG_ARGISNULL(1))
		database_id = get_cur_db_id();
	else
	{
		database_id = (Oid) PG_GETARG_INT32(1);
		user_id = GetSessionUserId();
	}

	/* lookup namespace_oid in pg_class */
	temp_nspid = get_rel_namespace(object_id);
	if (OidIsValid(temp_nspid))
	{
		if (pg_class_aclcheck(object_id, user_id, ACL_SELECT) == ACLCHECK_OK)
			namespace_oid = temp_nspid;
		else
			PG_RETURN_NULL();
	}
	if (!OidIsValid(namespace_oid))
	{							/* if not found earlier */
		/* Lookup namespace_oid in pg_proc */
		temp_nspid = tsql_get_proc_nsp_oid(object_id);
		if (OidIsValid(temp_nspid))
		{
			if (object_aclcheck(ProcedureRelationId, object_id, user_id, ACL_EXECUTE) == ACLCHECK_OK)
				namespace_oid = temp_nspid;
			else
				PG_RETURN_NULL();
		}
	}
	if (!OidIsValid(namespace_oid))
	{							/* if not found earlier */
		/* Lookup namespace_oid in pg_trigger */
		temp_nspid = tsql_get_trigger_rel_oid(object_id);
		if (OidIsValid(temp_nspid))
		{
			/*
			 * Since pg_trigger does not contain namespace oid, we use the
			 * fact that the schema name of the trigger should be same as that
			 * of the table the trigger is on
			 */
			if (pg_class_aclcheck(temp_nspid, user_id, ACL_SELECT) == ACLCHECK_OK)
				namespace_oid = get_rel_namespace(temp_nspid);
			else
				PG_RETURN_NULL();
		}
	}
	if (!OidIsValid(namespace_oid))
	{							/* if not found earlier */
		/* Lookup namespace_oid in pg_constraint */
		namespace_oid = tsql_get_constraint_nsp_oid(object_id, user_id);
	}

	/* Find schema name from namespace_oid */
	if (OidIsValid(namespace_oid))
	{
		namespace_name = get_namespace_name(namespace_oid);
		if (object_aclcheck(NamespaceRelationId, namespace_oid, user_id, ACL_USAGE) != ACLCHECK_OK ||
		/* database_id should be same as that of db_id of physical schema name */
			database_id != get_dbid_from_physical_schema_name(namespace_name, true))
			PG_RETURN_NULL();
		schema_name = get_logical_schema_name(namespace_name, true);
		pfree(namespace_name);
		PG_RETURN_TEXT_P(cstring_to_text(schema_name));
	}
	else
		PG_RETURN_NULL();
}

Datum
pg_extension_config_remove(PG_FUNCTION_ARGS)
{
	Oid			tableoid = PG_GETARG_OID(0);
	char	   *tablename = get_rel_name(tableoid);

	/*
	 * We only allow this to be called from an extension's SQL script. We
	 * shouldn't need any permissions check beyond that.
	 */
	if (!creating_extension)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("%s can only be called from an SQL script executed by CREATE/ALTER EXTENSION",
						"pg_extension_config_remove()")));
	if (tablename == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_TABLE),
				 errmsg("OID %u does not refer to a table", tableoid)));
	if (getExtensionOfObject(RelationRelationId, tableoid) !=
		CurrentExtensionObject)
		ereport(ERROR,
				(errcode(ERRCODE_OBJECT_NOT_IN_PREREQUISITE_STATE),
				 errmsg("table \"%s\" is not a member of the extension being created",
						tablename)));

	extension_config_remove_wrapper(CurrentExtensionObject, tableoid);

	PG_RETURN_VOID();
}

/*
 * The EOMONTH function is a Transact-SQL function in SQL Server that returns 
 * the last day of the month of a specified date, with an optional offset.
 */
Datum
EOMONTH(PG_FUNCTION_ARGS)
{
    int year, month, day;
    int offset = 0;
    DateADT date;
    bool isOffsetGiven = false;
    bool isOriginalDateOutsideTSQLEndLimit = false;

    if (PG_ARGISNULL(0))
    {
        PG_RETURN_NULL();
    }
    else
    {
        date = PG_GETARG_DATEADT(0);
    }

    if (!PG_ARGISNULL(1))
    {
        offset = PG_GETARG_INT32(1);
        isOffsetGiven = true;
    }

    /* Convert the date to year, month, day */
    j2date(date + POSTGRES_EPOCH_JDATE, &year, &month, &day);

    /* This flag is required later to check and throw the T-SQL compatibility error. */
    isOriginalDateOutsideTSQLEndLimit = year < 1 || year > 9999;

    /* Adjust the month based on the offset */
    month += offset;

    /* 
     * Check if the new month is greater than 0, which indicates a positive offset. 
     * If it is true, the months continue to increase one by one, until they reach 12. After this point, they revert back to 1 and 
     * if the months exceed 12, it signifies that we must also increment the year.
     * 
     * If it is false, the months continue to decrease one by one, until they reach 1. After this point, they will reset to 12 and 
     * if the months go below 1, it signifies that we must also decrement the year.
     */
    if(month > 0)
    {
        /* 
         * The year value is incremented by how many full sets of 12 months fit into the 'month' value.
         * Subtracting 1 from 'month' before dividing ensures we don't count an extra year when 'month' is exactly divisible by 12.
         * We are considering 12 months as a full year, so if we have exactly 12 months, we should not increment the year yet.
         */
        year += (month - 1) / 12;
		
        /* 
         * The new month value is calculated based on the remainder when divided by 12.
         * This makes sure the month value stays within the range of 1 to 12. The subtraction by 1 and addition by 1
         * ensure that the month value starts from 1 (January) rather than 0.
         */
        month = (month - 1) % 12 + 1; 
    }
    else
    {
        /* 
         * The year value is decremented based on how many full sets of 12 months fit into the 'month' value.
         * This calculates how many years to decrement given the total number of negative months.
         */
        year += month / 12 - 1;

        /* 
         * The new month value is calculated based on the modulus operation when divided by 12.
         * If the month value is negative, this operation makes sure the month value stays within the range of 1 to 12.
         */
        month = month % 12 + 12;
    }

    /* Now move to the first day of the next month */
    month++;

    /* If the new year is less than 1 or greater than 9999, report an error. */
    if (year < 1 || year > 9999)
    {
        /* If the offset was given by the user and the provided year was within T-SQL range, throw overflow error else throw T-SQL compatibility error. */
        if (isOffsetGiven && !isOriginalDateOutsideTSQLEndLimit)
        {
            ereport(ERROR,
                (errcode(ERRCODE_DATETIME_FIELD_OVERFLOW),
                 errmsg("Adding a value to a 'date' column caused an overflow.")));
        }
        else
        {
            ereport(ERROR,
                (errcode(ERRCODE_DATETIME_FIELD_OVERFLOW),
                 errmsg("The date exceeds T-SQL compatibility limits.")));
        }
    }

    /* 
     * Convert the year, month, and day (1st day of the new month) back date format, then subtract one day 
     * to get the last day of the "offset" month.
     */
    date = date2j(year, month, 1) - POSTGRES_EPOCH_JDATE - 1;
    PG_RETURN_DATEADT(date);
}

/*
 * Funtion used to check whether the object is MS shipped. 
 * This is being used in objectproperty_internal.
 */
bool is_ms_shipped(char *object_name, int type, Oid schema_id)
{
	int	i = 0;
	bool	is_ms_shipped = false;
	char	*namespace_name = NULL;
	/*
	 * This array contains information of objects that reside in a schema in one specfic database.
	 * For example, 'master_dbo' schema can only exist in the 'master' database.
	 */
#define NUM_DB_OBJECTS 11
	int	shipped_objects_not_in_sys_db_type[NUM_DB_OBJECTS] = {
		OBJECT_TYPE_TSQL_STORED_PROCEDURE, OBJECT_TYPE_TSQL_STORED_PROCEDURE,
		OBJECT_TYPE_TSQL_STORED_PROCEDURE, OBJECT_TYPE_TSQL_STORED_PROCEDURE,
		OBJECT_TYPE_TSQL_STORED_PROCEDURE, OBJECT_TYPE_TSQL_STORED_PROCEDURE,
		OBJECT_TYPE_TSQL_STORED_PROCEDURE, OBJECT_TYPE_TSQL_SCALAR_FUNCTION,
		OBJECT_TYPE_VIEW, OBJECT_TYPE_VIEW, OBJECT_TYPE_TSQL_STORED_PROCEDURE
	};
	char	*shipped_objects_not_in_sys_db[NUM_DB_OBJECTS][2] = {
		{"xp_qv","master_dbo"},
		{"xp_instance_regread","master_dbo"},
		{"sp_addlinkedserver", "master_dbo"},
		{"sp_addlinkedsrvlogin", "master_dbo"},
		{"sp_dropserver", "master_dbo"},
		{"sp_droplinkedsrvlogin", "master_dbo"},
		{"sp_testlinkedserver", "master_dbo"},
		{"fn_syspolicy_is_automation_enabled", "msdb_dbo"},
		{"syspolicy_configuration", "msdb_dbo"},
		{"syspolicy_system_health_state", "msdb_dbo"},
		{"sp_enum_oledb_providers", "master_dbo"}
	};

	/*
	 * This array contains information of objects that reside in a schema in any number of databases.
     	 * For example, 'dbo' schema can exist in the 'master', 'tempdb', 'msdb', and any user created database.
	 */
#define NUM_ALL_DB_OBJECTS 1
	int	shipped_objects_not_in_sys_all_db_type[NUM_ALL_DB_OBJECTS] = {OBJECT_TYPE_VIEW};
	char	*shipped_objects_not_in_sys_all_db[NUM_ALL_DB_OBJECTS][2] = {
		{"sysdatabases","dbo"}
	};

	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData 	scanKey;
	SysScanDesc 	scan;
	Datum		datum;
	TupleDesc	dsc;


	namespace_name = get_namespace_name(schema_id);

	if (pg_strcasecmp(namespace_name, "sys") == 0)
		is_ms_shipped = true;
		

	/*
	 * Check whether the object is present in shipped_objects_not_in_sys_db.
	 */
	for (i = 0; i < NUM_DB_OBJECTS; i++)
	{
		if (is_ms_shipped || (type == shipped_objects_not_in_sys_db_type[i] &&
			pg_strcasecmp(object_name, shipped_objects_not_in_sys_db[i][0]) == 0 &&
			pg_strcasecmp(namespace_name, shipped_objects_not_in_sys_db[i][1]) == 0))
		{
			is_ms_shipped = true;
			break;
		}
	}
#undef NUM_DB_OBJECTS

	rel = table_open(namespace_ext_oid, AccessShareLock);
	dsc = RelationGetDescr(rel);

	/*
	 * Check whether the object is present in shipped_objects_not_in_sys_all_db.
	 * 
	 * As the objects in shipped_objects_not_in_sys_all_db can be present in any number of databases, 
	 * We scan the pg_namespace catalog to find the occurences in all the databases and find whether 
	 * any entry matches the object that we are looking for.
	 */
	for (i = 0; i < NUM_ALL_DB_OBJECTS; i++)
	{
		char		*tempnspname = NULL;
		bool		isNull = false;

		if (is_ms_shipped)
			break;
		if (type != shipped_objects_not_in_sys_all_db_type[i])
			continue;

		ScanKeyInit(&scanKey,
					Anum_namespace_ext_orig_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					CStringGetDatum(shipped_objects_not_in_sys_all_db[i][1]));

		scan = systable_beginscan(rel, InvalidOid, false,
							  		NULL, 1, &scanKey);

		while (HeapTupleIsValid(tuple = systable_getnext(scan)))
		{
			datum = heap_getattr(tuple, Anum_namespace_ext_namespace, dsc, &isNull);
			tempnspname = TextDatumGetCString(datum);
			if (pg_strcasecmp(namespace_name, tempnspname) == 0)
			{
				is_ms_shipped = true;
				break;
			}
		}

		systable_endscan(scan);
		if (tempnspname)
			pfree(tempnspname);
	}
#undef NUM_ALL_DB_OBJECTS

	table_close(rel, AccessShareLock);

	return is_ms_shipped;
}

Datum
objectproperty_internal(PG_FUNCTION_ARGS)
{
	Oid		object_id;
	Oid		schema_id = InvalidOid;
	char		*property;
	Oid		user_id = GetUserId();
	HeapTuple	tuple;
	int		type = 0;
	char		*object_name = NULL;
	char		*nspname = NULL;

	if (PG_ARGISNULL(0) || PG_ARGISNULL(1))
		PG_RETURN_NULL();
	else
	{
		object_id = (Oid) PG_GETARG_INT32(0);
		property = text_to_cstring(PG_GETARG_TEXT_P(1));
		property = downcase_identifier(property, strlen(property), false, true);
		remove_trailing_spaces(property);
	}

	/*
	 * Search for the object_id in pg_class, pg_proc, pg_attrdef, pg_constraint.
	 * If the object_id is not found in any of the above catalogs, return NULL.
	 * Else, get the object name, type of the object and the schema_id in which 
	 * the object is present.
	 */

	/* pg_class */
	tuple = SearchSysCache1(RELOID, ObjectIdGetDatum(object_id));
	if (HeapTupleIsValid(tuple))
	{
		Form_pg_class pg_class = (Form_pg_class) GETSTRUCT(tuple);

		object_name = NameStr(pg_class->relname);

		if (pg_class_aclcheck(object_id, user_id, ACL_SELECT) == ACLCHECK_OK)
			schema_id = get_rel_namespace(object_id);

		/* 
		 * Get the type of the object 
		 */
		if ((pg_class->relpersistence == 'p' || pg_class->relpersistence == 'u' || pg_class->relpersistence == 't') &&
				(pg_class->relkind == 'r'))
		{
			/* 
			 * Check whether it is a Table type (TT) object.
			 * The reltype of the pg_class object should be there in pg_type. The pg_type object found
			 * should be of composite type (c) and the type of dependency should be DEPENDENCY_INTERNAL (i).
			 * We scan pg_depend catalog to find the type of the dependency.
			 */
			HeapTuple tp;
			tp = SearchSysCache1(TYPEOID, ObjectIdGetDatum(pg_class->reltype));
			if(HeapTupleIsValid(tp))
			{
				Form_pg_type typform = (Form_pg_type) GETSTRUCT(tp);

				if (typform->typtype == 'c')
				{
					Relation	depRel;
					ScanKeyData key[2];
					SysScanDesc scan;
					HeapTuple	tup;

					depRel = table_open(DependRelationId, RowExclusiveLock);

					ScanKeyInit(&key[0],
								Anum_pg_depend_objid,
								BTEqualStrategyNumber, F_OIDEQ,
								ObjectIdGetDatum(typform->typrelid));
					ScanKeyInit(&key[1],
								Anum_pg_depend_refobjid,
								BTEqualStrategyNumber, F_OIDEQ,
								ObjectIdGetDatum(typform->oid));

					scan = systable_beginscan(depRel, InvalidOid, false,
							  				NULL, 2, key);

					if (HeapTupleIsValid(tup = systable_getnext(scan)))
					{
						Form_pg_depend depform = (Form_pg_depend) GETSTRUCT(tup);

						if (depform->deptype == 'i')
							type = OBJECT_TYPE_TABLE_TYPE;
					}

					systable_endscan(scan);

					table_close(depRel, RowExclusiveLock);
				}
				ReleaseSysCache(tp);
			}
			/*
			 * If the object is not of Table type (TT), it should be user defined table (U)
			 */
			if (type == 0 || type != OBJECT_TYPE_TABLE_TYPE)
				type = OBJECT_TYPE_TABLE;
		}
		else if (pg_class->relkind == 'v')
			type = OBJECT_TYPE_VIEW;
		else if (pg_class->relkind == 's')
			type = OBJECT_TYPE_SEQUENCE_OBJECT;

		ReleaseSysCache(tuple);
	}
	/* pg_proc */
	if (!schema_id)
	{
		tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			if (object_aclcheck(ProcedureRelationId, object_id, user_id, ACL_EXECUTE) == ACLCHECK_OK)
			{
				Form_pg_proc procform = (Form_pg_proc) GETSTRUCT(tuple);

				object_name = NameStr(procform->proname);

				schema_id = tsql_get_proc_nsp_oid(object_id);

				if (procform->prokind == 'p')
				type = OBJECT_TYPE_TSQL_STORED_PROCEDURE;
				else if (procform->prokind == 'a')
					type = OBJECT_TYPE_AGGREGATE_FUNCTION;
				else
				{
					/*
					 * Check whether the object is SQL DML trigger(TR), SQL table-valued-function (TF),
					 * SQL inline table-valued function (IF), SQL scalar function (FN).
					 */
					char	*temp = format_type_extended(procform->prorettype, -1, FORMAT_TYPE_ALLOW_INVALID);
					/*
					 * If the prorettype of the pg_proc object is "trigger", then the type of the object is "TR"
					 */
					if (pg_strcasecmp(temp, "trigger") == 0) 
						type = OBJECT_TYPE_TSQL_DML_TRIGGER;
					/*
					 * For SQL table-valued-functions and SQL inline table-valued functions, re-implement the existing SQL.
					 */
					else if (procform->proretset)
					{
						HeapTuple tp;
						tp = SearchSysCache1(TYPEOID, ObjectIdGetDatum(procform->prorettype));
						if (HeapTupleIsValid(tp))
						{
							Form_pg_type typeform = (Form_pg_type) GETSTRUCT(tuple);

							if (typeform->typtype == 'c')
								type = OBJECT_TYPE_TSQL_TABLE_VALUED_FUNCTION;
							else
								type = OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION;

							ReleaseSysCache(tp);
						}
					}
					else
						type = OBJECT_TYPE_TSQL_SCALAR_FUNCTION;
					
					pfree(temp);
				}
			}
			ReleaseSysCache(tuple);
		}
	}
	/* pg_attrdef */
	if (!schema_id)
	{
		Relation	attrdefrel;
		ScanKeyData key;
		SysScanDesc attrscan;

		attrdefrel = table_open(AttrDefaultRelationId, AccessShareLock);
		ScanKeyInit(&key,
					Anum_pg_attrdef_oid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(object_id));

		attrscan = systable_beginscan(attrdefrel, AttrDefaultOidIndexId, true,
									NULL, 1, &key);

		tuple = systable_getnext(attrscan);
		if (HeapTupleIsValid(tuple))
		{
			/*
			 * scan pg_attribute catalog to find the corresponding row.
			 * This pg_attribute pbject will be helpful to check whether the object is DEFAULT (D)
			 * and to find the schema_id.
			 */
			Form_pg_attrdef atdform = (Form_pg_attrdef) GETSTRUCT(tuple);
			Relation	attrRel;
			ScanKeyData key[2];
			SysScanDesc scan;
			HeapTuple	tup;

			if (pg_attribute_aclcheck(atdform->adrelid, atdform->adnum, user_id, ACL_SELECT) &&
				pg_attribute_aclcheck(atdform->adrelid, atdform->adnum, user_id, ACL_INSERT) &&
				pg_attribute_aclcheck(atdform->adrelid, atdform->adnum, user_id, ACL_UPDATE) &&
				pg_attribute_aclcheck(atdform->adrelid, atdform->adnum, user_id, ACL_REFERENCES))
			{
				attrRel = table_open(AttributeRelationId, RowExclusiveLock);

				ScanKeyInit(&key[0],
							Anum_pg_attribute_attrelid,
							BTEqualStrategyNumber, F_OIDEQ,
							ObjectIdGetDatum(atdform->adrelid));
				ScanKeyInit(&key[1],
							Anum_pg_attribute_attnum,
							BTEqualStrategyNumber, F_INT2EQ,
							Int16GetDatum(atdform->adnum));

				scan = systable_beginscan(attrRel, AttributeRelidNumIndexId, true,
						  				NULL, 2, key);

				if (HeapTupleIsValid(tup = systable_getnext(scan)))
				{
					Form_pg_attribute attrform = (Form_pg_attribute) GETSTRUCT(tup);

					if (attrform->atthasdef && !attrform->attgenerated)
					{
						object_name = NameStr(attrform->attname);
						type = OBJECT_TYPE_DEFAULT_CONSTRAINT;
						if (pg_class_aclcheck(atdform->adrelid, user_id, ACL_SELECT) == ACLCHECK_OK)
							schema_id = get_rel_namespace(atdform->adrelid);
					}
				}

				systable_endscan(scan);

				table_close(attrRel, RowExclusiveLock);
			}

		}
		systable_endscan(attrscan);
		table_close(attrdefrel, AccessShareLock);
	}
	/* pg_constraint */
	if (!schema_id)
	{
		tuple = SearchSysCache1(CONSTROID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);
			object_name = NameStr(con->conname);
			schema_id = tsql_get_constraint_nsp_oid(object_id, user_id);
			/*
			 * If the contype is 'f' on the pg_constraint object, then it is a Foreign key constraint
			 */
			if (con->contype == 'f')
				type = OBJECT_TYPE_FOREIGN_KEY_CONSTRAINT;
			/*
			 * If the contype is 'p' on the pg_constraint object, then it is a Primary key constraint
			 */
			else if (con->contype == 'p')
				type = OBJECT_TYPE_PRIMARY_KEY_CONSTRAINT;
			/*
			 * Reimplemented the existing SQL .
			 * If the contype is 'c' and conrelid is 0 on the pg_constraint object, then it is a Check constraint
			 */
			else if (con->contype == 'c' && con->conrelid != 0)
				type = OBJECT_TYPE_CHECK_CONSTRAINT;
			
			ReleaseSysCache(tuple);
		}
	}

	/*
	 * If the object_id is not found or user does not have enough privileges on the object and schema,
	 * Return NULL.
	 */
	if (!schema_id || object_aclcheck(NamespaceRelationId, schema_id, user_id, ACL_USAGE) != ACLCHECK_OK)
	{
		pfree(property);
		PG_RETURN_NULL();
	}

	/*
	 * schema_id found should be in sys.schemas view except 'sys'.
	 */
	nspname = get_namespace_name(schema_id);

	if (!(nspname && pg_strcasecmp(nspname, "sys") == 0) && 
		(!nspname || pg_strcasecmp(nspname, "pg_catalog") == 0 ||
		pg_strcasecmp(nspname, "pg_toast") == 0 ||
		pg_strcasecmp(nspname, "public") == 0))
	{
		pfree(property);
		if (nspname)
			pfree(nspname);

		PG_RETURN_NULL();
	}

	pfree(nspname);

	/* OwnerId */
	if (pg_strcasecmp(property, "ownerid") == 0)
	{
		/*
		 * Search for schema_id in pg_namespace catalog. Return nspowner from 
		 * the found pg_namespace object.
		 */
		if (OidIsValid(schema_id))
		{
			HeapTuple	tp;
			int		result;

			tp = SearchSysCache1(NAMESPACEOID, ObjectIdGetDatum(schema_id));
			if (HeapTupleIsValid(tp))
			{
				Form_pg_namespace nsptup = (Form_pg_namespace) GETSTRUCT(tp);
				result = ((int) nsptup->nspowner);
				ReleaseSysCache(tp);
			}
			else
			{
				pfree(property);
				PG_RETURN_NULL();
			}
			pfree(property);
			PG_RETURN_INT32(result);
		}
	}
	/* IsDefaultCnst */
	else if (pg_strcasecmp(property, "isdefaultcnst") == 0)
	{
		/*
		 * The type of the object should be OBJECT_TYPE_DEFAULT_CONSTRAINT.
		 */
		if (type == OBJECT_TYPE_DEFAULT_CONSTRAINT)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* ExecIsQuotedIdentOn, IsSchemaBound, ExecIsAnsiNullsOn */
	else if (pg_strcasecmp(property, "execisquotedidenton") == 0 ||
			pg_strcasecmp(property, "isschemabound") == 0 ||
			pg_strcasecmp(property, "execisansinullson") == 0)
	{
		/*
		 * These properties are only applicable to OBJECT_TYPE_TSQL_STORED_PROCEDURE, OBJECT_TYPE_REPLICATION_FILTER_PROCEDURE,
		 * OBJECT_TYPE_VIEW, OBJECT_TYPE_TSQL_DML_TRIGGER, OBJECT_TYPE_TSQL_SCALAR_FUNCTION, OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION, 
		 * OBJECT_TYPE_TSQL_TABLE_VALUED_FUNCTION and OBJECT_TYPE_RULE.
		 * Hence, return NULL if the object is not from the above types.
		 */
		if (!(type == OBJECT_TYPE_TSQL_STORED_PROCEDURE || type == OBJECT_TYPE_REPLICATION_FILTER_PROCEDURE ||
			type == OBJECT_TYPE_VIEW || type == OBJECT_TYPE_TSQL_DML_TRIGGER || type == OBJECT_TYPE_TSQL_SCALAR_FUNCTION ||
			type == OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION || type == OBJECT_TYPE_TSQL_TABLE_VALUED_FUNCTION ||
			type == OBJECT_TYPE_RULE))
		{
			pfree(property);
			PG_RETURN_NULL();
		}

		/*
		 * Currently, for IsSchemaBound property, we have hardcoded the value to 0
		 */
		if (pg_strcasecmp(property, "isschemabound") == 0)
		{
			pfree(property);
			PG_RETURN_INT32(0);
		}
		/*
		 * For ExecIsQuotedIdentOn and ExecIsAnsiNullsOn, we hardcoded it to 1
		 */
		pfree(property);
		PG_RETURN_INT32(1);
	}
	/* TableFullTextPopulateStatus, TableHasVarDecimalStorageFormat */
	else if (pg_strcasecmp(property, "tablefulltextpopulatestatus") == 0 ||
			pg_strcasecmp(property, "tablehasvardecimalstorageformat") == 0)
	{
		/*
		 * Currently, we have hardcoded the return value to 0.
		 */
		if (type == OBJECT_TYPE_TABLE)
		{
			pfree(property);
			PG_RETURN_INT32(0);
		}
		/*
		 * These properties are only applicable if the type of the object is TABLE, 
		 * Hence, return NULL if the object is not a TABLE.
		 */
		pfree(property);
		PG_RETURN_NULL();		
	}
	/* IsMSShipped*/
	else if (pg_strcasecmp(property, "ismsshipped") == 0)
	{
		/*
		 * Check whether the object is MS shipped. We are using is_ms_shipped helper function
		 * to check the same.
		 */
		if (is_ms_shipped(object_name, type, schema_id))
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsDeterministic */
	else if (pg_strcasecmp(property, "isdeterministic") == 0)
	{
		/*
		 * Currently, we hardcoded the value to 0.
		 */
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsProcedure */
	else if (pg_strcasecmp(property, "isprocedure") == 0)
	{
		/*
		 * Check whether the type of the object is OBJECT_TYPE_TSQL_STORED_PROCEDURE.
		 */
		if (type == OBJECT_TYPE_TSQL_STORED_PROCEDURE)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsTable */
	else if (pg_strcasecmp(property, "istable") == 0)
	{
		/*
		 * The type of the object should be OBJECT_TYPE_INTERNAL_TABLE or OBJECT_TYPE_TABLE_TYPE or
		 * TABLE or OBJECT_TYPE_SYSTEM_BASE_TABLE.
		 */
		if (type == OBJECT_TYPE_INTERNAL_TABLE || type == OBJECT_TYPE_TABLE_TYPE ||
			type == OBJECT_TYPE_TABLE || type == OBJECT_TYPE_SYSTEM_BASE_TABLE)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);		
	}
	/* IsView */
	else if (pg_strcasecmp(property, "isview") == 0)
	{
		/*
		 * The type of the object should be OBJECT_TYPE_VIEW.
		 */
		if (type == OBJECT_TYPE_VIEW)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsUserView */
	else if (pg_strcasecmp(property, "isusertable") == 0)
	{
		/*
		 * The object should be of the type TABLE and should not be MS shipped.
		 */
		if (type == OBJECT_TYPE_TABLE && is_ms_shipped(object_name, type, schema_id) == 0)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsTableFunction */
	else if (pg_strcasecmp(property, "istablefunction") == 0)
	{
		/*
		 * The object should be OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION or OBJECT_TYPE_TSQL_TABLE_VALUED_FUNCTION
		 * OBJECT_TYPE_ASSEMBLY_TABLE_VALUED_FUNCTION.
		 */
		if (type == OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION || type == OBJECT_TYPE_TSQL_TABLE_VALUED_FUNCTION ||
			type == OBJECT_TYPE_ASSEMBLY_TABLE_VALUED_FUNCTION)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);	
	}
	/* IsInlineFunction */
	else if (pg_strcasecmp(property, "isinlinefunction") == 0)
	{
		/*
		 * The object should be OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION.
		 */
		if (type == OBJECT_TYPE_TSQL_INLINE_TABLE_VALUED_FUNCTION)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);

	}
	/* IsScalarFunction */
	else if (pg_strcasecmp(property, "isscalarfunction") == 0)
	{
		/*
		 * The object should be either OBJECT_TYPE_TSQL_SCALAR_FUNCTION or OBJECT_TYPE_ASSEMBLY_SCALAR_FUNCTION.
		 */
		if (type == OBJECT_TYPE_TSQL_SCALAR_FUNCTION || type == OBJECT_TYPE_ASSEMBLY_SCALAR_FUNCTION)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsPrimaryKey */
	else if (pg_strcasecmp(property, "isprimarykey") == 0)
	{
		/*
		 * The object should be a OBJECT_TYPE_PRIMARY_KEY_CONSTRAINT.
		 */
		if (type == OBJECT_TYPE_PRIMARY_KEY_CONSTRAINT)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsIndexed */
	else if (pg_strcasecmp(property, "isindexed") == 0)
	{
		/*
		 * Search for object_id in pg_index catalog by indrelid column.
		 * The object is indexed if the entry exists in pg_index.
		 */
		Relation	indRel;
		ScanKeyData 	key;
		SysScanDesc 	scan;
		HeapTuple	tup;

		if (type != OBJECT_TYPE_TABLE)
			PG_RETURN_INT32(0);

		indRel = table_open(IndexRelationId, RowExclusiveLock);

		ScanKeyInit(&key,
				Anum_pg_index_indrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(object_id));

		scan = systable_beginscan(indRel, IndexIndrelidIndexId, true,
				  		NULL, 1, &key);

		if (HeapTupleIsValid(tup = systable_getnext(scan)))
		{
			systable_endscan(scan);
			table_close(indRel, RowExclusiveLock);
			pfree(property);
			PG_RETURN_INT32(1);
		}

		systable_endscan(scan);
		table_close(indRel, RowExclusiveLock);
		pfree(property);

		PG_RETURN_INT32(0);
	}
	/* IsDefault */
	else if (pg_strcasecmp(property, "isdefault") == 0)
	{
		/*
		 * Currently hardcoded to 0.
		 */
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsOBJECT_TYPE_RULE */
	else if (pg_strcasecmp(property, "isrule") == 0)
	{
		/*
		 * Currently hardcoded to 0.
		 */
		pfree(property);
		PG_RETURN_INT32(0);
	}
	/* IsTrigger */
	else if (pg_strcasecmp(property, "istrigger") == 0)
	{
		/*
		 * The type of the object should be OBJECT_TYPE_ASSEMBLY_DML_TRIGGER.
		 */
		if (type == OBJECT_TYPE_ASSEMBLY_DML_TRIGGER)
		{
			pfree(property);
			PG_RETURN_INT32(1);
		}
		pfree(property);
		PG_RETURN_INT32(0);
	}
	
	if (property)
		pfree(property);

	PG_RETURN_NULL();
}

PG_FUNCTION_INFO_V1(bbf_pivot);
Datum
bbf_pivot(PG_FUNCTION_ARGS)
{	
	ReturnSetInfo   *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc		tupdesc;
	MemoryContext 	per_query_ctx;
	MemoryContext 	oldcontext;
	HTAB	   	   	*bbf_pivot_hash;
	char			*src_sql_string;
	char			*cat_sql_string;
	char			*funcName;

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize) ||
		rsinfo->expectedDesc == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));
	
	src_sql_string = text_to_cstring(PG_GETARG_TEXT_PP(0));
	cat_sql_string = text_to_cstring(PG_GETARG_TEXT_PP(1));
	funcName = text_to_cstring(PG_GETARG_TEXT_PP(2));

	/* check if babelfish pivot metadata is complete */
	if (src_sql_string == NULL || cat_sql_string == NULL || funcName == NULL 
		|| strlen(src_sql_string) == 0 || strlen(src_sql_string) == 0 || strlen(funcName) == 0)
	{
		ereport(ERROR,
			(errcode(ERRCODE_CHECK_VIOLATION),
				errmsg("Babelfish PIVOT is not properly initialized.")));
	}
		
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	/* get the requested return tuple description */
	tupdesc = CreateTupleDescCopy(rsinfo->expectedDesc);

	/*
	 * Check to make sure we have a reasonable tuple descriptor
	 *
	 * Note we will attempt to coerce the values into whatever the return
	 * attribute type is and depend on the "in" function to complain if
	 * needed.
	 */
	if (tupdesc->natts < 2)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("query-specified return tuple and " \
						"bbf_pivot function are not compatible")));

	/* load up the categories hash table */
	bbf_pivot_hash = load_categories_hash(cat_sql_string, per_query_ctx);

	/* let the caller know we're sending back a tuplestore */
	rsinfo->returnMode = SFRM_Materialize;

	/* now go build it */
	rsinfo->setResult = get_bbf_pivot_tuplestore(src_sql_string,
												funcName,
												bbf_pivot_hash,
												tupdesc,
												rsinfo->allowedModes & SFRM_Materialize_Random);

	/*
	 * SFRM_Materialize mode expects us to return a NULL Datum. The actual
	 * tuples are in our tuplestore and passed back through rsinfo->setResult.
	 * rsinfo->setDesc is set to the tuple description that we actually used
	 * to build our tuples with, so the caller can verify we did what it was
	 * expecting.
	 */
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);
	return (Datum) 0;
}

/*
 * load up the categories hash table
 */
static HTAB *
load_categories_hash(const char 	*sourcetext, 
					 MemoryContext 	per_query_ctx)
{
	HTAB	   *bbf_pivot_hash;
	HASHCTL		ctl;
	int			ret;
	uint64		tuple_processed;
	MemoryContext oldcontext;

	/* initialize the category hash table */
	ctl.keysize = MAX_CATNAME_LEN;
	ctl.entrysize = sizeof(bbf_pivot_HashEnt);
	ctl.hcxt = per_query_ctx;

	/*
	 * use INIT_CATS, defined above as a guess of how many hash table entries
	 * to create, initially
	 */
	bbf_pivot_hash = hash_create("bbf_pivot hash",
								INIT_CATS,
								&ctl,
								HASH_ELEM | HASH_STRINGS | HASH_CONTEXT);

	/* Connect to SPI manager */
	if ((ret = SPI_connect()) < 0)
		/* internal error */
		elog(ERROR, "load_categories_hash: SPI_connect returned %d", ret);

	/* Retrieve the category name rows */
	ret = SPI_execute(sourcetext, true, 0);
	tuple_processed = SPI_processed;

	/* Check for qualifying tuples */
	if ((ret == SPI_OK_SELECT) && (tuple_processed > 0))
	{
		SPITupleTable *spi_tuptable = SPI_tuptable;
		TupleDesc	spi_tupdesc = spi_tuptable->tupdesc;
		uint64		i;

		/*
		 * The provided categories SQL query must always return one column:
		 * category - the label or identifier for each column
		 */
		if (spi_tupdesc->natts != 1)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("provided \"categories\" SQL must " \
							"return 1 column of at least one row")));

		Assert(spi_tuptable->numvals >= tuple_processed);
		for (i = 0; i < tuple_processed; i++)
		{
			bbf_pivot_cat_desc *catdesc;
			char	   *catname;
			char	   *catname_lower;
			HeapTuple	spi_tuple;

			/* get the next sql result tuple */
			spi_tuple = spi_tuptable->vals[i];

			/* get the category from the current sql result tuple */
			catname = SPI_getvalue(spi_tuple, spi_tupdesc, 1);
			catname_lower = downcase_identifier(catname, strlen(catname), false, false);
			if (catname_lower == NULL)
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("provided \"categories\" SQL must " \
								"not return NULL values")));

			oldcontext = MemoryContextSwitchTo(per_query_ctx);

			catdesc = (bbf_pivot_cat_desc *) palloc(sizeof(bbf_pivot_cat_desc));
			catdesc->catname = pstrdup(catname_lower);
			catdesc->attidx = i;
			/* Add the tuple description block to the hashtable */
			bbf_pivot_HashTableInsert(bbf_pivot_hash, catdesc);

			MemoryContextSwitchTo(oldcontext);
		}
	}

	if (SPI_finish() != SPI_OK_FINISH)
		/* internal error */
		elog(ERROR, "load_categories_hash: SPI_finish() failed");

	return bbf_pivot_hash;
}

/*
 * create and populate the bbf_pivot tuplestore
 */
static Tuplestorestate *
get_bbf_pivot_tuplestore(const char 	*sourcetext,
						 const char		*funcName,
						 HTAB 			*bbf_pivot_hash,
						 TupleDesc 		tupdesc,
						 bool 			randomAccess)
{
	Tuplestorestate *tupstore;
	int			num_categories = hash_get_num_entries(bbf_pivot_hash);
	AttInMetadata *attinmeta = TupleDescGetAttInMetadata(tupdesc);
	char	  **values;
	HeapTuple	tuple;
	int			ret;
	uint64		tuple_processed;

	/* initialize our tuplestore (while still in query context!) */
	tupstore = tuplestore_begin_heap(randomAccess, false, work_mem);

	/* Connect to SPI manager */
	if ((ret = SPI_connect()) < 0)
		/* internal error */
		elog(ERROR, "get_bbf_pivot_tuplestore: SPI_connect returned %d", ret);

	/* Now retrieve the bbf_pivot source rows */
	ret = SPI_execute(sourcetext, true, 0);
	tuple_processed = SPI_processed;

	/* Check for qualifying tuples */
	if ((ret == SPI_OK_SELECT) && (tuple_processed > 0))
	{
		SPITupleTable *spi_tuptable = SPI_tuptable;
		TupleDesc	spi_tupdesc = spi_tuptable->tupdesc;
		int			ncols = spi_tupdesc->natts;
		char	   **columngroup;
		char	   **lastcolumngroup = NULL;
		bool		firstpass = true;
		uint64		i;
		int			j;
		int			non_pivot_columns;
		int			result_ncols;
		/* 
		 * only COUNT will output 0 when no row is selected
		 * https://www.postgresql.org/docs/12/functions-aggregate.html 
		 */
		bool		output_zero = !strcasecmp(funcName, "count");

		if (num_categories == 0)
		{
			/* no qualifying category tuples */
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("provided \"categories\" SQL must " \
							"return 1 column of at least one row")));
		}

		if (ncols < 2)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("invalid source data SQL statement"),
					 errdetail("The provided SQL must return 2 " \
							   " columns; category, and values.")));

		Assert(spi_tuptable->numvals >= tuple_processed);
		/* 
		* The last 2 columns of the results are category column and value column
		* that will be used for later pivot operation. The remaining columns are 
		* non_pivot columns;
		*/
		non_pivot_columns = ncols - 2;
		result_ncols = non_pivot_columns + num_categories;

		/* Recheck to make sure we tuple descriptor still looks reasonable */
		if (tupdesc->natts != result_ncols)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("invalid return type"),
					 errdetail("Query-specified return " \
							   "tuple has %d columns but bbf_pivot " \
							   "returns %d.", tupdesc->natts, result_ncols)));

		/* allocate space and make sure it's clear */
		values = (char **) palloc0(result_ncols * sizeof(char *));
		columngroup = (char **) palloc0(non_pivot_columns * sizeof(char *));
		lastcolumngroup = (char **) palloc0(non_pivot_columns * sizeof(char *));

		for (i = 0; i < tuple_processed; i++)
		{
			HeapTuple	spi_tuple;
			bbf_pivot_cat_desc *catdesc;
			char	   *catname;
			char	   *catname_lower;
			bool 	   	is_new_row = false;

			/* get the next sql result tuple */
			spi_tuple = spi_tuptable->vals[i];

			if (ncols > 2)
			{
				/* get the non-pivot column group from the current sql result tuple */
				for (j = 0; j < non_pivot_columns; j++)
				{	
					columngroup[j] = SPI_getvalue(spi_tuple, spi_tupdesc, j+1);
				}

				/*
				* if we're on a new output row, grab the column values up to
				* column N-2 now
				*/

				if (!firstpass)
				{
					for (j = 0; j < non_pivot_columns; j++)
					{	
						if (!xstreq(columngroup[j], lastcolumngroup[j]))
						{
							is_new_row = true;
							break;
						}
					}
				}

				if (firstpass || is_new_row)
				{
					/*
					* a new row means we need to flush the old one first, unless
					* we're on the very first row
					*/
					if (!firstpass)
					{
						/* only COUNT will output 0 when no row is selected */
						if (output_zero)
						{
							for (j = 0; j < result_ncols; j++)
							{
								if (values[j] == NULL)
									values[j] = pstrdup("0");
							}
						}

						/* rowid changed, flush the previous output row */
						tuple = BuildTupleFromCStrings(attinmeta, values);

						tuplestore_puttuple(tupstore, tuple);

						for (j = 0; j < result_ncols; j++)
							xpfree(values[j]);
					}

					for (j = 0; j < non_pivot_columns; j++)
						values[j] = SPI_getvalue(spi_tuple, spi_tupdesc, j + 1);

					/* we're no longer on the first pass */
					firstpass = false;
				}
			}

			/*
			 * look up the category and fill in the appropriate column
			 * Column names get from SPI result can be in mixed case but we only use
			 * lowered cases column names for new pivot table, and so we need to lower 
			 * the column names obtained from SPI results to get the tuple index from 
			 * the hash table
			 */
			catname = SPI_getvalue(spi_tuple, spi_tupdesc, ncols - 1);
			catname_lower = downcase_identifier(catname, strlen(catname), false, false);
			if (catname_lower != NULL)
			{
				bbf_pivot_HashTableLookup(bbf_pivot_hash, catname_lower, catdesc);

				if (catdesc)
					values[catdesc->attidx + non_pivot_columns] =
						SPI_getvalue(spi_tuple, spi_tupdesc, ncols);
			}

			if (ncols > 2)
			{
				for (j = 0; j < non_pivot_columns; j++)
				{	
					xpfree(lastcolumngroup[j]);
					xpstrdup(lastcolumngroup[j], columngroup[j]);
				}
			}
		}

		/* flush the last output row */
		if (output_zero)
		{
			for (i = 0; i < result_ncols; i++)
			{
				if (values[i] == NULL)
					values[i] = pstrdup("0");
			}
		}
		tuple = BuildTupleFromCStrings(attinmeta, values);
		tuplestore_puttuple(tupstore, tuple);
	}

	if (SPI_finish() != SPI_OK_FINISH)
		/* internal error */
		elog(ERROR, "get_bbf_pivot_tuplestore: SPI_finish() failed");

	return tupstore;
}
