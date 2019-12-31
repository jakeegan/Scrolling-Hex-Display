#-----------------------------------------------------------------------------
# An interrupt-based Nios II assembly-language program to receive character
# data over UART and convert the data to a scrolling 7 segment hex display.
#-----------------------------------------------------------------------------

	.text

	.global	_start

	.equ 	JTAG_UART_BASE, 	0x10001000
	.equ	JTAG_UART_DATA,		0x10001000
	.equ	JTAG_UART_CONTROL, 	0x10001004
	.equ 	WRITE_MASK, 		0xFFFF 					
	.equ 	READ_MASK, 			0x8000 				
	.equ 	DATA_MASK, 			0xFF 					
	.equ	LAST_RAM_WORD, 		0x007FFFFC
	.equ	TIMER_STATUS, 		0x10002000			
	.equ	TIMER_CONTROL, 		0x10002004			
	.equ	TIMER_START_LO, 	0x10002008			
	.equ	TIMER_START_HI, 	0x1000200C			
	.equ	TIMER_SNAP_LO, 		0x10002010			
	.equ	TIMER_SNAP_HI, 		0x10002014			
    .equ	TIMER_START_VALUE, 	0x2FAF080		# 1s at 50MHz
	.equ	LEDS, 				0x10000010
	.equ	HEX_DISPLAY_PORT,	0x10000020

	.org	0x0000
_start:
	br	main

	.org	0x0020
 
	br	isr

#-----------------------------------------------------------------------------
# Main loop 
#-----------------------------------------------------------------------------

main:
	movia 	sp, LAST_RAM_WORD
	call 	Init
main_loop:
	br 		main_loop

#-----------------------------------------------------------------------------
# Initialize values and enable interrupts
#-----------------------------------------------------------------------------

Init:
	subi	sp, sp, 8
	stw		r2, 4(sp)
	stw		r3, 0(sp)
	movia	r3, FLAG
	mov		r2, r0
	stw		r2, 0(r3)
	movia	r3, TIMER_STATUS
	mov		r2, r0
	stwio	r2, 0(r3)
	movia	r3, TIMER_START_LO
	movia	r2, TIMER_START_VALUE
	stwio	r2, 0(r3)
	srli	r2, r2, 16
	stwio	r2, 4(r3)
	movia	r3, TIMER_CONTROL
	movi	r2, 7
	stwio	r2, 0(r3)
	movia	r3, JTAG_UART_CONTROL
	movi	r2, 1
	stwio	r2, 0(r3)
	movi	r2, 0b100000001
	wrctl	ienable, r2
	movi	r2, 1
	wrctl	status, r2
	ldw		r2, 4(sp)
	ldw		r3, 0(sp)
	addi	sp, sp, 8
	ret

#-----------------------------------------------------------------------------
# Interrupt service routine to check interrupts and call respective handlers
#-----------------------------------------------------------------------------

isr:
	subi	ea, ea, 4
	subi	sp, sp, 12
	stw		r2, 8(sp)
	stw		r3, 4(sp)
	stw		ra, 0(sp)
	rdctl	r2, ipending
check_timer:
	andi	r3, r2, 1
	beq		r3, r0, check_uart
	call	HandleTimer
check_uart:
	andi	r3, r2, 0b100000000
	beq		r3, r0, exit_isr
	call 	HandleUart
exit_isr:
	ldw		r2, 8(sp)
	ldw		r3, 4(sp)
	ldw		ra, 0(sp)
	addi	sp, sp, 12
	eret
	
#-----------------------------------------------------------------------------
# Clears timer interurpt and calls UpdateHexDisplay
#-----------------------------------------------------------------------------

HandleTimer:
	subi	sp, sp, 12
	stw		r2, 8(sp)
	stw		r3, 4(sp)
	stw		ra, 0(sp)
	movia	r3, TIMER_STATUS
	mov		r2, r0
	stwio	r2, 0(r3)
	movia	r3, FLAG
	mov		r2, r0
	stw		r2, 0(r3)
	call 	UpdateHexDisplay
	movia	r2, LEDS
	ldwio	r3, 0(r2)
	xori	r3, r3, 1
	stwio	r3, 0(r2)
	ldw		r2, 8(sp)
	ldw		r3, 4(sp)
	ldw		ra, 0(sp)
	addi	sp, sp, 12
	ret

