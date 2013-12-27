package com.goide.lexer;

import com.intellij.lexer.FlexLexer;
import com.intellij.psi.tree.IElementType;
import com.goide.GoTypes;
import java.util.*;
import java.lang.reflect.Field;
import org.jetbrains.annotations.NotNull;
import static com.goide.GoParserDefinition.*;

%%


%{
  public _GoLexer() {
    this((java.io.Reader)null);
  }
%}

%unicode
%class _GoLexer
%implements FlexLexer, GoTypes
%unicode
%public

%function advance
%type IElementType

%eof{
  return;
%eof}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////// User code //////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

%{

  private Stack<IElementType> gStringStack = new Stack<IElementType>();
  private Stack<IElementType> blockStack = new Stack<IElementType>();

  private int afterComment = YYINITIAL;
  private int afterNls = YYINITIAL;
  private int afterBrace = YYINITIAL;

  private void clearStacks(){
    gStringStack.clear();
    blockStack.clear();
  }

  private Stack<IElementType> braceCount = new Stack<IElementType>();

%}


NL = [\r\n] | \r\n      // NewLine
WS = [ \t\f]            // Whitespaces


//C_STYLE_COMMENT="/*" [^"*/"]* "*/"
//COMMENT_TAIL=( [^"*"]* ("*"+ [^"*""/"] )? )* ("*" | "*"+"/")?

LINE_COMMENT = "//" [^\r\n]*
//MULTILINE_COMMENT = "/*" "*"

LETTER = [:letter:] | "_"
DIGIT =  [:digit:]

HEX_DIGIT = [0-9A-Fa-f]
INT_DIGIT = [0-9]
OCT_DIGIT = [0-7]

NUM_INT = "0" | ([1-9] {INT_DIGIT}*)
NUM_HEX = ("0x" | "0X") {HEX_DIGIT}+
NUM_OCT = "0" {OCT_DIGIT}+

FLOAT_EXPONENT = [eE] [+-]? {DIGIT}+
NUM_FLOAT = ( ( ({DIGIT}+ "." {DIGIT}*) | ({DIGIT}* "." {DIGIT}+) ) {FLOAT_EXPONENT}?) | ({DIGIT}+ {FLOAT_EXPONENT})

IDENT = {LETTER} ({LETTER} | {DIGIT} )*
//IDENT_NOBUCKS = {LETTER} ({LETTER} | {DIGIT})*

STR =      "\""
ESCAPES = [abfnrtv]

//STRING_NL = {ONE_NL}
//STRING_ESC = \\ [^]
//REGEX_ESC = \\ n | \\ r | \\ t | \\ b | \\ f | "\\" "\\" | \\ "$" | \\ \" | \\ \' | "\\""u"{HEX_DIGIT}{4} | "\\" [0..3] ([0..7] ([0..7])?)? | "\\" [4..7] ([0..7])? | "\\" {ONE_NL}

/// Regexes ////////////////////////////////////////////////////////////////

//ESCAPPED_REGEX_SEP = \\ "/"
//REGEX_BEGIN = "/""$" |  "/" ([^"/""$"] | {REGEX_ESC} | {ESCAPPED_REGEX_SEP})? {REGEX_CONTENT}"$"
//REGEX_CONTENT = ({REGEX_ESC}    | {ESCAPPED_REGEX_SEP} | [^"/"\r\n"$"])*

//REGEX_LITERAL = "/" ([^"/"\n\r"$"] | {REGEX_ESC} | {ESCAPPED_REGEX_SEP})? {REGEX_CONTENT} ("$""/" | "/")

////////////////////////////////////////////////////////////////////////////

//SINGLE_QUOTED_STRING_BEGIN = "\'" ( {STRING_ESC} | "\""  | [^\\\'\r\n] | "$" )*
//SINGLE_QUOTED_STRING = {SINGLE_QUOTED_STRING_BEGIN} \'
//TRIPLE_QUOTED_STRING = "\'\'\'" ({STRING_ESC} | \" | "$" | [^\'] | {STRING_NL} | \'(\')?[^\'] )* (\'\'\' | \\)?

