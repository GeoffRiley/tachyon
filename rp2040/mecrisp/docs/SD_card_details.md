# SD Cards

Notes on the architecture of SD cards and microSD cards in particular.

We are aiming to operate in the SPI Mode which is a secondary protocol offered through the SD Memory Card protocol.
This is actually a subset of the full SD protocol operating in a single bit serial rather than a four bit parallel mode.

The following structures are used by the various command to send and receive data.

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

## Command Classes

The SD protocol has twelve classes of command defined, however, the SPI version does not support three of these classes: 1, 3 and 9. Most commands are mandatory and *should* be reliable whilst a number are optional and may not be implemented.

### Class 0—Basic

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD0 | Mandatory | [31:0]Fill | R1 | GO_IDLE_STATE | Reset the SD Card
CMD1 | Mandatory | [31]Reserved_bit [30]HCS [29:0]Reserved_bits | R1 | SEND_OP_COND | Sends host capacity support information and activate the card's initialisation process. HCS is effective the the card received SEND_IF_COND command
CMD8 | Mandatory | [31:12]Reserved_bits [11:8]Supply_voltage(Vhs) [7:0]Check_pattern | R7 | SEND_IF_COND | Sends SD memory Card interface condition that included host supply voltage information and asks the accessed card whether card can operate in supplied voltage range.
CMD9 | Mandatory | [31:0]Fill | R1 | SEND_CSD | Asks the selected card to send its card-specific data (CSD)
CMD10 | Mandatory | [31:0]Fill | R1 | SEND_CID | Asks trhe selected card to send its card identification (CID)
CMD12 | Mandatory | [31:0]Fill | R1b | STOP_TRANSMISSION | Forces the card to stop transmission in Multiple Block Read Operation.
CMD13 | Mandatory | [31:0]Fill | R2 | SEND_STATUS | Asks the selected card to send its status register.
CMD58 | Mandatory | [31:0]Fill | R3 | READ_OCR | Reads the OCR register of a card. CCS bit is assigned to OCR[30]
CMD59 | Mandatory | [31:1]Fill [0]CRC_option | R1 | CRC_ON_OFF | Turns the CRC option on or off. | '1' in the CRC option bit will turn the option on, a '0' will turn it off.

* R1b is an R1 result with an optional trailing busy signal.

### Class 2—Block Read

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD16 | Mandatory | [31:0]Block_length | R1 | SET_BLOCKLEN | In case of SDSC Card, block length is set by this command. In case of SDHC and SDXC Cards, block length of the memory access comands are fixed to 12 bytes. The length of LOCK_UNLOCK command is set by this command regardless of card capacity.
CMD17 | Mandatory | [31:0]Data_address | R1 | READ_SINGLE_BLOCK | Reads a block of size selected by the SET_BLOCKLEN command.
CMD18 | Mandatory | [31:0]Data_address | R1 | READ_MULTIPLE_BLOCK | Continuously transfers dataa blocks from card to host until interrupted by a STOP_TRANSMISSION command.

### Class 4—Block Write

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD16 | Mandatory | [31:0]Block_length | R1 | SET_BLOCKLEN | In case of SDSC Card, block length is set by this command. In case of SDHC and SDXC Cards, block length of the memory access comands are fixed to 12 bytes. The length of LOCK_UNLOCK command is set by this command regardless of card capacity.
CMD24 | Mandatory | [31:0]Data_address | R1 | WRITE_BLOCK | Writes a block of the size selected by the SET_BLOCKLEN command.
CMD25 | Mandatory | [31:0]Data_address | R1 | WRITE_MULTIPLE_BLOCK | Continuously write blocks of data until 'STOP TRAN' token is sent rather than 'START BLOCK' token.
CMD27 | Mandatory | [31:0]Fill | R1 | PROGRAM_CSD | Programming of the programmable bits of the CSD.


### Class 5—Erase

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD32 | Mandatory | 
CMD33 | Mandatory | 
CMD38 | Mandatory | 

### Class 6—Write Protection

In each case these commands only operate if the card has write protection features. SDHC and SDXC cards do not implement these commands.

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD28 | Optional | [31:0]Data_address | R1b | SET_WRITE_PROT | This command sets the write protection bit of the addressed group. The properties of write protection are coded in the cad specific data (WP_GRP_SIZE).
CMD29 | Optional | [31:0]Data_address | R1b | CLR_WRITE_PROT | This command clears the write protection bit of the addressed group.
CMD30 | Optional | [31:0]Write_protect_data_address | R1 | SEND_WRITE_PROT | This command asks the card to send the status of the write protection bits.

* R1b is an R1 result with an optional trailing busy signal.

### Class 7—Lock Card

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD16 | Mandatory | [31:0]Block_length | R1 | SET_BLOCKLEN | In case of SDSC Card, block length is set by this command. In case of SDHC and SDXC Cards, block length of the memory access comands are fixed to 12 bytes. The length of LOCK_UNLOCK command is set by this command regardless of card capacity.
CMD42 | *(note)* | [31:0]Reserved_bits | R1 | LOCK_UNLOCK | Used to set/reset the Password or lock/unlock the card. A transferred datablock includes all the command details. The size of the Data Block is defined with SET_BLOCK_LEN command.

