%{
    #include<bits/stdc++.h>
    #include<node.h>
    using namespace std;
    
    extern int yylex();
    extern void yyerror(string s);
    extern int yylineno;
%}

%union {
    Node *node;
}

// tokens -> Terminals
token<node> 


// types -> Variables
type<node>


// Grammar
%%

%%


int main() {
    yyparse();
    return 0;
}

void yyerror(string s)
{
    cerr<<"Error at line number "<<yylineno<<": "<<s<<endl;
    exit(0);
}