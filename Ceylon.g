grammar Ceylon;

options {
    //backtrack=true;
    memoize=true;
    output=AST;
}

tokens {
    ANNOTATION;
    ANNOTATION_LIST;
    MEMBER_DECL;
    TYPE_DECL;
    ABSTRACT_MEMBER_DECL;
    ALIAS_DECL;
    ANNOTATION_NAME;
    ARG_LIST;
    ARG_NAME;
    ANON_METH;
    ATTRIBUTE_SETTER;
    BREAK_STMT;
    CALL_EXPR;
    CATCH_BLOCK;
    CATCH_STMT;
    CHAR_CST;
    CLASS_BODY;
    CLASS_DECL;
    OBJECT_DECL;
    CONDITION;
    DO_BLOCK;
    DO_ITERATOR;
    EXPR;
    FINALLY_BLOCK;
    FORMAL_PARAMETER;
    FORMAL_PARAMETER_LIST;
    IF_FALSE;
    IF_STMT;
    IF_TRUE;
    IMPORT_DECL;
    IMPORT_LIST;
    IMPORT_WILDCARD;
    IMPORT_PATH;
    IMPORT_ELEM;
    INIT_EXPR;
    INTERFACE_DECL;
    MEMBER_NAME;
    MEMBER_TYPE;
    NAMED_ARG;
    SEQ_ARG;
    NIL;
    RET_STMT;
    STMT_LIST;
    THROW_STMT;
    RETRY_STMT;
    TRY_BLOCK;
    TRY_CATCH_STMT;
    TRY_RESOURCE;
    TRY_STMT;
    TYPE_ARG_LIST;
    TYPE_NAME;
    TYPE_PARAMETER_LIST;
    WHILE_BLOCK;
    WHILE_STMT;
    SWITCH_STMT;
    SWITCH_EXPR;
    SWITCH_CASE_LIST;
    CASE_ITEM;
    EXPR_LIST;
    CASE_DEFAULT;
    TYPE_CONSTRAINT_LIST;
    TYPE;
    TYPE_CONSTRAINT;
    TYPE_DECL;
    SATISFIES_LIST;
    ABSTRACTS_LIST;
    SUBSCRIPT_EXPR;
    LOWER_BOUND;
    UPPER_BOUND;
    SELECTOR_LIST;
    TYPE_VARIANCE;
    TYPE_PARAMETER;
    STRING_CONCAT;
    INT_CST;
    FLOAT_CST;
    STRING_CST;
    QUOTE_CST;
    FOR_STMT;
    FOR_ITERATOR;
    FAIL_BLOCK;
    LOOP_BLOCK;
    FOR_CONTAINMENT;
    ENUM_LIST;
    SUPERCLASS;
    POSTFIX_EXPR;
    EXISTS_EXPR;
    NONEMPTY_EXPR;
    IS_EXPR;
    GET_EXPR;
    SET_EXPR;
    //PRIMARY;
}

@parser::header { package com.redhat.ceylon.compiler.parser; }
@lexer::header { package com.redhat.ceylon.compiler.parser; }

compilationUnit
    : importDeclaration*
      declaration+
      EOF
    -> ^(IMPORT_LIST importDeclaration*)
       declaration+
    ;

typeDeclaration
    : classDeclaration
    -> ^(CLASS_DECL classDeclaration)
    | interfaceDeclaration
    -> ^(INTERFACE_DECL interfaceDeclaration)
    | aliasDeclaration
    -> ^(ALIAS_DECL aliasDeclaration)
    | objectDeclaration
    -> ^(OBJECT_DECL objectDeclaration)
    ;

importDeclaration
    : 'import' packagePath '{' importElements '}'
      -> ^(IMPORT_DECL packagePath importElements)
    ;

importElements
    : importElement (',' importElement)* (',' importWildcard)?
    | importWildcard
    ;

importElement
    : 'implicit'? importAlias? importedName
    -> ^(IMPORT_ELEM 'implicit'? importAlias? importedName)
    ;

importWildcard
    : '...'
    -> ^(IMPORT_WILDCARD)
    ;

importAlias
    : 'local' importedName '='
    -> ^(ALIAS_DECL importedName)
    ;

importedName
    : typeName | memberName
    ;

