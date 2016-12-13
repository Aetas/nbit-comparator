/************************************************
*																*
* Derek Prince												*
* ECEN 2350: Digital Logic								*
* 2n-bit Comparator on the terasiC DE0 board		*
* Altera Cyclone 3 EP3C16F484							*
*																*
* Date: 				October 11th, 2016				*
* Last Modified: 	October 16th, 2016				*
*																*
************************************************/


module comparator_tb1(SW, status_leds, seg7_0, seg7_1, seg7_2, seg7_3);
   //controls number of comparator instances
   parameter n = 2;

	//outputs
   output wire [9:0] status_leds;							//board leds
   output wire [0:6] seg7_0, seg7_1, seg7_2, seg7_3;	//7 segment displays
   //inputs
	input wire [9:0] SW;

	//connectors
	wire eqbit, gtbit, ltbit;
   wire eqdbbit, gtdbbit, ltdbbit;		//debugging bits
   wire negative_is_allowed = SW[9]; 	//switch 9 tells the program that negative numbers are allowed

	//registers
   reg unsigned [2*n-1:0] x, y;						//inputs, really
   reg x_negative, y_negative;       	//I don't want these to be continuous assignment, thus registers

	//switch assignments
   always @(SW)
   begin: switchAssignments
		x[0] = SW[4];	//Assignments are done so that x is input on the left, y is input on the right. left->right.
		x[1] = SW[5];
		x[2] = SW[6];
		x[3] = SW[7];
		y[0] = SW[0];
		y[1] = SW[1];
		y[2] = SW[2];
		y[3] = SW[3];

		if (x_negative)		//these if statements are protected against unsigned because of how the variables are assigned. (see one block below)
			x = ~x + 4'b0001; // undo 2's compliment
		if (y_negative)		//x&y negative follow the slider, not x.
			y = ~y + 4'b0001;	//This allows me to change the register values without continuous assignments causing havok
   end

   assign status_leds[9] = negative_is_allowed;
   assign status_leds[8] = 1'b0;	//This is unused, I just want a determined value

	always @(negative_is_allowed, SW)
	begin: determineNegative
		x_negative = SW[7] & negative_is_allowed; // These are 1 if x or y are negative (respectively)
		y_negative = SW[3] & negative_is_allowed;
		// They are masked with negative_is_allowed because it forces 0 values when they are unsigned
		// i.e. positive
	end

   wire [n:0] eqcarry, gtcarry, ltcarry;
   //I only need an n+1 bit wide wire because there are only n stages of comparators and these link the stages but I need one more for the carry
   //otherwise final stage overflows X. Similarly, this could be done with an initial comparator block that is static to set up the sequence
   //This would mean the carries would return to n-bit widths
   assign eqcarry[0] = 1;	//sets the initial values for the first comparator stage
   assign gtcarry[0] = 0;	//continuous assignment is fine since these never change
   assign ltcarry[0] = 0;
   // I want these to be 0 initially so that it does not change the initial setup of a comparator
   // eq is 1 because it is anded with the evaluation. others are 0 because of OR

   //------------Comparison block------------//
   generate
      genvar k;
 	      for (k = 0; k < 2*n; k = k + 2)  //add 2 because we are working with pairs of bits.
 	      //Since the module works by assuming the msbs were the input 5bit pairs, k+2*n-1 assures the instantiation goes down the line as genvar k goes up.
	      begin: comparestage
			   doublencomparator dnc((x[2*n-1-k]), (x[2*n-2-k]), (y[2*n-1-k]), (y[2*n-2-k]),
	                              (eqcarry[k/2]), (gtcarry[k/2]), (ltcarry[k/2]),
	                              (eqcarry[k/2+1]), (gtcarry[k/2+1]), (ltcarry[k/2+1]));  //just trying out this syntax.
			end
   endgenerate

   //------------Output Block------------//
   assign eqbit = eqcarry[n] & ~(x_negative ^ y_negative); //make sure they have the same sign: NXOR determines when bits are equal
   assign gtbit = ((~gtcarry[n] & y_negative) | (gtcarry[n] & ~x_negative)) & ~eqbit;
   assign ltbit = ~(eqbit | gtbit);
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
	// The result is and-ed with eqbit's complement to catch the case of both numbers being negative but also equal.
	// 	it only adds 3 cost and is much simpler than adding another, neraly identical function to the one from the k-map.

   assign status_leds[7] = eqbit;
   assign status_leds[6] = gtbit;
	assign status_leds[5] = ltbit;

	//------------7-Segment Display Output------------//
	seg7 hex2(.bnum(x), .led(seg7_2));	//Using displays 2 and 0 to display negatives
	seg7 hex0(.bnum(y), .led(seg7_0));	//on the displays just left of the number
	assign seg7_3[0:5] = 6'b111111;
	assign seg7_1[0:5] = 6'b111111;
	assign seg7_3[6] = ~x_negative;		//display negative signs if negative
	assign seg7_1[6] = ~y_negative;


   //------------Simple debugging checker------------//
   assign eqdbbit = (x == y) & (x_negative == y_negative);
   assign gtdbbit = ((~(x > y) & y_negative) | ((x > y) & ~x_negative)) & ~eqdbbit;	//same logic as above, just with direct arithmetic comparison
   assign ltdbbit = ~(eqdbbit | gtdbbit);
   assign status_leds[3] = eqdbbit;
   assign status_leds[2] = gtdbbit;
   assign status_leds[1] = ltdbbit;
   assign status_leds[0] = {eqdbbit, gtdbbit, ltdbbit} == {eqbit, gtbit, ltbit};	//This compares the two answers

endmodule //comparator_tb1
