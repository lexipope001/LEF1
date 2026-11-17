////////////////////////////////////////////////////////////////////////////////////////////////////
//
// File: datapath_datamemory.v (for LE F.1)
/// ******************************************
// YOU ARE NOT PERMITTED TO MODIFY THIS FILE.
// ******************************************
// Modified: KLC 3 Feb 2025
//
// Description: This module specifies the top-level component for the DATAPATH and DATA MEMORY
//              of the Simple Computer. It is mainly a structural module whose units are 
//              implemented in other modules in this project.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

// You must not change the module or port declarations.

module datapath_datamemory(clock, reset, DA, AA, BA, MB, FS, MD, RW, MW, imm, r0, r1, r2, r3, r4, r5, r6, r7, V, C, N, Z);
	input         clock;
	input         reset;	
	input   [2:0] DA;			// Destination Register Address field
	input   [2:0] AA;			// Operand A Register Address field
	input   [2:0] BA;			// Operand B Register Address field, Immediate Operand
	input         MB;			// Multiplexer B Select
	input   [3:0] FS;			// Function Unit Select
	input         MD;			// Multiplexer D Select
	input         RW;			// Register Write
	input         MW;			// Memory Write
	input   [2:0] imm;		// Immediate operand

	output [15:0] r0;			// CPU registers
	output [15:0] r1;
	output [15:0] r2;
	output [15:0] r3;
	output [15:0] r4;
	output [15:0] r5;
	output [15:0] r6;
	output [15:0] r7;
	output        V;			// Overflow status bit
	output        C;			// Carry-out status bit
	output        N;			// Negative status bit
	output        Z;			// Zero status bit

// End module and port declaration

// Wire declaration

	wire   [15:0] data_mem_out			/* synthesis keep */ ;	// Data Memory output
	wire   [15:0] Bus_D           	/* synthesis keep */ ;	// Register file input, Bus D	
	wire   [15:0] constant				/* synthesis keep */ ;	// Immediate operand
	wire   [15:0] A						/* synthesis keep */ ;	// Register file output A
	wire   [15:0] B						/* synthesis keep */ ;	// Register file output B
	wire   [15:0] mux_b_out				/* synthesis keep */ ;	// Multiplexer B output
	wire   [15:0] function_unit_out	/* synthesis keep */ ;	// Function Unit output
	wire   [15:0] mux_d_out				/* synthesis keep */ ;	// Multiplexer D output

// End wire declaration 
	
////////////  DATA  MEMORY  ////////////

// DATA MEMORY
// - Data Memory instantiation, as 256 x 16 unit.
// - These parameters control the size of the memory. Do not change them.

	single_port_ram #(8, 16) data_mem(clock, MW, A[7:0], mux_b_out, data_mem_out);

////////////    DATAPATH    //////////// 
	
// REGISTER FILE
// - Clear the data input to the register file on a reset.

	assign Bus_D = (reset == 1'b0) ? mux_d_out : (reset == 1'b1) ? 8'b00000000 : 8'bxxxxxxxx;

// - Register file instantiation.	

	dual_port_ram register_file(clock, reset, Bus_D, RW, DA, AA, BA, A, B, r0, r1, r2, r3, r4, r5, r6, r7);

// MULTIPLEXER B
// - Generate the 16-bit zero filled immediate operand. 

	assign constant = {13'b0000000000000, imm};

// - Instantiate Multiplexer B.

	mux2to1_16bit mux_b(MB, B, constant, mux_b_out);

// FUNCTION UNIT
// - Instantiate Function Unit.

	function_unit func_unit(FS, A, mux_b_out, function_unit_out, V, C, N, Z);
	
// MULTIPLEXER D
// - Instatiate Multiplexer D.

	mux2to1_16bit mux_d(MD, function_unit_out, data_mem_out, mux_d_out);

endmodule
