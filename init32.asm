;########################################################################################
;#	Título: Modulo de inicializacion en 32 bits					#
;#											#
;#	Versión:	1.0				Fecha: 	06/09/2015		#
;#	Autor: 		J. Balloffet			Tab: 	4			#
;#	Compilación:	Usar Makefile							#
;#	Uso: 			-							#
;#	------------------------------------------------------------------------	#
;#	Descripción:									#
;#		Inicializacion de un sistema basico desde BIOS				#
;#		Genera una BIOS ROM de 64kB para inicializacion y codigo principal	#
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

%define		INIT_STACK	0x00140000		; Direccion fisica para la pila
%define		T1_STACK_0	0x00141000		; Direccion fisica para la pila
%define		T1_STACK_3	0x00A09000		; Direccion fisica para la pila
%define		T2_STACK_0	0x00142000		; Direccion fisica para la pila
%define		T2_STACK_3	0x00A19000		; Direccion fisica para la pila
%define		T3_STACK_0	0x00143000		; Direccion fisica para la pila
%define		T3_STACK_3	0x00A29000		; Direccion fisica para la pila
%define 	STACK_SIZE	1024			; 1kB

%define		tables_start	0x00100000		; Direccion fisica de .tables
%define		stack_start	0x00140000		; Direccion fisica del stack
%define		main_start	0x00150000		; Direccion fisica de .main
%define		data_start	0x00200000		; Direccion fisica de .data
%define		bss_start	0x00210000		; Direccion fisica de .bss
%define		lib_start	0x00220000		; Direccion fisica de .lib
%define		other_start	0x00250000		; Direccion fisica de .other
%define		shared_start	0x00300000		; Direccion fisica de .shared
%define		t1_main_start	0x00A00000		; Direccion fisica de .t1_main
%define		t1_data_start	0x00A08000		; Direccion fisica de .t1_data
%define		t2_main_start	0x00A10000		; Direccion fisica de .t2_main
%define		t2_data_start	0x00A18000		; Direccion fisica de .t2_data
%define		t3_main_start	0x00A20000		; Direccion fisica de .t3_main
%define		t3_data_start	0x00A28000		; Direccion fisica de .t3_data

%define		DP1		PDPTE+0x1000		; Estructuras iniciales de Paginacion de Idle
%define		TP1		DP1+0x1000
%define		TP2		DP1+0x2000
%define		TP6		DP1+0x3000

%define		PDPTE_1		PDPTE+0x12000		; Estructuras iniciales de Paginacion de Tarea 1
%define		DP1_1		PDPTE_1+0x1000
%define		TP1_1		DP1_1+0x1000
%define		TP2_1		DP1_1+0x2000
%define		TP6_1		DP1_1+0x3000

%define		PDPTE_2		PDPTE_1+0x9000		; Estructuras iniciales de Paginacion de Tarea 2
%define		DP1_2		PDPTE_2+0x1000
%define		TP1_2		DP1_2+0x1000
%define		TP2_2		DP1_2+0x2000
%define		TP6_2		DP1_2+0x3000

%define		PDPTE_3		PDPTE_2+0x9000		; Estructuras iniciales de Paginacion de Tarea 3
%define		DP1_3		PDPTE_3+0x1000
%define		TP1_3		DP1_3+0x1000
%define		TP2_3		DP1_3+0x2000
%define		TP6_3		DP1_3+0x3000

;********************************************************************************
; Simbolos externos y globales
;********************************************************************************

GLOBAL 		Entry

EXTERN		__sys_tables_LMA			; definidos en linker.lds
EXTERN		__sys_tables_start
EXTERN		__sys_tables_end
EXTERN		__main_LMA
EXTERN		__main_start
EXTERN		__main_end
EXTERN		__mdata_LMA
EXTERN		__mdata_start
EXTERN		__mdata_end
EXTERN		__bss_start
EXTERN		__bss_end
EXTERN		__lib_LMA
EXTERN		__lib_start
EXTERN		__lib_end
EXTERN		__other_LMA
EXTERN		__other_start
EXTERN		__other_end
EXTERN		__shared_LMA
EXTERN		__shared_start
EXTERN		__shared_end
EXTERN		__t1_main_LMA
EXTERN		__t1_main_start
EXTERN		__t1_main_end
EXTERN		__t1_data_LMA
EXTERN		__t1_data_start
EXTERN		__t1_data_end
EXTERN		__t2_main_LMA
EXTERN		__t2_main_start
EXTERN		__t2_main_end
EXTERN		__t2_data_LMA
EXTERN		__t2_data_start
EXTERN		__t2_data_end
EXTERN		__t3_main_LMA
EXTERN		__t3_main_start
EXTERN		__t3_main_end
EXTERN		__t3_data_LMA
EXTERN		__t3_data_start
EXTERN		__t3_data_end

