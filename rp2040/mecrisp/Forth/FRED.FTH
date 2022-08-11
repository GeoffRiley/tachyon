\           ... FORTH RAPID EMBEDDED DEVELOPMENT EDITOR ...

mecrisp
2207190000 tme?                 --- make sure Tachyon Mecrisp Extension  is new enough
~edsect org  FORGET *FRED*      --- reclaim code and data
    org? org                    --- use latest org? -  all modules will define this to indicate next free

pub *FRED*      PRINT" FRED - Forth Rapid Embedded Development Editor 220715-0054 " ;
{
TABLE OF CONTENTS
    *THEME*     *HIGHLIGHTING*
    *KEYS*




TO DO:  Limit editing to file size
    insert/delete page
    add horizontal scroll
    add word wrap
    sleep mode - locks edit
    also other directives i.e. set theme, modes, etc.
    add conditional compile directives #IFDEF #IF etc
    column select mode - maybe ^B ^B first or ALT B
}







\       *** CONSTANTS ***
\ Tachyon reserves DATA from $2003000 for buffers and variables and is free at around DATA+$0A74 (2676 bytes)
DATA $E000 +    constant clipboard      --- clipboard holds up to 8kb (less 512 bytes at $2003FE00)
DATA $C000 +    constant pagebuf        --- allocate up to 8kB PAGEBUF near end of RAM
16              constant maxtabs
32              constant ftab*          --- ftab size
4 kb            constant =pagesz        --- display and edit one page at a time default
128             constant ew

\       *** VARIABLES ***
    long ~edsect        --- starting sector of current page
    long ~page

    long ~begin         --- marks beginning of selection (default -1 = none)
    long ~end           --- marks end of select
    long ~clipsz        --- size of content copied to clipboard

    long ~qt            --- quick time clock latch
    long ~find          --- length of find string
    long ~idle          --- idle timer - used to determine auto refresh
    long ~key           --- ASCII or abbreviated 32-bit  CSI code
    long ~seq           --- highlight sequence
    long ~hflgs         --- highlight flags
2   bytes ~pagesz        --- sectors/page (pagesize)
    byte ~dw            --- print display width (truncates page width)
    byte ~ftab          --- current file tab active
32  bytes ~word
maxtabs ftab* * bytes ~ftabs      --- hold the context for files

long ~edcold


\       *** FILE TAB VARIABLES ***
--- file tabs have 32 bytes for filename(12),cursor(4),theme(4),flgs(4),free(8)
pri ftab#               ~ftab C@ ;
pri @ftab               ~ftab C@ maxtabs MOD ;
pri FTAB$ ( -- a )      @ftab 5 << ~ftabs + ;
pri ~tcur ( -- a )      FTAB$ 12 + ;
pri ~theme ( -- a )     FTAB$ 16 + ;
pri ~eflgs ( -- a )     FTAB$ 20 + ;
pri ~offset             FTAB$ 24 + ;
\       *** CURSOR TRACKING ***
pri tcur@ ( -- cur )    ~tcur @ 0 FSIZE@ LIMIT ;
pri tcur! ( cur -- )    ~tcur ! ;
pri tcur+! ( n -- )     tcur@ + 0 MAX tcur! ;
pri tcur-! ( n -- )     NEGATE tcur+! ;

--- editor print width
pri dw ( -- n )         ~dw C@ 32 128 LIMIT ;
pri pagesz ( -- n )     ~pagesz C@ 16 MIN 9 << ;
pri #lines ( -- n )     pagesz ew / ;
pri @xy ( -- x y )      tcur@ 0 MAX pagesz //   ew U/MOD ;
pri @y ( -- y )         @xy NIP ;
pri @x ( -- x )         @xy DROP ;
pri LEFTLN ( -- row )   tcur@ ew 1- ANDN ;

\       *** BIT FLAGS ***
pri save? ( -- f )      1 ~eflgs ;
pri ins? ( -- f )       2 ~eflgs ;
pri wr? ( -- f )        7 ~eflgs ;
pri indent? ( -- f )    3 ~eflgs ;
pri lines? ( -- f )     4 ~eflgs ;


(       *** PAGE ACCESS ***     )
--- used for comparing for changes to be written back to sectors
pri COMPARE? ( src dst cnt -- f )       BOUNDS DO DUP C@ I C@ <> IF DROP 0 LEAVE THEN 1+ LOOP 0<> ;

--- save the current page to file (only save the modified sectors)
pri SAVEPAGE
    ~edsect @ pagesz 9 >> BOUNDS DO I SDBUF SDRD
      pagebuf I ~edsect @ - 9 << + DUP SDBUF 512 COMPARE? NOT
        IF RW I SDWR ELSE DROP THEN
    LOOP RO save? CLRB ;

pri ?SAVEPAGE           ~edsect @ 0EXIT  wr? BIT? 0EXIT SAVEPAGE ;

--- Read in a page from SD into the page buffer - 13.2ms per new page or 1us if buffered
pri LOADPAGE ( sect bytes -- ram )
    OVER ~edsect @ <>                           --- don't do anything if the ed sector is still the same
---   update edsect  buffer size
    IF save? BIT? IF ?SAVEPAGE THEN             --- autosave modified sectors of page (unless write protect set)
      OVER ~edsect ! pagebuf SWAP SDRDS         --- now read in the new page
    ELSE 2DROP
    THEN   pagebuf
