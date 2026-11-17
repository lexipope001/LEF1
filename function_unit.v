////////////////////////////////////////////////////////////////////////////////////////////////////
//
// File: function_unit.v
// Top-level file for Function Unit
// Modified by: alexandra Pope & michael Shields
// Description:Widened from the 8-bit LE C.3 design to 16-bit
////////////////////////////////////////////////////////////////////////////////////////////////////

module function_unit(FS, OpA, OpB, result, V, C, N, Z);
	input   [3:0] FS;				// Function Unit select code.
   input  [15:0] OpA;				// Function Unit operand A
   input  [15:0] OpB;				// Function Unit operand B
   output [15:0] result;		// Function Unit result
   output        V;				// Overflow status bit
   output        C;				// Carry-out status bit
   output        N;				// Negative status bit
   output        Z;				// Zero status bit
  wire [15:0] arith_out;
  wire [15:0] block0_out;
  wire [15:0] block1_out;
  wire [15:0] block2_out;

  wire [2:0] opselect;
  wire blocks_or_arith;

  wire carry, overflow;

  assign block012_or_arith = FS[3];
  assign opselect = FS[2:0];

  arith_circuit A_C (arith_out, carry, overflow, OpA, OpB, opselect);

  block0 B0 (block0_out, OpA, OpB, opselect);
  block1 B1 (block1_out, OpA, OpB, opselect);
  block2 B2 (block2_out, OpA, OpB, opselect);

  assign result = (arith_out & {16{~blocks_or_arith}}) |
                  ((block0_out | block1_out | block2_out) & {16{blocks_or_arith}});

  assign V = (~blocks_or_arith) & overflow;
  assign C = (~blocks_or_arith) & carry;
  assign Z = ~(result[15] |result[14]|result[13]|result[12]|result[11]|result[10]|result[9]|result[8]|result[7]|result[6]result[5]result[4]|result[3]|result[2]|result[1]|result[0]);
  assign N = result[15];

endmodule


// Module: arith_circuit (16-bit)
// 000 sub, 001 incB, 010 mova, 011 inc3A, 100 add, 101 decA
module arith_circuit (result, cflag, vflag, OpA, OpB, opselect);
	input  [2:0] opselect;
	input  [15:0] OpA, OpB;
	output [15:0] result;
	output cflag, vflag;

	wire c0, incB, nincB, decA, invB, low, zeroB;
	wire [15:0] a_in, b_zero, b_inv, b_in;

	assign c0    = ~(opselect[2] | opselect[1]);
	assign incB  = c0 & opselect[0];
	assign nincB = ~incB;
	assign decA  = opselect[2] & opselect[0];
	assign invB  = c0 & ~opselect[0];
	assign zeroB = ~(opselect[1] | decA);
	assign low   = opselect[0] & (opselect[1] | opselect[2]);

	assign a_in   = OpA & {16{nincB}};
	assign b_zero = OpB & {16{zeroB}};
	assign b_inv  = b_zero ^ {16{invB}};
	assign b_in   = b_inv | {{14{decA}}, {2{low}}};   // bits 15:2 for decA, bits 1:0 for inc3A/decA

	chained_adder fa_16_bits(result, cflag, vflag, a_in, b_in, c0);
endmodule