EXTERN		start32					; definido en main32.asm

EXTERN		CS_SEL_KER				; definidos en sys_tables.asm
EXTERN		DS_SEL_KER
EXTERN		CS_SEL_USR
EXTERN		DS_SEL_USR
EXTERN		GDT
EXTERN		GDTR
EXTERN		IDT
EXTERN		IDTR

EXTERN		TSS_INIT_SEL				; definidos en sys_tables.asm
EXTERN		TSS_INIT

EXTERN		CG_SEL					; definido en sys_tables.asm

EXTERN		PDPTE					; definido en sys_tables.asm
			
EXTERN		div_error_excep0_handler		; definidos en isr.asm
EXTERN		debug_excep1_handler
EXTERN 		breakpoint_excep3_handler
EXTERN		overflow_excep4_handler
EXTERN		bound_range_excep5_handler
EXTERN		undef_opcode_excep6_handler
EXTERN		dev_not_avail_excep7_handler
EXTERN		double_fault_excep8_handler
EXTERN		invalid_tss_excep10_handler
EXTERN		segm_not_pres_excep11_handler
EXTERN		stack_segment_excep12_handler
EXTERN		gen_prot_excep13_handler
EXTERN		page_fault_excep14_handler
EXTERN		float_error_excep16_handler
EXTERN		align_check_excep17_handler
EXTERN		machine_check_excep18_handler
EXTERN		simd_float_excep19_handler
EXTERN		virtual_excep20_handler
EXTERN		tmr_int32_handler
EXTERN		key_int33_handler

EXTERN		Inicio_T1				; definidos en tasks.asm
EXTERN		Inicio_T2
EXTERN		Inicio_T3

EXTERN		Services				; definido en isr.asm

EXTERN		Idle

;********************************************************************************
; Codigo de inicializacion - 16 Bits
;********************************************************************************
USE16
SECTION 	.reset_vector				; Reset vector del procesador

Entry:							; Punto de entrada definido en el linker
	jmp 	dword start				; Punto de entrada de mi BIOS
	times   16-($-Entry) db 0			; Relleno hasta el final de la ROM

;********************************************************************************
; Codigo de inicializacion - 32 Bits
;********************************************************************************
USE32
SECTION 	.init16
;--------------------------------------------------------------------------------
; Punto de entrada
;--------------------------------------------------------------------------------
start:							; Punto de entrada
	INCBIN "init16.bin"				; Binario de 16 bits

	mov 	eax,init32
	jmp	eax

SECTION		.init32
	
init32:
	;xchg bx, bx					; Magic breakpoint
							
;**********************EXPANDO A VMA******************************
							
	mov 	esi, __sys_tables_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __sys_tables_start			; Puntero a la VMA
	mov	ecx, __sys_tables_end
	sub	ecx, __sys_tables_start			; Calculo tamaño
	rep	movsb	

	mov 	esi, __main_LMA				; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __main_start			; Puntero a la VMA
	mov	ecx, __main_end	
	sub	ecx, __main_start			; Calculo tamaño
	rep	movsb	
	
	mov 	esi, __mdata_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __mdata_start			; Puntero a la VMA
	mov	ecx, __mdata_end	
	sub	ecx, __mdata_start			; Calculo tamaño
	rep	movsb	

	mov 	esi, __lib_LMA				; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __lib_start			; Puntero a la VMA
	mov	ecx, __lib_end	
	sub	ecx, __lib_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __other_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __other_start			; Puntero a la VMA
	mov	ecx, __other_end	
	sub	ecx, __other_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __shared_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __shared_start			; Puntero a la VMA
	mov	ecx, __shared_end	
	sub	ecx, __shared_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __t1_main_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __t1_main_start			; Puntero a la VMA
	mov	ecx, __t1_main_end	
	sub	ecx, __t1_main_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __t1_data_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __t1_data_start			; Puntero a la VMA
	mov	ecx, __t1_data_end	
	sub	ecx, __t1_data_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __t2_main_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __t2_main_start			; Puntero a la VMA
	mov	ecx, __t2_main_end	
	sub	ecx, __t2_main_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __t2_data_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __t2_data_start			; Puntero a la VMA
	mov	ecx, __t2_data_end	
	sub	ecx, __t2_data_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __t3_main_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __t3_main_start			; Puntero a la VMA
	mov	ecx, __t3_main_end	
	sub	ecx, __t3_main_start			; Calculo tamaño
	rep	movsb
	
	mov 	esi, __t3_data_LMA			; Puntero al inicio de la LMA, solo parte baja 
	mov 	edi, __t3_data_start			; Puntero a la VMA
	mov	ecx, __t3_data_end	
	sub	ecx, __t3_data_start			; Calculo tamaño
	rep	movsb
	
	xor	ax, ax
	mov 	edi, __bss_start			; Puntero a la VMA
	mov	ecx, __bss_end	
	sub	ecx, __bss_start			; Calculo tamaño
	rep	stosb

