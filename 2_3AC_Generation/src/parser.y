%{
    #include "node/node.h"
    #include "symbol_table/symbol_table.h"
    #include "type_utils/type_utils.h"
    #include "3ac/3ac.h"
    using namespace std;
    extern FILE* yyin;
    extern int yydebug;
    extern int yylex();
    extern void yyerror(string s);
    extern int yylineno;
    int nodeID{1};
    Node* root_node;
    map<string, string> color = {{"OPERATOR", "purple"}, {"KEYWORD", "green"}, {"DELIMITER", "blue"}, {"IDENTIFIER", "red"} , {"NUMBER", "pink"}, {"STRING_LITERAL", "orange"}, {"DATA TYPE", "cyan"}};

    // 3ac code generation
    vector<quad> tac;
    int temporary_counter = 0;
    int label_counter = 0;
    
    SymbolTable * curr_st;
    SymbolTableStack * st_stack;
    bool inside_type_hint=false;
    bool inside_declaration=false;
    bool inside_loop = false;
    bool is_return_type_present=false;
    map<string, int> type_priority={{"bool",0},{"int",1},{"float",2}};

    int curr_nesting_depth=0;
    stack<vector<int>> break_jumps;
    stack<string> continue_jump_labels;

    void error(string s, int line_no=yylineno)
    {
        yylineno=line_no;
        yyerror(s);
    }

    vector<SymbolTable*> print_st_vec;
    string curr_list_core_type;

%}

%define parse.trace
%define parse.error verbose

%union {
    Node *node;
}

%token NAME__

%token<node> EQUAL PLUS_EQUAL MINUS_EQUAL MULTIPLY_EQUAL RATE_EQUAL DIVIDE_EQUAL REMAINDER_EQUAL BITWISE_AND_EQUAL BITWISE_OR_EQUAL BITWISE_XOR_EQUAL LEFT_SHIFT_EQUAL RIGHT_SHIFT_EQUAL POWER_EQUAL INTEGER_DIVIDE INTEGER_DIVIDE_EQUAL COMMA PERIOD  MULTIPLY RATE DIVIDE POWER BITWISE_OR PLUS MINUS EQUAL_EQUAL NOT_EQUAL LESS_THAN_EQUAL LESS_THAN GREATER_THAN_EQUAL GREATER_THAN BITWISE_AND BITWISE_XOR REMAINDER BITWISE_NOT NUMBER NEWLINE NAME STRING_LITERAL LEFT_SHIFT RIGHT_SIHFT BREAK CONTINUE RETURN GLOBAL NONLOCAL ASSERT CLASS DEF IF ELIF ELSE WHILE FOR IN NONE TRUE FALSE OR AND NOT IS ASYNC INDENT DEDENT LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET ARROW SEMICOLON COLON


%type<node> THE_BEGIN file_input NEWLINE_or_stmt funcdef ARROW_test_or_not parameters typedargslist_or_not typedargslist tfpdef COMMA_tfpdef_EQUAL_test_or_not_kleene COLON_test_or_not COMMA_or_not EQUAL_test_or_not stmt simple_stmt SEMICOLON_small_stmt_kleene small_stmt expr_stmt EQUAL_testlist_star_expr_kleene annassign SEMICOLON_or_not testlist_star_expr test_or_star_expr augassign flow_stmt break_stmt continue_stmt return_stmt testlist_or_not global_stmt nonlocal_stmt assert_stmt COMMA_test_or_not compound_stmt if_stmt ELIF_test_COLON_suite_kleene while_stmt for_stmt ELSE_COLON_suite_or_not suite stmt_plus test IF_or_test_ELSE_test_or_not test_nocond or_test and_test not_test comparison comp_op star_expr expr xor_expr and_expr shift_expr LEFT_SHIFT_or_RIGHT_SIHFT arith_expr PLUS_or_MINUS term MULTIPLY_or_RATE_or_DIVIDE_or_REMAINDER_or_INTEGER_DIVIDE factor PLUS_or_MINUS_or_BITWISE_NOT power POWER_factor_or_not atom_expr atom STRING_plus testlist_comp COMMA_test_or_star_expr_kleene testlist_comp_or_not trailer subscriptlist COMMA_subscript_kleene subscript exprlist COMMA_expr_or_star_expr_kleene expr_or_star_expr testlist COMMA_test_kleene classdef LEFT_PAREN_arglist_or_not_RIGHT_PAREN_or_not arglist_or_not arglist COMMA_argument_kleene argument comp_for_or_not comp_iter comp_for comp_if comp_iter_or_not ASYNC_or_not 

%%


THE_BEGIN    : file_input {

    root_node=$1;
}

file_input  : file_input NEWLINE_or_stmt   {

                $1->push_back($2);
                $$ = $1;
}
            |  %empty {

                $$ = new Node(nodeID++, "file_input", yylineno);

}

NEWLINE_or_stmt : NEWLINE { $$ = NULL; }
                | stmt {
                        $$ = $1;
}


funcdef : DEF NAME {

                    SymbolTable* new_st=st_stack->add_table(FUNCTION_ST);
                    SymbolTableEntry* new_st_entry=new SymbolTableEntry(FUNC_DEF, {}, $2->lexval, 0, $1->lineno, -1, curr_st, new_st);
                    new_st->my_st_entry=new_st_entry;

                    if(curr_st->type==CLASS_ST)
                        tac.push_back(quad(curr_st->my_st_entry->lexval+"."+$2->lexval));
                    else
                        tac.push_back(quad($2->lexval));
                    
                    curr_st=new_st;
                    tac.push_back(quad("beginfunc", "", "", "", BEGINFUNC));

                    $1->begin_func_idx=tac.size()-1;

}

parameters ARROW_test_or_not COLON {

                
                $1->size_of_params=curr_st->offset;
                SymbolTableEntry* fn_st_entry=curr_st->my_st_entry;
                if(st_stack->tables.size()<2)
                {
                    error("Unknown error...");
                }

                SymbolTableEntry* temp1=st_stack->tables[st_stack->tables.size()-2]->is_present(fn_st_entry->lexval);
                if(temp1!=NULL)
                {
                    error("Variable/function of same name already declared at line number "+to_string(temp1->line_no), $1->lineno);

                }
                SymbolTableEntry* temp2=st_stack->tables[st_stack->tables.size()-2]->is_present(fn_st_entry->lexval);
                if(temp2!=NULL)
                {
                    error("Function already declared at line number "+to_string(temp2->line_no), $1->lineno);
                }
                if(st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && $4->child.size()==2)
                {
                    error("Function inside class must have self as first parameter", $1->lineno);
                }
                if($2->lexval=="__init__" || $2->lexval=="main")
                {
                    if($5 != NULL && resolve_type($5).substr(2)!="None"){
                        error("Return type of __init__ and main must be None.", $1->lineno);
                    }
                    fn_st_entry->return_type="None";
                }
                else
                {
                    if($5==NULL)
                    {
                        error("Return type hint not given", $1->lineno);
                    }
                    fn_st_entry->return_type=resolve_type($5).substr(2);
                }

                st_stack->tables[st_stack->tables.size()-2]->insert(fn_st_entry);


                curr_nesting_depth=0;
} 

suite {

                tac[$1->begin_func_idx].op1=to_string(curr_st->offset-$1->size_of_params);
                
                $$ = new Node(nodeID++,"funcdef", yylineno);
                $$->push_back($1);
                $$->push_back($2);
                $$->push_back($4);
                $$->push_back($5);
                $$->push_back($6);
                $$->push_back($8);


                if(!is_return_type_present)
                {
                    if(curr_st->my_st_entry->return_type!="None")
                    {
                        error("Function returning non-None reached end without returning a value", $1->lineno);
                    }
                }
                if(!is_return_type_present)
                {
                    tac.push_back(quad("leave", "", "", "", RETURN_STMT));
                }
                is_return_type_present=false;
                curr_nesting_depth=0;
                print_st_vec.push_back(curr_st);
                curr_st=st_stack->pop_table();

                tac.push_back(quad("endfunc", "", "", "", ENDFUNC));

}

ARROW_test_or_not   : ARROW {inside_type_hint=1;} test {
                        inside_type_hint=0;
                        $$ = new Node(nodeID++, "return_type_hint", yylineno);
                        $$->push_back($1);
                        $$->push_back($3);

                        if(!is_valid_type(resolve_type($3)))
                        {
                            error("Invalid return type given for function", $1->lineno);
                        }

}
                    | %empty    {
                        
                        $$ = NULL;
}

parameters: LEFT_PAREN typedargslist_or_not RIGHT_PAREN    {

                $$ = new Node(nodeID++, "parameters", yylineno);
                $$->push_back($1);
                $$->push_back($2);
                $$->push_back($3);
}

typedargslist_or_not    : typedargslist         {
                            $$ = $1;
}
                        | %empty   {
                            $$ = NULL;
}

typedargslist   : tfpdef  COMMA_tfpdef_EQUAL_test_or_not_kleene COMMA  {

                    if($1==NULL && $2==NULL ) $$=$3;
                    else
                    {
                        $$ = new Node(nodeID++,"typedargslist", yylineno);
                        $$->push_back($1);
                        if($2)
                        {
                            for(auto child: $2->child)
                            {
                                $$->push_back(child);
                            }
                        }
                        $$->push_back($3);
                    }


                    if($1 && $1->child.size()==1 && $1->child[0]->lexval=="self" && st_stack->tables.size()>=2 && st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && st_stack->tables[st_stack->tables.size()-1]->type==FUNCTION_ST)
                    {
                    }
                    else if($1 && st_stack->tables.size()>=2 && st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && st_stack->tables[st_stack->tables.size()-1]->type==FUNCTION_ST)
                    {
                        error("First argument in class method must be \"self\" without type hint", $1->lineno);
                    }



}
                | tfpdef COMMA_tfpdef_EQUAL_test_or_not_kleene    {

                if($2==NULL) $$=$1;
                else if($1==NULL) $$=$2;
                else
                {
                    $$ = new Node(nodeID++, "typedargslist", yylineno);
                    $$->push_back($1);
                    if($2)
                    {
                        for(auto child: $2->child)
                        {
                            $$->push_back(child);
                        }
                    }
                }


                if($1 && $1->child.size()==1 && $1->child[0]->lexval=="self" && st_stack->tables.size()>=2 && st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && st_stack->tables[st_stack->tables.size()-1]->type==FUNCTION_ST)
                {
                    ;
                }
                else if($1 && st_stack->tables.size()>=2 && st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && st_stack->tables[st_stack->tables.size()-1]->type==FUNCTION_ST)
                {
                    error("First argument in class method must be \"self\" without type hint", $1->lineno);
                }

}

