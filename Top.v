`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/10/17 12:25:41
// Design Name: 
// Module Name: Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top(
	input clk,
	input rstn,
	input [15:0]SW,
	output hs,
	output vs,
	output [3:0] r,
	output [3:0] g,
	output [3:0] b,
	output SEGLED_CLK,
	output SEGLED_CLR,
	output SEGLED_DO,
	output SEGLED_PEN,
    output LED_CLK,
	output LED_CLR,
	output LED_DO,
	output LED_PEN,
	inout [4:0]BTN_X,
	inout [3:0]BTN_Y,
	output buzzer
    );
	///////////////
	// Demo part //
	///////////////
	reg [31:0]clkdiv;
	always@(posedge clk) begin
		clkdiv <= clkdiv + 1'b1;
	end
	assign buzzer = 1'b1;
	wire [15:0] SW_OK;
	AntiJitter #(4) a0[15:0](.clk(clkdiv[15]), .I(SW), .O(SW_OK));
	
	wire [4:0] keyCode;
	wire keyReady;
	Keypad k0 (.clk(clkdiv[15]), .keyX(BTN_Y), .keyY(BTN_X), 
	   .keyCode(keyCode), .ready(keyReady));
	
	wire [31:0] segTestData;
	wire [3:0]sout;
    Seg7Device segDevice(.clkIO(clkdiv[3]), 
        .clkScan(clkdiv[15:14]), .clkBlink(clkdiv[25]),
		.data(segTestData), .point(8'h0), .LES(8'h0),
		.sout(sout));
	assign SEGLED_CLK = sout[3];
	assign SEGLED_DO = sout[2];
	assign SEGLED_PEN = sout[1];
	assign SEGLED_CLR = sout[0];
 	
	
	reg [9:0] x;
	reg [8:0] y;
	
 	reg [11:0] rgb_reg, rgb_next;
 	wire [9:0] col_addr;
 	wire [9:0] row_addr;
	wire [19:0] x_sqr, y_sqr, r_sqr;
    wire [11:0] ip_out;
    wire [11:0] data_in;
    
    wire video_on, graph_on;
    
    assign data_in = (graph_on)? rgb_reg : ip_out;
	
	vgac v0 (
		.vga_clk(clkdiv[1]), .clrn(SW_OK[15]), .d_in(data_in), 
		.row_addr(row_addr), .col_addr(col_addr), 
		.r(r), .g(g), .b(b), .hs(hs), .vs(vs)
	);
	reg wasReady;
//	reg [9:0] radius = 10'd15;
//	always @(posedge clk) begin
//		if (!rstn) begin
//			x <= 10'd320;
//			y <= 9'd240;
//			radius <= 10'd15;
//		end else begin
//			wasReady <= keyReady;
//			if (!wasReady&&keyReady) begin
//				case (keyCode)
//					5'h10: radius <= radius - 10'd5;
//					5'h12: radius <= radius + 10'd5;
//					5'hc: x <= x - 10'd20;
//					5'he: x <= x + 10'd20;
//					5'h9: y <= y - 9'd20;
//					5'h11: y <= y + 9'd20;
//					default: ;
//				endcase
//			end
//		end
//	end
	
    ///////////////////
	// Breakout part //
	///////////////////
    localparam  [1:0]
        newgame = 2'b00,
        play    = 2'b01,
        newball = 2'b10,
        over    = 2'b11;
        
	
	reg [1:0] state_reg, state_next;
	reg [1:0] ball_reg, ball_next;
	
	wire [11:0] graph_rgb, text_rgb;
	
	reg gra_still;
	wire hit, miss;
	
	assign video_on = 1'b1;
	
   //=======================================================
   // instantiation
   //=======================================================
	   // instantiate graph module
    pong_graph graph_unit
        (.clk(clk), .reset(!rstn), .btn(keyCode),
        .pix_x(col_addr), .pix_y(row_addr),
        .gra_still(SW[0]), .hit(hit), .miss(miss),
        .graph_on(graph_on), .graph_rgb(graph_rgb));
	

   //=======================================================
   // finite state machine
   //=======================================================
	always @(posedge clk, negedge rstn)
       if (!rstn)
          begin
             state_reg <= newgame;
             ball_reg <= 0;
             rgb_reg <= 12'h000;
          end
       else
          begin
            state_reg <= state_next;
            ball_reg <= ball_next;
//            if (pixel_tick)
               rgb_reg <= rgb_next;
          end
	
    always @*
      if (~video_on)
         rgb_next = "000"; // blank the edge/retrace
      else
         // display score, rule, or game over
//         if (text_on[3] ||
//               ((state_reg==newgame) && text_on[1]) || // rule
//               ((state_reg==over) && text_on[0]))
//            rgb_next = text_rgb;
//         else 
            if (graph_on)  // display graph
           rgb_next = graph_rgb;
//         else if (text_on[2]) // display logo
//           rgb_next = text_rgb;
         else
           rgb_next = 12'hff0; // yellow background
   
   // output
//    always @* begin
//        vga_data <= {{4{rgb_reg[2]}}, {4{rgb_reg[1]}}, {4{rgb_reg[0]}}};
//        vga_data <= rgb_reg;
//    end
	
//	assign x_sqr = (x - col_addr) * (x - col_addr);
//	assign y_sqr = (y - row_addr) * (y - row_addr);
//	assign r_sqr = radius * radius;
	
//	always@(*) begin
//		if ((x_sqr + y_sqr < r_sqr))
//			vga_data <= SW[12:1];
//		else vga_data <= 12'hfff;
//	end
    wire [18:0] d;

    
//    vgaIP ip1(.clock(clk),
//        .rst(!rstn),
//        .disp_RGB({ip_out[11:4], 4'hf}),
//        .disp_b(b),
//        .disp_g(g),
//        .disp_r(r),
//        .h_addr(col_addr),
//        .v_addr(row_addr),    
//        .hsync(hs),
//        .vsync(vs)
//    );
    
    
    blk_mem_gen_0(.clka(clk), .addra(d), .douta(ip_out));

    assign d = row_addr * 640 + col_addr;

	assign segTestData = {7'b0,x,8'b0,y};
	wire [15:0] ledData;
	assign ledData = SW_OK;
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), 
	.pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));


endmodule