;
pub PAGE ( offset -- ram )
    DUP pagesz / pagesz *
--- page offset   page sector
    SWAP OVER -   SWAP 9 >>
    @FILE +  ~offset C@ +   pagesz LOADPAGE +
;
pri PAGE# ( -- page# )          tcur@ pagesz / ;
pri PAGEADR ( -- offset )       tcur@ pagesz / pagesz *  ;


\       ... CHARACTER ACCESS ...
pri ED@                 PAGE C@  ;
pri ED!                 PAGE C!  ;

\       ... PLACEMENT ...
pri !TEXTXY             @xy SWAP 9 + SWAP 4 + XY ;
pri @STATUS             68 1 XY ;
pri @FOOTER ( x -- )    pagesz ew / 4 + XY ;

\       ... PAGE FORMATTING ...

pri SETCR               pagebuf pagesz BOUNDS DO $0D I 127 + C! ew +LOOP ;
--- convert block to CR delimited lines and replace nulls with spaces
pri FORMAT.PAGE         pagebuf pagesz BOUNDS DO I C@ 0= IF $20 I C! THEN LOOP SETCR ;

pub WIPE.PAGE           pagebuf pagesz $20 FILL FORMAT.PAGE ;
--- format the whole file as pages (blanks with CRs)
pub FORMAT.PAGES
    @FILE 0EXIT
--- Write over whole file
    RW FSIZE@ 0
    DO
      I PAGE DUP pagesz $20 FILL
      pagesz BOUNDS DO $0D I ew 1- + C! ew +LOOP
      SAVEPAGE SPINNER
      pagesz
    +LOOP
    RO
;
--- confirm complete page format with Y
pri ?FORMAT.PAGES       @STATUS PRINT"  Format? " KEY a>A ` Y = IF FORMAT.PAGES THEN ;

\      ... *THEME* ...    --- black red green yellow blue magenta cyan white
pub THEME               4 << OR 4 << OR 4 << OR ~theme ! ;
pri -THEME              ~theme @ SWAP 2 << >> >B DUP >N PLAIN PEN 4 >> PAPER ;
---                     text paper info frame
pub -C64                white blue  blue white THEME ;
pub -MINT               blue white black green THEME ;
pub -DARK               yellow black white magenta THEME ;
pub -DAY                white magenta black cyan  THEME ;
pub -BRIGHT             black yellow white magenta THEME ;
pub -MONO               white black white black THEME ;
pub -LOGO               white cyan cyan white THEME ;
pub -BLUE               black cyan blue white THEME ;
pri -HDRS               2 -THEME ;
pri -INFO               white pen red paper ;
pri -TEXT               0 -THEME ;
pri -TITLE              -HDRS bold white pen ;
















\       ... HEADER INFO ...

pri .PAGE#      8 SPACES CR ." PG "  PAGE# 1+ 3 Z U.R SPACE ;
pri .RW         wr? BIT? IF -INFO ."  EDIT" ELSE -HDRS ."  VIEW" THEN ;
pri .INDENT     indent? BIT? IF -INFO PRINT"  INDENT" ELSE -HDRS PRINT"  nodent" THEN ;
pri .INS        -TEXT  ins? BIT? IF -INFO PRINT"  INS" ELSE -HDRS PRINT"  OWR" THEN ;
pri .CLIP       -HDRS  ."  CLIP: " ~clipsz @ DUP IF -INFO 4 U.R SPACE  ELSE ." empty" THEN -HDRS ;
pri .SIZE       ." SIZE: "  ew PRINT ." x" pagesz ew / PRINT ;
--- display the clock in the top right corner ( use quick time software clock )

pri .CLOCK      42 1 XY .FDT ;
pri .TXTRULE    dw 0 DO I 7 AND 0= IF I 3 >> 1 U.R ELSE I 3 AND IF ` . ELSE ` | THEN EMIT THEN LOOP ;
pri .RULER      -HDRS REVERSE .TXTRULE ;

--- display header  - reset term - plain - clear
pri .INFO       PLAIN  -HDRS ( dw 8 + SPACES ) .RW SPACE .INDENT SPACE .INS SPACE .CLIP ;
















\       ... TEXT SELECTION ...
pri ?SELECT
    ~end @
    IF --- selection is active if ~end is non-zero
      DUP ~begin @ ~end @ WITHIN
        IF DROP REVERSE ELSE ~end @ 1+ = IF 0 -TEXT  THEN THEN
    ELSE DROP
    THEN ;
pri hflgs? ( b -- f )       DUP ~hflgs BIT? DUP IF SWAP ~hflgs CLRB ELSE SWAP ~hflgs SETB THEN ;
pri MATCH? ( b s -- f )
    ~seq SWAP C$=
    IF   hflgs? IF -TEXT 0 ELSE 1 THEN
    ELSE DROP 0
    THEN ;

\       ... KEYBOARD INPUT ...
pri EDINP ( str -- len )        @STATUS -INFO 26 SPACES @STATUS -HDRS TYPE -INFO TIB 32 ACCEPT ;
pri EDNUM ( str -- num f )      EDINP TIB SWAP NUMBER ;
pri EDKEY                       CSIKEY DUP ~key ! ;













\       ... *HIGHLIGHTING*  ...

create :$   $20 C, ` : C, $0D C,
pri ?CODE
                7 ~hflgs BIT? IF ~seq C@ $20 = IF -TEXT 7 ~hflgs CLRB THEN THEN
                7 s" ( " MATCH? IF -TEXT THEN
                7 s"  bup" MATCH? IF red pen THEN               --- pub
                7 :$ 3 MATCH? IF red pen THEN
                7 s"  irp" MATCH? IF black pen BOLD THEN ;      --- pri
