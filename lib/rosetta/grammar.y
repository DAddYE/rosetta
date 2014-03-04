class Parser

token BREAK CASE CHAN CONST CONTINUE
      DEFAULT DEFER ELSE FALL FOR DEF DO FUNC GO GOTO IF
      IMPORT INTERFACE MAP NAME PACKAGE RANGE RETURN SELECT
      STRUCT SWITCH TYPE VAR BODY IGNORE COMMENT
      INDENT OUTDENT TERM IN COP
      STRING NUMBER
      MODULE CLASS
      REGEX

options no_result_var

prechigh
  left     ToRightParen
  left     ')'
  left     '('
  left     NotParen
  left     '*' '/' '%' '&' '<<' '>>' '&^'
  left     '+' '-' '|' '^'
  left     '==' '!=' '<=' '>=' '<' '>'
  left     '&&'
  left     '||'
  left     '<-'
preclow

rule

root:
 package
 imports
 xdcl_list
                        { Root.new(val[0], val[1], val[2]) }

package:
| PACKAGE sym term       { Package.new(val[1]) }

imports:
                                          { [] }
| IMPORT import_stmt term                 { [val[1]] }
| IMPORT INDENT import_stmt_list OUTDENT  { val[2] }

import_stmt:
  string             { Import.new(nil, val[0]) }
| sym string         { Import.new(val[0], val[1]) }
| '.' string         { Import.new(val[0], val[1]) }

import_stmt_list:
  import_stmt                            { [val[0]] }
| import_stmt_list term import_stmt      { val[0] << val[2] }

/*
 * declarations
 */
xdcl:
                    { Line.new }
| common_dcl
| oo_dcl
| xfndcl
| non_dcl_stmt
| error

common_dcl:
  VAR vardcl                                             { DclVar.new(val[1]) }
| VAR INDENT vardcl_list OUTDENT                         { DclVar.new(ParensIndent.new(val[2])) }
| CONST constdcl                                         { DclConst.new(val[1]) }
| CONST INDENT constdcl_list OUTDENT                     { DclConst.new(ParensIndent.new(val[2])) }
| TYPE typedcl                                           { DclType.new(val[1]) }
| TYPE INDENT typedcl_list OUTDENT                       { DclType.new(ParensIndent.new(val[2])) }

oo_dcl:
  CLASS dotname                                          { DclClass.new(val[1], nil, []) }
| CLASS dotname dotname                                  { DclClass.new(val[1], val[2], []) }
| CLASS dotname INDENT xdcl_list OUTDENT                 { DclClass.new(val[1], nil, val[3]) }
| CLASS dotname dotname INDENT xdcl_list OUTDENT         { DclClass.new(val[1], val[2], val[4]) }
| MODULE dotname                                         { DclModule.new(val[1], []) }
| MODULE dotname INDENT xdcl_list OUTDENT                { DclModule.new(val[1], val[3]) }

vardcl:
  dcl_name_list ntype                   { DclCommon.new(val[0], val[1], []) }
| dcl_name_list ntype '=' expr_list     { DclCommon.new(val[0], val[1], val[3]) }
| dcl_name_list '=' expr_list           { DclCommon.new(val[0], nil, val[2]) }

constdcl:
  dcl_name_list ntype '=' expr_list     { DclCommon.new(val[0], val[1], val[3]) }
| dcl_name_list '=' expr_list           { DclCommon.new(val[0], nil, val[2]) }

constdcl1:
  constdcl
| dcl_name_list ntype                   { DclCommon.new(val[0], val[1], []) }
| dcl_name_list                         { DclCommon.new(val[0], nil, [])}

typedcl:
 sym ntype                             { DclCommon.new([val[0]], val[1], []) }

case:
  CASE expr_or_type_list            { SwitchCase.new(val[0], val[1], nil) }
| CASE expr_or_type_list '=' expr   { SwitchCase.new(val[0], Expr.new(val[1], val[2], val[3]), nil) }
| CASE expr_or_type_list ':=' expr  { SwitchCase.new(val[0], Expr.new(val[1], val[2], val[3]), nil) }
| DEFAULT                           { SwitchCase.new(val[0], nil, nil)}

caseblock:
  case
| case suite_stmt                    { val[0].statements = [val[1]]; val[0] }

caseblock_list:
  caseblock                          { [val[0]] }
| caseblock_list term caseblock      { val[0] << val[2] }

