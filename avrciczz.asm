; --------------------------------------------------------------------- 
;   NES avrciczz V3 for AVR MCU
;   Copyright (C) 2013 by Igor Golubovskiy (krikzz) <biokrik@gmail.com>
;   This software is part of the EverDrive-N8 project.
; --------------------------------------------------------------------- 
;                       ATtiny13A
;                       ,---_---.
;                    nc |1     8| VCC 
;          (NES-71) clk |2     7| rst (NES-70)
;                   led |3     6| din (NES-34)
;                   GND |4     5| dout(NES-35)
;                       `-------'
;  led 0: normal state
;  led 1: cic trying to change region
;  SUT_CKSEL fuse should be set to "ext clock + 0ms"
; --------------------------------------------------------------------- 


.include "tn13def.inc"

.equ dout_port = PORTB
.equ dout_ddr = DDRB
.equ dout_bit = 0

.equ din_port = PORTB
.equ din_ddr = DDRB
.equ din_pin = PINB
.equ din_bit = 1

.equ rst_port = PORTB
.equ rst_ddr = DDRB
.equ rst_pin = PINB
.equ rst_bit = 2

.equ led_port = PORTB
.equ led_ddr = DDRB
.equ led_bit = 4



.macro ram_w0 
	ldi r20, (@1)
	sts ram0+(@0), r20
.endmacro


.macro delay
	ldi r20, (@0)/3
loop:	
	dec r20
	brne loop
.endmacro


.macro led0
	cbi led_port, led_bit
.endmacro

.macro led1
	sbi led_port, led_bit
.endmacro

.macro 	rdr
	mov XL, r17
	ori XL, @1
	ld @0, X
.endmacro


.macro addi
	ldi r20, @1
	add @0, r20
.endmacro

main: ;cold start
	
	clr r25
	;init reset 
	cbi rst_ddr, rst_bit
	sbi rst_port, rst_bit
	
	;init din
	cbi din_ddr, din_bit
	;sbi din_port, din_bit
	

reboot:	
rst0:
	sbis rst_pin, rst_bit
	rjmp rst0
rst1:
	sbic rst_pin, rst_bit
	rjmp rst1
	
	clr XH
	clr YH

	
	
	;init dout	
	sbi dout_ddr, dout_bit
	cbi dout_port, dout_bit

	;init led
	sbi led_ddr, led_bit
	cbi led_port, led_bit

	

	
	ram_w0 0x1, 0x2
	
	ram_w0 0xc, 0x8
	ram_w0 0xd, 0x1
	ram_w0 0xe, 0x2
	ram_w0 0xf, 0x4

	;init pointer to KEY/LOCK
	clr r16
	out EEARL, r16
	sbi EECR, EERE 
	in ZL, EEDR
	;ldi ZL,32
	ldi ZH, 0x02
	
	cpi ZL, 32
	brne skip_uk_delay

uk_delay:
	delay 21
	;nop
	;nop
	;nop

skip_uk_delay:		
	delay 90
	;nop
	;nop
	;nop
	
	ldi XL, ram0 + 0xC
	lds r17, ram0+1 ;134

;132
init_key:
	in r18, din_pin
	ld r19, X+
	sbrc r18, din_bit
	add r17, r19
	sbrs r18, din_bit
	nop

init_0:
	delay 48
	nop
	nop

	cpi XL, ram1
	brne init_key
	nop
;372
	andi r17, 15
	sts ram0+1, r17
	
	
	
	inc ZL
	clr XH
	ldi XL, low(ram0+2)
copy_key:
	lpm r16, Z+
	st X+, r16
	cpi XL, ram0+32
	brne copy_key



	
	clr ZH
;---------------------------------------------------
	delay 150
	nop
	nop
	nop

	ldi XL, ram0+1
	delay 6
	rjmp main_loop
	

init_ptr:
	;ldi r16, ram0
	lds XL, ram0+7
	adiw XL, 8
	andi XL, 15
	ori XL, ram0
	cpi XL, ram0
	brne main_loop
	inc XL
	delay 6
	nop
	nop
	
	
;780
main_loop:
	in r16, din_pin
	sbrc r16, din_bit
	rjmp panic

	nop
	delay 12

	ld r16, X
	;ldi r16, 0
	;nop
	
	sbrc r16, 0
	sbi dout_port, dout_bit;20
	sbrs r16, 0
	rjmp dat0
dat0:	
	
	

	delay 3
	nop
	nop
	
	

	in r17, din_pin ;28
	nop
	nop
	nop
	cbi dout_port, dout_bit;32
	
	
	
	clr r16
	sbrc r17, din_bit
	ori r16, 1
	sbrs r17, din_bit
	ori r16, 0

	delay 261
	nop
	nop
	


	mov YL, XL
	andi YL, 15
	ori YL, ram1

	ld r17, Y;305
	andi r16, 1
	andi r17, 1
	cp r16, r17
	breq m2
	rjmp panic
	;nop
	;nop

m2:

	inc XL
	cpi XL, ram1
	brne main_loop ;loop time 316
	nop
	
	rjmp update_lock

panic:
	cpi r25, 0x3
	brne skip_rsw ;we don't want to chage region at each startup, riht?
	led1
	
	andi ZL, 96
	addi ZL, 32
	andi ZL, 96	

EEWrite:	
	sbic EECR,EEWE
	rjmp EEWrite
 	
	clr r16
	out EEARL, R16
	;out EEARH, R16
	out EEDR, ZL
 
	sbi EECR, EEMWE
	sbi EECR, EEWE

	rjmp reboot

skip_rsw:
	inc r25
	rjmp reboot


.org 256

;ram_w0 0x1, 0x2
	
;ram_w0 0xc, 0x8
;ram_w0 0xd, 0x1
;ram_w0 0xe, 0x2
;ram_w0 0xf, 0x4


;3193 - USA/Canada 
;KEY:  x952129F910DF97 
;LOCK: 3952F20F9109997 
cic_3193:
.db 0x0,0x9,0x5,0x2,0x1,0x2,0x9,0xF,0x9,0x1,0x0,0xD,0xF,0x9,0x7,0
.db 0x3,0x9,0x5,0x2,0xF,0x2,0x0,0xF,0x9,0x1,0x0,0x9,0x9,0x9,0x7,0


;3197 - UK/Italy/Australia 
;KEY:  x79AA1E0D019D99
;LOCK: 558937A00E0D66D 
cic_3197:
.db 0x0,0x7,0x9,0xA,0xA,0x1,0xE,0x0,0xD,0x0,0x1,0x9,0xD,0x9,0x9,0
.db 0x5,0x5,0x8,0x9,0x3,0x7,0xA,0x0,0x0,0xE,0x0,0xD,0x6,0x6,0xD,0


;3195 - Europe 
;KEY:  x7BD309F6EF2F97 
;LOCK: 17BEF0AF5706617 
cic_3195:
.db 0x0,0x7,0xB,0xD,0x3,0x0,0x9,0xF,0x6,0xE,0xF,0x2,0xF,0x9,0x7,0
.db 0x1,0x7,0xB,0xE,0xF,0x0,0xA,0xF,0x5,0x7,0x0,0x6,0x6,0x1,0x7,0


;3196 - Asia 
;KEY:  x6ADCF606EF2F97 
;LOCK: 06AD70AF6EF666C 
cic_3196:
.db 0x0,0x6,0xA,0xD,0xC,0xF,0x6,0x0,0x6,0xE,0xF,0x2,0xF,0x9,0x7,0
.db 0x0,0x6,0xA,0xD,0x7,0x0,0xA,0xF,0x6,0xE,0xF,0x6,0x6,0x6,0xC,0	


;r17 ram ptr
;r18 N
;r19 sum
;r21 P
;r22 temp

update_lock:
	ldi r17, ram0
up_b_loop:
	rdr r18, 0xF
	addi r18, 0xe
	andi r18, 0xF
up_n_loop:;N loop. time 312 or 336

	ldi r21, 3

	rdr r16, 2
	rdr r19, 3
	add r16, r19
	inc r16
	cpi r16, 16
	brsh tmp_hi
tmp_lo:
	rdr r19, 3
	st X, r16;previous read sets the address
	ldi r21, 4
	rjmp up1

tmp_hi:
	mov r19, r16
	andi r19, 0xF
	delay 6
up1:
	;load R[P]
	mov XL, r17
	add XL, r21
	ld r16, X

	;addr R[P] to sum
	add r19, r16
	
	;move sum & 0xF to R[P]
	andi r19, 0xF
	st X, r19

	;load R[P+1]
	inc XL
	ld r16, X
	ld r22, X

	;addr R[P+1] to sum
	add r19, r16
	andi r19, 0xF
	;move sum & 0xF to R[P+1]
	st X, r19

	inc XL	
	
	;inc temp to R[P+2] if less than 0x10
	addi r22, 8
	cpi r22, 16
	brsh tmp_hh
	rjmp tmp_ll

tmp_ll:
	ld r16, X
	add r22, r16
	rjmp u2
tmp_hh:
	delay 6

u2:
	;load sum from  R[P+2]
	ld r19, X

	;store temp & 0xf to  R[P+2]
	mov r16, r22
	andi r16, 0x0f
	st X, r16

	cpi r21, 3
	brne p_not_3
	;read R[0x6]
	rdr r16, 0x6
	;addr R[0x6] to sum
	add r19, r16
	inc r19
	andi r19, 0xF
	;move sum to R[0x6]
	st X, r19
	;extra delay here 6x4
	delay 15
	nop
p_not_3:
	
	addi r19, 0x8
	;some loop
	mov XL, r17
	ori XL, 7
up_loop:
	ld r16, X
	addi r16, 9
	add r19, r16
	andi r19, 0xF
	st X, r19
	inc XL
	mov r16, XL
	andi r16, 0xF
	cpi r16, 0
	brne up_loop

	;R[1] = R[1] + 1 + N
	rdr r16, 1 ;read [R1]
	add r16, r18;add N
	inc r16
	andi r16, 0xf
	st X, r16;stre result to R[1]

	;R[2] = ~(R[1] + R[2]) + 1
	rdr r22, 2;load R[2] to temp
	add r16, r22 ;add R[1] + R[2]
	ldi r22, 0xF
	eor r16, r22
	inc r16
	andi r16, 0x0F
	st X, r16

	delay 96
	nop

	dec r18
	cpi r18, 0xff
	breq up_n_loop_end
	nop
	rjmp up_n_loop

up_n_loop_end:

	addi r17, 16
	cpi r17, ram0+32
	breq up_b_loop_end
	nop
	rjmp up_b_loop

up_b_loop_end:
	delay 75
	;nop
	;nop


	cpi ZH, 8; 8 transactions with success means that region is correct
	breq inc_enough
	inc ZH
	nop
	nop
	rjmp init_ptr

inc_enough:
	clr r25
	nop
	rjmp init_ptr


.db "krikzz was here!"


.dseg
ram0: .byte 16
ram1: .byte 16