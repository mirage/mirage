# This file just defines __malloc_start for newlib for the simulator.
# The simulator has RAM up to the I/O area at 0x7F00.
	.globl __malloc_start
	.set __malloc_start,0x7F00
	
