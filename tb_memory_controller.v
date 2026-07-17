`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2026 09:53:55 PM
// Design Name: 
// Module Name: tb_memory_controller
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

module tb_memory_controller();

    // 1. Declare signals to connect to the UUT
    reg clk_75MHz;
    reg rst;
    reg [7:0] rom_data;

    wire [13:0] rom_addr;
    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;
    wire data_valid;

    // 2. Instantiate the main module
    memory_controller uut (
        .clk_75MHz(clk_75MHz),
        .rst(rst),
        .rom_data(rom_data),
        .rom_addr(rom_addr),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .data_valid(data_valid)
    );

    // 3. Create a Mock ROM for simulation (128x128 = 16384 pixels)
    reg [7:0] mock_rom [0:16383];
    integer r, c; // Variables for Row and Column generation

    // 4. Generate 75MHz Clock (Period = ~13.333 ns -> Half Period = ~6.666 ns)
    initial begin
        clk_75MHz = 0;
        forever #6.666 clk_75MHz = ~clk_75MHz;
    end

    // 5. Simulate ROM Read latency (1 clock cycle delay)
    always @(posedge clk_75MHz) 
    begin
        rom_data <= mock_rom[rom_addr];
    end

    // 6. Main Test Sequence
    initial begin
        // Initialize the Mock ROM with a SMART trackable pattern
        // Upper 4 bits = Row number (0 to 15, then wraps)
        // Lower 4 bits = Column number (0 to 15, then wraps)
        // Example: 8'h25 -> Row 2, Column 5
        for (r = 0; r < 128; r = r + 1) begin
            for (c = 0; c < 128; c = c + 1) begin
                mock_rom[(r * 128) + c] = {r[3:0], c[3:0]}; 
            end
        end

        // Apply Reset
        rst = 1;
        #20; 
        
        // Release Reset to start the controller
        rst = 0;

        // Let the simulation run
        #2000;
        
        // Stop the simulation
        $finish;
    end

endmodule