range_stmt:
  expr_list '=' range            { Expr.new(val[0], val[1], val[2]) }
| expr_list ':=' range           { Expr.new(val[0], val[1], val[2]) }
| expr_list inrange              { Expr.new(val[0], ':=', val[1]) }

range:
  RANGE expr    { Range.new(val[1]) }

inrange:
  IN expr       { Range.new(val[1]) }

for_header:
  osimple_stmt semi osimple_stmt semi osimple_stmt      { val }
| osimple_stmt                                          { val }
| range_stmt                                            { val }

for_body:
 for_header suite_stmt   { For.new(val[0], val[1]) }

for_stmt:
 FOR for_body            { val[1] }

if_header:
  simple_stmt                    { If::Header.new([val[0]]) }
| simple_stmt semi osimple_stmt  { If::Header.new(val) }

/* IF cond body (ELSE IF cond body)* (ELSE block)? */
if_stmt:
 IF if_header
 suite_stmt
 elseif_list else      { If.new(val[1], val[2], val[3], val[4]) }

elseif:
 ELSE IF if_header suite_stmt { If::ElseIf.new(val[2], val[3]) }

elseif_list:
                        { [] }
| elseif_list elseif    { val[0] << val[1] }

else:
| ELSE suite_stmt    { If::Else.new(val[1]) }

oif_header:
| if_header

switch_stmt:
  SWITCH oif_header
  INDENT caseblock_list OUTDENT { Switch.new(val[1], val[3]) }

select_stmt:
  SELECT
  INDENT caseblock_list OUTDENT { Select.new(val[2]) }

/*
 * expressions
 */
expr:
  uexpr
| expr '||' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '&&' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '==' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '!=' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '<' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '<=' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '>=' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '>' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '+' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '-' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '|' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '^' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '*' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '/' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '%' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '&' expr      { Expr.new(val[0], val[1], val[2]) }
| expr '&^' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '<<' expr     { Expr.new(val[0], val[1], val[2]) }
| expr '>>' expr     { Expr.new(val[0], val[1], val[2]) }
/* not an expression anymore, but left in so we can give a good error */
| expr '<-' expr     { Expr.new(val[0], val[1], val[2]) }

uexpr:
  pexpr
| '*' uexpr          { Expr.new([], val[0], val[1]) }
| '&' uexpr          { Expr.new([], val[0], val[1]) }
| '+' uexpr          { Expr.new([], val[0], val[1]) }
| '-' uexpr          { Expr.new([], val[0], val[1]) }
| '!' uexpr          { Expr.new([], val[0], val[1]) }
| '~' uexpr          { Expr.new([], val[0], val[1]) }
| '^' uexpr          { Expr.new([], val[0], val[1]) }
| '<-' uexpr         { Expr.new([], val[0], val[1]) }

/*
 * call-like statements that
 * can be preceded by 'defer' and 'go'
 */
pseudocall:
  call
| call_do
| call_self

call:
  pexpr special                          { Call.new(val[0], val[1], [], false) }
| pexpr '(' ')'                          { Call.new(val[0], nil, [], false) }
| pexpr '(' expr_or_type_list ')'        { Call.new(val[0], nil, val[2], false) }
| pexpr '(' expr_or_type_list '...' ')'  { Call.new(val[0], nil, val[2], true) }

simple_call:
  nameo '(' ')'                          { Call.new(val[0], nil, [], false) }
| nameo '(' expr_or_type_list ')'        { Call.new(val[0], nil, val[2], false) }
| nameo '(' expr_or_type_list '...' ')'  { Call.new(val[0], nil, val[2], true) }

call_self:
  pexpr '::' simple_call                 { val[2].args.unshift(val[0]); val[2] }

# Call without parens.
# files.each() do (f, type)
#   fmt.Println(f)
call_do:
  call fnliteral                         { args = val[0].args; args << Comma.new unless args.empty?; args << val[1]; val[0] }

# name:len()
pexpr_no_paren:
  literal
