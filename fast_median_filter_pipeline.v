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

module fast_median_filter_pipeline (
    input wire clk,
    input wire rst,
    input wire valid_in,
    
    input wire [7:0] p00, p01, p02,
    input wire [7:0] p10, p11, p12,
    input wire [7:0] p20, p21, p22,
    
    output reg [7:0] median_out,
    output reg valid_out
);

    // =========================================================================
    // Stage 1: Row Sorting
    // =========================================================================
    wire [7:0] r1_min, r1_mid, r1_max;
    wire [7:0] r2_min, r2_mid, r2_max;
    wire [7:0] r3_min, r3_mid, r3_max;
    
    sort3 sort_r1 (p00, p01, p02, r1_min, r1_mid, r1_max);
    sort3 sort_r2 (p10, p11, p12, r2_min, r2_mid, r2_max);
    sort3 sort_r3 (p20, p21, p22, r3_min, r3_mid, r3_max);
    
    // Stage 1 Pipeline Registers
    reg [7:0] reg_r1_min, reg_r1_mid, reg_r1_max;
    reg [7:0] reg_r2_min, reg_r2_mid, reg_r2_max;
    reg [7:0] reg_r3_min, reg_r3_mid, reg_r3_max;
    reg valid_d1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_r1_min <= 0; reg_r1_mid <= 0; reg_r1_max <= 0;
            reg_r2_min <= 0; reg_r2_mid <= 0; reg_r2_max <= 0;
            reg_r3_min <= 0; reg_r3_mid <= 0; reg_r3_max <= 0;
            valid_d1   <= 0;
        end else begin
            reg_r1_min <= r1_min; reg_r1_mid <= r1_mid; reg_r1_max <= r1_max;
            reg_r2_min <= r2_min; reg_r2_mid <= r2_mid; reg_r2_max <= r2_max;
            reg_r3_min <= r3_min; reg_r3_mid <= r3_mid; reg_r3_max <= r3_max;
            valid_d1   <= valid_in;
        end
    end

    // =========================================================================
    // Stage 2: Column Sorting
    // =========================================================================
    wire [7:0] c1_min, c1_mid, c1_max;
    wire [7:0] c2_min, c2_mid, c2_max;
    wire [7:0] c3_min, c3_mid, c3_max;
    
    sort3 sort_c1 (reg_r1_min, reg_r2_min, reg_r3_min, c1_min, c1_mid, c1_max);
    sort3 sort_c2 (reg_r1_mid, reg_r2_mid, reg_r3_mid, c2_min, c2_mid, c2_max);
    sort3 sort_c3 (reg_r1_max, reg_r2_max, reg_r3_max, c3_min, c3_mid, c3_max);
    
    // Stage 2 Pipeline Registers
    // We only register the values that are actually used in the final stage.
    reg [7:0] reg_c1_max, reg_c2_mid, reg_c3_min;
    reg valid_d2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_c1_max <= 0;
            reg_c2_mid <= 0;
            reg_c3_min <= 0;
            valid_d2   <= 0;
        end else begin
            reg_c1_max <= c1_max;
            reg_c2_mid <= c2_mid;
            reg_c3_min <= c3_min;
            valid_d2   <= valid_d1;
        end
    end

    // =========================================================================
    // Stage 3: Final Diagonal Sorting & Output
    // =========================================================================
    wire [7:0] diag_min, diag_mid, diag_max;
    
    sort3 sort_diag (reg_c1_max, reg_c2_mid, reg_c3_min, diag_min, diag_mid, diag_max);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            median_out <= 8'd0;
            valid_out  <= 1'b0;
        end else begin
            median_out <= diag_mid;
            valid_out  <= valid_d2;
        end
    end

endmodule