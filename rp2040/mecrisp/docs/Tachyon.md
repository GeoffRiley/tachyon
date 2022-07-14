# Tachyon extensions for Mecrisp FORTH

This document is particularly referencing the extensions as provided for the RP2040 processor, used for example on the Raspberry Pi Pico board.

## Words defined in order of definition

word | type  | stack | comment
---  | :---: | :---: | ---
tme  | const | | date of extension, YYMMDDhhmm
\*TACHYON\* | func | | print extensions introduction message
TME? | func  | ( stamp — ) | compare required *stamp* with *tme* and fails if current version is too old
{    | func  | | ignore all until the next *}*: braces form comment blocks

- Basic Tachyon compatible extensions

word | type  | stack | comment
---  | :---: | :---: | ---
pre  | func  | | pre-emptive colon definition (an immediate)
pub  | pre   | | public colon definition (normal)
pri  | pre   | | private colon definition (can be hidden later)
---  | pre   | | use as a clear separator and comment
}    | pre   | | do nothing, terminator for block comments
0EXIT | pub  | ( n — ) | exit if value on stack, *n*, is equal to zero
?EXIT | pub  | ( flag — ) | exit if *flag* on stack is true
BOUNDS | pub | ( s-addr len — e-addr s-addr ) | e-addr ← s-addr + len: setup an end address by adding a length to the start address
\>\> | pub   | ( n1 u — n2 ) | n2 ← n1 / 2^u, logical shift *n1* to the right by *u* bit-places, zero filling at the left
<<   | pub   | ( n1 u — n2 ) | n2 ← n1 * 2^u, logical shift *n1* to the left by *u* bit-places, zero filling at the right
LIT  | pri   | ( x — ) ( — x ) | compile or stack a literal value *x*
ASCLIT | pri | ( mask — ) | compile or stack a literal string from the input buffer
`    | pre   | | replaces *[CHAR]*
^    | pre   | | replaces *CHAR*
IP#  | pre   | | Parse ip4 address eg *IP# 192.168.0.101* → $C0A80005
CR   | pub   | | redefine as a single carriage return without line feed
CRLF | pub   | | emit a carriage return and line feed
#FF  | pub   | | form feed ensures compilation listing is not overwritten by FRED (Forth Rapid Embedded Development Editor)

- Clear type words

word | type  | stack | comment
---  | :---: | :---: | ---
PRINT | pub  | ( n — ) | print a single number; wrapper for standard *.* word
PRINT" | pre | | compile a string and print it when executed; wrapper for standard *."* word

- Creating a vector table

word | type  | stack | comment
---  | :---: | :---: | ---
VECTORS | pub | ( cnt — ) ( index — adr ) | create a vector table, at compile time create *cnt* vectors; execution return the *adr* of the vector number *index*
.RSTACK | pub | | print out the contents of the return stack in hex

- Simple fault handler

word | type  | stack | comment
---  | :---: | :---: | ---
FAULT | pub  | | simple fault handler, resets the system rather than taking any remedial actions
!FAULT | pub | | word to install *FAULT* in the *irq-fault* vector

- Hook control

word | type  | stack | comment
---  | :---: | :---: | ---
QUIT! | pub  | ( f — ) | install function *f* in the *hook-quit* vector
QUIT: | pub  | | defining word for new quit functions
EMIT! | pub  | ( f — ) | install function *f* in the *hook-emit* vector
KEYS! | pub   | ( key key? — ) | install function *key* in the *hook-key* vector; and *key?* in the *hook-key?* vector
!SERKEY | pub | | set *hook-key* to *serial-key* and *hook-key?* to *serial-key?*: redirect stdin to the serial input
CONOUT | pub | | set *hook_emit* to *serial-emit*: redirect stdout to the serial output
CON  | pub   | | redirect stdin and stdout to the serial interface
CON? | pub   | | check if console is being sent to serial port
SERIAL? | pub | | check is input is being taken from the serial port
save-emit | var | | variable to save the value of *serial-emit*/*hook-emit* during muting
MUTED | pub  | | save *hook-emit* in *save-emit*; set *hook-emit* to *DROP*
UNMUTED | pub | | restore *hook_emit* from *save-emit*
tbuf | const | | ← $2002800: tying buffer
~mkey | var  | | variable holding the multi-key entry buffer pointer
MKEY? | pri  | ( — addr ) | return the multi-key entry buffer pointer
MKEY | pri   | ( key — ) | look for new multi-key entries and increment *~mkey* or reset to using straight serial key routines
MLOAD | pub  | ( addr — ) | initialise *~mkey* and direct import stream through the multi-key routines
MSAVE | pub  | ( addr — ) | save input stream to buffer at *addr* until timeout occurs
FL   | pub   | | fast load input to a buffer before compiling after transfer completes

- Initialise stack pointer

word | type  | stack | comment
---  | :---: | :---: | ---
!SP  | pub   | | init stack pointer: move the SP back to the top of the stack space

- Timing tools

word | type  | stack | comment
---  | :---: | :---: | ---
~laps | var  | | array of two cells used by the timing tools (assuming a cell is 4 bytes)
LAP  | pub   | | move *~laps[0]* → *~laps[1]*; then *cycles* → *~laps[0]*
LAP@ | pub   | | return the time difference (in ms) between the last two calls to LAP
~p   | var   | | variable holding saved copy of thread end

- Terminal source code loader mode

word | type  | stack | comment
---  | :---: | :---: | ---
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

- Console Control Keys

word | type  | stack | comment
---  | :---: | :---: | ---
ctrls | VECTORS | | an array of 32 vectors corresponding to the 32 control keys; initialised to zeros
CTRL! | pub  | ( cfa n — ) | *ctrls[n]* ← *cfa* AND $1F: save the function address in the *n*th vector
~k   | var   | | variable for last command entry
REX  | pri   | | re-execute last entry
DISCARD | pri | | discard and reset the CLI **NOT SURE HOW THIS WORKS**
|    | key   | ^C | perform *RESET*
|    | key   | ^X | perform *REX*
|    | key   | esc | perform *DISCARD*

- Background polling whilst waiting for input

word | type  | stack | comment
---  | :---: | :---: | ---
~polls | buffer: | | 16 byte background polling buffer (4 cells)
!POLLS | pub | | initialise the *~polls* buffer to all zeros
@POLL | pub  | ( n — addr ) | return the address of the *n*th element of the *~polls* buffer
POLLS | pub  | | execute the defined polls
+POLL | pub  | ( cfa — ) | add a new polling routine, if there's space
QKEY | pub   | | polling loop waiting for input from serial interface, also executes control keys
!QKEY | pri  | | install *QKEY* to the *hook-key* vector and *serial-key?* to the *hook-key?* vector
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

- User Prompt

word | type  | stack | comment
---  | :---: | :---: | ---
TACHYON | pub | | main Tachyon user prompt: defined as the system quit function

- Data space variables — uninitialised

word | type  | stack | comment
---  | :---: | :---: | ---
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

- Tachyon like utility words

word | type  | stack | comment
---  | :---: | :---: | ---
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

- Unit multipliers

word | type  | stack | comment
---  | :---: | :---: | ---
KB   | pub   | ( u — u*1024 ) | convert *u* in kibibytes to bytes (1 KiB = 2^10 bytes—IEC unit)
MB   | pub   | ( u — u*1024*1024 ) | convert *u* in mebibytes to bytes (1 MiB = 2^20 bytes—IEC unit)
M    | pub   | ( u — u*1000000 ) | convert *u* in megabytes to bytes (1 MB = 10^6 bytes—SI unit)
s    | pub   | ( u — ) | delay *u* seconds
ON   | const | | ← 1
OFF  | const | | ← 0
1K   | const | | ← 1000

- unaligned longs

word | type  | stack | comment
---  | :---: | :---: | ---
~u   | var   | | variable for unaligned longs
U@   | pub   | ( addr — long ) | given the *addr* of an unaligned long, fetch the value
U!   | pub   | ( long addr — ) | given the *addr* of an unaligned long, store the long at that location

- Stack globals

word | type  | stack | comment
---  | :---: | :---: | ---
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

- Bit on byte flag operations

word | type  | stack | comment
---  | :---: | :---: | ---
SET  | pub   | ( mask addr — ) | set the bits in *mask* on the value in *[addr]*
CLR  | pub   | ( mask addr — ) | clear the bits in *mask* on the value in *[addr]*
SET? | pub   | ( mask addr — f ) | test if the bits in *mask* are set in the value in *[addr]*

- Bit on long flag operations

word | type  | stack | comment
---  | :---: | :---: | ---
SETB | pub   | ( bit addr — ) | set bit number *bit* on the value in *[addr]*
CLRB | pub   | ( bit addr — ) | clear bit number *bit* on the value in *[addr]*
TOGB | pub   | ( bit addr — ) | toggle bit number *bit* on the value in *[addr]*
BIT? | pub   | ( bit addr — f ) | test if bit number *bit* on the value in *[addr]* is set

- Null terminated strings

word | type  | stack | comment
---  | :---: | :---: | ---
$!   | pub   | ( src dst — ) | store nullterm or counted string as nullterm string
LEN$ | pub   | ( str — len ) | find the length of a nullterm string
PRINT$ | pub | ( str — ) | print nullterm string
a>A  | pub   | ( c1 — c2 ) | convert lowercase (*c1*) to upcase (*c2*)

- ANSI

word | type  | stack | comment
---  | :---: | :---: | ---
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
.PAR  | pri   | ( u c — ) | output *u* as a decimal value followed by the character *c*
.PAR; | pri   | ( u — ) | output *u* as a decimal value followed by a semicolon
COL8! | pri   | ( u a — ) | output then ANSI control sequence to set an 8 bit colour, *u*, for the foreground (*a* = 38) or background (*a* == 48)
@!    | pub   | ( n a — n ) | retrieve the value from *a* and store it in *n*, returning *n*
PEN8  | pub   | ( col — ) | if different, set and store the 8 bit foreground colour
PAPER8 | pub  | ( col — ) | if different, set and store the 8 bit background colour
COL24! | pri  | ( rgb a — ) | output then ANSI control sequence to set a 24 bit colour, *u*, for the foreground (*a* = 38) or background (*a* == 48)
PEN24 | pub   | ( col — ) | if different, set and store the 24 bit foreground colour
COL!  | pri   | ( attr — ) | set the SGR (foreground/background colour, font style, etc) directly
PEN   | pub   | ( col — ) | if different, set and store the foreground colour
PAPER | pub   | ( col — ) | if different, set and store the background colour
CUR   | pri   | ( c n — ) | output the first half of a cursor positioning command with *n* as the parameter and *c* as the separator
XY    | pub   | ( x y — ) | move the output cursor to co-ordinate (x,y): top left = (1,1)
ERSCR | pub   | ( — ) | erase the screen, leaving the cursor where it is
ERLINE | pub  | ( — ) | erase the current line, leaving the cursor where it is
CLS   | pub   | ( — ) | erase the screen and move the cursor back to the top left
asw   | pri   | ( f — ) | if *f* is true output 'h' otherwise output 'l'
CURSOR | pub  | ( on/off — ) | switch the cursor on or off according to the passed parameter
ATR   | pri   | ( c — ) | output an ANSI 'select graphic rendition' attribute type *c*
PLAIN | pub   | ( — ) | resets pen and paper to defaults and clears all attributes
REVERSE | pub | ( — ) | swaps foreground and background colours
BOLD  | pub   | ( — ) | embolden the output text; different font or more intense colour may be employed
UL    | pub   | ( — ) | underline the output text
BLINK | pub   | ( — ) | cause output text to blink
WRAP  | pub   | ( on/off — ) | switch word wrap on or off if it is supported by the terminal
UTF8  | pub   | ( code — ) | output a UTF8 character *code*
EMOJI | pub   | ( ch — ) | output an emoji character *ch*

- Print Hex & Binary numbers

word | type  | stack | comment
---  | :---: | :---: | ---
.HEX  | pub   | ( d len — ) | output the unsigned double *d* in hex with *len* digits
.B    | pub   | ( b — ) | output the byte *b* as two hex digits
.H    | pub   | ( u — ) | output the integer *u* as four hex digits
.L    | pub   | ( l — ) | output the long *l* as 8 hex digits
.BINX | pub   | ( u len — ) | output the value *u* in binary with *len* digits (grouped in fours with underscores)
.BIN  | pub   | ( u — ) | output the value *u* as 32 binary digits
.BIN8 | pub   | ( b — ) | output the value *b* as 8 binary digits
.BYTE | pub   | ( c — ) | output the character *c* as a dollar symbol followed by two hex digits

- Print decimal numbers

word | type  | stack | comment
---  | :---: | :---: | ---
~z    | var   | | variable holding the leading character for decimal number output
D.R   | pub   | ( d len — ) | output unsigned double *d*, right justified in a field of *len* places: leading character reset to space on return
U.R   | pub   | ( u len — ) | output unsigned value *u*, right justified in a field of *len* places: leading character reset to space on return
Z     | pub   | ( — ) | use leading zeros for the next print
D.DEC | pub   | ( l — ) | output unsigned long *l* in a comma grouped decimal format
.DEC  | pub   | ( u — ) | output unsigned value *u* in a comma grouped decimal format
.DEC2 | pub   | ( u — ) | output tens and units of *u* in two decimal digits
.DEC4 | pub   | ( u — ) | output thousands to units of *u* in four decimal digits
~dp   | var   | | Variable **seems to track decimals?**
D.DECS | pub  | ( d len — ) | output unsigned double *d* with comma groups in a field of *len* places
.DECS | pub   | ( u len — ) | output unsigned value *u* with comma groups in a field of *len* places
.DP   | pub   | ( n len dp — ) | output fixed place decimal *n* with *dp* decimal places in a field of *len* places
~sp   | long  | | "stack global" tracks position of 'spinner'
SPINNER | pub | ( — ) | output the 'next' spinner position: semi-graphical indicator of activity action

- Timing reporting tools

word | type  | stack | comment
---  | :---: | :---: | ---
.LAP  | pub   | ( — ) | print the elapsed time in microseconds
.LAPS | pub   | ( n — ) | print the elapsed time in  nanoseconds divided by *n*
\*END\* | pub | ( — ) | print a report of memory use during file load and a reminder to save

- Any address dump

word | type  | stack | comment
---  | :---: | :---: | ---
AEMIT | pub   | ( c sub — ) | output a character *c* but use *sub* if a non-printing character

- Device memory operations

word | type  | stack | comment
---  | :---: | :---: | ---
~dm   | var   | | dump memory fetch word pointer: default *@*
~dmh  | var   | | dump memory fetch half word pointer: default *H@*
~dmc  | var   | | dump memory fetch character/byte pointer: default *C@*

- Dump memory operations

word | type  | stack | comment
---  | :---: | :---: | ---
DMC@  | pub   | ( — ) | execute dump memory fetch character
DMH@  | pub   | ( — ) | execute dump memory fetch half word
DM@   | pub   | ( — ) | execute dump memory fetch word
DUMP! | pub   | ( addr h-addr c-addr — ) | set dump memory operators
MEM   | pub   | ( — ) | reset memory operators to defaults
PRINT: | pub  | ( — ) | output a colon followed by a space
.ADDR | pub   | ( addr — ) | output the *addr* in 8 hex digits followed by a colon and space, all on the next line
(DUMPA) | pub | ( s-addr len — ) | output the (printable) characters from address location *s-addr* for *len* bytes
.BYTES | pub  | ( s-addr len — ) | output the hex values of the bytes from address location *s-addr* for *len* bytes
DUMP   | pub  | ( s-addr len — ) | output a hex and character dump from address location *s-addr* for *len* bytes
DUMPA  | pub  | ( s-addr len — ) | output a character dump from address location *s-addr* for *len* bytes
DUMPAW | pub  | ( s-addr len — ) | output a wide character dump from address location *s-addr* for *len* bytes
DUMPL  | pub  | ( s-addr len — ) | output the hex values of the words from address location *s-addr* for *len* bytes
DUMPH  | pub  | ( s-addr len — ) | output the hex values of the half words from address location *s-addr* for *len* bytes
QD     | pub  | ( s-addr — ) | output a quick dump of $40 bytes from *s-addr*

- Better stack listing

word | type  | stack | comment
---  | :---: | :---: | ---
.S     | pub  | ( — ) | output a snapshot of the current parameter stack
\>NFA  | pub  | ( cfa — nfa ) | return name field address *nfa* for given code field address *cfa*
\>LFA  | pub  | ( cfa — lfa ) | return link field address *lfa* for given code field address *cfa*
NFA'   | pub  | ( — nfa ) | return name field address *nfa* for next word on input stream

- Simple names only dictionary listing

word | type  | stack | comment
---  | :---: | :---: | ---
~n     | var  | | variable used to count characters output to line
tw     | var  | | variable defining terminal width: default = 80
HIGHLIGHT | pub | ( lfa — lfa ) | set the pen colour depending upon the word characteristic flags
nwords | pub  | ( max — ) | output a list of *max* words starting from the most recent: if *max* is negative, print all
qw     | pub  | ( — ) | output a list of the 20 most recently defined words
words  | pub  | ( — ) | output a list of all defined words

- Enhances SEE to display header

word | type  | stack | comment
---  | :---: | :---: | ---
.HEAD | pub  | | 
SEE  | pub   | ( — ) | display the implementation of the next word in the input stream
DASM | pub   | ( c-addr — ) | disassemble code starting at *c-addr*
@code | const | | constant pointer to the code base
@words | const | | constant pointer to the dictionary base
FORGET | pub | ( — ) | remove all words from the dictionary starting at the next word in the input stream
clkfreq | const | | constant representing the system clock frequency (125MHz)
clksysdiv | const | | constant pointer to the clock system divider
clk!  | pub  | ( n — ) | *[clksysdiv]* ← *n* << 8 initialise the clock divider to *n*
xosc  | const | | constant pointer to the crystal oscillator?
pllsys | const | | constant pointer to the phase locked loop system?

- I/O Words and NeoPixel

word | type  | stack | comment
---  | :---: | :---: | ---
ROM  | const | | ← $00000000
XIP  | const | | ← $10000000
RAM  | const | | ← $20000000
APB  | const | | ← $40000000
IO0  | const | | ← $40014000
PADS0 | const | | ← $4001c000
RESETS | const | | ← $4000c000
AHB  | const | | ← $50000000
M0   | const | | ← $E0000000
PLLSYS | const | | ← $40028000
PLLCS | const | | ← 0
PLLPWR | const | | ← 4
PLLDIV | const | | ← 8
SIO  | pub   | ( n — addr ) | convert SIO number *n* to it's appropriate *addr*
IOIN | const | | ← $004
IOOUT | const | | ← $010; GPIO output value
IOSET | const | | ← $014; GPIO output value set
IOCLR | const | | ← $018; GPIO output value clear
IOXOR | const | | ← $01C
IOOE | const | | ← $020; GPIO output enable
OESET | const | | ← $024; GPIO output enable set
OECLR | const | | ← $028; GPIO output enable clear
OEXOR | const | | ← $02C
GPSR  | func  | ( pin — addr ) | convert *pin* number to it's GPIO status register *addr*
GPCR  | func  | ( pin — addr ) | convert *pin* number to it's GPIO control register *addr*
MASK! | func  | ( flg addr mask — ) | *flg* == true: *[addr]* ← *[addr]* OR *mask*; *flg* == false: *[addr]* ← (NOT *[addr]*) AND *mask*
PADS1V8 | func | ( — ) | select 1.8v for pads bank 0
PADS3V3 | func | ( — ) | select 3.3v for pads bank 0
@PAD  | func  | ( pin — addr ) | convert *pin* number to it's PAD *addr*
PAD@  | func  | ( pin — val ) | read *val* from the PAD *pin*
PAD!  | func  | ( val pin — ) | write *val* to the PAD *pin*
PU    | func  | ( pin — ) | set the PAD *pin* to pull-up, disabling pull-down
PD    | func  | ( pin — ) | set the PAD *pin* to pull-down, disabling pull-up
SCHMITT | func | ( flag pin — ) | set the Schmitt trigger input for *pin*
SLEW  | func  | ( speed pin — ) | set the slew rate for *pin* to *speed*: fast (1) or slow (0)

- Pin Function Select

word | type  | stack | comment
---  | :---: | :---: | ---
FNC  | func  | ( pin func — ) | set *func* for *pin* (setting the GPIO status register)
#SPI | func  | ( pin — ) | default GPIO *pin* as SPI
#UART | func | ( pin — ) | default GPIO *pin* as UART
#I2C | func  | ( pin — ) | default GPIO *pin* as I2C
#PWM | func  | ( pin — ) | default GPIO *pin* as PWM
#SIO | func  | ( pin — ) | default GPIO *pin* as SIO
#PIO0 | func | ( pin — ) | default GPIO *pin* as PIO0
#PIO1 | func | ( pin — ) | default GPIO *pin* as PIO1
#USB | func  | ( pin — ) | default GPIO *pin* as USB

- Simple I/O words

word | type  | stack | comment
---  | :---: | :---: | ---
SIO! | func  | ( val reg — ) | store *val* in the appropriate SIO *reg*
SIO@ | func  | ( reg — val ) | fetch *val* from the appropriate SIO *reg*
FLOAT | func | ( pin — ) | set GPIO *pin* to float: tri-state
PIN@ | func  | ( pin — bit ) | get the *bit* value of the input on GPIO *pin*
PIN? | func  | ( pin — pin bit ) | get the *bit* value of the input on GPIO *pin* retaining the *pin* on stack: setup for a test
HIGH | func  | ( pin — ) | set the value for GPIO *pin* output high (1)
LOW  | func  | ( pin — ) | set the value for GPIO *pin* output low (0)
TOGGLE | func | ( pin — ) | swap the value for GPIO *pin* from high to low, or low to high
PIN! | func  | ( bit pin — ) | set the value for GPIO *pin* output to high or low dependent upon *bit* (0 or 1)
WAITHI | func | ( pin — ) | wait for the GPIO *pin* input to enter the high (1) state
WAITLO | func | ( pin — ) | wait for the GPIO *pin* input to enter the low (0) state
WAITEDGE | func | ( pin — ) | wait from the GPIO *pin* input to transition from low to high, or high to low
~pin | long  | | long variable space allocated on heap: contains the 'current' pin
PIN  | func  | ( pin — ) | set the operating *pin* for future function
H    | func  | ( — ) | set the current pin high
L    | func  | ( — ) | set the current pin low
F    | func  | ( — ) | set the current pin to float: tri-state
.FNC | func  | ( pin — ) | print the function for *pin*: 'GPIO', 'SPI ', 'UART', etc (always four characters)
.PIN | func  | ( pin — ) | print the state of *pin*: function, allocated PAD, i/o direction, H/L condition, GPIO status and control registers
lsio | func  | ( ­— ) | print out the state of the GPIO pins from 0 to 29.
|    | key   | ^P | execute *lsio*

- PWM: Pulse Width Modulation

word | type  | stack | comment
---  | :---: | :---: | ---
~pwm | var   | | ← $40050000: base address of the PWM
@PWM | func  | ( offset — abs-addr ) | convert the absolute address, *abs-addr*, for a given parameter
PWMCSR | func | ( — abs-addr ) | return *abs-addr* of CSR: control and status register
PWMDIV | func | ( — abs-addr ) | return *abs-addr* of DIV: clock divider register (INT/FRAC form a fixed point fractional number)
PWMCTR | func | ( — abs-addr ) | return *abs-addr* of CTR: direct access to PWM counter
PWMCC | func | ( — abs-addr ) | return *abs-addr* of CC: counter compare values
PWMTOP | func | ( — abs-addr ) | return *abs-addr* of TOP:  counter wrap value
PWMCC! | func | ( u16 — ) | store 16 bit value *u16* in the top or bottom half of the CC dependent upon 'current' pin, *~pin*
!PWM | func  | ( — ) | setup the PWM base address for the 'current' pin, *~pin*
PWM  | func  | ( on off div — ) | set the duty cycle and divider for the 'current' pin
MUTE | func  | ( — ) | mute the current pin by setting it to SIO mode
HZ   | func  | ( freq — ) | set the PWM for the 'current' pin to produce a *freq* Hz square wave
KHZ  | func  | ( freq — ) | set the PWM for the 'current' pin to produce a *freq* KHz square wave
DUTY | func  | ( on frame — ) | change the duty cycle within the frame cycle without changing the frequency
PWM% | func  | ( duty% — ) | set the 'current' pin to produce a 1KHz square ware at *duty%* percentage

- Simple sounds

word | type  | stack | comment
---  | :---: | :---: | ---
spkr | var   | | ← 0: pin assigned to 'speaker'
TONE | func  | ( hz ms — ) | produce a *hz* hertz tone for *ms* milliseconds
CLICK | func | ( — ) | produce a click sound
BIP  | func  | ( — ) | produce a 3KHz tone for 50ms
BEEP | func  | ( — ) | produce a 3KHz tone for 150ms
BEEPS | func | ( n — ) | produce *n* 3KHz tones lasting 150ms each with a 50ms gap between each
WARBLE | func | ( hz1 hz2 ms — ) | produce a sequence of 3 double tone signals at *hz1* hertz and *hz2* hertz, each lasting *ms* milliseconds
SIREN | func | ( — ) | produce a 'siren' effect of duotones at 400Hz/550Hz for 400ms each, repeating the sequence three times
~R   | func  | ( — ) | produce a 'trill' effect of duotones at 500Hz/600Hz for 40ms each, repeating the sequence three times
RING | func  | ( — ) | produce a 'ring ring' effect using the *~R* trill twice waiting 200ms between
RINGS | func | ( n — ) | produce a set of *n* *RING* effects with a 1 second pause between each
ZAP  | func  | ( — ) | produce a rising 'laser fire' sound effect
ZAPS | func  | ( n — ) | produce a series of *n* 'laser fire' zaps with a 50ms pause between each 'shot'
SAUCER | func | ( — ) | produce a 'flying saucer' sound effect

- Simple NeoPixel Driver

word | type  | stack | comment
---  | :---: | :---: | ---
_neopin | var | | ← 28 *bit*; ($10000000)
NEOPIN | func | ( n — ) | store selected neopin, *n*
pixdly | func | ( — ) | short pixel delay
pix1 | func  | ( — ) | set the neopixel to the on state
pix0 | func  | ( — ) | clear the neopixel to the off state
pix! | func  | ( f — ) | set or clear the neopixel conditional upon the flag *f*
NEO! | func  | ( $ggrrbb — ) | set the colour of the neopixel on the encoded colour given by *$ggrrbb*
NEOS! | func | ( buffer c — ) | write to a neopixel array from *buffer* of *c* elements each of four bytes
RGB  | func  | ( red green blue — ) | set colour of the neopixel to the provided blend of *red*, *green* and *blue* values
white! | func | ( — ) | set the neopixel to white
blank! | func | ( — ) | set the neopixel to blank/black
blue! | func | ( — ) | set the neopixel to blue
red! | func | ( — ) | set the neopixel to red
green! | func | ( — ) | set the neopixel to green

- UARTS

word | type  | stack | comment
---  | :---: | :---: | ---
~uart | var  | | ← 0; base for UART accesses
UART0 | func | ( — ) | *~uart* ← $40034000; select the first UART
UART1 | func | ( — ) | *~uart* ← $40048000; select the second UART
UART | func  | ( n — addr ) | for a given uart register, *n*, return the appropriate access address, *addr*
UDR  | func  | ( — addr ) | return the *addr* for the UDR register
UFR  | func  | ( — addr ) | return the *addr* for the UFR register
IBRD | func  | ( — addr ) | return the *addr* for the IBRD register
FBRD | func  | ( — addr ) | return the *addr* for the FBRD register
LCR  | func  | ( — addr ) | return the *addr* for the LCR register
UCR  | func  | ( — addr ) | return the *addr* for the UCR register
~baud | var  | | ← 115200: current baudrate (default: 115200)
BAUD | func  | ( baud — ) | set the current UART to the required *baud*rate
CONBAUD | func | ( baud — ) | set the console baudrate
RX   | func  | ( — c ) | receive a character, *c*, from the active UART
TX   | func  | ( c — ) | senc a character, *c*, to the active UART

- Experimental Interactive PIO register methods — WIP

word | type  | stack | comment
---  | :---: | :---: | ---
~pio | var   | | ← 0; base for PIO accesses
PIO0 | func  | ( — ) | *~pio* ← $50200000; select the first PIO
PIO1 | func  | ( — ) | *~pio* ← $50300000; select the second PIO
@PIO | func  | ( n — addr ) | for a given pio register, *n*, return the appropriate access address, *addr*
sm   | var   | | ← 0; pio state machine in use
ch   | var   | | ← 0; pio channel in use
SM0  | func  | ( — ) | select the first state machine
SM1  | func  | ( — ) | select the second state machine
SM2  | func  | ( — ) | select the third state machine
SM3  | func  | ( — ) | select the forth state machine
@SM  | func  | ( n — addr ) | for a given state machine register, *n*, return the appropriate access address, *addr*
FCTRL | func | ( — addr ) | return the *addr* for the FCTRL register
FSTAT | func | ( — addr ) | return the *addr* for the FSTAT register
FDEBUG | func | ( — addr ) | return the *addr* for the FDEBUG register
FLEVEL | func | ( — addr ) | return the *addr* for the FLEVEL register
TXFIFO | func | ( — addr ) | return the *addr* for the TXFIFO register for the current state machine
RXFIFO | func | ( — addr ) | return the *addr* for the RXFIFO register for the current state machine
IRQ  | func  | ( — addr ) | return the *addr* for the IRQ register
IRQ_FORCE | func | ( — addr ) | return the *addr* for the IRQ_FORCE register
INSYN | func | ( — addr ) | return the *addr* for the INPUT_SYNC_BYPASS register
DBG_PADOUT | func | ( — addr ) | return the *addr* for the DBG_PADOUT register
DBG_PADOE | func | ( — addr ) | return the *addr* for the DBG_PADOE register
DBG_CFGINFO | func | ( — addr ) | return the *addr* for the DBG_CFGINFO register
PIOMEM | func | ( n — addr ) | return the *addr* for PIOMEM register *n*; 32 registers
CLKDIV | func | ( — addr ) | return the *addr* for statemachine register CLKDIV
EXECCTRL | func | ( — addr ) | return the *addr* for statemachine register EXECCTRL
SHIFTCTRL | func | ( — addr ) | return the *addr* for statemachine register SHIFTCTRL
ADDR | func  | ( — addr ) | return the *addr* for statemachine register ADDR
INSTR | func | ( — addr ) | return the *addr* for statemachine register INSTR
PINCTRL | func | ( — addr ) | return the *addr* for statemachine register PINCTRL
INTR | func  | ( — addr ) | return the *addr* for the INTR register
IRQE0 | func | ( — addr ) | return the *addr* for the IRQE0 register
IRQF0 | func | ( — addr ) | return the *addr* for the IRQF0 register
IRQS0 | func | ( — addr ) | return the *addr* for the IRQS0 register

- HC-SR04 PIN Sensor

word | type  | stack | comment
---  | :---: | :---: | ---
PING | func  | ( echo trig — mm ) | trigger a ping and return with a result in millimeters

- Grove Ultrasonic Ranger

word | type  | stack | comment
---  | :---: | :---: | ---
RANGER | func | ( pin — mm ) | perform a measurement and return the result in millimeters