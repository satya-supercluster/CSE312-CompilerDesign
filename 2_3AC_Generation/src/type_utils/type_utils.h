#ifndef TYPE_UTILS_H
#define TYPE_UTILS_H
#include "../node/node.h"
#include "../symbol_table/symbol_table.h"
using namespace std;
string resolve_type(Node *);
int resolve_width(string);
void print_st(vector<SymbolTable *>);
string type_check_arith(string, string, string, int);
string type_check_shift(string, string, string, int);
bool is_valid_type(string);
bool compare_args(vector<string>, vector<string>, vector<string>);
bool same_type_kind(string, string);
string min_type(string, string);
string max_type(string, string);
bool is_obj(string);
bool is_list(string);
string strip(string);
bool can_be_converted(string, string);
#endif