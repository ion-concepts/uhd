initial
  begin
     @(posedge clk);
     rst <= 1'b1;
     stb_in <= 1'b0;
     run <= 1'b0;
     
     repeat (5) @(posedge clk);
     @(posedge clk);
     rst <= 1'b0;
     @(posedge clk);
    
     //
     write_setting_bus(0,2);   // Scale = 2 (log2(4)
     write_setting_bus(1,4);   // Integration Interval = 4
     write_setting_bus(2,1);   // Enable Integration
     //
     // Simple Test sequences.
     // Square 4 complex numbers (16bit signed I & Q) to get power.
     // Sum powers and scale to integrate
     //
     // 
     // 10000 + 10000j
     @(posedge clk);
     round_i <= 16'sd10000;
     round_q <= 16'sd10000;
     run <= 1'b1;
     stb_in <= 1'b1;
     // 5000 + 0j
     @(posedge clk);
     round_i <= 16'sd5000;
     round_q <= 16'sd0;
     // 0 - 2000j
     @(posedge clk);
     round_i <= 16'sd0;
     round_q <= -16'sd2000;
     // -7000 - 1234j
     @(posedge clk);
     round_i <= -16'sd7000;
     round_q <= -16'sd1234;
     // and go idle.
     @(posedge clk);
     stb_in <= 1'b0;
     //
     // Stop "DSP" and reprogram config.
     //
     repeat (10) @(posedge clk);
     run <= 1'b0;
     @(posedge clk);
     write_setting_bus(0,0);   // Scale = 2 (log2(4)
     write_setting_bus(1,1);   // Integration Interval = 4
     write_setting_bus(2,1);   // Enable Integration
     //
          // 10000 + 10000j
     @(posedge clk);
     round_i <= 16'sd10000;
     round_q <= 16'sd10000;
     run <= 1'b1;
     stb_in <= 1'b1;
     // 5000 + 0j
     @(posedge clk);
     round_i <= 16'sd5000;
     round_q <= 16'sd0;
     // 0 - 2000j
     @(posedge clk);
     round_i <= 16'sd0;
     round_q <= -16'sd2000;
     // -7000 - 1234j
     @(posedge clk);
     round_i <= -16'sd7000;
     round_q <= -16'sd1234;
     // and go idle.
     @(posedge clk);
     stb_in <= 1'b0;
     //
     // Kill simulation
     repeat (1000) @(posedge clk);
     $finish;
     
  end // initial begin
   
