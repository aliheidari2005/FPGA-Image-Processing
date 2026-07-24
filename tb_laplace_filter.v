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


module tb_laplace_filter();

    reg clk;
    reg rst;
    reg valid_in;
    reg [7:0] p00, p01, p02;
    reg [7:0] p10, p11, p12;
    reg [7:0] p20, p21, p22;
    
    wire [7:0] edge_pixel;
    wire valid_out;

    laplace_filter uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .edge_pixel(edge_pixel),
        .valid_out(valid_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        valid_in = 0;
        #20;
        rst = 0;
        #10;
        
        p00=100; p01=100; p02=100;
        p10=100; p11=100; p12=100;
        p20=100; p21=100; p22=100;
        valid_in = 1;
        #10;
        
        p00=100; p01=100; p02=100;
        p10=100; p11=50;  p12=100;
        p20=100; p21=100; p22=100;
        valid_in = 1;
        #10;
        
        p00=102; p01=102; p02=102;
        p10=102; p11=100; p12=102;
        p20=102; p21=102; p22=102;
        valid_in = 1;
        #10;
        
        valid_in = 0;
        #30; 
        
        $finish;
    end

    always @(posedge clk) begin
        if (valid_out) begin
            $display("Time: %0t ns | Laplace Output: %3d", $time, edge_pixel);
        end
    end

endmodule