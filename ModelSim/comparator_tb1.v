/*
* Derek Prince
* Date:
* Last Modified: 
* License: WGAF
*/


module comparator_tb1(eqbit, gtbit, ltbit);
  //controls number of comparator instances
  parameter n = 4;
  
  //reg clk;
  //reg [2*n-1:0] count;
  
  output eqbit, gtbit, ltbit;
  reg [2*n-1:0] x, y;
  
  reg x_negative, y_negative;       //I don't want these to be continuous assignment, thus registers
  wire negative_is_allowed = 1;     //On the DE0 borad this will be controlled by a switch
  
  initial begin
    x = 8'b10000010;
    y = 8'b00000000;
  end
  
  always @(negative_is_allowed)
    begin
      x_negative =  x[2*n-1] & negative_is_allowed; // These are 1 if x or y are negative (respectively)
      y_negative = y[2*n-1] & negative_is_allowed;  
      // They are masked with negative_is_allowed because it forces 0 values when they are unsigned
      // i.e. positive
    end
  
  wire [n:0] eqcarry, gtcarry, ltcarry;
  //I only need an n+1 bit wide wire because there are only n stages of comparators and these link the stages but I need one more for the carry
  //otherwise final stage overflows X. Similarly, this could be done with an initial comparator block that is static to set up the sequence
  //This would mean the carries would return to n-bit widths
  assign eqcarry[0] = 1;  //sets the initial values for the first comparator stage
  assign gtcarry[0] = 0;
  assign ltcarry[0] = 0;
  // I want these to be 0 initially so that it does not change the initial setup of a comparator
  // eq is 1 because it is anded with the evaluation. others are 0 because of OR

  //------------Signed Conversions------------//
  //Take care of signs by converting to unsigned if necessary.
  //Using comparisons and if statements would be best but we're not allowed to do that. Thus, masking and gates instead.
  
  //***** Might need to have another if statement enclosing this one watching a switch that tells the board if numbers are signed
  //***** Otherwise it will assume large unsigned numbers are signed.
  always @(x_negative, y_negative)
    begin
      if (x_negative)
        x = ~x + 1'b1;  // undo 2's compliment
      if (y_negative)
        y = ~y + 1'b1;
    end
  
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
  assign eqbit = eqcarry[n] & ~(x_negative ^ y_negative); //make sure they have the same sign: NXOR determines when bits are equal
  assign gtbit = (~gtcarry[n] & y_negative) | (gtcarry[n] & ~x_negative);
  assign ltbit = ltcarry[n] | ~(eqbit | gtbit);
  // gtbit was the most complicated function since it has so many cases
  // Fortunately, k-maps exists so I just did that.
  //
  // g\xy  00  01  11  10
  //      -----------------
  //    0 | 0 | 1 | 1 | 0 |
  //      -----------------
  //    1 | 1 | 1 | 0 | 0 |
  //      -----------------
  //
  //    f(x,y,g) = g'y + gx'
  //
  // where x and y are 1 when their respective numbers are negative
  // and g returns true when the magnitude of x is greater than the magnitude of y.
  
  
  always @(eqbit, ltbit, gtbit)
  begin
    $display("eqbit: %b", eqbit);
    $display("gtbit: %b", gtbit);
    $display("ltbit: %b", ltbit);
  end
  
endmodule //comparator_tb1
