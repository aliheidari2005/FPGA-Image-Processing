`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2026 10:18:03 PM
// Design Name: 
// Module Name: tb_top_level
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



`timescale 1ns / 1ps

module tb_top_level();

    reg clk_25MHz;
    reg rst_pin;

    wire data_valid;
    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;

    top_level uut (
        .clk_25MHz(clk_25MHz),
        .rst_pin(rst_pin),
        .data_valid(data_valid),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    initial begin
        clk_25MHz = 0;
        forever #20 clk_25MHz = ~clk_25MHz;
    end

    initial begin
        $display("----------------------------------------");
        $display("Starting Top Level Simulation...");
        $display("----------------------------------------");
        
        rst_pin = 1;

        #200;
        rst_pin = 0;


        #50000; 

        $display("Simulation Finished.");
        $stop;
    end

 
    always @(posedge uut.clk_75MHz) begin
        if (data_valid) begin
            $display("Time: %0t ns | DATA VALID!", $time);
            $display(" [%3d, %3d, %3d] ", p00, p01, p02);
            $display(" [%3d, %3d, %3d] ", p10, p11, p12);
            $display(" [%3d, %3d, %3d] ", p20, p21, p22);
            $display("------------------------");
        end
    end

endmodule