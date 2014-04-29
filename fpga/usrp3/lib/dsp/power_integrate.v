//
// Copyright 2014 Ion Concepts LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

module power_integrate
  #(parameter BASE = 0)
    (
     input clk,
     input reset,
     // Control
     input run,
     //
     // Settings bus
     //
     input set_stb, input [7:0] set_addr, input [31:0] set_data,
     //
     // Input bus - Complex sample stream to integrate
     //
     input [15:0] i_in, input [15:0] q_in, input strobe_in, 
     //
     // Output CHDR bus - 32bit unsigned ints of integrated power.
     //
     output reg [31:0] power_out, output reg strobe_out,
     //
     output [63:0] debug
     );

   // Set the scale factor to right shift the accumulator by.
   // Normally programed with LOG2 of the number of integrated samples.
   wire [3:0] 	   scale;
   
   setting_reg #(.my_addr(BASE+0), .awidth(8), .width(4)) sr_scale
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(scale), .changed());

   // Set the number of complex samples to integrate power for. Note this is a sample count
   // and there are normally 2 complex samples per 64bit CHDR payload line.
   wire [15:0] 	   integrate;

   setting_reg #(.my_addr(BASE+1), .awidth(8), .width(16)) sr_integrate
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(integrate), .changed());

   // This block defaults to being bypassed unless explicitly enabled.
   //
   wire 	   enable;

   setting_reg #(.my_addr(BASE+2), .awidth(8), .width(1)) sr_power_enable
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(enable), .changed());

   //
   // Integrator datapath:
   //
   // Square each paired I & Q sample, then add them. 
   // Accumulate the result until we dump the integrated value, when the accumulator is simulatneously reset.
   //
   reg signed [15:0] 	  i_in0, q_in0; // Signed sample data
   reg signed [31:0] 	  i_sq0, q_sq0; // We just squared so these are always unsigned values.
   reg [32:0] 		  sum_of_squares; // 2bit word growth from 4 additions of 31bit unsigned values.
   reg [47:0] 		  acc; // Allow for lots of word growth for programable integration periods.
   reg 			  pipe2_en, pipe3_en, pipe4_en, pipe5_en;
   reg 			  clear_acc;
   reg [15:0] 		  count;

   
   always @(posedge clk)
     if (strobe_in && enable) 
       begin
	  // Deal with the corner case of a finishing odd line with only one complex sample
	  // by forcing the 2nd opperand to be all zero's and still accululating it later.
	  i_in0 <= i_in;
	  q_in0 <= q_in;
	  pipe2_en <= 1'b1;
       end
     else
       begin
	   pipe2_en <= 1'b0;
       end
   
   always @(posedge clk)
     if (pipe2_en)
       begin
	  // Signed multiplication of 16bit signed operands. For 1.15 opperands this yields a 2.30 result.
	  // Note however we are squaring (multiply by self) and so regardless of the sign of the opperands
	  // all results are positive, thus the MSB of all "signed" products will be 0.
	  i_sq0 <= i_in0 * i_in0;
	  q_sq0 <= q_in0 * q_in0;
	  pipe3_en <= 1'b1;
       end
     else
       begin
	   pipe3_en <= 1'b0;
       end // else: !if(pipe3_en)
   
   always @(posedge clk)
     if (pipe3_en)
       // We omit the bit[31]'s because the signed multiplication always yields a positive result and thus
       // this is a redundant sign bit.
       // We add 2 (unsigned) numbers here so word growth of 1 bit.
       begin
	  sum_of_squares[32:0] <= i_sq0[30:0] + q_sq0[30:0];	  
	  pipe4_en <= 1'b1;
       end
     else
       begin
	   pipe4_en <= 1'b0;
       end // else: !if(pipe4_en)
   
   always @(posedge clk)
     if (~run)
       // Reset accumulator if we are just tstarting from idle
       begin
	  acc <= 48'h0;
	  count <= 0;
	  pipe5_en <= 1'b0;
       end
     else if (pipe4_en)
       if (clear_acc)
	 // New integration starts, don't add in previous accumulator.
	 begin
	    acc <= sum_of_squares;
	    count <= 16'h1;
	    pipe5_en <= 1'b0;
	    clear_acc <= 1'b0;
	 end
       else
         // Unsigned integration of products. Total word growth is log2(N) bits, where N is
         // is the number of iterations of this accumulator.
         // (NOTE: Packets with an odd number of samples cause an inaccuracy in this word growth calc)
	 begin
	    acc <= acc + sum_of_squares;
	    count <= count + 1'b1;
	    if ((count + 1) == integrate)
	      begin
		 pipe5_en <= 1'b1;
		 clear_acc <= 1'b1;
	      end
	 end
     else
       begin
	  pipe5_en <= 1'b0;
       end
	 

   always @(posedge clk)
     if (~enable)
       // Bypass mode
       begin
	  power_out[31:0] <= {i_in, q_in};
	  strobe_out <= strobe_in;
       end
     else if (pipe5_en)
       // The maximum left shift here of 16bits sets the maximum number of integrations as
       // 2^15 (2^16 actual complex samples)
       begin
	  power_out[31:0] <= acc[47:0] >> (scale+1);
	  strobe_out <= 1'b1;
       end
     else
       strobe_out <= 1'b0;
   

endmodule
   
