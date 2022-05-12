# SD Cards

Notes on the architecture of SD cards and microSD cards in particular.

## Coded Structures

### CID (Card Identification) Register Definitions

Name | Type | Width (bits) | CID Value | Comments
--- | --- | :---: | :---: | ---
Manufacturer ID *(MID)* | Binary | 8 | 0x03 | MIDs are controlled and assigned by the SD-3C, LLC
OEM/App ID *(OID)* | ASCII | 16 | "SD" ASCII Code $53, $44 | Ids the card OEM and/or the card contents. The OID is controlled and assigned by the SD-3C, LLC
Product Name *(PNM)* | ASCII | 40 | "SD32G", "SD16G", "SD08G", "SD06G", "SD04G", "SD02G", "SD01G" | Five char string
Product Revision *(PRV)* | BDC | 8 | $hl | Product revision h.l
Serial Number *(PSN)* | Binary | 32 | Product serial number | 32-bit unsigned integer
Reserved | - | 4 | - | -
Manufacturer Date Code *(MDT)* | BCD | eg April 2010 = $104 | Manufacturing date—yym offset from 2000
CRC7 Checksum *(CRC)* | Binary | 7 | CRC7 | Calculated
Not used, always 1 | - | 1 | - | -

### RCA (Relative Card Address)

*Not available in SPI mode*

### DSR (Driver State Register)

This is optional and not present on SanDisk microSD cards.

### CSD (Card Specific Data) Register Definitions

The CSD register holds configuration information required to access the card data. It defines the data format, error correction, maximum data access time, and so on. The actual field structure of the CSD varies depending upon the physical structure of the card and its capacity.

The CSD begins with a CSD Register Structure that then acts as a header for the following full Register.

#### CSD Structure

CSD_Structure | CSD Structure Version | Valid for SD Physical Specification / Card Capacity
:---: | :---: | ---
0 | CSD Version 1.0 | Version 1.01 to 1.10 and Version 2.00/Standard Capacity
1 | CSD Version 2.0 | Version 2.00/High Capacity
2 | Reserved | -
3 | Reserved | -

### SCR (SD Configuration Register)

### OCR (Operation Control Register) Definition

The OCR stores a cards VDD voltage profile.

### SSR (SD Status Register)

This is the first of two status fields provided by an SD memory card.  This is the SD Status comprising an extended status field of 512 bits that support special features of the card along with future application specific features.

### CSR (Card Status Register)

This is the second of two status fields provided by an SD memory card. This is the Card Status comprising a 32 bit field. The intended use of CSR is to transmit the card's status information to the host. If not specified otherwise, the status entries are always related to the previous issued command.

The following table defines the entries of the status register. Unused and reserved bits should always be set to zero.

The columns type and clear condition use the following symbols:

- Type
  Symbol | Description
  :---: | ---
  E | Error bit
  S | Status bit
  R | Detected and set for the actual command response
  X | Detected and set during the previous command. Reception of a valid command will clear it (with a delay of one command)

- Clear Condition
  Symbol | Description
  :---: | ---
  A | According to the card current state
  B | Always related to the previous command. Reception of a valid command will clear it (with a delay of one command)
  C | Clear by read

