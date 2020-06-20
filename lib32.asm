;################################################################################
;#	Título: Funciones auxiliares						#
;#										#
;#	Versión:	1.0			Fecha: 	13/09/2015		#
;#	Autor: 		Javier Balloffet	Tab: 	4			#
;#	Compilación:								#
;#			Usar Makefile						#
;#	Uso: 			-						#
;#	------------------------------------------------------------------------#
;#	Descripción:								#
;#		* Funciones auxiliares para modo protegido 32 bits		#
;#	------------------------------------------------------------------------#
;#	Revisiones:								#
;#		1.0 | 13/09/2015 | J.BALLOFFET | Inicial			#
;#	------------------------------------------------------------------------#
;#	TODO:									#
;#		-								#
;################################################################################

%include 	"general.inc"

USE32

;********************************************************************************
; Simbolos externos y globales
;********************************************************************************

GLOBAL		printcounter
GLOBAL		scantable
GLOBAL		krn_print_screen
GLOBAL		krn_clear_screen
GLOBAL		krn_inverse_screen
GLOBAL		krn_scan_code

EXTERN		scankeyfifo			; definidos en isr.asm
EXTERN		counter
EXTERN		shiftflag

;********************************************************************************
; Datos
;********************************************************************************

SECTION 	.data
printcounter	db	0
scantable	db	0,0xFF,"1","2","3","4","5","6","7","8","9","0",0xFF,0XFF,0xFF,0xFF
		db	"q","w","e","r","t","y","u","i","o","p",0xFF,0XFF,0xFF,0xFF,"a","s"
		db	"d","f","g","h","j","k","l",0xFF,0XFF,0xFF,0xFF,0xFF,"z","x","c","v"
		db	"b","n","m",0xFF,0XFF,0xFF,0xFF,0xFF,0XFF," "

;********************************************************************************
; Funciones auxiliares
;********************************************************************************
SECTION  	.lib	 		progbits

;--------------------------------------------------------------------------------
;|	Título: Impresion en pantalla 						|
;|	Versión:	1.0			Fecha: 	13/09/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		krn_print_screen(char *string, char x, char y, char color)	|
;|		Impresion en modo texto sobre RAM de video			|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		ebp+8		*string						|
;| 		ebp+12		x (columna)					|
;|		ebp+16		y (fila)					|
;| 		ebp+20		color						|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

krn_print_screen:
	push	ebp				; Resguardo Stack Base Pointer
	mov	ebp, esp			; Puntero imagen - Stack Pointer
	pushad
	mov	esi, [ebp+8]			; Cargo en el Source Index el puntero al string
	xor 	eax, eax			; EAX = 0
	mov	eax, [ebp+16]			; Cargo EAX con la fila (y)
	mov	ebx, 80	
	mul	bx				; Multiplico numero de fila por 80 (AX = AX*BX)
	add	eax, [ebp+12]			; Sumo columna (x)
	shl	eax, 1				; Multiplico por 2, ya que son 16 bits por caracter (atributos)
	mov	edi, eax			; Cargo en EAX en el Source Index
	add	edi, VGA_RAM			; Le sumo la direccion de inicio de la VGA_RAM
	mov	edx, [ebp+20]			; Cargo en EDX el color (atributos)

.loop:
	lodsb					; Cargo siguiente caracter - LOAD STRING BYTE (AX <- DS:SI)
	or	al, al				; Es el caracter nulo? - Si es cero pone en 1 el ZERO FLAG
	jz	krn_p_s_end			; JUMP IF ZERO	
	mov	[edi], al			; Cargo en lo apuntado por EDI el caracter (AL -> ES:DI)
	mov	[edi+1], dl			; Cargo en la direccion siguiente el atributo
	add	edi, 2				; Incremento el puntero EDI en 2
	jmp	.loop				; Sigo imprimiendo el resto

krn_p_s_end:
	popad
	pop	ebp				; Obtengo Stack Base Pointer
	ret

;--------------------------------------------------------------------------------
;|	Título: Limpieza de pantalla 						|
;|	Versión:	1.0			Fecha: 	13/09/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		krn_clear_screen()						|
;|		Impresion en modo texto sobre RAM de video			|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		Nada								|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

krn_clear_screen:
	pushad
	mov	edi, VGA_RAM
	xor	eax, eax
	mov	ecx, 80*25

.loop:
	stosw					; AX -> ES:DI
	loop	.loop
	popad
	ret
	
;--------------------------------------------------------------------------------
;|	Título: Pantalla en modo inverso					|
;|	Versión:	1.0			Fecha: 	13/09/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		krn_inverse_screen()						|
;|		Impresion en modo texto sobre RAM de video			|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		Nada								|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

krn_inverse_screen:
	pushad
	mov	edi, VGA_RAM
	mov	ah,0x70				; Cargo en AH el color blanco para lograr el modo inverso
	mov	al,0x00				; Cargo en AL cero para limpiar la pantalla - AX=AH:AL
	mov	ecx, 80*25			; Cargo en CX la cantidad de veces a realizar el bucle

.loop:
	stosw					; STORE STRING WORD - AX -> ES:DI (Incrementa DI en 2)
	loop	.loop				; Decrementa CX y salta si CX no es cero
	popad
	ret
	
;--------------------------------------------------------------------------------
;|	Título: Obtener Scan Code						|
;|	Versión:	1.0			Fecha: 	14/09/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		char GetScanCode()						|
;|		Obtiene la tecla pulsada de un Scan Code en una FIFO		|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		Nada								|
;|										|
;|	Retorna:								|
;|		ebp+8		&char caracter pulsado				|
;|		EAX		0x00 OK - OxFF ERROR				|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

krn_scan_code:
	push	ebp				; Resguardo Stack Base Pointer
	mov	ebp, esp			; Puntero imagen - Stack Pointer
	pushad
scanloop:
	xor	eax,eax
	xor	ebx,ebx
	xor	ecx,ecx
	mov	al,[counter]
	cmp	[printcounter],al
	jne	not_empty_fifo
	hlt
	jmp	scanloop
	
not_empty_fifo:
	mov	eax,scankeyfifo
	add	al,[printcounter]
	mov	bl,[eax]
	add	[printcounter],byte 1
	mov	al,[printcounter]
	cmp	al,10
	jb	indexnotmax
	mov	[printcounter],byte 0
indexnotmax:	
	mov	eax,scantable
	add	al,bl
	mov	cl,[eax]
	mov	eax,0x00			;devuelvo exito
	cmp	cl,0xFF
	jne	scanok				;exito!		
	mov	eax,0xFF			;devuelvo error
	jmp	scanend
scanok:	
	mov	bl,[shiftflag]
	cmp	bl,0				; Esta shift pulsado?
	je	scanend
	;xchg	bx,bx
	cmp	cl,57				; Es un numero??
	jbe	scanend
	sub	cl,32				; Lo paso a mayusculas
scanend:	
	mov	edi,[ebp+8],			; Cargo el registro indice con la direccion de la variable pasada por referencia
	mov	[edi],cl			; Cargo en la variable, el ascii de la tecla pulsada
	popad
	pop	ebp				; Obtengo Stack Base Pointer
	ret

;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet								c2015
;********************************************************************************