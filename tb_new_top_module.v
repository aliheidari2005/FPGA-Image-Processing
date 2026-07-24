`timescale 1ns / 1ps

module tb_new_top_module();

    // 1. Signals for driving the Top Module
    reg clk_25MHz;
    reg rst_pin;
    reg enable;
    
    // Outputs from the Top Module
    wire [7:0] final_pixel;
    wire       final_valid;

    // 2. File I/O Variables
    integer file_id;
    integer pixel_count;

    // 3. Instantiate the Unit Under Test (UUT)
    new_top_module uut (
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

        $display("Starting Simulation...");

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
        // 16384 pixels * 13.3ns + pipeline latency = ~220us. Giving it 1ms to be safe.
        #1000000; 
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
            if (pixel_count % 4096 == 0) begin
                $display("Captured %d / 16384 pixels...", pixel_count);
            end
            
            // Stop simulation exactly when the frame completes
            if (pixel_count == 16384) begin
                $display("Success: All 16384 pixels captured!");
                $fclose(file_id);
                $finish;
            end
        end
    end

endmodule