`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:18:33 12/20/2018 
// Design Name: 
// Module Name:    ps2_keyboard 
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
module ps2_keyboard(clk,rst,ps2k_clk,ps2k_data,ps2_byte,ps2_state);

input clk; //50M时钟信号
input rst;  //复位信号
input ps2k_clk;   //PS2接口时钟信号
input ps2k_data;  //PS2接口数据信号
output[7:0] ps2_byte;    // 1byte键值，只做简单的按键扫描
output ps2_state;    //键盘当前状态，ps2_state=1表示有键被按下

//------------------------------------------

reg ps2k_clk_r0,ps2k_clk_r1,ps2k_clk_r2;  //ps2k_clk状态寄存器

//wire pos_ps2k_clk;     // ps2k_clk上升沿标志位

wire neg_ps2k_clk;   // ps2k_clk下降沿标志位

always @ (posedge clk or negedge rst) begin
    if(!rst) begin
           ps2k_clk_r0 <= 1'b0;
           ps2k_clk_r1 <= 1'b0;
           ps2k_clk_r2 <= 1'b0;
       end
    else begin                         //锁存状态，进行滤波
           ps2k_clk_r0 <= ps2k_clk;
           ps2k_clk_r1 <= ps2k_clk_r0;
           ps2k_clk_r2 <= ps2k_clk_r1;
       end
end

assign neg_ps2k_clk = ~ps2k_clk_r1 & ps2k_clk_r2;    //下降沿

//------------------------------------------

reg[7:0] ps2_byte_r;     //PC接收来自PS2的一个字节数据存储器
reg[7:0] temp_data;  //当前接收数据寄存器
reg[3:0] num; //计数寄存器

always @ (posedge clk or negedge rst) begin
    if(!rst) begin
           num <= 4'd0;
           temp_data <= 8'd0;
       end
    else if(neg_ps2k_clk) begin //检测到ps2k_clk的下降沿
           case (num)
              4'd0:  num <= num+1'b1;
              4'd1:  begin
                         num <= num+1'b1;
                         temp_data[0] <= ps2k_data;  //bit0
                     end
              4'd2:  begin
                         num <= num+1'b1;
                         temp_data[1] <= ps2k_data;  //bit1
                     end
              4'd3:  begin
                         num <= num+1'b1;
                         temp_data[2] <= ps2k_data;  //bit2
                     end
              4'd4:  begin
                         num <= num+1'b1;
                         temp_data[3] <= ps2k_data;  //bit3
                     end
              4'd5:  begin
                         num <= num+1'b1;
                         temp_data[4] <= ps2k_data;  //bit4
                     end
              4'd6:  begin
                         num <= num+1'b1;
                         temp_data[5] <= ps2k_data;  //bit5
                     end
              4'd7:  begin
                         num <= num+1'b1;
                         temp_data[6] <= ps2k_data;  //bit6
                     end
              4'd8:  begin
                         num <= num+1'b1;
                         temp_data[7] <= ps2k_data;  //bit7
                     end
              4'd9:  begin
                         num <= num+1'b1;  //奇偶校验位，不做处理
                     end
              4'd10: begin
                         num <= 4'd0;  // num清零
                     end
              default: ;
              endcase
       end
end

reg key_f0;       //松键标志位，置1表示接收到数据8'hf0（键盘断码），再接收到下一个数据后清零
reg ps2_state_r;  //键盘当前状态，ps2_state_r=1表示有键被按下

always @ (posedge clk or negedge rst) begin //接收数据的相应处理，这里只对1byte的键值进行处理
    if(!rst) begin
           key_f0 <= 1'b0;
           ps2_state_r <= 1'b0;
       end
    else if(num==4'd10&&neg_ps2k_clk) begin   //刚传送完一个字节数据
           //if(temp_data == 8'hf0) key_f0 <= 1'b1;
           //else begin
                  if(!key_f0) begin //说明有键按下
                         ps2_state_r <= 1'b1;
                         ps2_byte_r <= temp_data; //锁存当前键值   
                     end
                  else begin
                         ps2_state_r <= 1'b0;
                         key_f0 <= 1'b0;            
                     end
              //end
       end
end

assign ps2_byte = ps2_byte_r;
assign ps2_state = ps2_state_r;

endmodule
