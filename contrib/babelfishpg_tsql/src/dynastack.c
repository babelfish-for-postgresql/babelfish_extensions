#include "dynavec.h"
#include "dynastack.h"

DynaStack *
create_stack(size_t elem_size)
{
	return (DynaStack *) create_vector(elem_size);
}

DynaStack *
create_stack2(size_t elem_size, size_t init_num_elems)
{
	return (DynaStack *) create_vector2(elem_size, init_num_elems);
}

void
destroy_stack(DynaStack *stack)
{
	destroy_vector((DynaVec *) stack);
}

void *
stack_top(DynaStack *stack)
{
	DynaVec    *vec = (DynaVec *) stack;

	return vec_back(vec);
}

void
stack_pop(DynaStack *stack)
{
	vec_pop_back((DynaVec *) stack);
}

void
stack_push(DynaStack *stack, const void *elem_ptr)
{
	vec_push_back((DynaVec *) stack, elem_ptr);
}

bool
stack_is_empty(DynaStack *stack)
{
	return stack->size == 0;
}

size_t
stack_size(const DynaStack *stack)
{
	return vec_size((const DynaVec *) stack);
}
