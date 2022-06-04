# Tachyon extensions for Mecrisp FORTH

This document is particularly referencing the extensions as provided for the RP2040 processor, used for example on the Raspberry Pi Pico board.

## Words defined in order of definition

word | type  | stack | comment
---  | :---: | :---: | ---
tme  | const | | date of extension, YYMMDDhhmm
\*TACHYON\* | func | | print extensions introduction message
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
PRINT | pub  | ( n — ) | print a single number; wrapper for standard *.* word
PRINT" | pre | | compile a string and print it when executed; wrapper for standard *."* word
VECTORS | pub | ( cnt — ) ( index — adr ) | create a vector table, at compile time create *cnt* vectors; execution return the *adr* of the vector number *index*
.RSTACK | pub | | print out the contents of the return stack in hex
FAULT | pub  | | simple fault handler, resets the system rather than taking any remedial actions
!FAULT | pub | | word to install *FAULT* in the *irq-fault* vector
QUIT! | pub  | ( f — ) | install function *f* in the *hook-quit* vector
QUIT: | pub  | | defining word for new quit functions
EMIT! | pub  | ( f — ) | install function *f* in the *hook-emit* vector
KEY! | pub   | ( f — ) | install function *f* in the *hook-key* vector
!SERKEY | pub | | set *hook-key* to *serial-key* and *hook-key?* to *serial-key?*: redirect stdin to the serial input
CONOUT | pub | | set *hook_emit* to *serial-emit*: redirect stdout to the serial output
CON  | pub   | | redirect stdin and stdout to the serial interface
CON? | pub   | | check if console is being sent to serial port
save-emit | var | | variable to save the value of *serial-emit*/*hook-emit* during muting
MUTED | pub  | | save *hook-emit* in *save-emit*; set *hook-emit* to *DROP*
UNMUTED | pub | | restore *hook_emit* from *save-emit*
~mkey | var  | | variable holding the multi-key entry buffer pointer
MKEY? | pri  | ( — addr ) | return the multi-key entry buffer pointer
MKEY | pri   | ( key — ) | look for new multi-key entries and increment *~mkey* or reset to using straight serial key routines
MLOAD | pri  | ( addr — ) | initialise *~mkey* and direct import stream through the multi-key routines
!SP  | pub   | | init stack pointer: move the SP back to the top of the stack space
~laps | var  | | array of two cells used by the timing tools (assuming a cell is 4 bytes)
LAP  | pub   | | move *~laps[0]* → *~laps[1]*; then *cycles* → *~laps[0]*
LAP@ | pub   | | return the time difference (in ms) between the last two calls to LAP
~p   | var   | | variable holding saved copy of thread end
?REPORT | pub | | checks if the thread end position is inconsistent; if so it prints an error message
EMITS | pub  | ( c u — ) | emit *u* consecutive copies of the character *c*
EMITD | pub  | ( u — ) | lim. 0 <= *u* <= 9: convert *u* into the ascii equivalent digit and emit it
TAB  | pub   | ( — ) | emit a tab character
TABS | pub   | ( u — ) | emit *u* tab characters
INDENT | pub | ( u — ) | emit a carriage return followed by *u* tabs
@org | var   | | variable: data space base pointer
~m   | var   | | variable: dictionary position
~o   | var   | | variable: data space tracker pointer
mecrisp | pub | | initialise *~m*, *~o*, stack and *~laps*
ctrls | VECTORS | | an array of 32 vectors corresponding to the 32 control keys; initialised to zeros
CTRL! | pub  | ( cfa n — ) | *ctrls[n]* ← *cfa*: save the function address in the *n*th vector
~k   | var   | | variable for last command entry
REX  | pri   | | re-execute last entry
DISCARD | pri | | discard and reset the CLI **NOT SURE HOW THIS WORKS**
|    | key   | ^C | perform *RESET*
|    | key   | ^X | perform *REX*
|    | key   | esc | perform *DISCARD*
~polls | buffer: | | 16 byte background polling buffer (4 cells)
!POLLS | pub | | initialise the *~polls* buffer to all zeros
@POLL | pub  | ( n — addr ) | return the address of the *n*th element of the *~polls* buffer
POLLS | pub  | | execute the defined polls
+POLL | pub  | ( cfa — ) | add a new polling routine, if there's space
QKEY | pub   | | polling loop waiting for input from serial interface
~defers | var | | a single deferred execution vector
~depth | var | | depth of deferred word
defers | pub | | execute the deferred word, if one exists: clears *~defers* before execution
->   | pub   | | defer the execution of this word until the end of the line
.base | pub  | | print the radix base prompt signal: '#' for decimal, '$' for hex, '%' for binary and '?' for anything else
.depth | pub | | print two digit depth
.mode | pub  | | print 'R' for compile to ram mode or 'F' for compile to flash mode
COMPEX | pub | | *place saver*
~query | var | | pointer to cfa of *query*
prompt | pub | | print the CLI prompt
respond | pub | | print the execution operating response
TACHYON | pub | | main Tachyon user prompt: defined as the system quit function
|    |      | |
DATA | const | | ← $20030000: base for all data and buffers
org  | pub   | ( n — ) | *org* ← *n*: update data space pointer with the given value
org@ | pub   | ( — addr ) | return the address pointed to by the data space pointer
res  | pre   | ( n — ) | *org* ← *org* + *n*: reserve bytes in data space without assigning a name
(bytes) | pri | ( n — ) | create a new constant of *n* bytes, updating *org* ← *org* + *n* afterwards
bytes | pre  | ( n — ) | pre-emptive version of *(bytes)*: use *n* *bytes* *new_name*
byte | pre   | ( — ) | allocate a single byte constant
alorg | pub  | ( n — ) | align *@org* on a boundary appropriate to the given value *n*: *n* should be a power of 2
(longs) | pri | ( n — ) | reserve space in the data space for *n* 32 bit long values
longs | pre  | ( n — ) | pre-emptive version of *(longs)*
long | pre   | ( — ) | allocate space for a single 32 bit long value
shift | pub  | ( n — ) | perform *<<* or *>>* automatically for *n* places depending upon the sign: negative shit right, positive shift left
\>\| | pub   | ( mask — bit ) | return the bit number of the rightmost bit within the provided mask
\|<  | pub   | ( bit — mask ) | return a mask with bit number *bit* set
bit  | pub   | ( bit — mask ) | synonym for \|<
bits | pub   | ( n1 bit — n2 ) | mask off the lower *bit* bits in *n1*
ANDN | pub   | ( n1 mask — n2 ) | clear the bits set in mask from the value *n1*
\>N  | pub   | ( n1 — n2 ) | *n2* ← low 4 bits of *n1*
\>B  | pub   | ( n1 — n2 ) | *n2* ← low 8 bits of *n1*
\>W  | pub   | ( n1 — n2 ) | *n2* ← low 16 bits of *n1*
W\>B | pub   | ( w — lb hb ) | split word *w* into two 8 bit values
L\>W | pub   | ( long — lw hw ) | split long *long* into two 16 bit values
HH!  | pub   | ( u addr — ) | *u* is a 16 bit value; update the higher 16 bits of the contents of *addr* with the value of *u*
LH!  | pub   | ( u addr — ) | *u* is a 16 bit value; update the lower 16 bits of the contents of *addr* with the value of *u*
HH@  | pub   | ( addr — u ) | fetch the higher 16 bits of the contents of *addr*
~    | pub   | ( addr — ) | *[addr]* ← 0: clear the long value at *addr*
~~   | pub   | ( addr — ) | *[addr]* ← -1: set the long value at *addr*
C~   | pub   | ( addr — ) | *[addr]* ← 0: (8 bit) clear the byte value at *addr*
C~~  | pub   | ( addr — ) | *[addr]* ← -1: (8 bit) set the byte value at *addr*
++   | pub   | ( addr — ) | *[addr]* ← *[addr]* + 1: increment long value at *addr*
--   | pub   | ( addr — ) | *[addr]* ← *[addr]* - 1: decrement long value at *addr*
C++  | pub   | ( addr — ) | *[addr]* ← *[addr]* + 1: (8 bit) increment byte value at *addr*
B++  | pub   | ( b a — b+1 a ) | add one to the second value on the stack
C@++ | pub   | ( addr — addr+1 n ) | read a byte from *[addr]* and increment *addr*
3RD  | pub   | ( u3 u2 u1 — u3 u2 u1 u3 ) | copy the third element from the stack
4TH  | pub   | ( u4 u3 u2 u1 — u4 u3 u2 u1 u4) | copy the fourth element from the stack
ERASE | pub  | ( addr len — ) | fill *len* bytes of memory starting at *addr* with zero
WITHIN | pub | ( n min max — f ) | return true (1) if *n* is between *min* and *max* (inclusive)
LIMIT | pub  | ( n min max — n ) | constrain *n* to *min* and *max*
U/   | pub   | ( u1 u2 — u3 ) | *u3* ← floor(*u1* / *u2*)
//   | pub   | ( u1 u2 — u3 ) | *u3* ← remainder(*u1* / *u2*)
HMS  | pub   | ( #hhmmss — ss mm hh ) | divide hours, minutes and seconds from single value
KB   | pub   | ( u — u*1024 ) | convert *u* in kibibytes to bytes (1 KiB = 2^10 bytes—IEC unit)
MB   | pub   | ( u — u*1024*1024 ) | convert *u* in mebibytes to bytes (1 MiB = 2^20 bytes—IEC unit)
M    | pub   | ( u — u*1000000 ) | convert *u* in megabytes to bytes (1 MB = 10^6 bytes—SI unit)
s    | pub   | ( u — ) | delay *u* seconds
ON   | const | | ← 1
OFF  | const | | ← 0
1K   | const | | ← 1000
0EXIT | pub  | ( n — ) | if *n* == 0 remove the top element from the return stack: return from the calling word
?EXIT | pub  | ( f — ) | if *f* is true remove the top element from the return stack: return from the calling word
~u   | var   | | variable for unaligned longs
U@   | pub   | ( addr — long ) | given the *addr* of an unaligned long, fetch the value
U!   | pub   | ( long addr — ) | given the *addr* of an unaligned long, store the long at that location
~a   | long  | | "stack global"
ant! | pub   | ( n — ) | store *n* in *~a*
ant  | pub   | ( — n ) | fetch *~a*
~b   | long  | | "stack global"
bat! | pub   | ( n — ) | store *n* in *~b*
bat  | pub   | ( — n ) | fetch *~b*
~c   | long  | | "stack global"
cat! | pub   | ( n — ) | store *n* in *~c*
cat  | pub   | ( — n ) | fetch *~c*
~d   | long  | | "stack global"
dog! | pub   | ( n — ) | store *n* in *~d*
dog  | pub   | ( — n ) | fetch *~d*
~e   | long  | | "stack global"
emu! | pub   | ( n — ) | store *n* in *~e*
emu  | pub   | ( — n ) | fetch *~e*
~f   | long  | | "stack global"
fox! | pub   | ( n — ) | store *n* in *~f*
fox  | pub   | ( — n ) | fetch *~f*
SET  | pub   | ( mask addr — ) | set the bits in *mask* on the value in *[addr]*
CLR  | pub   | ( mask addr — ) | clear the bits in *mask* on the value in *[addr]*
SET? | pub   | ( mask addr — f ) | test if the bits in *mask* are set in the value in *[addr]*
SETB | pub   | ( bit addr — ) | set bit number *bit* on the value in *[addr]*
CLRB | pub   | ( bit addr — ) | clear bit number *bit* on the value in *[addr]*
TOGB | pub   | ( bit addr — ) | toggle bit number *bit* on the value in *[addr]*
BIT? | pub   | ( bit addr — f ) | test if bit number *bit* on the value in *[addr]* is set
$!   | pub   | ( src dst — ) | store nullterm or counted string as nullterm string
LEN$ | pub   | ( str — len ) | find the length of a nullterm string
PRINT$ | pub | ( str — ) | print nullterm string
a>A  | pub   | ( c1 — c2 ) | convert lowercase (*c1*) to upcase (*c2*)
~pen | var   | | colour of foreground printing (default = 7; white)
~paper | var | | colour of background surface (default = 0; black)
PEN@ | pub   | ( — c ) | fetch the current pen colour
PAPER@ | pub | ( — c ) | fetch the current background colour
black | const | | ← 0
red   | const | | ← 1
green | const | | ← 2
yellow | const | | ← 3
blue  | const | | ← 4
magenta | const | | ← 5
cyan  | const | | ← 6
white | const | | ← 7
ESC   | pub   | ( c — ) | output and escape character ($1B) followed by the given character
ESC[  | pub   | ( — ) | output the standard ANSI introduction sequence (ESC-[)
CSI   | pri   | ( c — ) | output the ANSI introduction followed by the character *c*
HOME  | pub   | ( — ) | move the output cursor to co-ordinate (1,1): top left corner
COL   | pri   | ( col fg/bg — ) | set the foreground/background colour
PEN!  | pub   | ( col — ) | set and store the foreground colour
PEN   | pub   | ( col — ) | if different, set and store the foreground colour
PAPER! | pub  | ( col — ) | set and store the background colour
PAPER | pub   | ( col — ) | if different, set and store the background colour