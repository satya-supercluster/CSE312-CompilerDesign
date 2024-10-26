#include <bits/stdc++.h>
using namespace std;
#include "symbol_table.h"
#include "../3ac/3ac.h"
#include "../type_utils/type_utils.h"
extern SymbolTableStack *st_stack;
extern SymbolTable *curr_st;
extern void yyerror(string s);
extern map<string, int> type_priority;
extern void error(string, int);

SymbolTableEntry::SymbolTableEntry(enum types entry_type, vector<string> type, string lexval, int width, int line_no, int offset, SymbolTable *container_st, SymbolTable *local_st)
{
    this->entry_type = entry_type;
    this->type = type;
    this->lexval = lexval;
    this->width = width;
    this->line_no = line_no;
    this->offset = offset;
    this->container_st = container_st;
    this->local_st = local_st;
    this->obj_st = NULL;
}

SymbolTableEntry *SymbolTable::is_present(string s, vector<string> v, vector<string> v_min)
{
    if (entries.count(s))
    {
        vector<SymbolTableEntry *> v_of_sts = this->entries[s];
        for (int i = 0; i < v_of_sts.size(); i++)
        {
            if (compare_args(v_of_sts[i]->type, v, v_min))
            {
                return v_of_sts[i];
            }
        }
    }
    return NULL;
}

SymbolTableEntry *SymbolTable::is_present(string s)
{
    if (entries.count(s))
        return this->entries[s][0];
    if (count(global_vars.begin(), global_vars.end(), s) && this->type != GLOBAL_ST)
    {
        SymbolTableEntry *ret = st_stack->tables[0]->is_present(s);
        return ret;
    }
    return NULL;
}

SymbolTableEntry *SymbolTable::inherit_tree_lookup(string s)
{
    SymbolTable *st_ptr = this;
    while (st_ptr)
    {
        SymbolTableEntry *temp = st_ptr->is_present(s);
        if (temp)
            return temp;
        st_ptr = st_ptr->parent_class_st;
    }
    return NULL;
}

int SymbolTable::insert(SymbolTableEntry *ste)
{
    this->entries[ste->lexval].push_back(ste);
    return 0;
}
SymbolTable::SymbolTable()
{
    offset = 0;
    parent_class_st = NULL;
    type = GLOBAL_ST;
    my_st_entry = NULL;
}

SymbolTableEntry *SymbolTableStack::lookup(string s)
{
    for (int i = tables.size() - 1; i >= 0; i--)
    {
        SymbolTableEntry *temp = tables[i]->is_present(s);
        if (tables[i]->type == CLASS_ST)
            continue;
        if (temp)
            return temp;
    }
    return NULL;
}

SymbolTable *SymbolTableStack::add_table(enum st_types type)
{
    SymbolTable *new_table = new SymbolTable();
    this->tables.push_back(new_table);
    new_table->type = type;
    return new_table;
}

SymbolTable *SymbolTableStack::pop_table()
{

    if (this->tables.size() > 0)
    {
        this->tables.pop_back();
    }
    if (this->tables.size() > 0)
    {
        return this->tables.back();
    }

    return NULL;
}