pri ?BOLD       0 s" ***" MATCH? IF BOLD THEN ;
pri ?UL         1 s"  ___" MATCH? IF UL THEN ;
pri ?BLINK      2 s" !!!" MATCH? IF BLINK THEN ;
pri ?COMMENT    3 s"  ---" MATCH? IF magenta PEN THEN
                3 s"  \"  MATCH? IF magenta pen THEN ;
pri ?REVERSE    4 s"  ..." MATCH? IF REVERSE THEN ;
pri ?PARA       5 s" ("  MATCH? IF magenta PEN THEN
                5 s" )"  MATCH? IF -TEXT THEN  ;
pri ?BRACES     6 s" {" MATCH? IF magenta PEN THEN
                6 s" }" MATCH? IF -TEXT THEN  ;

{
block comments
\ comment row
( comments *** BOLD *** )
*** BOLD ***
___ UNDERLINE ___
!!! BLINK !!!
... REVERSE ...
}
pri ?MODE       8 s" |X|" MATCH? DROP   ;


\       ... TEXT DISPLAY ...

pri ?HIGHLIGHT ( ch -- )
    ~seq @ 8 << OR ~seq !
    ?MODE 8 ~hflgs BIT? 0= IF ?BOLD ?UL ?BLINK ?COMMENT ?REVERSE ?PARA  ?BRACES ?CODE THEN
;
pri .LINE# ( index -- )
--- print line numbers or offset
    PLAIN CR lines? BIT?
    IF L>W .B .H
    ELSE 7 >> 2 SPACES 1+ ~offset C@ 4 * + 4 U.R
    THEN
;
--- Start each row with address offset
pri .ROW ( index -- )
    DUP .LINE#
---           text theme, reset hightlights
    ." :|"    -TEXT ~hflgs C~ dw BOUNDS
      DO I ?SELECT  I ED@ DUP ?HIGHLIGHT
---   indicate CR terminators anywhere in the line else display char
        DUP $0D = IF DROP REVERSE ` < EMIT -TEXT ELSE ` . AEMIT THEN
      LOOP
    -TEXT
;
--- refresh line
pri .LINE               LEFTLN .ROW ;






\       ... PAGE DISPLAY ...

pri .FTABS
    PLAIN ERLINE -HDRS PRINT"  FILES: "
    maxtabs 0 DO PLAIN I 1 AND IF REVERSE THEN blue pen
      I 5 << ~ftabs + DUP @
