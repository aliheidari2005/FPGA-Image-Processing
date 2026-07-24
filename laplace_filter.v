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
    wire signed [11:0] sum_wire;
    
    assign sum_wire = $signed({4'b0, p00}) + $signed({4'b0, p01}) + $signed({4'b0, p02}) +
                      $signed({4'b0, p10}) +                        $signed({4'b0, p12}) +
                      $signed({4'b0, p20}) + $signed({4'b0, p21}) + $signed({4'b0, p22}) -
                      ($signed({4'b0, p11}) <<< 3);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            edge_pixel <= 8'd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            if (sum_wire >= 12'sd30) begin
                edge_pixel <= 8'd255;
            end else begin
                edge_pixel <= 8'd0;
            end
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule