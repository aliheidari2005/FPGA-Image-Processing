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
    wire [7:0] min_ab = (a < b) ? a : b;
    wire [7:0] max_ab = (a > b) ? a : b;
    
    assign min = (min_ab < c) ? min_ab : c;
    assign max = (max_ab > c) ? max_ab : c;
    
    assign mid = (a + b + c) - min - max; 
endmodule