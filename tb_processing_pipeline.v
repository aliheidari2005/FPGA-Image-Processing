`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2026 12:54:51 AM
// Design Name: 
// Module Name: tb_processing_pipeline
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


module tb_processing_pipeline();

    reg clk;
    reg rst;

    reg valid_in_med;
    reg [7:0] p00_in, p01_in, p02_in;
    reg [7:0] p10_in, p11_in, p12_in;
    reg [7:0] p20_in, p21_in, p22_in;
    
    wire med_valid_out;
    wire [7:0] med_pixel_out;
    
    wire lb_valid_out;
    wire [7:0] lb_p00, lb_p01, lb_p02;
    wire [7:0] lb_p10, lb_p11, lb_p12;
    wire [7:0] lb_p20, lb_p21, lb_p22;
    
    wire lap_valid_out;
    wire [7:0] lap_pixel_out;
    
    fast_median_filter U_MEDIAN (
        .clk(clk), .rst(rst),
        .valid_in(valid_in_med),
        .p00(p00_in), .p01(p01_in), .p02(p02_in),
        .p10(p10_in), .p11(p11_in), .p12(p12_in),
        .p20(p20_in), .p21(p21_in), .p22(p22_in),
        .median_out(med_pixel_out),
        .valid_out(med_valid_out)
    );

    line_buffer_3x3 #(
        .IMG_WIDTH(256)
    ) U_LINE_BUFFER (
        .clk(clk), .rst(rst),
        .valid_in(med_valid_out),
        .pixel_in(med_pixel_out),
        .valid_out(lb_valid_out),
        .p00(lb_p00), .p01(lb_p01), .p02(lb_p02),
        .p10(lb_p10), .p11(lb_p11), .p12(lb_p12),
        .p20(lb_p20), .p21(lb_p21), .p22(lb_p22)
    );

    laplace_filter U_LAPLACE (
        .clk(clk), .rst(rst),
        .valid_in(lb_valid_out),
        .p00(lb_p00), .p01(lb_p01), .p02(lb_p02),
        .p10(lb_p10), .p11(lb_p11), .p12(lb_p12),
        .p20(lb_p20), .p21(lb_p21), .p22(lb_p22),
        .edge_pixel(lap_pixel_out),
        .valid_out(lap_valid_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    reg [7:0] test_img [0:255][0:255];
    integer r, c;
    integer file_id;

    initial begin
        for (r = 0; r < 256; r = r + 1) begin
            for (c = 0; c < 256; c = c + 1) begin
                if (r > 64 && r < 192 && c > 64 && c < 192)
                    test_img[r][c] = 8'd200;
                else
                    test_img[r][c] = 8'd50;
            end
        end
        
        test_img[70][70] = 8'd255;
        test_img[80][80] = 8'd0;
        test_img[100][100] = 8'd255;
        test_img[50][50] = 8'd0;
        
        file_id = $fopen("output_img.txt", "w");
        if (file_id == 0) begin
            $display("ERROR: Cannot open output file!");
            $finish;
        end
        
        rst = 1;
        valid_in_med = 0;
        #20;
        rst = 0;
        #10;
        
        $display("Starting Pipeline Simulation...");

        for (r = 0; r < 256; r = r + 1) begin
            for (c = 0; c < 256; c = c + 1) begin
                p00_in = (r>0 && c>0) ? test_img[r-1][c-1] : 8'd0;
                p01_in = (r>0)        ? test_img[r-1][c]   : 8'd0;
                p02_in = (r>0 && c<255)? test_img[r-1][c+1]: 8'd0;
                
                p10_in = (c>0)        ? test_img[r][c-1]   : 8'd0;
                p11_in =                test_img[r][c];
                p12_in = (c<255)      ? test_img[r][c+1]   : 8'd0;
                
                p20_in = (r<255 && c>0)? test_img[r+1][c-1]: 8'd0;
                p21_in = (r<255)      ? test_img[r+1][c]   : 8'd0;
                p22_in = (r<255 && c<255)? test_img[r+1][c+1]: 8'd0;
                
                valid_in_med = 1;
                #10;
            end
        end
        valid_in_med = 0;
        
        #8000; 
        
        $fclose(file_id);
        $display("Simulation Finished Successfully! Results saved to output_img.txt");
        $finish;
    end

    integer out_col = 0;
    
    always @(posedge clk) begin
        if (lap_valid_out) begin
            $fwrite(file_id, "%-3d ", lap_pixel_out);
            
            out_col = out_col + 1;
            
            if (out_col == 256) begin
                $fwrite(file_id, "\n");
                out_col = 0;
            end
        end
    end

endmodule