Bits | Identifier | Type | Value | Description | Clear Condition
:---: | --- | :---: | --- | --- | :---:
31 | OUT_OF_RANGE | E R X | '0'=no_error '1'=error | The command's argument was out of the allowed range for this card | C
30 | ADDRESS_ERROR | E R X | '0'=no_error '1'=error | A misaligned address which did not match the block length was used in the command | C
29 | BLOCK_LEN_ERROR | E R X | '0'=no_error '1'=error | The transferred block length is not allowed for this card, or the number of transferred bytes does not match the block length | C
28 | ERASE_SEQ_ERROR | E R | '0'=no_error '1'=error | An error in the sequence of erase commands occurred | C
27 | ERASE_PARAM | E R X | '0'=no_error '1'=error | An invalid selection of write-blocks for erase occurred | C
26 | WP_VIOLATION | E R X | '0'=not_protected '1'=protected | Set when the host attempts to write to a protected block or to the temporary or permanent write protected card | C
25 | CARD_IS_LOCKED | S X | '0'=card_unlocked '1'=card_locked | When set, signals that the card is locked by the host | A
24 | LOCK_UNLOCK_FAILED | E R X | '0'=no_error '1'=error | Set when a sequence or password error has been detected in lock/unlock card command | C
23 | COM_CRC_ERROR | E R | '0'=no_error '1'=error | RThe CRC check of the previous command failed | B
22 | ILLEGAL_COMMAND | E R | '0'=no_error '1'=error | Command not legal for the card state | B
21 | CARD_ECC_FAILED | E R X | '0'=no_error '1'=error | Card internal ECC was applied but failed to correct data | C
20 | CC_ERROR | E R X | '0'=no_error '1'=error | Internal card controller error | C
19 | ERROR | E R X | '0'=no_error '1'=error | A general or an unknown error occurred during the operation | C
18 | reserved
17 | reserved for DEFERRED_RESPONSE
16 | CSD_OVERWRITE | E R X | '0'=no_error '1'=error | Can be either one of the following errors:<br/>The read only section of the CSD does not match the card content<br/>An attempt to reverse the copy (set as original) or permanent WP (unprotected) bits was made | C
15 | WP_ERASE_SKIP | E R X | '0'=not_protected '1'=protected | Set when only partial address space was erased due to existing write protected blocks or the temporary or permanent write protected card was erased | C
14 | CARD_ECC_DISABLED | S X | '0'=enabled '1'=disabled | The command has been executed without using the internal ECC | A
13 | ERASE_RESET | S R | '0'=cleared '1'=set | An erase sequence was cleared before executing because an out of erase sequence command was received | C
12:9 | CURRENT_STATE | S X | "0"=idle "1"=ready "2"=ident "3"=stby "4"=tran "5"=data "6"=rcv "7"=prg "8"=dis "9"-"14"=reserved "15"=reserved_for_I/O_mode | The state of the card when receiving the command. If the command execution causes a state change, it will be visible to the host in the response to the next command. The four bits are interpreted as a binary coded number between zero and 15 | B
8 | READY_FOR_DATA | S X | "0"=not_ready "1"=read | Corresponds to buffer empty signalling on the bus | A
7:6 | reserved
5 | APP_CMD | S R | "0"=disabled "1"=enabled | The card will expect ACMD, or an indication that the command has been interpreted as ACMD | C
4 | reserved for SD I/O Card
3 | AKE_SEQ_ERROR (SD Memory Card app. spec.) | E R | '0'=no_error '1'=error | Error in the sequence of the authentication process | C
2 | reserved for application specific commands
1:0 | reserved for manufacturer test mode



## CRC7 Calculation

The CRC7 (Cyclic Redundancy Code—7 bit) is a method of ensuring that transmissions between the SD card and the host are free from errors. A CRC is calculated for each command, each response and for each transferred data block.

The calculation is made based on the expansion of the following polynomial:
  G(x) = x<sup>7</sup> + x<sup>3</sup> + 1  
  M(x) = b<sub>0</sub> * x<sup>n</sup> + b<sub>1</sub> * x<sup>n-1</sup> + … + b<sub>n</sub> * x<sup>0</sup>  
  CRC[6…0] = (M(x) * x<sup>7</sup>) *mod* G(x)

Where *b* is the stream of bits to be encoded from left to right; and *n* is the number of bits minus one being protected by the CRC. For example, commands and responses are forty bits long (5 bytes) and so *n* = 39; whereas CSD and CID records are 120 bits long (15 bytes) leading to *n* = 119.

### Example Commands with CRC7

See (Command Format)[#Command Format]

Command | Arg | A | B | C | D | E
--- | :---: | :---: | :---: | :---: | :---: | :---:
CMD0 | 0 | 01 | 000000 | 00000000 00000000 00000000 00000000 | 1001010 | 1
CMD17 | 0 | 01 | 010001 | 00000000 00000000 00000000 00000000 | 0101010 | 1
CMD17 Resp | | 00 | 010001 | 00000000 00000000 00001001 00000000 | 0110011 | 1


- A: Start and Transmission bit
- B: Command index
- C: Argument
- D: CRC (calculated)
- E: Stop bit
## Command Format

All commands have a fixed code length of 48 bits, most significant bit sent first:

Bit position | Width (bits) | Value | Description
:---: | :---: | :---: | ---
47 | 1 | "0" | Start bit
46 | 1 | "1" | Transmission bit
[45:40] | 6 | x | Command index
[39:8] | 32 | x | Argument
[7:1] | 7 | c | CRC7
0 | 1 | "1" | End bit

The start bit is always zero and followed by the transmission direction bit, one indicates from host, the next six bits represent the binary coded integer value of the command index (ranging from zero to 63). Some commands require an argument such as an address and this is coded in the next 32 bits.
All values represented by *x* in the above table are dependent upon the particular command, and the CRC, *c* is calculated across all the bits from positions [47:8].
Every command is terminated by an end bit of one.