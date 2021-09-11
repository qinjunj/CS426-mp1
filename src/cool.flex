/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

%option noyywrap

/*
 * Define names for regular expressions here.
 */

/* Define start conditions. */
%x STRING ESCAPE

digit       [0-9]
letter      [a-zA-Z]
whitespace  [ \t\f\r\v]
character   [^\n\"\\]
escapeChar  [

%%
<INITIAL>\n    ++curr_lineno;
<INITIAL>{whitespace}+   /* eat up whitespaces */

<INITIAL>(?i:class)  {return 258;}
<INITIAL>(?i:else)   {return 259;}
<INITIAL>(?i:fi)     {return 260;}
<INITIAL>(?i:if)     {return 261;}
<INITIAL>(?i:in)     {return 262;}
<INITIAL>(?i:inherits) {return 263;}
<INITIAL>(?i:let)    {return 264;}
<INITIAL>(?i:loop)   {return 265;}
<INITIAL>(?i:pool)   {return 266;}
<INITIAL>(?i:then)   {return 267;}
<INITIAL>(?i:while)  {return 268;}
<INITIAL>(?i:case)   {return 269;}
<INITIAL>(?i:esac)   {return 270;}
<INITIAL>(?i:of)     {return 271;}
<INITIAL>(?i:=>)     {return 272;}
<INITIAL>(?i:new)    {return 273;}
<INITIAL>(?i:isvoid) {return 274;}
<INITIAL>(?i:not)    {return 281;}
<INITIAL>t(?i:rue)   {cool_yylval.boolean = 1; return 277;}
<INITIAL>f(?i:alse)  {cool_yylval.boolean = 0; return 277;}


<INITIAL>{digit}+      {  
                cool_yylval.symbol = inttable.add_int(atoi(yytext)); 
                return 276; 
              }   

<INITIAL>[a-z]({digit}|{letter}|_)*  { cool_yylval.symbol = idtable.add_string(yytext);
                                  return 279;
                                } 
<INITIAL>[A-Z]({digit}|{letter}|_)*  { cool_yylval.symbol = idtable.add_string(yytext);
                                  return 278;
                                } 

<INITIAL>\"    { 
                 string_buf_ptr = string_buf;
                 BEGIN(STRING);
               }


<STRING>\n    {
                cool_yylval.err_msg = "Unterminated string constant";
                return 283;
              }

<STRING>{character}*    {
                          char *yptr = yytext;
                          while (*yptr) 
                              *string_buf_ptr++ = *yptr++;
                        }

<STRING>\\    BEGIN(ESCAPE);



 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

%%


