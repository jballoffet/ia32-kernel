SECTIONS
{
	. = 0xFFFFFFF0; 							/* location counter = VMA */
	.reset_vector : 							/* Reset vector */ 
	  AT ( 0xFFFFFFF0 )							/* LMA al origen del binario */
		{ *(.reset_vector) __reset_vector = . ; }

	. = 0xFFFF0000; 							/* location counter = VMA */
	.init16 :									/* seccion de salida */
	  AT ( 0xFFFF0000 )							/* Desplazo para alinear a 0x100 el offset de init16.asm */
		{ *(.init16); }
	
	.init32 0x000F4000: 
	  AT ( 0xFFFF4000 )
		{ __init32_LMA = LOADADDR(.init32);
		__init32_start = . ; *(.init32*);
		__init32_end = . ;}
	
	.tables 0x00100000 : 
	  AT ( LOADADDR(.init32) + SIZEOF(.init32) )
		{ __sys_tables_LMA = LOADADDR(.tables);
		__sys_tables_start = . ; *(.sys_tables*);
		__sys_tables_end = . ;}
	
	.main 0x00150000 : 
	  AT ( LOADADDR(.tables) + SIZEOF(.tables) )
		{ __main_LMA = LOADADDR(.main);
		__main_start = . ; *(.main);
		__main_end = . ;}
		
	.data 0x00200000 : 	
	  AT ( LOADADDR(.main) + SIZEOF(.main) )
		{ __mdata_LMA = LOADADDR(.data);
		  __mdata_start = . ; *(.data*);
		  __mdata_end = . ; }
	
	__datos_no_iniciali_inicio = .;
	 
	.bss 0x00210000 :
		{ __bss_start = . ; *(.bss) *(COMMON); 
		*(.dat_no_inic*); __bss_end = . ;}
		
	.lib 0x00220000 : 	
	  AT ( LOADADDR(.data) + SIZEOF(.data) )
		{ __lib_LMA = LOADADDR(.lib);
		  __lib_start = . ; *(.lib*);
		  __lib_end = . ; }	
		  
	.other 0x00250000 : 	
	  AT ( LOADADDR(.lib) + SIZEOF(.lib) )
		{ __other_LMA = LOADADDR(.other);
		  __other_start = . ; *(.other*);
		  __other_end = . ; }
		  
	.shared 0x00300000 : 	
	  AT ( LOADADDR(.other) + SIZEOF(.other) )
		{ __shared_LMA = LOADADDR(.shared);
		  __shared_start = . ; *(.shared*);
		  __shared_end = . ; }

	.t1_main 0x00A00000 : 	
	  AT ( LOADADDR(.shared) + SIZEOF(.shared) )
		{ __t1_main_LMA = LOADADDR(.t1_main);
		  __t1_main_start = . ; *(.t1_main*);
		  __t1_main_end = . ; }

	.t1_data 0x00A08000 : 	
	  AT ( LOADADDR(.t1_main) + SIZEOF(.t1_main) )
		{ __t1_data_LMA = LOADADDR(.t1_data);
		  __t1_data_start = . ; *(.t1_data*);
		  __t1_data_end = . ; }	
	
	.t2_main 0x00A10000 : 	
	  AT ( LOADADDR(.t1_data) + SIZEOF(.t1_data) )
		{ __t2_main_LMA = LOADADDR(.t2_main);
		  __t2_main_start = . ; *(.t2_main*);
		  __t2_main_end = . ; }
	
	.t2_data 0x00A18000 : 	
	  AT ( LOADADDR(.t2_main) + SIZEOF(.t2_main) )
		{ __t2_data_LMA = LOADADDR(.t2_data);
		  __t2_data_start = . ; *(.t2_data*);
		  __t2_data_end = . ; }
		  
	.t3_main 0x00A20000 : 	
	  AT ( LOADADDR(.t2_data) + SIZEOF(.t2_data) )
		{ __t3_main_LMA = LOADADDR(.t3_main);
		  __t3_main_start = . ; *(.t3_main*);
		  __t3_main_end = . ; }
	
	.t3_data 0x00A28000 : 	
	  AT ( LOADADDR(.t3_main) + SIZEOF(.t3_main) )
		{ __t3_data_LMA = LOADADDR(.t3_data);
		  __t3_data_start = . ; *(.t3_data*);
		  __t3_data_end = . ; }	
}