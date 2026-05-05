;--- PIN DEFINITIONS ---
SDA      BIT P3.0
SCL      BIT P3.1
MODE_SW  BIT P3.2   ; HIGH = STORE, LOW = VERIFY
LED_G    BIT P1.0
LED_R    BIT P1.1
LED_Y    BIT P1.2
LED_BLUE  BIT P1.4
BUZZER   BIT P1.3

ORG 0000H
LJMP START

ORG 0030H
START:
    MOV P1, #00H
    MOV P0, #0FFH       ; Force all segments OFF (Common Anode logic)
    SETB LED_Y          
    MOV R2, #0FFH       
    ACALL UPDATE_DISPLAY

MAIN:
    ACALL SCAN_KEYPAD   
    CJNE A, #0FFH, KEY_FOUND ; If A is NOT 0FFH, a key was pressed
    SJMP MAIN                ; Otherwise, keep waiting

KEY_FOUND:
    ; Logic for '*' (Reset)
    CJNE A, #10, NOT_RESET
    MOV R2, #0FFH
    ACALL ALL_OFF
    SETB LED_Y
    ACALL UPDATE_DISPLAY     ; Update display to show '-'
    SJMP MAIN

NOT_RESET:
    ; Logic for '#' (Execute)
    CJNE A, #11, NOT_EXEC
    MOV A, R2
    CJNE A, #0FFH, EXECUTE_LOGIC
    SJMP MAIN

NOT_EXEC:
    MOV R2, A           
    ACALL UPDATE_DISPLAY ; Update 7-seg with new ID
    SJMP MAIN

;--- CORE LOGIC ---
EXECUTE_LOGIC:
    ACALL CALC_CHECKSUM ; Result is now a CRC-8 in R0
    JNB MODE_SW, DO_STORE
    
DO_VERIFY:
    MOV A, R2           
    ACALL EE_READ       
    CJNE A, 00H, FAIL   ; Compare EEPROM (A) with CRC (R0/00H)
    
    ACALL ALL_OFF
    SETB LED_G          
    ACALL WAIT_FOR_USER 
    LJMP START

FAIL:
    ACALL ALL_OFF
    SETB LED_R          
    SETB BUZZER
    ACALL WAIT_FOR_USER 
    LJMP START
	
DO_STORE:
    MOV A, R2            ; Address
    MOV B, R0            ; Data (Checksum)
    ACALL EE_WRITE
    
    ACALL ALL_OFF        ; Clear all indicators
    SETB LED_BLUE        ; Light up the new Success LED
    ACALL WAIT_FOR_USER  ; Keep it lit until a key is pressed
    LJMP START           ; Return to standby (Yellow LED on)
	
	
;--- REFACTORED WAIT ROUTINE ---
WAIT_FOR_USER:
    ; Wait for key release 
W_REL1:
    ACALL SCAN_KEYPAD
    CJNE A, #0FFH, W_REL1
    ; Wait for any new key press
W_PRES:
    ACALL SCAN_KEYPAD
    CJNE A, #0FFH, W_DONE
    SJMP W_PRES
W_DONE:
    ; Wait for final release
W_REL2:
    ACALL SCAN_KEYPAD
    CJNE A, #0FFH, W_REL2
    RET
;--- KEYPAD SCAN (PORT 2) ---
SCAN_KEYPAD:
    MOV P2, #0F0H       ; Columns high, Rows low
    MOV A, P2
    ANL A, #0F0H
    XRL A, #0F0H
    JZ NO_KEY           ; Exit if no key pressed
    
    ; Row 0 Scan
    MOV P2, #0FEH
    MOV A, P2
    JNB P2.4, K1
    JNB P2.5, K2
    JNB P2.6, K3
    
    ; Row 1 Scan
    MOV P2, #0FDH
    JNB P2.4, K4
    JNB P2.5, K5
    JNB P2.6, K6
    
    ; Row 2 Scan
    MOV P2, #0FBH
    JNB P2.4, K7
    JNB P2.5, K8
    JNB P2.6, K9

    ; Row 3 Scan
    MOV P2, #0F7H
    JNB P2.4, KSTAR
    JNB P2.5, K0
    JNB P2.6, KHASH

NO_KEY:
    MOV A, #0FFH
    RET

; Key Mappings
K1: MOV A, #1
    RET
K2: MOV A, #2
    RET
K3: MOV A, #3
    RET
K4: MOV A, #4
    RET
K5: MOV A, #5
    RET
K6: MOV A, #6
    RET
K7: MOV A, #7
    RET
K8: MOV A, #8
    RET
K9: MOV A, #9
    RET
K0: MOV A, #0
    RET
KSTAR:
    MOV A, #10
    RET
KHASH:
    MOV A, #11
    RET

; Calculating file length
FILE_LEN EQU (MY_FILE_END - MY_FILE)
;--- ROBUST CRC-8 CALCULATION ---
; Polynomial: X^8 + X^5 + X^4 + 1 (0x31)
CALC_CHECKSUM:
    MOV DPTR, #MY_FILE
    MOV R7, #FILE_LEN         ; Check 10 bytes
    MOV R0, #00H        ; R0 holds the CRC remainder (Initial value 0)
    
