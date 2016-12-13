/************************************************
*																                *
* Derek Prince												                      *
* ECEN 2350: Digital Logic								              *
* 2n-bit Comparator on the terasiC DE0 board		  *
* Altera Cyclone 3 EP3C16F484							            *
*																                *
* Date: 				October 11th, 2016				              *
* Last Modified: 	October 16th, 2016				        *
*																                *
************************************************/


module comparator_tb1(eqbit, gtbit, ltbit);
  //controls number of comparator instances
  parameter n = 4;
  
  reg clk;//clock
  
  output eqbit, gtbit, ltbit;
  wire eqdbbit, gtdbbit, ltdbbit, agree;		//debugging bits
  reg unsigned [2*n-1:0] x, y;
  
  initial begin
    clk = 0;
    x = 8'b11111111;
    y = 8'b0;
  end
  
  always #5 clk = ~clk;
  always @(posedge clk)
    x = x + 1;

  always @(negedge x == 8'b11111111)
    y = y + 1;
  
  wire [n:0] eqcarry, gtcarry, ltcarry;
  //I only need an n+1 bit wide wire because there are only n stages of comparators and these link the stages but I need one more for the carry
  //otherwise final stage overflows X. Similarly, this could be done with an initial comparator block that is static to set up the sequence
  //This would mean the carries would return to n-bit widths
  assign eqcarry[0] = 1;  //sets the initial values for the first comparator stage
  assign gtcarry[0] = 0;
  assign ltcarry[0] = 0;
  // I want these to be 0 initially so that it does not change the initial setup of a comparator
  // eq is 1 because it is anded with the evaluation. others are 0 because of OR

  //------------Comparison block------------//
  generate
    genvar k;
 	    for (k = 0; k < 2*n; k = k + 2)  //add 2 because we are working with pairs of bits.
 	      //Since the module works by assuming the msbs were the bit pairs in, k+2*n-1 assures the instantiation goes down the line as genvar goes up.
	      doublencomparator dnc(.x0(x[2*n-1-k]), .x1(x[2*n-2-k]), .y0(y[2*n-1-k]), .y1(y[2*n-2-k]),
	                              .eqin(eqcarry[k/2]), .gtin(gtcarry[k/2]), .ltin(ltcarry[k/2]), 
	                              .eqout(eqcarry[k/2+1]), .gtout(gtcarry[k/2+1]), .ltout(ltcarry[k/2+1]));  //just trying out this syntax.
  endgenerate
  
  //------------Output Block------------//
  assign eqbit = eqcarry[n];
  assign gtbit = gtcarry[n];
  assign ltbit = ltcarry[n];
  
  assign eqdbbit = x == y;
  assign gtdbbit = x > y;
  assign ltdbbit = ~(eqdbbit | gtdbbit);
  assign agree = {eqdbbit, gtdbbit, ltdbbit} == {eqbit, gtbit, ltbit};
  
  always @(agree)
  begin
    if (~agree)
      begin: monitor_output
        $display("Simulation disagreed on x = %b , y = %b", x, y);
        $display("eqbit: %b , eqdbbit: %b", eqbit, eqdbbit);
        $display("gtbit: %b , gtdbbit: %b", gtbit, gtdbbit);
        $display("ltbit: %b , ltdbbit: %b", ltbit, ltdbbit);
      end
  end
  
  always @(x[2*n-1])
    if ((x == 8'b0) && (y == 8'b11111111))
      $display("All variations compared");
      
endmodule //comparator_tb1
