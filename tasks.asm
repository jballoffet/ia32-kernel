;################################################################################
;#	Título: Tasks								#
;#										#
;#	Versión:	1.0			Fecha: 	13/10/2015		#
;#	Autor: 		Javier Balloffet	Tab: 	4			#
;#	Compilación:								#
;#			Usar Makefile						#
;#	Uso: 			-						#
;#	------------------------------------------------------------------------#
;#	Descripción:								#
;#		* Rutinas de tareas para sistema multitarea			#
;#	------------------------------------------------------------------------#
;#	Revisiones:								#
;#		1.0 | 13/10/2015 | J.BALLOFFET | Inicial			#
;#	------------------------------------------------------------------------#
;#	TODO:									#
;#		-								#
;################################################################################

%include 	"general.inc"

USE32

;********************************************************************************
; Simbolos externos y globales
;********************************************************************************

GLOBAL		Inicio_T1
GLOBAL		Inicio_T2
GLOBAL		Inicio_T3

EXTERN		Sleep					; definidos en wrapper.asm
EXTERN		Scan_Key
EXTERN		Print_Screen
EXTERN		Time

;********************************************************************************
; Datos
;********************************************************************************

SECTION 	.t1_data		progbits
printstruct1:
atributos1	dd 0
fila1		dd 0
columna1	dd 0
Contador_T1 	db "000000000", NULL

SECTION 	.t2_data		progbits
printstruct2:
atributos2 	dd 0
fila2		dd 0
columna2	dd 0
Contador_T2 	db "          00/00/00 - 00:00:00", NULL

timestruct2:
segundo2	dd 0
minuto2		dd 0
hora2		dd 0
dia2		dd 0
diasemana2	dd 0
mes2		dd 0
anio2		dd 0

numASCII	dd 0

dias:
domingo		db " Domingo ",NULL
lunes		db "  Lunes  ",NULL
martes		db "  Martes ",NULL
miercoles	db "Miercoles",NULL
jueves		db "  Jueves ",NULL
viernes		db " Viernes ",NULL
sabado		db "  Sabado ",NULL

SECTION 	.t3_data		progbits
key_ascii	db 0
printstruct3:
atributos3	dd 0
fila3		dd 0
columna3	dd 0
msgPtr		db 0, NULL

;********************************************************************************
; Tareas
;********************************************************************************

;------------------------------------TAREA 1-------------------------------------
; Contador incremental
;--------------------------------------------------------------------------------

SECTION		.t1_main		progbits		
Inicio_T1:	
	mov	edi, Contador_T1			; Cargo contador y lo incremento
	mov 	al, '0'
	mov 	ecx, 9
	cld
	rep 	stosb
ciclo_t1:
	mov 	edi, Contador_T1 + 8
	mov 	ecx, 9
ciclo_incrementar1:
	mov 	al, [edi]
	inc 	al
	cmp 	al, '9'
	jbe	digito_ok1
	mov 	al, '0'
	mov 	[edi], al
	dec	edi
	loop	ciclo_incrementar1
	jmp	mostrar_t1
digito_ok1:
	mov 	[edi], al
mostrar_t1:
	mov	dword[atributos1],WHITE_F | BLACK_B	; Atributos: Color
	mov	dword[fila1],8				; Y=8 (FILA)
	mov	dword[columna1],36			; X=36 (COLUMNA)
	push	printstruct1				; Pusheo puntero a estructura de parametros de impresion
	call	Print_Screen				; Llamo al servicio Print_Screen que imprime en pantalla
	add	esp, 4					; Limpio stack de parametros	
	
;NOTA DEL PROGRAMADOR: Si bien no es recomendable que una tarea se aduenie del procesador, se realizo de esta manera a fines demostrativos
;		       del funcionamiento de las prioridades en el scheduler
	
	;mov	eax,100
	;push	eax					; Pusheo cantidad de ms a dormir la tarea
	;call	Sleep					; Llamo al servicio Sleep que duerme la tarea la cantidad de ms indicada
	;add	esp, 4					; Limpio stack de parametros
	
	;mov	ecx,0xFFFFFFF