//STRING_LITERAL = {TRIPLE_QUOTED_STRING} | {SINGLE_QUOTED_STRING}


// Single-double-quoted GStrings
//GSTRING_SINGLE_CONTENT = ({STRING_ESC} | [^\\\"\r\n"$"] | "\'" )+

// Triple-double-quoted GStrings
//GSTRING_TRIPLE_CONTENT = ({STRING_ESC} | \' | \" (\")? [^\""$"] | [^\\\""$"] | {STRING_NL})+


//GSTRING_TRIPLE_CTOR_END = {GSTRING_TRIPLE_CONTENT} \"\"\"


//GSTRING_LITERAL = \"\" | \" ([^\\\"\n\r"$"] | {STRING_ESC})? {GSTRING_SINGLE_CONTENT} \" | \"\"\" {GSTRING_TRIPLE_CTOR_END}


// %state IN_COMMENT
%state MAYBE_SEMICOLON

%%

//<IN_COMMENT> {
//!"*/"+                                      {}
//
//"*/"                                        { yybegin(YYINITIAL); return MULTILINE_COMMENT; }
//<<EOF>>                                     { yybegin(YYINITIAL); return MULTILINE_COMMENT; }
//}

<YYINITIAL> {
"|"                                       { return BIT_OR; }

{WS}                                     { return WS; }
{NL}+                                    { return NLS; }

{LINE_COMMENT}                             { return LINE_COMMENT; }
//{MULTILINE_COMMENT}                             { return MULTILINE_COMMENT; }
"/*" ( ([^"*"]|[\r\n])* ("*"+ [^"*""/"] )? )* ("*" | "*"+"/")? { return MULTILINE_COMMENT; }

//([^"*/"] | [\r\n])+ "*/"?

"..."                                     { return TRIPLE_DOT; }
"."                                       { return DOT; }

"'" . "'"                                               { yybegin(MAYBE_SEMICOLON); return CHAR; }
"'" \n "'"                                              { yybegin(MAYBE_SEMICOLON); return CHAR; }
"'\\" [abfnrtv\\\'] "'"                                 { yybegin(MAYBE_SEMICOLON); return CHAR; }
"'\\" {OCT_DIGIT} {OCT_DIGIT} {OCT_DIGIT} "'"        { yybegin(MAYBE_SEMICOLON); return CHAR; }
"'\\x" {HEX_DIGIT} {HEX_DIGIT} "'"                    { yybegin(MAYBE_SEMICOLON); return CHAR; }
"'\\u" {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} "'"
                                                        { yybegin(MAYBE_SEMICOLON); return CHAR; }
"'\\U" {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} {HEX_DIGIT} "'"
                                                        { yybegin(MAYBE_SEMICOLON); return CHAR; }

"`" [^`]* "`"?                            { yybegin(MAYBE_SEMICOLON); return STRING; }
{STR} ( [^\"\\\n\r] | "\\" ("\\" | {STR} | {ESCAPES} | [0-8xuU] ) )* {STR}? { yybegin(MAYBE_SEMICOLON); return STRING; }
"{"                                       { return LBRACE; }
"}"                                       { yybegin(MAYBE_SEMICOLON); return RBRACE; }

"["                                       { return LBRACK; }
"]"                                       { yybegin(MAYBE_SEMICOLON); return RBRACK; }

"("                                       { return LPAREN; }
")"                                       { yybegin(MAYBE_SEMICOLON); return RPAREN; }

":"                                       { return COLON; }
";"                                       { return SEMICOLON; }
","                                       { return COMMA; }

"=="                                      { return EQ; }
"="                                       { return ASSIGN; }

"!="                                      { return NOT_EQ; }
"!"                                       { return NOT; }

"++"                                      { yybegin(MAYBE_SEMICOLON); return PLUS_PLUS; }
"+="                                      { return PLUS_ASSIGN; }
"+"                                       { return PLUS; }

"--"                                      { yybegin(MAYBE_SEMICOLON); return MINUS_MINUS; }
"-="                                      { return MINUS_ASSIGN; }
"-"                                       { return MINUS; }

"||"                                      { return COND_OR; }
"|="                                      { return BIT_OR_ASSIGN; }

"&^="                                     { return BIT_CLEAR_ASSIGN; }
"&^"                                      { return BIT_CLEAR; }
"&&"                                      { return COND_AND; }

"&="                                      { return BIT_AND_ASSIGN; }
"&"                                       { return BIT_AND; }

"<<="                                     { return SHIFT_LEFT_ASSIGN; }
"<<"                                      { return SHIFT_LEFT; }
"<-"                                      { return SEND_CHANNEL; }
"<="                                      { return LESS_OR_EQUAL; }
"<"                                       { return LESS; }

"^="                                      { return BIT_XOR_ASSIGN; }
"^"                                       { return BIT_XOR; }

"*="                                      { return MUL_ASSIGN; }
"*"                                       { return MUL; }

"/="                                      { return QUOTIENT_ASSIGN; }
"/"                                       { return QUOTIENT; }

"%="                                      { return REMAINDER_ASSIGN; }
"%"                                       { return REMAINDER; }

">>="                                     { return SHIFT_RIGHT_ASSIGN; }
">>"                                      { return SHIFT_RIGHT; }
">="                                      { return GREATER_OR_EQUAL; }
">"                                       { return GREATER; }

":="                                      { return VAR_ASSIGN; }


"break"                                   { yybegin(MAYBE_SEMICOLON); return BREAK;  }
"fallthrough"                             { yybegin(MAYBE_SEMICOLON); return FALLTHROUGH; }
"return"                                  { yybegin(MAYBE_SEMICOLON); return RETURN ;  }
"continue"                                { yybegin(MAYBE_SEMICOLON); return CONTINUE ;  }

"default"                                 { return DEFAULT;  }
"package"                                 { return PACKAGE;  }
"func"                                    { return FUNC;  }
"interface"                               { return INTERFACE;  }
"select"                                  { return SELECT;  }

"case"                                    { return CASE;  }
"defer"                                   { return DEFER;  }
"go"                                      { return GO;  }
"map"                                     { return MAP;  }

"chan"                                    {  return CHAN;  }

"struct"                                  {  return STRUCT;  }
"else"                                    {  return ELSE;  }
"goto"                                    {  return GOTO;  }
"switch"                                  {  return SWITCH;  }
"const"                                   {  return CONST; }

"if"                                      {  return IF ;  }
"for"                                     {  return FOR ;  }
"import"                                  {  return IMPORT ;  }

"range"                                   {  return RANGE;  }
"type"                                    {  return TYPE_;  }
"var"                                     {  return VAR;  }

{IDENT}                                  {  yybegin(MAYBE_SEMICOLON); return IDENTIFIER; }

{NUM_FLOAT}"i"                           {  yybegin(MAYBE_SEMICOLON); return FLOATI; }
{NUM_FLOAT}                              {  yybegin(MAYBE_SEMICOLON); return FLOAT; }
{DIGIT}+"i"                              {  yybegin(MAYBE_SEMICOLON); return DECIMALI; }
{NUM_OCT}                                {  yybegin(MAYBE_SEMICOLON); return OCT; }
{NUM_HEX}                                {  yybegin(MAYBE_SEMICOLON); return HEX; }
{NUM_INT}                                {  yybegin(MAYBE_SEMICOLON); return INT; }

.                                         {  return com.intellij.psi.TokenType.BAD_CHARACTER; }
}

<MAYBE_SEMICOLON> {
{WS}               { return WS; }
{NL}               { yybegin(YYINITIAL); yypushback(yytext().length()); return SEMICOLON_SYNTHETIC; }
{LINE_COMMENT}       { return LINE_COMMENT; }
"/*" ( ([^"*"]|[\r\n])* ("*"+ [^"*""/"] )? )* ("*" | "*"+"/")?
                    { return MULTILINE_COMMENT; }

.           { yybegin(YYINITIAL); yypushback(yytext().length()); }
}