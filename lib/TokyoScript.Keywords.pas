unit TokyoScript.Keywords;
{

  TokyoScript (c)2018 Execute SARL
  http://www.execute.Fr

}

interface

uses
  System.SysUtils;

type
  TKeyword = (
    kw_None,
    kwAnd,
    kwArray,
    kwAs,
    kwBegin,
    kwCase,
    kwChr,
    kwClass,
    kwConst,
    kwConstructor,
    kwDestructor,
    kwDiv,
    kwDo,
    kwDownto,
    kwElse,
    kwEnd,
    kwExcept,
    kwExit,
    kwExport,
    kwExternal,
    kwFinalization,
    kwFinally,
    kwFor,
    kwForward,
    kwFunction,
    kwGoto,
    kwIf,
    kwImplementation,
    kwIn,
    kwInherited,
    kwInitialization,
    kwInterface,
    kwIs,
    kwLabel,
    kwMod,
    kwNil,
    kwNot,
    kwOf,
    kwOr,
    kwOrd,
    kwOut,
    kwOverride,
    kwPrivate,
    kwProcedure,
    kwProgram,
    kwProperty,
    kwProtected,
    kwPublic,
    kwPublished,
    kwRecord,
    kwRepeat,
    kwSet,
    kwShl,
    kwShr,
    kwThen,
    kwTo,
    kwTry,
    kwType,
    kwUnit,
    kwUntil,
    kwUses,
    kwVar,
    kwVirtual,
    kwWhile,
    kwWith,
    kwXor
  );
  TKeywords = set of TKeyword;

const
  KEYWORDS: array[TKeyword] of string = (
    '',
    'AND',
    'ARRAY',
    'AS',
    'BEGIN',
    'CASE',
    'CHR',
    'CLASS',
    'CONST',
    'CONSTRUCTOR',
    'DESTRUCTOR',
    'DIV',
    'DO',
    'DOWNTO',
    'ELSE',
    'END',
    'EXCEPT',
    'EXIT',
    'EXPORT',
    'EXTERNAL',
    'FINALIZATION',
    'FINALLY',
    'FOR',
    'FORWARD',
    'FUNCTION',
    'GOTO',
    'IF',
    'IMPLEMENTATION',
    'IN',
    'INHERITED',
    'INITIALIZATION',
    'INTERFACE',
    'IS',
    'LABEL',
    'MOD',
    'NIL',
    'NOT',
    'OF',
    'OR',
    'ORD',
    'OUT',
    'OVERRIDE',
    'PRIVATE',
    'PROCEDURE',
    'PROGRAM',
    'PROPERTY',
    'PROTECTED',
    'PUBLIC',
    'PUBLISHED',
    'RECORD',
    'REPEAT',
    'SET',
    'SHL',
    'SHR',
    'THEN',
    'TO',
    'TRY',
    'TYPE',
    'UNIT',
    'UNTIL',
    'USES',
    'VAR',
    'VIRTUAL',
    'WHILE',
    'WITH',
    'XOR'
  );

function GetKeyword(Str: string): TKeyword;

implementation

const
  KW2: array[0..7] of TKeyword = (
    kwAs,
    kwDo,
    kwIf,
    kwIn,
    kwIs,
    kwOf,
    kwOr,
    kwTo
  );
  KW3: array[0..17] of TKeyword = (
    kwAnd,
    kwChr,
    kwDiv,
    kwEnd,
    kwFor,
    kwMod,
    kwSet,
    kwVar,
    kwNil,
    kwNot,
    kwOrd,
    kwOut,
    kwSet,
    kwShl,
    kwShr,
    kwTry,
    kwVar,
    kwXor
  );
  KW4: array[0..8] of TKeyword = (
    kwCase,
    kwElse,
    kwExit,
    kwGoto,
    kwThen,
    kwType,
    kwUnit,
    kwUses,
    kwWith
  );
  KW5: array[0..6] of TKeyword = (
    kwArray,
    kwBegin,
    kwClass,
    kwConst,
    kwLabel,
    kwUntil,
    kwWhile
  );
  KW6: array[0..5] of TKeyword = (
    kwDownto,
    kwExcept,
    kwExport,
    kwPublic,
    kwRecord,
    kwRepeat
  );
  KW7: array[0..4] of TKeyword = (
    kwFinally,
    kwForward,
    kwPrivate,
    kwProgram,
    kwVirtual
  );
  KW8: array[0..3] of TKeyword = (
    kwExternal,
    kwFunction,
    kwOverride,
    kwProperty
  );
  KW9: array[0..4] of TKeyword = (
    kwInherited,
    kwInterface,
    kwProcedure,
    kwProtected,
    kwPublished
  );
  KW10: array[0..0] of TKeyword = (
    kwDestructor
  );
  KW11: array[0..0] of TKeyword = (
    kwConstructor
  );
  KW12: array[0..0] of TKeyword = (
    kwFinalization
  );
  KW14: array[0..1] of TKeyword = (
    kwImplementation,
    kwInitialization
  );

function IsKeyword(const AKeywords: array of TKeyword; const AStr: string): TKeyword;
var
  Index: Integer;
begin
  for Index := 0 to Length(AKeywords) - 1 do
  begin
    Result := AKeywords[Index];
    if KEYWORDS[Result] = AStr then
      Exit;
  end;
  Result := kw_None;
end;

function GetKeyword(Str: string): TKeyword;
var
  Index: Integer;
begin
  Str := UpperCase(Str);
  case Length(Str) of
    2 : Result := IsKeyword(KW2, Str);
    3 : Result := IsKeyword(KW3, Str);
    4 : Result := IsKeyword(KW4, Str);
    5 : Result := IsKeyword(KW5, Str);
    6 : Result := IsKeyword(KW6, Str);
    7 : Result := IsKeyword(KW7, Str);
    8 : Result := IsKeyword(KW8, Str);
    9 : Result := IsKeyword(KW9, Str);
   10 : Result := IsKeyword(KW10, Str);
   11 : Result := IsKeyword(KW11, Str);
   12 : Result := IsKeyword(KW12, Str);
   14 : Result := IsKeyword(KW14, Str);
  else
    Result := kw_None;
  end;
end;

end.
