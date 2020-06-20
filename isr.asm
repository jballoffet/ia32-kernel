;################################################################################
;#	Título: Interrupt Service Routines					#
;#										#
;#	Versión:	1.0			Fecha: 	13/09/2015		#
;#	Autor: 		Javier Balloffet	Tab: 	4			#
;#	Compilación:								#
;#			Usar Makefile						#
;#	Uso: 			-						#
;#	------------------------------------------------------------------------#
;#	Descripción:								#
;#		* Rutinas de atencion de excepciones e interrupciones		#
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
; Macros
;********************************************************************************

%define		MAX_SERV	4
%define		MAX_TABLES	0x00113000

%define		TASKIDLE	0
%define		TASK1 		1
%define		TASK2 		2
%define		TASK3 		3

%define		CONTEXT_ESP0	0x00
%define		CONTEXT_SS0	0x04
%define		CONTEXT_CR3	0x08
%define		CONTEXT_EIP	0x0C
%define		CONTEXT_ESP3	0x10
%define		CONTEXT_ES	0x14
%define		CONTEXT_CS	0x18
%define		CONTEXT_SS3	0x1C
%define		CONTEXT_DS	0x20
%define		CONTEXT_FS	0x24
%define		CONTEXT_GS	0x28
%define		CONTEXT_ACCESS	0x2C
%define		CONTEXT_STACK0	0x30


;********************************************************************************
; Simbolos externos y globales
;********************************************************************************

GLOBAL		div_error_excep0_handler
GLOBAL		debug_excep1_handler
GLOBAL 		breakpoint_excep3_handler
GLOBAL		overflow_excep4_handler
GLOBAL		bound_range_excep5_handler
GLOBAL		undef_opcode_excep6_handler
GLOBAL		dev_not_avail_excep7_handler
GLOBAL		double_fault_excep8_handler
GLOBAL		invalid_tss_excep10_handler
GLOBAL		segm_not_pres_excep11_handler
GLOBAL		stack_segment_excep12_handler
GLOBAL		gen_prot_excep13_handler
GLOBAL		page_fault_excep14_handler
GLOBAL		float_error_excep16_handler
GLOBAL		align_check_excep17_handler
GLOBAL		machine_check_excep18_handler
GLOBAL		simd_float_excep19_handler
GLOBAL		virtual_excep20_handler
GLOBAL		tmr_int32_handler
GLOBAL		key_int33_handler

GLOBAL		scankeyfifo
GLOBAL		counter
GLOBAL		shiftflag

GLOBAL		Services

GLOBAL		Task1SleepTime
GLOBAL		Task2SleepTime
GLOBAL		Task3SleepTime

EXTERN		krn_print_screen			; definidos en lib32.asm
EXTERN		krn_clear_screen

EXTERN		PDPTE					; definidos en sys_tables.asm
EXTERN		DS_SEL_KER
EXTERN		TSS_INIT_SEL
EXTERN		Task1State
EXTERN		Task2State
EXTERN		Task3State
EXTERN		Task1Priority
EXTERN		Task2Priority
EXTERN		Task3Priority
EXTERN		selector_nueva_tarea
EXTERN		nueva_tarea

EXTERN		service_print_screen			; definidos en services.asm
EXTERN		service_scan_key
EXTERN		service_sleep
EXTERN		service_time

EXTERN		CurrentTask
EXTERN		ContextsList

EXTERN		TSS_INIT

;********************************************************************************
; Datos
;********************************************************************************

SECTION 	.data		
msgHandler0 	db "Excepcion 0: Division por cero", NULL
msgHandler1 	db "Excepcion 1: Debug", NULL
msgHandler3 	db "Excepcion 3: Breakpoint", NULL
msgHandler4 	db "Excepcion 4: Overflow", NULL
msgHandler5 	db "Excepcion 5: Bound range excedido", NULL
msgHandler6 	db "Excepcion 6: Opcode indefinido", NULL
msgHandler7 	db "Excepcion 7: Dispositivo no disponible", NULL
msgHandler8 	db "Excepcion 8: Doble falta", NULL
msgHandler10 	db "Excepcion 10: TSS Invalida", NULL
msgHandler11 	db "Excepcion 11: Segmento no presente", NULL
msgHandler12 	db "Excepcion 12: Falla de segmento de pila", NULL
msgHandler13 	db "Excepcion 13: Proteccion general", NULL
msgHandler14 	db "Excepcion 14: Falla de pagina -> Repaginando...", NULL
msgHandler16 	db "Excepcion 16: Error de punto flotante de FPU", NULL
msgHandler17 	db "Excepcion 17: Chequeo de alineacion", NULL
msgHandler18 	db "Excepcion 18: Chequeo de maquina", NULL
msgHandler19 	db "Excepcion 19: Error de punto flotante de SIMD", NULL
msgHandler20 	db "Excepcion 20: Virtualizacion", NULL

