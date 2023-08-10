#ifndef EXTENDEDPROPERTY_H
#define EXTENDEDPROPERTY_H

typedef enum ExtendedPropertyType
{
    EXTENDED_PROPERTY_DATABASE = 0,
    EXTENDED_PROPERTY_SCHEMA,
    EXTENDED_PROPERTY_TABLE,
    EXTENDED_PROPERTY_VIEW,
    EXTENDED_PROPERTY_SEQUENCE,
    EXTENDED_PROPERTY_PROCEDURE,
    EXTENDED_PROPERTY_FUNCTION,
    EXTENDED_PROPERTY_TYPE,
    EXTENDED_PROPERTY_TABLE_COLUMN,
    EXTENDED_PROPERTY_MAX /* should be last */
} ExtendedPropertyType;

extern const char *const ExtendedPropertyTypeNames[];

extern void delete_extended_property(int16 db_id,
                                     const char *type,
                                     const char *schema_name,
                                     const char *major_name,
                                     const char *minor_name);
extern void update_extended_property(int16 db_id,
                                     const char *type,
                                     const char *schema_name,
                                     const char *major_name,
                                     const char *minor_name,
                                     int attnum,
                                     const char *new_value);

#endif