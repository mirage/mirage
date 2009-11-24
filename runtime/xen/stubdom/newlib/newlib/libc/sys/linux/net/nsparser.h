#define NL 257
#define SUCCESS 258
#define UNAVAIL 259
#define NOTFOUND 260
#define TRYAGAIN 261
#define RETURN 262
#define CONTINUE 263
#define STRING 264
typedef union {
	char *str;
	int   mapval;
} YYSTYPE;
extern YYSTYPE _nsyylval;
