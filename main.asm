;
; dif_tempo_assembly.asm
;
; Created: 29/12/2017 13:43:06
; Author : MarianoBW
;
.def temp    = R16
.def time1 = r17
.def time2 = r18
.def sum40 = r19
.def dir=r20
.def flag40khz = R23


;.equ CLOCK   = 8000000
;.equ BAUD    = 9600
;.equ UBRRVAL = CLOCK/(BAUD*16)-1



.org 0x0000
	rjmp start

.org 0x002           ; local da memoria do ext_int0       pag 65
	rjmp int0_calc

.org 0x004           ; local da memoria do ext_int1
	rjmp int1_ini

.org 0x001A   ; timer1 ovf
	rjmp timer1_ovf

.org 0x001C   ; local da memoria do TIM0_COMPA 
	rjmp TIM0_COMPA



start:
	cli
	;
	ldi temp,0b10000000
	;sts CKSEL,r16
	sts CLKPR,temp
	;ldi r16,0b10000000
	;sts CLKPR,r16
	ldi temp,0b00000000
	sts CLKPR,temp
	;
	;saidas e entradas
	;ldi r16,0b11000001     ;configura pino PD0,PD6,PD7,PC3,PC4 como saída e demais como entradas
	sbi DDRD,0
	sbi DDRD,6
	sbi DDRD,7
	sbi DDRC,3
	sbi DDRC,4
	;--------------------
	;40KHz
	
	;cli
	ldi temp,0b00000000
	out TCCR0A,temp
	out TCCR0B,temp
	ldi temp,0b00000010    ;configura TCC0A    CTC mode		 pg 104
	out TCCR0A,temp
	ldi temp,0b00000001    ;configura TCC0B    clk/1			 pg 107
	out TCCR0B,temp
	ldi temp,0b11111000    ; OCR0A = 248 
	;ldi temp,0b01100100    ; OCR0A = 100 
	;ldi r16,0b00000000
	out OCR0A,temp
	ldi temp,0b00000000    ; saida = 0
	out PORTD,temp
	ldi temp,0b00000010    ;liga clk 40khz
	sts TIMSK0,temp
	;
	;-------------------------------
	;interrupçao externa
	ldi temp,0b00001110 ; rising edge of INT1 /  falling edge of INT0 // pg 71
	sts EICRA,temp
	ldi temp,0b00000010 ; liga int1 e int0
	out EIMSK,temp      
	;
	;-------------------------------
	;Timer1 config
	ldi temp,0b00000000
	sts TCCR1A,temp        ;configura TCCR1A    normal mode		 pg 132
	;out TCCR1B,r16
	ldi temp,0b00000001    ;configura TCCR1B    clk/1			 pg 133
	sts TCCR1B,temp
	ldi temp,0b00000001    ;liga timer1 ovf
	sts TIMSK1,temp

	; ini var
	ldi temp,0b00000000
	ldi sum40,0b00000000 ; contador de pulsos
	ldi dir,0b00000000
	ldi flag40khz,0b00000000    ; flag 40khz
	
	sei					 ; ativa interrupçao
	rjmp loop


loop:
	;sei
	nop
	rjmp loop



TIM0_COMPA: ; nao funciona ?????
	cli
	;cpi sum40,0b00000101
	;breq fim40khz
	cpi flag40khz,0b00000000 ; se flag = 0 
	brne baixo ;PC+2 ; entao   / pula 1 linha se nao igual
	rjmp cima  ; seta 1 no pind6

cima:
	sbi PORTD,6 ; seta 1 no pind6
	ldi flag40khz,0b00000001 ; levanta flag 40khz
	sei
	add sum40,flag40khz
	rjmp loop
baixo:
	cbi PORTD,6 ; se nao, seta 0 no pind6
	ldi flag40khz,0b00000000 ; zerra flag 40khz
	sei
	rjmp loop
fim40khz:
	cbi PORTD,6
	ldi flag40khz,0b00000000
	
	ldi temp,0b00000000    ;configura TCC0B    clk off			 pg 107
	sts TCCR0B,temp
	sei
	rjmp loop
	;sei

int0_calc:
	cli
	ldi temp,0b00000000    ;configura TCC0B    clk off			 pg 107
	out TCCR0B,temp

	ldi temp,0b00000000    ;configura TCC1B    clk off			 pg 107
	sts TCCR1B,temp

	lds time1,TCNT1L    ; guarda valores de tempo							 /// ver se esta certo
	lds time2,TCNT1H    ;													             ||
	
	cbi PORTD,6 ;  seta 0 no pind6
	ldi flag40khz,0b00000000 ; zerra flag 40khz

	cbi PORTC,3  ; zerra controle de direçao
	cbi PORTC,4

	ldi temp,0b00000010 ;desativa int0 e ativa int1
	out EIMSK,temp

	sei
	rjmp loop

int1_ini:
	cli


	ldi temp,0b00000000 ; reseta timer 0 e 1
	out TCNT0,temp
	sts TCNT1L,temp     ; zerar o tempo									/// ver se esta certo
	sts TCNT1H,temp	   ;	

	
	ldi temp,0b00000001    ;configura TCCR0B    clk/1			 pg 107
	out TCCR0B,temp												      
	ldi temp,0b00000001    ;configura TCCR1B    clk/1		     pg 107
	sts TCCR1B,temp

	ldi temp,0b00000001 ;desativa int1 e ativa int0
	out EIMSK,temp 

	ldi sum40, 0b00000000

	cpi dir,0b00001000 
	breq dir2
	rjmp dir1

dir1:
	ldi dir,0b00001000
	sbi PORTC,3
	sei
	rjmp loop
dir2:
	ldi dir,0b00010000
	sbi PORTC,4
	sei
	rjmp loop



timer1_ovf:
	cli
	cpi r22,0b00000000 ; se flag = 0 
	brne baixo1 ;PC+2 ; entao   / pula 1 linha se nao igual
	rjmp cima1  ; seta 1 no pind0

cima1:
	sbi PORTD,0 ; seta 1 no pind0
	ldi r22,0b00000001 ; levanta flag
	sei
	rjmp loop
baixo1:
	cbi PORTD,0 ; se nao, seta 0 no pind0
	ldi r22,0b00000000 ; zerar flag 
	sei
	rjmp loop
	