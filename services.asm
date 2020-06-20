;################################################################################
;#	Título: Servicios de Kernel						#
;#										#
;#	Versión:	1.0			Fecha: 	04/11/2015		#
;#	Autor: 		Javier Balloffet	Tab: 	4			#
;#	Compilación:								#
;#			Usar Makefile						#
;#	Uso: 			-						#
;#	------------------------------------------------------------------------#
;#	Descripción:								#
;#		* Servicios de Kernel						#
;#	------------------------------------------------------------------------#
;#	Revisiones:								#
;#		1.0 | 04/11/2015 | J.BALLOFFET | Inicial			#
;#	------------------------------------------------------------------------#
;#	TODO:									#
;#		-								#
;################################################################################

%include 	"general.inc"

USE32

;********************************************************************************
; Macros
;********************************************************************************

%define		TASKIDLE	0
%define		TASK1 		1
%define		TASK2 		2
%define		TASK3 		3

;********************************************************************************
; Simbolos externos y globales
;********************************************************************************

GLOBAL		service_print_screen
GLOBAL		service_scan_key
GLOBAL		service_sleep
GLOBAL		service_time

EXTERN		DS_SEL_KER			; definidos en sys_tables.asm
EXTERN		TSS_T1_SEL
EXTERN		TSS_T2_SEL
EXTERN		TSS_T3_SEL
EXTERN		Task1State
EXTERN		Task2State
EXTERN		Task3State

EXTERN		Task1SleepTime			; definidos en isr.asm
EXTERN		Task2SleepTime
EXTERN		Task3SleepTime

EXTERN		scankeyfifo			; definidos en isr.asm
EXTERN		counter
EXTERN		shiftflag

EXTERN		printcounter			; definidos en lib32.asm
EXTERN		scantable

EXTERN		CurrentTask

;********************************************************************************
; Servicios de Kernel
;********************************************************************************

SECTION  	.other	 		progbits	
	
;************************* Service 1: Sleep ****************************

service_sleep:
	cld
	push	es
	push	ds
	mov 	bx, DS_SEL_KER
 	mov 	ds, bx
  	mov 	es, bx
	;str	ax				; Veo que tarea solicito el servicio sleep
	mov	ax,[CurrentTask]
	cmp	ax, TASK1		;TSS_T1_SEL
	je	sleept1
	cmp	ax, TASK2		;TSS_T2_SEL
	je	sleept2
	cmp	ax, TASK3		;TSS_T3_SEL
	je	sleept3
	
sleept1:
	mov	byte [Task1State], 2		; Paso a estado Sleeping
	mov	[Task1SleepTime], ecx		; Cargo tiempo a dormir
	jmp	sleep_end
	
sleept2:
	mov	byte [Task2State], 2		; Paso a estado Sleeping
	mov	[Task2SleepTime], ecx		; Cargo tiempo a dormir
	jmp	sleep_end
	
sleept3:
	mov	byte [Task3State], 2		; Paso a estado Sleeping
	mov	[Task3SleepTime], ecx		; Cargo tiempo a dormir
	jmp	sleep_end
		
sleep_end:
	pop	ds
	pop	es
	int 	0x20				; Invoco al Scheduler
	ret
  
;********************* Service 2: Scan_Key **************************
	
service_scan_key:
	mov	edi, ecx
	cld
	push	es
	push	ds
	mov 	bx, DS_SEL_KER
	mov 	ds, bx
	mov 	es, bx
scanloop:
	xor	eax,eax
	xor	ebx,ebx
	xor	ecx,ecx
	mov	al,[counter]			; Hay algun dato nuevo en la FIFO? (tail ~= head)
	cmp	[printcounter],al
	jne	not_empty_fifo			; Si hay, salto				
	mov	eax,0xFF			; Devuelvo error
	jmp	scanend				; Si no hay, me voy
	
not_empty_fifo:
	mov	eax,scankeyfifo			; Cargo comienzo de la FIFO
	add	al,[printcounter]		; Le sumo tail
	mov	bl,[eax]			; Obtengo tecla
	add	[printcounter],byte 1		; Incremento tail en 1
	mov	al,[printcounter]		; Si llegue al final de la FIFO vuelvo al principio
	cmp	al,10
	jb	indexnotmax
	mov	[printcounter],byte 0
indexnotmax:	
	mov	eax,scantable			; Cargo tabla de scancodes
	add	al,bl				; Sumo offset de la tecla
	mov	cl,[eax]			; Obtengo ASCII de la tecla
	mov	eax,0x00
	cmp	cl,0xFF				; La tecla es valida?
	jne	scanok				; Si, devuelvo exito	
	mov	eax,0xFF			; No, devuelvo error
	jmp	scanend
scanok:	
	mov	bl,[shiftflag]
	cmp	bl,0				; Esta shift pulsado?
	je	scanend				; No, me voy
	cmp	cl,57				; Es un numero?
	jbe	scanend				; Si, me voy
	sub	cl,32				; Paso el caracter a mayuscula
scanend:	
	mov	[edi],cl			; Cargo en la variable, el ascii de la tecla pulsada
	pop	ds
	pop	es
	ret
	
;******************* Service 3: Print_Screen ***********************
 