tablepointer	dd 0x00106000
pagepointer	dd 0x00160000

pdptedesc	dd 0
dpdesc		dd 0
tpdesc		dd 0

counter		dd 0
shiftflag	db 0

Task1SleepTime	dd 0
Task2SleepTime	dd 0
Task3SleepTime	dd 0

T1Runnable	db 0
T2Runnable	db 0
T3Runnable	db 0

MaxPriorReach	db 0

Handlers:								; Handlers: Puntero a funcion
		dd	0						; Null pointer
		dd	service_sleep	
		dd	service_scan_key
		dd	service_print_screen
		dd	service_time

;********************************************************************************
; Datos no inicializados
;********************************************************************************

SECTION		.bss	
scankeyfifo	resb 	10

;********************************************************************************
; Interrupt Service Routines
;********************************************************************************

SECTION  	.lib	 		progbits

;***************** Handler de Timer - Scheduler ***********************

tmr_int32_handler:
	push		ds				; Salvo registros
	push		es
	pushad
	
	mov		ebx,0
	mov		bl, [CurrentTask]
	mov		eax, dword[ContextsList+ebx*4]	; Coloco EAX apuntando al contexto de la tarea actual (en ejecucion)
	
	mov		[eax +CONTEXT_ESP0], esp	; Guardo en el contexto de la tarea actual el ESP0
	
	mov		ax,DS_SEL_KER			; Direcciono datos de kernel
	mov 		ds,ax
	mov 		es,ax
	
	mov 		al,0x20               		; PIC EOI (End of Interrupt)
	out 		0x20,al

;---------- Descuento de los contadores de Sleep ---------------
	
	cmp 		byte [Task1State], 2 		; Me fijo si Tarea1 esta durmiendo (Sleep)
	jne		checktmr2			; Si no duerme me voy
	dec		dword[Task1SleepTime]		; Decremento el contador de sleep
	cmp 		dword[Task1SleepTime], 0	; Me fijo si es cero
	jne		checktmr2			; Si no es cero todavia debe dormir
	mov		byte [Task1State], 1		; Arriba tarea1! Pasa a ready, fin del tiempo de sleep
checktmr2:	
	cmp 		byte [Task2State], 2 		; Me fijo si Tarea2 esta durmiendo (Sleep)
	jne		checktmr3			; Si no duerme me voy
	dec		dword[Task2SleepTime]		; Decremento el contador de sleep
	cmp 		dword[Task2SleepTime], 0	; Me fijo si es cero
	jne		checktmr3			; Si no es cero todavia debe dormir
	mov		byte [Task2State], 1		; Arriba tarea2! Pasa a ready, fin del tiempo de sleep
checktmr3:	
	cmp 		byte [Task3State], 2 		; Me fijo si Tarea3 esta durmiendo (Sleep)
	jne		scheduler			; Si no duerme me voy
	dec		dword[Task3SleepTime]		; Decremento el contador de sleep
	cmp 		dword[Task3SleepTime], 0	; Me fijo si es cero
	jne		scheduler			; Si no es cero todavia debe dormir
	mov		byte [Task3State], 1		; Arriba tarea3! Pasa a ready, fin del tiempo de sleep

;----------------------- Scheduler ------------------------------
	
scheduler:
	mov		byte [T1Runnable], 0		; Evaluar prioridades
	mov		byte [T2Runnable], 0
	mov		byte [T3Runnable], 0
	mov		byte [MaxPriorReach], 0
	mov		ecx,0
	mov		cl,9				; Cargo en cl el maximo nivel de prioridad (9)
	
priorityloop:						; Loop que recorre las prioridades desde 9 (max prioridad) hasta 1 (idle task)
	cmp 		cl,[Task1Priority]  
	je		CheckTask1