packagePath
    : LIDENTIFIER ('.' LIDENTIFIER)*
    -> ^(IMPORT_PATH LIDENTIFIER*)
    ;
    
block
    : '{' declarationOrStatement* directiveStatement? '}'
    -> ^(STMT_LIST declarationOrStatement* directiveStatement?)
    ;

/*inlineClassDeclaration
    : 'new' 
      annotations?
      type
      positionalArguments?
      satisfiedTypes?
      inlineClassBody
    ;

inlineClassBody
    : '{' declarationOrStatement* '}'
    ;*/

declarationOrStatement
    : (annotatedDeclarationStart) => declaration | statement
    ;

//TODO: I don't understand why we need to distinguish
//      methods from attributes at this stage. Why not
//      do it later?
declaration
    :
    annotations?
    ( 
        memberDeclaration 
      -> ^(MEMBER_DECL memberDeclaration annotations?)
      | typeDeclaration 
      -> ^(TYPE_DECL typeDeclaration annotations?)
    )
/*    (((memberHeader memberParameters) => 
            (mem=memberDeclaration 
                -> ^(METHOD_DECL $mem $ann?)))
    | (mem=memberDeclaration 
            -> ^(MEMBER_DECL $mem $ann?))
    | (typ=typeDeclaration 
            -> ^(TYPE_DECL $typ $ann?))
    | (inst=instance
            -> ^(INSTANCE $inst $ann?)))*/
    ;

//special rule for syntactic predicates
annotatedDeclarationStart
    : declarationStart
    | annotationName
      ( 
          declarationStart
        | annotationName
        | annotationArguments annotatedDeclarationStart
      )
    ;

declarationStart
    : declarationKeyword | type '...'? LIDENTIFIER
    ;

declarationKeyword
    : 'local' 
    | 'assign' 
    | 'void'
    | 'interface' 
    | 'class' 
    | 'object'
    ;

//by making these things keywords, we reduce the amount of
//backtracking
/*declarationAnnotation
    : 'abstract'
    | 'default'
    | 'override'
    | 'fixed'
    | 'mutable'
    | 'extension'
    | 'volatile'
    //| 'small'
    | visibility
    ;

visibility
    : 'public'
    | 'module'
    | 'package'
    | 'private'
    | 'protected'
    ;*/

statement 
    : specificationOrExpressionStatement
    | controlStructure
    //| '...'
    ;

//Note that this rule is way too permissive,
//and we need to do a lot more work later in
//the compiler
specificationOrExpressionStatement
    : expression specifier? ';'!
    ;

directiveStatement
    : directive (';'!)?
    ;

directive
    : returnDirective
    | throwDirective
    | breakDirective
    | continueDirective
    | retryDirective
    ;

returnDirective
    : 'return' expression?
    -> ^(RET_STMT expression?)
    ;

throwDirective
    : 'throw' expression? //| '...'
    -> ^(THROW_STMT expression?)
    ;

breakDirective
    : 'break' expression?
    -> ^(BREAK_STMT expression?)
    ;

continueDirective
    : 'continue'
    ;

retryDirective
    : 'retry'
    -> ^(RETRY_STMT)
    ;

memberDeclaration
    : memberHeader memberDefinition
    ;

memberHeader
    : memberType memberName
    -> ^(MEMBER_TYPE memberType) memberName
    | 'assign' memberName
    -> ^(ATTRIBUTE_SETTER memberName)
    ;

memberType
    : type | 'void' | 'local'
    ;

memberParameters
    : typeParameters? formalParameters+ extraFormalParameters typeClass? typeConstraints?
    ;

//TODO: should we allow the shortcut style of method
//      definition for a method or getter which returns
//      a parExpression, just like we do for Smalltalk
//      style parameters below?
memberDefinition
    : memberParameters?
      ( /*'...' |*/ block | (specifier | initializer)? ';'! )
    ;
    
interfaceDeclaration
    :
        'interface'!
        typeName
        typeParameters?
        caseTypes?
        typeClass?
        satisfiedTypes?
        typeConstraints?
        (classBody | typeSpecifier)
    ;

interfaceBody
    : '{'! declaration* '}'!
    ;

