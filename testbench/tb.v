`timescale	1ns / 1ns

`define	SIM
   
module tb();

    reg			sys_clk;
    reg			fpga_reset;
    wire [7:0]		sb;
    
    initial begin
	sys_clk = 0;
	fpga_reset = 1'b1;
	#500;
	fpga_reset = 1'b0;
    end

    initial begin
	$dumpfile("dump.vcd");      
	$dumpvars(0);      
	#50_000 $display("Shutting down @ %1d", $time);

	$finish;
    end
	    
    always #4.1666 sys_clk = ~sys_clk;

    fpga_top top(
	.clk_i		(sys_clk),
	.s_o		(sb)
    );

endmodule


