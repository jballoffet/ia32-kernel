;################################################################################
;#	Título: Tablas de sistema						#
;#										#
;#	Versión:	1.0			Fecha: 	06/09/2015		#
;#	Autor: 		Javier Balloffet	Tab: 	4			#
;#	Compilación:								#
;#			Usar Makefile						#
;#	Uso: 			-						#
;#	------------------------------------------------------------------------#
;#	Descripción:								#
;#		* GDT con Segmentos de Codigo y Datos				#
;#		* IDT con Excepciones e Interrupciones				#
;#	------------------------------------------------------------------------#
;#	Revisiones:								#
;#		1.0 | 06/09/2015 | J.BALLOFFET | Inicial			#
;#	------------------------------------------------------------------------#
;#	TODO:									#
;#		-								#
;################################################################################

USE32

;********************************************************************************
; Macros
;********************************************************************************

%define		INIT_STACK	0x00140000		; Direccion fisica para la pila
%define		T1_STACK_0	0x00141000		; Direccion fisica para la pila
%define		T1_STACK_3	0x00A09000		; Direccion fisica para la pila
%define		T2_STACK_0	0x00142000		; Direccion fisica para la pila
%define		T2_STACK_3	0x00A19000		; Direccion fisica para la pila
%define		T3_STACK_0	0x00143000		; Direccion fisica para la pila
%define		T3_STACK_3	0x00A29000		; Direccion fisica para la pila
%define 	STACK_SIZE	1024			; 1kB

%define		PDPTE_1		PDPTE+0x12000		; Estructuras iniciales de Paginacion de Tarea 1
%define		PDPTE_2		PDPTE_1+0x9000		; Estructuras iniciales de Paginacion de Tarea 2
%define		PDPTE_3		PDPTE_2+0x9000		; Estructuras iniciales de Paginacion de Tarea 3

;********************************************************************************
; Simbolos externos y globales
;********************************************************************************

GLOBAL		GDT
GLOBAL		CS_SEL_KER
GLOBAL		CS_SEL_USR
GLOBAL		DS_SEL_KER
GLOBAL		DS_SEL_USR
GLOBAL		TSS_INIT_SEL
GLOBAL		CG_SEL
GLOBAL		GDTR

GLOBAL		IDT
GLOBAL		IDTR

GLOBAL		PDPTE

GLOBAL		TSS_INIT

GLOBAL		Task1State
GLOBAL		Task2State
GLOBAL		Task3State
GLOBAL		Task1Priority
GLOBAL		Task2Priority
GLOBAL		Task3Priority
GLOBAL		selector_nueva_tarea
GLOBAL		nueva_tarea

GLOBAL		CONTEXT_INIT
GLOBAL		CONTEXT_T1
GLOBAL		CONTEXT_T2
GLOBAL		CONTEXT_T3

GLOBAL		CurrentTask
GLOBAL		ContextsList

EXTERN		Inicio_T1
EXTERN		Inicio_T2
EXTERN		Inicio_T3

;********************************************************************************
; Tablas de sistema
;********************************************************************************

SECTION		.sys_tables 	progbits
ALIGN 4									; Como no se si la memoria viene desalineada, por las dudas la alineo

;--------------------------------------------------------------------------------
; GDT
;--------------------------------------------------------------------------------
GDT:									; Inicio de la GDT
NULL_SEL	equ	$-GDT						; Creo el DESCRIPTOR NULL
	dq	0x0

CS_SEL_KER  	equ 	$-GDT						; Creo el DESCRIPTOR DE CODIGO DE KERNEL
	dw 	0xFFFF 							; Limite 0-15
	dw 	0x0000							; Base 0-15
	db 	0x00							; Base 16-23
	db 	0x9A							; P = 1 DPL = 00 S = 1 TIPO = 101 A = 0 (10011010b)
	db 	0xCF							; G = 1 D/B = 1 AVL= 0 LIMITE = 1111 (Limite 16-19) (11011111b)
	db 	0							; Base 24-31
		
