;########################################################################################
;#	Título: Codigo principal de la aplicacion de 32 bits				#
;#											#
;#	Versión:	1.0				Fecha: 	06/09/2015		#
;#	Autor: 		J. Balloffet			Tab: 	4			#
;#	Compilación:	Usar Makefile							#
;#	Uso: 			-							#
;#	------------------------------------------------------------------------	#
;#	Descripción:									#
;#	------------------------------------------------------------------------	#
;#	Revisiones:									#
;#		1.0 | 06/09/2015 | J.BALLOFFET | Inicial				#
;#	------------------------------------------------------------------------	#
;#	TODO:										#
;#		-									#
;########################################################################################

%include 	"general.inc"

;********************************************************************************
; Macros
;********************************************************************************

%define		PDPTE_1		PDPTE+0x12000
%define		PDPTE_2		PDPTE_1+0x12000
%define		PDPTE_3		PDPTE_2+0x12000

;********************************************************************************
; Simbolos externos
;********************************************************************************

GLOBAL		start32

GLOBAL		Idle

EXTERN		PDPTE					; definido en sys_tables.asm
EXTERN		TSS_INIT_SEL

EXTERN		krn_print_screen			; definido en lib32.asm
EXTERN		krn_clear_screen

;********************************************************************************
; Datos
;********************************************************************************

SECTION 	.data	
msgBooting1	db "Booteando sistema operativo...", NULL
msgBooting2	db "Comprobando handlers de excepciones y paginacion automatica...", NULL
msgBooting3	db "Fin del booteo exitoso, pulse ESC para ejecutar el Sistema Operativo", NULL
msgInicio1 	db "Sistema multitarea - Paginacion PAE 4kB - Scheduler por comp de interrupcion", NULL
msgInicio2 	db "Javier Francisco Balloffet - 1435887 - Tecnicas Digitales III - UTN FRBA - 2015", NULL
msgInicio8 	db "Prioridades por default: T1=4, T2=2, T3=3", NULL
msgInicio9 	db "Oprima F4 para todas las prioridades en 2 y F5 para volver al default", NULL
msgInicio3 	db "Tarea 1: Contador incremental. Para arrancar/pausar oprima F1", NULL
msgInicio4 	db "Tarea 2: Fecha y Hora de sistema. Para arrancar/pausar oprima F2", NULL
msgInicio5 	db "Tarea 3: Procesador de textos. Para comenzar/finalizar oprima F3", NULL
msgInicio6 	db "         Escriba del 0-9 y a-z. Para mayusculas pulse shift izquierdo", NULL
msgInicio7 	db ">:", NULL

;********************************************************************************
; Datos no inicializados
;********************************************************************************

SECTION		.bss	
semilla		resb 	1

USE32
;********************************************************************************
; Codigo principal
;********************************************************************************

SECTION  	.main 			progbits

start32:
	xchg	bx, bx						; Magic breakpoint
	
;**************************CARGO TR IDLE TASK*****************************
	
	mov 	ax, TSS_INIT_SEL
	ltr	ax						; Cargo TR con TSS_INIT_SEL
	
;************************INICIALIZAR PAGINACION***************************

;--------------CARGO CR3----------------

	mov	eax,PDPTE					; Cargo cr3 con direccion de PDPTE
	mov	cr3,eax

;-------------ACTIVO PAGINACION-------------

	mov 	eax,cr4
	or 	eax,00100000b 					; Seteo paginacion en PAE 4kb
	mov 	cr4,eax
	
	mov 	eax,cr0
	or 	eax,0x80000000					; Activo paginacion
	mov 	cr0,eax

;******************MENSAJE DE INICIO**************************

	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	0						; Y=0 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgBooting1					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	2						; Y=0 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgBooting2					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
;***********PRUEBO DIVIDE ERROR DIVIDIENDO POR CERO***********************

	mov	edx,0						; Dividendo parte alta
	mov	eax,100						; Dividendo parte baja
	mov	ecx,0						; Divisor igual a 0
	div	ecx						; eax = Resultado, edx = Resto

