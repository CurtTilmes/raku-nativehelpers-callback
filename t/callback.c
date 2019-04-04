#include <stdlib.h>
#include <stdio.h>

typedef struct {
    int a;
} *thing;

typedef int (*callback)(void *);

callback the_callback;
void *the_userdata;

thing make_a_thing()
{
    return (thing) malloc(sizeof(int));
}

void setcallback(callback cb, void *user_data)
{
    the_callback = cb;
    the_userdata = user_data;
}

int callit()
{
    return the_callback(the_userdata);
}
