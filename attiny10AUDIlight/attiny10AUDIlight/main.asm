;
; attiny10AUDIlight.asm
;
; Created: 15/05/2022 20:57:34
; Author : Manama
; this is anticlockwise signal for left turn
; data order green red blue


;pb0 dataout
;
.def data = r19


.dseg

pad1: .byte 1
pad2: .byte 1



.cseg


reset:
    LDI r16,0xD8		;setting clock divider change enable
	OUT CCP,r16
	LDI r16,0x00		; selecting internal 8MHz oscillator
	OUT CLKMSR, r16
	LDI r16,0xD8		; setting clock divider change enable
	OUT CCP,r16	
	LDI r16,(0<<CLKPS3)+(0<<CLKPS2)+(0<<CLKPS1)+(0<<CLKPS0);
	OUT CLKPSR,r16		; set to 8MHz clock (disable div8)
	LDI r16,0xFF		; overclock (from 4MHz(0x00) to 15 MHz(0xFF))
	OUT OSCCAL,r16
portsetup:
	ldi r16,0b0001		; load r16 with 0x1
	out ddrb,r16		; enable pb0 as output
	ldi r16,0b0000		; load r16 0x00
	out portb,r16		; port b low (0v)
	rcall LED_RESET		;put data line low,positive edge is the main factor
mainloop:
	rcall audi			;routine that lights up each led one by one until all LEDS are lit like a audi car indicator
	push r22			; save r22 to stack
	ldi r22,255			; load 255 for delay routine
	rcall delayms		; gives 331ms delay
	ldi r22,200			; load 255 for delay routine
	rcall delayms		; gives 331ms delay
	pop r22				; restore r22
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	rcall blackout		;added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
	push r22			;added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
	ldi r22,255			;added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
	rcall delayms		;331ms   added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
;	ldi r22,255			;added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
;	rcall delayms		;331ms   added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
;	ldi r22,255			;added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
;	rcall delayms		;331ms   added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
	pop r22				;added on 10-06-22 for testing not needed on vehicle if connected from flasher relay output/flashing output
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	rjmp mainloop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Transmits 1 byte to the led matrix ,call 3 times for 1 led to transmit g,r,b data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bytetx:
	ldi r17,8			; number of bits 8
loop0:
	sbi portb,0			; set pb0 high
	nop					; 417ns = 0
	sbrc data,7			; if bit to be transmitted at position 7 is 0 skip next instruction of calling additional delay
	rcall ten66ns		; 1us = 1 (if bit 7 is 1 this instruction is executed and total delay of 1us for data to stay high)
	lsl data			; shift data out as we transmitted equalent pulse tp LED
	cbi portb,0			; pull pb0 low
	rcall ten66ns		; 1us = off time
	dec r17				; decrease bit counter
	brne loop0			; loop back until counter is 0
	ret					; return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;10 nano seconds delay
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
ten66ns:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;the ws2812 reset procedure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LED_RESET:					;66us
	cbi portb,0
	ldi r16,255
loop1:
	dec r16
	brne loop1
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;delay routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delay:
	push r16
	ldi r16,250
	rcall delay1
dd:	dec r16
	brne dd
	pop r16
	ret

delay1:
	push r20
	ldi r20,250
ddd:dec r20
	brne ddd
	pop r20
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1 milli second delay routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ms1:
	push r16
	ldi r16,10
msloop:
	rcall delay
	dec r16
	brne msloop
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delayms:
;	ldi r22,16
delaymsloop:
	rcall ms1
	dec r22
	brne delaymsloop
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;LHS indicator lamp flash routine - leds sequence from rhs to lhs /anti clockwise
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

audi:
	ldi r20,24			;load r20 with # of LEDs , tested with 24 led ring
	ldi r21,1			;load r21 with 1 (1st step ,will be increased by audiloop, max out at 24 steps for each led)
	ldi r22,24			;load r22 with # of leds , tested with 24 led ring
audiloop:
	cpi r21,25			;check r21 reached 25th step (means 24 steps finished for 24 leds and all leds light up)
	breq allon			;if all 24 steps are finished branch to allon to exit procedure
	cpi r21,24			;check if r21 is on the 24th step, the last step has no unlit leds so no need blank procedure
	breq orangeloop		;branch to orangeloop , override sendblack as all leds are to be litup in the 24th step
	rcall sendblack		;1st step to 23rd step needs this procedure to keep leds off in the range of 23 - 1
	dec r22				;decrease r22 (step counter)
	cp r22,r21			;check whether step counter has performed enough black frames
	brne audiloop		;if required number of blank steps has not been performed loop back
orangeloop:
	rcall sendorange	;call procedure to light up the LED in orange colour
	dec r22				;dec step counter
	brne orangeloop		;if steps not exhausted loop through orangeloop
	rcall LED_RESET		;if all 24 steps have finished perform LED_RESET to latch data
	push r22			;save r22 for delay routine
	ldi r22,20           ; 16 ,now increased to 20 for more delay
	rcall delayms		;20.4ms for value 16 on logic analyzer
	pop r22				;restore r22 after delay proc
	inc r21				;increase led counter
	ldi r22,24			;reload the step counter
	rjmp audiloop		;jump back to audiloop
allon:					; return to caller when all 24 leds are lit
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;this procedure sends 24 off frames to each led to switch the entire indicator off , needed on continous power supply only
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
blackout:
	ldi r20,24			;load r20 with # of LEDs , here 24 leds on the ring from aliexpress
boloop:
	rcall sendblack		;call procedure to send 0s to all colours in each led 0x00,0x00,0x00
	dec r20				;decrease led counter
	brne boloop			;loop back till 24 sets are sent
	rcall LED_RESET		;sent led reset at the ned to latch sent data
	ret					; return to caller
	
	

	

sendblack:
	ldi data,0			;green
	rcall bytetx		;call byte transfer proc
	ldi data,0			;red
	rcall bytetx		;call byte transfer proc
	ldi data,0			;blue
	rcall bytetx		;call byte transfer proc
	ret					;return to caller
sendorange:
	ldi data,50			;green
	rcall bytetx		;call byte transfer proc
	ldi data,255		;red
	rcall bytetx		;call byte transfer proc
	ldi data,0			;blue
	rcall bytetx		;call byte transfer proc
	ret					;return to caller