classDeclaration
    :
        'class'!
        typeName
        typeParameters?
        formalParameters
        extraFormalParameters
        caseTypes?
        typeClass?
        extendedType?
        satisfiedTypes?
        typeConstraints?
        (classBody | typeSpecifier | ';')
    ;

objectDeclaration
    :
        'object'!
        memberName
        extendedType?
        satisfiedTypes?
        classBody
    ;

classBody
    : '{' declarationOrStatement* '}'
    -> ^(STMT_LIST declarationOrStatement*)
 //    -> ^(CLASS_BODY ^(STMT_LIST $stmts))
    ;

extendedType
    : 'extends' type positionalArguments
    -> ^(SUPERCLASS type positionalArguments) 
    ;

satisfiedTypes
    : 'satisfies' type (',' type)*
    -> ^(SATISFIES_LIST type+)
    ;

abstractedType
    : 'abstracts' type
    -> ^(ABSTRACTS_LIST type)
    ;
    
caseTypes
    : 'of' caseType (',' caseType)*
    -> ^(ABSTRACTS_LIST caseType+)
    ;

caseType 
    : type 
    //| (annotations? 'case' memberName) => annotations? 'case' memberName 
    | memberName
    ;

typeClass
    : 'is' type (',' type)* 
    ;

typeConstraint
    : 'given' typeName formalParameters? typeClass? satisfiedTypes? abstractedType?
    -> ^(TYPE_CONSTRAINT typeName formalParameters? satisfiedTypes? abstractedType?)
    ;
    
typeConstraints
    : typeConstraint+
    -> ^(TYPE_CONSTRAINT_LIST typeConstraint+)
    ;

type
    : typeNameWithArguments ('.' typeNameWithArguments)* abbreviation*
    -> ^(TYPE typeNameWithArguments+ abbreviation*)
    | 'subtype' abbreviation*
    -> ^(TYPE 'subtype' abbreviation*)
    ;

abbreviation
    : '?' | ARRAY | LBRACKET dimension ']'
    ;


typeNameWithArguments
    : typeName typeArguments?
    ;
    
annotations
    : annotation+
    -> ^(ANNOTATION_LIST annotation+)
    ;

//TODO: we could minimize backtracking by limiting the 
//kind of expressions that can appear as arguments to
//the annotation
annotation
    : annotationName annotationArguments?
    -> ^(ANNOTATION annotationName annotationArguments?)
    ;

annotationArguments
    : arguments | ( nonstringLiteral | stringLiteral )+
    ;

typeName
    : UIDENTIFIER
    -> ^(TYPE_NAME UIDENTIFIER)
    ;

annotationName
    : LIDENTIFIER
    -> ^(ANNOTATION_NAME LIDENTIFIER)
    ;

memberName 
    : LIDENTIFIER
    -> ^(MEMBER_NAME LIDENTIFIER)
    ;

typeArguments
    : '<' typeArgument (',' typeArgument)* '>'
    -> ^(TYPE_ARG_LIST typeArgument+)
    ;

typeArgument
    : type '...'? | '#'! dimension
    ;

dimension
    : dimensionTerm ('+' dimensionTerm)*
    ;

dimensionTerm
    : (NATURALLITERAL '*')* dimensionAtom
    ;

dimensionAtom
    : NATURALLITERAL 
    | memberName 
    | parenDimension
    ;

parenDimension
    : '(' dimension ')'
    ;

typeParameters
    : '<' typeParameter (',' typeParameter)* '>'
    -> ^(TYPE_PARAMETER_LIST typeParameter+)
    ;

typeParameter
    : ordinaryTypeParameter '...'? | '#'! dimensionalTypeParameter
    ;

ordinaryTypeParameter
    : variance? typeName
    -> ^(TYPE_PARAMETER ^(TYPE_VARIANCE variance)? typeName)
    ;

variance
    : 'in' | 'out'
    ;
    
dimensionalTypeParameter
    : memberName
    -> ^(TYPE_PARAMETER memberName)
    ;
    
initializer
    : ':=' expression
    -> ^(INIT_EXPR expression)
    ;

specifier
    : '=' expression
    -> ^(INIT_EXPR expression)
    ;

typeSpecifier
    : '='! type ';'!
    ;

