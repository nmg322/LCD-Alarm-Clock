;Author: NEELMANI GAUTAM
;Interfaced 16x2 LCD display in 4-bit mode using sufficient delay with ATMega328P

.include "/usr/share/avra/m328Pdef.inc"

.equ LCD_DATA = PORTD
.equ LCD_DATA_DIR = DDRD
.equ LCD_CTRL = PORTB
.equ LCD_CTRL_DIR = DDRB
.equ LCD_RS = 0
.equ LCD_RW = 1
.equ LCD_E = 2
.equ pushBT1 = 3 ;yes, increment, PORTB
.equ pushBT2 = 4 ;no, enter, PORTB
.equ Buzzer = 2 ;PORTD

.equ LCD_FUNCTION_SET = 0x38
.equ LCD_FUNCTION_SET_4BIT = 0x28
.equ LCD_DISPLAY_OFF = 0x08
.equ LCD_DISPLAY_ON = 0x0C
.equ LCD_DISPLAY_CLEAR = 0x01
.equ LCD_ENTRY_MODE_SET = 0x06
.equ LCD_CURSOR_HOME = 0x02
.equ LCD_LINE1_ADDR = 0x80
.equ LCD_LINE2_ADDR = 0xC0

.def lcdData = r16
.def waitTemp1 = r17
.def waitTemp2 = r18
.def waitTemp3 = r19
.def HRS_ONES = r20
.def HRS_TENS = r21
.def MIN_ONES = r22
.def MIN_TENS = r23
.def SEC_ONES = r24
.def SEC_TENS = r25
.def AHT = r26
.def AHO = r27
.def AMT = r28
.def AMO = r29

.macro strobe
	sbi LCD_CTRL, LCD_E
	cbi LCD_CTRL, LCD_E
.endmacro

.macro rwLow
	cbi LCD_CTRL, LCD_RW
.endmacro

.macro rwHigh
	cbi LCD_CTRL, LCD_RW
.endmacro

.macro rsLow
	cbi LCD_CTRL, LCD_RS
.endmacro

.macro rsHigh
	sbi LCD_CTRL, LCD_RS
.endmacro

.macro lcdCommand	;lcdCommand C executes command C to control lcd
	rsLow
	ldi lcdData, @0
	rcall lcdOutNibble
	swap lcdData
	rcall lcdOutNibble
.endmacro

.macro lcdChar		;lcdChar print lcdData
	rsHigh
	rcall lcdOutNibble
	swap lcdData
	rcall lcdOutNibble
.endmacro

.macro printStr
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)

	lcdCommand @1
string_loop:
	lpm lcdData, Z+
	tst lcdData
	breq end
	lcdChar
	rjmp string_loop
end: nop
.endmacro

.macro set_Time
	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME
	printStr HT, LCD_LINE1_ADDR
H10:lcdCommand $C7
	call wait100ms
	IN lcdData, PINB
	SBRC lcdData, pushBT1
	INC @0
	CPI @0, 3
	BRNE HR10
	LDI @0, 0
HR10: mov waitTemp1, @0
	call dec2str
    lcdChar
    IN lcdData, PINB
	SBRS lcdData, pushBT2
	JMP H10

	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME
	printStr HO, LCD_LINE1_ADDR
H1:	lcdCommand $C7
	call wait100ms
	IN lcdData, PINB
	SBRC lcdData, pushBT1
	INC @1
	CPI @1, 10
	BRNE HR1
	LDI @1, 0
HR1: mov waitTemp1, @1
	call dec2str
    lcdChar
    IN lcdData, PINB
	SBRS lcdData, pushBT2
	JMP H1

	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME
	printStr MT, LCD_LINE1_ADDR
M10:lcdCommand $C7
	call wait100ms
	IN lcdData, PINB
	SBRC lcdData, pushBT1
	INC @2
	CPI @2, 6
	BRNE MN10
	LDI @2, 0
MN10: mov waitTemp1, @2
	call dec2str
    lcdChar
    IN lcdData, PINB
	SBRS lcdData, pushBT2
	JMP M10

	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME
	printStr MO, LCD_LINE1_ADDR
M1:	lcdCommand $C7
	call wait100ms
	IN lcdData, PINB
	SBRC lcdData, pushBT1
	INC @3
	CPI @3, 10
	BRNE MN1
	LDI @3, 0
