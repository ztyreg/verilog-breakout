`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:48:23 12/22/2018 
// Design Name: 
// Module Name:    shift_reg 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module shift_reg(
	input wire clk, S_L, s_in,
    input wire R_S,
    input wire [7:0] p_in,
    output wire [7:0] Q
    );
	
	wire [7:0] or_out;
	wire [7:0] and_1_out;
	wire [7:0] and_2_out;
	wire n_S_L;
    wire n_R_S;
    wire R_or_S;
    wire temp[1:0];

    FD  f0(.Q(Q[7]), .D(or_out[7]), .C(clk)),
    	f1(.Q(Q[6]), .D(or_out[6]), .C(clk)),
    	f2(.Q(Q[5]), .D(or_out[5]), .C(clk)),
    	f3(.Q(Q[4]), .D(or_out[4]), .C(clk)),
    	f4(.Q(Q[3]), .D(or_out[3]), .C(clk)),
    	f5(.Q(Q[2]), .D(or_out[2]), .C(clk)),
    	f6(.Q(Q[1]), .D(or_out[1]), .C(clk)),
    	f7(.Q(Q[0]), .D(or_out[0]), .C(clk));

    OR2 o0(or_out[7], and_1_out[7], and_2_out[7]),
    	o1(or_out[6], and_1_out[6], and_2_out[6]),
    	o2(or_out[5], and_1_out[5], and_2_out[5]),
    	o3(or_out[4], and_1_out[4], and_2_out[4]),
    	o4(or_out[3], and_1_out[3], and_2_out[3]),
    	o5(or_out[2], and_1_out[2], and_2_out[2]),
    	o6(or_out[1], and_1_out[1], and_2_out[1]),
    	o7(or_out[0], and_1_out[0], and_2_out[0]);

    // R_S: 0, s_in; 1, Q[0]
    OR2 p0(temp[1], n_R_S, s_in),
        p1(temp[0], R_S, Q[0]);

    AND2 c0(R_or_S, temp[1], temp[0]);

    AND2 a0(and_1_out[7], R_or_S, n_S_L),
    	a1(and_1_out[6], Q[7], n_S_L),
    	a2(and_1_out[5], Q[6], n_S_L),
    	a3(and_1_out[4], Q[5], n_S_L),
    	a4(and_1_out[3], Q[4], n_S_L),
    	a5(and_1_out[2], Q[3], n_S_L),
    	a6(and_1_out[1], Q[2], n_S_L),
    	a7(and_1_out[0], Q[1], n_S_L);

    AND2 b0(and_2_out[7], p_in[7], S_L),
    	b1(and_2_out[6], p_in[6], S_L),
    	b2(and_2_out[5], p_in[5], S_L),
    	b3(and_2_out[4], p_in[4], S_L),
    	b4(and_2_out[3], p_in[3], S_L),
    	b5(and_2_out[2], p_in[2], S_L),
    	b6(and_2_out[1], p_in[1], S_L),
    	b7(and_2_out[0], p_in[0], S_L);
    
    INV i0(n_S_L, S_L);
    INV i1(n_R_S, R_S);


endmodule