;caverna:	
	;loop	caverna	
	jmp	ciclo_t1
  
;------------------------------------TAREA 2-------------------------------------
; Muestra fecha y hora de sistema
;--------------------------------------------------------------------------------

SECTION		.t2_main		progbits
Inicio_T2:
ciclo_t2:	
	mov	eax,segundo2				; Limpio registros de tiempo
	mov	ecx,7
cleanloop:
	mov	dword[eax],0x0000
	loop	cleanloop
	
	push	timestruct2				; Pusheo puntero a estructura de parametros de tiempo
	call	Time					; Llamo al servicio Time que devuelve fecha y hora del sistema
	add	esp, 4					; Limpio stack de parametros	
	
	mov	eax,segundo2				; Cargo eax con el primer parametro de tiempo
	mov	ecx,7					; Cargo ecx con la cantidad de parametros de tiempo
cvtASCII:
	push	eax					; Pusheo parametro de tiempo
	call	timetoASCII				; Subrutina que convierte el tiempo a ASCII
	add	esp, 4					; Limpio stack de parametros
	add	eax,4					; Incremento al parametro que sigue
	loop	cvtASCII
	
	mov	ax,[segundo2]				; Cargo segundos en el string
	mov	[Contador_T2+28],al
	mov	[Contador_T2+27],ah
	
	mov	ax,[minuto2]				; Cargo minutos en el string
	mov	[Contador_T2+25],al
	mov	[Contador_T2+24],ah
	
	mov	ax,[hora2]				; Cargo hora en el string
	mov	[Contador_T2+22],al
	mov	[Contador_T2+21],ah
	
	mov	ax,[anio2]				; Cargo anio en el string
	mov	[Contador_T2+17],al
	mov	[Contador_T2+16],ah
	
	mov	ax,[mes2]				; Cargo mes en el string
	mov	[Contador_T2+14],al
	mov	[Contador_T2+13],ah
	
	mov	ax,[dia2]				; Cargo dia en el string
	mov	[Contador_T2+11],al
	mov	[Contador_T2+10],ah
	
 	xor	edx,edx					; Obtengo string correspondiente al dia de la semana
 	mov	eax,[diasemana2]
 	sub	eax,0x3030
	mov	ebx,domingo
	cmp	eax,1
	je	copy
	mov	ebx,lunes
	cmp	eax,2
	je	copy
	mov	ebx,martes
	cmp	eax,3
	je	copy
	mov	ebx,miercoles
	cmp	eax,4
	je	copy
	mov	ebx,jueves
	cmp	eax,5
	je	copy
	mov	ebx,viernes
	cmp	eax,6
	je	copy
	mov	ebx,sabado
copy:
 	mov	eax,Contador_T2
 	mov	ecx,9
loopcopy:
 	mov	dl,[ebx]				; Cargo dia de la semana en el string
 	mov	[eax],dl
 	add	ebx,1
 	add	eax,1
 	loop	loopcopy

mostrar_t2:
	mov	dword[printstruct2],WHITE_F | BLACK_B	; Atributos: Color	
	mov	dword[fila2],12				; Y=12 (FILA)			
	mov	dword[columna2],26			; X=26 (COLUMNA)
	push	printstruct2				; Pusheo puntero a estructura de parametros de impresion
	call	Print_Screen				; Llamo al servicio Print_Screen que imprime en pantalla
	add	esp, 4					; Limpio stack de parametros
	
	mov	eax,500
	push	eax					; Pusheo cantidad de ms a dormir la tarea (no tiene sentido que corra permanentemente)
	call	Sleep					; Llamo al servicio Sleep que duerme la tarea la cantidad de ms indicada
	add	esp, 4					; Limpio stack de parametros
	
	jmp	ciclo_t2
	
