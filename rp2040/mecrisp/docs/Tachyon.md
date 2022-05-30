# Tachyon extensions for Mecrisp FORTH

This document is particularly referencing the extensions as provided for the RP2040 processor, used for example on the Raspberry Pi Pico board.

## Words defined in order of definition

word | type  | stack | comment
---  | :---: | :---: | ---
tme  | const | | date of extension, YYMMDDhhmm
TME? | func  | ( stamp — ) | compare required *stamp* with *tme* and fails if current version is too old
{    | func  | | ignore all until the next *}*: braces form comment blocks
pre  | func  | | pre-emptive colon definition (an immediate)
pub  | pre   | | public colon definition (normal)
pri  | pre   | | private colon definition (can be hidden later)
---  | pre   | | use as a clear separator and comment
}    | pre   | | do nothing, terminator for block comments
BOUNDS | pub | ( n1 n2 — n3 n1 ) | n3 ← n1 + n2
\>\> | pub   | ( n1 u — n2 ) | n2 ← n1 / 2^u, logical shift *n1* to the right by *u* bit-places, zero filling at the left
<<   | pub   | ( n1 u — n2 ) | n2 ← n1 * 2^u, logical shift *n1* to the left by *u* bit-places, zero filling at the right
LIT  | pri   | ( x — ) ( — x ) | compile or stack a literal value *x*
ASCLIT | pri | ( mask — ) | compile or stack a literal string from the input buffer
`    | pre   | | replaces *[CHAR]*
^    | pre   | | replaces *CHAR*
IP#  | pre   | | Parse ip4 address eg *IP# 192.168.0.101* → $C0A80005
CR   | pub   | | redefine as a single carriage return without line feed
CRLF | pub   | | emit a carriage return and line feed
