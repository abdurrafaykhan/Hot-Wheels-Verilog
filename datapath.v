module datapath(

	//initialize inputs for clock, reset and moving in 3 directions
	input Clock, Resetn, moveForward, moveRight, moveLeft,
	
	//initialize inputs for setting reset signals, starting the race, drawing the background, car and over the car
	input setResetSignals, startRace, drawBG, drawCar, drawErase, 
	
	//initialize inputs for moving, drawing explosion and the start/win screen
	input move, drawBoom, drawStartScreen, drawWinScreen,
	
	//initialize output for checking if the background, car, drawover car have been drawn and if the race is finished
	output reg DoneDrawBG, DoneDrawCar, DoneDrawErase, FinishedRace, 
	
	//initalize output that checks for collision, whether the explosion, start screen and win screen has been draw
	output reg Collision, DoneDrawBoom, DoneDrawStartScreen, DoneDrawWinScreen,
	
	//initalize output for the colour, x position and y position to be displayed
	output reg[5:0] colourDisplay,
	output reg[7:0] yDisplay,
	output reg[8:0] xDisplay);
	
	//----------------------------------RAM, Registers, and Wires----------------------------------
	
	
	//sets local paramaters 
	localparam orientRight          = 0,
				  orientUpRightRight   = 1,	
			     orientUpRight   	  = 2,
				  orientUpUpRight 	  = 3,
			     orientUp        	  = 4,
				  orientUpUpLeft 		  = 5,
				  orientUpLeft    	  = 6,
				  orientUpLeftLeft 	  = 7,
			     orientLeft      	  = 8,
				  orientDownLeftLeft   = 9,
			     orientDownLeft  	  = 10,
				  orientDownDownLeft   = 11,
			     orientDown      	  = 12,
				  orientDownDownRight  = 13,
			     orientDownRight 	  = 14,
				  orientDownRightRight = 15;
	
	
	//addresses for ROM files
	reg[13:0] carAddress = 14'd0;
	reg[16:0] backgroundAddress = 17'd0;
	reg[16:0] startScreenAddress = 17'd0;
	reg[16:0] winScreenAddress = 17'd0;
	reg[9:0] boomAddress = 10'd0;
	
	
	//bits used for the ROM files that are used in displaying pixels
	wire[5:0] carColourToDisplay;
	wire[5:0] backgroundColourToDisplay;
	wire[5:0] boomColourToDisplay;
	wire[5:0] winScreenColourToDisplay;
	wire[5:0] startScreenColourToDisplay;

	
	//only being used to read the rom files, not write
	car_rom carRom(
		.address(carAddress),
		.clock(Clock),
		.q(carColourToDisplay));
		
	race_track_rom track(
		.address(backgroundAddress),
		.clock(Clock),
		.q(backgroundColourToDisplay));
		
	boom_rom boom(
		.address(boomAddress), 
		.clock(Clock),
		.q(boomColourToDisplay));

	win_screen_rom win(
		.address(winScreenAddress), 
		.clock(Clock),
		.q(winScreenColourToDisplay));

	start_screen_rom start(
		.address(startScreenAddress), 
		.clock(Clock),
		.q(startScreenColourToDisplay));
	
	
	//creates variables used for checking if the car past the finished line 
	//creates storage variables for the x and y position as well as counters for the positions
	//creates storage variable for the orientation and how many pixels are to be moved 
	reg pastStartLine = 1'b0;
	reg[7:0] yCount = 8'd0;
	reg[7:0] currentYPosition = 8'd0;
	reg[8:0] xCount = 9'd0;
	reg[8:0] currentXPosition = 9'd0;
	reg[3:0] currentOrientation = orientRight;
	localparam pixelsToMove = 2;
	
	//----------------------------------Operations Based on Input----------------------------------
	
	
	//occurs at every iteration of the posedge clock
	always@(posedge Clock) begin
	
		//------------------------------------Resetting Signals------------------------------------
		
		
		//if resetting signals
		if(setResetSignals) begin
			
			//sets all the values for the storage variables to 0
			backgroundAddress <= 17'd0;
			carAddress <= 14'd0;
			boomAddress <= 10'd0;
			startScreenAddress <= 17'd0;
			winScreenAddress <= 17'd0;
			currentXPosition <= 9'd0;
			currentYPosition <= 8'd0;
			xCount <= 9'd0;
			yCount <= 8'd0;
			DoneDrawBG <= 1'b0;
			DoneDrawCar <= 1'b0;
			DoneDrawBoom <= 1'b0;
			DoneDrawErase <= 1'b0;
			Collision <= 1'b0;
			currentOrientation <= orientRight;
			FinishedRace <= 1'b1;
			pastStartLine <= 1'b0;
			DoneDrawStartScreen <=1'b0;
			DoneDrawWinScreen <= 1'b0;
		end
		
		//if the game has started, then set FinishedRace to 0 since the game is not finished
		if(startRace) FinishedRace <= 1'b0;
		
		
		//------------------------------------Drawing Start Screen------------------------------------
		
		//while the start screen is being drawn
		if(drawStartScreen && !DoneDrawStartScreen)
		
		begin
			
			//set the colour to be displayed as the one read from the rom file of the start screen
			//while moving through the image
			colourDisplay <= startScreenColourToDisplay;
			xDisplay <= currentXPosition + xCount;
			yDisplay <= currentYPosition + yCount;
			
			//if the rom file reaches the end, then reset the addresses and set DoneDrawStartScreen to true
			if(xCount == 9'd319 && yCount == 8'd239)
			begin
				xCount <= 9'd0;
				yCount <= 8'd0;
				
				currentXPosition <= 9'd0;
				currentYPosition <= 8'd0;
				startScreenAddress <= 17'd0;
				DoneDrawStartScreen <= 1'b1;
			end
			
			//if the rom file reaches the end of the row, then start at the beginning of the row underneath
			else if(xCount == 9'd319)
			begin
				xCount <= 9'd0;
				yCount <= yCount + 8'd1;
				startScreenAddress <= startScreenAddress + 17'd1;
				DoneDrawStartScreen <= 1'b0;
			end
			
			//moves through the row of the rom
			else begin
				xCount <= xCount + 9'd1;
				startScreenAddress <= startScreenAddress + 17'd1;
				DoneDrawStartScreen <= 1'b0;
			end
		end
		

		//------------------------------------Drawing Win Screen------------------------------------

		//while drawing the win screen
		if(drawWinScreen && !DoneDrawWinScreen)
		begin
			
			//set the colour to be displayed as the one read from the rom file of the start screen
			//while moving through the image
			colourDisplay <= winScreenColourToDisplay;
			xDisplay <= currentXPosition + xCount;
			yDisplay <= currentYPosition + yCount;
			
			//if the rom file reaches the end, then reset the addresses and set DoneDrawWinScreen to true
			if(xCount == 9'd319 && yCount == 8'd239)
			begin
				xCount <= 9'd0;
				yCount <= 8'd0;
				
				currentXPosition <= 9'd0;
				currentYPosition <= 8'd0;
				winScreenAddress <= 17'd0;
				DoneDrawWinScreen <= 1'b1;
			end

			//if the rom file reaches the end of the row, then start at the beginning of the row underneath
			else if(xCount == 9'd319)
			begin
				xCount <= 9'd0;
				yCount <= yCount + 8'd1;
				winScreenAddress <= winScreenAddress + 17'd1;
				DoneDrawWinScreen <= 1'b0;
			end
			
			//moves through the row of the rom
			else begin
				xCount <= xCount + 9'd1;
				winScreenAddress <= winScreenAddress + 17'd1;
				DoneDrawWinScreen <= 1'b0;
			end
		end
		
	
		//------------------------------------Drawing Background------------------------------------
		
		//while drawing the background
		if(drawBG && !DoneDrawBG) begin
		
			//set the colour to be displayed as the one read from the rom file of the start screen
			//while moving through the image
			colourDisplay <= backgroundColourToDisplay; 
			xDisplay <= currentXPosition + xCount;
			yDisplay <= currentYPosition + yCount;
			
			
			//if the rom file reaches the end, then reset the addresses and set DoneDrawBG to true
			//after drawing the background, sets the x and y position to that of the car's position
			if(xCount == 9'd319 && yCount == 8'd239)
			begin
				xCount <= 9'd0;
				yCount <= 8'd0;
				
				currentXPosition <= 9'd94; 
				currentYPosition <= 8'd193;
				backgroundAddress <= (320 * 193) + 94;
				
				DoneDrawBG <= 1'b1;
			end
			
			//if the rom file reaches the end of the row, then start at the beginning of the row underneath
			else if(xCount == 9'd319)
			begin
				xCount <= 9'd0;
				yCount <= yCount + 8'd1;
				backgroundAddress <= backgroundAddress + 17'd1;
				DoneDrawBG <= 1'b0;
			end
			
			//moves through the row of the rom
			else begin
				xCount <= xCount + 9'd1;
				backgroundAddress <= backgroundAddress + 17'd1;
				DoneDrawBG <= 1'b0;
			end
		end
		
		//---------------------------------------Drawing Car---------------------------------------
		
		
		//while drawing car
		else if(drawCar && !DoneDrawCar) begin
			
			
			//to erase the background in the rom file, detect given colour and plot background at those pixels
			if(carColourToDisplay == 6'b100010) begin
				colourDisplay <= backgroundColourToDisplay;
				xDisplay <= currentXPosition + xCount;
				yDisplay <= currentYPosition + yCount;
			end
			
			//draws the car
			else begin
				colourDisplay <= carColourToDisplay; // Colour of sprite at current position
				xDisplay <= currentXPosition + xCount;
				yDisplay <= currentYPosition + yCount;
			end
			
			//after drawing the car, reset counter and restore address to the top left corner of the box
			if(xCount == 9'd31 && yCount == 8'd31) begin
				xCount <= 9'd0;
				yCount <= 8'd0;
				backgroundAddress <= backgroundAddress + (-(320 * 31) - 31);
				DoneDrawCar <= 1'b1;
			end
			
			//if the rom file reaches the end of the row, then start at the beginning of the row underneath
			else if(xCount == 9'd31) begin
				xCount <= 9'd0;
				yCount <= yCount + 8'd1;
				carAddress <= carAddress + 14'd1;
				backgroundAddress <= backgroundAddress + (320 - 31);
				DoneDrawCar <= 1'b0;
			end
			
			//moves through the row of the rom
			else begin
				xCount <= xCount + 9'd1;
				carAddress <= carAddress + 14'd1;
				backgroundAddress <= backgroundAddress + 17'd1;
				DoneDrawCar <= 1'b0;
			end
			
			//checking if the car address is not purple at a given location
			//and background is green						
			if(backgroundColourToDisplay == 6'b001001 && carColourToDisplay !=  6'b100010) begin
				DoneDrawCar <= 1'b1; 
				Collision <= 1'b1; 
				backgroundAddress <= backgroundAddress + (-(320 * yCount) - xCount); 
				xCount <= 9'd0; 
				yCount <= 8'd0;

			end
		end
		
		//---------------------------------------Drawing Explosion---------------------------------------
		
		//while drawing the explosion
		if(drawBoom && !DoneDrawBoom) begin
			
			
			//outputs the explosion display
			colourDisplay <= boomColourToDisplay; 
			xDisplay <= currentXPosition + xCount;
			yDisplay <= currentYPosition + yCount;
			
			
			//resets signals when explosion has been drawn
			if(xCount == 9'd31 && yCount == 8'd31) begin
				xCount <= 9'd0;
				yCount <= 8'd0;
				backgroundAddress <= backgroundAddress + (-(320 * 31) - 31);
				DoneDrawBoom <= 1'b1;
				FinishedRace <= 1'b1;
			end
			
			//if the rom file reaches the end of the row, then start at the beginning of the row underneath
			//and goes to the next row of the background as well keeping the dimensions of the rom in mind (-31)
			else if(xCount == 9'd31) begin
				xCount <= 9'd0;
				yCount <= yCount + 8'd1;
				boomAddress <= boomAddress + 10'd1;
				backgroundAddress <= backgroundAddress + (320 - 31);
				DoneDrawBoom <= 1'b0;
			end
			
			//moves through the row of the rom
			else begin
				xCount <= xCount + 9'd1;
				boomAddress <= boomAddress + 10'd1;
				backgroundAddress <= backgroundAddress + 17'd1;
				DoneDrawBoom <= 1'b0;
			end
		end
		
		//while drawing over the car
		if(drawErase && !DoneDrawErase) begin
		
			//erase the car and replace with background display
			colourDisplay <= backgroundColourToDisplay; 
			xDisplay <= currentXPosition + xCount;
			yDisplay <= currentYPosition + yCount;
			
			//once the car has been erased, reset count and restore address to top left corner of car box
			if(xCount == 9'd31 && yCount == 8'd31) begin
				xCount <= 9'd0;
				yCount <= 8'd0;
				backgroundAddress <= backgroundAddress + (-(320 * 31) - 31);
				DoneDrawErase <= 1'b1;
			end
			
			//if the rom file reaches the end of the row, then start at the beginning of the row underneath
			//and goes to the next row of the background as well keeping the dimensions of the rom in mind (-31)
			else if(xCount == 9'd31) begin
				xCount <= 9'd0;
				yCount <= yCount + 8'd1;
				backgroundAddress <= backgroundAddress + (320 - 31);
				DoneDrawErase <= 1'b0;
			end
			
			//moves through the row of the rom
			else begin
				xCount <= xCount + 9'd1;
				backgroundAddress <= backgroundAddress + 17'd1;
				DoneDrawErase <= 1'b0;
			end
		end
		
		//---------------------------------------Moving Car---------------------------------------
		
		// If move is true, then enter this if statement
		if(move) begin
	
			// Signals from drawing are reset to prepare for the next draw
			DoneDrawBG <= 1'b0;
			DoneDrawCar <= 1'b0;
			DoneDrawErase <= 1'b0;
			DoneDrawWinScreen <= 1'b0;
			DoneDrawStartScreen <= 1'b0;

			// enter this case regardless of what orientation the car is in
			case(currentOrientation)
				// if the car is pointing to the right
				orientRight: begin
					// if the user wants to move forward
					if(moveForward) begin
						carAddress <= orientRight * 1024;
						// orientation doesn't change if the user moves forward -- it is still right
						currentOrientation <= orientRight;
						backgroundAddress <= backgroundAddress + pixelsToMove;
						// Car moves right by 2 pixels, only x position changes
						currentXPosition <= currentXPosition + pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						// Moves to a different sprite 
						carAddress <= orientDownRightRight * 1024; 
						// orientation changed to -45 degrees
						currentOrientation <= orientDownRightRight;
						// Car stays at the same location, no need to change x and y position
					end
					else if (moveLeft) begin
						carAddress <= orientUpRightRight * 1024; // Car stays at the same location
						// orientation changes to 45 degrees
						currentOrientation <= orientUpRightRight;
					end
				end
				
				// orientation when car is at 22.5 degrees
				orientUpRightRight: begin
					// if the user presses the forward key
					if(moveForward) begin
						carAddress <= orientUpRightRight * 1024;
						// orienation stays the same
						currentOrientation <= orientUpRightRight;
						backgroundAddress <= backgroundAddress + (-(320 * (pixelsToMove - 1)) + pixelsToMove);
						currentXPosition <= currentXPosition + pixelsToMove;
						currentYPosition <= currentYPosition - (pixelsToMove - 1);
					end
					// if the user presses the right key 
					else if(moveRight) begin
						carAddress <= orientRight * 1024;
						// orientation reverts back to 0 degrees
						currentOrientation <= orientRight;
					end
					// if user presses the left key
					else if (moveLeft) begin
						carAddress <= orientUpRight * 1024;
						// orientation is 45 degrees
						currentOrientation <= orientUpRight;
					end
				end
				
				// orientation when car is 45 degrees
				orientUpRight: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientUpRight * 1024;
						// orientation is 45 degrees
						currentOrientation <= orientUpRight;
						backgroundAddress <= backgroundAddress + (-(320 * pixelsToMove) + pixelsToMove);
						// x and y both change at constant rate
						currentXPosition <= currentXPosition + pixelsToMove;
						currentYPosition <= currentYPosition - pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientUpRightRight * 1024;
						// orientation is 22.5 degrees
						currentOrientation <= orientUpRightRight;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientUpUpRight * 1024;
						// orientation is 67.5 degrees
						currentOrientation <= orientUpUpRight;
					end
				end
				// orientation of car is 67.5 degrees
				orientUpUpRight: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientUpUpRight * 1024;
						// orientation remains the same
						currentOrientation <= orientUpUpRight;
						backgroundAddress <= backgroundAddress + (-(320 * pixelsToMove) + (pixelsToMove - 1));
						// x position changes slightly
						currentXPosition <= currentXPosition + (pixelsToMove - 1);
						// car goes up, so pixels get subtracted from the y position
						currentYPosition <= currentYPosition - pixelsToMove;
					end
					else if(moveRight) begin
						carAddress <= orientUpRight * 1024;
						currentOrientation <= orientUpRight;
					end
					else if(moveLeft) begin
						carAddress <= orientUp * 1024;
						currentOrientation <= orientUp;
					end
				end
				
				// orientation when car is 90 degrees
				orientUp: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientUp * 1024;
						// orientation stays the same
						currentOrientation <= orientUp;
						backgroundAddress <= backgroundAddress - (320 * pixelsToMove);
						// car goes up, so pixels get subtracted from the y position
						currentYPosition <= currentYPosition - pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientUpUpRight * 1024;
						// orientation is 67.5 degrees
						currentOrientation <= orientUpUpRight;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientUpUpLeft * 1024;
						// orientation is 112.5 degrees
						currentOrientation <= orientUpUpLeft;
					end
				end
				// orientation is 112.5 degrees
				orientUpUpLeft: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientUpUpLeft * 1024;
						// orientation remains the same
						currentOrientation <= orientUpUpLeft;
						backgroundAddress <= backgroundAddress + (-(320 * pixelsToMove) - (pixelsToMove - 1));
						// x position changes slightly 
						currentXPosition <= currentXPosition - (pixelsToMove - 1);
						// car goes up, so pixels get subtracted from the y position
						currentYPosition <= currentYPosition - pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientUp * 1024;
						// orientation is 90 degrees 
						currentOrientation <= orientUp;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientUpLeft * 1024;
						// orientation is 135 degrees
						currentOrientation <= orientUpLeft;
					end
				end
				// orientation is 135 degrees
				orientUpLeft: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientUpLeft * 1024;
						// orientation stays the same
						currentOrientation <= orientUpLeft;
						backgroundAddress <= backgroundAddress + (-(320 * pixelsToMove) - pixelsToMove);
						// x and y positions both decrease at same rate
						currentXPosition <= currentXPosition - pixelsToMove;
						currentYPosition <= currentYPosition - pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientUpUpLeft * 1024;
						// orientation is 112.5 degrees
						currentOrientation <= orientUpUpLeft;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientUpLeftLeft * 1024;
						// orientation is 157.5 degrees
						currentOrientation <= orientUpLeftLeft;
					end
				end
				// orientation is 157.5 degrees
				orientUpLeftLeft: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientUpLeftLeft * 1024;
						// orientation is the same
						currentOrientation <= orientUpLeftLeft;
						backgroundAddress <= backgroundAddress + (-(320 * (pixelsToMove - 1)) - pixelsToMove);
						// y changes slightly, x moves at the regular rate
						currentXPosition <= currentXPosition - pixelsToMove;
						currentYPosition <= currentYPosition - (pixelsToMove - 1);
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientUpLeft * 1024;
						// oritentation is 135 degrees
						currentOrientation <= orientUpLeft;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientLeft * 1024;
						// orientation is 180 degrees
						currentOrientation <= orientLeft;
					end
				end
				// orientation is 180 degrees
				orientLeft: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientLeft * 1024;
						currentOrientation <= orientLeft;
						backgroundAddress <= backgroundAddress - pixelsToMove;
						// only x changes at constant rate
						currentXPosition <= currentXPosition - pixelsToMove;
					end
					// if user pressses  right
					else if(moveRight) begin
						carAddress <= orientUpLeftLeft * 1024;
						// orientation is 157.5 degrees
						currentOrientation <= orientUpLeftLeft;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientDownLeftLeft * 1024;
						// orientation is 202.5 degrees
						currentOrientation <= orientDownLeftLeft;
					end
				end
				// orientation is 202.5 degrees
				orientDownLeftLeft: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientDownLeftLeft * 1024;
						// orientation remains the same
						currentOrientation <= orientDownLeftLeft;
						backgroundAddress <= backgroundAddress + (320 * (pixelsToMove - 1) - pixelsToMove);
						// x changes constantly, y changes slightly
						currentXPosition <= currentXPosition - pixelsToMove;
						currentYPosition <= currentYPosition + (pixelsToMove - 1);
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientLeft * 1024;
						// orientation is 180 degrees
						currentOrientation <= orientLeft;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientDownLeft * 1024;
						// orientation is 247.5 degrees
						currentOrientation <= orientDownLeft;
					end
				end
				// orientation is 247.5 degrees
				orientDownLeft: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientDownLeft * 1024;
						// orientation remains the same
						currentOrientation <= orientDownLeft;
						backgroundAddress <= backgroundAddress + ((320 * pixelsToMove) - pixelsToMove);
						// y and x both change constantly, but y increases since the car goes down
						currentXPosition <= currentXPosition - pixelsToMove;
						currentYPosition <= currentYPosition + pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientDownLeftLeft * 1024;
						// orientation is 202.5 degrees
						currentOrientation <= orientDownLeftLeft;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientDownDownLeft * 1024;
						// orientation is 247.5 degrees
						currentOrientation <= orientDownDownLeft;
					end
				end
				// orientation is 247.5 degrees
				orientDownDownLeft: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientDownDownLeft * 1024;
						// orientation is 247.5 degrees
						currentOrientation <= orientDownDownLeft;
						backgroundAddress <= backgroundAddress + (320 * pixelsToMove - (pixelsToMove - 1));
						// y changes constantly but x moves at a slower rate
						currentXPosition <= currentXPosition - (pixelsToMove - 1);
						currentYPosition <= currentYPosition + pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientDownLeft * 1024;
						// orientation is 225 degrees
						currentOrientation <= orientDownLeft;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientDown * 1024;
						// orientation is 270 degrees
						currentOrientation <= orientDown;
					end
				end
				// orientation is 270 degrees
				orientDown: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientDown * 1024;
						// orientation stays the same
						currentOrientation <= orientDown;
						backgroundAddress <= backgroundAddress + (320 * pixelsToMove);
						// only y changes at a constant rate
						currentYPosition <= currentYPosition + pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientDownDownLeft * 1024;
						// orientation is 247.5 degrees
						currentOrientation <= orientDownDownLeft;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientDownDownRight * 1024;
						// orientation is 292.5 degrees
						currentOrientation <= orientDownDownRight;
					end
				end
				// orientation is 292.5 degrees
				orientDownDownRight: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientDownDownRight * 1024;
						// orientation stays the same
						currentOrientation <= orientDownDownRight;
						backgroundAddress <= backgroundAddress + (320 * pixelsToMove + (pixelsToMove - 1));
						// x changes at a slower rate but y changes at the constant rate
						currentXPosition <= currentXPosition + (pixelsToMove - 1);
						currentYPosition <= currentYPosition + pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientDown * 1024;
						// orientation is 270 degrees
						currentOrientation <= orientDown;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientDownRight * 1024;
						// orientation is 315 degrees
						currentOrientation <= orientDownRight;
					end
				end
				// orientation is 315 degrees
				orientDownRight: begin
					// if user presses forward
					if(moveForward) begin
						carAddress <= orientDownRight * 1024;
						// orientation stays the same
						currentOrientation <= orientDownRight;
						backgroundAddress <= backgroundAddress + ((320 * pixelsToMove) + pixelsToMove);
						// x and y move at constant rate
						currentXPosition <= currentXPosition + pixelsToMove;
						currentYPosition <= currentYPosition + pixelsToMove;
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientDownDownRight * 1024;
						// orientation is 292.5 degrees
						currentOrientation <= orientDownDownRight;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientDownRightRight * 1024;
						// orientation is 337.5 degrees
						currentOrientation <= orientDownRightRight;
					end
				end
				// orientation is 337.5 degrees
				orientDownRightRight: begin
				// if user presses forward
					if(moveForward) begin
						carAddress <= orientDownRightRight * 1024;
						// orientation stays the same
						currentOrientation <= orientDownRightRight;
						backgroundAddress <= backgroundAddress + (320 * (pixelsToMove - 1) + pixelsToMove);
						// x changes at a constant rate, but y moves at a slower rate
						currentXPosition <= currentXPosition + pixelsToMove;
						currentYPosition <= currentYPosition + (pixelsToMove - 1);
					end
					// if user presses right
					else if(moveRight) begin
						carAddress <= orientDownRight * 1024;
						// orientation is 315 degrees
						currentOrientation <= orientDownRight;
					end
					// if user presses left
					else if(moveLeft) begin
						carAddress <= orientRight * 1024;
						// orientation is 0 degrees
						currentOrientation <= orientRight;
					end
				end
				
			endcase
		end
		
		// the finish line conditions, the y goes from 183 to 206 
		if(currentXPosition == 9'd150 && currentYPosition > 8'd100 &&
		   currentYPosition < 8'd240)
			pastStartLine <= 1'b1;
		
		//DRAWING WIN SCREEN
		if(!FinishedRace && pastStartLine && (currentXPosition == 9'd124 || currentXPosition == 9'd125) &&
		    currentYPosition > 8'd187 && currentYPosition < 8'd199) begin// numbers for y may change after testing on board
				FinishedRace <= 1'b1;
				currentXPosition <= 9'd0;
				currentYPosition <= 8'd0;
				xCount <= 9'd0;
				yCount <= 8'd0;
		end
	end
			
endmodule	