| name
| pexpr '.' sym                             { ExprSelector.new(val[0], val[2]) }
| pexpr '.' '(' expr_or_type ')'            { ExprTypeAssert.new(val[0], val[3]) }
| pexpr '.' '(' type ')'                    { ExprTypeAssert.new(val[0], val[3]) }
| pexpr '[' expr ']'                        { ExprIndex.new(val[0], val[2]) }
| pexpr '[' oexpr ':' oexpr ']'             { ExprSlice.new(val[0], val[2], val[4], nil) }
| pexpr '[' oexpr ':' oexpr ':' oexpr ']'   { ExprSlice.new(val[0], val[2], val[4], val[6]) }
| pseudocall
| convtype '(' expr ')'                     { Conversion.new(val[0], nil, val[2], false) }
| comptype braced_keyval                    { CompLiteral.new(val[0], val[1]) }
| pexpr_no_paren braced_keyval              { CompLiteral.new(val[0], val[1]) }
| '(' expr_or_type ')' braced_keyval        { CompLiteral.new(Parens.new(val[1]), val[3])}
| fnliteral

type:
  TYPE { Literal.new(val[0], @token) }

keyval:
 expr ':' complitexpr                    { KeyType.new(val[0], val[2]) }

complitexpr:
  expr
| braced_keyval


braced_keyval:
  '{' braced_keyval_list '}'                { val[1] }
| '{' INDENT braced_keyval_list OUTDENT '}' { val[2] }

pexpr:
  pexpr_no_paren
| '(' expr_or_type ')'  { Parens.new(val[1]) }

expr_or_type:
  expr
| non_expr_type = ToRightParen

name_or_type:
  ntype

/*
 * names and types
 * newname is used before declared
 * oldname is used after declared
 */
osym:
| sym

sym:
  NAME                { Literal.new(val[0], @token) }
| '@' NAME            { InstanceVar.new(val[1], @token) }
| '@' '@' NAME        { ClassVar.new(val[2], @token) }

regex:
  REGEX       { RegexType.new(val[0], @token) }

string:
  STRING      { StringType.new(val[0], @token) }

number:
  NUMBER      { NumericType.new(val[0], @token) }

literal:
  string
| number
| regex

special:
  '?'
| '!'

specialfn:
  '[' ']'         { val.join }
| '[' ']' '='     { val.join }
| '='             { val[0] }
| special

ospecialfn:
| specialfn

name:
  sym = NotParen

nameo:
  NAME       { Literal.new(val[0], @token) }

semi:
  ';'        { Semicolon.new }

comma:
  ','        { Comma.new }

term:
  TERM       { Line.new }

/*
 * to avoid parsing conflicts, type is split into
 * channel types
 * function types
 * parenthesized types
 * any other type
 * the type system makes additional restrictions,
 * but those are not implemented in the grammar.
 */
dotdotdot:
  '...'          { Variadic.new(nil) }
| '...' ntype    { Variadic.new(val[1]) }

ntype:
  recvchantype
| fntype
| othertype
| ptrtype
| dotname
| '(' ntype ')' { Parens.new(val[1]) }

non_expr_type:
  recvchantype
| fntype
| othertype
| '*' non_expr_type { PointerType.new(val[1]) }

non_recvchantype:
  fntype
| othertype
| ptrtype
| dotname
| '(' ntype ')' { Parens.new(val[1]) }

convtype:
  fntype
| othertype

comptype:
  othertype

fnret_type:
  recvchantype
| fntype
| othertype
| ptrtype
| dotname

dotname:
  name            { QualifiedIdent.new(nil, nil, val[0]) }
| name '.' sym    { QualifiedIdent.new(val[0], val[1], val[2]) }
| name '::' sym   { QualifiedIdent.new(val[0], val[1], val[2]) }

othertype:
  '[' oexpr ']' ntype       { ArrayType.new(val[1], val[3]) }
| '[' '...' ']' ntype       { ArrayType.new(Variadic.new(nil), val[3]) }
| CHAN non_recvchantype     { ChanType::SendRecv.new(val[1]) }
| CHAN '<-' ntype           { ChanType::Send.new(val[2]) }
| MAP '[' ntype ']' ntype   { MapType.new(val[2], val[4]) }
| structtype
| interfacetype

ptrtype:
  '*' ntype           { PointerType.new(val[1]) }

recvchantype:
  '<-' CHAN ntype     { Chan::Recv.new(val[2]) }

structtype:
  STRUCT '{' '}'                         { StructType.new([]) }
| STRUCT '{' structdcl_list '}'          { StructType.new(val[2]) }
| STRUCT INDENT structdcl_list OUTDENT   { StructType.new(val[2]) }

interfacetype:
  INTERFACE '{' '}'                            { InterfaceType.new([]) }