prior2:
	cmp 		cl,[Task2Priority]  
	je		CheckTask2
prior3:
	cmp 		cl,[Task3Priority]  
	je		CheckTask3
prior4:	
	cmp		byte [MaxPriorReach], 1		; Encontre alguna/s tarea/s en estado ready de mayor prioridad?
	je		dispatcher			; Si, me voy al dispatcher
	
	dec		cl				; No, entonces bajo la vara de prioridad
	cmp		cl,0				; Llegue a cero?
	jne		priorityloop			; No, entonces recorro el bucle nuevamente en busca de alguna tarea ready
	jmp		dispatcher			; Si, me voy al dispatcher (ejecutara idle task)
	
CheckTask1:
	cmp		byte [Task1State], 1		; Ready?
 	jne		prior2				; Not ready
	mov		byte [MaxPriorReach], 1		; Es de mayor prioridad
	mov		byte [T1Runnable], 1		; Factible de correr
	jmp		prior2
	
CheckTask2:
	cmp		byte [Task2State], 1		; Ready?
 	jne		prior3				; Not ready
	mov		byte [MaxPriorReach], 1		; Es de mayor prioridad
	mov		byte [T2Runnable], 1		; Factible de correr
	jmp		prior3
	
CheckTask3:
	cmp		byte [Task3State], 1		; Ready?
 	jne		prior4				; Not ready
	mov		byte [MaxPriorReach], 1		; Es de mayor prioridad
	mov		byte [T3Runnable], 1		; Factible de correr
	jmp		prior4

;----------------------- Dispatcher ------------------------------
	
dispatcher:		
	mov		eax,0
	mov		ax,[CurrentTask]		; Obtener tarea que se estaba ejecutando
	cmp 		ax, TASK1			; Es tarea 1?
	je		EjecutaT1			; Si es igual salto a EjecutaT1
	cmp 		ax, TASK2			; Es tarea 2?
	je		EjecutaT2			; Si es igual salto a EjecutaT2
	cmp 		ax, TASK3			; Es tarea 3?
	je		EjecutaT3			; Si es igual salto a EjecutaT3
	
	cmp 		byte [T2Runnable], 1 		; Ejecuta Idle Task - Me fijo si Tarea2 esta despierta (Ready)
	mov		ax, TASK2
	je 		CambiarTarea			; Si esta despierta cambio de tarea
	cmp		byte [T1Runnable], 1		; Me fijo si Tarea1 esta despierta (Ready)
	mov 		ax, TASK1
	je		CambiarTarea			; Si esta despierta cambio de tarea
	cmp		byte [T3Runnable], 1		; Me fijo si Tarea3 esta despierta (Ready)
	mov 		ax, TASK3
	je		CambiarTarea			; Si esta despierta cambio de tarea
	jmp		fin_tmr_hdlr			; TODAS LAS TAREAS DUERMEN (SLEEP) - NO CAMBIO DE TAREA, MANTIENE IDLE LA EJECUCION

EjecutaT1:
	cmp 		byte [T2Runnable], 1 		; T1 es solidaria y si T2 quiere correr (Ready) le pasa la bocha
	mov		ax, TASK2
	je 		CambiarTarea
	cmp 		byte [T3Runnable], 1 		; T1 es solidaria y si T3 quiere correr (Ready) le pasa la bocha
	mov		ax, TASK3
	je 		CambiarTarea
	cmp		byte [T1Runnable], 1		; T1 esta ready?
	mov 		ax, TASKIDLE		 
	jne 		CambiarTarea			; Si no esta en ready, me voy a idle 
	jmp		fin_tmr_hdlr
	
EjecutaT2:
	cmp 		byte [T3Runnable], 1 		; T2 es solidaria y si T3 quiere correr (Ready) le pasa la bocha
	mov		ax, TASK3
	je 		CambiarTarea
	cmp 		byte [T1Runnable], 1 		; T2 es solidaria y si T1 quiere correr (Ready) le pasa la bocha
	mov		ax, TASK1
	je 		CambiarTarea
	cmp		byte [T2Runnable], 1		; T2 esta ready?
	mov 		ax, TASKIDLE
	jne 		CambiarTarea			; Si no esta en ready, me voy a idle 
	jmp		fin_tmr_hdlr
	
