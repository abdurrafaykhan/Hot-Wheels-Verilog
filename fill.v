module fill
	(
	
		//initializes clock frequency
		CLOCK_50,	
		
		//Initializes inputs for the key, switches, hex display + ps2 inputs
		KEY,
		SW,
		HEX0, HEX1,
		PS2_CLK,
		PS2_DAT,
		
		
		// VGA related outputs
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B 							//	VGA Blue[9:0]
  						
	);
	
	//initializes clock frequency
	input			CLOCK_50;

	//Initializes inputs for the key, switches, hex display + ps2 inputs
	input	 [3:0] KEY;
	input  [9:0] SW;
	output [0:6] HEX0, HEX1;
	
	// VGA related outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[9:0]
	output	[7:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[9:0]
	
	//initializes variable for reset
	wire resetn;
	
	//assignes key[2] to reset the game
	assign resetn = KEY[3];
	
	//2 way stream for ps2 controller----------------------------------------------------------------------------
	inout				PS2_CLK;
	inout				PS2_DAT;
	wire 				signalStraight, signalRight, signalLeft;
	
	
	//Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [5:0] colour;
	wire [8:0] x;
	wire [7:0] y;
	wire writeEn;
	wire[7:0] secondsPassed;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
			
		//loads the background with given resolution and file
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 2;
		defparam VGA.BACKGROUND_IMAGE = "track.mif";
			
			
		projectTop P0(
			.Clock(CLOCK_50),
			.Resetn(resetn),
			.simReset(1'b0),
			.Start(SW[9]),
			.moveForward(signalStraight),
			.moveRight(signalRight),
			.moveLeft(signalLeft),
			.xDisplay(x),
			.yDisplay(y),
			.secondsPassed(secondsPassed),
			.colourDisplay(colour),
			.plotDisplay(writeEn));
		
		PS2_Call ps2call(
			// Inputs
			CLOCK_50,
			SW[9],

			// Bidirectionals
			PS2_CLK,
			PS2_DAT,
	
			// Outputs
			signalStraight, signalRight, signalLeft);
	
		hex7seg hex0(.c(secondsPassed[3:0]), .led(HEX0));
		hex7seg hex1(.c(secondsPassed[7:4]), .led(HEX1));
	
endmodule
