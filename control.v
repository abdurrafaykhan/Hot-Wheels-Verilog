module control(

	//takes in input for clock, reset, EnableOneFrame, starting the game, and directions of motion
	input Clock, Resetn, EnableOneFrame, start, forward, right, left,
	
	//takes in input for conditions of whether certain situations have been drawn and completed
	input DoneDrawBG, DoneDrawCar, DoneDrawErase, DoneDrawBoom, DoneDrawStartScreen, DoneDrawWinScreen, FinishedRace, Collision,
	
	//takes in storage variables for starting the race track display, and drawing all features
	output reg setResetSignals, startRace, drawBG, drawCar, drawErase, drawBoom, drawStartScreen, drawWinScreen, move, plot);
	
	//takes in storage values for current state and next state
	reg[3:0] current_state, next_state;

	
	//sets local parameters for the various states of the game
	localparam  DRAW_START_SCREEN = 0,
					START_RACE		   = 1,
					SET_RESET_SIGNALS = 2,
					DRAW_BACKGROUND   = 3,
					DRAW_CAR          = 4,
					WAIT_FOR_MOVE     = 5,
					DRAW_OVER_CAR     = 6,
					MOVE_FORWARD 	   = 7,
					MOVE_LEFT_RIGHT   = 8,
					WAIT_LEFT_RIGHT   = 9,
					DRAW_EXPLOSION    = 10,
					DRAW_WIN_SCREEN   = 11;
    
    // Next state logic aka our state table
    always@(*)
	 
	 //begins the state table
    begin: state_table 
		case (current_state)
		
			//When drawing the start screen
			DRAW_START_SCREEN:
			begin
				//if the start screen is done being drawn
				if(DoneDrawStartScreen)
				begin
					//if the game has finished and is not being played, draw start screen next
					if(!start && FinishedRace) next_state = DRAW_START_SCREEN;
					
					//if the game is to be played, start the ract next
					else if(start) next_state = START_RACE;
					
					//otherwise draw start screen next
					else next_state = DRAW_START_SCREEN;
				end
				
				//if start screen is not done being drawn, draw start screen next
				else next_state = DRAW_START_SCREEN;
			end
			
			//When the race is ready to start, draw background next
			START_RACE: next_state = DRAW_BACKGROUND;
			
			//when signals have been reset, draw the start screen for a game reset
			SET_RESET_SIGNALS: next_state = DRAW_START_SCREEN;
			
			//draw the background if the background has not been drawn
			//otherwise draw the car if the background has been drawn
			DRAW_BACKGROUND: next_state = DoneDrawBG ? DRAW_CAR : DRAW_BACKGROUND;
			
			//when car is being drawn
			DRAW_CAR: begin
			
				//if car is done being drawn
				if(DoneDrawCar) 
				begin
					//if the game has not started, reset signals next
					if(!start) next_state = SET_RESET_SIGNALS;
					//if the race is finished, draw the win screen next
					else if(FinishedRace) next_state = DRAW_WIN_SCREEN;
					//if collision has occured, draw explosion next
					else if(Collision) next_state = DRAW_EXPLOSION;
					//if user moves forward and EnableOneFrame is true, draw over car next
					else if(forward == 1'b1 && EnableOneFrame) next_state = DRAW_OVER_CAR;
					//if user turns left or right, then wait for the left/right turn  next
					else if(left == 1'b1 || right == 1'b1) next_state = WAIT_LEFT_RIGHT;
					//otherwise wait for move next
					else next_state = WAIT_FOR_MOVE;
				end
				//if the car is not drawn, draw the car
				else next_state = DRAW_CAR;
			end
			
			//when waiting for a move
			WAIT_FOR_MOVE: begin
				//if user moves forward and EnableOneFrame is true, draw over car next
				if(forward == 1'b1 && EnableOneFrame) next_state = DRAW_OVER_CAR;
				//if user turns left or right, then wait for the left/right turn  next
				else if(left == 1'b1 || right == 1'b1) next_state = DRAW_OVER_CAR;
				//otherwise wait for a move
				else next_state = WAIT_FOR_MOVE;
			end
			
			//when drawing over the car
			DRAW_OVER_CAR: begin
			
				//if the car has been drawn over
				if(DoneDrawErase) begin
				
					//if moving foward, move forward next
					if(forward == 1'b1) next_state = MOVE_FORWARD;
					//if moving left or right, move left/right next
					else if(left == 1'b1 || right == 1'b1) next_state = MOVE_LEFT_RIGHT;
					//otherwise draw car next
					else next_state = DRAW_CAR;
				end
				//if the car not been drawn over, draw the car over
				else next_state = DRAW_OVER_CAR;
			end
			
			//when moving forward, draw the car next
			MOVE_FORWARD: next_state = DRAW_CAR;
			
			//when movign left or right, draw the car next
			MOVE_LEFT_RIGHT: next_state = DRAW_CAR;
			
			//when waiting for left/right, wait for left/right again if car turned left or right
			//if car didnt turn left or right, then wait for move next
			WAIT_LEFT_RIGHT: next_state = (left == 1'b1 || right == 1'b1) ? WAIT_LEFT_RIGHT : WAIT_FOR_MOVE;
			
			//when drawing the explosion
			DRAW_EXPLOSION: begin
			
				//if explosion is done being drawn
				if(DoneDrawBoom) begin
				
					//if the game is in motion, draw explosion next
					if(start) next_state = DRAW_EXPLOSION;
					
					//otherwise reset signals next since game is not in motion
					else next_state = SET_RESET_SIGNALS;
				end
				//if explosion is not done being drawn, draw explosion
				else next_state = DRAW_EXPLOSION;
			end
			
			//when drawing the win screen
			DRAW_WIN_SCREEN: begin
			
				//if win screen is done being drawn
				if(DoneDrawWinScreen) begin
				
					//and the game has started already, draw win screen
					if(start) next_state = DRAW_WIN_SCREEN;
					
					//otherwise reset signals
					else next_state = SET_RESET_SIGNALS;
				end
				//if win screen is not done being drawn, draw win screen
				else next_state = DRAW_WIN_SCREEN;
			end
			
			//default case is to reset signals
			default: next_state = SET_RESET_SIGNALS;
		endcase
    end // state_table

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
		
		//sets values for all the cases
		setResetSignals = 1'b0;
		startRace = 1'b0;
		drawBG = 1'b0;
		drawCar = 1'b0;
		drawErase = 1'b0;
		drawBoom = 1'b0;
		drawStartScreen = 1'b0;
		drawWinScreen = 1'b0;
		move = 1'b0;
		plot = 1'b0;
	 
		  
        case (current_state)
		  
			//when drawing the start screen
			DRAW_START_SCREEN: begin
				//drawing start screen and plotting are true
				drawStartScreen = 1'b1;
				plot = 1'b1;
			end
			//when reseting signals, setResetSignals are ture
			SET_RESET_SIGNALS: setResetSignals = 1'b1;
			
			//when drawing background, drawbackground and plot are true
			DRAW_BACKGROUND: begin
				drawBG = 1'b1;
				plot = 1'b1;
			end
			
			//when starting race, startrace is true
			START_RACE: startRace = 1'b1;
			
			//when drawing car
			DRAW_CAR: begin
				//if car is done being drawn, plot is false
				if(DoneDrawCar) plot = 1'b0;
				
				//if car is not done being drawn
				//draw car and plot are true
				else begin
					drawCar = 1'b1;
					plot = 1'b1;
				end
			end
			
			//when drawing over the car
			DRAW_OVER_CAR: begin
			
				//if car isdone being drawn over, plot is false
				if(DoneDrawErase) plot = 1'b0;
				
				//if car is not done being drawn over
				//drawovercar and plot are true
				else begin
					drawErase = 1'b1;
					plot = 1'b1;
				end
			end
			
			//when moving forward, move is true
			MOVE_FORWARD: move = 1'b1;
		
			//when moving left/right, move is true
			MOVE_LEFT_RIGHT: move = 1'b1;
			
			//when drawing explosions
			DRAW_EXPLOSION: begin
				
				//if explosion is done being drawn, plot is false
				if(DoneDrawBoom) plot = 1'b0;
				
				//if explosion is not done being drawn
				//drawexplosion and plot are true
				else begin
					drawBoom = 1'b1;
					plot = 1'b1;
				end
			end
			
			//when drawing win screen, drawwinscreen and plot are true
			DRAW_WIN_SCREEN: begin
				drawWinScreen = 1'b1;
				plot = 1'b1;
			end
        endcase
    end // enable_signals
   
	
    // current_state registers
    always@(posedge Clock)
    begin: state_FFs
	 
			//when the game is being reset, set current state to set reset signals
        if(!Resetn)
           current_state <= SET_RESET_SIGNALS;
			  
		  //when the game is not being reset, move on the state so currentState = nextState
        else
            current_state <= next_state;
    end // state_FFS
	 
endmodule