---   if active and current focus then display in red whether normal/reverse tab
      IF @ftab I = IF bold white I 1 AND IF paper ELSE pen THEN THEN
        I 1+  ` : .PAR     DUP LEN$ 12 MIN TYPE SPACE
      ELSE DROP LEAVE THEN
    LOOP PLAIN ;

pri .PAGE
--- page offset    for page size
    0 ~hflgs H! PAGEADR pagesz ( DUP 2 >> + ) BOUNDS
      DO CRLF I .ROW  ew +LOOP ;
pri HEADER
    OFF CURSOR -HDRS HOME dw 8 + SPACES CR   .PAGE# SPACE .INFO 1 2 XY .FTABS ;
pri REFRESH
    15 EMIT HEADER 9 3 XY .RULER .PAGE CRLF PLAIN 16 SPACES *FRED*
--- current cursor     refresh timer
    !TEXTXY ON CURSOR   cycles ~idle !  0 ~eflgs CLRB ;
pri REDRAW              PLAIN CLS REFRESH ;
--- check if block needs to be refreshed (but not if key input busy)
pri ?REFRESH            KEY? ?EXIT   ~page @ ~edsect @ <> IF ~edsect @ ~page ! REFRESH THEN ;
pri ?PAGE               tcur@ PAGE DROP ?REFRESH ;
pri ?IDLE
    cycles ~idle @ - ABS 500000 >
    0 ~eflgs BIT? AND IF REFRESH THEN
    ~qt @ QTIME@ <> IF QTIME@ ~qt ! -HDRS .CLOCK -TEXT !TEXTXY THEN ;


\       ... NAVIGATION ...
--- smart tab will jump to comments column or indent 4 spaces etc
pri EDTAB
    @x 0= IF 4 tcur+! EXIT THEN  --- only 4 spaces from left margin
--- if previous a char & some text between cols 8..47 then tab to 48   else standard tab       set cursor
    tcur@ 1- ED@ $20 > tcur@ ew 1- AND 8 47 WITHIN AND
--- but no more text on the remainder of the line
    0 tcur@ PAGE BEGIN DUP C@ $0D <> WHILE DUP C@ $20 > IF NIP 1 SWAP THEN 1+ REPEAT DROP 0= AND
    IF LEFTLN 48 +  ELSE tcur@ 8 + 7 ANDN THEN tcur! ;

pri GOLEFT              1 tcur-! ;
pri GORIGHT             1 tcur+! ;
pri LNUP                ew tcur-! @y #lines 1- = ~offset C@ 0<> AND IF -1 ~offset C+! ew 4 * tcur+! THEN ?PAGE ?REFRESH ;
pri LNDN                ew tcur+! @y 0= IF ~offset C++ ew 4 * tcur-! THEN  ?PAGE ?REFRESH ;
pri PGUP                pagesz tcur-! REFRESH ;
pri PGDN                pagesz tcur+! REFRESH ;

pri CLRLN ( ch -- )     LEFTLN PAGE ew 1- ROT FILL .LINE save? SETB ;
pri WIPELN              $20 CLRLN ;
--- test if  line is blank
pri BLANKS? ( adr -- f )        0 SWAP BEGIN DUP C@ $0D <> WHILE C@++ ROT OR SWAP REPEAT  DROP $20 = ;


\       ... CHARACTER STORE ...
--- write a char to the page and set modified flag
pri EDCHAR! ( ch -- )   wr? BIT? IF tcur@ ED!  3 ~eflgs SET THEN ;
--- write new char but skip over any CR terminators
pri EDCHAR!!            wr? BIT? IF EDCHAR! 1 tcur+! tcur@ ED@ $0D = IF 1 tcur+! THEN ELSE DROP THEN ;
--- write char to file        forward but skip any embedded CR    then check refresh
pri EDCHAR              DUP EMIT EDCHAR!! ?REFRESH ;


\       ... INSERT/DELETE ...

pri DELLN --- Delete a line in the page
    LEFTLN PAGE DUP ew + SWAP   OVER pagesz // pagesz SWAP - MOVE
    tcur@ pagesz / pagesz * pagesz + ew - PAGE ew 1- $20 FILL REFRESH save? SETB ;
pri DELCH --- Delete a char but if the line is blank then delete the line
    LEFTLN PAGE BLANKS? IF DELLN ELSE tcur@ PAGE DUP 1+ SWAP ew @x - 2- MOVE THEN
   .LINE save? SETB ;

pri EDINS --- toggle insert/overwrite mode
    ins? BIT? IF ins? CLRB ELSE ins? SETB THEN REFRESH !TEXTXY ;
pri INSLN? --- Insert a line in the page
    pagebuf pagesz + ew - BLANKS? DUP 0EXIT
    LEFTLN PAGE DUP ew + pagebuf pagesz + OVER - MOVE WIPELN save? SETB ;
pri INSLN               INSLN? IF REFRESH THEN ;

pri INSCR
--- cur - insert new line  & cur   adr   adr-of-next-line+    ( cur src dst )
    tcur@ ew tcur+! INSLN? IF DUP PAGE DUP ew + ew 1- ANDN indent? BIT? IF 4 + THEN
    ( s d ) DUP BEGIN 1- DUP C@ $20 > UNTIL 1+ ( s d e ) 3RD -
    ( s d c ) 3rd 3rd 3rd  MOVE NIP $20 FILL REFRESH THEN tcur! ;
pri EDCR --- go to start of next line or auto-indent OR insert a line if at start and insert on.
    ins? BIT? IF LEFTLN tcur@ = IF INSLN EXIT ELSE tcur@ PAGE BLANKS? NOT IF INSCR EXIT THEN  THEN  THEN
    LEFTLN indent? BIT?
      IF   BEGIN DUP ED@ $20 = WHILE 1+ REPEAT DUP ED@ $0D = IF DROP LEFTLN THEN THEN
    ew + tcur! ?REFRESH ;






\    ... CLIPBOARD ROUTINES ...

pri !CLIP               ~end ~ ~begin ~~ ;
pri !CLIPS              !CLIP ~clipsz ~ ;
--- save selected text
pri SAVECLIP        ~begin @ PAGE clipboard   ~end @ ~begin @ -   DUP ~clipsz ! MOVE ;

pub EDCOPY --- mark the end and copy from begin -OR- copy the whole page if begin and end are same
    tcur@ ~begin @ = IF tcur@ pagesz / pagesz *  DUP ~begin ! pagesz 2- + ~end ! SAVECLIP REFRESH EXIT THEN
--- if begin is set - select block else  just select the current line
    ~begin @ 1+
    IF tcur@ ~end !   ~end @ ~begin @ <=
---    swap begin and end if wrong way around (why not?)
      IF ~end @ ~begin @ SWAP  ~begin ! ~end ! THEN
    ELSE
      LEFTLN DUP ~begin ! ew 1- + ~end !
    THEN
    SAVECLIP REFRESH ;

pub EDPASTE --- paste text marked by ^B and ending in ^C to current cursor - skip terminators
    ~clipsz @ ?DUP IF clipboard + clipboard ( to from )
    BEGIN DUP C@ DUP $0D = IF DROP ELSE EDCHAR!! THEN
    1+ DUP 3RD >= UNTIL 2DROP THEN
    ~end @ 0= IF !CLIPS THEN REFRESH ;

pub EDCUT --- cut the selected block -OR- only copy if there is no begin
    ~clipsz @ 0= IF EDCOPY THEN
    ~begin @ tcur!  ~end @ ~begin @ DO $20 EDCHAR!! LOOP
    ~begin @ tcur!    !CLIP REFRESH ;



\       ... FILE OPERATIONS ...

--- check if file tab is active and open it - return with success flag
pri OPENTAB? ( -- f )   FTAB$ @ IF FTAB$ FOPEN$ ELSE DROP FALSE THEN ;
pri OPENTAB             OPENTAB? DROP ;

pri REVERT              save? CLRB OPENTAB tcur@ pagesz + ED@ DROP REDRAW ~end ~ ;
--- just revert the page for an undo for the present
pri UNDO                REVERT ;

--- open the config file and return with the ftab offset and flag
pri EDCFG ( -- a f )    s" FRED.CFG" FOPEN$ DUP IF 512 SDADR RW SWAP THEN ;

--- compare and save config and file tabs if changed
pri SAVECFG
    EDCFG 0EXIT DUP ~ftabs 512 COMPARE?
    NOT IF RW ~ftabs SWAP 512 MOVE FLUSH ELSE DROP THEN  ;
---   load config & file tabs                    else init ftabs and create config file
pri LOADCFG             EDCFG IF ~ftabs 512 MOVE ELSE ~ftabs 512 ERASE 32 KB FSIZE! SAVECFG THEN  ;



pub SAVEFILE
    ?SAVEPAGE RO MODIFIED SAVECFG
    @STATUS PRINT" SAVED    " OPENTAB ;

pri EDOPEN? ( s -- f )  EDINP DUP IF TIB + C~ TIB FOPEN$ THEN ;
pri EDDIR               PLAIN CLS HEADER  CRLF DIRW  ;




\       ... MULTIPLE FILE TABS ...

pri FIXTABS
    ~ftabs maxtabs 1- 5 << BOUNDS
    DO I @ 0= I FOPEN$ 0= OR  IF  I ftab* + I ftab* MOVE I ftab* + ftab* ERASE  THEN
    ftab* +LOOP ;
pri SHOWTAB             OPENTAB? IF ~page ~ ~edsect ~  ?PAGE ELSE -MINT REFRESH THEN ;
--- switch to next tab - save first then find the next active tab  (shouln't be necessary if trimmed)
pri NEXTTAB             SAVEFILE maxtabs 0 DO ~ftab C++ OPENTAB? IF LEAVE THEN LOOP SHOWTAB ;
pri PREVTAB             SAVEFILE maxtabs 0 DO -1 ~ftab C+! OPENTAB? IF LEAVE THEN LOOP SHOWTAB ;
--- find the next spare tab
pri NEWTAB              BEGIN ~ftab C++  FTAB$ @ 0= UNTIL ;
--- save current, setup new tab with name, sector, etc
pri ADDTAB              NEWTAB  file$ FTAB$ $!   0 tcur! -MINT ?PAGE SAVECFG ;
--- switch directly to the tab numbered 1..9
pub FTABx               SAVEFILE ~key C@ $31 - ~ftab C! FTAB$ @ if SHOWTAB ELSE NEXTTAB THEN ;

pub NEWFILE             SAVEFILE RWC s" NEW" EDOPEN? IF FORMAT.PAGES ADDTAB SHOWTAB THEN ;
pri ?NEWFILE            FTAB$ C@ 0= IF NEWFILE THEN ;
pub EDOPEN              SAVEFILE EDDIR s" OPEN: " EDOPEN? IF ADDTAB THEN SHOWTAB ;
pri CLOSETAB            SAVEFILE FTAB$ ftab* ERASE PREVTAB FIXTABS ?NEWFILE SAVECFG SHOWTAB ;
pri CLOSETABS           SAVEFILE FTAB$ 512 ERASE ~ftab C~ SHOWTAB ;
---     *** MOVE FILE TABS ***
ftab* bytes tabbuf
pri SWAPTAB ( src dst -- )      DUP tabbuf ftab* MOVE   2DUP ftab* MOVE   DROP tabbuf SWAP ftab* MOVE ;
pri MOVETABL                    @ftab 0EXIT FTAB$ DUP ftab* - SWAPTAB -1 ~ftab C+! ;
pri MOVETABR                    @ftab 1+ maxtabs = ?EXIT   FTAB$ DUP ftab* + SWAPTAB 1 ~ftab C+! ;
pub MOVETAB ( left -- )
    IF MOVETABL ELSE MOVETABR THEN
--- interactive left/right placement exits on any other key
    BEGIN REFRESH EDKEY   CASE $1B5B44 OF MOVETABL ENDOF $1B5B43 OF MOVETABR ENDOF EXIT ENDCASE AGAIN ;

\       ... FIND & HELP etc ...
pri ?EDFIND ( dir -- )
    ~find @
    IF tcur@ OVER +
      BEGIN DUP PAGE C@
      WHILE DUP PAGE TIB ~find @ C$=
         IF tcur! DROP REFRESH EXIT THEN
        OVER +
      REPEAT DROP
   THEN DROP @STATUS PRINT"  NOT FOUND     "
;
pub EDLINK
    TIB 32 ERASE tcur@ PAGE BEGIN 1- DUP C@ $21 < UNTIL 1+
    DUP BEGIN 1+ DUP C@ $21 < UNTIL OVER - TIB SWAP MOVE TIB LEN$ ~find ! 1 ?EDFIND                              ;

pub EDFIND              s" FIND " EDINP ~find ! 1 ?EDFIND ;

pri MARKEND             0 CLRLN REFRESH ;
pri GOPAGE              1 MAX 1- pagesz * tcur! REFRESH ;
pub EDPAGE              s" PAGE " EDNUM IF GOPAGE THEN ;
pub EDSIZE              s" LINES " EDNUM IF 2 >>  ~pagesz C!  THEN ;
pub EDWIDTH             s" COLUMNS " EDNUM IF 16 128 LIMIT ~dw C! THEN ;
pri EDESC               !CLIPS REDRAW ;
pri EDRET               CRLF PRINT" <RETURN>" KEY DROP CLS REFRESH ;
pri EDFF                PLAIN #FF ` * 80 EMITS CRLF ;
pri EDFULL              128 ~dw C! REDRAW ;
pri EDBS                1 tcur-! $20 EDCHAR! .LINE ;
pri EDNOP               REFRESH ;
pri REVTAB              tcur@ 8 - 7 ANDN tcur! ;
pri EDBEGIN             !CLIPS tcur@ ~begin ! ~end ~ ;
pri EDEDIT              wr? SETB REFRESH ;

