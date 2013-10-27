/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2013 George Gallant
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Verilog Module for driving Xess StickIt! seven-segment LED module.
 */

module fpga_top(
    input		clk_i,
    output wire [7:0]	s_o
);

    localparam
	FSM_INIT=	0,
	FSM_RUN=	1;

    reg [5:0] 		reset_delay;
    reg 		rst, reset;
    reg [23:0] 		counter;
    reg [7:0] 		seg;
    reg [7:0] 		led, nextLed; 			
    reg [111:0] 	scrollData, nextScrollData;
    reg [2:0] 		state, nextState; 			
    wire 		clk_50mhz, dcm_clk0, dcm_clkfx, dcm_locked;

    /*
     * Assert 1 line high to drive the cathode.
     * Assert the remaining 7 to either low or float.
     * Study the schematic!!!
     */
    assign s_o[0] = led[0] ? 1'b1 : (seg[0] ? 1'b0 : 1'bz);
    assign s_o[1] = led[1] ? 1'b1 : (seg[1] ? 1'b0 : 1'bz);
    assign s_o[2] = led[2] ? 1'b1 : (seg[2] ? 1'b0 : 1'bz);
    assign s_o[3] = led[3] ? 1'b1 : (seg[3] ? 1'b0 : 1'bz);
    assign s_o[4] = led[4] ? 1'b1 : (seg[4] ? 1'b0 : 1'bz);
    assign s_o[5] = led[5] ? 1'b1 : (seg[5] ? 1'b0 : 1'bz);
    assign s_o[6] = led[6] ? 1'b1 : (seg[6] ? 1'b0 : 1'bz);
    assign s_o[7] = led[7] ? 1'b1 : (seg[7] ? 1'b0 : 1'bz);

    /*
     * The DCM is entirely unnecessary for this project. Needed 50MHz for another
     * design and started with this code to prove it working.
     */
    DCM_SP #(.CLKFX_DIVIDE(6), .CLKFX_MULTIPLY(25)) dcm_0(
	.CLK0		(dcm_clk0),
	.CLK180		(),
	.CLK270		(),
	.CLK2X		(),
	.CLK2X180	(),
	.CLK90		(),
	.CLKDV		(),
	.CLKFX		(dcm_clkfx),
	.CLKFX180	(),
	.LOCKED		(dcm_locked),
	.PSDONE		(),
	.STATUS		(),
	.DSSEN		(1'b1),
	.PSCLK		(1'b0),
	.PSEN		(1'b0),
	.PSINCDEC	(1'b0),
	.CLKFB		(dcm_clk0),
	.CLKIN		(clk_i),
	.RST		(1'b0)
    );

    BUFG bufg (.I(dcm_clkfx), .O(clk_50mhz));
    
    initial begin
	state = FSM_INIT;
	counter = 0;
	rst = 1;
	reset = 1;
	reset_delay = 30;
    end

    always @(posedge clk_i) begin
	if (reset_delay > 0)
	    reset_delay = reset_delay - 1'b1;
	else
	    reset = 0;
    end

    /*
     * Derive a reset signal in the 50MHz domain
     */
    always @(posedge clk_50mhz) begin
	rst = reset;
    end
    
    /*
     * Clock driven section of simple FSM.
     */
    always @(posedge clk_50mhz) begin
	if (rst)
	    begin
		state <= FSM_INIT;
		counter <= 0;
	    end
	else
	    begin
		counter <= counter + 1'b1;
		state <= nextState;
		led <= nextLed;
		scrollData <= nextScrollData;
	    end
    end

    /*
     * Combinational driven section of simple FSM.
     * 
     * 1. Wait for the DCM to assert the "locked" signal
     * 2. At time intervals 0x100 ticks advance the individual led selector
     * 3. At time intervals 0x400000 ticks scroll the output data pattern
     */
    always @(*) begin
	nextLed = led;
	nextState = state;
	nextScrollData = scrollData;

	case (state)
	    FSM_INIT:
		begin
		    nextState = FSM_RUN;
		    nextScrollData[  6:  0] = 7'b0000111;		// "7"
		    nextScrollData[ 13:  7] = 7'b1111101;		// "6"
		    nextScrollData[ 20: 14] = 7'b1101101;		// "5"
		    nextScrollData[ 27: 21] = 7'b1100110;		// "4"
		    nextScrollData[ 34: 28] = 7'b1001111;		// "3"
		    nextScrollData[ 41: 35] = 7'b1011011;		// "2"
		    nextScrollData[ 48: 42] = 7'b0000110;		// "1"
		    nextScrollData[ 55: 49] = 7'b0111111;		// "0"
		    nextScrollData[ 62: 56] = 7'b1110001;		// "F"
		    nextScrollData[ 69: 63] = 7'b1111001;		// "E"
		    nextScrollData[ 76: 70] = 7'b1011110;		// "D"
		    nextScrollData[ 83: 77] = 7'b0111001;		// "C"
		    nextScrollData[ 90: 84] = 7'b1111100;		// "B"
		    nextScrollData[ 98: 91] = 7'b1110111;		// "A"
		    nextScrollData[104: 98] = 7'b1101111;		// "9"
		    nextScrollData[111:105] = 7'b1111111;		// "8"
		    nextLed = 8'b0000_0001;
		end
	    FSM_RUN:
		begin
		    if (counter[8:0] == 9'h100)
			begin
			    nextLed[7:0] = {led[6:0], led[7]};
			end
		    if (counter[23:0] == 24'h80_0000)
			begin
			    nextScrollData[111:0] = {scrollData[104:0], scrollData[111:105]};
			end
		end
	endcase
    end

    /*
     * Figure the required output mapping for each LED. Look at the
     * schematic. One output line is driven high and the remaining 7
     * are either floated to be off or driven low to be on.
     * 
     * Used in conjunction with the assign statements to properly assert
     * the output lines.
     */
    always @(*) begin
	seg <= 8'b0000_0000;
	case (led)
	    8'b0000_0001: seg[7:0] <= {scrollData[ 6: 0], 1'b0};
	    8'b0000_0010: seg[7:0] <= {scrollData[13: 8], 1'b0, scrollData[7]};
	    8'b0000_0100: seg[7:0] <= {scrollData[20:16], 1'b0, scrollData[15:14]};
	    8'b0000_1000: seg[7:0] <= {scrollData[27:24], 1'b0, scrollData[23:21]};
	    8'b0001_0000: seg[7:0] <= {scrollData[34:32], 1'b0, scrollData[31:28]};
	    8'b0010_0000: seg[7:0] <= {scrollData[41:40], 1'b0, scrollData[39:35]};
	    8'b0100_0000: seg[7:0] <= {scrollData[48],    1'b0, scrollData[47:42]};
	    8'b1000_0000: seg[7:0] <= {                   1'b0, scrollData[55:49]};
	endcase
    end
 
endmodule