tfpdef  : NAME COLON_test_or_not {

                    $$ = new Node(nodeID++, "formal_param", yylineno);
                    $$->push_back($1);
                    $$->push_back($2);




                    if(curr_st->is_present($1->lexval))
                    {
                        error("Parameter redeclared in function "+curr_st->my_st_entry->lexval+" declared at line number "+to_string(curr_st->my_st_entry->line_no), $1->lineno);
                    }
                    string type;
                    if($1->lexval=="self" && st_stack->tables.size() > 1 && st_stack->tables[st_stack->tables.size()-2]->type == CLASS_ST)
                    {
                        type=st_stack->tables[st_stack->tables.size()-2]->my_st_entry->lexval;
                    }
                    else
                    {
                        if(!$2)
                        {
                            error("Type hint missing in function parameter", $1->lineno);
                        }
                        type=resolve_type($2).substr(1);
                    }
                    int width=resolve_width(type);
                    SymbolTableEntry* curr_param=new SymbolTableEntry(OBJ, {type}, $1->lexval, width, $1->lineno, curr_st->offset, curr_st, NULL);
                    curr_st->offset+=width;
                    curr_st->insert(curr_param);
                    curr_st->my_st_entry->type.push_back(type);


                    


}

COMMA_tfpdef_EQUAL_test_or_not_kleene   : COMMA_tfpdef_EQUAL_test_or_not_kleene COMMA tfpdef {

                                        if($1==NULL)
                                        {
                                            $1=new Node(nodeID++, "formal_params", yylineno);
                                        }
                                        $1->push_back($2);
                                        $1->push_back($3);
                                        $$ = $1;


                                        
                                        
}
                                        | %empty    {

                                        $$=NULL;

}



COLON_test_or_not   : COLON {inside_type_hint=1;}test  {
                        inside_type_hint=0;
                        $$ = new Node(nodeID++, "param_type_hint", yylineno);
                        $$->push_back($1);
                        $$->push_back($3);

                        if(!is_valid_type(resolve_type($3)))
                        {
                            error("Invalid type hint", $1->lineno);
                        }

}
                    | %empty  {

                        $$=NULL;
}

COMMA_or_not    : COMMA {
                    $$ = $1;
}
                | %empty    {
                    $$ = NULL;
}

EQUAL_test_or_not   : EQUAL test {
                        $$ = new Node(nodeID++, "param_val",yylineno);
                        $$->push_back($1);
                        $$->push_back($2);

                        $$->info = new temp_type_info();
                        $$->info->type = $2->info->type;
                        $$->info->type_min = $2->info->type_min;
                        if($2==NULL || $2->info==NULL || $2->info->type.size()==0)
                        {
                            error("Invalid declaration", $1->lineno);
                        }
                        if( $2->info->type[0]=='!'){
                            error("Variable not declared before use", $1->lineno);
                        }

                        $$->rvalue=$2->rvalue;      
}
                    | %empty    {
                        $$ = NULL;
}


stmt    : simple_stmt {
            $$ = $1;
}
        | compound_stmt {
            $$ = $1;
}
        |  IF NAME__ EQUAL_EQUAL STRING_LITERAL COLON NEWLINE INDENT NAME LEFT_PAREN RIGHT_PAREN NEWLINE DEDENT {
            
            if($8->lexval!="main")
                error("Program must begin from main function", $1->lineno);
            if($4->lexval!="__main__")
                error("__name__ must be \"__main__\"", $1->lineno);
            
            tac.push_back(quad("programstart"));
            tac.push_back(quad("call","main","0", "", FUNCCALL));
            
        }

simple_stmt : small_stmt SEMICOLON_small_stmt_kleene SEMICOLON_or_not NEWLINE {

                if($1==NULL && $2==NULL) $$=$3;
                else if($1==NULL && $3==NULL) $$=$2;
                else if($2==NULL && $3==NULL) $$=$1;
                else
                {
                    $$ = new Node(nodeID++, "simple_stmt", yylineno);
                    $$->push_back($1);
                    if($2)
                    {
                        for(auto child: $2->child)
                            $$->push_back(child);
                    }
                    $$->push_back($3);
                }

}

SEMICOLON_small_stmt_kleene : SEMICOLON_small_stmt_kleene SEMICOLON small_stmt {

                        if($1==NULL)
                        {
                            $1=new Node(nodeID++, "small_stmts", yylineno);
                        }
                        $1->push_back($2);
                        $1->push_back($3);
                        $$ = $1;
}

                            | %empty   {
                                $$=NULL;
}

small_stmt  : expr_stmt {$$=$1;}
            | flow_stmt {$$=$1;}
            | global_stmt {$$=$1;}

