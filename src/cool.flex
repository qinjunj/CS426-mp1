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

int string_len; /* record string length */
int comment_paran; /* record number of open comments, for detecting unmatched comment marks */
int containNull; /* record if there is NULL within a string */


%}

%option noyywrap

/*
 * Define names for regular expressions here.
 */

/* Define start conditions. */
%x STRING ESCAPE COMMENT_LINE COMMENT_BLOCK

digit       [0-9]
letter      [a-zA-Z]
whitespace  [ \t\f\r\v]
/* characters that need to be escaped i.e. \c -> c */ 
nonEscapeChar [^btnf\n] 

%%
<INITIAL>\n    ++curr_lineno;
<INITIAL>{whitespace}+   /* eat up whitespaces */

<INITIAL>(?i:class)  {return CLASS;}
<INITIAL>(?i:else)   {return ELSE;}
<INITIAL>(?i:fi)     {return FI;}
<INITIAL>(?i:if)     {return IF;}
<INITIAL>(?i:in)     {return IN;}
<INITIAL>(?i:inherits) {return INHERITS;}
<INITIAL>(?i:let)    {return LET;}
<INITIAL>(?i:loop)   {return LOOP;}
<INITIAL>(?i:pool)   {return POOL;}
<INITIAL>(?i:then)   {return THEN;}
<INITIAL>(?i:while)  {return WHILE;}
<INITIAL>(?i:case)   {return CASE;}
<INITIAL>(?i:esac)   {return ESAC;}
<INITIAL>(?i:of)     {return OF;}
<INITIAL>(?i:=>)     {return DARROW;}
<INITIAL>(?i:new)    {return NEW;}
<INITIAL>(?i:isvoid) {return ISVOID;}
<INITIAL>(?i:not)    {return NOT;}
<INITIAL>t(?i:rue)   {cool_yylval.boolean = 1; return BOOL_CONST;}
<INITIAL>f(?i:alse)  {cool_yylval.boolean = 0; return BOOL_CONST;}

<INITIAL>":"  return ':';
<INITIAL>"="  return '=';
<INITIAL>"("  return '(';
<INITIAL>")"  return ')';
<INITIAL>"{"  return '{';
<INITIAL>"}"  return '}';
<INITIAL>","  return ',';
<INITIAL>"+"   return '+';
<INITIAL>"-"   return '-';
<INITIAL>"*"   return '*';
<INITIAL>"/"   return '/';
<INITIAL>"~"   return '~';
<INITIAL>"<"   return '<';
<INITIAL>"<-"   return ASSIGN;
<INITIAL>"<="   return LE;
<INITIAL>";"    return ';';
<INITIAL>"."   return '.';
<INITIAL>"@"    return '@';
   


<INITIAL>{digit}+  {  
                       cool_yylval.symbol = inttable.add_int(atoi(yytext)); 
                       return INT_CONST; 
                   }   

<INITIAL>[a-z]({digit}|{letter}|_)*  { cool_yylval.symbol = idtable.add_string(yytext);
                                       return OBJECTID;
                                     } 

<INITIAL>[A-Z]({digit}|{letter}|_)*  { cool_yylval.symbol = idtable.add_string(yytext);
                                       return TYPEID;
                                     } 
<INITIAL>\"    { 
                 string_buf_ptr = string_buf;
                 memset(string_buf, '\0', MAX_STR_CONST*sizeof(char));
                 BEGIN(STRING);
                 string_len = 0;
               }


<STRING>\n    {
                cool_yylval.error_msg = "Unterminated string constant";
                ++curr_lineno;
                BEGIN(INITIAL);
                return ERROR;
              }

<STRING>\\n    { *string_buf_ptr++ = '\n'; string_len++; }
<STRING>\\t    { *string_buf_ptr++ = '\t'; string_len++; }           
<STRING>\\b    { *string_buf_ptr++ = '\b'; string_len++; }
<STRING>\\f    { *string_buf_ptr++ = '\f'; string_len++; }

<STRING>\\{nonEscapeChar}  { *string_buf_ptr++ = yytext[1]; string_len++; }

<STRING>\\\n    { *string_buf_ptr++ = yytext[1]; ++curr_lineno; string_len++; }

<STRING><<EOF>> {
                  cool_yylval.error_msg = "Unterminated string constant";
                  BEGIN(INITIAL);
                  return ERROR;
                }
<STRING>"\000"    containNull = 1; 

<STRING>\"  { 
              *string_buf_ptr = '\0';
              if (containNull == 1) {
                  cool_yylval.error_msg = "String constant contains null";
                  BEGIN(INITIAL);
                  containNull = 0;
                  return ERROR;
              }
              if (string_len >= MAX_STR_CONST) {
                  cool_yylval.error_msg = "String constant too long";
                  BEGIN(INITIAL);
                  return ERROR;
              }
              cool_yylval.symbol = stringtable.add_string(string_buf);
              BEGIN(INITIAL);
              return STR_CONST;
            }

<STRING>.            {
                          char *yptr = yytext;
                          while (*yptr) {
                              *string_buf_ptr++ = *yptr++;
                              string_len++;
                          }
                     }

<INITIAL>--    BEGIN(COMMENT_LINE);

<COMMENT_LINE>\n  { BEGIN(INITIAL); ++curr_lineno; }

<COMMENT_LINE>. /* eat up comments */
 
<INITIAL>\(\*    { BEGIN(COMMENT_BLOCK); comment_paran = 1; }

<INITIAL>\*\)    { cool_yylval.error_msg = "Unmatched *)"; BEGIN(INITIAL); return ERROR; }

<COMMENT_BLOCK>\(\*    { ++comment_paran; }

<COMMENT_BLOCK>\*\)  { 
                        --comment_paran; 
                        if (comment_paran < 0) {
                            cool_yylval.error_msg = "Unmatched *)";
                            return ERROR;  
                        } else if (comment_paran == 0) {
                            BEGIN(INITIAL);
                        }
                     } 

<COMMENT_BLOCK>\n    { ++curr_lineno; }

<COMMENT_BLOCK><<EOF>>    {
                            cool_yylval.error_msg = "EOF in comment";
                            BEGIN(INITIAL);
                            return ERROR;
                          }

<COMMENT_BLOCK>.  /* eat up comments */

    /* anything that falls to this rule indicates an error */ 
<INITIAL>.    { cool_yylval.error_msg = yytext; return ERROR; } 

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