CS_SEL_USR  	equ 	$-GDT						; Creo el DESCRIPTOR DE CODIGO DE USUARIO
	dw 	0xFFFF 							; Limite 0-15
	dw 	0x0000							; Base 0-15
	db 	0x00							; Base 16-23
	db 	0xFA							; P = 1 DPL = 11 S = 1 TIPO = 101 A = 0 (11111010b)
	db 	0xCF							; G = 1 D/B = 1 AVL= 0 LIMITE = 1111 (Limite 16-19) (11011111b)
	db 	0							; Base 24-31
	
DS_SEL_KER  	equ 	$-GDT						; Creo el DESCRIPTOR DE DATOS DE KERNEL
	dw 	0xFFFF							; Limite 0-15
	dw 	0x0000							; Base 0-15
	db 	0x00							; Base 16-23
	db 	0x92							; P = 1 DPL = 00 S = 1 TIPO = 001 A = 0 (10010010b)
	db 	0xCF							; G = 1 D/B = 1 AVL=0 LIMITE= 1111 (Limite 16-19) (11011111b) 
	db 	0							; Base 24-31

DS_SEL_USR 	equ 	$-GDT						; Creo el DESCRIPTOR DE DATOS DE USUARIO
	dw 	0xFFFF 							; Limite 0-15
	dw 	0x0000							; Base 0-15
	db 	0x00							; Base 16-23
	db 	0xF2							; P = 1 DPL = 11 S = 1 TIPO = 001 A = 0 (11110010b)
	db 	0xCF							; G = 1 D/B = 1 AVL=0 LIMITE= 1111 (Limite 16-19) (11011111b)
	db 	0							; Base 24-31
	
TSS_INIT_SEL 	equ 	$-GDT						; Creo el DESCRIPTOR DE TSS DE INICIO
	dw	104-1
	dw	0
	db	0
	db	89h							; Compuerta de tarea: ocupada (8B) - Compuerta de interrupcion: desocupada (89) 
	dw	0
	
CG_SEL		equ 	$-GDT						; Creo el DESCRIPTOR DE CALLGATE
	dw	0		
	dw	CS_SEL_KER
	db	2							; Cantidad de parametros de 32 bits a copiarse entre pilas
	db	0ECh
	dw	0
	
GDT_LENGTH 	equ 	$-GDT						; Calculo Tamanio de la GDT

GDTR:									; Creo GDTR (Puntero a GDT)
	dw 	GDT_LENGTH-1						; Tamanio (Size)
	dd 	GDT							; Direccion
	