* CMD42 is optional for protocol versions 1.01 and 1.10; mandatory for protocol version 2.0
### Class 8—Application Specific

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD55 | Mandatory | [31:0]Fill | R1 | APP_CMD | Defines to the card that the next command is an application specific command rather than a standard command.
CMD56 | Mandatory | [31:1]Fill [0]RD/WR | R1 | GEN_CMD | Used to transfer a Data Block to the card or to get a Data Block from the card for general purpose/application specific commands. In case of Standard Capacity SD Memory Card, the size of the Data Block shall be defined with SET_CLOCK_LEN command. In case of SDHC and SDXC cards, block length is fixed to 512 bytes.
ACMD6 | Mandatory | Not implemented in SPI Mode.
ACMD13 | Mandatory | [31:0]Fill | R2 | SD_STATUS | Send the SD Status.
ACMD22 | Mandatory | [31:0]Fill | R1 | SEND_NUM_WR_BLOCKS | Send the numbers of the well written (without errors) blocks. Responds with 32 bit + CRC data block.
ACMD23 | Mandatory | [31:23]Fill [22:0]Number_of_blocks | R1 | SET_WR_BLK_ERASE_COUNT | Set the number of write blocks to be pre-erased before writing (to be used for faster Multiple Block WR command). '1'=default (one wr block).
ACMD41 | Mandatory | [31]Reserved_bit [30]HCS [29:0]Reserved_bits | R1 | SD_SEND_OP_COND | Sends host capacity support information and activates the card's initialisation process.
ACMD42 | Mandatory | [31:1]Fill [0]Set_CD | R1 | SET_CLR_CARD_DETECT | Connect(1) or Disconnect(0) the 50KΩ pull-up resistor on CS (pin-1) of the card. The pull-up may be used for card detection.
ACMD51 | Mandatory | [31:0]Fill | R1 | SEND_SCR | Reads the SD Configuration Register (SCR).

### Class 10—Switch

Command | Mandatory / Optional | Argument | Abbreviation | Description
:---: | --- | --- | :---: | ---
CMD6 | Mandatory | [31]Mode [30:24]Reserved [23:20]FN_group_6 [19:16]FN_group_5 [15:12]FN_group_4 [11:8]FN_group_3 [7:4]FN_group_2 [3:0]FN_group_1 | R1 | SWITCH_FUNC | Mode=0: Checks switchable function; Mode=1: Switch card function.
CMD34 | Optional | 
CMD35 | Optional | 
CMD36 | Optional | 
CMD37 | Optional | 
CMD50 | Optional | 
CMD57 | Optional | 

* CMD24-37, CMD50 and CMD57 are all reserved for SD command expansion and depend upon the states of the switch groups selected.

#### CMD6 Mode 0—Check switchable function

A single function may be selected in each of the six groups in a single invocation of CMD6. The default function is done by setting the function to zero. Select a specific function by using the appropriate value form the table below. Selecting 0xF will keep the current function that has been selected for the function group.

The response returns three statuses:
* The functions that are supported by each of the function groups.
* The function that the card will switch to in each of the function groups. This value is identical to the provided argument if the host made a value selection or 0xF if the selected function was invalid.
* Maximum current consumption under the selected functions. If one of the selected functions was wrong, the return value will be zero.

Group No. | 6 | 5 | 4 | 3 | 2 | 1
:---: | :---: | :---: | :---: | :---: | :---: | :---:
**Func name** | **reserved** | **reserved** | **Current Limit** | **Driver Strength** | **Command system** | **Access mode**
0x0 | Default | Default | Default 200mA | Default Type_B | Default | Default SDR12
0x1 | Reserved | Reserved | 400mA | Type_A | For_eC | High-Speed SDR25
0x2 | Reserved | Reserved | 600mA | Type_C | Reserved | SDR50
0x3 | Reserved | Reserved | 800mA | Type_D | OTP | SDR104
0x4 | Reserved | Reserved | Reserved | Reserved | ASSD | DDR50
0x5 | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0x6 | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0x7 | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0x8 | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0x9 | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0xA | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0xB | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0xC | Reserved | Reserved | Reserved | Reserved | (eSD) | Reserved
0xD | Reserved | Reserved | Reserved | Reserved | Reserved | Reserved
0xE | Reserved | Reserved | Reserved | Reserved | Vendor Specific | Reserved
0xF | No influence | No influence | No influence | No influence | No influence | No influence

#### CMD6 Mode 1—Switch card function

Again, a single function may be selected in each of the six groups in a single invocation of CMD6. The default function is done by setting the function to zero. It is recommended to specify 0xF (no influence) for all functions except the one that requires changing, select from the table above.

The response returns three statuses:
* The functions that are supported by each of the function groups.
* The function that is the result of the switch command. In case of invalid selection of one function or more, all set values are ignored and no change will be done (identical to the case where 0xF is selected for all groups). The response to an invalid selection will be 0xF.
* Maximum current consumption under the selected functions. If one of the selected functions was wrong, the return value will be zero.

### Class 11—Reserved

No commands defined.

