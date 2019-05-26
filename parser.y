%output "parser.c"
%defines "parser.h"

//mensagem de erro para erro de sintaxe
%define parse.error verbose
//habilita lookahead
%define parse.lac full

%{
    #include <stdio.h>
    #include "parser.h"
    extern int yylineno; //sera utilizado na funcao yyerror
    int yylex(void);
    void yyerror (char const *s);

%}

//tokens
%token ELSE IF INPUT INT OUTPUT RETURN VOID WHILE WRITE
%token SEMI COMMA LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE
%token ASSIGN
%token NUM STRING
%token ID


//tratando a precedencia de operadores
%left LT LE GT GE EQ NEQ
%left PLUS MINUS
%left TIMES OVER

%%
program: func_decl_list;
func_decl_list: func_decl_list func_decl | func_decl;
func_decl: func_header func_body;
func_header: ret_type ID LPAREN params RPAREN;
func_body: LBRACE opt_var_decl opt_stmt_list RBRACE;
opt_var_decl: %empty | var_decl_list;
opt_stmt_list: %empty | stmt_list;
ret_type: INT | VOID;
params: VOID | param_list;
param_list: param_list COMMA param | param;
param: INT ID | INT ID LBRACK RBRACK;
var_decl_list: var_decl_list var_decl | var_decl;
var_decl: INT ID SEMI | INT ID LBRACK NUM RBRACK SEMI;
stmt_list: stmt_list stmt | stmt;
stmt: assign_stmt | if_stmt | while_stmt | return_stmt | func_call SEMI;
assign_stmt: lval ASSIGN arith_expr SEMI;
lval: ID | ID LBRACK NUM RBRACK | ID LBRACK ID RBRACK;
if_stmt: IF LPAREN bool_expr RPAREN block | IF LPAREN bool_expr RPAREN block ELSE block;
block: LBRACE opt_stmt_list RBRACE;
while_stmt: WHILE LPAREN bool_expr RPAREN block;
return_stmt: RETURN SEMI | RETURN arith_expr SEMI;
func_call: output_call | write_call | user_func_call;
input_call: INPUT LPAREN RPAREN;
output_call: OUTPUT LPAREN arith_expr RPAREN;
write_call: WRITE LPAREN STRING RPAREN;
user_func_call: ID LPAREN opt_arg_list RPAREN;
opt_arg_list: %empty | arg_list;
arg_list: arg_list COMMA arith_expr | arith_expr;
bool_expr: arith_expr LT arith_expr | arith_expr LE arith_expr | arith_expr GT arith_expr
        | arith_expr GE arith_expr | arith_expr EQ arith_expr | arith_expr NEQ arith_expr;
arith_expr: arith_expr PLUS arith_expr | arith_expr MINUS arith_expr | arith_expr TIMES arith_expr
        | arith_expr OVER arith_expr | LPAREN arith_expr RPAREN | lval | input_call
        | user_func_call | NUM;
%%

//funcao para tratar o erro
void yyerror (char const *s){ 
        printf("PARSE ERROR (%d): %s\n", yylineno, s);
}

int main(void){
    int result = yyparse();
    if (result == 0) printf("PARSE SUCCESSFUL!\n");
}