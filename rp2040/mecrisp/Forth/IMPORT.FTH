\     *** PORTING UTILITY  from/to page files ***
pri IMPORT!
    DUP $0A $0D WITHIN
    IF OVER $0D = OVER $0A = AND NOT IF LEFTLN ew + tcur! THEN
     --- write the character directly to the page buffer
    ELSE DUP pagebuf tcur@ + C! 1 tcur+! THEN
;
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
        IF tcur@ 7 ANDN 8 + tcur!
--- else handle CR/LF or characters
        ELSE IMPORT!
        THEN
--- replace prev   save one full page
        NIP       tcur@ pagesz >= IF SAVEPAGE pagesz 9 >> ~edsect +!     WIPE.PAGE 0 tcur! THEN
      ELSE LEAVE THEN
    LOOP
---  insert terminator line
    DROP LEFTLN ew + pagebuf + ew 1- 0 FILL
    SAVEPAGE UNMUTED
;
pub IMPORT ( <from> <to> -- )
    OPEN-FILE FSIZE@ ( sect size ) OPEN-FILE ( sect1 size sect2 ) IMPORTS ;