nonstringLiteral
    : NATURALLITERAL
    -> ^(INT_CST NATURALLITERAL)
    | FLOATLITERAL
    -> ^(FLOAT_CST FLOATLITERAL)
    | QUOTEDLITERAL
    -> ^(QUOTE_CST QUOTEDLITERAL)
    | CHARLITERAL
    -> ^(CHAR_CST CHARLITERAL)
    ;

stringExpression
    : (SIMPLESTRINGLITERAL (interpolatedExpressionStart|SIMPLESTRINGLITERAL)) 
        => stringTemplate
    -> ^(STRING_CONCAT stringTemplate)
    | stringLiteral
    ;

stringLiteral
    : SIMPLESTRINGLITERAL
    -> ^(STRING_CST SIMPLESTRINGLITERAL)
    ;

stringTemplate
    : SIMPLESTRINGLITERAL 
    ( (interpolatedExpressionStart|SIMPLESTRINGLITERAL) => 
        ( (interpolatedExpressionStart) => expression )? 
        SIMPLESTRINGLITERAL 
    )+
    ;

//special rule for syntactic predicates
//this includes every token that could be 
//the beginning of an expression, except 
//for SIMPLESTRINGLITERAL and '['
interpolatedExpressionStart
    : '(' 
    | '{'
    | LIDENTIFIER 
    | UIDENTIFIER 
    | selfReference 
    | nonstringLiteral
    | prefixOperator
    ;

prefixOperator
    : '$' | '-' |'++' | '--' | '~'
    ;

expression
    : assignmentExpression
    -> ^(EXPR assignmentExpression)
    ;

//Even though it looks like this is non-associative
//assignment, it is actually right associative because
//assignable can be an assignment
//Note that = is not really an assignment operator, but 
//can be used to init locals
assignmentExpression
    : disjunctionExpression
      ((':='^ | '.='^ | '+='^ | '-='^ | '*='^ | '/='^ | '%='^ | '&='^ | '|='^ | '^='^ | '~='^ | '&&='^ | '||='^ | '?='^) expression )?
    ;

//should '^' have a higher precedence?
disjunctionExpression
    : conjunctionExpression 
      ('||'^ conjunctionExpression)?
    ;

conjunctionExpression
    : logicalNegationExpression 
      ('&&'^ logicalNegationExpression)*
    ;

logicalNegationExpression
    : '!'^ logicalNegationExpression
    | equalityExpression
    ;

equalityExpression
    : comparisonExpression
      (('=='^|'!='^|'==='^) comparisonExpression)?
    ;

comparisonExpression
    : existenceEmptinessExpression
      (('<=>'^ |'<'^ |'>'^ |'<='^ |'>='^ |'in'^ |'is'^|'extends'^|'satisfies'^) existenceEmptinessExpression)?
    ;

/*
existenceEmptinessExpression
    : e=defaultExpression 
    ('exists' -> ^(EXISTS_EXPR $e) 
     | 'nonempty' -> ^(NONEMPTY_EXPR $e)
     | -> $e)
    ;
*/

existenceEmptinessExpression
    : e=defaultExpression
       (('exists' -> ^(EXISTS_EXPR $e))
        | ('nonempty' -> ^(NONEMPTY_EXPR $e)) )?
     -> $e
    ;

defaultExpression
    : rangeIntervalEntryExpression 
      ('?'^ defaultExpression)?
    ;

//I wonder if it would it be cleaner to give 
//'..' a higher precedence than '->'

rangeIntervalEntryExpression
    : additiveExpression
      (('..'^ | '->'^) additiveExpression)?
    ;

additiveExpression
    : multiplicativeExpression
      (('+'^ | '-'^ | '|'^ | '^'^ | '~'^) multiplicativeExpression)*
    ;

multiplicativeExpression 
    : negationComplementExpression
      (('*'^ | '/'^ | '%'^ | '&'^) negationComplementExpression)*
    ;

negationComplementExpression 
    : ('-'^ | '~'^ | '$'^) negationComplementExpression
    | exponentiationExpression
    ;

exponentiationExpression
    : incrementDecrementExpression 
      ('**'^ incrementDecrementExpression)?
    ;

incrementDecrementExpression
    : ('++'^ | '--'^) incrementDecrementExpression
    | primary
    ;

