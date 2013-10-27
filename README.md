This is a demo of using Verilog to generate a bitfile to exercise the Xess 8 element
LCD board. The project utilizes a Makefile to invoke the various Xilinx tools and Xess
loader program.

My environment:
   1. Centos 6.4 Linux
   2. Xilinx Webpack 14.4
   3. Icarus Verilog
   4. GTK waveform viewer

To use:

   1. Edit the Makefile
     a. Set the path to the Xilinx tools "/opt/Xilinx/14.4".
     b. Select your Xess Board, xula or xula 2.
   2. Attach a PMOD header to the LCD module and plug it into the Stickit PM6 header.
   3. Connect the Xula to the host via USB and verify operation with xstest.
   4. Type "make xsload". This will create the bitfile and load it into the Xula.

This code is released under the MIT Open Source Initiative License.
