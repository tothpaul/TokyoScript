unit TokyoScript.Chars;
{

  TokyoScript (c)2018 Execute SARL
  http://www.execute.Fr

}
interface

type
  TCharType = (
  // Char to CharType
    ctNull,        // 0
    ctBinary,      // 1..8, 11..12, 14..31
    ctPadding,     // 9, ' '
    ctLineFeed,    // 10
    ctReturn,      // 13
    ctDigit,       // '0'..'9'
    ctAlpha,       // 'a'..'z', 'A'..'Z', '_'
    ctExclamat,    // '!'
    ctDoubleQuote, // '"'
    ctSharp,       // '#'
    ctDollar,      // '$'
    ctPercent,     // '%'
    ctAmpersand,   // '&'
    ctSimpleQuote, //  '
    ctLParent,     // '('
    ctRParent,     // ')'
    ctStar,        // '*'
    ctPlus,        // '+'
    ctComma,       // ','
    ctMinus,       // '-'
    ctDot,         // '.'
    ctSlash,       // '/'
    ctColon,       // ':'
    ctSemiColon,   // ';'
    ctLT,          // '<'
    ctEQ,          // '='
    ctGT,          // '>'
    ctQuestion,    // '?'
    ctAt,          // '@'
    ctLBracket,    // '['
    ctBackSlash,   // '\'
    ctRBracket,    // ']'
    ctPower,       // '^'
    ctGrave,       // '`'
    ctLBrace,      // '{'
    ctPipe,        // '|'
    ctRBrace,      // '}'
    ctTilde,       // '~'

    ctAnsi,        // > 127
    ctUnicode,     // > 255

  // more types
    ctNone,
    ctAssign,      // ':='
    ctGE,          // '>='
    ctLE,          // '<='
    ctNE,          // '<>'
    ctRange,       // '..'
    ctIdent,       // ctApha + [ctAlpha|dtDigits]*
    ctKeyword,
    ctChar,        // #[$]123
    ctHexa,        // $xxx
    ctNumber,      // 123
    ctReal,        // 1.23
    ctString       // 'hello'
  );

  TCharTypes = set of TCharType;

function GetCharType(c: Char): TCharType;

implementation

const
  CHARTYPES : array[#0..#126] of TCharType = (
    ctNull,             // 0
    ctBinary, ctBinary, ctBinary, ctBinary, // 1..8
    ctBinary, ctBinary, ctBinary, ctBinary,
    ctPadding,          //  9
    ctLineFeed,         // 10
    ctBinary, ctBinary, // 11, 12
    ctReturn,           // 13
    ctBinary, ctBinary, ctBinary, ctBinary, ctBinary, ctBinary, // 14..31
    ctBinary, ctBinary, ctBinary, ctBinary, ctBinary, ctBinary,
    ctBinary, ctBinary, ctBinary, ctBinary, ctBinary, ctBinary,
    ctPadding,          // 32
    ctExclamat,         // !
    ctDoubleQuote,      // "
    ctSharp,            // #
    ctDollar,           // $
    ctPercent,          // %
    ctAmpersand,        // &
    ctSimpleQuote,      // '
    ctLParent,          // (
    ctRParent,          // )
    ctStar,             // *
    ctPlus,             // +
    ctComma,            // ,
    ctMinus,            // -
    ctDot,              // .
    ctSlash,            // /
    ctDigit, ctDigit, ctDigit, ctDigit, ctDigit, // 0..9
    ctDigit, ctDigit, ctDigit, ctDigit, ctDigit,
    ctColon,            // :
    ctSemiColon,        // ;
    ctLT,               // <
    ctEQ,               // =
    ctGT,               // >
    ctQuestion,         // ?
    ctAt,               // @
    ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, // A .. Z
    ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha,
    ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha,
    ctLBracket,         // [
    ctBackSlash,        // \
    ctRBracket,         // ]
    ctPower,            // ^
    ctAlpha,            // _
    ctGrave,            // ` = Chr(96)
    ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, // a .. z
    ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha,
    ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha, ctAlpha,
    ctLBrace,           // {
    ctPipe,             // |
    ctRBrace,           // }
    ctTilde             // ~
    // 127 = DEL
  );

function GetCharType(c: Char): TCharType;
begin
  if Ord(c) > 255 then
    Exit(ctUnicode);
  if Ord(c) > 126 then
    Exit(ctAnsi);
  Result := CHARTYPES[c];
end;

end.