selfReference
    : 'this' //typeName?
    | 'super'
    | 'outer'
    ;

enumeration
    : '{' expressions '}'
    -> ^(ENUM_LIST expressions?)
    ;
    
primary
options {backtrack=true;}
/*
    : b=base 
    ((selector+
     -> ^(SELECTOR_LIST $b selector+))
    | -> $b
    )
*/
// This backtracking predicate really shouldn't be necessary, and the ANTLR
// book seems to agree, but the above doesn't work.
//    : base selector+ -> ^(SELECTOR_LIST base selector+)
//    | base
    : //base selector* 
    base selector+
    -> ^(EXPR base selector*)
    | base
    ;

postfixOperator
    : '--' | '++'
    ;	

base 
    : nonstringLiteral
    | stringExpression
    | parExpression
    | enumeration
    | selfReference
    | nameAndTypeArguments
    //| inlineClassDeclaration
    ;
    
selector 
    : memberSelector
    | argumentsWithFunctionalArguments
    -> ^(CALL_EXPR argumentsWithFunctionalArguments)
    | elementSelector
    | postfixOperator 
    -> ^(POSTFIX_EXPR postfixOperator)
    ;

memberSelector
    : ('.' | '?.' | SPREAD) ( nameAndTypeArguments | 'outer' )
    ;

nameAndTypeArguments
    : typeNameAndTypeArguments | memberNameAndTypeArguments
    ;

typeNameAndTypeArguments
    : ( typeName | 'subtype' ) 
      ( (typeArguments) => typeArguments )?
      //(ARRAY | ('?') => '?' )*
    ;

memberNameAndTypeArguments
    : memberName 
      ( (typeArguments) => typeArguments )?
    ;

elementSelector
    : '?'? LBRACKET elementsSpec ']'
    -> ^(SUBSCRIPT_EXPR '?'? elementsSpec)
    ;

elementsSpec
    : additiveExpression ( '...' | '..' additiveExpression )?
    -> ^(LOWER_BOUND additiveExpression) ^(UPPER_BOUND additiveExpression)?	
    ;

argumentsWithFunctionalArguments
    : arguments functionalArgument*
    ;
    
arguments
    : positionalArguments | namedArguments
    ;
    
namedArgument
    : namedSpecifiedArgument | namedFunctionalArgument
    ;

namedFunctionalArgument
    : (formalParameterType|'local') parameterName formalParameters* block
    ;

namedSpecifiedArgument
    : parameterName specifier ';'!
    ;

namedArgumentStart
    : LIDENTIFIER '=' 
    | declarationStart
    ;

parameterName
    : LIDENTIFIER
    -> ^(ARG_NAME LIDENTIFIER)
    ;

namedArguments
    : '{' ((namedArgumentStart) => namedArgument)* expressions? '}'
    -> ^(ARG_LIST ^(NAMED_ARG namedArgument)* ^(SEQ_ARG expressions)?)
    ;

parExpression 
    : '('! expression ')'!
    ;
    
positionalArguments
    : '(' ( positionalArgument (',' positionalArgument)* )? ')'
    -> ^(ARG_LIST positionalArgument*)
    ;

positionalArgument
    : (declarationStart) => specialArgument
    | expression
    ;

//a smalltalk-style parameter to a positional parameter
//invocation
functionalArgument
    : functionalArgumentHeader functionalArgumentDefinition
    -> ^(NAMED_ARG functionalArgumentHeader? ^(ANON_METH functionalArgumentDefinition))
    ;
    
functionalArgumentHeader
    : parameterName
    -> ^(ARG_NAME parameterName)
    /*| 'case' '(' expressions ')'
    -> ^(CASE_ITEM expressions)*/
    ;

functionalArgumentDefinition
    : ( (formalParametersStart) => formalParameters )? 
      ( block | parExpression /*| literal | specialValue*/ )
    ;

specialArgument
    : (type | 'local') memberName (containment | specifier)
    //| isCondition
    //| existsCondition
    ;

extraFormalParameters
    : extraFormalParameter*
    -> ^(FORMAL_PARAMETER_LIST ^(FORMAL_PARAMETER extraFormalParameter)*)?
    ;

