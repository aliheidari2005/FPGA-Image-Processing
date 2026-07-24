`timescale 1ns / 1ps

module rom_reader #(
    parameter IMG_WIDTH     = 128,
    parameter IMG_HEIGHT    = 128,
    parameter ADDR_WIDTH    = 14,
    parameter IN_DATA_WIDTH = 24   // Set to 24 for RGB, 8 for Grayscale
)(
    input wire clk,
    input wire rst,
    input wire enable,                
    
    // --- ROM Interface ---
    output reg [ADDR_WIDTH-1:0] rom_addr,
    input  wire [IN_DATA_WIDTH-1:0] rom_data,  
    
    // --- Downstream Interface ---
    output reg [7:0] pixel_out,
    output reg       valid_out
);

    localparam MAX_ADDR = (IMG_WIDTH * IMG_HEIGHT) - 1;

    // Pipeline tracking for 1-cycle ROM latency
    reg req_valid_d1;
    reg req_valid_d2;

    wire [7:0] gray_comb;

    // ==============================================================================
    // Conditional Data Processing (Generate Block)
    // ==============================================================================
    generate
        if (IN_DATA_WIDTH == 24) begin : gen_rgb2gray
            // If input is 24-bit, instantiate the RGB to Grayscale converter
            rgb2gray u_rgb2gray (
                .rgb_in(rom_data),
                .gray_out(gray_comb)
            );
        end else begin : gen_passthrough
            // If input is already 8-bit (or anything else), pass the lower 8 bits directly
            assign gray_comb = rom_data[7:0];
        end
    endgenerate

    // ==============================================================================
    // Stage 1: Address Generation & Latency Pipeline
    // ==============================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rom_addr     <= {ADDR_WIDTH{1'b0}};
            req_valid_d1 <= 1'b0;
            req_valid_d2 <= 1'b0;
        end else begin
            if (enable) begin
                req_valid_d1 <= 1'b1;
                
                if (rom_addr == MAX_ADDR) begin
                    rom_addr <= {ADDR_WIDTH{1'b0}};
                end else begin
                    rom_addr <= rom_addr + 1'b1;
                end
            end else begin
                req_valid_d1 <= 1'b0;
            end
            
            // Second delay stage to match the synchronous ROM read latency
            req_valid_d2 <= req_valid_d1;
        end
    end

    // ==============================================================================
    // Stage 2: Data Capture 
    // ==============================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_out <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            // Now valid_out safely aligns with when rom_data is stable and ready
            valid_out <= req_valid_d2;
            
            if (req_valid_d2) begin
                pixel_out <= gray_comb;
            end
        end
    end

endmodule