EjecutaT3:
	cmp 		byte [T1Runnable], 1 		; T3 es solidaria y si T1 quiere correr (Ready) le pasa la bocha
	mov		ax, TASK1
	je 		CambiarTarea
	cmp 		byte [T2Runnable], 1 		; T3 es solidaria y si T2 quiere correr (Ready) le pasa la bocha
	mov		ax, TASK2
	je 		CambiarTarea
	cmp		byte [T3Runnable], 1		; T3 esta ready?
	mov 		ax, TASKIDLE
	jne 		CambiarTarea			; Si no esta en ready, me voy a idle 
	jmp		fin_tmr_hdlr
CambiarTarea:
	mov		[CurrentTask],ax		; Cambio la tarea actual por la nueva
	
	mov		ebx,0
	mov		bl, [CurrentTask]
	mov		eax, dword[ContextsList+ebx*4]	; Coloco EAX apuntando al contexto de la tarea nueva
	
	mov		ebx,[eax+CONTEXT_CR3]
	mov		cr3,ebx				; Cargo CR3 de la tarea nueva
	
	mov		bx,[eax+CONTEXT_GS]
	mov		gs,bx				; Cargo GS de la tarea nueva
	
	mov		bx,[eax+CONTEXT_FS]
	mov		fs,bx				; Cargo FS de la tarea nueva	
	
	mov		bx,[eax+CONTEXT_ES]
	mov		es,bx				; Cargo ES de la tarea nueva
	
	mov		bx,[eax+CONTEXT_DS]
	mov		ds,bx				; Cargo DS de la tarea nueva
	
	mov		esp, [eax +CONTEXT_ESP0]	; Cargo ESP0 de la tarea nueva
	mov		ebx, [eax+CONTEXT_STACK0]
	mov		dword [TSS_INIT+4], ebx		; Cargo STACK0 de la tarea nueva en la TSS
	
	mov		ebx,[eax+CONTEXT_ACCESS]	; Es la primera vez que va a correr la tarea?
	cmp		ebx,0
	je		first_time			; Si, salto. No, sigo
	
	popad                     			; Restaurar los registros de uso general.
	pop 		es                    		; Restaurar el registro ES.
	pop 		ds                    		; Restaurar el registro DS.                    
	iret                      			; Volver al codigo principal de la tarea.
	
first_time:
	mov		dword[eax+CONTEXT_ACCESS], 1	; Coloco a la tarea como ya ejecutada al menos una vez
	mov		ebx,[eax+CONTEXT_ESP3]		; Cargo ESP3 de la tarea nueva
	mov		ecx,[eax+CONTEXT_CS]		; Cargo CS de la tarea nueva
	mov		edx,[eax+CONTEXT_EIP]		; Cargo direccion de inicio de la tarea nueva
	
	push		ds				; Cargo DS de la tarea nueva en la pila
	push		ebx				; Cargo ESP3 de la tarea nueva en la pila
	push		200h				; Cargo EFLAGS de la tarea nueva en la pila
	push		ecx				; Cargo CS de la tarea nueva en la pila
	push		edx				; Cargo direccion de inicio de la tarea nueva en la pila
	
	mov		ebp, 0				; Cargo ebp de la tarea nueva
	mov		edi, 0				; Cargo edi de la tarea nueva
	mov		esi, 0				; Cargo esi de la tarea nueva
	mov		edx, 0				; Cargo edx de la tarea nueva
	mov		ecx, 0				; Cargo ecx de la tarea nueva
	mov		ebx, 0				; Cargo ebx de la tarea nueva
	mov		eax, 0				; Cargo eax de la tarea nueva
	
	iret
	
fin_tmr_hdlr:
	popad                     			;Restaurar los registros de uso general.
	pop 		es                    		;Restaurar el registro ES.
	pop 		ds                    		;Restaurar el registro DS.                    
	iret                      			;Volver al codigo principal de la tarea.  

;*********************** Handler de Teclado ****************************
	
