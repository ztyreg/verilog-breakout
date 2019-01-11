`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:48:01 01/03/2019 
// Design Name: 
// Module Name:    ps2tokey 
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
module ps2tokey(
    input clk,
	 input PS2_clk,
	 input PS2_data,
	 output [4:0]key_pressed
    );
    wire[7:0]a;
	 wire rdy;
	 
	 integer released;
	 integer key_up_pressed=0;
	 integer key_down_pressed=0;
	 integer key_left_pressed=0;
	 integer key_right_pressed=0;
	 integer key_space_pressed=0;
	 
	 parameter key_up=8'h1d;
	 parameter key_down=8'h1b;
	 parameter key_left=8'h1c;
	 parameter key_right=8'h23;
	 parameter key_space=8'h29;
	 parameter key_released=8'hf0;
	 
	 initial begin released=0;end
	 
	 ps2_keyboard m1(.clk(clk),.rst(1-rdy),.ps2k_clk(PS2_clk),.ps2k_data(PS2_data),.ps2_byte(a),.ps2_state(rdy));
	 
	 always @(negedge rdy) begin
		if(released==0)begin
			if(a[7:0]==key_released)begin released=1;end
			if(a[7:0]==key_up)begin key_up_pressed=1;end
			if(a[7:0]==key_down)begin key_down_pressed=1;end
			if(a[7:0]==key_left)begin key_left_pressed=1;end
			if(a[7:0]==key_right)begin key_right_pressed=1;end
			if(a[7:0]==key_space)begin key_space_pressed=1;end				
		end else begin
			if(a[7:0]==key_up)begin key_up_pressed=0;end
			if(a[7:0]==key_down)begin key_down_pressed=0;end
			if(a[7:0]==key_left)begin key_left_pressed=0;end
			if(a[7:0]==key_right)begin key_right_pressed=0;end
			if(a[7:0]==key_space)begin key_space_pressed=0;end		
			released=0;
		end
	 end
	 
	 assign key_pressed[0]=key_up_pressed;
	 assign key_pressed[1]=key_down_pressed;
	 assign key_pressed[2]=key_left_pressed;
	 assign key_pressed[3]=key_right_pressed;
	 assign key_pressed[4]=key_space_pressed;

endmodule
