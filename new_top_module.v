`timescale 1ns / 1ps

module new_top_module #(
    // =========================================================================
    // Top-Level Parameters
    // =========================================================================
    parameter IMG_WIDTH     = 256, // Width of the image
    parameter IMG_HEIGHT    = 256, // Height of the image
    parameter ADDR_WIDTH    = 16,  // log2(IMG_WIDTH * IMG_HEIGHT)
    parameter COORD_WIDTH   = 8,   // log2(IMG_WIDTH)
    parameter DATA_WIDTH    = 8,   // Internal pipeline pixel bit-width
    parameter IN_DATA_WIDTH = 24    // ROM output data width (8 for Gray, 24 for RGB)
)(
    input  wire clk_25MHz,         // 25MHz external clock
    input  wire rst_pin,           // Active-high reset
    input  wire enable,            // Starts the image processing pipeline
    
    output wire [DATA_WIDTH-1:0] final_pixel, // The resulting edge-detected pixel
    output wire                  final_valid  // High when final_pixel is valid
);

    // =========================================================================
    // 1. Internal Wire Declarations
    // =========================================================================
    
    // Clocking
    wire clk_75MHz;
    wire clk_locked;
    
    // ROM Interface
    wire [ADDR_WIDTH-1:0]    system_rom_addr;
    wire [IN_DATA_WIDTH-1:0] system_rom_data; 
    
    // Stage 1: ROM Reader Outputs
    wire [DATA_WIDTH-1:0] rr_pixel_out;
    wire                  rr_valid_out;
    
    // Stage 2: First Window Generator (For Median Filter) Outputs
    wire                  wg1_valid;
    wire [DATA_WIDTH-1:0] m_p00, m_p01, m_p02;
    wire [DATA_WIDTH-1:0] m_p10, m_p11, m_p12;
    wire [DATA_WIDTH-1:0] m_p20, m_p21, m_p22;
    
    // Stage 3: Median Filter Outputs
    wire [DATA_WIDTH-1:0] median_pixel;
    wire                  median_valid;
    
    // Stage 4: Second Window Generator (For Laplace Filter) Outputs
    wire                  wg2_valid;
    wire [DATA_WIDTH-1:0] l_p00, l_p01, l_p02;
    wire [DATA_WIDTH-1:0] l_p10, l_p11, l_p12;
    wire [DATA_WIDTH-1:0] l_p20, l_p21, l_p22;

    // =========================================================================
    // 2. IP Core Instantiations
    // =========================================================================

    // Generate 75MHz fast clock from 25MHz input
    clk_25to75 instance_clk_wiz (
        .CLK_IN1(clk_25MHz),
        .CLK_OUT1(clk_75MHz),
        .RESET(rst_pin),
        .LOCKED(clk_locked)
    );

    // Block RAM containing the image
    image_mem instance_rom (
        .clka(clk_75MHz),
        .addra(system_rom_addr),
        .douta(system_rom_data) 
    );

    // =========================================================================
    // 3. Pipeline Interconnections
    // =========================================================================

    // Stage 1: Memory Controller & RGB to Grayscale
    rom_reader #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .ADDR_WIDTH(ADDR_WIDTH),
        .IN_DATA_WIDTH(IN_DATA_WIDTH)
    ) u_rom_reader (
        .clk(clk_75MHz),
        .rst(rst_pin),
        .enable(enable & clk_locked), // Only enable when clock is stable
        
        .rom_addr(system_rom_addr),
        .rom_data(system_rom_data),
        
        .pixel_out(rr_pixel_out),
        .valid_out(rr_valid_out)
    );

    // Stage 2: Create 3x3 Window for Median Filter
    window_generator_3x3 #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .DATA_WIDTH(DATA_WIDTH),
        .COORD_WIDTH(COORD_WIDTH)
    ) u_window_gen_median (
        .clk(clk_75MHz),
        .rst(rst_pin),
        .pixel_in(rr_pixel_out),
        .valid_in(rr_valid_out),
        
        .window_valid(wg1_valid),
        .p00(m_p00), .p01(m_p01), .p02(m_p02),
        .p10(m_p10), .p11(m_p11), .p12(m_p12),
        .p20(m_p20), .p21(m_p21), .p22(m_p22)
    );

    // Stage 3: Noise Reduction (Median Filter)
    fast_median_filter_pipeline u_median_filter (
        .clk(clk_75MHz),
        .rst(rst_pin),
        .valid_in(wg1_valid),
        
        .p00(m_p00), .p01(m_p01), .p02(m_p02),
        .p10(m_p10), .p11(m_p11), .p12(m_p12),
        .p20(m_p20), .p21(m_p21), .p22(m_p22),
        
        .median_out(median_pixel),
        .valid_out(median_valid)
    );

    // Stage 4: Create 3x3 Window for Laplace Filter
    // This generator treats the cleaned output of the median filter as its new input stream
    window_generator_3x3 #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .DATA_WIDTH(DATA_WIDTH),
        .COORD_WIDTH(COORD_WIDTH)
    ) u_window_gen_laplace (
        .clk(clk_75MHz),
        .rst(rst_pin),
        .pixel_in(median_pixel),
        .valid_in(median_valid),
        
        .window_valid(wg2_valid),
        .p00(l_p00), .p01(l_p01), .p02(l_p02),
        .p10(l_p10), .p11(l_p11), .p12(l_p12),
        .p20(l_p20), .p21(l_p21), .p22(l_p22)
    );

    // Stage 5: Edge Detection (Laplacian Filter)
    laplace_filter u_laplace_filter (
        .clk(clk_75MHz),
        .rst(rst_pin),
        .valid_in(wg2_valid),
        
        .p00(l_p00), .p01(l_p01), .p02(l_p02),
        .p10(l_p10), .p11(l_p11), .p12(l_p12),
        .p20(l_p20), .p21(l_p21), .p22(l_p22),
        
        .edge_pixel(final_pixel),
        .valid_out(final_valid)
    );

endmodule