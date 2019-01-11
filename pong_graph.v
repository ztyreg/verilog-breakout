// Listing 14.7
module pong_graph 
   (
    input wire clk, reset,
    input wire [4:0] btn,
    input wire [9:0] pix_x, pix_y,
    input wire gra_still,
    output wire graph_on,
    output reg hit, miss,
    output reg [11:0] graph_rgb
   );

   // costant and signal declaration
   // x, y coordinates (0,0) to (639,479)
   localparam MAX_X = 640;
   localparam MAX_Y = 480;
   wire refr_tick;
   //--------------------------------------------
   // bricks
   //--------------------------------------------
   localparam NUM_BRICKS = 2; // 6*8
   localparam ROW_BRICKS = 1;//
   localparam COL_BRICKS = 2;//
   localparam BRICK_HEIGHT = 70; // 6*70+60=480
   localparam BRICK_WIDTH = 35; // 35*8=280
   // bricks region boundary
   localparam REGION_X_L = 40;
   localparam REGION_X_R = 110;//
   localparam REGION_Y_T = 30;
   localparam REGION_Y_B = 100;//
   reg [1:0] bricks_destroyed = 2'b0;//
   reg [1:0] bricks_destroyed_next = 2'b0;
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // bar left, right boundary
   localparam BAR_X_L = 600;
   localparam BAR_X_R = 603;
   // bar top, bottom boundary
   wire [9:0] bar_y_t, bar_y_b;
   localparam BAR_Y_SIZE = 72;
   // register to track top boundary  (x position is fixed)
   reg [9:0] bar_y_reg, bar_y_next;
   // bar moving velocity when the button are pressed
   localparam BAR_V = 4;
   //--------------------------------------------
   // left vertical bar AI
   //--------------------------------------------
   // bar left, right boundary
   localparam AI_X_L = 6;
   localparam AI_X_R = 9;
   // bar top, bottom boundary
   wire [9:0] ai_y_t, ai_y_b;
   localparam AI_Y_SIZE = 72;
   // register to track top boundary  (x position is fixed)
   reg [9:0] ai_y_reg, ai_y_next;
   // bar moving velocity when the button are pressed
   localparam AI_V = 1;
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   localparam BALL_SIZE = 8;
   // ball left, right boundary
   wire [9:0] ball_x_l, ball_x_r;
   // ball top, bottom boundary
   wire [9:0] ball_y_t, ball_y_b;
   // reg to track left, top position
   reg [9:0] ball_x_reg, ball_y_reg;
   wire [9:0] ball_x_next, ball_y_next;
   // reg to track ball speed
   reg [9:0] x_delta_reg, x_delta_next;
   reg [9:0] y_delta_reg, y_delta_next;
   // ball velocity can be pos or neg)
   localparam BALL_V_P = 1;
   localparam BALL_V_N = -1;
   //--------------------------------------------
   // round ball 
   //--------------------------------------------
   wire [2:0] rom_addr, rom_col;
   reg [7:0] rom_data;
   wire rom_bit;
   //--------------------------------------------
   // object output signals
   //--------------------------------------------
   wire wall_on, bar_on, sq_ball_on, rd_ball_on;
   wire brick_on;
   wire ai_on;
   wire [47:0] brick_on_sub;
   wire [11:0] brick_rgb;
   wire [11:0] ai_rgb;
   wire [11:0] wall_rgb, bar_rgb, ball_rgb;
   //--------------------------------------------
   // iterators and counts
   //--------------------------------------------
   // i for loop
   genvar i; 
   integer j, col, row, top, bottom, left, right;
   // number of bricks left
   integer bricks_count = 48;
  
   // body 
   //--------------------------------------------
   // round ball image ROM
   //--------------------------------------------
   always @*
   case (rom_addr)
      3'h0: rom_data = 8'b00111100; //   ****
      3'h1: rom_data = 8'b01111110; //  ******
      3'h2: rom_data = 8'b11111111; // ********
      3'h3: rom_data = 8'b11111111; // ********
      3'h4: rom_data = 8'b11111111; // ********
      3'h5: rom_data = 8'b11111111; // ********
      3'h6: rom_data = 8'b01111110; //  ******
      3'h7: rom_data = 8'b00111100; //   ****
   endcase
   
   // registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            bar_y_reg <= 0;
            ball_x_reg <= 0;
            ball_y_reg <= 0;
            x_delta_reg <= 10'h004;
            y_delta_reg <= 10'h004;
         end   
      else
         begin
            bar_y_reg <= bar_y_next;
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
            bricks_destroyed <= bricks_destroyed_next;
         end   

   // refr_tick: 1-clock tick asserted at start of v-sync
   //       i.e., when the screen is refreshed (60 Hz)
   assign refr_tick = (pix_y==481) && (pix_x==0);
   
   //--------------------------------------------
   // brick (region)
   //--------------------------------------------
   // pixel within region
   for (i = 0; i < NUM_BRICKS; i = i + 1) 
   begin
      assign brick_on_sub[i] =  (!bricks_destroyed[i] &&
                                (REGION_X_L+(i%COL_BRICKS)*BRICK_WIDTH <= pix_x) && 
                                (pix_x <= REGION_X_L+(i%COL_BRICKS+1)*BRICK_WIDTH - 1) &&
                                (REGION_Y_T+(i/COL_BRICKS)*BRICK_HEIGHT <= pix_y) && 
                                (pix_y <= REGION_Y_T+(i/COL_BRICKS+1)*BRICK_HEIGHT - 1));
   end
   assign brick_on = |brick_on_sub; // in any on brick region
   // brick rgb output
   assign brick_rgb = 12'h00f; // red

   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // boundary
   assign bar_y_t = bar_y_reg;
   assign bar_y_b = bar_y_t + BAR_Y_SIZE - 1;
   // pixel within bar
   assign bar_on = (BAR_X_L<=pix_x) && (pix_x<=BAR_X_R) &&
                   (bar_y_t<=pix_y) && (pix_y<=bar_y_b); 
   // bar rgb output
   assign bar_rgb = 12'h0f0; // green
   // new bar y-position
   always @*
   begin
      bar_y_next = bar_y_reg; // no move
      if (gra_still) // initial position of paddle
         bar_y_next = (MAX_Y-BAR_Y_SIZE)/2;
      else if (refr_tick)
         if ((btn == 5'h10) & (bar_y_b < (MAX_Y-1-BAR_V)))
            bar_y_next = bar_y_reg + BAR_V; // move down
         else if ((btn == 5'hc) & (bar_y_t > BAR_V)) 
            bar_y_next = bar_y_reg - BAR_V; // move up
   end 
   
   //--------------------------------------------
   // left vertical bar AI
   //--------------------------------------------
   // boundary
//   assign ai_y_t = ai_y_reg;
//   assign ai_y_b = ai_y_t + AI_Y_SIZE - 1;
//   // pixel within AI
//   assign ai_on = (AI_X_L<=pix_x) && (pix_x<=AI_X_R) &&
//                   (ai_y_t<=pix_y) && (pix_y<=ai_y_b); 
//   // AI rgb output
//   assign ai_rgb = 12'h0f0; // green
   
//   wire ai_y_next_in, ai_y_next_out;
//   wire [7:0] ai_next_list;
//   // new AI y-position
//   always @*
//   begin
//      ai_y_next = (ball_y_t > ai_y_t - AI_Y_SIZE / 2) ? 0 : 1; // no move
//      if (gra_still) // initial position of paddle
//         ai_y_next = (MAX_Y-AI_Y_SIZE)/2;
//      else if (refr_tick)
//         if ((ai_next_list[7] == 1) & (ai_y_b < (MAX_Y-1-AI_V)))
//            ai_y_next = ai_y_reg + AI_V; // move down
//         else if ((ai_next_list[7] == 0) & (ai_y_t > AI_V)) 
//            ai_y_next = ai_y_reg - AI_V; // move up
//   end 
   
//   shift_reg s0(.clk(clk), .S_L(1'b0), .s_in(ai_y_next), .R_S(1'b0), 
//                .p_in(7'b0), .Q(ai_next_list));

   //--------------------------------------------
   // square ball
   //--------------------------------------------
   // boundary
   assign ball_x_l = ball_x_reg;
   assign ball_y_t = ball_y_reg;
   assign ball_x_r = ball_x_l + BALL_SIZE - 1;
   assign ball_y_b = ball_y_t + BALL_SIZE - 1;
   // pixel within ball
   assign sq_ball_on =
            (ball_x_l<=pix_x) && (pix_x<=ball_x_r) &&
            (ball_y_t<=pix_y) && (pix_y<=ball_y_b);
   // map current pixel location to ROM addr/col
   assign rom_addr = pix_y[2:0] - ball_y_t[2:0];
   assign rom_col = pix_x[2:0] - ball_x_l[2:0];
   assign rom_bit = rom_data[rom_col];
   // pixel within ball
   assign rd_ball_on = sq_ball_on & rom_bit;
   // ball rgb output
   assign ball_rgb = 12'hf00;   // red
  
   // new ball position
   assign ball_x_next = (gra_still) ? MAX_X/2 :
                        (refr_tick) ? ball_x_reg+x_delta_reg :
                        ball_x_reg ;
   assign ball_y_next = (gra_still) ? MAX_Y/2 :
                        (refr_tick) ? ball_y_reg+y_delta_reg :
                        ball_y_reg ;
                        
                        
   
                        
                        
                        
   //--------------------------------------------
   // new ball velocity
   //--------------------------------------------
   always @*   
   begin
      hit = 1'b0;
      miss = 1'b0;
      x_delta_next = x_delta_reg;
      y_delta_next = y_delta_reg;
      bricks_destroyed_next = bricks_destroyed;
      if (gra_still)     // initial velocity
         begin
            x_delta_next = BALL_V_N;
            y_delta_next = BALL_V_P;
            bricks_destroyed_next = 2'b0;
         end   
      else if (ball_y_t < 1) // reach top
         y_delta_next = BALL_V_P;
      else if (ball_y_b > (MAX_Y-1)) // reach bottom
         y_delta_next = BALL_V_N;
      else if (ball_x_l < 1) // reach left
         x_delta_next = BALL_V_P;
      else if ((BAR_X_L<=ball_x_r) && (ball_x_r<=BAR_X_R) &&
               (bar_y_t<=ball_y_b) && (ball_y_t<=bar_y_b))
         x_delta_next = BALL_V_N;
      else if (ball_x_r>(MAX_X-1))   // reach right border
         x_delta_next = BALL_V_N;
      else 
      
      begin: loop
         for (j = 0; j < NUM_BRICKS; j = j + 1)
         begin: pass // for every brick
            col = j % COL_BRICKS;
            row = j / ROW_BRICKS;
            top = REGION_Y_T + row * BRICK_HEIGHT;
            bottom = REGION_Y_T + (row + 1) * BRICK_HEIGHT - 1;
            left = REGION_X_L + col * BRICK_WIDTH;
            right = REGION_X_L + (col + 1) * BRICK_WIDTH - 1;
            
            
            
            
//            if (!bricks_destroyed[j] &&
//                 (left <= ball_x_r) && 
//                 (ball_x_l <= right) &&
//                 (top <=ball_y_b) && 
//                 (ball_y_t<= bottom))
//            begin
//                if ((left<=ball_x_r) && // l<br
//                     (ball_x_r<=right) && // br<r
//                     (top<=ball_y_b) && // t<bb
//                     (ball_y_t<=bottom)) // bt<b
//                begin // hit from l
//                  x_delta_next <= BALL_V_N;
//                  hit <= 1'b1;
//                  bricks_destroyed[j] <= 1;
//                  disable loop;
//                end
//                else if ((right>=ball_x_l) && // r>bl
//                     (ball_x_l>=left) && // bl>l
//                     (top<=ball_y_b) && // t<bb
//                     (ball_y_t<=bottom)) // bt<b
//                begin // hit from r
//                  x_delta_next <= BALL_V_P;
//                  hit <= 1'b1;
//                  bricks_destroyed[j] <= 1;
//                  disable loop;
//                end
//                else if ((left<=ball_x_r) && // l<br
//                     (ball_x_l<=right) && // bl<r
//                     (top<=ball_y_b) && // t<bb
//                     (ball_y_b<=bottom)) // bb<b
//                begin // hit from t
//                  y_delta_next <= BALL_V_N;
//                  hit <= 1'b1;
//                  bricks_destroyed[j] <= 1;
//                  disable loop;
//                end
//                else if ((left<=ball_x_r) && // l<br
//                     (ball_x_l<=right) && // bl<r
//                     (bottom>=ball_y_t) && // b>bt
//                     (ball_y_t>=top)) // bt>t
//                begin // hit from b
//                  y_delta_next <= BALL_V_P;
//                  hit <= 1'b1;
//                  bricks_destroyed[j] <= 1;
//                  disable loop;
//                end
//             end



            if (!bricks_destroyed[j] &&
                 (left <= ball_x_r) && (ball_x_l <= right) &&
                 (top <= ball_y_b) && (ball_y_t <= bottom)) begin // ball in collision region
                 
               if ((left < ball_x_r) && (ball_x_l < right)) begin // if ball hits t or b
                  if (ball_y_t < top) // hits t
                     y_delta_next = BALL_V_N; // bounce back
                  else // hits b
                     y_delta_next = BALL_V_P; // bounce back
//                  y_delta_next <= BALL_V_P;
                  hit = 1'b1;
                  bricks_destroyed_next[j] = 1;
               end
               else if ((top < ball_y_b) && (ball_y_t < bottom)) begin // if ball hits l or r
                  if (ball_x_l < left) // hits l
                     x_delta_next = BALL_V_N; // bounce back
                  else // hits r
                     x_delta_next = BALL_V_P; // bounce back
//                  x_delta_next <= BALL_V_P;
//                  bricks_destroyed[j] <= 1;
                  hit = 1'b1;
                  bricks_destroyed_next[j] = 1;
               end
            end




         end
      end
   end 

   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @* 
      if (brick_on)
         graph_rgb = brick_rgb;
      else if (bar_on)
         graph_rgb = bar_rgb;
      else if (rd_ball_on)
           graph_rgb = ball_rgb;
      else
            graph_rgb = 12'hff0; // cyan background
   // new graphic_on signal
   assign graph_on = brick_on | bar_on | rd_ball_on;

endmodule

