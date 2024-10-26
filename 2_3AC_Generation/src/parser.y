%{
    #include "node/node.h"
    using namespace std;
    extern FILE* yyin;
    extern int yydebug;
    extern int yylex();
    extern void yyerror(string s);
    extern int yylineno;
    int nodeID{1};
    Node* root_node;
    map<string, string> color = {{"OPERATOR", "purple"}, {"KEYWORD", "green"}, {"DELIMITER", "blue"}, {"IDENTIFIER", "red"} , {"NUMBER", "pink"}, {"STRING_LITERAL", "orange"}, {"DATA TYPE", "cyan"}};
%}

%define parse.trace
%define parse.error verbose

%union {
    Node *node;
}


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


funcdef : DEF NAME parameters ARROW_test_or_not COLON suite {
                $$ = new Node(nodeID++,"funcdef", yylineno);
                $$->push_back($1);
                $$->push_back($2);
                $$->push_back($3);
                $$->push_back($4);
                $$->push_back($5);
                $$->push_back($6);
}

ARROW_test_or_not   : ARROW test {

                        $$ = new Node(nodeID++, "return_type_hint", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
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

typedargslist   : tfpdef EQUAL_test_or_not COMMA_tfpdef_EQUAL_test_or_not_kleene COMMA  {
                    
                    if($1==NULL && $2==NULL && $3==NULL) $$=$4;
                    else
                    {
                        $$ = new Node(nodeID++,"typedargslist", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        if($3)
                        {
                            for(auto child: $3->child)
                            {
                                $$->push_back(child);
                            }
                        }
                        $$->push_back($4);
                    }

}
                | tfpdef EQUAL_test_or_not COMMA_tfpdef_EQUAL_test_or_not_kleene    {

                if($1==NULL && $2==NULL) $$=$3;
                if($1==NULL && $3==NULL) $$=$2;
                if($2==NULL && $3==NULL) $$=$1;
                else
                {
                    $$ = new Node(nodeID++, "typedargslist", yylineno);
                    $$->push_back($1);
                    $$->push_back($2);
                    if($3)
                    {
                        for(auto child: $3->child)
                        {
                            $$->push_back(child);
                        }
                    }
                }

}

tfpdef  : NAME COLON_test_or_not {

                    $$ = new Node(nodeID++, "formal_param", yylineno);
                    $$->push_back($1);
                    $$->push_back($2);
}

COMMA_tfpdef_EQUAL_test_or_not_kleene   : COMMA_tfpdef_EQUAL_test_or_not_kleene COMMA tfpdef EQUAL_test_or_not {

                                        if($1==NULL)
                                        {
                                            $1=new Node(nodeID++, "formal_params", yylineno);
                                        }
                                        $1->push_back($2);
                                        $1->push_back($3);
                                        $1->push_back($4);
                                        $$ = $1;
}
                                        | %empty    {

                                        $$=NULL;

}



COLON_test_or_not   : COLON test {

                        $$ = new Node(nodeID++, "param_type_hint", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
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
            | nonlocal_stmt {$$=$1;}
            | assert_stmt {$$=$1;}

expr_stmt   : testlist_star_expr annassign {

                        if($1==NULL) $$=$2;
                        else if($2==NULL) $$=$1;
                        else
                        {
                            $2->push_front($1);
                            $$=$2;
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
}
            | testlist_star_expr EQUAL_testlist_star_expr_kleene {


                        if($1==NULL) $$=$2;
                        else if($2==NULL) $$=$1;
                        else
                        {
                            $2->push_front($1);
                            $$=$2;
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
}
                                |  %empty   {
                                    $$=NULL;
}

annassign   : COLON test EQUAL_test_or_not  {

                        $$ = new Node(nodeID++, "annassign", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
}



SEMICOLON_or_not    : SEMICOLON {$$=$1;}
                    |  %empty  {$$=NULL;}

testlist_star_expr  : test_or_star_expr COMMA_test_or_star_expr_kleene COMMA_or_not  {

                if($1==NULL && $2==NULL) $$=$3;
                else if($1==NULL && $3==NULL) $$=$2;
                else if($2==NULL && $3==NULL) $$=$1;
                else
                {
                        $$ = new Node(nodeID++, "testlist_star_expr", yylineno );
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
}

test_or_star_expr   : test {$$=$1;}
                    | star_expr {$$=$1;}

augassign   : PLUS_EQUAL {$$=$1;}
            | MINUS_EQUAL {$$=$1;}
            | MULTIPLY_EQUAL {$$=$1;}
            | RATE_EQUAL {$$=$1;}
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

break_stmt  : BREAK {$$=$1;}

continue_stmt   : CONTINUE {$$=$1;}

return_stmt : RETURN testlist_or_not {

                        $$ = new Node(nodeID++, "return_stmt", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);

}

testlist_or_not : testlist {$$=$1;}
                | %empty {$$=NULL;}


global_stmt : GLOBAL NAME {

                        $$ = new Node(nodeID++, "global_stmt", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
}
            | global_stmt COMMA NAME  {
                        $1->push_back($2);
                        $1->push_back($3);

                        $$=$1;
            }

nonlocal_stmt   : NONLOCAL NAME {

                        $$ = new Node(nodeID++, "nonlocal_stmt", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
}

                | nonlocal_stmt COMMA NAME {

                        $1->push_back($2);
                        $1->push_back($3);

                        $$=$1;
                }

assert_stmt : ASSERT test COMMA_test_or_not {
    
                        $$ = new Node(nodeID++,"assert_stmt",yylineno );

                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
}


COMMA_test_or_not   : COMMA test {
    
                        $$ = new Node(nodeID++, "COMMA_test", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
}
                    |  %empty {$$=NULL;}

compound_stmt   : if_stmt  {$$=$1;}
                | while_stmt {$$=$1;}
                | for_stmt {$$=$1;}
                | funcdef {$$=$1;}
                | classdef {$$=$1;}

if_stmt : IF test COLON suite ELIF_test_COLON_suite_kleene ELSE_COLON_suite_or_not {

    
                        $$ = new Node(nodeID++, "if_stmt", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($4);
                        if($5)
                        {
                            for(auto child: $5->child)
                            {
                                $$->push_back(child);
                            }
                        }
                        $$->push_back($6);

}

ELIF_test_COLON_suite_kleene    : ELIF_test_COLON_suite_kleene ELIF test COLON suite {

                                if($1==NULL)
                                {
                                    $1=new Node(nodeID++, "ELIF_blocks", yylineno);
                                }
                                $1->push_back($2);
                                $1->push_back($3);
                                $1->push_back($4);
                                $1->push_back($5);

                                $$=$1;
    
}
                                | %empty {
                                $$=NULL;

}

while_stmt  : WHILE test COLON suite ELSE_COLON_suite_or_not {
    
                        $$ = new Node(nodeID++, "while_stmt", yylineno);

                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($4);
                        $$->push_back($5);
}

for_stmt    : FOR exprlist IN testlist COLON suite ELSE_COLON_suite_or_not  {

                        $$ = new Node(nodeID++, "for_stmt", yylineno);

                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($4);
                        $$->push_back($5);
                        $$->push_back($6);
                        $$->push_back($7);
}

ELSE_COLON_suite_or_not : ELSE COLON suite {
    
                        $$ = new Node(nodeID++, "ELSE_block", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
}
                        | %empty  {$$=NULL;}


suite   : simple_stmt   {$$=$1;}
        | NEWLINE INDENT stmt_plus DEDENT  {
            
            $$=$3;                               
}

stmt_plus   : stmt_plus stmt {

                if($1==NULL || $1->title!="stmts")
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

test    : or_test IF_or_test_ELSE_test_or_not  {
    
    if($1==NULL) $$=$2;
    else if($2==NULL) $$=$1;
    else
    {

        $$ = new Node(nodeID++, "test", yylineno);
        $$->push_back($1);
        $$->push_back($2);
    }
}

IF_or_test_ELSE_test_or_not : IF or_test ELSE test  {


                        $$ = new Node(nodeID++, "inline_IF_ELSE", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($4);
}
                            | %empty  {$$=NULL;}

test_nocond : or_test {$$=$1;}

or_test : and_test  {                            
    
                $$ = $1;
}
        | or_test OR and_test  {


                $2->push_back($1);
                $2->push_back($3);
                $$=$2;
}

and_test    : not_test {                           
    
                $$ = $1;
}

            | and_test AND not_test {

                $2->push_back($1);
                $2->push_back($3);
                $$=$2;
}

not_test    : NOT not_test {
                $1->push_back($2);
                $$=$1;
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
}



comp_op : LESS_THAN { $$=$1;}
        | GREATER_THAN { $$=$1;}
        | EQUAL_EQUAL { $$=$1;} 
        | GREATER_THAN_EQUAL  { $$=$1;}
        | LESS_THAN_EQUAL { $$=$1;}
        | NOT_EQUAL { $$=$1;}
        | IN { $$=$1;}
        | NOT IN { $$=$1;}
        | IS  { $$=$1;}
        | IS NOT { $$=$1;}

star_expr   : MULTIPLY expr {                            
        $$ = new Node(nodeID++, "star_expr", yylineno);
        $$->push_back($1);
        $$->push_back($2);
}

expr    : xor_expr {                            
                $$ = $1;
}
        | expr BITWISE_OR xor_expr {

                $$=$2;
                $$->push_back($1);
                $$->push_back($3);
}


xor_expr    : and_expr {  
                $$=$1;                          
} 
            | xor_expr BITWISE_XOR and_expr {
                $$=$2;
                $$->push_back($1);
                $$->push_back($3);
}

and_expr    : shift_expr {                            
                $$ = $1;
}
            | and_expr BITWISE_AND shift_expr {
                $$=$2;
                $$->push_back($1);
                $$->push_back($3);
}

shift_expr  : arith_expr {                            
                $$ = $1;
}
            | shift_expr LEFT_SHIFT_or_RIGHT_SIHFT arith_expr 
            {
                $$=$2;
                $$->push_back($1);
                $$->push_back($3);
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

}

MULTIPLY_or_RATE_or_DIVIDE_or_REMAINDER_or_INTEGER_DIVIDE   : MULTIPLY          {$$ = $1;}    
                                                            | RATE              {$$ = $1;}
                                                            | DIVIDE            {$$ = $1;}    
                                                            | REMAINDER         {$$ = $1;}        
                                                            | INTEGER_DIVIDE    {$$ = $1;}            

factor  : PLUS_or_MINUS_or_BITWISE_NOT factor {
                $$=$1;
                $$->push_back($2);
}
        | power {                           
            $$ = $1;
}

PLUS_or_MINUS_or_BITWISE_NOT    : PLUS          {$$ = $1;}
                                | MINUS         {$$ = $1;}
                                | BITWISE_NOT   {$$ = $1;}

power   : atom_expr  POWER_factor_or_not    {

        if($2==NULL) $$=$1;
        else if($1==NULL) $$=$2;
        else
        {
            $$=$2;
            $$->push_front($1);
        }
}

POWER_factor_or_not     : POWER factor {
                $$=$1;
                $$->push_front($2);
}
                        | %empty    {
                            $$ = NULL;
}
 
atom_expr   : atom  {

        $$=$1;
}
            | atom_expr trailer     {

                if($1==NULL || $1->title!="atom_expr")
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
}


atom    : LEFT_PAREN  testlist_comp_or_not RIGHT_PAREN {


                        $$ = new Node(nodeID++, "atom", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
}
        | LEFT_BRACKET testlist_comp_or_not RIGHT_BRACKET {

                        $$ = new Node(nodeID++, "atom", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);


}
        | NAME {$$=$1;}
        | NUMBER  {$$=$1;}
        | STRING_plus {$$=$1;}
        | NONE {$$=$1;}
        | TRUE {$$=$1;}
        | FALSE {$$=$1;}

STRING_plus : STRING_plus STRING_LITERAL  {

                    if($1->title!="strings")
                    {
                        $$=new Node(nodeID++, "strings", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                    }
                    else
                    {
                        $1->push_back($2);
                        $$ = $1;
                    }
}
            | STRING_LITERAL {
                    $$ = $1;
}

testlist_comp   : test_or_star_expr comp_for {

                        $$ = new Node(nodeID++, "testlist_comp", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
}
                | test_or_star_expr COMMA_test_or_star_expr_kleene COMMA_or_not {

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

}

COMMA_test_or_star_expr_kleene  : COMMA_test_or_star_expr_kleene COMMA test_or_star_expr {

                    if($1==NULL)
                    {
                        $1=new Node(nodeID++, "COMMA_test_or_star_exprs", yylineno);
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
}
        | LEFT_BRACKET subscriptlist RIGHT_BRACKET  {

                        $$ = new Node(nodeID++, "trailer", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);

}
        | PERIOD NAME {
            $$ =new Node(nodeID++, "trailer", yylineno);
            $$->push_back($1);
            $$->push_back($2);
            
}

subscriptlist   : subscript COMMA_subscript_kleene COMMA_or_not {

                if($1==NULL && $2==NULL) $$=$3;
                else if($1==NULL && $3==NULL) $$=$2;
                else if($2==NULL && $3==NULL) $$=$1;
                else
                {
                        $$ = new Node(nodeID++, "subscriptlist", yylineno);
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
}

COMMA_subscript_kleene  : COMMA_subscript_kleene COMMA subscript {

                    if($1 == NULL){
                        $1=new Node(nodeID++, "subscripts", yylineno);
                    }
                    $1->push_back($2);
                    $1->push_back($3);
                    
                    $$ = $1;
}
                        | %empty {
                            $$ = NULL;
}

subscript   : test {$$=$1;}


exprlist    : expr_or_star_expr COMMA_expr_or_star_expr_kleene COMMA_or_not {

                if($1==NULL && $2==NULL) $$=$3;
                else if($1==NULL && $3==NULL) $$=$2;
                else if($2==NULL && $3==NULL) $$=$1;
                else
                {
                    $$ = new Node(nodeID++, "exprlist", yylineno);

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
}

COMMA_expr_or_star_expr_kleene  : COMMA_expr_or_star_expr_kleene COMMA expr_or_star_expr {

                    if($1 == NULL){
                        $1=new Node(nodeID++, "COMMA_expr_or_star_expr_kleene", yylineno);
                    }
                    $1->push_back($2);
                    $1->push_back($3);
                    
                    $$ = $1;
}
                                | %empty {
                        $$ = NULL;
}

expr_or_star_expr   : expr {$$=$1;}
                    | star_expr {$$=$1;}

testlist    : test COMMA_test_kleene COMMA_or_not {

                if($1==NULL && $2==NULL) $$=$3;
                else if($1==NULL && $3==NULL) $$=$2;
                else if($2==NULL && $3==NULL) $$=$1;
                else
                {
                        $$ = new Node(nodeID++, "testlist", yylineno);
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
}

COMMA_test_kleene   : COMMA_test_kleene COMMA test {
                    
                    if($1 == NULL){
                        $1=new Node(nodeID++, "tests", yylineno);
                    }
                    $1->push_back($2);
                    $1->push_back($3);
                    
                    $$ = $1;
}
                    | %empty {
                    $$ = NULL;

}


classdef    : CLASS NAME LEFT_PAREN_arglist_or_not_RIGHT_PAREN_or_not COLON suite {


                        $$ = new Node(nodeID++, "classdef", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($4);
                        $$->push_back($5);
                        
}

LEFT_PAREN_arglist_or_not_RIGHT_PAREN_or_not    : LEFT_PAREN arglist_or_not RIGHT_PAREN {


                        $$ = new Node(nodeID++, "optional_arglist", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        
}
                        | %empty {$$=NULL;} 

arglist_or_not  : arglist  {$$=$1;}
                |  %empty {$$=NULL;}

arglist : argument COMMA_argument_kleene COMMA_or_not {

                if($1==NULL && $2==NULL) $$=$3;
                else if($1==NULL && $3==NULL) $$=$2;
                else if($2==NULL && $3==NULL) $$=$1;
                else
                {
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
                }
}

COMMA_argument_kleene   : COMMA_argument_kleene COMMA argument {
                
                if($1 == NULL){
                    $1=new Node(nodeID++, "arguments", yylineno);
                }
                $1->push_back($2);
                $1->push_back($3);
                
                $$ = $1;
}
                        | %empty  {
                            $$ = NULL;
}


argument    : test comp_for_or_not {

                if($1==NULL) $$=$2;
                else if($2==NULL) $$=$1;
                else
                {
                    $$ = new Node(nodeID++, "argument", yylineno);
                    $$->push_back($1);
                    $$->push_back($2);
                        
                }
}
            | test EQUAL test {


                $$ = new Node(nodeID++, "argument", yylineno);
                $$->push_back($1);
                $$->push_back($2);
                $$->push_back($3);
                        
}

comp_for_or_not : comp_for {$$=$1;}
                | %empty {$$=NULL;}

comp_iter   : comp_for {$$=$1;}
            | comp_if {$$=$1;}

comp_for    : ASYNC_or_not FOR exprlist IN or_test comp_iter_or_not {


                        $$ = new Node(nodeID++, "comp_for", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        $$->push_back($4);
                        $$->push_back($5);
                        $$->push_back($6);

}

comp_if     : IF test_nocond comp_iter_or_not {

                        $$ = new Node(nodeID++, "comp_if", yylineno);
                        $$->push_back($1);
                        $$->push_back($2);
                        $$->push_back($3);
                        
}

comp_iter_or_not    :  comp_iter {$$=$1;}
                    |  %empty {$$=NULL;}

ASYNC_or_not    : ASYNC {$$=$1;}
                | %empty {$$=NULL;}





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
    cout<<"-output <filename>: specifies output dot script file "<<endl;
    cout<<"-verbose : enables debug messages for the parsing process"<<endl;
}


int main(int argc, char *argv[]) {


    string output_filename = "trial.out";
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
    ofstream fout(output_filename);
    if(!fout.is_open()){
        cerr<<"Error: unable to open output file\n";
        return -1;
    }
    int nodeID_dot = 0;
    fout<<"digraph G {"<<endl;
    fout<<"ordering=out"<<endl;
    create_nodes(fout, root_node);
    create_edges(fout, root_node);
    fout<<"}\n";
    fout.close();
    return 0;
}

void yyerror(string s)
{
    cerr<<"Error at line number "<<yylineno<<": "<<s<<endl;
    exit(0);
}