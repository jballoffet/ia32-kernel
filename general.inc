;--------------------------------------------------------------------------------
; Atributos de video
;--------------------------------------------------------------------------------
%define		RED_F		0x04
%define		GREEN_F		0x02
%define		BLUE_F		0x01
%define		RED_B		0x40
%define		GREEN_B		0x20
%define		BLUE_B		0x10
%define		BLINK		0x80
%define		INTENSE		0x08
%define		WHITE_B		0x70
%define		BLACK_F		0x00
%define		WHITE_F		0x07
%define		BLACK_B		0x00

;--------------------------------------------------------------------------------
; Comandos strings
;--------------------------------------------------------------------------------
%define 	CR		0x0D					; Carriage return
%define 	LF		0x0A					; Line feed
%define 	NULL		0x00					; Fin de strings

;--------------------------------------------------------------------------------
; Buffer de video
;--------------------------------------------------------------------------------
%define 	VGA_RAM			0x00280000			; VMA
%define 	VGA_RAM_LMA		0xB8000

;--------------------------------------------------------------------------------
; Entrada de Teclado
;--------------------------------------------------------------------------------
%define 	ESC_KEY		0x01					; Scan code de ESC