expr_stmt   : testlist_star_expr annassign {

                        

                        if($1==NULL) $$=$2;
                        else if($2==NULL) $$=$1;
                        else
                        {
                            $2->push_front($1);
                            $$=$2;
                        }
                        if($2->child.size()<=2)
                        {
                            error("Error in declaration, type hint not provided", $1->lineno);
                        }                        

                        

                        string type=resolve_type($2->child[2]);
                        int width=resolve_width(type);
                        SymbolTableEntry* new_st_entry=new SymbolTableEntry(OBJ, {type}, "", width, $1->lineno, curr_st->offset, curr_st, NULL);
                        string st=resolve_type($2->child[0]);

                        if(st.size()>=5 && st.substr(0, 5)=="self."
                        &&
                        ( st_stack->tables.size()>=2 && st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && st_stack->tables[st_stack->tables.size()-1]->type==FUNCTION_ST && st_stack->tables[st_stack->tables.size()-1]->my_st_entry->lexval=="__init__")
                        
                        )
                        {
                            new_st_entry->lexval=st.substr(5);
                            SymbolTableEntry* temp_st_en=st_stack->tables[st_stack->tables.size()-2]->is_present(st.substr(5));
                            if(temp_st_en)
                            {
                                error("Class variable redeclared, previously declared at line no: "+to_string(temp_st_en->line_no), $1->lineno);
                            }
                            new_st_entry->offset = st_stack->tables[st_stack->tables.size()-2]->offset;
                            st_stack->tables[st_stack->tables.size()-2]->insert(new_st_entry);
                            st_stack->tables[st_stack->tables.size()-2]->offset+=width;
                        }
                        else if($1->name=="NAME")
                        {
                            SymbolTableEntry* temp=curr_st->is_present(st);
                            new_st_entry->lexval=st;
                            if(temp)
                            {
                                error("Redeclaration of variable/function previously declared at line number " + to_string(temp->line_no), $1->lineno);
                            }
                            curr_st->insert(new_st_entry);

                            curr_st->offset += width;
                        }
                        else
                        {
                            error("Invalid declaration.", $1->lineno);
                        }
                        if($1->info->is_lvalue==false)
                        {
                            error("Only lvalue can be assigned.", $1->lineno);
                        }

                        if($1 && $1->name == "NAME")
                        {
                            if($2->rvalue.size())
                                tac.push_back(quad("=", $2->rvalue, "", $1->lexval, NAME_ASSIGNMENT));
                        }
                        else
                        {
                            if($2->rvalue.size())
                                tac.push_back(quad("=", $2->rvalue, "", $1->lvalue, STORE));
                        }

}
            | testlist_star_expr augassign testlist {



                        if($1==NULL && $2==NULL) $$=$3;
                        else if($1==NULL && $3==NULL) $$=$2;
                        else if($2==NULL && $3==NULL) $$=$1;
                        else
                        {
                            $2->push_back($1);
                            $2->push_back($3);
                            $$=$2; 
                        }

                        if($1->info->is_lvalue==false)
                        {
                            error("Only lvalue can be assigned.", $1->lineno);
                        }

                        if($1->info->type[0]=='!')
                        {
                            error("Variable not declared before use", $1->lineno);
                        }
                        if($3->info->type[0]=='!')
                        {
                            error("Variable not declared before use", $1->lineno);
                        }

                        if(!can_be_converted($1->info->type, $3->info->type) || !can_be_converted($1->info->type, $3->info->type_min)){
                                error("Type mismatch in augmented assignment.", $1->lineno);
                        }
                        convert($3->info->type, $1->info->type, $3->rvalue);
                        vector<string> v={"+=","-=","*=","**=","/=","%=","//="};
                        if(count(v.begin(), v.end(),$2->lexval))
                        {
                            type_check_arith($1->info->type,$3->info->type, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                        }
                        else
                        {
                            type_check_shift($1->info->type,$3->info->type, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                        }

                        

                        gen_augassign_tac($1,$2,$3);



}
            | testlist_star_expr EQUAL_testlist_star_expr_kleene {


                        if($1==NULL) $$=$2;
                        else if($2==NULL) $$=$1;
                        else
                        {
                            $2->push_front($1);
                            $$=$2;
                        }


                        if($2 && $1->info->is_lvalue==false)
                        {
                            error("Only lvalue can be assigned.", $1->lineno);
                        }

                        if($1->info->type[0]=='!')
                        {
                            string st=resolve_type($1);

                            if(st.size()>=5 && st.substr(0, 5)=="self."
                            &&
                            ( st_stack->tables.size()>=2 && st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && st_stack->tables[st_stack->tables.size()-1]->type==FUNCTION_ST && st_stack->tables[st_stack->tables.size()-1]->my_st_entry->lexval=="__init__")
                            
                            )
                            {
                                SymbolTableEntry* inherit_lookup=st_stack->tables[st_stack->tables.size()-2]->inherit_tree_lookup(st.substr(5));
                                if(inherit_lookup==NULL)
                                {

                                    error("Variable not declared before use",$1->lineno);
                                }
                                else
                                {
                                    SymbolTableEntry* new_st_entry=new SymbolTableEntry(OBJ, inherit_lookup->type, inherit_lookup->lexval, inherit_lookup->width, $1->lineno, inherit_lookup->offset, curr_st, NULL);
                                    st_stack->tables[st_stack->tables.size()-2]->insert(new_st_entry);
                                }
                                $1->info->type=inherit_lookup->type[0];
                                $1->info->type_min=inherit_lookup->type[0];
                            }
                            else
                                error("Variable not declared before use",$1->lineno);
                        }

                        if($2 && (!can_be_converted($1->info->type, $2->info->type) || !can_be_converted($1->info->type, $2->info->type_min))){
                            error("Type mismatch in assignment",$1->lineno);
                        }
                        if($2)
                        {
                            convert($2->info->type, $1->info->type, $2->rvalue);
                            if($1 && $1->name == "NAME")
                            {
                                tac.push_back(quad("=", $2->rvalue, "", $1->lexval, NAME_ASSIGNMENT));
                            }
                            else
                            {
                                tac.push_back(quad("=", $2->rvalue, "", $1->lvalue, STORE));
                            }
                        }

    }

EQUAL_testlist_star_expr_kleene :EQUAL testlist_star_expr EQUAL_testlist_star_expr_kleene  {

                        if($3!=NULL)
                        {
                            $3->push_front($2);
                            $1->push_back($3);
                            $$=$1;
                        }
                        else
                        {
                            $1->push_back($2);
                            $$=$1;
                        }
                        if($3 && $2->info->is_lvalue==false)
                        {
                            error("Only lvalue can be assigned.",$1->lineno);
                        }
                        if($2->info->type[0]=='!')
                        {
                            error("Variable not declared before use",$1->lineno);
                        }

                        $$->info = new temp_type_info();
                        $$->info->type = $2->info->type;
                        $$->info->type_min = $2->info->type_min;
                        if($3 && (!can_be_converted($2->info->type, $3->info->type) || !can_be_converted($2->info->type, $3->info->type_min))){
                            error("Type mismatch in assignment",$1->lineno);
                        }
                        if($3==NULL)
                        {
                            $$->lvalue=$2->lvalue;
                            $$->rvalue=$2->rvalue;
                        }
                        else
                        {
                            convert($3->info->type, $2->info->type, $3->rvalue);
                            if($2 && $2->name == "NAME")
                            {
                                tac.push_back(quad("=", $3->rvalue, "", $2->lexval, NAME_ASSIGNMENT));
                            }
                            else
                            {
                                tac.push_back(quad("=", $3->rvalue, "", $2->lvalue, STORE));
                            }
                            $$->rvalue=$3->rvalue;
                        }

                        
}
                                |  %empty   {
                                    $$=NULL;
}

            
                        
annassign   : COLON {inside_type_hint=1; } test {inside_type_hint=0; 

                        string str=resolve_type($3);
                        while(is_list(str))
                            str=strip(str);
                        curr_list_core_type=str;

} EQUAL_test_or_not  {

                        curr_list_core_type="";
                        $$ = new Node(nodeID++, "annassign", yylineno);
                        $$->push_back($1);
                        $$->push_back($3);
                        $$->push_back($5);

                        
                        string type = resolve_type($3);
                        if(!is_valid_type(type))
                        {
                            error("Invalid type hint",$1->lineno);
                        }
                        if($5 && !can_be_converted(type , $5->info->type) && !can_be_converted(type , $5->info->type_min)) 
                            error("Assigned value does not match declared type",$1->lineno);

                        if($5){
                            convert($5->info->type, type, $5->rvalue);
                            $$->rvalue = $5->rvalue;
                        }
                        else{
                            if(type == "float"){
                                $$->rvalue = "0.0";
                            }
                            else{
                                $$->rvalue = "0";
                            }
                        }


}



SEMICOLON_or_not    : SEMICOLON {$$=$1;}
                    |  %empty  {$$=NULL;}

testlist_star_expr  : test_or_star_expr  {

                $$=$1;

}

test_or_star_expr   : test {   $$=$1;}

augassign   : PLUS_EQUAL {$$=$1;}
            | MINUS_EQUAL {$$=$1;}
            | MULTIPLY_EQUAL {$$=$1;}
            | DIVIDE_EQUAL {$$=$1;}
            | REMAINDER_EQUAL {$$=$1;}
            | BITWISE_AND_EQUAL {$$=$1;}
            | BITWISE_OR_EQUAL {$$=$1;}
            | BITWISE_XOR_EQUAL {$$=$1;}
            | LEFT_SHIFT_EQUAL {$$=$1;}
            | RIGHT_SHIFT_EQUAL {$$=$1;}
            | POWER_EQUAL {$$=$1;}
            | INTEGER_DIVIDE_EQUAL {$$=$1;}


flow_stmt   : break_stmt {$$=$1;}
            | continue_stmt {$$=$1;}
            | return_stmt  {$$=$1;}

break_stmt  : BREAK {
                
                $$=$1; 
                if(!break_jumps.size())
                {
                    error("Break statement must appear inside loop",$1->lineno);
                }
                tac.push_back(quad("jump", "", "", "", JUMP));
                break_jumps.top().push_back(tac.size() - 1);
                
}

continue_stmt   : CONTINUE {
                $$=$1; 
                if(!continue_jump_labels.size()){
                    error("Continue statement must appear inside loop",$1->lineno);
                }
                tac.push_back(quad("jump", "", "", continue_jump_labels.top(), JUMP));
}

return_stmt : RETURN testlist_or_not {

                        $$ = new Node(nodeID++, "return_stmt", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);

                        if(curr_st->type!=FUNCTION_ST)
                        {
                            error("Return statement must only appear inside functions.",$1->lineno);
                        }
                        if($2==NULL || $2->info->type=="None")
                        {
                            if(curr_st->my_st_entry->return_type!="None")
                            {
                                error("None returned for a function with non-None return type",$1->lineno);
                            }
                        }
                        else if(curr_st->my_st_entry->return_type=="None")
                        {
                            error("Returning non-None value for a function with None return type",$1->lineno);
                        }

                        
                        if($2 && !can_be_converted(curr_st->my_st_entry->return_type, $2->info->type))
                        {
                            error("Returned value does not match function's return type.",$1->lineno);
                        }
                        if(curr_nesting_depth==0)
                        {
                            is_return_type_present=true;
                        }

                        if($2==NULL)
                        {
                            tac.push_back(quad("leave", "", "", "", RETURN_STMT));
                            tac.push_back(quad("return","","","",RETURN_STMT));
                        }
                        else
                        {
                            convert($2->info->type, curr_st->my_st_entry->return_type, $2->rvalue);
                            // tac.push_back(quad("push", $2->rvalue, "", "", PUSHPARAM));
                            tac.push_back(quad("leave", "", "", "", RETURN_STMT));
                            tac.push_back(quad("return", $2->rvalue,"","",RETURN_STMT));
                        }
}

testlist_or_not : testlist {$$=$1;}
                | %empty {$$=NULL;}


global_stmt : GLOBAL NAME {

                        $$ = new Node(nodeID++, "global_stmt", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);

                        SymbolTableEntry* temp_entry=curr_st->is_present($2->lexval);
                        
                        if(temp_entry)
                        {
                            error("Global keyword cannot be used for previously declared variable.",$1->lineno);
                        }
                        else
                        {
                            temp_entry=st_stack->lookup($2->lexval);
                            if(!temp_entry)
                            {
                                error("Variable not declared before used in global statement",$1->lineno);
                            }
                            if(temp_entry->entry_type!=OBJ )
                            {
                                error("Function/class names cannot be used with global keyword", $1->lineno);
                            }
                            curr_st->global_vars.push_back($2->lexval);
                        }
}
            | global_stmt COMMA NAME  {
                        $1->push_back($2);
                        $1->push_back($3);

                        $$=$1;

                        SymbolTableEntry* temp_entry=curr_st->is_present($3->lexval);
                        
                        if(temp_entry)
                        {
                            error("Global keyword cannot be used for previously declared variable.",$3->lineno);
                        }
                        else
                        {
                            temp_entry=st_stack->lookup($3->lexval);
                            if(!temp_entry)
                            {
                                error("Variable not declared before used in global statement",$3->lineno);
                            }
                            if(temp_entry->entry_type!=OBJ )
                            {
                                error("Function/class names cannot be used with global keyword", $3->lineno);
                            }
                            curr_st->global_vars.push_back($3->lexval);
                        }
            }

compound_stmt   : if_stmt  {$$=$1;}
                | while_stmt {$$=$1;}
                | for_stmt {$$=$1;}
                | funcdef {$$=$1;}
                | classdef {$$=$1;}

if_stmt : IF test COLON {
    
                        curr_nesting_depth++;
                        tac.push_back(quad("ifFalse", $2->rvalue,"","", CONDITIONAL_JUMP));
                        $1->if_not_executed_jump = tac.size()-1;

} suite {
                        curr_nesting_depth--;
                        tac.push_back(quad("jump", "","","",JUMP));
                        $1->if_executed_jump=tac.size()-1;

} ELIF_test_COLON_suite_kleene ELSE_COLON_suite_or_not {

                        $$ = new Node(nodeID++, "if_stmt", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($5);
                        if($7)
                        {
                            for(auto child: $7->child)
                            {
                                $$->push_back(child);
                            }
                        }
                        $$->push_back($8);

                        if(!can_be_converted($2->info->type, "bool"))
                        {
                            error("Invalid predicate in if statement.",$2->lineno);
                        }

                        string temp_label=new_label();
                        tac.push_back(quad(temp_label));

     
                        if($7)
                             tac[$1->if_not_executed_jump].target=$7->child[0]->else_block_label;
                        else if($8)
                            tac[$1->if_not_executed_jump].target=$8->else_block_label;
                        else
                            tac[$1->if_not_executed_jump].target=temp_label;

                        tac[$1->if_executed_jump].target=temp_label;

                        if($7){
                            string next_label;
                            for(int i = 0; i<$7->child.size(); i+=4){
                                next_label = $7->child[i]->else_block_label;
                                if(i>=4) 
                                    tac[$7->child[i-4]->if_not_executed_jump].target = next_label;
                                tac[$7->child[i]->if_executed_jump].target = temp_label;
                            }
                            if($8)
                                tac[$7->child[$7->child.size()-4]->if_not_executed_jump].target=$8->else_block_label;
                            else
                                tac[$7->child[$7->child.size()-4]->if_not_executed_jump].target=temp_label;
                        }

}

ELIF_test_COLON_suite_kleene    : ELIF_test_COLON_suite_kleene ELIF
{

                    string temp_label=new_label();
                    tac.push_back(quad(temp_label));
                    $2->else_block_label=temp_label;



}
test COLON {
                    curr_nesting_depth++;
                    tac.push_back(quad("ifFalse", $4->rvalue,"","", CONDITIONAL_JUMP));
                    $2->if_not_executed_jump = tac.size() - 1;

} suite {

                        curr_nesting_depth--;
                        if($1==NULL)
                        {
                            $1=new Node(nodeID++, "ELIF_blocks", yylineno);
                        }
                        $1->push_back($2);
                        $1->push_back($4);
                        $1->push_back($5);
                        $1->push_back($7);

                        $$=$1;
                        if(!can_be_converted($4->info->type, "bool"))
                        {
                            error("Invalid predicate in elif statement.",$4->lineno);
                        }

                        tac.push_back(quad("jump", "","","",JUMP));
                        $2->if_executed_jump=tac.size()-1;
    
}
                                | %empty {
                                $$=NULL;

}

while_stmt  : WHILE {

                    string temp_label=new_label();
                    tac.push_back(quad(temp_label));
                    $1->else_block_label=temp_label;
                    continue_jump_labels.push(temp_label);
}
test COLON {
    
                    curr_nesting_depth++; 
                    tac.push_back(quad("ifFalse", $3->rvalue,"","", CONDITIONAL_JUMP));
                    $1->if_not_executed_jump = tac.size() - 1;
                    break_jumps.push({});
} suite {
                    curr_nesting_depth--;
                    continue_jump_labels.pop();

                    tac.push_back(quad("jump", "","",$1->else_block_label,JUMP));
                    $6->break_jumps = break_jumps.top();
                    break_jumps.pop();
                    

} ELSE_COLON_suite_or_not {
    

                        $$ = new Node(nodeID++, "while_stmt", yylineno);

                        $$->push_back($1);
                        $$->push_back($3);
                        $$->push_back($4);
                        $$->push_back($6);
                        $$->push_back($8);
                        if(!can_be_converted($3->info->type, "bool"))
                        {
                            error("Invalid predicate in while statement.",$3->lineno);
                        }

                        string temp_label=new_label();
                        tac.push_back(quad(temp_label));

                        if($8)
                            tac[$1->if_not_executed_jump].target=$8->else_block_label;
                        else
                            tac[$1->if_not_executed_jump].target=temp_label;

                        for(auto x: $6->break_jumps){
                            tac[x].target = temp_label;
                        }

}

for_stmt    : FOR exprlist IN testlist COLON {curr_nesting_depth++; inside_loop=true;

                        if($2->info->type[0]=='!')
                        {
                            error("Loop variable not declared before use",$2->lineno);
                        }
                        if(!$2->info->is_lvalue)
                            error("Loop variable should be an lvalue",$2->lineno);


                        if($2->info->type!="int")
                        {
                            error("Loop variable must be an integer",$2->lineno);
                        }

                        if($4->info->type != "range!" && $4->info->type != "range!!"){
                            error("Only iterating over ranges is supported.",$4->lineno);
                        }


                        string start, limit;
                        if($4->info->type=="range!")
                        {
                            limit=$4->child[1]->child[1]->child[0]->rvalue;
                            start="0";
                        }
                        else{
                            start=$4->child[1]->child[1]->child[0]->rvalue;
                            limit=$4->child[1]->child[1]->child[2]->rvalue;
                        }
                        string new_temp=new_temporary();

                        if($2->name=="NAME")
                            tac.push_back(quad("=",start,"",$2->lvalue,NAME_ASSIGNMENT));
                        else
                            tac.push_back(quad("=",start,"",$2->lvalue,STORE));

                        if($2->name=="NAME")
                            tac.push_back(quad("=", $2->lvalue,"",new_temp, NAME_ASSIGNMENT));
                        else
                            tac.push_back(quad("=", $2->lvalue,"",new_temp, LOAD));



                        tac.push_back(quad("jump", "", "", "", JUMP));
                        int skip_increment_label = tac.size() - 1;
                        

                        string for_test_label = new_label();
                        tac.push_back(quad(for_test_label));
                        
                        $1->else_block_label=for_test_label;
                        tac.push_back(quad("+", new_temp,"1",new_temp, ARITH));
                        if($2->name=="NAME")
                            tac.push_back(quad("=", new_temp,"",$2->lvalue,NAME_ASSIGNMENT));
                        else
                            tac.push_back(quad("=", new_temp,"",$2->lvalue,STORE));

                        string comparison_label_skip = new_label();
                        tac.push_back(quad(comparison_label_skip));
                        tac[skip_increment_label].target = comparison_label_skip;

                        string new_temp_comp=new_temporary();
                        tac.push_back(quad("<",new_temp,limit,new_temp_comp,LOGIC));
                        tac.push_back(quad("ifFalse",new_temp_comp,"","",CONDITIONAL_JUMP));
                        $1->if_not_executed_jump=tac.size()-1;
                        

                        continue_jump_labels.push(for_test_label);
                        break_jumps.push({});


} suite {
            curr_nesting_depth--; 

            
            tac.push_back(quad("jump", "","",$1->else_block_label,JUMP));

            continue_jump_labels.pop();
            $7->break_jumps = break_jumps.top();
            break_jumps.pop();
            
} ELSE_COLON_suite_or_not  {

                        $$ = new Node(nodeID++, "for_stmt", yylineno);

                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($4);
                        $$->push_back($5);
                        $$->push_back($7);
                        $$->push_back($9);

                        string temp_label = new_label();
                        tac.push_back(quad(temp_label));
                    
                        if($9){
                            tac[$1->if_not_executed_jump].target = $9->else_block_label;
                        }
                        else{
                            tac[$1->if_not_executed_jump].target = temp_label; 
                        }

                        for(auto x: $7->break_jumps)
                        {
                            tac[x].target = temp_label;
                        }

                        
}

ELSE_COLON_suite_or_not : ELSE COLON {
                        curr_nesting_depth++;
                        string temp_label=new_label();
                        tac.push_back(quad(temp_label));

                        $2->else_block_label = temp_label;
} suite {
    

                        curr_nesting_depth--;
                        $$ = new Node(nodeID++, "ELSE_block", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($4);

                        $$->else_block_label=$2->else_block_label;
}
                        | %empty  {$$=NULL;}


suite   : simple_stmt   {$$=$1;}
        | NEWLINE INDENT stmt_plus DEDENT  {
            
            $$=$3;                               
}

stmt_plus   : stmt_plus stmt {

                if($1==NULL || $1->name!="stmts")
                {
                    Node* temp=$1;
                    $1=new Node(nodeID++, "stmts", yylineno);
                    $1->push_back(temp);
                }
                $1->push_back($2);
                $$=$1;
    
}
            | stmt {                            
                $$ = $1;

}

test    : or_test   {


    $$=$1;


}
or_test : and_test  {                            
    
                $$ = $1;

}
        | or_test OR and_test  {


                $2->push_back($1);
                $2->push_back($3);
                $$=$2;

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type = "bool";
                $$->info->type_min = "bool";

                $$->info->is_lvalue=false;
                convert(str1, "bool", $1->rvalue);
                convert(str2, "bool", $3->rvalue);

                tac.push_back(quad("||",$1->rvalue, $3->rvalue, $1->rvalue, LOGIC));
                $$->rvalue = $1->rvalue;
}

and_test    : not_test {                           
    
                $$ = $1;

}

            | and_test AND not_test {

                $2->push_back($1);
                $2->push_back($3);
                $$=$2;

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type = "bool";
                $$->info->type_min = "bool";

                $$->info->is_lvalue=false;
                convert(str1, "bool", $1->rvalue);
                convert(str2, "bool", $3->rvalue);
                tac.push_back(quad("&&",$1->rvalue, $3->rvalue, $1->rvalue, LOGIC));
                $$->rvalue = $1->rvalue;
}

not_test    : NOT not_test {
                $1->push_back($2);
                $$=$1;
                $$->info = new temp_type_info();
                string str1 = $2->info->type;
                if(str1[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                if(str1 == "int" || str1 == "bool") {
                    $$->info->type = "bool";
                    $$->info->type_min = "bool";
                    convert(str1, "bool", $2->rvalue);
                }
                else{
                    error("Invalid operand for " + $1->lexval,$1->lineno);
                }

                $$->info->is_lvalue=false;

                tac.push_back(quad("!","", $2->rvalue, $2->rvalue, LOGIC));
                $$->rvalue = $2->rvalue;
}
            | comparison {                            
                $$ = $1;
}

comparison  : expr {                            
                $$ = $1;
}
            | comparison comp_op expr {
                $2->push_back($1);
                $2->push_back($3);
                $$=$2;

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                if($1->info->type=="str"  && $3->info->type=="str")
                {
                    ;
                }
                else
                    type_check_arith(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);

                $$->info->type = "bool";
                $$->info->type_min = "bool";


                if($1->info->type=="str"  && $3->info->type=="str")
                {

                    tac.push_back(quad("save registers", "", "", "", RETURN_STMT));
                    tac.push_back(quad("param", $3->rvalue, "", "", PUSHPARAM));
                    tac.push_back(quad("param", $1->rvalue, "", "", PUSHPARAM));
                    tac.push_back(quad("stackpointer", "-24", "","", STACK_MANIPULATION));
                    tac.push_back(quad("call", "strcmp"+$2->lexval, "2","", FUNCCALL));
                    string new_temp=new_temporary();
                    tac.push_back(quad("=","return_value","",new_temp,NAME_ASSIGNMENT));
                    $$->rvalue = new_temp;
                    tac.push_back(quad("stackpointer", "+24", "","", STACK_MANIPULATION));
                    tac.push_back(quad("restore registers", "", "", "", RETURN_STMT));
                }
                else
                {
                    if(str1=="float")
                    {
                        if(str2=="int")
                            convert("int", "float", $3->rvalue);
                    }
                    if(str1=="int")
                    {
                        if(str2=="float")
                            convert("int", "float", $1->rvalue);
                        if(str2=="bool")
                            convert("bool", "int", $3->rvalue);
                    }
                    if(str1=="bool")
                    {
                        if(str2=="int")
                            convert("bool", "int", $1->rvalue);
                    }
                    
                    tac.push_back(quad($2->lexval,$1->rvalue, $3->rvalue, $1->rvalue, LOGIC));
                    $$->rvalue = $1->rvalue;
                }
                $$->info->is_lvalue=false;
}



comp_op : LESS_THAN { $$=$1;}
        | GREATER_THAN { $$=$1;}
        | EQUAL_EQUAL { $$=$1;} 
        | GREATER_THAN_EQUAL  { $$=$1;}
        | LESS_THAN_EQUAL { $$=$1;}
        | NOT_EQUAL { $$=$1;}
expr    : xor_expr {                            
                $$ = $1;
}
        | expr BITWISE_OR xor_expr {

                $$=$2;
                $$->push_back($1);
                $$->push_back($3);

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                $$->info->type = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type_min = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);

                $$->info->is_lvalue=false;

                convert(str1, $$->info->type, $1->rvalue);
                convert(str2, $$->info->type, $3->rvalue);
                tac.push_back(quad("|",$1->rvalue, $3->rvalue, $1->rvalue, BITWISE));
                $$->rvalue = $1->rvalue;
}


xor_expr    : and_expr {  
                $$=$1;             

} 
            | xor_expr BITWISE_XOR and_expr {
                $$=$2;
                $$->push_back($1);
                $$->push_back($3);

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                $$->info->type = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type_min = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);

                $$->info->is_lvalue=false;
                convert(str1, $$->info->type, $1->rvalue);
                convert(str2, $$->info->type, $3->rvalue);
                tac.push_back(quad("^",$1->rvalue, $3->rvalue, $1->rvalue, BITWISE));
                $$->rvalue = $1->rvalue;
}

and_expr    : shift_expr {                            
                $$ = $1;
}
            | and_expr BITWISE_AND shift_expr {
                $$=$2;
                $$->push_back($1);
                $$->push_back($3);

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                $$->info->type = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type_min = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);

                $$->info->is_lvalue=false;
                convert(str1, $$->info->type, $1->rvalue);
                convert(str2, $$->info->type, $3->rvalue);
                tac.push_back(quad("&",$1->rvalue, $3->rvalue, $1->rvalue, BITWISE));
                $$->rvalue = $1->rvalue;
}

shift_expr  : arith_expr {                            
                $$ = $1;
}
            | shift_expr LEFT_SHIFT_or_RIGHT_SIHFT arith_expr 
            {
                $$=$2;
                $$->push_back($1);
                $$->push_back($3);

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                $$->info->type = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type_min = type_check_shift(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);

                $$->info->is_lvalue=false;
                convert(str1, $$->info->type, $1->rvalue);
                convert(str2, $$->info->type, $3->rvalue);
                tac.push_back(quad($2->lexval,$1->rvalue, $3->rvalue, $1->rvalue, BITWISE));
                $$->rvalue = $1->rvalue;
}

LEFT_SHIFT_or_RIGHT_SIHFT   : LEFT_SHIFT {
                $$=$1;
}
                            | RIGHT_SIHFT {
                $$=$1;
}

arith_expr  : term {
                $$=$1;
}
            | arith_expr PLUS_or_MINUS term {
                $$=$2;
                $$->push_back($1);
                $$->push_back($3);

                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                $$->info->type = type_check_arith(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type_min = type_check_arith(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);

                $$->info->is_lvalue=false;
                convert(str1, $$->info->type, $1->rvalue);
                convert(str2, $$->info->type, $3->rvalue);
                tac.push_back(quad($2->lexval,$1->rvalue, $3->rvalue, $1->rvalue, ARITH));
                $$->rvalue = $1->rvalue;
}

PLUS_or_MINUS   : PLUS {
                $$=$1;
}
                | MINUS {
                $$=$1;
}

term    : factor {                           
                $$ = $1;

}
        | term MULTIPLY_or_RATE_or_DIVIDE_or_REMAINDER_or_INTEGER_DIVIDE factor {

                $$=$2;
                $$->push_back($1);
                $$->push_back($3);
                string str1 = $1->info->type;
                string str2 = $3->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!' || str2[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                $$->info->type = type_check_arith(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);
                $$->info->type_min = type_check_arith(str1, str2, "Type error: invalid operands for " + $2->lexval, $2->lineno);

                if($2->lexval == "/"){
                    $$->info->type = "float";
                    $$->info->type_min = "float";
                }

                $$->info->is_lvalue=false;
                convert(str1, $$->info->type, $1->rvalue);
                convert(str2, $$->info->type, $3->rvalue);
                tac.push_back(quad($2->lexval,$1->rvalue, $3->rvalue, $1->rvalue, ARITH));
                $$->rvalue = $1->rvalue;

}

MULTIPLY_or_RATE_or_DIVIDE_or_REMAINDER_or_INTEGER_DIVIDE   : MULTIPLY          {$$ = $1;}    
                                                            | DIVIDE            {$$ = $1;}    
                                                            | REMAINDER         {$$ = $1;}  
                                                            | INTEGER_DIVIDE    {$$ = $1;}            

factor  : PLUS_or_MINUS_or_BITWISE_NOT factor {
                $$=$1;
                $$->push_back($2);
                string str1 = $2->info->type;
                $$->info = new temp_type_info();
                if(str1[0]=='!')
                {
                    error("Variable not declared before use",$1->lineno);
                }
                if(str1 == "int" || str1 == "bool"){
                    $$->info->type = "int";
                    $$->info->type_min = "int";
                }
                else if(($1->lexval == "+" || $1->lexval == "-") && str1 == "float"){
                    $$->info->type = "float";
                    $$->info->type_min = "float";
                }
                else{
                    error("Type error: invalid operand for unary " + $1->lexval,$1->lineno);
                }
                $$->info->is_lvalue=false;
                
                convert(str1, $$->info->type, $1->rvalue);
                if($1->lexval == "~")
                    tac.push_back(quad($1->lexval,"",$2->rvalue, $2->rvalue, BITWISE));
                else
                    tac.push_back(quad($1->lexval,"",$2->rvalue, $2->rvalue, ARITH));

                $$->rvalue = $2->rvalue;
}
        | power {                           
            $$ = $1;
}

PLUS_or_MINUS_or_BITWISE_NOT    : PLUS          {$$ = $1;}
                                | MINUS         {$$ = $1;}
                                | BITWISE_NOT   {$$ = $1;}

power   : atom_expr  POWER_factor_or_not    {

        if($2==NULL)
        {
            $$=$1;
        }
        else if($1==NULL)
        {
            $$=$2;
        }
        else
        {
            $$=$2;
            $$->push_front($1);


            string str1=$1->info->type;
            string str2=$2->info->type;
            if(str1[0]=='!' || str2[0]=='!')
            {
                error("Variable not declared before use",$1->lineno);
            }
            $$->info->type=type_check_arith(str1, str2, "Type error: invalid operands for **", $2->lineno);
            $$->info->type_min=type_check_arith(str1, str2, "Type error: invalid operands for **", $2->lineno);
            $$->info->is_lvalue=false;


            convert(str1, $$->info->type, $1->rvalue);
            convert(str2, $$->info->type, $2->child[1]->rvalue);
            tac.push_back(quad("**",$1->rvalue, $2->child[1]->rvalue, $1->rvalue, ARITH));
            $$->rvalue = $1->rvalue;

        }


}

POWER_factor_or_not     : POWER factor {
                $$=$1;
                $$->push_front($2);
                $$->info = new temp_type_info();


                $$->info->type = $2->info->type;
                $$->info->type_min = $2->info->type_min;
                $$->info->is_lvalue = false;

}
                        | %empty    {
                            $$ = NULL;
}
 
atom_expr   : atom  {

        $$=$1;


}
            | atom_expr trailer  {




                struct temp_type_info *temp_info = new temp_type_info();
                if($1!=NULL && $1->info!=NULL)
                {
                    temp_info->type = $1->info->type;
                    temp_info->type_min = $1->info->type_min;
                    temp_info->args = $1->info->args;
                    temp_info->args_min = $1->info->args_min;
                    temp_info->candidates = $1->info->candidates;
                    temp_info->is_lvalue = $1->info->is_lvalue;
                    temp_info->trailer_type = $1->info->trailer_type;
                }
                if($1==NULL || $1->name!="atom_expr")
                {
                    $$=new Node(nodeID++, "atom_expr", yylineno);
                    $$->push_back($1);
                    $$->push_back($2);
                }
                else
                {
                    $1->push_back($2);
                    $$ = $1;
                }
 
                if(!inside_type_hint)
                {
                    if($1->info == NULL){

                        error("Invalid operation.",$1->lineno);
                    }
                    if($1->info->type[0]=='!')
                    {
                        error("Variable/function not declared",$1->lineno);
                    }


                    if($1->info->type[0]=='@')
                    {


                        if($2->info->trailer_type!=0)
                        {
                            error("Operation not allowed on function.",$1->lineno);
                        }
                        SymbolTableEntry* fn_entry=NULL;
    

                        for(auto temp:$1->info->candidates)
                        {
                            vector<string> temp_args=$2->info->args;
                            vector<string> temp_args_min=$2->info->args_min;

                            if($1->info->type[1]=='@')//inserting type of self in method invocation
                            {
                                vector<string> current_candidate_type;
                                if(temp->type.size() >= 1)
                                    current_candidate_type=vector<string>(temp->type.begin()+1, temp->type.end());
                                
                                if(compare_args(current_candidate_type,temp_args, temp_args_min))
                                {
                                    fn_entry=temp;
                                    break;
                                }
                            }

                            else if(temp->lexval == "len"){
                                if(temp_args.size() != 1){
                                    fn_entry = NULL;
                                    break;
                                }
                                if(!is_list(temp_args[0])){
                                    fn_entry = NULL;
                                    break;
                                }
                                else{
                                    fn_entry = temp;
                                    break;
                                }
                            }
                            else if(temp->lexval == "range"){
                                if(temp_args.size() != 1 && temp_args.size()!=2){
                                    fn_entry = NULL;
                                    break;
                                }
                                if(temp->type.size()==2 && temp_args.size()==2 ){
                                    if(temp_args[0]=="int" &&temp_args[1]=="int")
                                        fn_entry = temp;
                                    else
                                        fn_entry=NULL;
                                    break;
                                }
                                if(temp->type.size()==1 && temp_args.size()==1 ){
                                    if(temp_args[0]=="int")
                                        fn_entry = temp;
                                    else
                                        fn_entry=NULL;
                                    break;
                                }

                            }
                            else if(temp->lexval == "print"){
                                if(temp_args.size() != 1){
                                    fn_entry = NULL;
                                    break;
                                }
                                if(is_obj(temp_args[0])){
                                    fn_entry = NULL;
                                    break;
                                }
                                else if(temp_args==temp->type){
                                    fn_entry = temp;
                                    break;
                                }
                            }
                            else if(compare_args(temp->type,temp_args, temp_args_min))
                            {
                                fn_entry=temp;
                                break;
                            }
                            
                        }
                        if(fn_entry==NULL)
                        {
                            error("No candidate found for function usage",$1->lineno);
                        }
                        temp_info->type=fn_entry->return_type;
                        temp_info->type_min=fn_entry->return_type;
                        temp_info->is_lvalue = false;


                        if(fn_entry->lexval!="range" && fn_entry->lexval!="len")
                        {
                            int size = 0;
                            tac.push_back(quad("save registers", "", "", "", RETURN_STMT));
                            if($2->child.size()!=2)
                            {
                                string st;
                                for(int i=(($2->child[1]->child.size()-1)/2)*2;i>=0;i-=2)
                                {
                                    st =$2->child[1]->child[i]->info->type;
                                    int idx=i/2;
                                    convert(st, fn_entry->type[idx], $2->child[1]->child[i]->rvalue);
                                    tac.push_back(quad("param", $2->child[1]->child[i]->rvalue, "", "", PUSHPARAM));
                                    size+=resolve_width(st);
                                }

                            }

                            string func_fullname = fn_entry->lexval;
                            if($1->info->type[1]=='@')
                            {
                                func_fullname = fn_entry->container_st->my_st_entry->lexval+"."+func_fullname;
                                tac.push_back(quad("param", $1->rvalue, "", "", PUSHPARAM));
                                size+=8;
                            }
                            int add=(fn_entry->return_type=="None")?0:8;
                            size+=add;
                            if(size)
                                tac.push_back(quad("stackpointer", "-"+to_string(size), "","", STACK_MANIPULATION));
                            if(func_fullname=="print")
                                tac.push_back(quad("call", func_fullname+"_"+fn_entry->type[0], to_string(fn_entry->type.size()), "", FUNCCALL));
                            else
                                tac.push_back(quad("call", func_fullname, to_string(fn_entry->type.size()), "", FUNCCALL));
                            if(fn_entry->return_type!="None")
                            {
                                string new_temp=new_temporary();
                                tac.push_back(quad("=","return_value","",new_temp,NAME_ASSIGNMENT));
                                $$->rvalue = new_temp;
                            }
                            else{
                                $$->rvalue = "";
                            }
                            if(size)
                                tac.push_back(quad("stackpointer", "+"+to_string(size), "","", STACK_MANIPULATION));
                            tac.push_back(quad("restore registers", "", "", "", RETURN_STMT));
                        }
                        if(fn_entry->lexval=="len")
                        {

                            string new_temp=new_temporary();
                            tac.push_back(quad("=", $2->child[1]->child[0]->rvalue, "",new_temp, LOAD ));
                            $$->rvalue=new_temp;
                        }


                    }

                    else if($1->info->type[0]=='$')
                    {

                        if($2->info->trailer_type!=0)
                        {
                            error("Incorrect object initialization.",$1->lineno);
                        }
                        SymbolTableEntry* class_entry = st_stack->lookup($1->info->type.substr(1));

                        if(!class_entry){
                            error("No such class exists",$1->lineno);
                        }
                        vector<string> temp = {$1->info->type.substr(1)};
                        for(auto it : $2->info->args) temp.push_back(it);
                        vector<string> temp_min = {$1->info->type.substr(1)};
                        for(auto it: $2->info->args_min) temp_min.push_back(it);
                        SymbolTableEntry* init_entry = class_entry->local_st->is_present("__init__", temp, temp_min);
                        if(!init_entry){
                            error("No matching constructor found for class",$1->lineno);
                        }
                        temp_info->type = $1->info->type.substr(1);
                        temp_info->type_min = $1->info->type.substr(1);
                        temp_info->is_lvalue = false;

                        int size = 8;
                        string new_temp=new_temporary();
                        tac.push_back(quad("=",to_string(class_entry->local_st->offset),"",new_temp,NAME_ASSIGNMENT));
                        tac.push_back(quad("save registers", "", "", "", RETURN_STMT));
                        tac.push_back(quad("param", new_temp, "", "", PUSHPARAM));
                        if(size)
                            tac.push_back(quad("stackpointer", "-"+to_string(size+8), "","", STACK_MANIPULATION));
                        tac.push_back(quad("call", "allocmem", "1", "", FUNCCALL));
                        tac.push_back(quad("=","return_value","",new_temp,NAME_ASSIGNMENT));
                        if(size)
                            tac.push_back(quad("stackpointer", "+"+to_string(size+8), "","", STACK_MANIPULATION));
                        tac.push_back(quad("restore registers", "", "", "", RETURN_STMT));


                        tac.push_back(quad("save registers", "", "", "", RETURN_STMT));
                        if($2->child.size()!=2)
                        {
                            string st;
                            for(int i=(($2->child[1]->child.size()-1)/2)*2;i>=0;i-=2)
                            {
                                st =$2->child[1]->child[i]->info->type;
                                int idx=i/2;
                                convert(st, init_entry->type[idx], $2->child[1]->child[i]->rvalue);
                                tac.push_back(quad("param", $2->child[1]->child[i]->rvalue, "", "", PUSHPARAM));
                                size+=resolve_width(st);
                            }
                            
                        }
                        tac.push_back(quad("param", new_temp, "", "", PUSHPARAM));
                        if(size)
                            tac.push_back(quad("stackpointer", "-"+to_string(size), "","", STACK_MANIPULATION));
                        tac.push_back(quad("call", class_entry->lexval+".__init__", to_string(init_entry->type.size()), "", FUNCCALL));
                        if(size)
                            tac.push_back(quad("stackpointer", "+"+to_string(size), "","", STACK_MANIPULATION));
                        tac.push_back(quad("restore registers", "", "", "", RETURN_STMT));
                        $$->rvalue = new_temp;
                    }
                    else if($1->info->type.size()>=6 && $1->info->type.substr(0, 5)=="list[" && $1->info->type.back()==']')
                    {
                        if($2->info->trailer_type!=1)
                        {
                            error("Invalid operation on list type.",$1->lineno);
                        }
                        if($2->info->type != "int"){
                            error("Array index must be integer",$1->lineno);
                        }
                        temp_info->type=$1->info->type.substr(5, $1->info->type.size()-6);
                        temp_info->type_min=$1->info->type.substr(5, $1->info->type.size()-6);
                        temp_info->is_lvalue = $1->info->is_lvalue;

                            string offset=new_temporary();
                            string value=new_temporary();
                            int size=resolve_width(temp_info->type);
                            tac.push_back(quad("*", to_string(size), $2->child[1]->rvalue, offset, ARITH));
                            tac.push_back(quad("+", $1->rvalue, offset, offset, ARITH));
                            tac.push_back(quad("+", "8", offset, offset, ARITH));   // for size
                            tac.push_back(quad("=", offset,"" ,value, LOAD));
                            $$->rvalue=value;
                            $$->lvalue=offset;
                            
                    }
                    else
                    {
                        string st=$1->info->type;
                        
                        if(st=="int" || st=="float" || st=="bool" || st=="None")
                        {
                            error("Operation not allowed on basic types." ,$1->lineno);
                        }
                        if(st=="str")
                        {
                                error("Operation not allowed on strings",$1->lineno);
                        }
                        else
                        {
                            if($2->info->trailer_type==0)
                            {
                                
                                error("Method call not allowed on object",$1->lineno);
                            }
                            if($2->info->trailer_type==1)
                            {
                                
                                error("Array access not allowed on object",$1->lineno);
                            }

                            SymbolTableEntry* class_entry=st_stack->lookup(st);
                            SymbolTableEntry* temp_st_entry=class_entry->local_st->inherit_tree_lookup($2->info->type.substr(1));

                            vector<SymbolTableEntry*> candidates;

                            if(temp_st_entry==NULL)
                            {
                                candidates={};
                            }
                            else
                            {
                                if(temp_st_entry->entry_type==FUNC_DEF)
                                {

                                    candidates={temp_st_entry};
                                    
                                }
                                else
                                {
                                    if(class_entry->local_st->is_present($2->info->type.substr(1)))
                                    {
                                        candidates={class_entry->local_st->is_present($2->info->type.substr(1))};
                                    }
                                    else
                                    {
                                        candidates={};
                                    }
                                }
                            }
                            if(candidates.size()==0)
                            {
                                if($1->name=="NAME" && $1->lexval=="self" && st_stack->tables.size()>=2 && st_stack->tables[st_stack->tables.size()-2]->type==CLASS_ST && st_stack->tables[st_stack->tables.size()-1]->type==FUNCTION_ST && st_stack->tables[st_stack->tables.size()-1]->my_st_entry->lexval=="__init__")
                                {
                                    temp_info->type="!";
                                    temp_info->is_lvalue = $1->info->is_lvalue;
                                    string offset=new_temporary();
                                    int size=resolve_width(temp_info->type);
                                    tac.push_back(quad("=", $1->rvalue,"" ,offset, NAME_ASSIGNMENT));
                                    if(temp_st_entry != NULL){
                                        tac.push_back(quad("+", to_string(temp_st_entry->offset), offset, offset, ARITH));
                                    }
                                    else {
                                        tac.push_back(quad("+", to_string(st_stack->tables[st_stack->tables.size()-2]->offset), offset, offset, ARITH));
                                    }
                                    $$->lvalue=offset;
                                }
                                else
                                    error("Method/member not present in class.",$1->lineno);
                            }
                            else
                            {
                                if(candidates[0]->entry_type==OBJ)
                                {
                                    temp_info->type=candidates[0]->type[0];
                                    temp_info->type_min=candidates[0]->type[0];
                                    temp_info->is_lvalue = $1->info->is_lvalue;

                                    string offset=new_temporary();
                                    string value=new_temporary();
                                    int size=resolve_width(temp_info->type);
                                    tac.push_back(quad("=", $1->rvalue,"" ,offset, NAME_ASSIGNMENT));
                                    tac.push_back(quad("+", to_string(candidates[0]->offset), offset, offset, ARITH));
                                    tac.push_back(quad("=", offset,"" ,value, LOAD));
                                    $$->rvalue=value;
                                    $$->lvalue=offset;
                                }
                                else
                                {
                                    temp_info->type="@@"+class_entry->lexval;
                                    temp_info->candidates=candidates;
                                    temp_info->is_lvalue = false;

                                    $$->rvalue=$1->rvalue;
                                }
                            }
                            
                        }
                    }
                }
                else
                {
                    temp_info->type="!";
                    temp_info->is_lvalue=false;
                }

                $$->info=temp_info;

}



atom    : LEFT_PAREN  test RIGHT_PAREN {


                        $$=$2;






}
        | LEFT_BRACKET testlist_comp_or_not RIGHT_BRACKET {


                        $$ = new Node(nodeID++, "atom", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->info = new temp_type_info();

                        if(!$2)
                        {
                            error("Empty lists are not allowed",$1->lineno);
                        }
                        if($2->info->type[0]=='!')
                        {
                            error("Variable not declared before use",$1->lineno);
                        }
                        $$->info->type = "list[" + $2->info->type + "]";
                        $$->info->type_min = "list[" + $2->info->type_min + "]";

                        $$->info->is_lvalue=false; 

                        int size=resolve_width($2->child[0]->info->type)*((1+$2->child.size())/2);
                        size += 8; 
                        string new_temp=new_temporary();
                        tac.push_back(quad("=",to_string(size),"",new_temp,NAME_ASSIGNMENT));
                        tac.push_back(quad("save registers", "", "", "", RETURN_STMT));
                        tac.push_back(quad("param", new_temp, "", "", PUSHPARAM));
                        tac.push_back(quad("stackpointer", "-16", "","", STACK_MANIPULATION));
                        tac.push_back(quad("call", "allocmem", "1", "", FUNCCALL));
                        tac.push_back(quad("=","return_value","",new_temp,NAME_ASSIGNMENT));
                        $$->rvalue=new_temp;
                        tac.push_back(quad("stackpointer", "+16", "","", STACK_MANIPULATION));
                        tac.push_back(quad("restore registers", "", "", "", RETURN_STMT));
                        string offset=new_temporary();
                        tac.push_back(quad("=", new_temp,"",offset, NAME_ASSIGNMENT));
                        tac.push_back(quad("=", to_string(((1+$2->child.size())/2)),"" ,offset, STORE));

                        for(int i=0;i<$2->child.size();i+=2)
                        {
                            tac.push_back(quad("+", to_string(resolve_width($2->child[0]->info->type)), offset, offset, ARITH));
                            if(curr_list_core_type.size())
                                convert($2->child[i]->info->type, curr_list_core_type, $2->child[i]->rvalue);
                            tac.push_back(quad("=", $2->child[i]->rvalue,"" ,offset, STORE));
                        }



}
        | NAME {

                            $$=$1;

                            if($1->lexval=="float" || $1->lexval=="int" ||$1->lexval=="str" || $1->lexval=="bool" || $1->lexval=="list")
                            {
                                if(!inside_type_hint)
                                {
                                    error("Invalid use of type names",$1->lineno);
                                }
                                $1->info=new temp_type_info();
                                $1->info->is_lvalue=false; 
                                $1->info->type="!";
                                
                            }
                            else
                            {

                                
                                    SymbolTableEntry* temp=st_stack->lookup($1->lexval);
                                    $1->info=new temp_type_info();
                                    if(temp==NULL)
                                    {
                                        $1->info->type="!";
                                        $1->info->is_lvalue=true; 
                                    }
                                    else if(temp->entry_type==FUNC_DEF)
                                    {
                                        $1->info->type="@"+temp->lexval;
                                        if(temp->lexval=="print" || temp->lexval=="len" || temp->lexval=="range")
                                        {
                                            $1->info->candidates=st_stack->tables[0]->entries[temp->lexval];
                                        }
                                        else{
                                            $1->info->candidates={temp};
                                        }
                                        $1->info->is_lvalue=false; 
                                    }
                                    else if(temp->entry_type==OBJ)
                                    {

                                        $1->info->type=temp->type[0];
                                        $1->info->type_min=temp->type[0];
                                        $1->info->is_lvalue=true; 
                                    
                                        $$->lvalue=$1->lexval;
                                        string new_temp=new_temporary();
                                        tac.push_back(quad("=", $1->lexval,"" ,new_temp, NAME_ASSIGNMENT));
                                        $$->rvalue=new_temp;
                                    }
                                    else if(temp->entry_type==CLASS_DEF)
                                    {
                                        $1->info->type="$"+temp->lexval;
                                        $1->info->is_lvalue=false; 
                                    }

                            }



}
        | INTEGER  {
                    $$=$1;
                    $1->info=new temp_type_info();
                    $1->info->type="int";
                    $1->info->type_min="int";
                    $1->info->is_lvalue=false;

                    string new_temp=new_temporary();
                    tac.push_back(quad("=", $1->lexval,"" ,new_temp, NAME_ASSIGNMENT));
                    $$->rvalue=new_temp;

        }
        | FLOAT_NUMBER  {
                    $$=$1;
                    $1->info=new temp_type_info();
                    $1->info->type="float";
                    $1->info->type_min="float";
                    $1->info->is_lvalue=false; 

                    string new_temp=new_temporary();
                    tac.push_back(quad("=", $1->lexval,"" ,new_temp, NAME_ASSIGNMENT));
                    $$->rvalue=new_temp;
        }
        | IMAGINARY_NO  {
                    $$=$1;
                    $1->info=new temp_type_info();
                    $1->info->type="?";
                    $1->info->type_min="?";
                    error("Imaginary type not supported",$1->lineno);
                    $1->info->is_lvalue=false; 

        }
        | STRING_plus {
                    $$=$1;
                    $1->info=new temp_type_info();
                    $1->info->type="str";
                    $1->info->type_min="str";
                    $1->info->is_lvalue=false; 

                    string new_temp=new_temporary();
                    tac.push_back(quad("=", "\""+$1->lexval+"\"","" ,new_temp, NAME_ASSIGNMENT));
                    $$->rvalue=new_temp;


        }
        | NONE {
                    $$=$1;
                    $1->info=new temp_type_info();
                    $1->info->type="None";        
                    $1->info->type_min="None";        
                    $1->info->is_lvalue=false; 
        }
        | TRUE {$$=$1;
        
                    $1->info=new temp_type_info();
                    $1->info->type="bool";
                    $1->info->type_min="bool";
                    $1->info->is_lvalue=false; 

                    string new_temp=new_temporary();
                    tac.push_back(quad("=", "1","" ,new_temp, NAME_ASSIGNMENT));
                    $$->rvalue=new_temp;
        }
        | FALSE {$$=$1;
        
                    $1->info=new temp_type_info();
                    $1->info->type="bool";        
                    $1->info->type_min="bool";       
                    $1->info->is_lvalue=false; 

                    string new_temp=new_temporary();
                    tac.push_back(quad("=", "0","" ,new_temp, NAME_ASSIGNMENT));
                    $$->rvalue=new_temp;
        }

STRING_plus : STRING_plus STRING_LITERAL  {


                    $1->lexval+=$2->lexval;
                    $$=$1;
}
            | STRING_LITERAL {
                    $$ = $1;
}

testlist_comp   : 
                test_or_star_expr COMMA_test_or_star_expr_kleene COMMA_or_not {


                        $$ = new Node(nodeID++, "testlist_comp", yylineno);
                        $$->push_back($1);
                        if($2)
                        {
                            for(auto child: $2->child)
                            {
                                $$->push_back(child);
                            }
                        }
                        $$->push_back($3);

                        if($1->info->type[0]=='!')
                        {
                            error("Variable not declared before use",$1->lineno);
                        }


                        if($2 && !same_type_kind($1->info->type, $2->info->type)) 
                            error("Type mismatch in list",$1->lineno);


                        $$->info = new temp_type_info();
                        if($2!=NULL)
                        {

                            $$->info->type = max_type($1->info->type,$2->info->type);
                            $$->info->type_min = min_type($1->info->type_min,$2->info->type_min);
                        }
                        else
                        {
                            $$->info->type=$1->info->type;
                            $$->info->type_min=$1->info->type_min;
                        }

                    
}

COMMA_test_or_star_expr_kleene  : COMMA_test_or_star_expr_kleene COMMA test_or_star_expr {

                    if($1==NULL)
                    {
                        $1=new Node(nodeID++, "COMMA_test_or_star_exprs", yylineno);
                        $1->info = new temp_type_info();
                        $1->info->type = $3->info->type;
                        $1->info->type_min = $3->info->type_min;

                        if($3->info->type[0]=='!')
                        {
                            error("Variable not declared before use",$1->lineno);
                        }
                    }
                    else
                    {
                        if($3->info->type[0]=='!')
                        {
                            error("Variable not declared before use",$1->lineno);
                        }
                        if(!same_type_kind($1->info->type , $3->info->type))
                            error("Type mismatch in list",$1->lineno);

                        $1->info->type = max_type($1->info->type,$3->info->type);
                        $1->info->type_min = min_type($1->info->type_min,$3->info->type_min);
                    }


                    $1->push_back($2);
                    $1->push_back($3);
                    
                    $$ = $1;


                    
}
                                | %empty {

                    $$=NULL;
}

testlist_comp_or_not    : testlist_comp {
                                $$ = $1;

}
                        | %empty {
                                $$ = NULL;

}

trailer : LEFT_PAREN arglist_or_not RIGHT_PAREN  {
                        $$ = new Node(nodeID++, "trailer", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);

                        $$->info=new temp_type_info();
                        if($2!=NULL && $2->info!=NULL)
                        {
                            $$->info->args=$2->info->args;
                            $$->info->args_min=$2->info->args_min;
                        }
                        $$->info->trailer_type=0;

}
        | LEFT_BRACKET subscript RIGHT_BRACKET  {


                        $$ = new Node(nodeID++, "trailer", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);

                        if(!inside_type_hint)
                        {

                            $$->info = new temp_type_info();
                            $$->info->type = $2->info->type;
                            $$->info->type_min = $2->info->type_min;
                            $$->info->trailer_type = 1;

                            if($2->info->type[0]=='!')
                            {
                                error("Variable not declared before use",$1->lineno);
                            }
                        }

}
        | PERIOD NAME {

            $$ =new Node(nodeID++, "trailer", yylineno);
            $$->push_back($1);
            $$->push_back($2);

            $$->info = new temp_type_info();
            $$->info->type = "."+$2->lexval;
            $$->info->trailer_type = 2;

            
}



subscript   : test {$$=$1;


}


exprlist    : expr_or_star_expr  {

                $$ = $1;

}


expr_or_star_expr   : expr {$$=$1;}

testlist    : test  {

    
                    $$=$1;



}



classdef    : CLASS NAME {

                    SymbolTable* new_st=st_stack->add_table(CLASS_ST);
                    SymbolTableEntry* prev_entry=curr_st->is_present($2->lexval);
                    if(prev_entry!=NULL)
                    {
                        error("Name already used at line no: "+to_string(prev_entry->line_no),$1->lineno);
                    }
                    SymbolTableEntry* new_st_entry=new SymbolTableEntry(CLASS_DEF, {"class"}, $2->lexval, 0, $1->lineno, -1, curr_st, new_st);
                    new_st->my_st_entry=new_st_entry;
                    curr_st=new_st;

} 
LEFT_PAREN_arglist_or_not_RIGHT_PAREN_or_not COLON {

                    if(st_stack->tables.size()<2)
                    {
                        error("Something is wrong...",$1->lineno);
                    }
                    if(curr_st->parent_class_st)
                        curr_st->offset = curr_st->parent_class_st->offset;
                    st_stack->tables[st_stack->tables.size()-2]->insert(curr_st->my_st_entry);
}
suite {

                        
                        $$ = new Node(nodeID++, "classdef", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($4);
                        $$->push_back($5);
                        $$->push_back($7);
                        


                        print_st_vec.push_back(curr_st);
                        curr_st=st_stack->pop_table();
                        
                        
}

LEFT_PAREN_arglist_or_not_RIGHT_PAREN_or_not    : LEFT_PAREN arglist_or_not RIGHT_PAREN {



                        $$ = new Node(nodeID++, "optional_arglist", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        if($2==NULL || $2->info==NULL);
                        else if($2->info->args.size()>1)
                        {
                            error("Multiple inheritance not supported.",$1->lineno);
                        }
                        else if($2->info->args.size()==1)
                        {
                            if($2->info->args[0][0]!='$')
                            {
                                error("Improper arguments in inheritance.",$1->lineno);
                            }
                            SymbolTableEntry* class_lookup=st_stack->lookup($2->info->args[0].substr(1));

                            if(class_lookup==NULL)
                            {
                                error("Parent class not defined.",$1->lineno);
                            }
                            curr_st->parent_class_st=class_lookup->local_st;
                        }
}
                        | %empty {
                            $$=NULL;} 

arglist_or_not  : arglist  {$$=$1;



            if($1->info->type[0]=='!')
            {
                error("Variable not declared before use",$1->lineno);
            }
}
                |  %empty {$$=NULL;}

arglist : argument COMMA_argument_kleene COMMA_or_not {
                $$ = new Node(nodeID++, "arglist", yylineno);
                $$->push_back($1);
                
                if($2)
                {
                    for(auto child: $2->child)
                    {
                        $$->push_back(child);
                    }
                }
                $$->push_back($3);

                if($1->info->type[0]=='!')
                {
                    error("Identifier not declared before use",$1->lineno);
                }


                int cnt=0;
                $$->info=new temp_type_info();

                for(auto child: $$->child)
                {
                    if(cnt%2==0)
                    {
                        $$->info->args.push_back(child->info->type);
                        $$->info->args_min.push_back(child->info->type_min);
                    }
                    cnt++;
                }
}

COMMA_argument_kleene   : COMMA_argument_kleene COMMA argument {
                
                if($1 == NULL){
                    $1=new Node(nodeID++, "arguments", yylineno);
                }
                $1->push_back($2);
                $1->push_back($3);
                
                $$ = $1;


                if($3->info->type[0]=='!')
                {
                    error("Identifier not declared before use",$1->lineno);
                }
}
                        | %empty  {
                            $$ = NULL;
}


argument    : test  {

                $$=$1;


}



%%

void create_edges(ofstream &fout, Node* curr_node)
{
    for(auto child: curr_node->child)
    {
        if(child)
        {
            fout<<"node"<<curr_node->id<<" -> node"<<child->id<<";\n";
            create_edges(fout, child);
        }
    }
}

void create_nodes(ofstream &fout, Node *curr_node){

    if(!curr_node){
        return;
    }
    if(curr_node->lexval=="")
        fout<<"node"<<curr_node->id<<" [label= \""<<curr_node->title<<"\"]\n";
    else if(curr_node->title!="STRING_LITERAL")
        fout<<"node"<<curr_node->id<<" [label= \""<<curr_node->title<<"("<<curr_node->lexval<<")"<<"\", shape = rectangle, color = "<< color[curr_node->title]<<"]\n";
    else
    {
        string temp;
        for(int i=0;i<curr_node->lexval.size();i++)
        {
            char c=curr_node->lexval[i];
            if(c=='\'' || c=='\"' || c==';' || c==':' || c=='}' || c=='{' || c=='<' || c=='>')
            {
                temp+="\\";
            }
            temp+=c;
        }
        fout<<"node"<<curr_node->id<<" [label= \""<<curr_node->title<<"("<<temp<<")"<<"\", shape = rectangle, color = "<< color[curr_node->title]<<"]\n";
    }
    for(auto &child: curr_node->child){
        if(child) create_nodes(fout, child);
    }
}

void print_help(){
    cout <<"Usage:\n";
    cout<<"-help : prints this help message"<<endl;
    cout<<"-input <filename> : specifies the input test file to be used for compilation"<<endl;
    cout<<"-output <filename>: specifies output file to store the Three Address Code "<<endl;
    cout<<"-verbose : enables debug messages for the parsing process"<<endl;
}

int main(int argc, char *argv[])
{
    st_stack=new SymbolTableStack();
    curr_st=st_stack->add_table(GLOBAL_ST);

    print_st_vec.push_back(curr_st);

    SymbolTableEntry *print_int = new SymbolTableEntry(FUNC_DEF, {"int"}, "print", 8, 0, curr_st->offset, curr_st, NULL);
    SymbolTableEntry *print_str = new SymbolTableEntry(FUNC_DEF, {"str"}, "print", 8, 0, curr_st->offset, curr_st, NULL);
    SymbolTableEntry *print_bool = new SymbolTableEntry(FUNC_DEF, {"bool"}, "print", 8, 0, curr_st->offset, curr_st, NULL);
    SymbolTableEntry *print_float = new SymbolTableEntry(FUNC_DEF, {"float"}, "print", 8, 0, curr_st->offset, curr_st, NULL);
    print_bool->return_type = "None";
    print_int->return_type = "None";
    print_float->return_type = "None";
    print_str->return_type = "None";
    
    SymbolTableEntry *len = new SymbolTableEntry(FUNC_DEF, {""}, "len", 8, 0, curr_st->offset, curr_st, NULL);
    len->return_type="int";
    SymbolTableEntry *range_single = new SymbolTableEntry(FUNC_DEF, {"int"}, "range", 8, 0, curr_st->offset, curr_st, NULL);
    SymbolTableEntry *range_double = new SymbolTableEntry(FUNC_DEF, {"int", "int"}, "range", 16, 0, curr_st->offset, curr_st, NULL);
    range_single->return_type="range!";
    range_double->return_type="range!!";
    SymbolTableEntry *dunder_name = new SymbolTableEntry(OBJ, {"str"}, "__name__", 8, 0, curr_st->offset, curr_st, NULL);
    curr_st->offset += 8;
    
    curr_st->insert(print_int);
    curr_st->insert(range_double);
    curr_st->insert(range_single);
    curr_st->insert(len);
    curr_st->insert(print_str);
    curr_st->insert(print_bool);
    curr_st->insert(print_float);
    curr_st->insert(dunder_name);
    

    string output_filename = "tac.txt";
    FILE* input_file = stdin;

    for(int i=1;i<argc;i++)
    {
        if((string)argv[i]=="-help")
        {
            print_help();
            return 0;
        }
        else if((string)argv[i]=="-output")
        {
            if(i+1>=argc)
            {
                cerr<<"Error: Invalid parameters - output file missing"<<endl;
                return -1;
            }
            output_filename=argv[i+1];
            i++;
        }
        else if((string)argv[i]=="-input")
        {
            if(i+1 >= argc){
                cerr<<"Error: Invalid parameters - input file missing\n";
                return -1;
            }
            input_file = fopen(argv[i+1], "r");
            if (!input_file) {
                perror("Error: Unable to open input file\n");
                return -1;
            }
            yyin = input_file;
            i++;
        }
        else if((string)argv[i]=="-verbose"){
            yydebug = 1;
        }
        else
        {
            cerr<<"Error: Invalid options"<<endl;
            print_help();
            return -1;
        }
    }
    yyparse();

    print_tac(output_filename);

    print_st(print_st_vec);
    return 0;
}

void yyerror(string s)
{
    cerr<<"Error at line number "<<yylineno<<": "<<s<<endl;
    exit(0);
}