\     *** PORTING UTILITY  from/to page files ***
pri IMPORT!
    DUP $0A $0D WITHIN
    IF OVER $0D = OVER $0A = AND NOT IF LEFTLN ew + tcur! THEN
     --- write the character directly to the page buffer
    ELSE DUP pagebuf tcur@ + C! 1 tcur+! THEN ;
pri IMPORTS ( srcsect size dstsec -- )
    3RD OVER AND 0= IF 2DROP EXIT THEN
--- reopen source as main file - setup dest
    ROT OPEN-SECTOR         ~edsect ! 0 tcur! MUTED
    WIPE.PAGE   0 SWAP 0 ( prevch size 0 )
    DO
--- get next char from source and end on null
      FGET ?DUP
--- process a single character checking for tabs
      IF DUP $09 =
        IF tcur@ 7 ANDN 8 + tcur!  ELSE IMPORT! THEN
--- else handle CR/LF or characters
--- replace prev   save one full page
        NIP       tcur@ pagesz >= IF SAVEPAGE pagesz 9 >> ~edsect +!     WIPE.PAGE 0 tcur! THEN
      ELSE LEAVE THEN
    LOOP
---  insert terminator line
    DROP LEFTLN ew + pagebuf + ew 1- 0 FILL
    SAVEPAGE UNMUTED ;
