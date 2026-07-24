`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 11:41:32 PM
// Design Name: 
// Module Name: sort3
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
module sort3 (
    input wire [7:0] a, b, c,
    output wire [7:0] min, mid, max
);
    // Find min and max of a and b
    wire [7:0] min_ab = (a < b) ? a : b;
    wire [7:0] max_ab = (a > b) ? a : b;
    
    // Compare with c to find absolute min and max
    assign min = (min_ab < c) ? min_ab : c;
    assign max = (max_ab > c) ? max_ab : c;
    
    // Pure comparator logic for the middle value
    assign mid = (min_ab > c) ? min_ab : 
                 (max_ab < c) ? max_ab : c;
endmodule