| INTERFACE '{' interfacedcl_list '}'          { InterfaceType.new(val[2]) }
| INTERFACE INDENT interfacedcl_list OUTDENT   { InterfaceType.new(val[2]) }

/*
 * function stuff
 * all in one place to show how crappy it all is
 */

fndcl:
  fname '(' oarg_type_list ')' fnres    { Function.new(val[0], val[2], val[4], nil) }

xfndcl:
  DEF fndcl suite_stmt             { val[1].body = val[2]; val[1] }
| DEF fndcl                        { val[1] }

fnlitdcl:
  DO '(' oarg_type_list ')' fnres     { FunctionDo.new(nil, val[2], val[4], nil) }
| DO fnres                            { FunctionDo.new(nil, [], val[2], nil) }


fnliteral:
  fnlitdcl INDENT stmt_list OUTDENT  { val[0].body = val[2]; val[0] }
| fnlitdcl error                     { val[0].body = val[2]; val[0] }

fntype:
  FUNC '(' oarg_type_list ')' fnres     { Function.new(nil, val[2], val[4], nil) }

optr:
            { 0 }
| '*' optr  { val[1] += 1 }

fname:
  optr dotname ospecialfn { Function::Name.new(val[0], val[1], val[3]) }

fnres:
  = NotParen                   { [] }
| '->' fnret_type              { [val[1]] }
| '->' '(' oarg_type_list ')'  { [val[2]] }


/*
 * lists of things
 * note that they are left recursive
 * to conserve yacc stack. they need to
 * be reversed to interpret correctly
 */

keyval_list:
  keyval                                   { [val[0]] }
| complitexpr                              { [val[0]] }
| keyval_list comma keyval                 { val[0] << val[1] << val[2] }
| keyval_list comma complitexpr            { val[0] << val[1] << val[2] }

braced_keyval_list:
                          { [] }
| keyval_list ocomma      { val[0] }

xdcl_list:
  xdcl                                 { [val[0]] }
| xdcl_list term xdcl                  { val[0] << val[1] << val[2] }

vardcl_list:
  vardcl                               { [val[0]] }
| vardcl_list term vardcl              { val[0] << val[1] << val[2] }

constdcl_list:
  constdcl1                            { [val[0]] }
| constdcl_list term constdcl1         { val[0] << val[1] << val[2] }

typedcl_list:
  typedcl                              { [val[0]] }
| typedcl_list term typedcl            { val[0] << val[1] << val[2] }

structdcl_list:
  structdcl                            { [val[0]] }
| structdcl_list term structdcl        { val[0] << val[1] << val[2] }

interfacedcl_list:
  interfacedcl                         { [val[0]] }
| interfacedcl_list term interfacedcl  { val[0] << val[1] << val[2] }

structdcl:
  sym_list ntype oliteral              { StructType::Field.new(val[0], val[1], val[2], false) }
| embed oliteral                       { StructType::Field.new([val[0]], nil, val[1], false)}
| '(' embed ')' oliteral               { StructType::Field.new([Parens.new(val[1])], nil, val[3], false) }
| '*' embed oliteral                   { StructType::Field.new([val[1]], nil, val[2], true) }
| '(' '*' embed ')' oliteral           { StructType::Field.new([Parens.new(PointerType.new(val[2]))], val[4], false) }
| '*' '(' embed ')' oliteral           { StructType::Field.new([Parens.new(val[2])], val[4], true) }

packname:
  nameo             { QualifiedIdent.new(nil, nil, val[0]) }
| nameo '.' sym     { QualifiedIdent.new(val[0], val[1], val[2]) }

embed:
 packname

interfacedcl:
  sym indcl          { InterfaceType::Spec.new(val[0], val[1][0], val[1][1]) }
| packname           { InterfaceType::Spec.new(val[0], nil, nil) }
| '(' packname ')'   { InterfaceType::Spec.new(Parens.new(val[1]), nil, nil) }

indcl:
 '(' oarg_type_list ')' fnres  { [Parens.new(val[1]), val[3]] }

/*
 * function arguments.
 */
arg_type:
  name_or_type         { Param.new(val[0], nil) }
| sym name_or_type     { Param.new(val[0], val[1]) }
| sym dotdotdot        { Param.new(val[0], val[1]) }
| dotdotdot            { Param.new(val[0], nil) }