;*********************CARGO HANDLERS EN IDT*****************************
	
	mov	eax,tmr_int32_handler			; Cargo en la IDT handler de timer (32) (direccion de salto)
	mov	[IDT+0x20*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x20*8+6],ax			; Parte alta
	
	mov	eax,key_int33_handler			; Cargo en la IDT handler de teclado (33) (direccion de salto)
	mov	[IDT+0x21*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x21*8+6],ax			; Parte alta
	
	mov	eax,div_error_excep0_handler		; Cargo en la IDT handler de divide error (0) (direccion de salto)
	mov	[IDT+0x00*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x00*8+6],ax			; Parte alta
	
	mov	eax,debug_excep1_handler		; Cargo en la IDT handler de debug (1) (direccion de salto)
	mov	[IDT+0x01*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x01*8+6],ax			; Parte alta
	
	mov	eax,breakpoint_excep3_handler		; Cargo en la IDT handler de breakpoint (3) (direccion de salto)
	mov	[IDT+0x03*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x03*8+6],ax			; Parte alta
	
	mov	eax,overflow_excep4_handler		; Cargo en la IDT handler de overflow (4) (direccion de salto)
	mov	[IDT+0x04*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x04*8+6],ax			; Parte alta
	
	mov	eax,bound_range_excep5_handler		; Cargo en la IDT handler de bound range (5) (direccion de salto)
	mov	[IDT+0x05*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x05*8+6],ax			; Parte alta
	
	mov	eax,undef_opcode_excep6_handler		; Cargo en la IDT handler de invalid opcode (6) (direccion de salto)
	mov	[IDT+0x06*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x06*8+6],ax			; Parte alta
	
	mov	eax,dev_not_avail_excep7_handler	; Cargo en la IDT handler de device not available (7) (direccion de salto)
	mov	[IDT+0x07*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x07*8+6],ax			; Parte alta
	
	mov	eax,double_fault_excep8_handler		; Cargo en la IDT handler de double fault (8) (direccion de salto)
	mov	[IDT+0x08*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x08*8+6],ax			; Parte alta
	
	mov	eax,invalid_tss_excep10_handler		; Cargo en la IDT handler de invalid TSS (10) (direccion de salto)
	mov	[IDT+0x0A*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x0A*8+6],ax			; Parte alta
	
	mov	eax,segm_not_pres_excep11_handler	; Cargo en la IDT handler de segment not present (11) (direccion de salto)
	mov	[IDT+0x0B*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x0B*8+6],ax			; Parte alta
	
	mov	eax,stack_segment_excep12_handler	; Cargo en la IDT handler de stack-segment fault (12) (direccion de salto)
	mov	[IDT+0x0C*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x0C*8+6],ax			; Parte alta
	
	mov	eax,gen_prot_excep13_handler		; Cargo en la IDT handler de general protection (13) (direccion de salto)
	mov	[IDT+0x0D*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x0D*8+6],ax			; Parte alta
	
	mov	eax,page_fault_excep14_handler		; Cargo en la IDT handler de page fault (14) (direccion de salto)
	mov	[IDT+0x0E*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x0E*8+6],ax			; Parte alta
	
	mov	eax,float_error_excep16_handler		; Cargo en la IDT handler de FPU floating-point error (16) (direccion de salto)
	mov	[IDT+0x10*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x10*8+6],ax			; Parte alta
	
	mov	eax,align_check_excep17_handler		; Cargo en la IDT handler de alignment check (17) (direccion de salto)
	mov	[IDT+0x11*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x11*8+6],ax			; Parte alta
	
	mov	eax,machine_check_excep18_handler	; Cargo en la IDT handler de machine check (18) (direccion de salto)
	mov	[IDT+0x12*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x12*8+6],ax			; Parte alta
	
	mov	eax,simd_float_excep19_handler		; Cargo en la IDT handler de simd floating-point (19) (direccion de salto)
	mov	[IDT+0x13*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x13*8+6],ax			; Parte alta
	
	mov	eax,virtual_excep20_handler		; Cargo en la IDT handler de virtualization (20) (direccion de salto)
	mov	[IDT+0x14*8],ax				; Parte baja
	shr	eax,16
	mov	[IDT+0x14*8+6],ax			; Parte alta
	
