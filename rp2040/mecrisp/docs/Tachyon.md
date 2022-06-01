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
PRINT | pub  | ( n — ) | print a single number; wrapper for standard *.* word
PRINT" | pre | | compile a string and print it when executed; wrapper for standard *."* word
VECTORS | func | ( cnt — ) ( index — adr ) | create a vector table, at compile time create *cnt* vectors; execution return the *adr* of the vector number *index*
.RSTACK | func | | print out the contents of the return stack in hex
FAULT | func | | simple fault handler, resets the system rather than taking any remedial actions
!FAULT | func | | word to install *FAULT* in the *irq-fault* vector
QUIT! | func | ( f — ) | install function *f* in the *hook-quit* vector
QUIT: | func | | defining word for new quit functions
EMIT! | func | ( f — ) | install function *f* in the *hook-emit* vector
KEY!  | func | ( f — ) | install function *f* in the *hook-key* vector
!SERKEY | func | | set *hook-key* to *serial-key* and *hook-key?* to *serial-key?*: redirect stdin to the serial input
CONOUT | func | | set *hook_emit* to *serial-emit*: redirect stdout to the serial output
CON   | func | | redirect stdin and stdout to the serial interface
save-emit | var | | variable to save the value of *serial-emit*/*hook-emit* during muting
MUTED | func | | save *hook-emit* in *save-emit*; set *hook-emit* to *DROP*
UNMUTED | func | | restore *hook_emit* from *save-emit*
!SP   | func | | init stack pointer: move the SP back to the top of the stack space
~laps | var  | | array of two cells used by the timing tools (assuming a cell is 4 bytes)
LAP   | func | | move *~laps[0]* → *~laps[1]*; then *cycles* → *~laps[0]*
LAP@  | func | | return the time difference (in ms) between the last two calls to LAP
~p    | var  | | variable holding saved copy of thread end
?REPORT | func | | checks if the thread end position is inconsistent; if so it prints an error message
EMITS | func | ( c u — ) | emit *u* consecutive copies of the character *c*
EMITD | func | ( u — ) | lim. 0 <= *u* <= 9: convert *u* into the ascii equivalent digit and emit it
TAB   | func | ( — ) | emit a tab character
TABS  | func | ( u — ) | emit *u* tab characters
INDENT | func | ( u — ) | emit a carriage return followed by *u* tabs
@org  | var  | | variable: data space base pointer
~m    | var  | | variable: dictionary position
~o    | var  | | variable: data space tracker pointer
mecrisp | func | | initialise *~m*, *~o*, stack and *~laps*
ctrls | VECTORS | | an array of 32 vectors corresponding to the 32 control keys; initialised to zeros
CTRL! | func | ( cfa n — ) | *ctrls[n]* ← *cfa*: save the function address in the *n*th vector
~k    | var  | | variable for last command entry
REX   | func | | re-execute last entry
DISCARD | func | | discard and reset the CLI **NOT SURE HOW THIS WORKS**
      | key  | ^C | perform *RESET*
      | key  | ^X | perform *REX*
      | key  | esc | perform *DISCARD*
~polls | buffer: | | 16 byte background polling buffer (4 cells)
!POLLS | func | | initialise the *~polls* buffer to all zeros
@POLL | func | ( n — addr ) | return the address of the *n*th element of the *~polls* buffer
POLLS | func | | execute the defined polls
+POLL | func | ( cfa — ) | add a new polling routine, if there's space
QKEY  | func | | polling loop waiting for input from serial interface
~defers | var | | a single deferred execution vector
~depth | var | | depth of deferred word
defers | func | | execute the deferred word, if one exists: clears *~defers* before execution
->    | func | | defer the execution of this word until the end of the line
.base | func | | print the radix base prompt signal: '#' for decimal, '$' for hex, '%' for binary and '?' for anything else
.depth | func | | print two digit depth
.mode | func | | print 'R' for compile to ram mode or 'F' for compile to flash mode
COMPEX | func | | *place saver*
~query | var | | pointer to cfa of *query*
TACHYON | func | | main Tachyon user prompt: defined as the system quit function

