#ifndef _3AC_H
#define _3AC_H
#include "../symbol_table/symbol_table.h"
#include "../type_utils/type_utils.h"
using namespace std;

enum tac_types
{
    LABEL,
    BEGINFUNC,
    ENDFUNC,
    NAME_ASSIGNMENT,
    LOAD,
    STORE,
    ARITH,
    BITWISE,
    LOGIC,
    PUSHPARAM,
    POPPARAM,
    STACK_MANIPULATION,
    FUNCCALL,
    CONDITIONAL_JUMP,
    JUMP,
    RETURN_STMT,
    CVT
};

struct quad
{
    string opcode;
    string op1;
    string op2;
    string target;
    bool is_label;
    enum tac_types tac_type;

    string label;

    quad(string, string, string, string, enum tac_types); // quad
    quad(string);                                         // label
};

extern vector<quad> tac;
extern int temporary_counter;
extern int label_counter;

void print_tac(string);
string new_temporary();
string new_label();
void gen_augassign_tac(Node *, Node *, Node *);
void convert(string, string, string);
#endif
