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
	input [15:0] SW,
	input PS2_clk,
	input PS2_data,
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
	
	wire [4:0] keyCodeBoard, keyCodePad, keyCode;
	
	wire keyReady;
	ps2tokey tokey(.clk(clk),.PS2_clk(PS2_clk),.PS2_data(PS2_data),.key_pressed(keyCodeBoard));
	//Keypad k0 (.clk(clkdiv[15]), .keyX(BTN_Y), .keyY(BTN_X),.keyCode(keyCodePad), .ready(keyReady));
	//assign keyCode = (keyCodeBoard == 0) ? keyCodeBoard : keyCodePad;
	
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
 	
	
	reg [3:0] x = 4'd4;
	reg [3:0] y = 4'd8;
	
 	reg [11:0] rgb_reg, rgb_next;
 	wire [9:0] col_addr;
 	wire [9:0] row_addr;
	wire [19:0] x_sqr, y_sqr, r_sqr;
    wire [11:0] ip_out;
    wire [11:0] data_in;
    
    wire video_on, graph_on;
    wire [3:0] text_on;
    
    assign data_in = (graph_on)? rgb_reg : ip_out;
	
	vgac v0 (
		.vga_clk(clkdiv[1]), .clrn(SW_OK[15]), .d_in(data_in), 
		.row_addr(row_addr), .col_addr(col_addr), 
		.r(r), .g(g), .b(b), .hs(hs), .vs(vs)
	);
	reg wasReady;

	
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
	
	wire [3:0] dig0, dig1;
	
	assign video_on = 1'b1;
	
   //=======================================================
   // instantiation
   //=======================================================
	   // instantiate graph module
    pong_graph graph_unit
        (.clk(clkdiv), .reset(!rstn), .btn(keyCodeBoard),
        .pix_x(col_addr), .pix_y(row_addr),
        .gra_still(SW[0]), .hit(hit), .miss(miss),
        .graph_on(graph_on), .graph_rgb(graph_rgb));
        
//    pong_text text_unit
//      (.clk(clk),
//       .pix_x(col_addr), .pix_y(row_addr),
//       .dig0(dig0), .dig1(dig1), .ball(ball_reg),
//       .text_on(text_on), .text_rgb(text_rgb));
	

   //=======================================================
   // finite state machine
   //=======================================================
	always @(posedge clk, negedge rstn)
       if (!rstn) begin
         state_reg <= newgame;
         ball_reg <= 0;
         rgb_reg <= 12'h000;
      end
       else begin
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
   

    wire [18:0] blk_mem_0_d;

    //blk_mem_gen_0 v0(.clka(clkdiv), .addra(blk_mem_0_d), .douta(ip_out));

    assign blk_mem_0_d = row_addr * 640 + col_addr;
    
     reg [7:0] counter;
     initial begin
        counter = 8'd0;
     end
     always @(posedge clk) begin
         if (hit) begin
           if(counter[3:0] < 4'd9)
                counter[3:0] <= counter[3:0] + 4'd1;
            else if(counter[3:0] == 4'd9)begin
                counter[3:0] <= 4'd0;
                if(counter[7:4] < 4'd9)
                    counter[7:4] <= counter[7:4] + 4'd1;
                else
                    counter[7:4] <= 4'd0;
            end
        end
     end

	assign segTestData = {24'd0, counter};
	wire [15:0] ledData;
	assign ledData = SW_OK;
	
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), 
	.pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));
    
    // counter


endmodule

