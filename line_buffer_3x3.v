`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2026 12:06:59 AM
// Design Name: 
// Module Name: line_buffer_3x3
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


module line_buffer_3x3 #(
    parameter IMG_WIDTH = 256
)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [7:0] pixel_in,
    
    output reg valid_out,
    output reg [7:0] p00, p01, p02,
    output reg [7:0] p10, p11, p12,
    output reg [7:0] p20, p21, p22
);
    reg [7:0] line_buf_1 [0:IMG_WIDTH-1];
    reg [7:0] line_buf_2 [0:IMG_WIDTH-1];
    
    integer i;
    reg [15:0] pixel_cnt;
    
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_cnt <= 16'd0;
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
            
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line_buf_1[i] <= 8'd0;
                line_buf_2[i] <= 8'd0;
            end
        end else begin
            if (valid_in) begin
                for (i = IMG_WIDTH-1; i > 0; i = i - 1) begin
                    line_buf_1[i] <= line_buf_1[i-1];
                    line_buf_2[i] <= line_buf_2[i-1];
                end
                
                line_buf_1[0] <= pixel_in;
                
                line_buf_2[0] <= line_buf_1[IMG_WIDTH-1];
                
                p22 <= pixel_in;
                p21 <= p22;
                p20 <= p21;
                
                p12 <= line_buf_1[IMG_WIDTH-1];
                p11 <= p12;
                p10 <= p11;
                
                p02 <= line_buf_2[IMG_WIDTH-1];
                p01 <= p02;
                p00 <= p01;
                
                if (pixel_cnt >= (2 * IMG_WIDTH + 2)) begin
                    valid_out <= 1'b1;
                end else begin
                    valid_out <= 1'b0;
                    pixel_cnt <= pixel_cnt + 1'b1;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule