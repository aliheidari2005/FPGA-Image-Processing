`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2026 12:16:46 AM
// Design Name: 
// Module Name: tb_line_buffer_3x3
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


module tb_line_buffer_3x3();

    reg clk;
    reg rst;
    reg valid_in;
    reg [7:0] pixel_in;
    
    wire valid_out;
    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;

    line_buffer_3x3 #(
        .IMG_WIDTH(128)
    ) uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .pixel_in(pixel_in),
        .valid_out(valid_out),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;

    initial begin
        rst = 1;
        valid_in = 0;
        pixel_in = 0;
        
        #20;
        rst = 0;
        #10;
        
        $display("========================================");
        $display("Starting Line Buffer Simulation...");
        $display("========================================");
        
        for (i = 1; i <= 384; i = i + 1) begin
            valid_in = 1;
            pixel_in = i[7:0]; 
            #10;
        end
        
        valid_in = 0;
        
        #100;
        $display("========================================");
        $display("Simulation Finished.");
        $display("========================================");
        $finish;
    end

    integer print_count = 0;
    
    always @(posedge clk) begin
        if (valid_out && print_count < 5) begin
            $display("Time: %0t ns | Window Valid!", $time);
            $display("  [%3d, %3d, %3d]", p00, p01, p02);
            $display("  [%3d, %3d, %3d]", p10, p11, p12);
            $display("  [%3d, %3d, %3d]", p20, p21, p22);
            $display("----------------------------------------");
            
            print_count = print_count + 1;
        end
    end

endmodule