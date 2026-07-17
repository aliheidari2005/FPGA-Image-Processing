`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2026 10:15:26 PM
// Design Name: 
// Module Name: top_level
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

module top_level (
    input wire clk_25MHz,       // Main board clock from physical pin
    input wire rst_pin,         // Active high reset button from physical pin
    
    // Outputs for the processing logic module
    output wire data_valid,
    output wire [7:0] p00, output wire [7:0] p01, output wire [7:0] p02,
    output wire [7:0] p10, output wire [7:0] p11, output wire [7:0] p12,
    output wire [7:0] p20, output wire [7:0] p21, output wire [7:0] p22
);

    // Internal wires to establish connections between IP cores and custom modules
    wire clk_75MHz;
    wire clk_locked;
    wire [13:0] system_rom_addr;
    wire [7:0] system_rom_data;
    wire internal_rst;

    // Global reset generation: The system remains in reset if the external button is pressed
    // OR if the clock generator IP has not stabilized yet (clk_locked is 0)
    assign internal_rst = rst_pin | (~clk_locked);

    // 1. Instantiation of Clocking Wizard IP Core
    // Generates a stable 75MHz clock from the 25MHz external source
    clk_wiz_0 instance_clk_wiz (
        .clk_in1(clk_25MHz),       // Input 25MHz from board
        .clk_out1(clk_75MHz),      // Output 75MHz fast clock
        .reset(rst_pin),           // Input reset
        .locked(clk_locked)        // Output stability indicator
    );

    // 2. Instantiation of Block Memory Generator (ROM) IP Core
    // Stores the image data initialized via a .coe file
    blk_mem_gen_0 instance_rom (
        .clka(clk_75MHz),          // Fast clock for synchronous reading
        .addra(system_rom_addr),   // 14-bit Address requested by the memory controller
        .douta(system_rom_data)    // 8-bit Data returned to the memory controller
    );

    // 3. Instantiation of the Custom Memory Controller Module
    // Manages the sliding 3x3 window and memory addressing
    memory_controller instance_controller (
        .clk_75MHz(clk_75MHz),
        .rst(internal_rst),
        .rom_data(system_rom_data), // Wired to ROM output
        .rom_addr(system_rom_addr), // Wired to ROM input address
        .data_valid(data_valid),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

endmodule