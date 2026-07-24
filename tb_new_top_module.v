`timescale 1ns / 1ps

module tb_new_top_module();

    // =========================================================================
    // Testbench Parameters (Set for 256x256 RGB)
    // =========================================================================
    parameter IMG_WIDTH     = 256;
    parameter IMG_HEIGHT    = 256;
    parameter ADDR_WIDTH    = 16;
    parameter COORD_WIDTH   = 8;
    parameter DATA_WIDTH    = 8;
    parameter IN_DATA_WIDTH = 24;
    
    localparam TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT;

    // 1. Signals for driving the Top Module
    reg clk_25MHz;
    reg rst_pin;
    reg enable;
    
    // Outputs from the Top Module
    wire [DATA_WIDTH-1:0] final_pixel;
    wire                  final_valid;

    // 2. File I/O Variables
    integer file_id;
    integer pixel_count;

    // 3. Instantiate the Unit Under Test (UUT)
    new_top_module #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .ADDR_WIDTH(ADDR_WIDTH),
        .COORD_WIDTH(COORD_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .IN_DATA_WIDTH(IN_DATA_WIDTH)
    ) uut (
        .clk_25MHz(clk_25MHz),
        .rst_pin(rst_pin),
        .enable(enable),
        .final_pixel(final_pixel),
        .final_valid(final_valid)
    );

    // 4. Generate the 25MHz Input Clock
    // 40ns period = 25MHz
    initial begin
        clk_25MHz = 0;
        forever #20 clk_25MHz = ~clk_25MHz;
    end

    // 5. Main Stimulus Block
    initial begin
        // Initialize Inputs
        rst_pin = 1;
        enable = 0;
        pixel_count = 0;

        // Open the output file in write mode
        file_id = $fopen("output_image.txt", "w");
        if (!file_id) begin
            $display("Error: Could not open output_image.txt for writing.");
            $finish;
        end

        $display("Starting Simulation for %0d x %0d image...", IMG_WIDTH, IMG_HEIGHT);

        // Hold reset for 200ns
        #200;
        rst_pin = 0;

        // Wait a sufficient amount of time for the Clocking Wizard (PLL) to lock.
        // PLLs usually take a few microseconds to stabilize in simulation.
        #2000; 
        
        // Start the processing pipeline
        enable = 1;
        $display("Pipeline Enabled. Waiting for valid pixels...");

        // Safety timeout in case valid signals never arrive
        // 65536 pixels * 13.3ns + pipeline latency = ~871us. Giving it 5ms to be safe.
        #5000000; 
        $display("Simulation Timeout Reached!");
        $fclose(file_id);
        $finish;
    end

    // 6. Data Capture Block
    // We sample on the internal 75MHz clock because that is what drives the output valid signal.
    always @(posedge uut.clk_75MHz) begin
        if (final_valid) begin
            // Write the pixel value as a 2-digit uppercase hexadecimal string
            $fwrite(file_id, "%02X\n", final_pixel);
            
            pixel_count = pixel_count + 1;
            
            // Log progress occasionally so you know simulation isn't frozen
            // Triggers exactly 16 times during the frame
            if (pixel_count % (TOTAL_PIXELS / 16) == 0) begin
                $display("Captured %0d / %0d pixels...", pixel_count, TOTAL_PIXELS);
            end
            
            // Stop simulation exactly when the frame completes
            if (pixel_count == TOTAL_PIXELS) begin
                $display("Success: All %0d pixels captured!", TOTAL_PIXELS);
                $fclose(file_id);
                $finish;
            end
        end
    end

endmodule