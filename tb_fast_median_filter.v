`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 11:46:35 PM
// Design Name: 
// Module Name: tb_fast_median_filter
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


module tb_fast_median_filter();

    reg clk;
    reg rst;
    reg valid_in;
    reg [7:0] p00, p01, p02;
    reg [7:0] p10, p11, p12;
    reg [7:0] p20, p21, p22;
    
    wire [7:0] median_out;
    wire valid_out;

    fast_median_filter uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .median_out(median_out),
        .valid_out(valid_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        valid_in = 0;
        p00=0; p01=0; p02=0;
        p10=0; p11=0; p12=0;
        p20=0; p21=0; p22=0;
        
        #20;
        rst = 0;
        #10;
        
        p00 = 8'd255; p01 = 8'd100; p02 = 8'd105;
        p10 = 8'd110; p11 = 8'd0;   p12 = 8'd115;
        p20 = 8'd108; p21 = 8'd112; p22 = 8'd120;
        valid_in = 1;
        
        #10;
        valid_in = 0;
        
        #20;
        
        if (valid_out && median_out == 8'd110) begin
            $display("SUCCESS: Test Passed! Median is %d (Expected: 110)", median_out);
        end else begin
            $display("ERROR: Test Failed! Median is %d (Expected: 110)", median_out);
        end
        
        #50;
        $finish;
    end

endmodule