formalParameters
    : '(' (formalParameter (',' formalParameter)*)? ')'
    -> ^(FORMAL_PARAMETER_LIST ^(FORMAL_PARAMETER formalParameter)*)
    ;

//special rule for syntactic predicates
//be careful with this one, since it 
//matches "()", which can also be an 
//argument list
formalParametersStart
    : '(' ( annotatedDeclarationStart | ')' )
    ;
    
// FIXME: This accepts more than the language spec: named arguments
// and varargs arguments can appear in any order.  We'll have to
// enforce the rule that the ... appears at the end of the parapmeter
// list in a later pass of the compiler.
formalParameter
    : annotations? formalParameterType (parameterName | 'this') formalParameters*
      ( valueFormalParameter | iteratedFormalParameter | (specifiedFormalParameterStart) => specifiedFormalParameter )? 
      specifier?
    ;

valueFormalParameter
    : '->' type parameterName
    ;

iteratedFormalParameter
    : 'in' type parameterName
    ;

specifiedFormalParameter
    : '=' type parameterName
    ;

specifiedFormalParameterStart
    : '=' declarationStart
    ;

extraFormalParameter
    : formalParameterType parameterName formalParameters*
    ;

formalParameterType
    : type '...'? | 'void'
    ;

// Control structures.

condition
    : expression | existsCondition | nonemptyCondition | isCondition
    ;

existsCondition
    : 'exists' controlVariableOrExpression
    -> ^(EXISTS_EXPR controlVariableOrExpression)
    ;
    
nonemptyCondition
    : 'nonempty' controlVariableOrExpression
    -> ^(NONEMPTY_EXPR controlVariableOrExpression)
    ;

isCondition
    : 'is' type ( (memberName '=') => memberName specifier | expression )
    -> ^(IS_EXPR type memberName? specifier? expression?)
    ;

controlStructure
    : ifElse | switchCaseElse | simpleWhile | doWhile | forFail | tryCatchFinally
    ;
    
ifElse
    : ifBlock elseBlock?
    -> ^(IF_STMT ifBlock elseBlock?)
    ;

ifBlock
    : 'if' '(' condition ')' block
    -> ^(CONDITION condition) ^(IF_TRUE block)
    ;

elseBlock
    : 'else' (ifElse | block)
    -> ^(IF_FALSE block? ifElse?)
    ;

switchCaseElse
    : switchHeader ( '{' cases '}' | cases )
    -> ^(SWITCH_STMT switchHeader cases)
    ;

switchHeader
    : 'switch' '(' expression ')'
    -> ^(SWITCH_EXPR expression)
    ;

cases 
    : caseItem+ defaultCaseItem?
    -> ^(SWITCH_CASE_LIST caseItem+ defaultCaseItem?)
    ;
    
caseItem
    : 'case' '(' caseCondition ')' block
    -> ^(CASE_ITEM caseCondition block)
    ;

defaultCaseItem
    : 'else' block
    -> ^(CASE_DEFAULT block)
    ;

caseCondition
    : expressions | isCaseCondition
    ;

expressions
    : expression (',' expression)*
    -> ^(EXPR_LIST expression+)
    ;

isCaseCondition
    : 'is' type
    -> ^(IS_EXPR type)
    ;

forFail
    : forBlock failBlock?
    -> ^(FOR_STMT forBlock failBlock?)
    ;

forBlock
    : 'for' '(' forIterator ')' block
    -> forIterator ^(LOOP_BLOCK block)
    ;

failBlock
    : 'fail' block
    -> ^(FAIL_BLOCK block)
    ;

forIterator
    : variable ('->' variable)? containment
    -> ^(FOR_ITERATOR variable+ containment)
    ;
    
containment
    : 'in' expression
    -> ^(FOR_CONTAINMENT expression)
    ;
    
doWhile
    : doBlock loopCondition ';'
    -> ^(WHILE_STMT doBlock loopCondition)
    ;

simpleWhile
    : loopCondition whileBlock
    -> ^(WHILE_STMT loopCondition whileBlock)
    ;

loopCondition
    : 'while' '(' condition ')'
    -> ^(CONDITION condition)
    ;

whileBlock
    : block
    -> ^(WHILE_BLOCK block)
    ;