pub IMPORT ( <from> <to> -- )
    OPEN-FILE FSIZE@ ( sect size ) OPEN-FILE ( sect1 size sect2 ) IMPORTS ;
pub SAVEAS
    @FILE FSIZE@ ( src size )
    SAVEFILE RWC s" SAVE AS " EDOPEN?
    IF @FILE IMPORTS ADDTAB SHOWTAB ELSE 2DROP THEN ;



pri EDHELP              s" HELP" FOPEN$ IF 0 tcur! REFRESH THEN ;
pub EDPRINT             EDFF -FPRINT EDRET ;
pub EDPRINTP            EDFF BEGIN DUP C@ WHILE DUP C@ DUP EMIT $0D = IF $0A EMIT THEN 1+ REPEAT DROP EDRET ;
pub EDQUIT              SAVECFG 1 @FOOTER -INFO PRINT"  CLOSED " PLAIN !SP QUIT ;
--- this import is mainly for checking the include function






pub EDOUT               ['] EDCHAR!!  EMIT! ;
pri EDSTAMP             DATE@ EDOUT 6 Z U.R ` - EMIT TIME@ 100 / 4 Z U.R CON ;
pri PAGE/CLIP ( -- a )
    1 @FOOTER  CRLF
    ~clipsz @ ?DUP IF clipboard + C~ clipboard   DUP ~clipsz + C~
--- force a CR and null terminator into last 2 char of page
    ELSE $0D PAGEBUF pagesz 2- + H! PAGEBUF THEN
;
--- go to last char in line -
pri ENDLN               LEFTLN ew + BEGIN 1- DUP ED@ $20 > UNTIL 1+ tcur! ;
pri ENDTEXT             tcur@ BEGIN 1+ DUP ED@ 0= UNTIL tcur! REFRESH ;
pri ENDKEY              tcur@ ED@ 0= IF LNDN ENDTEXT ELSE tcur@ ENDLN tcur@ = IF ENDTEXT THEN THEN ;

--- If cursor is already on left then go to page or file home
pri HOMEKEY
    PAGEADR tcur@ = IF 0 tcur! ~offset C~  REFRESH EXIT THEN
    LEFTLN tcur@ = IF PAGEADR tcur! REFRESH ELSE LEFTLN tcur! THEN
;

\ ****************************************************
\ *KEYS*           *** KEY COMMANDS ***
\ ****************************************************

(       *** FUNCTION KEYS F1-F10 ETC ***        )

pri F1          EDHELP ;
pri F2          ;
pri F3          1 ?EDFIND REFRESH ;
pri F4          ;
pri F5          ;
pri F6          ;
pri F7          ;
pri F8          ;
pri F9          dw 8 + $7 ANDN ew 1+ MOD 64 MAX ~dw C! REDRAW ;
pri F10         SAVEFILE SAVECFG OPENTAB 1 @FOOTER CRLF  0 RELOAD ;
pri F11         ;
pri F12         EDDIR EDKEY DROP file$ FOPEN$ DROP REFRESH ;
pri ^F10        PLAIN  1 @FOOTER CRLF PAGE/CLIP MLOAD QUIT ;
pri _F3         -1 ?EDFIND REFRESH ;


\       *** CTL+ESC KEYS ***

pri ^HOME       0 tcur! ~offset C~ REFRESH ;
pri ^END        ENDTEXT ;
pri ^PGUP       PGUP PGUP PGUP PGUP ;
pri ^PGDN       PGDN PGDN PGDN PGDN ;
pri ^LEFT       8 tcur-! ;
pri ^RIGHT      8 tcur+! ;
pri ^UP         LNUP LNUP LNUP LNUP ;
pri ^DOWN       LNDN LNDN LNDN LNDN ;
\       *** CSI ESCAPE SEQUENCES ***
CREATE CSIVECS
    $001B5B48 , ' HOMEKEY ,     $001B4F46 , ' ENDKEY ,
    $001B5B56 , ' PGUP ,        $001B5B55 , ' PGDN ,
    $5B313341 , ' PGUP ,        $5B313342 , ' PGDN ,
    $001B5B44 , ' GOLEFT ,      $001B5B43 , ' GORIGHT ,
    $001B5B41 , ' LNUP ,        $001B5B42 , ' LNDN ,
    $001B5B5A , ' REVTAB ,      $00001B0D , ' INSLN ,
    $001B4F4D , ' DELLN ,       $00001B1B , ' EDESC ,
    $001B5B40 , ' EDINS ,       $00001B7F , ' DELCH ,
    --- ALT ---
    $5B313346 , ' MARKEND ,
    $5B35337E , ' PREVTAB ,     $5B36337E , ' NEXTTAB ,
    $5B313344 , ' PREVTAB ,     $5B313343 , ' NEXTTAB ,
    $5B33337E , ' WIPELN ,
    $00001B53 , ' SAVEAS ,      $00001B73 , ' SAVEAS ,
---     ALT 1..9 switch to FILE TAB
    $1B31 , ' FTABX , $1B32 , ' FTABX , $1B33 , ' FTABX , $1B34 , ' FTABX ,
    $1B35 , ' FTABX , $1B36 , ' FTABX , $1B37 , ' FTABX , $1B38 , ' FTABX ,
    $1B39 , ' FTABX ,

    --- CTRL ---
    $5B313548 , ' ^HOME ,       $5B313546 , ' ^END ,
    $5B35357E , ' ^PGUP ,       $5B36357E , ' ^PGDN ,
    $5B313544 , ' ^LEFT ,       $5B313543 , ' ^RIGHT ,
    $5B313541 , ' ^UP ,         $5B313542 , ' ^DOWN ,
    $5B33357E , ' DELLN ,       $1B4F3552 , ' EDLINK ,







    --- FUNCTION KEYS ---
    $001B4F50 , ' F1 ,          $001B4F51 , ' F2 ,
    $001B4F52 , ' F3 ,          $001B4F53 , ' F4 ,
    $001B4F54 , ' F5 ,          $001B4F55 , ' F6 ,
    $001B4F56 , ' F7 ,          $001B4F57 , ' F8 ,
    $001B4F58 , ' F9 ,          $5B32317E , ' F10 ,
    $001B4F59 , ' F12 ,
    --- CTRL FUNCTION KEYS ---
    $3231357E , ' ^F10 ,
    --- SHIFT FUNCTION KEYS ---
    $1B4F3252 , ' _F3 ,


    --- VT100 CODES ---
    $1B5B357E , ' PGUP ,        $1B5B367E , ' PGDN ,
    $1B5B317E , ' HOMEKEY ,     $001B4F46 , ' ENDKEY ,
    $1B5B327E , ' EDINS ,       $1B5B337E , ' DELCH ,
    $001B4F50 , ' F1 ,          $001B4F51 , ' F2 ,
    $001B4F52 , ' F3 ,          $001B4F53 , ' F4 ,
    $5B31367E , ' F5 ,          $5B31377E , ' F6 ,
    $5B31387E , ' F7 ,          $5B31397E , ' F8 ,
    $5B32307E , ' F9 ,          $5B32317E , ' F10 ,
    $5B32347E , ' F12 ,         $5B31317E , ' F1 ,
    $1B5B347E , ' ENDKEY ,      $5B31337E , ' F3 ,
    $001B5B46 , ' ENDKEY ,

    $00000000 ,  --- table terminator



(       *** CONTROL SEQUENCE COMMANDS ***       )
--- extended commands are  ^Y followed by another key
pri EDCMD
    EDKEY a>A CASE
    ` I OF indent? TOGB REFRESH                 ENDOF
    ` N OF lines?  TOGB REFRESH                 ENDOF
    ` X OF MARKEND                              ENDOF   --- erase current line (nulls)
    ` Z OF WIPE.PAGE REFRESH                    ENDOF   --- wipe & format page
    ^ P OF PAGE/CLIP EDPRINTP                   ENDOF   --- print page or clipboard
    ^ Q OF 1 @FOOTER  PLAIN CRLF QUIT           ENDOF   --- special debug quit
    ^ Z OF ?FORMAT.PAGES REFRESH                ENDOF   --- page format the whole file
    ` L OF EDSIZE REDRAW                        ENDOF   --- set new page size
    ` C OF EDWIDTH REDRAW                       ENDOF
    ` 0 OF -MONO REFRESH                        ENDOF   --- mono theme
    ` 1 OF -MINT REFRESH                        ENDOF
    ` 2 OF -DARK REFRESH                        ENDOF
    ` 3 OF -DAY REFRESH                         ENDOF
    ` 4 OF -BRIGHT REFRESH                      ENDOF
    ` 5 OF -C64 REFRESH                         ENDOF
    ` 6 OF -LOGO REFRESH                        ENDOF
    ` 7 OF -BLUE REFRESH                        ENDOF
    ` W OF wr? TOGB REFRESH                     ENDOF   --- toggle read/write & read-only mode
    ` T OF EDSTAMP .LINE                        ENDOF
    $1B5B44 OF 1 MOVETAB                        ENDOF
    $1B5B43 OF 0 MOVETAB                        ENDOF
    $0D OF FORMAT.PAGE REFRESH                  ENDOF
    $20 OF WIPELN                               ENDOF   --- blank current line (spaces)
    ENDCASE
;



\                        *** CONTROL KEYS ***
--- control key execution vectors 0..31
CREATE EDCTLS
        ' EDNOP ,
        ' GOLEFT ,      ' EDBEGIN ,     ' EDCOPY ,      ' GORIGHT ,     --- A B C D
        ' EDEDIT ,      ' EDFIND ,      ' EDPAGE ,      ' EDBS ,        --- E F G H
        ' EDTAB ,       ' EDNOP ,       ' EDINS ,       ' PGDN ,        --- I J K L
        ' EDCR ,        ' NEWFILE ,     ' EDOPEN ,      ' EDPRINT ,     --- M N O P
        ' EDQUIT ,      ' REVERT ,      ' SAVEFILE ,    ' EDNOP ,       --- Q R S T
        ' EDLINK ,      ' EDPASTE ,     ' CLOSETAB ,    ' EDCUT ,       --- U V W X
        ' EDCMD ,       ' UNDO ,        ' EDESC ,       ' EDNOP ,       --- Y Z [ \
        ' EDFULL ,      ' EDNOP ,       ' EDNOP ,                       --- ] ^ _
\ J T U \ ] ^ _

--- scan CSI vectors for matching key sequence code and execute - othewwise ignore
pri EDCSI       CSIVECS BEGIN DUP @ WHILE OVER OVER @ = IF NIP 4 + @ EXECUTE EXIT THEN 8 + REPEAT ;

pri ?INS        ins? BIT? IF tcur@ PAGE DUP 1+ ew @x - 2- MOVE THEN  ;
--- process key input into: controls - characters - CSI escape keys
pri EDKEY:
--- process control keys via EDCTLS table
    DUP $20 < IF 2 << EDCTLS + @ EXECUTE EXIT THEN
--- in case an ASCII DEL key is received (normally it's a CSI seq)
    DUP $7F = IF DROP EDBS EXIT THEN
--- if key > $FF then display the seq & process else insert/write char
    DUP 8 >> IF DUP 1 @FOOTER .L !TEXTXY EDCSI   ELSE ?INS EDCHAR  THEN
;





(       ... MAIN EDITOR TASK ...        )


--- main task loop handles keyboard input and idle time checks
pri EDTASK ( <addr>  -- )
    tcur! file$ FTAB$ $!
    CLS REFRESH
    cycles ~idle ! SHOWTAB
    BEGIN
      !SP   KEY?
        IF cycles ~idle !   -TEXT EDKEY EDKEY: !TEXTXY
        ELSE ?IDLE POLLS
        THEN
    AGAIN
;

(       *** INIT EDIT ***      )
pri !ED
    SD? 0= IF ."  No SD CARD! " QUIT THEN
    !MOUNT
    ~edcold @ $A55A <>
    IF
      ~edsect ~edcold OVER - ERASE
      -MINT
      ~edsect ~~  128 ~dw C! =pagesz 9 >> ~pagesz C!
      256 KB FSIZE!
      $A55A ~edcold !
    THEN
;



(       *** EDITOR ENTRY MODES ***      )

--- edit a sector (current in text mode)
pub EDSECT      !ED OPEN-SECTOR file$ 16 ERASE s" SECTOR" file$ SWAP MOVE 0 EDTASK ;

--- Create a new preformatted file - default size = 1MB (else use "n FSIZE! EDNEW <name>")
pub EDNEW       !ED RWC OPEN-FILE IF FORMAT.PAGES 0 EDTASK THEN ;

pri ^ED         !SP R> DROP SD? IF !ED LOADCFG FIXTABS OPENTAB? IF tcur@ EDTASK THEN THEN ;

--- Edit FRED itself
pub EDME          !ED -MINT indent? SETB s" FRED" FOPEN$ IF tcur@ EDTASK THEN ;
--- edit a file or if none specified then the last one opened
pub ED ( ED <file> )
    SD? 0= ~sdpins @ 0=  OR IF PRINT"  Sorry - no SD card! " EXIT THEN
    !ED LOADCFG FIXTABS  GET$ DUP LEN$
      IF SPACE FOPEN$ IF -MINT indent? SETB  0 EDTASK THEN
--- try to reopen the last file at the same position
      ELSE OPENTAB? IF tcur@ EDTASK THEN
      THEN
    PRINT"  Unknown file " DIRW
    ;

0 bytes org? --- update free data org
\ 16096  code bytes and 596 data bytes
*END*
