module PS2_Call (

	// Initializes a clock and reset input, alongside two bidirectional inouts for the PS2
	input	CLOCK_50, input Resetn, inout	PS2_CLK, inout	PS2_DAT,
	
	// Initializes three output wires for the three directions that the car is allowed to move in the game
	output wire signalStraight, output wire signalRight, output wire signalLeft
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

 // Instantiates with the inputs module that is later defined in this file
 inputs detector(.CLOCK_50(CLOCK_50),
					  .signalStraight(signalStraight),
					  .signalLeft(signalLeft),
					  .signalRight(signalRight),
					  .ps2_key_pressed(ps2_key_pressed),
					  .ps2_key_data(last_data_received),
					  .Resetn(Resetn));
	
	
/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
	
	/*****************************************************************************
	 *                 Internal Wires and Registers Declarations                 *
	 *****************************************************************************/

	// Internal Wires
	wire		[7:0]	ps2_key_data;
	wire				ps2_key_pressed;

	// Internal Registers
	reg			[7:0]	last_data_received;
	
	// State Machine Registers

	/*****************************************************************************
	 *                             Sequential Logic                              *
	 *****************************************************************************/

	always @(posedge CLOCK_50)
	begin
		// Only enters if the reset key is not pressed
		if(!Resetn)
			// Stores 
			last_data_received <= 8'h00;
		else if(ps2_key_pressed == 1'b1)
			last_data_received <= ps2_key_data;
	end


	/*****************************************************************************
	 *                              Internal Modules                             *
	 *****************************************************************************/

	PS2_Controller PS2 (
		// Inputs
		.CLOCK_50(CLOCK_50),
		.reset(!Resetn),

		// Bidirectionals
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),

		// Outputs
		.received_data		(ps2_key_data),
		.received_data_en	(ps2_key_pressed)
	);
	
endmodule


module inputs(CLOCK_50, signalStraight, signalLeft, signalRight, ps2_key_pressed, ps2_key_data, Resetn);
 // Inputs for the clock, reset, and the detection of which ps2 is pressed
 input CLOCK_50,  ps2_key_pressed, Resetn;
 
 input [7:0] ps2_key_data;
 // Three directions that the car moves
 output reg signalStraight, signalLeft, signalRight;
 
 // The current state and next state for the finite state machine
 reg[3:0] current_state, next_state;
	
	localparam  
				// "Make" code is sent when the key is pressed down, and repeated periodically if the key is held down.
				E0 = 4'd0, 
				// The "break" code is sent when the key is released. 
				F0 = 4'd1, 
				// Initializes arbitrary values to the car movements
				WAIT = 4'd2,
				LEFT = 4'd3,
				RIGHT = 4'd4,
				STRAIGHT = 4'd5,
				LEFT_BREAK = 4'd6,
				RIGHT_BREAK = 4'd7,
				STRAIGHT_BREAK = 4'd8;
    
    // Next state logic
    always@(*)
    begin: state_table 
		// The current state
		case (current_state)
			WAIT: begin
				// make 
				if (ps2_key_data == 8'hE0 && ps2_key_pressed) next_state = E0;
				// break
				else if(ps2_key_data == 8'hF0 && ps2_key_pressed) next_state = F0;
				// goes back to wait, this is essentially a loop to detect a keyboard click
				else next_state = WAIT;
			end
			
			// begins if they key is pressed down or repeatedly held
			E0: begin
				// E0'75 is the hex for the up key
				if(ps2_key_data == 8'h75) next_state = STRAIGHT;
				// E0'6B is the hex for the left key
				else if(ps2_key_data == 8'h6B) next_state = LEFT;
				// E0'74 is the hex for the right key
				else if(ps2_key_data == 8'h74) next_state = RIGHT;
				// if they key is released, then move on to break
				else if (ps2_key_data == 8'hF0) next_state = F0;
				// detects a key press again
				else next_state = WAIT;
			end
			
			// begins if the key is released
			F0: begin
				// E0'75 is the hex for the up key
				if(ps2_key_data == 8'h75) next_state = STRAIGHT_BREAK;
				// E0'6B is the hex for the left key
				else if(ps2_key_data == 8'h6B) next_state = LEFT_BREAK;
				// E0'74 is the hex for the right key
				else if(ps2_key_data == 8'h74) next_state = RIGHT_BREAK;
				// detects a key press again
				else next_state = WAIT;
			end
			
			// the movements detected will lead back to the wait
			LEFT: next_state = WAIT;
			RIGHT: next_state = WAIT;
			STRAIGHT: next_state = WAIT;
			LEFT_BREAK: next_state = WAIT;
			RIGHT_BREAK: next_state = WAIT;
			STRAIGHT_BREAK: next_state = WAIT;
			
			// set default to wait as we want to know whether a key is pressed or released
			default: next_state = WAIT;
		endcase
	end
	
	
	always @(posedge CLOCK_50) begin
		// default false values for car movements 
		if (!Resetn) begin
			signalStraight <= 1'b0;
			signalLeft <= 1'b0;
			signalRight <= 1'b0;
		end
		
		// Sets signals to true if there is no break and false if there is a break
		else if (current_state == STRAIGHT) signalStraight <= 1'b1;
		else if(current_state == LEFT) signalLeft <= 1'b1;
		else if(current_state == RIGHT) signalRight <= 1'b1;
		else if (current_state == STRAIGHT_BREAK) signalStraight <= 1'b0;
		else if (current_state == LEFT_BREAK) signalLeft <= 1'b0;
		else if (current_state == RIGHT_BREAK) signalRight <= 1'b0;

	end
		
	always@(posedge CLOCK_50)
	/*********************************************WHY STATE_FFs**********************************/
    begin: state_FFs
		  // default is to wait for user input
        if(!Resetn)
           current_state <= WAIT;
		  // if reset is clicked, then the display will remain the same and the current state will point to the next state
        else
            current_state <= next_state;
    end
	 
endmodule
