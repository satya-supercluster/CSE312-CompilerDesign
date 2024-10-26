#include "../symbol_table/symbol_table.h"
#include "3ac.h"
#include<bits/stdc++.h>
using namespace std;
extern vector<quad> tac;
extern int temporary_counter;
extern int label_counter;
extern void yyerror(string);

quad::quad(string opcode, string op1, string op2, string target, enum tac_types type)
{
    this->opcode = opcode;
    this->op1 = op1;
    this->op2 = op2;
    this->target = target;
    this->is_label = false;
    this->tac_type = type;
}

quad::quad(string label)
{
    this->is_label = true;
    this->label = label;
    this->tac_type = LABEL;
}

void print_tac(string filename)
{
    ofstream fout(filename);
    if (!fout.is_open())
    {
        cerr << "Error: unable to open output file\n";
        return;
    }
    for (auto q : tac)
    {
        if (q.is_label)
        {
            fout << endl;
            fout << q.label << ":" << endl;
        }
        else if (q.tac_type == BEGINFUNC || q.tac_type == ENDFUNC)
        {
            fout << "\t" << q.opcode << " " << q.op1 << endl;
            if (q.tac_type == ENDFUNC)
            {
                fout << endl;
            }
        }
        else if (q.tac_type == NAME_ASSIGNMENT)
        {
            fout << "\t" << q.target << " = " << q.op1 << endl;
        }
        else if (q.tac_type == LOAD)
        {
            fout << "\t" << q.target << " = *(" << q.op1 << ")" << endl;
        }
        else if (q.tac_type == STORE)
        {
            fout << "\t" << "*(" << q.target << ") = " << q.op1 << endl;
        }
        else if (q.tac_type == ARITH || q.tac_type == BITWISE || q.tac_type == LOGIC)
        {
            fout << "\t" << q.target << " = " << q.op1 << " " << q.opcode << " " << q.op2 << endl;
        }
        else if (q.tac_type == PUSHPARAM || q.tac_type == FUNCCALL || q.tac_type == STACK_MANIPULATION || q.tac_type == RETURN_STMT)
        {
            fout << "\t" << q.opcode << " " << q.op1 << " " << q.op2 << endl;
        }
        else if (q.tac_type == CONDITIONAL_JUMP)
        {
            fout << "\t" << q.opcode << " " << q.op1 << " jump " << q.target << endl;
        }
        else if (q.tac_type == JUMP)
        {
            fout << "\t" << q.opcode << " " << q.target << endl;
        }
        else if (q.tac_type == CVT)
        {
            fout << "\t" << q.opcode << " " << q.op1 << endl;
        }
        else
        {
            fout << q.target << " EQUALS " << "\t" << q.op1 << "\t" << q.opcode << "\t" << q.op2 << "\t" << endl;
        }
    }
    fout.close();
}

string new_temporary()
{
    string temp = "t" + to_string(temporary_counter);
    temporary_counter++;
    return temp;
}

string new_label()
{
    string temp = "L" + to_string(label_counter);
    label_counter++;
    return temp;
}

void gen_augassign_tac(Node *lvalue, Node *operatorr, Node *operand)
{
    if (!lvalue)
    {
        yyerror("Unknown error.");
    }
    string new_temp = new_temporary();
    if (operatorr->lexval == "+=")
    {
        tac.push_back(quad("+", lvalue->rvalue, operand->rvalue, new_temp, ARITH));
    }
    else if (operatorr->lexval == "-=")
    {
        tac.push_back(quad("-", lvalue->rvalue, operand->rvalue, new_temp, ARITH));
    }
    else if (operatorr->lexval == "*=")
    {
        tac.push_back(quad("*", lvalue->rvalue, operand->rvalue, new_temp, ARITH));
    }
    else if (operatorr->lexval == "/=")
    {
        tac.push_back(quad("/", lvalue->rvalue, operand->rvalue, new_temp, ARITH));
    }
    else if (operatorr->lexval == "%=")
    {
        tac.push_back(quad("%", lvalue->rvalue, operand->rvalue, new_temp, ARITH));
    }
    else if (operatorr->lexval == "**=")
    {
        tac.push_back(quad("**", lvalue->rvalue, operand->rvalue, new_temp, ARITH));
    }
    else if (operatorr->lexval == "//=")
    {
        tac.push_back(quad("//", lvalue->rvalue, operand->rvalue, new_temp, ARITH));
    }
    else if (operatorr->lexval == "&=")
    {
        tac.push_back(quad("&", lvalue->rvalue, operand->rvalue, new_temp, BITWISE));
    }
    else if (operatorr->lexval == "|=")
    {
        tac.push_back(quad("|", lvalue->rvalue, operand->rvalue, new_temp, BITWISE));
    }
    else if (operatorr->lexval == "^=")
    {
        tac.push_back(quad("^", lvalue->rvalue, operand->rvalue, new_temp, BITWISE));
    }
    else if (operatorr->lexval == "<<=")
    {
        tac.push_back(quad("<<", lvalue->rvalue, operand->rvalue, new_temp, BITWISE));
    }
    else if (operatorr->lexval == ">>=")
    {
        tac.push_back(quad(">>", lvalue->rvalue, operand->rvalue, new_temp, BITWISE));
    }

    if (lvalue->title == "NAME")
    {
        tac.push_back(quad("=", new_temp, "", lvalue->lexval, NAME_ASSIGNMENT));
    }
    else
    {
        tac.push_back(quad("=", new_temp, "", lvalue->lvalue, STORE));
    }
}

void convert(string from, string to, string temp)
{
    vector<string> basic = {"int", "bool", "float"};
    if (!count(basic.begin(), basic.end(), from))
        return;
    if (!count(basic.begin(), basic.end(), to))
        return;
    if (from != to)
    {
        tac.push_back(quad("cvt_" + from + "_to_" + to, temp, "", "", CVT));
    }
}