;********************CARGO TSS EN TSS SEL EN GDT*****************************

	mov 	eax, TSS_INIT
	mov 	ebx,GDT
	add	ebx,TSS_INIT_SEL
	add	ebx,2
	mov 	[ebx],ax				;mov 	[GDT + TSS_INIT_SEL + 2], ax
	shr 	eax, 16
	add	ebx,2
	mov 	[ebx],al				;mov 	[GDT + TSS_INIT_SEL + 4], al
	add	ebx,3
	mov 	[ebx],ah				;mov 	[GDT + TSS_INIT_SEL + 7], ah
	
;***************************CARGO TSS**********************************

	mov	edi, TSS_INIT
	mov	dword [edi + 4], INIT_STACK + STACK_SIZE
	mov	dword [edi + 8], DS_SEL_KER
	mov	dword [edi + 28], PDPTE
	;mov	dword [edi + 32], Idle
	mov	dword [edi + 36], 200h
	;mov	dword [edi + 56], T1_STACK_3 + STACK_SIZE
	mov	dword [edi + 72], DS_SEL_KER
	mov	dword [edi + 76], CS_SEL_KER
	mov	dword [edi + 80], DS_SEL_KER
	mov	dword [edi + 84], DS_SEL_KER
	mov	dword [edi + 88], DS_SEL_KER
	mov	dword [edi + 92], DS_SEL_KER
	
;*************************CARGO GDT E IDT*******************************
	
	lgdt	[GDTR]					; Recargo nueva GDT
	lidt	[IDTR]					; Cargo IDT
	
;*************************INICIALIZO PILA*******************************

	mov 	ax, DS_SEL_KER
	mov 	ds, ax					; Inicializo selector de pila
	mov 	es, ax					; Inicializo selector de pila
	mov 	ss, ax					; Inicializo selector de pila
	mov 	esp, INIT_STACK + STACK_SIZE		; Inicializo la pila

;*********************CARGO SELECTOR CALL GATE**************************
	
	mov 	eax, Services	
	mov 	ebx,GDT
	add	ebx,CG_SEL
	mov 	[ebx],ax				;mov 	[GDT+CG_SEL], ax
	shr	eax, 16
	add	ebx,6
	mov 	[ebx],ax				;mov 	[GDT+CG_SEL+6], ax
	
;*********************INICIALIZO PIC Y TIMER****************************

	mov 	bx, 0x2028				; Base de los PICS
	call 	InitPIC					; Inicializo controlador de interrupciones
	call	Timer_Repr				; Inicializo timer

;***********************INICIALIZAR PAGINACION**************************

;------------------------BORRAR TABLAS DE PAGINA--------------------------

	mov     eax,PDPTE					; Cargo inicio de tablas
	mov	ebx,0
	mov	ecx,0x2400					; Pongo en cero todas las tablas de idle (200*18)
	
pageclean:
	mov	[eax],ebx					; Loop que pone todas las entradas de las tablas en 0
	add	eax,8
	loop	pageclean

;------------------------PAGINACION TAREA IDLE-----------------------------

;---------------CARGO PDPTE-------------
	
	mov	eax,PDPTE					; Cargo PDPTE
	mov	ebx,DP1+1					; Cargo inicio de DP + Atributos
	mov	[eax],ebx					; Cargo PDPTE	
	