#-----------------------------------------------------------------------------
# Clears UART interrupt and calls PrintHexDisplay
#-----------------------------------------------------------------------------

HandleUart:
	subi	sp, sp, 16
	stw		ra, 12(sp)
	stw		r2, 8(sp)
	stw		r3, 4(sp)
	stw		r4, 0(sp)
	movia	r3, JTAG_UART_DATA
	ldwio	r2, 0(r3)
	andi	r2, r2, DATA_MASK
	movia	r3, FLAG
	ldw		r4, 0(r3)
	bne		r4, r0, exit_hu
	movi	r4, 1	
	stw		r4, 0(r3)
	call 	PrintChar
	call 	PrintHexDisplay
exit_hu:
	ldw		ra, 12(sp)
	ldw		r2, 8(sp)
	ldw		r3, 4(sp)
	ldw		r4, 0(sp)
	addi	sp, sp, 16
	ret

#-----------------------------------------------------------------------------
# Echoes received character back
#-----------------------------------------------------------------------------

PrintChar:
	subi 	sp, sp, 8			
	stw 	r3, 0(sp) 
	stw 	r4, 4(sp)
	movia 	r3, JTAG_UART_CONTROL
pc_loop:
	ldwio 	r4, 0(r3) 
	andhi 	r4, r4, WRITE_MASK 
	beq 	r4, r0, pc_loop
	movia 	r3, JTAG_UART_DATA
	stwio	r2, 0(r3)
	ldw 	r3, 0(sp) 				
	ldw 	r4, 4(sp) 				
	addi 	sp, sp, 8				
	ret 

#-----------------------------------------------------------------------------
# Converts the character code to the hex display using a lookup table
#-----------------------------------------------------------------------------

PrintHexDisplay:
	subi 	sp, sp, 12	
	stw 	r3, 0(sp)
	stw 	r4, 4(sp)
	stw		r5, 8(sp)
	movia 	r3, HEX_LOOKUP_TABLE
	mov		r4, r2
	subi	r4, r4, '0'
	muli	r4, r4, 4
	add		r3, r3, r4
	ldw		r4, 0(r3)
	movia	r3, HEX_DISPLAY_PORT
	ldwio	r5, 0(r3)
	or		r4, r4, r5
	stwio	r4, 0(r3)
	ldw 	r3, 0(sp) 				
	ldw 	r4, 4(sp) 	
	ldw		r5, 8(sp)
	addi 	sp, sp, 12			
	ret 	
	
#-----------------------------------------------------------------------------
# Shifts digits on the hex display to the left
#-----------------------------------------------------------------------------

UpdateHexDisplay:
	subi 	sp, sp, 12			
	stw 	r2, 0(sp)
	stw 	r3, 4(sp)
	stw		r4, 8(sp)
	movia 	r2, HEX_DISPLAY_PORT
	ldwio	r3, 0(r2) 
	slli	r3, r3, 8
	stwio	r3, 0(r2)
	ldw 	r2, 0(sp) 				
	ldw 	r3, 4(sp) 	
	ldw		r4, 8(sp)
	addi 	sp, sp, 12				
	ret 	
#-----------------------------------------------------------------------------
# 
#-----------------------------------------------------------------------------

	.org	0x1000

FLAG:	.word	0
	
#seven segment character lookup table 0 to z
HEX_LOOKUP_TABLE:	.word   0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x77, 0x00, 0x39, 0x00, 0x79, 0x71, 0x3D, 0x76, 0x30, 0x1E, 0x00, 0x38, 0x00, 0x00, 0x3F, 0x73, 0x00, 0x00, 0x6D, 0x00, 0x3E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5F, 0x7C, 0x58, 0x5E, 0x00, 0x00, 0x00, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x54, 0x5C, 0x00, 0x67, 0x50, 0x00, 0x78, 0x1C, 0x00, 0x00, 0x00, 0x6E, 0x00
	.end
