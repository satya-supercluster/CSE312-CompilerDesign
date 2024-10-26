using namespace std;
#include "type_utils.h"
#include "../3ac/3ac.h"
extern SymbolTableStack *st_stack;
extern SymbolTable *curr_st;
extern void yyerror(string s);
extern map<string, int> type_priority;
extern void error(string, int);


string resolve_type(Node *node)
{
    if (node->lexval != "")
    {
        return node->lexval;
    }
    string str;
    for (auto child : node->child)
    {
        str += resolve_type(child);
    }
    return str;
}

int resolve_width(string type)
{
    if (type == "int")
    {
        return 8;
    }
    else if (type == "float")
    {
        return 8;
    }
    else if (type == "bool")
    {
        return 8;
    }
    else if (type == "str")
    {
        return 8;
    }
    else
    {
        return 8;
    }
}

void print_st(vector<SymbolTable *> v)
{

    for (auto table : v)
    {
        string table_name;
        if (table->type == GLOBAL_ST)
        {
            table_name = "global_symtab";
        }
        else
        {
            if (table->my_st_entry->container_st->type != GLOBAL_ST)
            {
                table_name = table->my_st_entry->container_st->my_st_entry->lexval + ".";
            }
            else
            {
                table_name = "";
            }
            table_name += table->my_st_entry->lexval;
        }
        string output_filename = table_name + ".csv";
        ofstream fout;
        fout.open(output_filename);
        fout << "Symbol Name" << "," << "Token,Category" << "," << "Type" << "," << "Line Number" << "," << "Return Type (for function)" << endl;
        for (auto p : table->entries)
        {
            for (int k = 0; k < p.second.size(); k++)
            {
                if (p.second[k]->entry_type == FUNC_DEF)
                {
                    fout << p.first << "," << "NAME,Function" << ",(";
                    for (int i = 0; i < p.second[k]->type.size(); i++)
                    {
                        fout << p.second[k]->type[i];
                        if (i < p.second[k]->type.size() - 1)
                            fout << ":";
                    }
                    fout << ")," << p.second[k]->line_no << "," << p.second[k]->return_type << endl;
                }
                else if (p.second[k]->entry_type == CLASS_DEF)
                {
                    fout << p.first << "," << "NAME,Class" << "," << "" << "," << p.second[k]->line_no << endl;
                }
                else
                    fout << p.first << "," << "NAME,Variable" << "," << p.second[k]->type[0] << "," << p.second[k]->line_no << endl;
            }
        }
        fout.close();
    }
}

bool is_valid_type(string s)
{
    if (s == "int" || s == "float" || s == "bool" || s == "str" || s == "None")
    {
        return true;
    }
    SymbolTableEntry *class_entry = st_stack->lookup(s);
    if (class_entry != NULL && class_entry->entry_type == CLASS_DEF)
    {
        return true;
    }
    if (s.size() >= 6 && s.substr(0, 5) == "list[" && s.back() == ']' && is_valid_type(s.substr(5, s.size() - 6)))
        return true;
    return false;
}

string type_check_arith(string t1, string t2, string error_str, int error_lineno)
{

    if (t1 == "int" && t2 == "bool")
    {
        return "int";
    }
    if (t1 == "bool" && t2 == "int")
    {
        return "int";
    }
    if (t1 == "bool" && t2 == "bool")
    {
        return "int";
    }
    if (t1 == "int" && t2 == "float")
    {
        return "float";
    }
    if (t1 == "float" && t2 == "int")
    {
        return "float";
    }
    if (t1 == "float" && t2 == "float")
    {
        return "float";
    }
    if (t1 == "int" && t2 == "int")
    {
        return "int";
    }
    error(error_str, error_lineno);
    return "";
}

string type_check_shift(string str1, string str2, string error_str, int error_lineno)
{
    if ((str1 == "int" || str1 == "bool") && (str2 == "int" || str2 == "bool"))
        return "int";
    error(error_str, error_lineno);
    return "";
}

bool same_type_kind(string t1, string t2)
{
    if (t1 != t2)
    {
        if ((t1 == "int" || t1 == "float" || t1 == "bool") && (t2 == "int" || t2 == "float" || t2 == "bool"))
        {
            return true;
        }
        return false;
    }
    else
        return true;
}