service_print_screen:
	xor 	eax, eax			; EAX = 0
	mov	eax, [ecx+4]			; Cargo EAX con la fila (y)
	mov	ebx, 80	
	mul	bx				; Multiplico numero de fila por 80 (AX = AX*BX)
	add	eax, [ecx+8]			; Sumo columna (x)
	shl	eax, 1				; Multiplico por 2, ya que son 16 bits por caracter (atributos)
	mov	edi, eax			; Cargo en EAX en el Source Index
	add	edi, VGA_RAM			; Le sumo la direccion de inicio de la VGA_RAM
	mov	edx, [ecx]			; Cargo en EDX el color (atributos)
	add	ecx, 12
	mov	esi, ecx			; Cargo en el Source Index el puntero al string
	
	cld
	push	es
	push	ds
	mov 	bx, DS_SEL_KER
	mov 	ds, bx
	mov 	es, bx
.loop:
	lodsb					; Cargo siguiente caracter - LOAD STRING BYTE (AX <- DS:SI)
	or	al, al				; Es el caracter nulo? - Si es cero pone en 1 el ZERO FLAG
	jz	print_end			; JUMP IF ZERO	
	mov	[edi], al			; Cargo en lo apuntado por EDI el caracter (AL -> ES:DI)
	mov	[edi+1], dl			; Cargo en la direccion siguiente el atributo
	add	edi, 2				; Incremento el puntero EDI en 2
	jmp	.loop				; Sigo imprimiendo el resto

print_end:
	pop	ds
	pop	es
	ret

;******************* Service 4: Time ***********************
	
;--------------------------------------------------------------------------------
;|	Título: Control RTC							|
;|	Versión:	1.0			Fecha: 	02/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		Rutina para manejo de servicios del Reloj de Tiempo Real	|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		AL = 0 Subfuncion fecha						|
;|		AL = 1 Subfuncion hora						|
;|										|
;|	Retorna:								|
;|		Fecha:								|
;|			DH = Año  						|
;|			DL = Mes		  				|
;|			AH = Dia   						|
;|			AL = Dia de la semana					|
;|		Hora:								|
;|			DL = Hora		  				|
;|			AH = Minutos						|
;|			AL = Segundos						|
;|			CL = 0:OK  N:Codigo de error				|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

service_time:
	cld
	push	es
	push	ds
	mov 	bx, DS_SEL_KER
 	mov 	ds, bx
  	mov 	es, bx
	call	Fecha				; Servicio de Fecha
	mov	[ecx+24],dh			; Cargo Anio
	mov	[ecx+20],dl			; Cargo Mes
	mov	[ecx+12],ah			; Cargo Dia
	mov	[ecx+16],al			; Cargo Dia de la Semana
	call	Hora				; Servicio de Hora
	mov	[ecx+8],dl			; Cargo Hora
	mov	[ecx+4],ah			; Cargo Minutos
	mov	[ecx],al			; Cargo Segundos
	pop	ds
	pop	es
	ret

;--------------------------------------------------------------------------------
;|	Título: Auxiliar RTC							|
;|	Versión:	1.0			Fecha: 	02/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		Subfuncion para obtener la hora del sistema desde el RTC	|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		Nada								|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

Hora:
	call	RTC_disponible			; asegura que no esta actualizandose el RTC
	mov	al, 4
	out	70h, al				; Selecciona Registro de Hora
	in	al, 71h				; lee hora
	mov	dl, al

	mov	al, 2
	out	70h, al				; Selecciona Registro de Minutos
	in	al, 71h				; lee minutos
	mov	ah, al

	xor	al, al
	out	70h, al				; Selecciona Registro de Segundos
	in	al, 71h				; lee minutos
	ret
	
;--------------------------------------------------------------------------------
;|	Título: Auxiliar RTC							|
;|	Versión:	1.0			Fecha: 	02/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		Subfuncion para obtener la fecha del sistema desde el RTC	|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		Nada								|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

Fecha:
	call	RTC_disponible			; asegura que no esta actualizandose el RTC
	mov	al, 9
	out	70h, al				; Selecciona Registro de Anio
	in	al, 71h				; lee anio
	mov	dh, al

	mov	al, 8
	out	70h, al				; Selecciona Registro de Mes
	in	al, 71h				; lee mes
	mov	dl, al

	mov	al, 7
	out	70h, al				; Selecciona Registro de Fecha
	in	al, 71h				; lee Fecha del mes
	mov	ah, al

	mov	al, 6
	out	70h, al				; Selecciona Registro de Di­a 
	in	al, 71h				; lee dia de la semana
	ret
	
;----------------------------------------------------------------------------------------
;|	Título: Auxiliar RTC								|
;|	Versión:	1.0			Fecha: 	02/11/2015			|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7			|
;|	--------------------------------------------------------------------------------|
;|	Descripción:									|
;| 		Verifica en el Status Register A que el RTC no esta actualizando	|
;|		fecha y hora.								|
;| 		Retorna cuando el RTC esta disponible					|
;|	--------------------------------------------------------------------------------|
;|	Recibe:										|
;|		Nada									|
;|	Retorna:									|
;|		Nada									|
;|	--------------------------------------------------------------------------------|
;|	Revisiones:									|
;----------------------------------------------------------------------------------------

RTC_disponible:
	mov	al, 0Ah
	out	70h, al				; Selecciona registro de status A
wait_for_free:
	in	al, 71h				; lee Status
	test	al, 80h
	jnz	wait_for_free
	ret

;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet								c2015
;********************************************************************************