; 
; Title:        LLIST to print to thermal printer
; Author:       Richard Turnnidge 2024
;
    include "macros.inc"

    .assume adl=1   ; We start up in full 24bit mode, allowing full memory access and 24-bit wide registers
    .org $0B0000    ; This program assembles to MOSlet RAm area
;    .org $040000    ; This program assembles to the first mapped RAM location, start for user programs

    jp start        ; skip headers

; Quark MOS header 
    .align 64       ; Quark MOS expects programs that it LOADs,to have a specific signature
                    ; Starting from decimal 64 onwards
    .db "MOS"       ; MOS header 'magic' characters
    .db 00h         ; MOS header version 0 - the only in existence currently afaik
    .db 01h         ; Flag for run mode (0: Z80, 1: ADL) - We start up in ADL mode here

_exec_name:     .DB  "LLIST.bin", 0      ; The executable name, only used in argv
argv_ptrs_max:      EQU 16          ; Maximum number of arguments allowed in argv

; ---------------------------------------------
;
;   INITIAL SETUP CODE HERE
;
; ---------------------------------------------

start:                      ; Start code here
    push af                 ; Push all registers to the stack
    push bc
    push de
    push ix
    push iy


    LD IX, argv_ptrs       ; The argv array pointer address
    PUSH IX
    CALL _parse_params     ; Parse the parameters
    POP IX                 ; IX: argv  
    LD B, 0                ;  C: argc
    LD B, C                ; B: # of arguments


    ld hl, (ix+3)           ; address of first arg, is a 0 terminated string for the file

    ld de, fileStoreHere    ; load if file extists
    ld bc, 1024
    MOSCALL $01

    cp 0                    ; check for error, exit if can't open file
    jp nz, printError

    call printMSG           ; print 'printing' MSG
    ld ix, argv_ptrs        ; address of arument pointers
    ld hl, (ix+3)           ; address of first arg, is a 0 terminated string for the file
    call PRSTR              ; display file name parsed
    ld hl, s_CRLF           ; next do a CR/LF
    call PRSTR   
    call PRINT_LOOP         ; xcall the actual serial printer loop
    call doneMSG            ; say we're done

now_exit:
                            ; Cleanup stack, prepare for return to MOS

    pop iy                  ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0                 ; Load the MOS API return code (0) for no errors.
 
    ret                     ; Return to MOS

; ---------------------------------------------

printError:
    ld hl, errMSG
    call PRSTR

    jp now_exit


PRINT_LOOP:
    call openUART1
    ld hl, fileStoreHere
    call PRSTR                     ; prints to screen *** not needed
    ld hl, fileStoreHere
    call LPRINT
    call closeUART1
    ret

LPRINT:
    LD  A,(HL)
    OR  A
    RET Z
    ld c, a 
    MOSCALL $18                     ; put C char to serial
    INC HL
    ld a, 00000010b
    call multiPurposeDelay
    JR  LPRINT

    ret


; ---------------------------------------------

; Print a zero-terminated string

PRSTR:      
    LD A,(HL)
    OR A
    RET Z
    RST.LIL 10h
    INC HL
    JR PRSTR

; ---------------------------------------------
; Parse the parameter string into a C array
; Parameters
; - HL: Address of parameter string
; - IX: Address for array pointer storage
; Returns:
; -  C: Number of parameters parsed

_parse_params:      
    LD  BC, _exec_name
    LD  (IX+0), BC                  ; ARGV[0] = the executable name
    INC IX
    INC IX
    INC IX
    CALL _skip_spaces               ; Skip HL past any leading spaces

    LD  BC, 1                       ; C: ARGC = 1 - also clears out top 16 bits of BCU
    LD  B, argv_ptrs_max - 1        ; B: Maximum number of argv_ptrs