MN1: mov waitTemp1, @3
	call dec2str
    lcdChar
    IN lcdData, PINB
	SBRS lcdData, pushBT2
	JMP M1
Break: nop
.endmacro

;====================================================================
.org 0
rjmp reset

reset:
	ldi HRS_TENS, 0
	ldi MIN_ONES, 0
	ldi MIN_TENS, 0
	ldi SEC_ONES, 0
	ldi SEC_TENS, 0
	ldi AHT, 0
	ldi AHO, 0
	ldi AMT, 0
	ldi AMO, 0
	
	ldi R16, $00
	OUT PORTD, R16
	OUT PORTB, R16

	ldi R16, low(RAMEND)
	out SPL, R16
	ldi R16, high(RAMEND)
	out SPH, R16

	ldi R16, $00
	OUT LCD_CTRL_DIR, R16
	ldi R16, $04
	OUT LCD_DATA_DIR, R16

	in waitTemp2, LCD_DATA_DIR
	ori waitTemp2, $F0
	out LCD_DATA_DIR, waitTemp2
	in  waitTemp2, LCD_CTRL_DIR
	ori waitTemp2, ((1<<LCD_RS)|(1<<LCD_RW)|(1<<LCD_E))
	out LCD_CTRL_DIR, waitTemp2

LCD_INIT:
	rwLow
	rsLow
	ldi lcdData,LCD_FUNCTION_SET
	call wait5ms
	rcall lcdOutNibble
	rcall wait100us
	rcall lcdOutNibble
	rcall wait100us
	rcall lcdOutNibble

	ldi lcdData,LCD_FUNCTION_SET_4BIT
	rcall wait100us
	rcall lcdOutNibble

	lcdCommand LCD_FUNCTION_SET_4BIT
	lcdCommand LCD_ENTRY_MODE_SET
	lcdCommand LCD_DISPLAY_ON
	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME

Main:
	Call Alarm_Set
	Call Time_Set
	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME
	printStr Tlabel, $86
	JMP RESET_SEC_TENS

RESET_HRS_TENS:
	CLR HRS_TENS
RESET_HRS_ONES:
	CLR HRS_ONES
RESET_MIN_TENS:
	CLR MIN_TENS
RESET_MIN_ONES:
	CLR MIN_ONES
RESET_SEC_TENS:
	CLR SEC_TENS
RESET_SEC_ONES:
	CLR SEC_ONES
CLOCK_LOOP:
	CP HRS_TENS, AHT
	BREQ IF1

EL:	CALL display_time
	INC SEC_ONES
	CPI SEC_ONES, 10
	BRNE CLOCK_LOOP
	INC SEC_TENS
	CPI SEC_TENS, 6
	BRNE RESET_SEC_ONES
	INC MIN_ONES
	CBI PORTD, Buzzer ;To turn off alarm
	CPI MIN_ONES, 10
	BRNE RESET_SEC_TENS
	INC MIN_TENS
	CPI MIN_TENS, 6
	BRNE RESET_MIN_ONES
	INC HRS_ONES
	CPI HRS_TENS, 2
	BRNE CD2
CD1:
	CPI HRS_ONES, 4
	BRNE RESET_MIN_TENS
	JMP CD3
CD2:
	CPI HRS_ONES, 10
	BRNE RESET_MIN_TENS
	JMP CD3
CD3:
	INC HRS_TENS
	CPI HRS_TENS, 3
	BRNE RESET_HRS_ONES
	SER HRS_ONES
	JMP RESET_HRS_TENS
IF1:
	CP HRS_ONES, AHO
	BREQ IF2
	JMP EL
IF2:
	CP MIN_TENS, AMT
	BREQ IF3
	JMP EL
IF3:
	CP MIN_ONES, AMO
	BREQ Bz
	JMP EL
Bz: SBI PORTD, Buzzer
	JMP EL

;====================================================================

Alarm_Set:
	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME
	printStr Alabel1, LCD_LINE1_ADDR
	printStr Alabel2, LCD_LINE2_ADDR
A0: IN waitTemp1, PINB
	SBRC waitTemp1, pushBT2
	RET
	SBRC waitTemp1, pushBT1
	JMP A1
	JMP A0