doBlock
    : 'do' block
    -> ^(DO_BLOCK block)
    ;

tryCatchFinally
    : tryBlock catchBlock* finallyBlock?
    -> ^(TRY_CATCH_STMT tryBlock catchBlock* finallyBlock?)
    ;

tryBlock
    : 'try' ('(' resource ')')? block
    -> ^(TRY_STMT resource? ^(TRY_BLOCK block))
    ;

catchBlock
    : 'catch' '(' variable ')' block
    -> ^(CATCH_STMT variable ^(CATCH_BLOCK block))
    ;

finallyBlock
    : 'finally' block
    -> ^(FINALLY_BLOCK block)
    ;

resource
    : controlVariableOrExpression
    -> ^(TRY_RESOURCE controlVariableOrExpression)
    ;

controlVariableOrExpression
    : (declarationStart) => variable specifier 
    | expression
    ;

variable
    : (type | 'local') memberName formalParameters*
    ;

// Lexer

fragment
Digits
    : ('0'..'9')+ ('_' ('0'..'9')+)*
    ;

fragment 
Exponent    
    : ( 'e' | 'E' ) ( '+' | '-' )? ( '0' .. '9' )+ 
    ;

fragment
Magnitude
    : 'k' | 'M' | 'G' | 'T'
    ;

fragment
FractionalMagnitude
    : 'm' | 'u' | 'n' | 'p'
    ;
    
fragment ELLIPSIS
    :   '...'
    ;

fragment RANGE
    :   '..'
    ;

fragment DOT
    :   '.'
    ;

fragment FLOATLITERAL :;
NATURALLITERAL
    : Digits
      ( Magnitude | { input.LA(2) != '.' }? => '.' Digits (Exponent|Magnitude|FractionalMagnitude)? { $type = FLOATLITERAL; } )?
    | '.' ( '..' { $type = ELLIPSIS; } | '.'  { $type = RANGE; } | { $type = DOT; } )
    ;
    
fragment SPREAD :;
fragment LBRACKET :;
fragment ARRAY :;
BRACKETS
    : '['
    ( 
      ( { input.LA(1) == ']' && input.LA(2) == '.' }? => '].' { $type = SPREAD; } )
    | ( { input.LA(1) == ']' }? => ']' { $type = ARRAY; } )
    | { $type = LBRACKET; } 
    )
    ;    

CHARLITERAL
    :   '`' ( ~ NonCharacterChars | EscapeSequence ) '`'
    ;

fragment
NonCharacterChars
    :    '`' | '\\' | '\t' | '\n' | '\f' | '\r' | '\b'
    ;

QUOTEDLITERAL
    :   '\'' QuotedLiteralPart '\''
    ;

fragment
QuotedLiteralPart
    : ~('\'')
    ;

SIMPLESTRINGLITERAL
    :   '"' StringPart '"'
    ;

fragment
NonStringChars
    :    '\\' | '"'
    ;

fragment
StringPart
    : ( ~ /* NonStringChars*/ ('\\' | '"')
    | EscapeSequence) *
    ;
    
fragment
EscapeSequence 
    :   '\\' 
        (
            'b'
        |   't'
        |   'n'
        |   'f'
        |   'r'
        |   '\\'
        |   '"'
        |   '\''
        |   '`'
        )
    ;

WS  
    :   (
             ' '
        |    '\r'
        |    '\t'
        |    '\u000C'
        |    '\n'
        ) 
        {
            skip();
        }          
    ;

LINE_COMMENT
    :   '//' ~('\n'|'\r')*  ('\r\n' | '\r' | '\n') 
        {
            skip();
        }
    |   '//' ~('\n'|'\r')*
        {
            skip();
        }
    ;   

MULTI_COMMENT
    :   '/*'
        {
            $channel=HIDDEN;
        }
        (    ~('/'|'*')
        |    ('/' ~'*') => '/'
        |    ('*' ~'/') => '*'
        |    MULTI_COMMENT
        )*
        '*/'
        ;
ABSTRACTS
    : 'abstracts'
    ;

ASSIGN
    :   'assign'
    ;
    
BREAK
    :   'break'
    ;

CASE
    :   'case'
    ;

CATCH
    :   'catch'
    ;

CLASS
    :   'class'
    ;

