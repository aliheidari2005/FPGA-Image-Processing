`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2026 12:44:36 AM
// Design Name: 
// Module Name: laplace_filter
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


module laplace_filter (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [7:0] p00, p01, p02,
    input wire [7:0] p10, p11, p12,
    input wire [7:0] p20, p21, p22,
    output reg [7:0] edge_pixel,
    output reg valid_out
);

    reg signed [10:0] sum_group1;
    reg signed [10:0] sum_group2;
    reg signed [11:0] center_val;
    reg valid_s1;

    wire signed [12:0] total_sum;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_group1 <= 0;
            sum_group2 <= 0;
            center_val <= 0;
            valid_s1   <= 0;
        end else begin
            sum_group1 <= ($signed({3'b0, p00}) + $signed({3'b0, p01})) + 
                          ($signed({3'b0, p02}) + $signed({3'b0, p10}));
                          
            sum_group2 <= ($signed({3'b0, p12}) + $signed({3'b0, p20})) + 
                          ($signed({3'b0, p21}) + $signed({3'b0, p22}));
                          
            center_val <= $signed({4'b0, p11}) <<< 3;
            valid_s1   <= valid_in;
        end
    end

    assign total_sum = (sum_group1 + sum_group2) - center_val;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            edge_pixel <= 0;
            valid_out  <= 0;
        end else begin
            if (valid_s1) begin
                if (total_sum >= 13'sd30)
                    edge_pixel <= 8'd255;
                else
                    edge_pixel <= 8'd0;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule