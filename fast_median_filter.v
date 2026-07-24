`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 11:43:11 PM
// Design Name: 
// Module Name: fast_median_filter
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


module fast_median_filter (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [7:0] p00, p01, p02,
    input wire [7:0] p10, p11, p12,
    input wire [7:0] p20, p21, p22,
    output reg [7:0] median_out,
    output reg valid_out
);
    wire [7:0] r1_min, r1_mid, r1_max;
    wire [7:0] r2_min, r2_mid, r2_max;
    wire [7:0] r3_min, r3_mid, r3_max;
    
    sort3 sort_r1 (p00, p01, p02, r1_min, r1_mid, r1_max);
    sort3 sort_r2 (p10, p11, p12, r2_min, r2_mid, r2_max);
    sort3 sort_r3 (p20, p21, p22, r3_min, r3_mid, r3_max);
    
    wire [7:0] c1_min, c1_mid, c1_max;
    wire [7:0] c2_min, c2_mid, c2_max;
    wire [7:0] c3_min, c3_mid, c3_max;
    
    sort3 sort_c1 (r1_min, r2_min, r3_min, c1_min, c1_mid, c1_max);
    sort3 sort_c2 (r1_mid, r2_mid, r3_mid, c2_min, c2_mid, c2_max);
    sort3 sort_c3 (r1_max, r2_max, r3_max, c3_min, c3_mid, c3_max);
    
    wire [7:0] diag_min, diag_mid, diag_max;
    sort3 sort_diag (c1_max, c2_mid, c3_min, diag_min, diag_mid, diag_max);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            median_out <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            median_out <= diag_mid;
            valid_out <= valid_in;
        end
    end
endmodule