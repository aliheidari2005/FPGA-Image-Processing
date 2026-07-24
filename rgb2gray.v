`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:45:40 07/24/2026 
// Design Name: 
// Module Name:    rgb2gray 
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
module rgb2gray (
    input  wire [23:0] rgb_in,   // {R[7:0], G[7:0], B[7:0]}
    output wire [7:0]  gray_out
);

    // 1. Extract color channels
    wire [7:0] r = rgb_in[23:16];
    wire [7:0] g = rgb_in[15:8];
    wire [7:0] b = rgb_in[7:0];

    // 2. Perform scaled integer multiplication
    // A 16-bit wire is used because the max value is (255*77 + 255*150 + 255*29) = 65280
    wire [15:0] gray_calc = (r * 8'd77) + (g * 8'd150) + (b * 8'd29);

    // 3. Divide by 256 by discarding the lower 8 bits (equivalent to >> 8)
    assign gray_out = gray_calc[15:8];

endmodule