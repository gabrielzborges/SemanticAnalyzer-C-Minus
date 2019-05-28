%output "parser.c"
%defines "parser.h"

//mensagem de erro para erro de sintaxe
%define parse.error verbose
//habilita lookahead
%define parse.lac full

%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "parser.h"
  #include "tables.h"
  extern int yylineno; //sera utilizado na funcao yyerror
  extern char *yytext;
  extern char yycopy[100];

  int yylex(void);
  void yyerror (char const *s);
  void var_verify();
  void var_new();
  void arity_verify();
  void func_verify();
  void func_new();

  char func_name[100];  //vetor auxiliar para guardar o nome de uma funcao
  int f_idx_in_table;
  int actual_arity = 0;
  int actual_scope = 0;
  LitTable *lit_tb;
  SymTable *sym_tb;
  SymFuncTable *func_tb;
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

func_decl_list: 
  func_decl_list func_decl {actual_scope++;} 
| func_decl {actual_scope++;}
;

func_decl: 
  func_header func_body
;

func_header: 
  ret_type ID {strcpy(func_name, yytext);} LPAREN params RPAREN {func_new(func_name, actual_arity);}
;

func_body: 
  LBRACE opt_var_decl opt_stmt_list RBRACE
;

opt_var_decl: 
  %empty 
| var_decl_list
;

opt_stmt_list: 
  %empty 
| stmt_list
;

ret_type: 
  INT 
| VOID
;

params: 
  VOID
| param_list
;

param_list: 
  param_list COMMA param 
| param
;

param: 
  INT ID {actual_arity++; var_new(yycopy, 0, actual_scope);}
| INT ID {actual_arity++; var_new(yycopy, -1, actual_scope);} LBRACK RBRACK
;

var_decl_list: 
  var_decl_list var_decl 
| var_decl
;

var_decl: 
  INT ID {var_new(yycopy, 0, actual_scope);} SEMI 
| INT ID LBRACK NUM {var_new(yycopy, atoi(yytext), actual_scope);} RBRACK SEMI
;

stmt_list: 
  stmt_list stmt 
| stmt
;

stmt: 
  assign_stmt 
| if_stmt 
| while_stmt 
| return_stmt 
| func_call SEMI
;

assign_stmt: 
  lval ASSIGN arith_expr SEMI
;

lval: 
  ID {var_verify(yycopy, actual_scope);} 
| ID LBRACK NUM RBRACK 
| ID LBRACK ID {var_verify(yycopy, actual_scope);} RBRACK
;

if_stmt: 
  IF LPAREN bool_expr RPAREN block 
| IF LPAREN bool_expr RPAREN block ELSE block
;

block: 
  LBRACE opt_stmt_list RBRACE
;

while_stmt: 
  WHILE LPAREN bool_expr RPAREN block
;

return_stmt: 
  RETURN SEMI 
| RETURN arith_expr SEMI
;

func_call: 
  output_call 
| write_call 
| user_func_call
;

input_call: 
  INPUT LPAREN RPAREN
;

output_call: 
  OUTPUT LPAREN arith_expr RPAREN
;

write_call: 
  WRITE LPAREN STRING {add_literal(lit_tb, yytext);} RPAREN
;

user_func_call: 
  ID {func_verify(yycopy);} LPAREN opt_arg_list RPAREN {arity_verify(func_tb, f_idx_in_table, actual_arity);}
;

opt_arg_list: 
  %empty 
| arg_list
;

arg_list: 
  arg_list COMMA arith_expr {actual_arity++;}
| arith_expr {actual_arity++;}
;

bool_expr: 
  arith_expr LT arith_expr 
| arith_expr LE arith_expr 
| arith_expr GT arith_expr
| arith_expr GE arith_expr 
| arith_expr EQ arith_expr 
| arith_expr NEQ arith_expr
;

arith_expr: 
  arith_expr PLUS arith_expr 
| arith_expr MINUS arith_expr 
| arith_expr TIMES arith_expr
| arith_expr OVER arith_expr 
| LPAREN arith_expr RPAREN 
| lval 
| input_call
| user_func_call 
| NUM
;
%%

//funcao para tratar o erro
void yyerror (char const *s){ 
        printf("PARSE ERROR (%d): %s\n", yylineno, s);
}

//funcao que checa se a variavel ja foi declarada
void var_verify(char* var_name, int scope){
  int index = lookup_var(sym_tb, var_name, scope);
  if(index == -1){
    printf("SEMANTIC ERROR (%d): variable '%s' was not declared.\n",
      yylineno, yycopy);
    exit(1);
  }
}

//funcao para guardar uma nova variavel
void var_new(char* var_name, int size, int scope){
  int index = lookup_var(sym_tb, var_name, scope);
  if(index != -1){
    printf("SEMANTIC ERROR (%d): variable '%s' already declared at line %d.\n",
      yylineno, var_name, get_line(sym_tb, index));
    exit(1);
  }
  add_var(sym_tb, var_name, yylineno, scope, size);
}

//imprime o erro caso nao seja a mesma aridade, caso contrario faz nada
void arity_verify(SymFuncTable *sft, int index, int arity, char* fname){
    if(sft->t[index].arity != arity){
      printf("SEMANTIC ERROR (%d): function '%s' was called with %d arguments but declared with %d parameters.\n", 
        yylineno, yycopy, arity, get_func_arity(func_tb, index));
      exit(1);
    }
    actual_arity = 0;
}

//funcao que checa se a funcao foi declarada
void func_verify(char *fname){
  int index = lookup_func(func_tb, fname);
  if(index == -1){
    printf("SEMANTIC ERROR (%d): function '%s' was not declared.\n",
      yylineno, yycopy);
    exit(1);
  }
  f_idx_in_table = index;
}

//funcao para guardar uma nova funcao
void func_new(char* fname, int arity){
  int index = lookup_func(func_tb, fname);
  if(index != -1){
    printf("SEMANTIC ERROR (%d): function '%s' already declared at line %d.\n",
      yylineno, fname, get_func_line(func_tb, index));
    exit(1);
  }
  add_func(func_tb, fname, yylineno, arity);
  actual_arity = 0;
}

int main(void){
  //criando as tabelas
  lit_tb = create_lit_table();
  sym_tb  = create_sym_table();
  func_tb = create_sym_func_table();

  int parse_success = yyparse();
  
  if(parse_success == 0){  //se o parse foi executado com sucesso
    printf("PARSE SUCCESSFUL!\n");

    //printando as tabelas
    printf("\n");
    print_lit_table(lit_tb);
    printf("\n\n");
    print_sym_table(sym_tb);
    printf("\n\n");
    print_sym_func_table(func_tb);

    //liberando as tabelas
    free_lit_table(lit_tb);
    free_sym_table(sym_tb);
    free_sym_func_table(func_tb);
  }
  return 0;
}