bool can_be_converted(string t1, string t2)
{
    // cout<<t1<<"-"<<t2<<endl;
    if (is_list(t1) || is_list(t2))
    {
        if (!(is_list(t1) && is_list(t2)))
            return false;
        return can_be_converted(strip(t1), strip(t2));
    }
    // cout<<t1<<"+"<<t2<<endl;
    if (is_obj(t1) || is_obj(t2))
    {
        if (!(is_obj(t2) && is_obj(t1)))
            return false;
        if (t1 == t2)
            return true;
        else
            return false;
    }
    // cout<<t1<<"=="<<t2<<endl;
    if (t1 == t2)
    {
        // cout<<"inside is list "<<t1<<" "<<t2 <<endl;
        return true;
    }
    // cout<<t1<<"==="<<t2<<endl;

    if (type_priority.count(t1) && type_priority.count(t2) && abs(type_priority[t1] - type_priority[t2]) <= 1)
    {
        // cout<<"inside if"<<endl;
        return true;
    }
    // cout<<t1<<"===="<<t2<<endl;
    return false;
}

bool compare_args(vector<string> formal_param, vector<string> actual_min, vector<string> actual_max)
{
    if (formal_param.size() != actual_min.size())
        return false;
    if (formal_param.size() != actual_max.size())
        return false;
    for (int i = 0; i < formal_param.size(); i++)
    {
        // cout<<"inside compare args "<<i<<" "<<formal_param[i]<<" "<<actual_min[i]<<endl;
        if (!can_be_converted(formal_param[i], actual_min[i]) || !can_be_converted(formal_param[i], actual_max[i]))
            return false;
    }
    return true;
}

string strip(string s)
{
    return s.substr(5, s.size() - 6);
}

bool is_list(string s)
{
    if (s.size() >= 6 && s.substr(0, 5) == "list[" && s.back() == ']')
        return true;
    return false;
}

bool is_obj(string s)
{
    if (s == "int" || s == "str" || s == "bool" || s == "float")
    {
        return false;
    }
    return true;
}

string max_type(string t1, string t2)
{
    if (is_list(t1) || is_list(t2))
    {
        if (!(is_list(t1) && is_list(t2)))
            yyerror("Type mismatch in list.");
        return "list[" + max_type(strip(t1), strip(t2)) + "]";
    }
    if (is_obj(t1) || is_obj(t2))
    {
        if (!(is_obj(t2) && is_obj(t1)))
            yyerror("Type mismatch in list.");
        if (t1 == t2)
            return t1;
        else
            yyerror("Type mismatch in list.");
    }
    if (t1 == "str" || t2 == "str")
    {
        if (!(t1 == "str" && t2 == "str"))
            yyerror("Type mismatch in list.");
        if (t1 == t2)
            return t1;
        else
            yyerror("Type mismatch in list.");
    }
    if (t1 == t2)
    {
        return t1;
    }
    if (type_priority[t1] < type_priority[t2])
    {
        return t2;
    }
    return t1;
}

string min_type(string t1, string t2)
{
    if (is_list(t1) || is_list(t2))
    {
        if (!(is_list(t1) && is_list(t2)))
        {
            yyerror("Type mismatch in list");
        }
        return "list[" + min_type(strip(t1), strip(t2)) + "]";
    }
    if (is_obj(t1) || is_obj(t2))
    {
        if (!(is_obj(t2) && is_obj(t1)))
        {
            yyerror("Type mismatch in list");
        }
        if (t1 == t2)
        {
            return t1;
        }
        else
            yyerror("Type mismatch in list");
    }
    if (t1 == "str" || t2 == "str")
    {
        if (!(t1 == "str" && t2 == "str"))
            yyerror("Type mismatch in list.");
        if (t1 == t2)
            return t1;
        else
            yyerror("Type mismatch in list.");
    }
    if (t1 == t2)
    {
        return t1;
    }
    if (type_priority[t1] < type_priority[t2])
    {
        return t1;
    }
    return t2;
}