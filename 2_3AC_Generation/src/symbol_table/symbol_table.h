#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H
#include <bits/stdc++.h>

struct temp_type_info
{
    string type;
    string type_min;
    vector<string> args;
    vector<string> args_min;
    vector<SymbolTableEntry*> candidates;
    int trailer_type;
    bool is_lvalue;
};

enum types
{
    OBJ,
    CLASS_DEF,
    FUNC_DEF
};

class SymbolTable;

class SymbolTableEntry
{
public:
    enum types entry_type;
    std::vector<std::string> type;
    std::string return_type;
    std::string lexval;
    int width;
    int line_no;
    int offset; // size of parameters for function, size of members for class
    SymbolTable *container_st;
    SymbolTable *local_st;
    SymbolTable *obj_st;

    SymbolTableEntry(enum types entry_type, std::vector<std::string> type, std::string lexval, int width, int line_no, int offset, SymbolTable *container_st, SymbolTable *local_st);
};

enum st_types
{
    CLASS_ST,
    FUNCTION_ST,
    GLOBAL_ST
};

class SymbolTable
{
public:
    std::map<std::string, std::vector<SymbolTableEntry *>> entries;
    int offset;
    enum st_types type;
    SymbolTableEntry *my_st_entry;
    SymbolTable *parent_class_st;
    SymbolTableEntry *is_present(std::string, std::vector<std::string>, std::vector<std::string>);
    SymbolTableEntry *is_present(std::string);
    int insert(SymbolTableEntry *);
    SymbolTableEntry *inherit_tree_lookup(std::string);
    SymbolTable();

    std::vector<std::string> global_vars;
};

class SymbolTableStack
{
public:
    std::vector<SymbolTable *> tables;
    SymbolTableEntry *lookup(std::string);
    SymbolTable *add_table(enum st_types);
    SymbolTable *pop_table();
};
#endif