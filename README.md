This is a demo of using Verilog to generate a bitfile to exercise the Xess 8 element
LCD board. The project utilizes a Makefile to invoke the various Xilinx tools and Xess
loader program.

My environment:
   Centos 6.4 Linux
   Xilinx Webpack 14.4
   Icarus Verilog
   GTK waveform viewer

To use:

   Edit the Makefile
       Set the path to the Xilinx tools "/opt/Xilinx/14.4".
       Select your Xess Board, xula or xula 2.
   Attach a PMOD header to the LCD module and plug it into the Stickit PM6 header.
   Connect the Xula to the host via USB and verify operation with xstest.
   Type "make xsload". This will create the bitfile and load it into the Xula.

This code is released under the MIT Open Source Initiative License.