;********************PRUEBO GENERAL PROTECTION****************************
; NOTA DEL PROGRAMADOR: Se dejo esta prueba comentada, ya que haltea el sistema y no se puede volver a la ejecucion del programa

	;jmp	0:start32					; JUMP a un selector no definido
	
;**********************PRUEBO INVALID OPCODE******************************
; NOTA DEL PROGRAMADOR: Se dejo esta prueba comentada, ya que haltea el sistema y no se puede volver a la ejecucion del programa

	;dw	0x0F						; OPCODE INVALIDO

;***********************PRUEBO DOBLE FAULT********************************

; Para probar la excepcion de doble falta, generar la prueba de divide error, pero antes
; eliminar el selector de la idt y comentar el handler de dicha excepcion

;***********************PRUEBO PAGE FAULT*********************************
	
	mov	eax,0x00090000					; Intento escribir en varias paginas no presentes
	mov	[eax],dword 1
	
	mov	eax,0x00190000
	mov	[eax],dword 1
	
	mov	eax,0x00230000
	mov	[eax],dword 1
	
	mov	eax,0x00400000
	mov	[eax],dword 1
	
	mov	eax,0x00450000
	mov	[eax],dword 1
	
	mov	eax,0x00500000
	mov	[eax],dword 1
	
	mov	eax,0x07329381
	mov	[eax],dword 1
	
	mov	eax,0x40000000
	mov	[eax],dword 1

	rdtsc							; Rutina que genera un numero pseudo-aleatorio
	mov	[semilla],eax
	mov	ecx,4						; Intento escribir en 4 posiciones aleatorias de memoria
random:	
	mov	eax,314159265
	mul	dword[semilla]
	add	eax,123
	mov	[semilla],eax
	mov	[eax],dword 1					; Intento escribir en dicha posicion de memoria
	loop	random

;******************MENSAJE DE BOOTEO TERMINADO**************************

	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	8						; Y=0 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgBooting3					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros

;*************************ESPERO TECLA ESC********************************

; NOTA DEL PROGRAMADOR: Se dejo por pooling (sin handler de teclado) para mantener compatibilidad con los puntos anteriores de la guia

WaitESC:
	in	al,0x60						; Copio el contenido del puerto 0x60 en la parte baja de eax (rax/eax/ax/ah/al)
	cmp	al,ESC_KEY					; COMPARE - Comparo con 0x01 (tecla ESC)
	jne	WaitESC						; JUMP IF NOT EQUAL - Salto si ESC no esta pulsada

;********************ACTIVO INTERRUPCIONES*******************************

	mov	al,11111100b	         			; Activo IRQ0 e IRQ1
	out	0x21,al
	sti							; Habilito interrupciones

;************************BORRO PANTALLA**********************************

	call	krn_clear_screen				; Borro pantalla

;**********************IMPRIMO EN PANTALLA*******************************

	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	0						; Y=0 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio1					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	1						; Y=1 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio8					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16	
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	2						; Y=2 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio9					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16	
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	3						; Y=3 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio2					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	6						; Y=6 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio3					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	10						; Y=10 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio4					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	14						; Y=14 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio5					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	15						; Y=15 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio6					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
	push 	WHITE_F | BLACK_B				; Atributos: Color
	push	17						; Y=17 (FILA)
	push	0						; X=0 (COLUMNA)
	push 	msgInicio7					; Mensaje
	call 	krn_print_screen				; Imprime en pantalla. ABI32.
	add	esp, 16						; Limpio stack de parametros
	
;*****************************IDLE TASK***********************************

; NOTA DEL PROGRAMADOR: Se dejo la instruccion nop en vez de hlt, ya que sino el RTC del bochs no funciona correctamente y se acelera

Idle:
	nop ;hlt						; Detengo el procesador -  Procesador en estado Halted
	jmp	Idle						; JUMP- Idle Loop
	
;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet	 							c2015
;********************************************************************************