arg_type_list:
  arg_type                       { [val[0]] }
| arg_type_list comma arg_type   { val[0] << val[1] << val[2] }

oarg_type_list:
                   { [] }
| arg_type_list

/*
 * statement
 */
stmt:
                    { Line.new }
| common_dcl
| non_dcl_stmt
| error

non_dcl_stmt:
  simple_stmt
| for_stmt
| switch_stmt
| select_stmt
| label_stmt
| if_stmt
| fall_stmt
| break_stmt
| continue_stmt
| go_stmt
| defer_stmt
| goto_stmt
| return_stmt

label_stmt:
  NAME ':'
  INDENT stmt_list OUTDENT   { StmtLabeled.new(val[0], val[3]) }

fall_stmt:
  FALL                       { StmtFall.new(@token) }

break_stmt:
  BREAK osym                 { StmtBreak.new(val[1]) }

continue_stmt:
  CONTINUE osym              { StmtContinue.new(val[1]) }

go_stmt:
  GO pseudocall                     { StmtGo.new(val[1]) }
| GO '!' go_call                    { StmtGo.new(val[2]) }

go_call:
  '(' ')' fnlitdcl                           { Call.new(val[2], nil, [], false) }
| '(' expr_or_type_list ')' fnliteral        { Call.new(val[3], nil, val[1], false) }
| '(' expr_or_type_list '...' ')' fnliteral  { Call.new(val[4], nil, val[1], false) }

defer_stmt:
  DEFER pseudocall           { StmtDefer.new(val[1]) }

goto_stmt:
  GOTO sym                   { StmtGoto.new(val[1]) }

return_stmt:
  RETURN oexpr_list          { StmtReturn.new(val[1]) }

small_stmt:
  simple_stmt
| FALL                       { StmtFall.new }
| BREAK osym                 { StmtBreak.new(val[1]) }
| CONTINUE osym              { StmtContinue.new(val[1]) }
| GO pseudocall              { StmtGo.new(val[1]) }
| DEFER pseudocall           { StmtDefer.new(val[1]) }
| GOTO sym                   { StmtGoto.new(val[1]) }
| RETURN oexpr_list          { StmtReturn.new(val[1]) }

simple_stmt:
  expr
| expr COP expr                         { Expr.new([val[0]], val[1], [val[2]]) }
| expr_list '=' expr_list               { Expr.new(val[0], val[1], val[2]) }
| expr_list ':=' expr_list              { Expr.new(val[0], val[1], val[2]) }
| expr '++'                             { Expr.new([val[0]], val[1], []) }
| expr '--'                             { Expr.new([val[0]], val[1], []) }

suite_stmt:
  ':' small_stmt_list      { [val[1]] }
| INDENT stmt_list OUTDENT { val[1]   }

small_stmt_list:
  small_stmt                           { [val[0]] }
| small_stmt_list ';' small_stmt       { val[0] << val[2] }

stmt_list:
  stmt                       { [val[0]] }
| stmt_list term stmt        { val[0] << val[1] << val[2] }

sym_list:
  sym                 { [val[0]] }
| sym_list comma sym  { val[0] << val[1] << val[2] }

dcl_name_list:
  sym                       { [val[0]] }
| dcl_name_list comma sym   { val[0] << val[1] << val[2] }

expr_list:
  expr                           { [val[0]] }
| expr_list comma expr           { val[0] << val[1] << val[2] }

expr_or_type_list:
  expr_or_type                             { [val[0]] }
| expr_or_type_list comma expr_or_type     { val[0] << val[1] << val[2] }

/*
 * optional things
 */

ocomma:
| comma

oexpr:
| expr

oexpr_list:
| expr_list

osimple_stmt:
| simple_stmt

oliteral:
| literal

---- header
module Rosetta
---- inner
  include Ast
  attr_reader :lexer

  def parse(code)
    @yydebug = true
    @lexer   = Lexer.new(code)
    @index   = -1
    @lexer.tokenize! # Tokenize the code using our lexer
    do_parse # Kickoff the parsing process
  end

  def tokens
    @lexer.tokens.to_a
  end

  def next_token
    @token = @lexer.tokens[@index+=1]
    @token
  end

  def on_error(error_token_id, error_value, value_stack)
    raise Rosetta::ParseError.new(@token, token_to_str(error_token_id),
      error_value, @lexer, value_stack)
  end
---- footer
end
