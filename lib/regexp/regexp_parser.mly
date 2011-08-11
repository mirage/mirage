%{

  open Regular_expr;;

%}

%token <char> CHAR
%token <Regular_expr.regexp> CHARSET
%token STAR ALT PLUS QUESTION OPENPAR CLOSEPAR EOF

%start  regexp_start
%type <Regular_expr.regexp> regexp_start

%left ALT
%left CONCAT CHAR CHARSET OPENPAR
%nonassoc STAR PLUS QUESTION

%%
regexp_start:
  | regexp EOF
      { $1 }
;

regexp:
  | CHAR
      { char $1 }
  | CHARSET
      { $1 }
  | regexp STAR
      { star $1 }
  | regexp PLUS
      { some $1 }
  | regexp QUESTION
      { opt $1 }
  | regexp ALT regexp
      { alt $1 $3 }
  | regexp regexp %prec CONCAT
      { seq $1 $2 }
  | OPENPAR regexp CLOSEPAR
      { $2 }
;