;------------------------------------TAREA 3-------------------------------------
; Procesador de textos desde el teclado
;--------------------------------------------------------------------------------

SECTION		.t3_main		progbits		
Inicio_T3:
	mov	[fila3],dword 17			; Y=17 (FILA)
	mov	[columna3],dword 2			; X=2 (COLUMNA)

escaneo:	
	push	key_ascii				; Paso por referencia key_ascii
	call	Scan_Key				; Llamo al servicio Scan_Key que devuelve la tecla pulsada
	add	esp, 4					; Limpio stack de parametros
	cmp	eax,0x00				; Chequeo error en la lectura de teclado
	je	show_char				; Si no hubo error, muestro tecla
	
;NOTA DEL PROGRAMADOR: Si bien no es recomendable que una tarea se aduenie del procesador, se realizo de esta manera a fines demostrativos
;		       del funcionamiento de las prioridades en el scheduler
	
	;mov	eax,10
	;push	eax					; Pusheo cantidad de ms a dormir la tarea (no tiene sentido que corra permanentemente)
	;call	Sleep					; Llamo al servicio Sleep que duerme la tarea la cantidad de ms indicada
	;add	esp, 4					; Limpio stack de parametros
	
	jmp	escaneo					; Tecla erronea o no se pulso el teclado
		
show_char:	
	mov	al,[key_ascii]				; Cargo en AL el caracter pulsado
	mov	[msgPtr],al				; Cargo caracter en la posicion de memoria apuntada por msgPtr
	mov	dword[atributos3],WHITE_F | BLACK_B	; Atributos: Color
	push	printstruct3				; Pusheo puntero a estructura de parametros de impresion
	call	Print_Screen				; Llamo al servicio Print_Screen que imprime en pantalla
	add	esp, 4					; Limpio stack de parametros
	
	add	[columna3],dword 1			; Incremento columna
	cmp	dword[columna3],79			; Llegue al final de la linea?
	jbe	escaneo					; No llegue. sigo
	mov	[columna3],dword 0			; Llegue, retorno de carro
	add	[fila3],dword 1				; Incremento linea
	cmp	dword[fila3],24				; Llegue al final de la pantalla?
	jbe	escaneo					; No llegue, sigo
	mov	[fila3],dword 17			; Llegue, reseteo fila y columna
	mov	[columna3],dword 2
	jmp	escaneo

;********************************************************************************
; Funciones
;********************************************************************************

SECTION  	.t2_main 		progbits
;--------------------------------------------------------------------------------
;|	Título: timetoASCII							|
;|	Versión:	1.0			Fecha: 	02/11/2015		|
;|	Autor: 		Javier Balloffet	Legajo:	143.588-7		|
;|	------------------------------------------------------------------------|
;|	Descripción:								|
;|		void timetoASCII(unsigned int numero)				|
;|		Convierte un numero entero positivo de 2 cifras a ASCII		|
;|	------------------------------------------------------------------------|
;|	Recibe:									|
;|		esp+4		numero						|
;|										|
;|	Retorna:								|
;|		Nada								|
;|	------------------------------------------------------------------------|
;|	Revisiones:								|
;--------------------------------------------------------------------------------

timetoASCII:
	push	ebp					; Resguardo Stack Base Pointer
	mov	ebp, esp				; Puntero imagen - Stack Pointer
	pushad						; Resguardo Registros de Uso General
	mov	edx,[ebp+8]
	mov	ax,[edx]				; Obtengo numero a convertir
	mov	ebx,[ebp+8]				; Obtengo donde devolverlo
	mov	cx,ax
	and	al,0x0F
	mov	[ebx],al
	add	byte[ebx],0x30
	mov	ax,cx
	shr	ax,4
	and	al,0x0F
	mov	[ebx+1],al
	add	byte[ebx+1],0x30
	popad						; Obtengo Registros de Uso General
	pop	ebp					; Obtengo Stack Base Pointer
	ret
	
;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet								c2015
;********************************************************************************