#ifndef EXTENDEDPROPERTY_H
#define EXTENDEDPROPERTY_H

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