;---------------CARGO DP1----------------

	mov	eax,DP1						; Cargo inicio de tablas
	mov	ebx,TP1+7					; Cargo inicio de TP1 + Atributos
	mov	[eax],ebx					; Cargo directorio de paginas
	add 	eax,8
	mov	ebx,TP2+7
	mov	[eax],ebx
	add	eax,8*4
	mov 	ebx,TP6+7
	mov 	[eax],ebx

;-------CARGO TABLAS DE PAGINAS----------
	
;Cargo .sys_tables 0x00100000

	mov	ebx,tables_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,tables_start+3				; Identity Mapping + Atributos de pagina (S-RW-P)
	mov	[eax],ebx
	mov	ecx,62						; Pagino 62 paginas mas para las demas tareas
tablesloop:	
	add 	eax,8
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	loop	tablesloop
	
;Cargo .stack 0x00140000
	
	mov	ebx,stack_start					; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,stack_start+3				; Identity Mapping + Atributos de pagina (S-RW-P)
	mov	[eax],ebx	
	add 	eax,8						; Pagino una pagina mas (Task 1 - Pila Nivel 0)
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	add 	eax,8						; Pagino una pagina mas (Task 2 - Pila Nivel 0)
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	add 	eax,8						; Pagino una pagina mas (Task 3 - Pila Nivel 0)
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	
;Cargo .main 0x00150000
	
	mov	ebx,main_start					; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,main_start+1				; Identity Mapping + Atributos de pagina (S-R-P)
	mov	[eax],ebx
	mov	ecx,2						; Pagino 2 paginas mas	
mainloop:	
	add 	eax,8
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	loop	mainloop
	
;Cargo .data 0x00200000
	
	mov	ebx,data_start					; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,data_start+3				; Identity Mapping + Atributos de pagina (S-RW-P)
	mov	[eax],ebx
	
;Cargo .bss 0x00210000
	
	mov	ebx,bss_start					; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,bss_start+3					; Identity Mapping + Atributos de pagina (S-RW-P)
	mov	[eax],ebx
	
;Cargo .lib 0x00220000
	
	mov	ebx,lib_start					; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,lib_start+1					; Identity Mapping + Atributos de pagina (S-R-P)
	mov	[eax],ebx
	
;Cargo .other 0x00250000
	
	mov	ebx,other_start					; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,other_start+1				; Identity Mapping + Atributos de pagina (S-R-P)
	mov	[eax],ebx
	
;Cargo VGA 0x00280000
	
	mov	ebx,VGA_RAM					; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,VGA_RAM_LMA+3				; Identity Mapping + Atributos de pagina (S-RW-P)
	mov	[eax],ebx

;Cargo .shared 0x00300000
	
	mov	ebx,shared_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1						; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,shared_start+5				; Identity Mapping + Atributos de pagina (U-R-P)
	mov	[eax],ebx
	
;------------------------PAGINACION TAREA 1-----------------------------

;---------------CARGO PDPTE_1-------------
	
	mov	eax,PDPTE_1					; Cargo PDPTE_1
	mov	ebx,DP1_1+1					; Cargo inicio de DP_1 + Atributos
	mov	[eax],ebx					; Cargo PDPTE_1	
	
;---------------CARGO DP1_1----------------

	mov	eax,DP1_1					; Cargo directorio de paginas
	mov	ebx,TP1_1+7					; Cargo inicio de TP1_1 + Atributos
	mov	[eax],ebx					; Cargo directorio de paginas
	add 	eax,8
	mov	ebx,TP2_1+7					; Cargo inicio de TP2_1 + Atributos
	mov	[eax],ebx					; Cargo directorio de paginas
	add	eax,8*4
	mov 	ebx,TP6_1+7					; Cargo inicio de TP6_1 + Atributos
	mov 	[eax],ebx					; Cargo directorio de paginas

;-------CARGO TABLAS DE PAGINAS----------

	mov     eax,TP1_1					; Cargo tabla de paginas TP1_1
	mov	ebx,TP1						; Cargo tabla de paginas TP1
	mov	ecx,0x400					; TP1 + TP2 = 2 tablas de 4KB = 2*0x1000 = 0x2000 -> 0x400(512 entradas * 2) 
	
pagecharge1:
	mov 	edx,[ebx]					; Loop que copia las tablas de paginas de Idle, ya que son iguales
	mov	[eax],edx
	add	eax,8
	add	ebx,8
	loop	pagecharge1
	