key_int33_handler:					; Rutina de atencion de interrupcion de teclado
	push	ds
	pushad
	mov 	ax, DS_SEL_KER
	mov 	ds, ax
	in	al,0x60					; Leo el puerto (Requerimiento de Bochs, sino vuelve a entrar)
	cmp	al, 0x3B				; tecla "F1" downcode
	je	F1_on
	cmp	al, 0x3C				; tecla "F2" downcode
	je	F2_on
	cmp	al, 0x3D				; tecla "F3" downcode
	je	F3_on
	cmp	al, 0x3E				; tecla "F4" downcode
	je	F4_on
	cmp	al, 0x3F				; tecla "F5" downcode
	je	F5_on		
	cmp	byte [Task3State], 0			; T3 esta blocked?
	je	key_fin					; Si esta blocked, me voy
	cmp	byte [Task3State], 2			; T3 esta sleeped? 
	je	continue				; Si duerme leo teclado para cuando despierte
	cmp	byte [T3Runnable], 0			; T3 esta para correr?
	je	key_fin					; Si no esta lista me voy
continue:
	cmp	al,0x2A					; tecla "shift izquierdo" downcode
	je	shift_on				; Si toque shift salto
	cmp	al,0xAA					; tecla "shift izquierdo" breakcode
	je	shift_off				; Si solte shift salto
	cmp	al,0x39					; maximo scancode valido
	ja	key_fin					; si es mayor me voy
	mov	ebx,scankeyfifo
	add	ebx,[counter]
	mov	[ebx],al				; Cargo en scankeyfifo el scancode de la tecla presionada
	add	[counter],byte 1			; incremento indice
	mov	al,[counter]
	cmp	al,10					; chequeo si llego al maximo
	jb	key_fin	
	mov	[counter],byte 0			; vuelvo el indice a 0
	jmp	key_fin
	
shift_on:
	mov	[shiftflag],byte 1			; Pongo flag de tecla shift pulsada en 1
	jmp	key_fin
	
shift_off:
	mov	[shiftflag],byte 0			; Pongo flag de tecla shift pulsada en 0
	jmp	key_fin
	
F1_on:
	cmp	byte [Task1State], 0			; Paso la tarea 1 de ready a blocked y viceversa
	je	readytask1
	mov	byte [Task1State], 0
	jmp 	key_fin
readytask1:	
	mov	byte [Task1State], 1
	jmp 	key_fin

F2_on:  
	cmp	byte [Task2State], 0			; Paso la tarea 2 de ready a blocked y viceversa
	je	readytask2
	mov	byte [Task2State], 0
	jmp 	key_fin
readytask2:	
	mov	byte [Task2State], 1
	jmp 	key_fin
	
F3_on:  
	cmp	byte [Task3State], 0			; Paso la tarea 3 de ready a blocked y viceversa
	je	readytask3
	mov	byte [Task3State], 0
	jmp 	key_fin
readytask3:	
	mov	byte [Task3State], 1
	jmp 	key_fin
	
F4_on:
	mov	byte [Task1Priority], 2			; Coloco todas las prioridades de las tareas en 2
	mov	byte [Task2Priority], 2
	mov	byte [Task3Priority], 2
	jmp	key_fin

F5_on:
	mov	byte [Task1Priority], 4			; Vuelvo a las prioridades originales de las tareas
	mov	byte [Task2Priority], 2
	mov	byte [Task3Priority], 3
	jmp	key_fin
	
key_fin:
	mov 	al,0x20					; PIC (END OF INTERRUPT) EOI
	out 	0x20,al
	popad
	pop 	ds
	iret						; Vuelvo al programa principal
	
;************************ DIVIDE ERROR EXCEPTION 0 HANDLER ************************
	
div_error_excep0_handler:	
	;xchg	bx,bx					; Para saber que excepcion ocurrio
	mov	ebx,eax
	;call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	4					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler0				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
	mov	eax,ebx
	mov	ecx,10					; Salvo division por cero
	iret
;exc0_fin:	
;	hlt
;	jmp 	exc0_fin
	
;************************ DEBUG EXCEPTION 1 HANDLER ************************
	
debug_excep1_handler:	
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler1				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc1_fin:	
	hlt
	jmp 	exc1_fin
	
;************************ BREAKPOINT EXCEPTION 3 HANDLER ************************
	
breakpoint_excep3_handler:	
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler3				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc3_fin:	
	hlt
	jmp 	exc3_fin
	
;************************ OVERFLOW EXCEPTION 4 HANDLER ************************
	
overflow_excep4_handler:	
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler4				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc4_fin:	
	hlt
	jmp 	exc4_fin
	
