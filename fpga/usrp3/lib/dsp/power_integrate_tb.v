`timescale 1ns/1ps

module power_integrate_tb();
   
 wire GSR, GTS;
   glbl glbl( );

   reg 	clk = 0;
   reg 	rst;
   reg 	bypass;
   reg 	run;
   
   reg stb_in;
   wire 	stb_out;

   
   reg signed [15:0] round_i, round_q;
   
   wire [31:0] sample;
  
   
   integer     x = 0, y =0;
   
   
   
   always #100 clk = ~clk;
   
`include "../../task_library.v"
`include "simulation_script.v"
   
   
    power_integrate 
     #(.BASE(0))
       power_integrate_i
	 (
	  .clk(clk),
	  .reset(rst),
	  .run(run),
	  .set_stb(set_stb),
	  .set_addr(set_addr),
	  .set_data(set_data),
	  .i_in(round_i),
	  .q_in(round_q),
	  .strobe_in(stb_in),
	  .power_out(sample),
	  .strobe_out(stb_out),
	  .debug()
	  );


endmodule // power_integrate_tb