_parse_params_1:    
    PUSH BC                         ; Stack ARGC    
    PUSH HL                         ; Stack start address of token
    CALL _get_token                 ; Get the next token
    LD A, C                         ; A: Length of the token in characters
    POP DE                          ; Start address of token (was in HL)
    POP BC                          ; ARGC
    OR A                            ; Check for A=0 (no token found) OR at end of string
    RET Z

    LD  (IX+0), DE                  ; Store the pointer to the token
    PUSH HL                         ; DE=HL
    POP DE
    CALL    _skip_spaces            ; And skip HL past any spaces onto the next character
    XOR A
    LD (DE), A                      ; Zero-terminate the token
    INC IX
    INC IX
    INC IX                          ; Advance to next pointer position
    INC C                           ; Increment ARGC
    LD  A, C                        ; Check for C >= A
    CP  B
    JR  C, _parse_params_1          ; And loop
    RET


; ---------------------------------------------

; Skip spaces in the parameter string
; Parameters:
; - HL: Address of parameter string
; Returns:
; - HL: Address of next none-space character
;    F: Z if at end of string, otherwise NZ if there are more tokens to be parsed
;
_skip_spaces:       
        LD  A, (HL)                 ; Get the character from the parameter string   
            CP  ' '                 ; Exit if not space
            RET NZ
            INC HL                  ; Advance to next character
            JR  _skip_spaces        ; Increment length

        
; ---------------------------------------------

; Get the next token
; Parameters:
; - HL: Address of parameter string
; Returns:
; - HL: Address of first character after token
; -  C: Length of token (in characters)

_get_token:     
    LD C, 0                         ; Initialise length
nt:         
    LD A, (HL)                      ; Get the character from the parameter string
    OR A                            ; Exit if 0 (end of parameter string in MOS)
    RET Z
    CP 13                           ; Exit if CR (end of parameter string in BBC BASIC)
    RET Z
    CP ' '                          ; Exit if space (end of token)
    RET Z
    INC HL                          ; Advance to next character
    INC C                           ; Increment length
    JR  nt

; ---------------------------------------------

CLS:
    ld a, 12
    rst.lil $10                     ; CLS
    ret

printMSG:
    ld hl, msg
    call PRSTR
    ret 

doneMSG:
    ld hl, msg2
    call PRSTR
    ret 

; ---------------------------------------------
;
;   UART CODE
;
; ---------------------------------------------

openUART1:

    ld ix, UART1_Struct
    MOSCALL $15                 ; open uart1
    ret 

; ---------------------------------------------

closeUART1:
    MOSCALL $16                  ; close uart1
    ret 

; ---------------------------------------------

UART1_Struct:   
    .dl     9600                ; baud rate 9600 in hex little endian, LSB first
    .db     8                   ; data bits
    .db     1                   ; stop bits
    .db     0                   ; parity bits
    .db     0                   ; flow control
    .db     0                   ; interrupt bits

; ---------------------------------------------

multiPurposeDelay:                      
                                ; arrive with A =  the delay byte. One bit to be set only.
    push bc 
    ld b, a 
waitLoop:
    MOSCALL $08                 ; get IX pointer to sysvars
    ld a, (ix + 0)              ; ix+0h is lowest byte of clock timer

                                ; need to check if bit set is same as last time we checked.
                                ;   bit 0 - changes 128 times per second
                                ;   bit 1 - changes 64 times per second
                                ;   bit 2 - changes 32 times per second
                                ;   bit 3 - changes 16 times per second

                                ;   bit 4 - changes 8 times per second
                                ;   bit 5 - changes 4 times per second
                                ;   bit 6 - changes 2 times per second
                                ;   bit 7 - changes 1 times per second
                                ; eg. and 00000010b           ; check 1 bit only
    and b 
    ld c,a 
    ld a, (oldTimeStamp)
    cp c                        ; is A same as last value?
    jr z, waitLoop              ; loop here if it is
    ld a, c 
    ld (oldTimeStamp), a        ; set new value
    pop bc
    ret

oldTimeStamp:   .db 00h

    ; ---------------------------------------------
msg:                .db "Printing file: ",0
msg2:               .db "Done.\r\n",0
errMSG:             .db "Sorry, could not open that file.\r\n",0
s_ARGUMENTS:        .DB  "Arguments:\n\r", 0
s_ARGV:             .DB  " - argv: ", 0
s_CRLF:             .DB  "\n\r", 0
argv_ptrs:          .ds    48, 0        ; max 16 x 3 bytes each

fileStoreHere:      .ds 1024,0          ; only storing 1k for sure, rest will go into RAm beyond the app