;************************ BOUND RANGE EXCEPTION 5 HANDLER ************************
	
bound_range_excep5_handler:	
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler5				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc5_fin:	
	hlt
	jmp 	exc5_fin
	
;******************** UNDEFINED OPCODE EXCEPTION 6 HANDLER ************************
	
undef_opcode_excep6_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler6				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc6_fin:	
	hlt
	jmp 	exc6_fin

;**************** DEVICE NOT AVAILABLE EXCEPTION 7 HANDLER ************************
	
dev_not_avail_excep7_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler7				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc7_fin:	
	hlt
	jmp 	exc7_fin
	
;********************* DOUBLE FAULT EXCEPTION 8 HANDLER ***************************
	
double_fault_excep8_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler8				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc8_fin:	
	hlt
	jmp 	exc8_fin
	
;********************* INVALID TSS EXCEPTION 10 HANDLER ***************************
	
invalid_tss_excep10_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler10				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc10_fin:	
	hlt
	jmp 	exc10_fin
	
;***************** SEGMENT NOT PRESENT EXCEPTION 11 HANDLER ***********************
	
segm_not_pres_excep11_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler11				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc11_fin:	
	hlt
	jmp 	exc11_fin
	
;***************** STACK-SEGMENT FAULT EXCEPTION 12 HANDLER ***********************
	
stack_segment_excep12_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler12				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc12_fin:	
	hlt
	jmp 	exc12_fin

;***************** GENERAL PROTECTION EXCEPTION 13 HANDLER ***********************
	
gen_prot_excep13_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler13				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros	
exc13_fin:	
	hlt
	jmp 	exc13_fin
	
;********************** PAGE FAULT EXCEPTION 14 HANDLER **************************
	
page_fault_excep14_handler:
	;xchg	bx,bx
	cli
	pop	ebx					; Cargo error code
	and	ebx,0x00000001				; Enmascaro bit de error presencia (Pagina no presente)
	cmp	ebx,0					; Chequeo bit de error de presencia (P flag == 0 -> error) 
	jne	finhdlr					; Si esta no es la fuente de error, salgo del Handler
	pushad						; Resguardo registros
	;call	krn_clear_screen			; Borro pantalla
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	6					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler14				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros	
	
;------------------------ PAGINACION DE PAGINA FALTANTE --------------------------
	
	mov	ebx,cr2					; Leo CR2 y chequeo en que dirección ocurrio #PF. La cargo en ebx. Direccion a paginar
	mov	ecx,ebx					; Cargo ecx con direccion lineal de error
	mov	edx,ecx					; Cargo ecx con direccion lineal de error
	shr	edx,30
	and	edx,0x00000003				; Tengo en edx numero de descriptor de la pdpte (offset dentro de la PDPTE)
	shr	ebx,21
	and	ebx,0x000001FF				; Tengo en ebx numero de descriptor del directorio de paginas (offset dentro de DP)
	shr	ecx,12
	and	ecx,0x000001FF				; Tengo en ecx numero de descriptor de la tabla de paginas (offset dentro de TP)
	shl	edx,3					; Multiplico por 8 (8 bytes - 64 bits)
	mov	[pdptedesc],edx				; Salvo Numero de Descriptor (en bytes) de PDPTE
	shl	ebx,3					; Multiplico por 8 (8 bytes - 64 bits)
	mov	[dpdesc],ebx				; Salvo Numero de Descriptor (en bytes) de DP
	shl	ecx,3					; Multiplico por 8 (8 bytes - 64 bits)
	mov	[tpdesc],ecx				; Salvo Numero de Descriptor (en bytes) de TP				
	mov	eax,cr3					; Cargo PDPTE - Estoy parado en el inicio de la PDPTE
	add	eax,[pdptedesc]				; Estoy parado en el descriptor correspondiente de la PDPTE
	mov	ebx,[eax]				; Cargo el contenido del descriptor de la PDPTE
	and	ebx,0x00000001					
	cmp	ebx,1					; Chequeo a ver si dicho DP esta creado
	jne	dpnotcreated				; Salto si esta NO PRESENTE	
