#include "postgres.h"
#include "dynavec.h"

#define DEFAULT_INIT_NUM_ELEMS 16

static void vec_expand(DynaVec *);

/***********************************************************************************
 *                          EXTERNAL APIS
 **********************************************************************************/

DynaVec *
create_vector(size_t elem_size)
{
	return create_vector2(elem_size, DEFAULT_INIT_NUM_ELEMS);
}

DynaVec *
create_vector2(size_t elem_size, size_t init_num_elems)
{
	DynaVec    *new_vec = palloc(sizeof(DynaVec));
	size_t		total_bytes = elem_size * init_num_elems;

	new_vec->data = palloc0(total_bytes);
	new_vec->capacity = total_bytes;
	new_vec->size = 0;
	new_vec->elem_size = elem_size;
	return new_vec;
}

DynaVec *
create_vector3(size_t elem_size, size_t init_num_elems, void *init_val)
{
	void	   *value;
	int			i;
	DynaVec    *vec = create_vector2(elem_size, init_num_elems);

	/* Initialization */
	for (i = 0; i < init_num_elems; i++)
	{
		value = vec_at(vec, i);
		memcpy(value, init_val, elem_size);
	}
	return vec;
}

DynaVec *
create_vector_copy(DynaVec *src)
{
	DynaVec    *vec = create_vector2(src->elem_size, vec_size(src));

	/* simply copy data from src vector */
	memcpy(vec->data, src->data, src->size);
	vec->size = src->size;
	return vec;
}

void
destroy_vector(DynaVec *vec)
{
	pfree(vec->data);
	vec->data = NULL;
	vec->capacity = 0;
	vec->size = 0;
	pfree(vec);
}

void
vec_push_back(DynaVec *vec, const void *elem_ptr)
{
	if ((vec->capacity - vec->size) < vec->elem_size)
		vec_expand(vec);
	memcpy(vec->data + vec->size, elem_ptr, vec->elem_size);
	vec->size += vec->elem_size;
}

void
vec_pop_back(DynaVec *vec)
{
	if (vec->size > 0)
		vec->size -= vec->elem_size;
}

void *
vec_at(const DynaVec *vec, size_t index)
{
	return (vec->data + (index * vec->elem_size));
}

void *
vec_back(const DynaVec *vec)
{
	if (vec->size < vec->elem_size)
		return NULL;
	return vec_at(vec, (vec->size / vec->elem_size - 1));
}

size_t
vec_size(const DynaVec *vec)
{
	return (vec->size / vec->elem_size);
}

/***********************************************************************************
 *                          INTERNAL FUNCTIONS
 **********************************************************************************/

static void
vec_expand(DynaVec *vec)
{
	size_t		cur_cap = vec->capacity;
	size_t		new_cap = cur_cap * 2;

	vec->data = repalloc(vec->data, new_cap);
	vec->capacity = new_cap;
}