BYTE_LOOP:
    CLR A
    MOVC A, @A+DPTR     ; Get byte from "File"
    XRL A, R0           ; XOR byte with current CRC
    MOV R0, A           
    
    MOV R6, #8          ; Process 8 bits
BIT_LOOP:
    MOV A, R0
    RLC A               ; Shift MSB into Carry
    JNC SHIFT_ONLY      ; If Carry is 0, just shift
    
    ; If Carry is 1, XOR with Polynomial 0x31
    XRL A, #31H         
SHIFT_ONLY:
    MOV R0, A           ; Store updated CRC
    DJNZ R6, BIT_LOOP   ; Repeat for all 8 bits
    
    INC DPTR
    DJNZ R7, BYTE_LOOP  ; Repeat for all bytes in file
    RET

;--- I2C HIGH LEVEL ---
EE_WRITE:
    ACALL I2C_START
    MOV A, #0A0H        
    ACALL I2C_SEND
    MOV A, #00H         
    ACALL I2C_SEND
    MOV A, R2           
    ACALL I2C_SEND
    MOV A, B            
    ACALL I2C_SEND
    ACALL I2C_STOP
    ACALL DELAY_5MS     
    RET

EE_READ:
    ACALL I2C_START
    MOV A, #0A0H
    ACALL I2C_SEND
    MOV A, #00H         
    ACALL I2C_SEND
    MOV A, R2           
    ACALL I2C_SEND
    ACALL I2C_START     
    MOV A, #0A1H        
    ACALL I2C_SEND
    ACALL I2C_RCV
    ACALL I2C_STOP
    RET

;--- I2C LOW LEVEL (FIXED SYNTAX) ---
I2C_START:
    SETB SDA
    SETB SCL
    CLR SDA
    CLR SCL
    RET

I2C_STOP:
    CLR SDA
    SETB SCL
    SETB SDA
    RET

I2C_SEND:
    MOV R3, #08H
SEND_LP:
    RLC A
    MOV SDA, C
    SETB SCL
    ACALL MIN_DELAY ; Small delay for Proteus stability
    CLR SCL
    DJNZ R3, SEND_LP
    
    ; ACK Clock Pulse (We pulse SCL but don't wait for SDA)
    SETB SDA        ; Release SDA
    SETB SCL
    ACALL MIN_DELAY
    CLR SCL
    RET

MIN_DELAY: 
    NOP
    NOP
    RET

I2C_RCV:
    MOV R3, #08H
    SETB SDA            
RCV_LP:
    SETB SCL
    MOV C, SDA
    RLC A
    CLR SCL
    DJNZ R3, RCV_LP
    SETB SCL            
    CLR SCL
    RET

DELAY_5MS: 
    MOV R4, #10
D1: MOV R5, #250
    DJNZ R5, $
    DJNZ R4, D1
    RET

ALL_OFF:
    CLR LED_G
    CLR LED_R
    CLR LED_Y
	CLR LED_BLUE
    CLR BUZZER
    RET

FLASH_GREEN:
    SETB LED_G
    ACALL DELAY_5MS
    CLR LED_G
    RET

; Number Display

; 7-Segment Patterns for 0-9 (Common Anode)
; A '0' bit turns the segment ON
SEG_DATA: 
    DB 0C0H ; 0 (Segments g is off, others on)
    DB 0F9H ; 1
    DB 0A4H ; 2
    DB 0B0H ; 3
    DB 99H  ; 4
    DB 92H  ; 5
    DB 82H  ; 6
    DB 0F8H ; 7
    DB 80H  ; 8
    DB 90H  ; 9
    DB 0BFH ; '-' (Middle bar 'g' is ON)
		
UPDATE_DISPLAY:
    MOV A, R2
    CJNE A, #0FFH, SHOW_NUM
    MOV A, #10          ; Index 10 in SEG_DATA is '-'
SHOW_NUM:
    MOV DPTR, #SEG_DATA
    MOVC A, @A+DPTR
    MOV P0, A
    RET
DISP_NOW:
    MOV DPTR, #SEG_DATA
    MOVC A, @A+DPTR     ; Get segment pattern from table
    MOV P0, A           ; Output to Port 0
    POP ACC             ; Restore Accumulator
    RET


;--- DATA FILE ---
MY_FILE:
    DB 12h, 12h, 22h, 02h, 02h, 32h, 12h, 32h, 12h, 32h, 0AAh, 055h, 0FFh, 000h, 11h, 22h
    DB 33h, 44h, 53h, 66h, 77h, 88h, 99h, 0AAh, 0BBh, 0CCh, 0DDh, 0EEh, 0FFh, 01h, 02h, 03h
    DB 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh, 10h, 11h, 12h, 13h
    DB 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 29h, 2Ah, 2Bh, 2Ch, 2Dh, 2Eh, 2Fh
    DB 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh
    DB 40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h, 48h, 49h, 4Ah, 4Bh, 4Ch, 4Dh, 4Eh, 4Fh
    DB 50h, 51h, 52h, 53h, 54h, 55h, 56h, 57h, 58h, 59h, 5Ah, 5Bh, 5Ch, 5Dh, 5Eh, 5Fh
    DB 60h, 61h, 62h, 63h, 64h, 65h, 66h, 67h, 68h, 69h, 6Ah, 6Bh, 6Ch, 6Dh, 6Eh, 6Fh
MY_FILE_END:

END