sigue1:	
	mov	eax,[eax]				; Cargo direccion de DP - Estoy parado al inicio de la DP
	and	eax,0xFFFFF000
	add	eax,[dpdesc]				; Estoy parado en el descriptor correspondiente de la DP
	mov	ebx,[eax]				; Cargo el contenido del descriptor de la DP
	and	ebx,0x00000001					
	cmp	ebx,1					; Chequeo a ver si la tabla de paginas esta creada
	jne	ptnotcreated				; Salto si esta NO PRESENTE
sigue2:	
	mov	eax,[eax]				; Cargo direccion de TP - Estoy parado al inicio de la TP
	and	eax,0xFFFFF000
	add	eax,[tpdesc]				; Estoy parado en el descriptor correspondiente de la TP
	mov	ebx,[pagepointer]			; Cargo puntero de pagina nueva
	add	ebx,7					; + Atributos de pagina
	mov	[eax],ebx				; Completo el descriptor de Page Table con la nueva pagina
	mov	eax,[pagepointer]			; Incremento pagepointer
	add	eax,0x1000
	mov	[pagepointer],eax
	
finhdlr:	
	mov	eax,cr3    				; Recargo cr3 (para forzar actualizacion de la TLB)
	mov	cr3,eax	
	popad
	sti
	iret	
	
exc14_fin:	
	hlt
	jmp 	exc14_fin
	
ptnotcreated:
	mov	ebx,[tablepointer]			; Cargo puntero de tabla nueva
	add	ebx,7					; + Atributos de tabla de paginas
	mov	[eax],ebx				; Completo descriptor de la DP (Nueva tabla de pagina)
	mov	ebx,[tablepointer]			; Incremento tablepointer
	add	ebx,0x1000
	cmp	ebx,MAX_TABLES				; Veo si llegue al limite de espacio de tablas
	jae	exc14_fin
	mov	[tablepointer],ebx	
	jmp	sigue2
	
dpnotcreated:
	mov	ebx,[tablepointer]			; Cargo puntero de tabla nueva
	add	ebx,1					; + Atributos de DP
	mov	[eax],ebx				; Completo descriptor de la PDPTE (Nuevo DP)
	mov	ebx,[tablepointer]			; Incremento tablepointer
	add	ebx,0x1000
	cmp	ebx,MAX_TABLES				; Veo si llegue al limite de espacio de tablas
	jae	exc14_fin
	mov	[tablepointer],ebx	
	jmp	sigue1
	
;************ FPU FLOATING POINT ERROR EXCEPTION 16 HANDLER **********************
	
float_error_excep16_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler16				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc16_fin:	
	hlt
	jmp 	exc16_fin
	
;******************** ALIGNMENT CHECK EXCEPTION 17 HANDLER ************************
	
align_check_excep17_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler17				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc17_fin:	
	hlt
	jmp 	exc17_fin
	
;********************* MACHINE CHECK EXCEPTION 18 HANDLER **************************
	
machine_check_excep18_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler18				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc18_fin:	
	hlt
	jmp 	exc18_fin
	
;***************** SIMD FLOATING POINT EXCEPTION 19 HANDLER ***********************
	
simd_float_excep19_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler19				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc19_fin:	
	hlt
	jmp 	exc19_fin
	
;******************** VIRTUALIZATION EXCEPTION 20 HANDLER ************************
	
virtual_excep20_handler:
	xchg	bx,bx					; Para saber que excepcion ocurrio
	call	krn_clear_screen
	push 	WHITE_F | BLACK_B			; Atributos: Color
	push	0					; Y=0 (FILA)
	push	0					; X=0 (COLUMNA)
	push 	msgHandler20				; Mensaje
	call 	krn_print_screen			; Imprime en pantalla. ABI32.
	add	esp, 16					; Limpio stack de parametros
exc20_fin:	
	hlt
	jmp 	exc20_fin

;************************** CALL GATE 0: SERVICES ********************************

Services:
	mov	eax,[esp+12]				; Cargo numero de servicio requerido
	cmp	eax,MAX_SERV
	ja	cg_end
	mov	ecx,[esp+8]				; Cargo puntero a estructura de parametros
	call	dword[Handlers+eax*4]			; Llamo a la subrutina correspondiente al servicio solicitado
cg_end:
	retf	8		; Fin de nuestros servicios. 4*cantidad de parametros, esto balancea la pila, si no esta bien, GP y Buenas Noches	

;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet								c2015
;********************************************************************************