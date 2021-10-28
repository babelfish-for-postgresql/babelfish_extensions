#ifndef DYNAVEC_H
#define DYNAVEC_H
#include <c.h>

/***********************************************************************************
 *              IMPLEMENTATION OF DYNAMICALLY EXPANDABLE VECTOR
 **********************************************************************************/

typedef struct
{
    char   *data;
    size_t capacity;    /* capacity in bytes */
    size_t size;        /* size in bytes */
    size_t elem_size;   /* size of element in bytes */
} DynaVec;

/***********************************************************************************
 *                          VECTOR APIS 
 **********************************************************************************/
/* create vector with default init size */
DynaVec *create_vector(size_t elem_size);
/* with configurable init size */
DynaVec *create_vector2(size_t elem_size, size_t init_num_elems);
/* with configurable init size and elements are initialized with init_val */
DynaVec *create_vector3(size_t elem_size, size_t init_num_elems, void *init_val);
/* copy content from existing vector */
DynaVec *create_vector_copy(DynaVec *src);

void       destroy_vector(DynaVec *);

/*
 * Please feel free to extended APIs.
 * Refer to std::vector semantic
 */
void   vec_push_back(DynaVec *vec, const void *elem_ptr);
void   vec_pop_back(DynaVec *vec);
void  *vec_at(const DynaVec *vec, size_t index);  /* NOTICE: No Boundary Check */
void  *vec_back(const DynaVec *vec);
size_t vec_size(const DynaVec *vec);  /* Number of elements in vector */

#endif  /* DYNAVEC_H */
