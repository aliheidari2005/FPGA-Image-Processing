`timescale 1ns / 1ps

module window_generator_3x3 #(
    parameter IMG_WIDTH   = 128,  
    parameter IMG_HEIGHT  = 128,  
    parameter DATA_WIDTH  = 8,    
    parameter COORD_WIDTH = 7     
)(
    input wire clk,
    input wire rst,
    
    input wire [DATA_WIDTH-1:0] pixel_in,
    input wire valid_in,
    
    output reg window_valid,
    
    output wire [DATA_WIDTH-1:0] p00, output wire [DATA_WIDTH-1:0] p01, output wire [DATA_WIDTH-1:0] p02,
    output wire [DATA_WIDTH-1:0] p10, output wire [DATA_WIDTH-1:0] p11, output wire [DATA_WIDTH-1:0] p12,
    output wire [DATA_WIDTH-1:0] p20, output wire [DATA_WIDTH-1:0] p21, output wire [DATA_WIDTH-1:0] p22
);

    // --- Line Buffers ---
    reg [DATA_WIDTH-1:0] lb0 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] lb1 [0:IMG_WIDTH-1];
    
    reg [DATA_WIDTH-1:0] lb0_out;
    reg [DATA_WIDTH-1:0] lb1_out;

    // --- Input Tracking & Auto-Flush Logic ---
    reg [COORD_WIDTH-1:0] in_col;   
    reg [COORD_WIDTH-1:0] in_row;   
    reg [COORD_WIDTH:0]   flush_cnt; // 1 bit larger to hold (IMG_WIDTH + 1)
    
    // Combine real input with internal flush signals
    wire effective_valid = valid_in | (flush_cnt > 0);
    wire [DATA_WIDTH-1:0] effective_pixel = valid_in ? pixel_in : {DATA_WIDTH{1'b0}};

    // --- Pipeline Registers ---
    reg [COORD_WIDTH-1:0] in_col_d1;
    reg [DATA_WIDTH-1:0]  pixel_in_d1;
    reg valid_d1;

    // --- Output Synchronization & Delay ---
    reg [COORD_WIDTH:0]   delay_cnt; 
    reg [COORD_WIDTH-1:0] out_col;
    reg [COORD_WIDTH-1:0] out_row;

    // --- Internal Window Registers ---
    reg [DATA_WIDTH-1:0] int_p00, int_p01, int_p02;
    reg [DATA_WIDTH-1:0] int_p10, int_p11, int_p12;
    reg [DATA_WIDTH-1:0] int_p20, int_p21, int_p22;

    // ==============================================================================
    // Stage 1: Input Addressing, Flush Generation & Line Buffer Read
    // ==============================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_col      <= {COORD_WIDTH{1'b0}};
            in_row      <= {COORD_WIDTH{1'b0}};
            flush_cnt   <= 0;
            in_col_d1   <= {COORD_WIDTH{1'b0}};
            pixel_in_d1 <= {DATA_WIDTH{1'b0}};
            valid_d1    <= 1'b0;
        end else begin
            if (effective_valid) begin
                // Frame end detection: Trigger flush when the last real pixel enters
                if (in_col == IMG_WIDTH - 1 && in_row == IMG_HEIGHT - 1) begin
                    flush_cnt <= IMG_WIDTH + 1;
                end else if (flush_cnt > 0) begin
                    flush_cnt <= flush_cnt - 1'b1;
                end

                // Track input coordinates to know when the frame ends
                if (in_col == IMG_WIDTH - 1) begin
                    in_col <= {COORD_WIDTH{1'b0}};
                    if (in_row == IMG_HEIGHT - 1)
                        in_row <= {COORD_WIDTH{1'b0}};
                    else
                        in_row <= in_row + 1'b1;
                end else begin
                    in_col <= in_col + 1'b1;
                end
                
                lb0_out <= lb0[in_col];
                lb1_out <= lb1[in_col];
                
                pixel_in_d1 <= effective_pixel;
                in_col_d1   <= in_col;
                valid_d1    <= 1'b1;
            end else begin
                valid_d1 <= 1'b0;
            end
        end
    end

    // ==============================================================================
    // Stage 2: Window Shift & Output Coordinate Tracking
    // ==============================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            window_valid <= 1'b0;
            delay_cnt    <= 0;
            out_col      <= {COORD_WIDTH{1'b0}};
            out_row      <= {COORD_WIDTH{1'b0}};
            
            int_p00 <= 0; int_p01 <= 0; int_p02 <= 0;
            int_p10 <= 0; int_p11 <= 0; int_p12 <= 0;
            int_p20 <= 0; int_p21 <= 0; int_p22 <= 0;
        end else begin
            if (valid_d1) begin
                lb0[in_col_d1] <= pixel_in_d1;
                lb1[in_col_d1] <= lb0_out;

                int_p00 <= int_p01; int_p01 <= int_p02; int_p02 <= lb1_out;       
                int_p10 <= int_p11; int_p11 <= int_p12; int_p12 <= lb0_out;       
                int_p20 <= int_p21; int_p21 <= int_p22; int_p22 <= pixel_in_d1;   

                // Delay output to align int_p11 with Output(0,0)
                if (delay_cnt < IMG_WIDTH + 1) begin
                    delay_cnt <= delay_cnt + 1'b1;
                    window_valid <= 1'b0;
                end else begin
                    window_valid <= 1'b1;
                    
                    if (window_valid) begin
                        if (out_col == IMG_WIDTH - 1) begin
                            out_col <= {COORD_WIDTH{1'b0}};
                            
                            if (out_row == IMG_HEIGHT - 1) begin
                                out_row <= {COORD_WIDTH{1'b0}};
                                delay_cnt <= 0; // Frame perfectly complete. Reset for next frame.
                            end else begin
                                out_row <= out_row + 1'b1;
                            end
                            
                        end else begin
                            out_col <= out_col + 1'b1;
                        end
                    end
                end
            end else begin
                window_valid <= 1'b0;
            end
        end
    end

    // ==============================================================================
    // Boundary Masking (Zero-Padding via Output Coordinates)
    // ==============================================================================
    assign p00 = (out_row == 0 || out_col == 0)             ? {DATA_WIDTH{1'b0}} : int_p00;
    assign p01 = (out_row == 0)                             ? {DATA_WIDTH{1'b0}} : int_p01;
    assign p02 = (out_row == 0 || out_col == IMG_WIDTH - 1) ? {DATA_WIDTH{1'b0}} : int_p02;

    assign p10 = (out_col == 0)                             ? {DATA_WIDTH{1'b0}} : int_p10;
    assign p11 = int_p11;                                   
    assign p12 = (out_col == IMG_WIDTH - 1)                 ? {DATA_WIDTH{1'b0}} : int_p12;

    assign p20 = (out_row == IMG_HEIGHT - 1 || out_col == 0)             ? {DATA_WIDTH{1'b0}} : int_p20;
    assign p21 = (out_row == IMG_HEIGHT - 1)                             ? {DATA_WIDTH{1'b0}} : int_p21;
    assign p22 = (out_row == IMG_HEIGHT - 1 || out_col == IMG_WIDTH - 1) ? {DATA_WIDTH{1'b0}} : int_p22;

endmodule