A1: set_Time AHT, AHO, AMT, AMO
	RET

Time_Set:
	lcdCommand LCD_DISPLAY_CLEAR
	lcdCommand LCD_CURSOR_HOME
	printStr Tsetlabel1, LCD_LINE1_ADDR
	printStr Tsetlabel2, LCD_LINE2_ADDR
TS0: IN waitTemp1, PINB
	SBRC waitTemp1, pushBT1
	JMP TS1
	SBRC waitTemp1, pushBT2
	JMP TS1
	JMP TS0
TS1: set_Time HRS_TENS, HRS_ONES, MIN_TENS, MIN_ONES
	 RET

display_time:
	lcdCommand $C4

	mov waitTemp1, HRS_TENS
	call dec2str
    lcdChar

    mov waitTemp1, HRS_ONES
	call dec2str
    lcdChar

    LDI lcdData, ':'
    lcdChar
    
    mov waitTemp1, MIN_TENS
	call dec2str
    lcdChar
    
    mov waitTemp1, MIN_ONES
	call dec2str
    lcdChar
    
    LDI lcdData, ':'
    lcdChar
    
    mov waitTemp1, SEC_TENS
	call dec2str
    lcdChar

    mov waitTemp1, SEC_ONES
	call dec2str
    lcdChar

    call wait1sec
    RET

dec2str:
	CPI waitTemp1, 0
	breq t0
	CPI waitTemp1, 1
	breq t1
	CPI waitTemp1, 2
	breq t2
	CPI waitTemp1, 3
	breq t3
	CPI waitTemp1, 4
	breq t4
	CPI waitTemp1, 5
	breq t5
	CPI waitTemp1, 6
	breq t6
	CPI waitTemp1, 7
	breq t7
	CPI waitTemp1, 8
	breq t8
	CPI waitTemp1, 9
	breq t9
t0: ldi lcdData, '0'
	ret
t1: ldi lcdData, '1'
	ret
t2: ldi lcdData, '2'
	ret
t3: ldi lcdData, '3'
	ret
t4: ldi lcdData, '4'
	ret
t5: ldi lcdData, '5'
	ret
t6: ldi lcdData, '6'
	ret
t7: ldi lcdData, '7'
	ret
t8: ldi lcdData, '8'
	ret
t9: ldi lcdData, '9'
	ret

wait100us:
   ldi waitTemp1, 0x00
   ldi waitTemp2, 0x02
w100us:
	dec waitTemp1
	brne w100us
	dec waitTemp2
	brne w100us
	ret

wait5ms:
	ldi waitTemp1, $00
	ldi waitTemp2, $00
w5ms:
	dec waitTemp1
	brne w5ms
	dec waitTemp2
	brne w5ms
	ret

wait100ms:
	ldi waitTemp3, 0x10
	ldi waitTemp2, 0x00
	ldi waitTemp1, 0x00
w100ms:
	dec waitTemp1
	brne w100ms
	dec waitTemp2
	brne w100ms
	dec waitTemp3
	brne w100ms
	ret

wait1sec:
	ldi waitTemp3, 53
	ldi waitTemp2, 0x00
	ldi waitTemp1, 0x00
w1sec:
	dec waitTemp1
	brne w1sec
	dec waitTemp2
	brne w1sec
	dec waitTemp3
	brne w1sec
	ret

lcdOutNibble:	;Send out high nibble of lcdData in upper data lines
	rcall wait5ms

	mov waitTemp2,lcdData
	andi waitTemp2, 0xF0
	in waitTemp1, LCD_DATA
	andi waitTemp1, 0x0F
	or waitTemp2, waitTemp1
	out LCD_DATA, waitTemp2
	strobe
	ret

;====================================================================

Tlabel:
.db "TIME", 0, 0

Tsetlabel1:
.db "PRESS ANY KEY TO", 0, 0

Tsetlabel2:
.db "    SET TIME    ", 0, 0

Alabel1:
.db " DO YOU WANT TO ", 0, 0

Alabel2:
.db "   SET ALARM?   ", 0, 0

HO:
.db "HOUR ONES PLACE", 0

HT:
.db "HOUR TENS PLACE", 0

MO:
.db "MIN. ONES PLACE", 0

MT:
.db "MIN. TENS PLACE", 0
