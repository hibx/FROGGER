`timescale 1ns / 1ps

// Used on Basys 3 

module pixel_gen(
    input clk,              // 100MHz
    input reset,            // btnC
    input up,               // btnU
    input down,             // btnD
    input left,             // btnL
    input right,            // btnR
    input [9:0] x,          // from vga controller
    input [9:0] y,          // from vga controller
    input video_on,         // from vga controller
    input p_tick,  
    input switch,///extra         // 25MHz from vga controller
    output reg [11:0] rgb ,  // to DAC, to vga connector
    output reg collision_state //,     
    //output reg [1:0] counter
    //output reg [2:0] lives   //reg
    );
    
    
    // 60Hz refresh tick
   
    reg [1:0] counter;
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0; // start of vsync(vertical retrace)
  
    // ****
  
    // maximum x, y values in display area
    parameter X_MAX = 639;
    parameter Y_MAX = 479;
    
    // FROG
    // square rom boundaries
    parameter FROG_SIZE = 28;
    parameter X_START = 320;                // starting x position - left rom edge centered horizontally
    parameter Y_START = 422;                // starting y position - centered in lower yellow area vertically
    
    // frog gameboard boundaries
    parameter X_LEFT = 32;                  // against left green wall
    parameter X_RIGHT = 608;                // against right green wall
    parameter Y_TOP = 1;//68;      //make it 1 taky end tk jaye             // against top home/wall areas 
    parameter Y_BOTTOM = 452;               // against bottom green wall
    // frog boundary signals
    wire [9:0] x_frog_l, x_frog_r;          // frog horizontal boundary signals
    wire [9:0] y_frog_t, y_frog_b;          // frog vertical boundary signals  
    reg [9:0] y_frog_reg = Y_START;         // frog starting position X
    reg [9:0] x_frog_reg = X_START;         // frog starting position Y
    reg [9:0] y_frog_next, x_frog_next;     // signals for register buffer 
    parameter FROG_VELOCITY = 1;   
    
    wire [9:0] sq_x_l, sq_x_r;              // square left and right boundary
    wire [9:0] sq_y_t, sq_y_b;              // square top and bottom boundary 
    reg [9:0] sq_x_reg, sq_y_reg;           // regs to track left, top position
    wire [9:0] sq_x_next, sq_y_next; 
    
    wire [9:0] sq1_x_l, sq1_x_r;              // square left and right boundary
    wire [9:0] sq1_y_t, sq1_y_b;              // square top and bottom boundary
    reg [9:0] sq1_x_reg, sq1_y_reg;           // regs to track left, top position
    wire [9:0] sq1_x_next, sq1_y_next;       // buffer wires
   reg collision_reg;
   wire collision_next;
   reg coll; 
    reg [9:0] x_delta_reg, y_delta_reg;     // track square speed
    reg [9:0] x_delta_next, y_delta_next; 
    reg [9:0] x1_delta_reg, y1_delta_reg;     // track square speed
    reg [9:0] x1_delta_next, y1_delta_next;         // frog velocity 
    
    //stationary blocks
    wire [9:0] blk1_x_l, blk1_x_r;              // block left and right boundary
    wire [9:0] blk1_y_t, blk1_y_b;              // block top and bottom boundary
    reg [9:0] blk1_x_reg, blk1_y_reg;           // regs to track left, top position
    wire [9:0] blk1_x_next, blk1_y_next;       // buffer wires
    
    wire [9:0] blk2_x_l, blk2_x_r;              // block left and right boundary
    wire [9:0] blk2_y_t, blk2_y_b;              // block top and bottom boundary
    reg [9:0] blk2_x_reg, blk2_y_reg;           // regs to track left, top position
    wire [9:0] blk2_x_next, blk2_y_next;       // buffer wires
    
    reg [9:0] b1_x_delta_reg, b1_y_delta_reg;     // track square speed
    reg [9:0] b1_x_delta_next, b1_y_delta_next;
    reg [9:0] b2_x_delta_reg, b2_y_delta_reg;     // track square speed
    reg [9:0] b2_x_delta_next, b2_y_delta_next;
    //reg
    
                     // bottom border of display area
    parameter SQ_RGB = 12'h0FF;             // red & green = yellow for square
    parameter SQ1_RGB = 12'h0F0;
    parameter BLK1_RGB = 12'hF00;
    parameter BLK2_RGB = 12'hF00;
    
    parameter BG_RGB = 12'hF00;             // blue background
    parameter SQUARE_SIZE = 50;             // width of square sides in pixels
    parameter SQUARE_VELOCITY_POS = 1.5;      // set position change value for positive direction
    parameter SQUARE_VELOCITY_NEG = -1.5; 
    parameter BLOCK_SIZE = 80;
    
    assign sq_x_l = sq_x_reg;                   // left boundary
    assign sq_y_t = sq_y_reg;                   // top boundary
    assign sq_x_r = sq_x_l + SQUARE_SIZE - 1;   // right boundary
    assign sq_y_b = sq_y_t + SQUARE_SIZE - 1;   // bottom boundary
    
    assign sq1_x_l = sq1_x_reg;                   // left boundary
    assign sq1_y_t = sq1_y_reg;                   // top boundary
    assign sq1_x_r = sq1_x_l + SQUARE_SIZE - 1;   // right boundary
    assign sq1_y_b = sq1_y_t + SQUARE_SIZE - 1; 
    
    
    assign blk1_x_l = blk1_x_reg;                   // left boundary
    assign blk1_y_t = blk1_y_reg;                   // top boundary
    assign blk1_x_r = blk1_x_l + BLOCK_SIZE - 1;   // right boundary
    assign blk1_y_b = blk1_y_t + BLOCK_SIZE - 1;
    
    assign blk2_x_l = blk2_x_reg;                   // left boundary
    assign blk2_y_t = blk2_y_reg;                   // top boundary
    assign blk2_x_r = blk2_x_l + BLOCK_SIZE - 1;   // right boundary
    assign blk2_y_b = blk2_y_t + BLOCK_SIZE - 1;
  
    wire start_screen_flag;
    wire game_over_flag;
    wire game_won_flag;
    startscreen start_screen(.pixel_x(x), .pixel_y(y), .flag(start_screen_flag));
    gameover game_over(.pixel_x(x), .pixel_y(y), .flag(game_over_flag));
    gamewon game_won(.pixel_x(x), .pixel_y(y), .flag(game_won_flag));
    // State machine
    reg [1:0] game_state;
    reg [1:0] game;
    parameter START_SCREEN_STATE = 2'b00;
    parameter GAME_SCREEN_STATE = 2'b01;
    parameter GAME_OVER_STATE = 2'b11;
  
   
    
    always @(posedge clk or posedge reset)begin
  /*  if (switch & collision_next==1)begin
     game<=GAME_OVER_STATE;end
     if (switch & collision_next!=1)begin
     game<=GAME_SCREEN_STATE;end
    if ( ~switch) begin  
    game<=START_SCREEN_STATE;end*/
    
        if(reset || ~switch || collision_reg==1'b1  ) begin //next tha pehle
             if (reset || ~switch)begin
          collision_reg<=0;
        end
            x_frog_reg <= X_START;
            y_frog_reg <= Y_START;
             sq_x_reg <= 0;
            sq_y_reg <= 0;
            sq1_x_reg <= 200;
            sq1_y_reg <= 200;
        
            x_delta_reg <= 10'h002;
            y_delta_reg <= 10'h002;
            x1_delta_reg <= 10'h004;
            y1_delta_reg <= 10'h008;
            
            blk1_x_reg <= 50;
            blk1_y_reg <= 70;
            
            blk2_x_reg <= 500;
            blk2_y_reg <= 70;
            
            b1_x_delta_reg <= 10'h002;
            b1_y_delta_reg <= 10'h002;
            b2_x_delta_reg <= 10'h002;
            b2_y_delta_reg <= 10'h002;
            // collision_next=collision_reg;
            
        end
        else  begin     /////////added condition
         
            x_frog_reg <= x_frog_next;
            y_frog_reg <= y_frog_next;
            sq_x_reg <= sq_x_next;
            sq_y_reg <= sq_y_next;
            sq1_x_reg <= sq1_x_next;
            sq1_y_reg <= sq1_y_next;
            collision_reg<=collision_next;
            x1_delta_reg <= x1_delta_next;
            y1_delta_reg <= y1_delta_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
           // lives<=lives;
            
            blk1_x_reg <= 50;
            blk1_y_reg <= 70;
            
            blk2_x_reg <= 500;
            blk2_y_reg <= 70;
            
            b1_x_delta_reg <= 10'h002;
            b1_y_delta_reg <= 10'h002;
            b2_x_delta_reg <= 10'h002;
            b2_y_delta_reg <= 10'h002;
           
            
        end
     
     
        end
      always @*begin
     
      if (switch & collision_reg==1)begin
     game_state<=GAME_OVER_STATE;end
     if (switch & collision_reg!=1 )begin
     game_state<=GAME_SCREEN_STATE;end
    if ( ~switch) begin
    game_state<=START_SCREEN_STATE;end
    end
    
   
     /* always @* begin 
       if (game==START_SCREEN_STATE)begin
     
         game_state<=START_SCREEN_STATE;    ////original
          
        
          end
      else if (switch && counter == 2'b11)begin
            game_state<=GAME_OVER_STATE;
            end
      else if (  game==GAME_SCREEN_STATE) begin
            game_state<=GAME_SCREEN_STATE;
            //game<=GAME_SCREEN_STATE;
            
      end 
      else if ( game==GAME_OVER_STATE)begin
            game_state<=GAME_OVER_STATE;
            //game<=GAME_OVER_STATE;
            end
       end*/
      
             
   
    // Frog Control
    always @* begin
        y_frog_next = y_frog_reg;       // no move
        x_frog_next = x_frog_reg;       // no move
        
        if(refresh_tick ) begin
        if (switch) begin  
                        
            if(up & (y_frog_t > FROG_VELOCITY) & (y_frog_t > (Y_TOP + FROG_VELOCITY)))
                y_frog_next = y_frog_reg - FROG_VELOCITY;  // move up
            else if(down & (y_frog_b < (Y_MAX - FROG_VELOCITY)) & (y_frog_b < (Y_BOTTOM - FROG_VELOCITY)))
                y_frog_next = y_frog_reg + FROG_VELOCITY;  // move down
            else if(left & (x_frog_l > FROG_VELOCITY) & (x_frog_l > (X_LEFT + FROG_VELOCITY - 1)))
                x_frog_next = x_frog_reg - FROG_VELOCITY;   // move left
            else if(right & (x_frog_r < (X_MAX - FROG_VELOCITY)) & (x_frog_r < (X_RIGHT - FROG_VELOCITY)))
                x_frog_next = x_frog_reg + FROG_VELOCITY;  
                end // move right
      else begin
       x_frog_next = x_frog_reg;
        y_frog_next = y_frog_reg;
       
      end
      end
      end   
      
 
    wire sq_on;
    assign sq_on = (sq_x_l <= x) && (x <= sq_x_r) &&
                   (sq_y_t <= y) && (y <= sq_y_b);
                   
    // new square position
    assign sq_x_next = (refresh_tick) ? sq_x_reg + x_delta_reg : sq_x_reg;
    assign sq_y_next = (refresh_tick) ? sq_y_reg + y_delta_reg : sq_y_reg;
    
    // new square velocity 
    always @* begin
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
       
        if(sq_y_t < 1)                              // collide with top display edge
            y_delta_next = SQUARE_VELOCITY_POS;     // change y direction(move down)
        else if(sq_y_b >400)// Y_MAX                  // collide with bottom display edge
            y_delta_next = SQUARE_VELOCITY_NEG;     // change y direction(move up)
        else if(sq_x_l < 1)                         // collide with left display edge
            x_delta_next = SQUARE_VELOCITY_POS;     // change x direction(move right)
        else if(sq_x_r > X_MAX)                     // collide with right display edge
            x_delta_next = SQUARE_VELOCITY_NEG;     // change x direction(move left)
    end
    
    wire sq1_on;
    assign sq1_on = (sq1_x_l <= x) && (x <= sq1_x_r) &&
                   (sq1_y_t <= y) && (y <= sq1_y_b);
                   
    // new square position
    assign sq1_x_next = (refresh_tick) ? sq1_x_reg + x1_delta_reg : sq1_x_reg;
    assign sq1_y_next = (refresh_tick) ? sq1_y_reg + y1_delta_reg : sq1_y_reg;
    
    // new square velocity 
    always @* begin
        x1_delta_next = x1_delta_reg;
        y1_delta_next = y1_delta_reg;
       
        if(sq1_y_t < 1)                              // collide with top display edge
            y1_delta_next = SQUARE_VELOCITY_POS;     // change y direction(move down)
        else if(sq1_y_b >400 )//Y_MAX)                     // collide with bottom display edge
            y1_delta_next = SQUARE_VELOCITY_NEG;     // change y direction(move up)
        else if(sq1_x_l < 1)                         // collide with left display edge
            x1_delta_next = SQUARE_VELOCITY_POS;     // change x direction(move right)
        else if(sq1_x_r > X_MAX)                     // collide with right display edge
            x1_delta_next = SQUARE_VELOCITY_NEG;     // change x direction(move left)
    end
    
    
    wire blk1_on;
    assign blk1_on = (blk1_x_l <= x) && (x <= blk1_x_r) &&
                   (blk1_y_t <= y) && (y <= blk1_y_b);
                   
    // new square position
    assign b1_x_next = (refresh_tick) ? blk1_x_reg + b1_x_delta_reg : blk1_x_reg;
    assign b1_y_next = (refresh_tick) ? blk1_y_reg + b1_y_delta_reg : blk1_y_reg;
    
    // new square velocity 
    always @* begin
        b1_x_delta_next = b1_x_delta_reg;
        b1_y_delta_next = b1_y_delta_reg;
       
        if(blk1_y_t < 1)                              // collide with top display edge
            b1_y_delta_next = 0;     // change y direction(move down)
        else if(blk1_y_b >400 )//Y_MAX)                     // collide with bottom display edge
            b1_y_delta_next = 0;     // change y direction(move up)
        else if(blk1_x_l < 1)                         // collide with left display edge
            b1_x_delta_next = 0;     // change x direction(move right)
        else if(blk1_x_r > X_MAX)                     // collide with right display edge
            b1_x_delta_next = 0;     // change x direction(move left)
    end
    
    wire blk2_on;
    assign blk2_on = (blk2_x_l <= x) && (x <= blk2_x_r) &&
                   (blk2_y_t <= y) && (y <= blk2_y_b);
                   
    // new square position
    assign b2_x_next = (refresh_tick) ? blk2_x_reg + b2_x_delta_reg : blk2_x_reg;
    assign b2_y_next = (refresh_tick) ? blk2_y_reg + b2_y_delta_reg : blk2_y_reg;
    
    // new square velocity 
    always @* begin
        b2_x_delta_next = b2_x_delta_reg;
        b2_y_delta_next = b2_y_delta_reg;
       
        if(blk2_y_t < 1)                              // collide with top display edge
            b2_y_delta_next = 0;     // change y direction(move down)
        else if(blk2_y_b >400 )//Y_MAX)                     // collide with bottom display edge
            b2_y_delta_next = 0;     // change y direction(move up)
        else if(blk2_x_l < 1)                         // collide with left display edge
            b2_x_delta_next = 0;     // change x direction(move right)
        else if(blk2_x_r > X_MAX)                     // collide with right display edge
            b2_x_delta_next = 0;     // change x direction(move left)
    end      
    
    // row and column wires for each rom
    wire [4:0] row1, col1;      // frog up
    wire [4:0] row2, col2;      // frog down
    wire [4:0] row3, col3;      // frog left
    wire [4:0] row4, col4;      // frog right

    
    // give value to rows and columns for roms
    // for frog roms
    assign col1 = x - x_frog_l;     // to obtain the column value, subtract rom left x position from x
    assign row1 = y - y_frog_t;     // to obtain the row value, subtract rom top y position from y
    assign col2 = x - x_frog_l;   
    assign row2 = y - y_frog_t;
    assign col3 = x - x_frog_l;   
    assign row3 = y - y_frog_t;
    assign col4 = x - x_frog_l;   
    assign row4 = y - y_frog_t;

    
    // Instantiate roms
    // frog direction roms
    frog_up_rom rom1(.clk(clk), .row(row1), .col(col1), .color_data(rom_data1));
    frog_down_rom rom2(.clk(clk), .row(row2), .col(col2), .color_data(rom_data2));
    frog_left_rom rom3(.clk(clk), .row(row3), .col(col3), .color_data(rom_data3));
    frog_right_rom rom4(.clk(clk), .row(row4), .col(col4), .color_data(rom_data4));
    
    
    // * ROM BOUNDARIES / STATUS SIGNALS *
    // frog rom data square boundaries
    assign x_frog_l = x_frog_reg;
    assign y_frog_t = y_frog_reg;
    assign x_frog_r = x_frog_l + FROG_SIZE - 1;
    assign y_frog_b = y_frog_t + FROG_SIZE - 1;
    
    // rom object status signal
    wire frog_on;
                    
    // pixel within rom square boundaries
    assign frog_on = (x_frog_l <= x) && (x <= x_frog_r) &&
                     (y_frog_t <= y) && (y <= y_frog_b);                              
 
    
                             
    // RGB color values for game board
    parameter GREEN  = 12'h0F0;
    parameter BLUE   = 12'h00F;
    parameter YELLOW = 12'hFF0; 
    parameter BLACK  = 12'h000;
    
    
    // Pixel Location Status Signals
    wire  top_black_on;
    wire lower_yellow_on;
    assign top_black_on = ((x >= 0)  && (x < 640)  &&  (y >= 0) && (y < 420));
    assign lower_yellow_on   = ((x >= 0) && (x < 640)  &&  (y >= 420) && (y < 480));
  
    
    
     
    // * MULTIPLEX FROG ROMS *
    wire [11:0] frog_rom;
    wire [11:0] rom_data1, rom_data2, rom_data3, rom_data4;
    
    reg [1:0] frog_select;
    
    
    
     always @(posedge clk or posedge reset) begin                                  
            if(reset || ~switch)
            frog_select = 2'b00;
        else if(refresh_tick)
            if(up)
                frog_select = 2'b00;
            else if(down)
                frog_select = 2'b01;
            else if(left)
                frog_select = 2'b10;
            else if(right)
                frog_select = 2'b11;
                 
  end
    
    assign frog_rom = (frog_select == 2'b00) ? rom_data1 :
                      (frog_select == 2'b01) ? rom_data2 :
                      (frog_select == 2'b10) ? rom_data3 :
                                               rom_data4 ;  
    

    // Game state handling
    always @* begin
     
        if (game_state ==  START_SCREEN_STATE && start_screen_flag) begin /////new
            // Start screen state
            rgb = 12'hFFF ; // Set the background color based on start screen flag
             // No collision on start screen
       end
        else if(game_state== GAME_OVER_STATE && game_over_flag) begin /////new
            rgb=12'hFFF;
       end 
      
        else begin
    
    // Set RGB output value based on status signals
    //always @*
        if(~video_on)
            rgb = 12'h000;
        
        else 
             if (frog_on && (sq_on || sq1_on /*|| sq2_on || blk1_on || blk2_on*/)) begin
            //collision_next=1;
            coll=1;
             end
             else if (y_frog_t<=(Y_TOP+10))begin
                   coll=1;
              end
        /* else if (frog_on && ( blk1_on || blk2_on)) begin      /////invalid format
              coll=1;
            end*/
            
             else if(sq_on ) /////////////////////
                rgb = SQ_RGB; 
                
        
             else if (sq1_on )    //else if
                rgb = SQ1_RGB;
            /* else if (sq2_on)
                rgb=SQ2_RGB;*/
             else if (blk1_on)
                rgb = BLK1_RGB;
             else if (blk2_on)
                rgb = BLK2_RGB;
                              
           
                else   begin   // yellow square
               // frog 
                 
			     if(frog_on && top_black_on) begin//lower_yellow_on)      // frog on lower yellow
			     	if(&frog_rom)  // check for white bitmap background value 12'hFFF
			     		rgb = BLACK;
			     	else
			     		rgb = frog_rom;
			     		end
			     else if(frog_on && lower_yellow_on) begin//lower_yellow_on)      // frog on lower yellow
			     	if(&frog_rom)  // check for white bitmap background value 12'hFFF
			     		rgb = YELLOW;
			     	else
			     		rgb = frog_rom;
			     end
                 else if(top_black_on) 
                     rgb = BLACK;
       
                 else if(lower_yellow_on)
                     rgb = YELLOW;
               end      
                end     
             end   
          assign collision_next=(coll==1)?1:0;     
endmodule
