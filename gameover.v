`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2023 11:55:41 AM
// Design Name: 
// Module Name: gameover
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




module gameover(pixel_x, pixel_y, flag);
  input [9:0] pixel_x;
  input [9:0] pixel_y;
  output flag;
  
  reg [0:29] startscrn [29:0];
  
  wire [5:0] x = pixel_x[9:4] - 5;
  wire [5:0] y = pixel_y[9:4];
  assign flag = startscrn[y][x];
 
  
  initial begin
    // Clear the start screen

    // Display "Game Over" message
    startscrn[0]  = 30'b000000000000000000000000000000; //0
    startscrn[1]  = 30'b000000000000000000000000000000; //1
    startscrn[2]  = 30'b000000000000000000000000000000; //2
    startscrn[3]  = 30'b000000000000000000000000000000; //3
    startscrn[4]  = 30'b000000000000000000000000000000; //4
    startscrn[5]  = 30'b000000000000000000000000000000; //5
    startscrn[6]  = 30'b000000000000000000000000000000; //6
    startscrn[7]  = 30'b000000000000000000000000000000; //7
    startscrn[8] = 30'b011110001110011100011101111100; //15
    startscrn[9] = 30'b011000011011011010101101100000; //16
    startscrn[10] = 30'b011000011011011001001101111100; //17
    startscrn[11] = 30'b011011011111011000001101100000; //18
    startscrn[12] = 30'b011011011011011000001101100000; //19
    startscrn[13] = 30'b011111011011011000001101111100;
    startscrn[14] = 30'b000000000000000000000000000000; //14
    startscrn[15] = 30'b000111110110110111110011110000; //15
    startscrn[16] = 30'b000110110110110110000010010000; //16
    startscrn[17] = 30'b000110110110110111110011110000; //17
    startscrn[18] = 30'b000110110110110110000011000000; //18
    startscrn[19] = 30'b000110110110110110000010100000; //19
    startscrn[20] = 30'b000111110011100111110010010000; //20
    startscrn[21] = 30'b000000000000000000000000000000; //21
    startscrn[22] = 30'b000000000000000000000000000000; //22
    startscrn[23] = 30'b000000000000000000000000000000; //23
    startscrn[24] = 30'b000000000000000000000000000000; //24
    startscrn[25] = 30'b000000000000000000000000000000; //25
    startscrn[26] = 30'b000000000000000000000000000000; //26
    startscrn[27] = 30'b000000000000000000000000000000; //27
    startscrn[28] = 30'b000000000000000000000000000000; //28
    startscrn[29] = 30'b000000000000000000000000000000; //29
  
    
  end
endmodule
