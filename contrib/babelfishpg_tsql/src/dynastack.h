#ifndef DYNASTACK_H
#define DYNASTACK_H

/*
 *  Vector base dynamically expandable stack
 */

typedef DynaVec DynaStack;

/******************************************************************
 *                           STACK APIS
 ******************************************************************/

DynaStack  *create_stack(size_t elem_size);
DynaStack  *create_stack2(size_t elem_size, size_t init_num_elems);
void		destroy_stack(DynaStack *stack);

void	   *stack_top(DynaStack *stack);
void		stack_pop(DynaStack *stack);
void		stack_push(DynaStack *stack, const void *elem_ptr);
bool		stack_is_empty(DynaStack *stack);
size_t		stack_size(const DynaStack *stack);


#endif							/* DYNASTACK_H */
