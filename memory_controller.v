`timescale 1ns / 1ps

module memory_controller (
    input wire clk_75MHz,       // 75MHz fast clock
    input wire rst,             // Active high synchronous reset
    input wire [7:0] rom_data,  // 8-bit data from Synchronous ROM (1-cycle latency)
    output reg [13:0] rom_addr, // 14-bit address for ROM (128x128=16384)
    output reg data_valid,      // High ONLY for 1 cycle when a valid 3x3 window is formed
    
    // 3x3 Matrix outputs
    output reg [7:0] p00, output reg [7:0] p01, output reg [7:0] p02,
    output reg [7:0] p10, output reg [7:0] p11, output reg [7:0] p12,
    output reg [7:0] p20, output reg [7:0] p21, output reg [7:0] p22
);

    reg [1:0] phase;       // Phase counter (0, 1, 2)
    reg [6:0] row_cnt;     // Current scanning row (0 to 127)
    reg [6:0] col_base;    // Starting column for the current 3-pixel width (0 to 125)
    
    reg [7:0] reg_p0;      // Buffer for the 1st pixel of the row
    reg [7:0] reg_p1;      // Buffer for the 2nd pixel of the row
    
    // Counters and flags for strictly 1-cycle data_valid pulse
    reg [1:0] invalid_cnt; // Tracks how many rows need to be scanned before a window is valid
    reg strip_done;        // Flag to indicate end of a vertical strip

    // 1. Synchronous Phase Management
    always @(posedge clk_75MHz or posedge rst) begin
        if (rst) begin
            phase <= 2'b0;
        end else begin
            if (phase == 2'd2)
                phase <= 2'b0;
            else
                phase <= phase + 1'b1;
        end
    end

    // 2. Vertical Scanning, Pipeline & Validation Logic
    always @(posedge clk_75MHz or posedge rst) begin
        if (rst) begin
            row_cnt <= 7'b0;
            col_base <= 7'b0;
            rom_addr <= 14'b0;
            reg_p0 <= 8'b0;
            reg_p1 <= 8'b0;
            data_valid <= 1'b0;
            
            invalid_cnt <= 2'd3; // Initially, the first 3 rows form no valid window
            strip_done <= 1'b0;
            
            p00 <= 8'b0; p01 <= 8'b0; p02 <= 8'b0;
            p10 <= 8'b0; p11 <= 8'b0; p12 <= 8'b0;
            p20 <= 8'b0; p21 <= 8'b0; p22 <= 8'b0;
        end else begin
            case (phase)
                2'd0: begin
                    // Phase 0: Form the Top Row and perform VERTICAL SHIFT
                    p00 <= reg_p0; p01 <= reg_p1; p02 <= rom_data; 
                    p10 <= p00;    p11 <= p01;    p12 <= p02;      
                    p20 <= p10;    p21 <= p11;    p22 <= p12;      
                    
                    // Generate a strict 1-cycle valid pulse
                    if (invalid_cnt == 2'd0) begin
                        data_valid <= 1'b1;
                    end else begin
                        data_valid <= 1'b0;
                        invalid_cnt <= invalid_cnt - 1'b1;
                    end

                    // If we just finished moving to a new vertical strip, reset the invalid counter
                    if (strip_done) begin
                        invalid_cnt <= 2'd2; // Need 2 more rows to form the next valid window
                        strip_done <= 1'b0;
                    end

                    // Pipeline: Request Pixel 2 for CURRENT row
                    rom_addr <= {row_cnt, col_base + 7'd1}; 
                end
                
                2'd1: begin
                    reg_p0 <= rom_data; 
                    data_valid <= 1'b0; // Turn off immediately to ensure it's a pulse
                    
                    // Pipeline: Request Pixel 3 for CURRENT row
                    rom_addr <= {row_cnt, col_base + 7'd2}; 
                end
                
                2'd2: begin
                    reg_p1 <= rom_data; 
                    data_valid <= 1'b0; // Ensure data_valid is off
                    
                    // Update scanning coordinates (Moving DOWN the image)
                    if (row_cnt == 7'd127) begin
                        row_cnt <= 7'b0;
                        strip_done <= 1'b1; // Trigger flag for Phase 0
                        
                        // Move to the next 3-pixel wide vertical strip
                        if (col_base == 7'd125) 
                            col_base <= 7'b0;
                        else
                            col_base <= col_base + 1'b1;
                            
                        // Pipeline: Request Pixel 1 for the NEW vertical strip (Row 0)
                        rom_addr <= {7'b0, (col_base == 7'd125) ? 7'b0 : col_base + 1'b1};
                    end else begin
                        row_cnt <= row_cnt + 1'b1; 
                        
                        // Pipeline: Request Pixel 1 for the NEXT row down
                        rom_addr <= {row_cnt + 1'b1, col_base};
                    end
                end
            endcase
        end
    end

endmodule