;--------------------------------------------------------------------------------
; IDT
;--------------------------------------------------------------------------------
IDT:									; Inicio de la IDT - EXCEPCIONES - Total de descriptores = 32  
DESCR_DE:								; Excepcion 0: Divide Error (#DE)    
	dw 	0							; div_error_excep0_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0

DESCR_DB:								; Excepcion 1: Debug Exception (#DB)    
	dw 	0							; debug_excep1_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
	times 1 dd 0,0      						; NMI Interrupt (2)
	
DESCR_BP:								; Excepcion 3: Breakpoint (#BP)    
	dw 	0							; breakpoint_excep3_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0

DESCR_OF:								; Excepcion 4: Overflow (#OF)    
	dw 	0							; overflow_excep4_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_BR:								; Excepcion 5: Bound Range Exceeded (#BR)    
	dw 	0							; bound_range_excep5_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_UD:								; Excepcion 6: Undefined Opcode (#UD)
	dw 	0							; undef_opcode_excep6_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_NM:								; Excepcion 7: Device Not Available (#NM)
	dw 	0							; dev_not_avail_excep7_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_DF:								; Excepcion 8: Double Fault (#DF)
	dw 	0							; double_fault_excep8_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
	times 1 dd 0,0      						; Coprocessor Segment Overrun (9)
	
DESCR_TS:								; Excepcion 10: Invalid TSS (#TS)
	dw 	0							; invalid_tss_excep10_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_NP:								; Excepcion 11: Segment Not Present (#NP)
	dw 	0							; segm_not_pres_excep11_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_SS:								; Excepcion 12: Stack-Segment Fault (#SS)
	dw 	0							; stack_segment_excep12_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_GP:								; Excepcion 13: General Protection (#GP)
	dw 	0							; gen_prot_excep13_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0

DESCR_PF:								; Excepcion 14: Page Fault (#PF)
	dw 	0							; page_fault_excep14_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0

	times 1 dd 0,0							; Intel Reserved. Do not use (15)

DESCR_MF:								; Excepcion 16: FPU Floating-Point Error (#MF)
	dw 	0							; float_error_excep16_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_AC:								; Excepcion 17: Alignment Check (#AC)
	dw 	0							; align_check_excep17_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_MC:								; Excepcion 18: Machine Check (#MC)
	dw 	0							; machine_check_excep18_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_XM:								; Excepcion 19: SIMD Floating-Point Exception (#XM)
	dw 	0							; simd_float_excep19_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0
	
DESCR_VE:								; Excepcion 20: Virtualization Exception (#VE)
	dw 	0							; virtual_excep20_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8F
	dw 	0	

	times 11 dd 0,0    						; Intel Reserved. Do not use (21-31)
	
DESCR_TMR:								; Interrupcion 32: Timer
	dw	0							; tmr_int32_handler - IRQ 0
	dw	CS_SEL_KER
	db	0
	db	0x8E							; Por compuerta de interrupcion
	dw	0

DESCR_KEY:								; Interrupcion 33: Keyboard
	dw 	0							; key_int33_handler
	dw 	CS_SEL_KER
	db 	0
	db 	0x8E							; Por compuerta de interrupcion
	dw 	0
	
IDT_LENGTH	equ 	$-IDT						; Calculo Tamanio de la IDT

IDTR:									; Creo IDTR (Puntero a IDT)
	dw 	IDT_LENGTH-1						; Tamanio (Size)
	dd 	IDT							; Direccion

;--------------------------------------------------------------------------------
; TSS
;--------------------------------------------------------------------------------
TSS_INIT:								; TSS DE INCIO
	times 104 db 0
  
CONTEXT_INIT:
	dd INIT_STACK + STACK_SIZE					; Offset 0x00: Imagen ESP0 (PL=0)
	dd DS_SEL_KER							; Offset 0x04: Imagen selector SS0 (PL=0)
	dd PDPTE							; Offset 0x08: Imagen CR3
	dd 0								; Offset 0x0C: Imagen EIP
	dd 0								; Offset 0x10: Imagen ESP3 (PL=3)
	dd DS_SEL_KER							; Offset 0x14: Imagen ES
	dd CS_SEL_KER							; Offset 0x18: Imagen CS
	dd 0								; Offset 0x1C: Imagen selector SS3 (PL=3)
	dd DS_SEL_KER							; Offset 0x20: Imagen DS
	dd DS_SEL_KER							; Offset 0x24: Imagen FS
	dd DS_SEL_KER							; Offset 0x28: Imagen GS
	dd 1								; Offset 0x2C: Accessed bit
	dd INIT_STACK + STACK_SIZE					; Offset 0x30: Stack 0 Init
	
CONTEXT_T1:
	dd T1_STACK_0 + STACK_SIZE					; Offset 0x00: Imagen ESP0 (PL=0)
	dd DS_SEL_KER							; Offset 0x04: Imagen selector SS0 (PL=0)
	dd PDPTE_1							; Offset 0x08: Imagen CR3
	dd Inicio_T1							; Offset 0x0C: Imagen EIP (comienzo)
	dd T1_STACK_3 + STACK_SIZE					; Offset 0x10: Imagen ESP3 (PL=3)
	dd DS_SEL_USR + 3						; Offset 0x14: Imagen ES
	dd CS_SEL_USR + 3						; Offset 0x18: Imagen CS
	dd DS_SEL_USR + 3						; Offset 0x1C: Imagen selector SS3 (PL=3)
	dd DS_SEL_USR + 3						; Offset 0x20: Imagen DS
	dd DS_SEL_USR + 3						; Offset 0x24: Imagen FS
	dd DS_SEL_USR + 3						; Offset 0x28: Imagen GS
	dd 0								; Offset 0x2C: Accessed bit
	dd T1_STACK_0 + STACK_SIZE					; Offset 0x30: Stack 0 Init
	
CONTEXT_T2:
	dd T2_STACK_0 + STACK_SIZE					; Offset 0x00: Imagen ESP0 (PL=0)
	dd DS_SEL_KER							; Offset 0x04: Imagen selector SS0 (PL=0)
	dd PDPTE_2							; Offset 0x08: Imagen CR3
	dd Inicio_T2							; Offset 0x0C: Imagen EIP (comienzo)
	dd T2_STACK_3 + STACK_SIZE					; Offset 0x10: Imagen ESP3 (PL=3)
	dd DS_SEL_USR + 3						; Offset 0x14: Imagen ES
	dd CS_SEL_USR + 3						; Offset 0x18: Imagen CS
	dd DS_SEL_USR + 3						; Offset 0x1C: Imagen selector SS3 (PL=3)
	dd DS_SEL_USR + 3						; Offset 0x20: Imagen DS
	dd DS_SEL_USR + 3						; Offset 0x24: Imagen FS
	dd DS_SEL_USR + 3						; Offset 0x28: Imagen GS
	dd 0								; Offset 0x2C: Accessed bit
	dd T2_STACK_0 + STACK_SIZE					; Offset 0x30: Stack 0 Init
	
CONTEXT_T3:
	dd T3_STACK_0 + STACK_SIZE					; Offset 0x00: Imagen ESP0 (PL=0)
	dd DS_SEL_KER							; Offset 0x04: Imagen selector SS0 (PL=0)
	dd PDPTE_3							; Offset 0x08: Imagen CR3
	dd Inicio_T3							; Offset 0x0C: Imagen EIP (comienzo)
	dd T3_STACK_3 + STACK_SIZE					; Offset 0x10: Imagen ESP3 (PL=3)
	dd DS_SEL_USR + 3						; Offset 0x14: Imagen ES
	dd CS_SEL_USR + 3						; Offset 0x18: Imagen CS
	dd DS_SEL_USR + 3						; Offset 0x1C: Imagen selector SS3 (PL=3)
	dd DS_SEL_USR + 3						; Offset 0x20: Imagen DS
	dd DS_SEL_USR + 3						; Offset 0x24: Imagen FS
	dd DS_SEL_USR + 3						; Offset 0x28: Imagen GS
	dd 0								; Offset 0x2C: Accessed bit
	dd T3_STACK_0 + STACK_SIZE					; Offset 0x30: Stack 0 Init
	
CurrentTask		dd 0						; Tarea en ejecucion

ContextsList:								; Vector con los contextos
	dd CONTEXT_INIT
	dd CONTEXT_T1
	dd CONTEXT_T2
	dd CONTEXT_T3

Task1State		db 0						; Estado de la tarea1 (0=Blocked, 1=Ready, 2=Sleeping)
Task2State		db 0						; Estado de la tarea2 (0=Blocked, 1=Ready, 2=Sleeping)
Task3State		db 0						; Estado de la tarea3 (0=Blocked, 1=Ready, 2=Sleeping)

Task1Priority		db 4						; Nivel de prioridad de la tarea1
Task2Priority		db 2						; Nivel de prioridad de la tarea2
Task3Priority		db 3						; Nivel de prioridad de la tarea3

nueva_tarea		dd 0                				; Salto indirecto para cambiar de tarea.
selector_nueva_tarea	dw 0

;--------------------------------------------------------------------------------
; PAGINACION
;--------------------------------------------------------------------------------
ALIGN	4096

PDPTE:									; Inicio de las tablas de paginacion
	times 4 dq 0,0

;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet								c2015
;********************************************************************************
