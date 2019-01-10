`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:55:04 01/02/2019 
// Design Name: 
// Module Name:    vgaIP 
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
module vgaIP(
input clock,     //系统输入时钟 25MHz
inout rst,		  //复位信号
input [11:0] disp_RGB,
output reg [3:0] disp_b,
output reg [3:0] disp_g,
output reg [3:0] disp_r,
output reg [9:0] h_addr,
output reg [9:0] v_addr,    
output  hsync,     //VGA行同步信号
output  vsync     //VGA场同步信号
);



reg vga_clk = 0;     
reg cnt_clk = 0;
//reg [11:0] data;

//wire [15:0]rom_addr;
//wire [11:0]rom_data;
wire dat_act;
wire  vga_pclk;	//vga时钟
wire disp_topic;	//显示区域信号
reg [9:0] vga_h_cnt;	//列计数
reg [9:0] vga_v_cnt;	//行计数

//VGA行、场扫描时序参数表
parameter hsync_end   = 10'd95,
   hdat_begin  = 10'd143,//143
   hdat_end  = 10'd783,
   hpixel_end  = 10'd799,
   vsync_end  = 10'd1,
   vdat_begin  = 10'd34,//34
   vdat_end  = 10'd514,
   vline_end  = 10'd524;

									
always @(posedge clock)		//25MHz VGA时钟
begin
	if(cnt_clk == 1)begin
		vga_clk <= ~vga_clk;
		cnt_clk <= 0;
	end
	else
		cnt_clk <= cnt_clk + 1;
end
assign vga_pclk = vga_clk;

//************************VGA驱动部分******************************* 
//行扫描     
always @(posedge vga_pclk)
begin
 if (hcount_ov)
  vga_h_cnt <= 10'd0;
 else
  vga_h_cnt <= vga_h_cnt + 10'd1;
 end
assign hcount_ov = (vga_h_cnt == hpixel_end);

//场扫描
always @(posedge vga_pclk)
begin
 if (hcount_ov)
begin
 if (vcount_ov)
   vga_v_cnt <= 10'd0;
  else
   vga_v_cnt <= vga_v_cnt + 10'd1;
 end
end
assign  vcount_ov = (vga_v_cnt == vline_end);

//数据、同步信号输
assign dat_act =    ((vga_h_cnt > hdat_begin) & (vga_h_cnt <= hdat_end))
							 & ((vga_v_cnt > vdat_begin) & (vga_v_cnt <= vdat_end));
assign hsync = (vga_h_cnt > hsync_end);
assign vsync = (vga_v_cnt > vsync_end);    

//************************显示数据处理部分******************************* 

wire [9:0]col = vga_h_cnt - 144;
wire [9:0]row = vga_v_cnt - 35; 
 

assign disp_topic = (vga_v_cnt> 10'd34) & (vga_v_cnt<= 10'd192)//514 
                    & (vga_h_cnt> 10'd143) & (vga_h_cnt <= 10'd379);//783

always @ (posedge vga_pclk)begin
			h_addr <= col;
			v_addr <= row;
			if(dat_act)begin
				disp_b <= disp_RGB[11:8];
				disp_g <= disp_RGB[7:4];
				disp_r <= disp_RGB[3:0];
			end
			else
				disp_b <= 4'h0;
				disp_g <= 4'h0;
				disp_r <= 4'h0;
		end

endmodule
