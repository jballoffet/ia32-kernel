;################################################################################
;#	Título: Wrapper								#
;#										#
;#	Versión:	1.0			Fecha: 	04/11/2015		#
;#	Autor: 		Javier Balloffet	Tab: 	4			#
;#	Compilación:								#
;#			Usar Makefile						#
;#	Uso: 			-						#
;#	------------------------------------------------------------------------#
;#	Descripción:								#
;#		* Rutinas de wrapper para servicios de kernel			#
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
; Simbolos externos y globales
;********************************************************************************

GLOBAL		Sleep
GLOBAL 		Scan_Key
GLOBAL 		Print_Screen
GLOBAL		Time

EXTERN		CG_SEL

;********************************************************************************
; Wrapper
;********************************************************************************

SECTION  	.shared	 		progbits

;--------------------------------------------------------------------------------
;|	Título: Sleep								|
;|	Versión:	1.0			Fecha: 	01/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		void Sleep(double cant_ms)					|
;|		Duerme la tarea la cantidad de ms pasada			|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		esp+4		cant_ms						|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

Sleep:
	mov	ebx,[esp+4]		; Paso parametros (1: cant_ms)
	push	dword 1			; Especifico No de Servicio Solicitado (1: Sleep)
	push	ebx
	call	CG_SEL:0		; Llama al callgate
	ret
	
;--------------------------------------------------------------------------------
;|	Título: Scan_Key							|
;|	Versión:	1.0			Fecha: 	01/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		void Scan_Key(char* key_ascii)					|
;|		Devuelve el ascii de la tecla pulsada por referencia		|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		esp+4		key_ascii					|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

Scan_Key:
	mov	ebx,[esp+4]		; Paso parametros (1: key_ascii)
	push	dword 2			; Especifico No de Servicio Solicitado (2: Scan_Key)
	push	ebx
	call	CG_SEL:0		; Llama al callgate
	ret
	
;--------------------------------------------------------------------------------
;|	Título: Print_Screen							|
;|	Versión:	1.0			Fecha: 	01/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		void Print_Screen(struct* param)				|
;|		Imprime en pantalla el string pasado por referencia		|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		esp+4		param						|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

Print_Screen:
	mov	ebx,[esp+4]		; Paso parametros (1: param)
	push	dword 3			; Especifico No de Servicio Solicitado (3: Print_Screen)
	push	ebx
	call	CG_SEL:0		; Llama al callgate
	ret
	
;--------------------------------------------------------------------------------
;|	Título: Time								|
;|	Versión:	1.0			Fecha: 	02/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		void Time(struct* param)					|
;|		Devuelve fecha y hora en la estructura pasada por referencia	|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		esp+4		param						|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

Time:
	mov	ebx,[esp+4]		; Paso parametros (1: param)
	push	dword 4			; Especifico No de Servicio Solicitado (4: Time)
	push	ebx
	call	CG_SEL:0		; Llama al callgate
	ret
	
;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet								c2015
;********************************************************************************