;Cargo .t1_main 0x00A00000
	
	mov	ebx,t1_main_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1_1					; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,t1_main_start+5				; Identity Mapping + Atributos de pagina (U-R-P)
	mov	[eax],ebx
	
;Cargo .t1_data 0x00A08000
	
	mov	ebx,t1_data_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1_1					; Cargo DP1_1 - Estoy parado en el inicio de la DP1_1
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,t1_data_start+7				; Identity Mapping + Atributos de pagina (U-RW-P)
	mov	[eax],ebx
	add 	eax,8						; Pagino una pagina mas (Pila Nivel 3)
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	
;------------------------PAGINACION TAREA 2-----------------------------

;---------------CARGO PDPTE_2-------------
	
	mov	eax,PDPTE_2					; Cargo PDPTE_2
	mov	ebx,DP1_2+1					; Cargo inicio de DP1_2 + Atributos
	mov	[eax],ebx					; Cargo PDPTE_2	
	
;---------------CARGO DP1_2----------------

	mov	eax,DP1_2					; Cargo directorio de paginas
	mov	ebx,TP1_2+7					; Cargo inicio de TP1_2 + Atributos (U-RW-P)
	mov	[eax],ebx					; Cargo directorio de paginas
	add 	eax,8
	mov	ebx,TP2_2+7					; Cargo inicio de TP2_2 + Atributos (U-RW-P)
	mov	[eax],ebx					; Cargo directorio de paginas
	add	eax,8*4
	mov 	ebx,TP6_2+7					; Cargo inicio de TP6_2 + Atributos (U-RW-P)
	mov 	[eax],ebx					; Cargo directorio de paginas

;-------CARGO TABLAS DE PAGINAS----------

	mov     eax,TP1_2					; Cargo tabla de paginas TP1_2
	mov	ebx,TP1						; Cargo tabla de paginas TP1
	mov	ecx,0x400					; TP1 + TP2 = 2 tablas de 4KB = 2*0x1000 = 0x2000 -> 0x400(512 entradas * 2) 
	
pagecharge2:
	mov 	edx,[ebx]					; Loop que copia las tablas de paginas de Idle, ya que son iguales
	mov	[eax],edx
	add	eax,8
	add	ebx,8
	loop	pagecharge2

;Cargo .t2_main 0x00A10000
	
	mov	ebx,t2_main_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1_2					; Cargo DP1_2 - Estoy parado en el inicio de la DP1_2
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,t2_main_start+5				; Identity Mapping + Atributos de pagina (U-R-P)
	mov	[eax],ebx
	
;Cargo .t2_data 0x00A18000
	
	mov	ebx,t2_data_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1_2					; Cargo DP - Estoy parado en el inicio de la DP
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,t2_data_start+7				; Identity Mapping + Atributos de pagina (U-RW-P)
	mov	[eax],ebx
	add 	eax,8						; Pagino una pagina mas (Pila Nivel 3)
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	
;------------------------PAGINACION TAREA 3-----------------------------

;---------------CARGO PDPTE_3-------------
	
	mov	eax,PDPTE_3					; Cargo PDPTE_3
	mov	ebx,DP1_3+1					; Cargo inicio de DP1_3 + Atributos
	mov	[eax],ebx					; Cargo PDPTE_3	
	
;---------------CARGO DP1_3----------------

	mov	eax,DP1_3					; Cargo directorio de paginas DP1_3
	mov	ebx,TP1_3+7					; Cargo inicio de TP1_3 + Atributos (U-RW-P)
	mov	[eax],ebx					; Cargo directorio de paginas
	add 	eax,8
	mov	ebx,TP2_3+7					; Cargo inicio de TP2_3 + Atributos (U-RW-P)
	mov	[eax],ebx					; Cargo directorio de paginas
	add	eax,8*4
	mov 	ebx,TP6_3+7					; Cargo inicio de TP3_3 + Atributos (U-RW-P)
	mov 	[eax],ebx					; Cargo directorio de paginas

;-------CARGO TABLAS DE PAGINAS----------

	mov     eax,TP1_3					; Cargo tabla de paginas TP1_3
	mov	ebx,TP1						; Cargo tabla de paginas TP1
	mov	ecx,0x400					; TP1 + TP2 = 2 tablas de 4KB = 2*0x1000 = 0x2000 -> 0x400(512 entradas * 2) 
	