// Module: chained_adder (16-bit ripple carry)
module chained_adder(sum, cflag, vflag, a, b, cin);
	input cin;
	input [15:0] a, b;

	output [15:0] sum;
	output carry, overflow;

	wire [15:1] c;
	wire c16;

	full_adder fa0  (sum[0],  c[1],  a[0],  b[0],  cin);
	full_adder fa1  (sum[1],  c[2],  a[1],  b[1],  c[1]);
	full_adder fa2  (sum[2],  c[3],  a[2],  b[2],  c[2]);
	full_adder fa3  (sum[3],  c[4],  a[3],  b[3],  c[3]);
	full_adder fa4  (sum[4],  c[5],  a[4],  b[4],  c[4]);
	full_adder fa5  (sum[5],  c[6],  a[5],  b[5],  c[5]);
	full_adder fa6  (sum[6],  c[7],  a[6],  b[6],  c[6]);
	full_adder fa7  (sum[7],  c[8],  a[7],  b[7],  c[7]);
	full_adder fa8  (sum[8],  c[9],  a[8],  b[8],  c[8]);
	full_adder fa9  (sum[9],  c[10], a[9],  b[9],  c[9]);
	full_adder fa10 (sum[10], c[11], a[10], b[10], c[10]);
	full_adder fa11 (sum[11], c[12], a[11], b[11], c[11]);
	full_adder fa12 (sum[12], c[13], a[12], b[12], c[12]);
	full_adder fa13 (sum[13], c[14], a[13], b[13], c[13]);
	full_adder fa14 (sum[14], c[15], a[14], b[14], c[14]);
	full_adder fa15 (sum[15], c16,   a[15], b[15], c[15]);

	assign overflow = c16 ^ c[15];
	assign carry = c16;
endmodule


// Module: full_adder
module full_adder(sum, cout, a, b, cin);
	input a, b, cin;
	output sum, cout;
	wire a_xor_b;
	assign a_xor_b = a ^ b;
	assign sum  = a_xor_b ^ cin;
	assign cout = (a & b) | (cin & a_xor_b);
endmodule


// Module: block0 (rem16, mod8) - 16-bit
module block0 (result, OpA, OpB, opselect);
	input [2:0] opselect;
	input [15:0] OpA, OpB;
	output [15:0] result;

	wire remnotzero, remupper, upperout;
	wire block0;
	wire out_block0;

	assign block0 = (~opselect[2]) & (opselect[1] | opselect[0]);

	// remainder is nonzero when any of B[3:0] is 1
	assign remnotzero = OpB[3] | OpB[2] | OpB[1] | OpB[0];
	// rem16: upper bits = sign of B if remainder nonzero, else 0
	assign remupper = OpB[15] & remnotzero;
	// rem16 keeps the upper bits, mod8 clears them
	assign upperout = remupper & opselect[0];

	assign out_block0= upperout & using_block0;

	assign result[0] = OpB[0] & block0;
	assign result[1] = OpB[1] & block0;
	assign result[2] = OpB[2] & block0;
	assign result[3] = OpB[3] & opselect[0] &block0;
	assign result[15:4] = {12{out_block0}};
endmodule


// Module: block1 (nor, and, nand) - 16-bit
module block1 (result, OpA, OpB, opselect);
	input [2:0] opselect;
	input [15:0] OpA, OpB;
	output [15:0] result;

	wire nand_bool, nor_bool, and_bool, block1;

	assign nor_bool  = ~opselect[2];
	assign nand_bool = opselect[0] & opselect[2];
	assign and_bool  = ~(opselect[0] | ~opselect[2]);
	assign block1 = ~opselect[1] & (~opselect[0]|opselect[2]);

	wire [15:0] nored, nanded, anded, nanded_original;

	assign nor_ = ~(~(OpA|OpB) & {16{nor_bool}});
	assign nand_original = ~(OpA & OpB);
	assign nand_ = ~(nand_original & {16{nand_bool}});
	assign and_ = ~(~nand_original & {16{and_bool}});
	assign result = ~(nor_ & and_ & nand_) & {16{block1}};
endmodule


// Module: block2 (notA, notB) - 16-bit
module block2 (result, OpA, OpB, opselect);
	input [2:0] opselect;
	input [15:0] OpA, OpB;
	output [15:0] result;

	wire [15:0] opA_select, opB_select;
	wire s, block2;

	assign s = opselect[0];
	assign block2 = opselect[2] & opselect[1];

	assign opA_selected = {16{s}}  & OpA;
	assign opB_selected = {16{~s}} & OpB;

	assign result = ~(opA_select|opB_select) & {16{block2}};
endmodule

