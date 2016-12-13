/************************************************
*                                               *
* Derek Prince                                  *
* ECEN 2350: Digital Logic                      *
* 2n-bit Comparator on the terasiC DE0 board    *
* Altera Cyclone 3 EP3C16F484                   *
*	                                              *
* Date: 				October 11th, 2016              *
* Last Modified: 	October 16th, 2016            *
*                                               *
*************************************************

Copyright (c) 2016 Derek Prince

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

// X has priority. Meaning, if greater than is 1: X is greater than Y. Same goes for lt = 1.
module doublencomparator(x0, x1, y0, y1, eqin, gtin, ltin, eqout, gtout, ltout);

	input x0, x1, y0, y1;				// input bit pairs
	input eqin, gtin, ltin;				// carry inputs (eq = equal, gt = greater than, lt = less than)
	output eqout, gtout, ltout;		// outputs

	// Equality
	// every bit needs to be equal for it to be equal. Astonishing, right?
	// This means that if eqin is 0 already, the whole thing is 0.
	// Which is good, otherwise the final output might say that 0001 is equal to 1101.
	assign eqout = eqin & (x0 ~^ y0) & (x1 ~^ y1);
	// COST:
	// If we assume the XOR gate is a NAND, AND, & OR gate, each with only two inputs, that means one XOR has a cost of 9.
	// I'm choosing not to include the NAND gate as an AND followed by an OR because an AND gate is made by inverting the output of a NAND.
	// So the NAND is cheaper and it would be stupid to say a NAND has the cost of a NAND and two NOTs.
	// ------------------------------------------------
	// Moving on, this gives me a cost of 15 for eqout.

	// Greater Than
	// I did a few versions of this function that were very short but they would always miss ~100 of 56k possibilities.
	// So I just made a kmap of the inputs and the carry in bit.
	// Since this does not cover the acse of the previous bits being less than, I AND-ed it with the less than in bit to cover that case.
	//
	// gx0\x1y0y1    000 001 011 010  100 101 111 110
   //              ----------------------------------
   //          00  | 0 | 0 | 0 | 0 || 1 | 0 | 0 | 0 |
   //              ----------------------------------
   //          01  | 1 | 1 | 0 | 0 || 1 | 1 | 0 | 1 |
   //              ----------------------------------
   //          11  | 1 | 1 | 1 | 1 || 1 | 1 | 1 | 1 |
   //              ----------------------------------
   //          10  | 1 | 1 | 1 | 1 || 1 | 1 | 1 | 1 |
   //              ----------------------------------
   //
   //          f = g + y0'x' + x1y0'y1' + x0x1y0y1'
   //
   // Looking at this, it's clear that each input to the OR gate covers one case where x is greater than y.
   // I was hoping for a more condensed version of this but oh well.
	assign gtout = (gtin | (x0 & ~y0) | (x1 & ~y0 & ~y1) | (x0 & x1 & y0 & ~y1)) & ~ltin;
	// COST:
	// This function is by far the most expensive because it has the most cases.
	// ltout is easy because it's the default case if eqout and gtout are 0.
	// ---------------------------------------------
	// Just add the inputs and outputs as normal: 29

	// Less Than
	// This one is the simplest of all purely because the other two
	// are done already and the output can only have one 'state'
	// So just check if either of the other outputs are true and
	// assign lt true if they are not.
	// And remember to carry the input
	assign ltout = ltin | ~(eqout | gtout);
	// COST:
	// --------------------------------------------
	// Just add the inputs and outputs as normal: 8

	// TOTAL COST:
	// 52

	// As a side note, ltout is a redundant calculation that isn't required to carry through.
	// e.g. If there are 3 states and the output is neither of the first two states, then by default is has to be the third state.
	// This would mean that each module could cut off 8 cost.
	// Since the same check is performed at the output so that 2's compliment numbers can use the same circuitry,
	// this has zero drawbacks and is only included because the assignment specifically requested it.
	// Another thing to consider is that a 2-to-1 mux is a much cheaper way of implementing an xor gate
	// and is more than likely what the FPGA does at compilation. So the actual cost is cut down even more.

endmodule //doublencomparator