pagecharge3:
	mov 	edx,[ebx]					; Loop que copia las tablas de paginas de Idle, ya que son iguales
	mov	[eax],edx
	add	eax,8
	add	ebx,8
	loop	pagecharge3

;Cargo .t3_main 0x00A20000
	
	mov	ebx,t3_main_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1_3					; Cargo DP1_3 - Estoy parado en el inicio de la DP1_3
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,t3_main_start+5				; Identity Mapping + Atributos de pagina (U-R-P)
	mov	[eax],ebx
	
;Cargo .t3_data 0x00A28000
	
	mov	ebx,t3_data_start				; Cargo seccion a paginar
	mov	ecx,ebx						; Cargo ecx direccion lineal de error
	shr	ebx,21
	and	ebx,0x000001FF					; Tengo en ebx numero de descriptor del directorio de paginas
	shr	ecx,12
	and	ecx,0x000001FF					; Tengo en ecx numero de descriptor de la tabla de paginas
	mov	eax,DP1_3					; Cargo DP1_3 - Estoy parado en el inicio de la DP1_3
	shl	ebx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ebx
	mov	eax,[eax]					
	and	eax,0xFFFFF000					; Estoy parado en el inicio de la Page Table que corresponde
	shl	ecx,3						; Multiplico por 8 (8 bytes - 64 bits)
	add	eax,ecx						; Estoy parado en el descriptor de la Page Table que corresponde
	mov	ebx,t3_data_start+7				; Identity Mapping + Atributos de pagina (U-RW-P)
	mov	[eax],ebx
	add 	eax,8						; Pagino una pagina mas (Pila Nivel 3)
	add 	ebx,0x1000
	mov 	[eax],ebx					; Completo el descriptor
	
;**********************SALTO INTERSEGMENTO**************************
	
	mov 	eax, start32				; VMA de entrada
	push 	dword CS_SEL_KER
	push 	eax
	retf						; Salto a main32

;*******************************************************************
; FUNCIONES
;*******************************************************************
;--------------------------------------------------------------------------------
; Inicializacion del controlador de interrupciones
; Corre la base de los tipos de interrupción de ambos PICs 8259A de la PC a los 8 tipos consecutivos a 
; partir de los valores base que recibe en BH para el PIC Nº1 y BL para el PIC Nº2.
; A su retorno las Interrupciones de ambos PICs están deshabilitadas.
;--------------------------------------------------------------------------------
InitPIC:
							; Inicialización PIC Nº1
							; ICW1
	mov	al, 11h         			; IRQs activas x flanco, cascada, y ICW4
	out     20h, al  
							; ICW2
	mov     al, bh          			; El PIC Nº1 arranca en INT tipo (BH)
	out     21h, al
							; ICW3
	mov     al, 04h         			; PIC1 Master, Slave ingresa Int.x IRQ2
	out     21h, al
							; ICW4
	mov     al, 01h         			; Modo 8086
	out     21h, al
							; Antes de inicializar el PIC Nº2, deshabilitamos 
							; las Interrupciones del PIC1
	mov     al, 0FFh
	out     21h, al
							; Ahora inicializamos el PIC Nº2
							; ICW1
	mov     al, 11h        			  	; IRQs activas x flanco,cascada, y ICW4
	out     0A0h, al  
							; ICW2
	mov    	al, bl          			; El PIC Nº2 arranca en INT tipo (BL)
	out     0A1h, al
							; ICW3
	mov     al, 02h         			; PIC2 Slave, ingresa Int x IRQ2
	out     0A1h, al
							; ICW4
	mov     al, 01h         			; Modo 8086
	out     0A1h, al
							; Enmascaramos el resto de las Interrupciones 
							; (las del PIC Nº2)
	mov     al, 0FFh
	out     0A1h, al
	ret

;--------------------------------------------------------------------------------
; Inicializacion del timer
;--------------------------------------------------------------------------------
	
Timer_Repr:
	mov 	al,00110100b 				; PROGRAMACION DEL TIMER TICK
	out 	43h,al
	mov 	ax,1193					; 1ms (1.1932 MHz * 1ms = 1193)
	out 	40h,al
	mov 	al,ah
	out 	40h,al
	ret

;********************************************************************************
; 			-  -- --- Fin de archivo --- --  -
; J. Balloffet							c2015
;********************************************************************************
