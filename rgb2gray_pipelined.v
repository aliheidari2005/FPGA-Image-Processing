`timescale 1ns / 1ps

module rgb2gray_pipelined (
    input  wire        clk,
    input  wire        rst,
    input  wire [23:0] rgb_in,
    input  wire        valid_in,
    
    output reg  [7:0]  gray_out,
    output reg         valid_out
);

    // Assuming standard format: R = [23:16], G = [15:8], B = [7:0]
    
    // --- Pipeline Stage 1 Registers ---
    reg [15:0] r_mult;
    reg [15:0] g_mult;
    reg [15:0] b_mult;
    reg        valid_d1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_mult   <= 16'd0;
            g_mult   <= 16'd0;
            b_mult   <= 16'd0;
            valid_d1 <= 1'b0;
        end else begin
            // Multiplications
            r_mult   <= rgb_in[23:16] * 8'd77;
            g_mult   <= rgb_in[15:8]  * 8'd150;
            b_mult   <= rgb_in[7:0]   * 8'd29;
            // Delay the valid signal
            valid_d1 <= valid_in;
        end
    end

    // --- Pipeline Stage 2 Registers ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gray_out  <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            // Sum the multiplied values and shift right by 8 (divide by 256)
            gray_out  <= (r_mult + g_mult + b_mult) >> 8;
            // Output the final valid signal
            valid_out <= valid_d1;
        end
    end

endmodule