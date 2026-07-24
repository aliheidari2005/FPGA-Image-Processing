`timescale 1ns / 1ps

module rom_reader #(
    parameter IMG_WIDTH     = 128,
    parameter IMG_HEIGHT    = 128,
    parameter ADDR_WIDTH    = 14,
    parameter IN_DATA_WIDTH = 24   // Set to 24 for RGB, 8 for Grayscale
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,               
    
    // --- ROM Interface ---
    output reg  [ADDR_WIDTH-1:0]    rom_addr,
    input  wire [IN_DATA_WIDTH-1:0] rom_data,  
    
    // --- Downstream Interface ---
    output wire [7:0] pixel_out,
    output wire       valid_out
);

    localparam MAX_ADDR = (IMG_WIDTH * IMG_HEIGHT) - 1;

    // Pipeline tracking for address generation and ROM latency
    reg req_valid_d1;
    reg req_valid_d2;
    reg req_valid_d3;

    reg [IN_DATA_WIDTH-1:0] rom_data_reg;

    // ==============================================================================
    // Stage 1 & 2: Address Generation, ROM Latency, and Input Registration
    // ==============================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rom_addr     <= {ADDR_WIDTH{1'b0}};
            req_valid_d1 <= 1'b0;
            req_valid_d2 <= 1'b0;
            req_valid_d3 <= 1'b0;
            rom_data_reg <= {IN_DATA_WIDTH{1'b0}};
        end else begin
            // Stage 1: Address Generation
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
            
            // Stage 2: Wait for synchronous ROM read latency
            req_valid_d2 <= req_valid_d1;
            
            // Stage 3: Register the incoming ROM data to break combinational paths
            // Also delay the valid signal to keep it aligned with the registered data
            rom_data_reg <= rom_data;
            req_valid_d3 <= req_valid_d2;
        end
    end

    // ==============================================================================
    // Stage 4 & 5: Data Processing (Pipelined Generate Block)
    // ==============================================================================
    generate
        if (IN_DATA_WIDTH == 24) begin : gen_rgb2gray
            // Instantiate the 2-stage pipelined converter
            rgb2gray_pipelined u_rgb2gray (
                .clk       (clk),
                .rst       (rst),
                .rgb_in    (rom_data_reg),
                .valid_in  (req_valid_d3),
                .gray_out  (pixel_out),
                .valid_out (valid_out)
            );
        end else begin : gen_passthrough
            // Match the 2-cycle latency of the RGB converter
            reg [7:0] pass_d1, pass_d2;
            reg       v_d1, v_d2;
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    pass_d1 <= 8'd0; pass_d2 <= 8'd0;
                    v_d1    <= 1'b0; v_d2    <= 1'b0;
                end else begin
                    // Cycle 1 delay
                    pass_d1 <= rom_data_reg[7:0];
                    v_d1    <= req_valid_d3;
                    
                    // Cycle 2 delay
                    pass_d2 <= pass_d1;
                    v_d2    <= v_d1;
                end
            end
            
            assign pixel_out = pass_d2;
            assign valid_out = v_d2;
        end
    endgenerate

endmodule