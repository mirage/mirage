

typedef struct 
{
  	int fp_rounding:2;	/* fp rounding control 		*/
  	int integer_rounding:1;	/* integer rounding 		*/
  	int rfu:1;	        /* reserved			*/
	int fp_trap:5;   	/* floating point trap bits 	*/
	int otm:1;	
	int rfu2:3;
	int att:3;
	int rfu3:16;
} v60_tkcw_type;