CONTINUE
    :   'continue'
    ;

DO
    :   'do'
    ;
    
ELSE
    :   'else'
    ;            

EXISTS
    :   'exists'
    ;

EXTENDS
    :   'extends'
    ;

FINALLY
    :   'finally'
    ;

FOR
    :   'for'
    ;

FAIL
    :   'fail'
    ;

GIVEN
    :   'given'
    ;

IF
    :   'if'
    ;

SATISFIES
    :   'satisfies'
    ;

IMPORT
    :   'import'
    ;

IMPLICIT
    :   'implicit'
    ;

INTERFACE
    :   'interface'
    ;

LOCAL
    :   'local'
    ;

NONEMPTY
    :   'nonempty'
    ;

RETURN
    :   'return'
    ;

SUPER
    :   'super'
    ;

SWITCH
    :   'switch'
    ;

THIS
    :   'this'
    ;

OUTER
    :   'outer'
    ;

OBJECT
    :   'object'
    ;

OF
    :   'of'
    ;

SUBTYPE
    :   'subtype'
    ;

THROW
    :   'throw'
    ;

TRY
    :   'try'
    ;

RETRY
    : 'retry'
    ;

UNION
    : 'union'
    ;

VOID
    :   'void'
    ;

WHILE
    :   'while'
    ;

LPAREN
    :   '('
    ;

RPAREN
    :   ')'
    ;

LBRACE
    :   '{'
    ;

RBRACE
    :   '}'
    ;

RBRACKET
    :   ']'
    ;

SEMI
    :   ';'
    ;

COMMA
    :   ','
    ;

EQ
    :   '='
    ;

RENDER
    :   '$'
    ;

NOT
    :   '!'
    ;

BITWISENOT
    :   '~'
    ;

QMARK
    :   '?'
    ;

COLON
    :   ':'
    ;
    
COLONEQ
    :   ':='
    ;

EQEQ
    :   '=='
    ;

IDENTICAL
    :   '==='
    ;

AND
    :   '&&'
    ;

OR
    :   '||'
    ;

INCREMENT
    :   '++'
    ;

DECREMENT
    :   '--'
    ;

PLUS
    :   '+'
    ;

MINUS
    :   '-'
    ;

TIMES
    :   '*'
    ;

DIVIDED
    :   '/'
    ;

BITWISEAND
    :   '&'
    ;

BITWISEOR
    :   '|'
    ;

BITWISEXOR
    :   '^'
    ;

REMAINDER
    :   '%'
    ;

NOTEQ
    :   '!='
    ;

GT
    :   '>'
    ;

LT
    :   '<'
    ;        

GTEQ
    :   '>='
    ;

LTEQ
    :   '<='
    ;        

ENTRY
    :   '->'
    ;
    
COMPARE
    :   '<=>'
    ;
    
IN
    :   'in'
    ;

IS
    :   'is'
    ;

HASH
    :   '#'
    ;

QMARKDOT
    :    '?.'
    ;

POWER
    :    '**'
    ;

DOTEQ
    :   '.='
    ;

PLUSEQ
    :   '+='
    ;

MINUSEQ
    :   '-='
    ;

TIMESEQ
    :   '*='
    ;

DIVIDEDEQ
    :   '/='
    ;

BITWISEANDEQ
    :   '&='
    ;

BITWISEOREQ
    :   '|='
    ;

BITWISEXOREQ
    :   '^='
    ;

BITWISNOTEQ
    :   '~='
    ;
REMAINDEREQ
    :   '%='
    ;

QMARKEQ
    :   '?='
    ;

ANDEQ
    :   '&&='
    ;

OREQ
    :   '||='
    ;

LIDENTIFIER 
    :   LIdentifierPart IdentifierPart*
    ;

UIDENTIFIER 
    :   UIdentifierPart IdentifierPart*
    ;

// FIXME: Unicode identifiers
fragment
LIdentifierPart
    :   '_'
    |   'a'..'z'
    ;       
                       
// FIXME: Unicode identifiers
fragment
UIdentifierPart
    :   'A'..'Z'
    ;       
                       
fragment 
IdentifierPart
    :   LIdentifierPart 
    |   UIdentifierPart
    |   '0'..'9'
    ;