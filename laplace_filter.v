`timescale 1ns / 1ps

module laplace_filter (
    input wire clk,
    input wire rst,
    input wire valid_in,
    
    // 3x3 Window Inputs
    input wire [7:0] p00, p01, p02,
    input wire [7:0] p10, p11, p12,
    input wire [7:0] p20, p21, p22,
    
    output reg [7:0] edge_pixel,
    output reg valid_out
);

    // =========================================================================
    // Stage 1: Partial Sums and Center Pixel Scaling (Binary Tree)
    // =========================================================================
    // Pipeline registers for Stage 1
    reg signed [10:0] sum_group1; // Sum of first 4 neighbors
    reg signed [10:0] sum_group2; // Sum of remaining 4 neighbors
    reg signed [11:0] center_val; // Scaled center pixel
    reg valid_s1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_group1 <= 0;
            sum_group2 <= 0;
            center_val <= 0;
            valid_s1   <= 0;
        end else begin
            // Group 1: Sum of top row and middle-left pixel
            sum_group1 <= ($signed({3'b0, p00}) + $signed({3'b0, p01})) + 
                          ($signed({3'b0, p02}) + $signed({3'b0, p10}));
                          
            // Group 2: Sum of middle-right pixel and bottom row
            sum_group2 <= ($signed({3'b0, p12}) + $signed({3'b0, p20})) + 
                          ($signed({3'b0, p21}) + $signed({3'b0, p22}));
                          
            // Center pixel multiplied by 8 (implemented as shift-left by 3)
            center_val <= $signed({4'b0, p11}) <<< 3;
            
            // Pass the valid signal to the next stage
            valid_s1   <= valid_in;
        end
    end

    // =========================================================================
    // Stage 2: Final Summation and Threshold Application
    // =========================================================================
    // Combinational final sum: (Sum of all 8 neighbors) - (8 * center)
    wire signed [12:0] total_sum;
    assign total_sum = (sum_group1 + sum_group2) - center_val;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            edge_pixel <= 0;
            valid_out  <= 0;
        end else begin
            if (valid_s1) begin
                // Apply edge detection threshold (Threshold = 30)
                if (total_sum >= 13'sd30)
                    edge_pixel <= 8'd255; // Edge detected (White)
                else
                    edge_pixel <= 8'd0;   // No edge (Black)
                    
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule