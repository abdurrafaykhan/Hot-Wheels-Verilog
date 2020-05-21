module projectTop(

	//initalizes input for clock, resetn, SIMRESET----------------, start, three direction turns
	input Clock, Resetn, simReset, Start, moveForward, moveRight, moveLeft,
	
	//initalizes output for the x position, y position, timer for the score, colour display and plot
	output reg[8:0] xDisplay,
	output reg[7:0] yDisplay,
	output reg[7:0] secondsPassed,
	output[5:0] colourDisplay,
	output reg plotDisplay);
	
	//initialization of variables:
	
	//checking for reset,start of the race, drawing the background, car and background with moving car
	wire setResetSignals, startRace, drawBG, drawCar, drawErase;
	
	//checking for whether car is moving, explosion needs to be drawn, win screen and start screen display
	wire move, drawBoom, drawWinScreen, drawStartScreen;
	
	//checking for whether car, background, background with moving car is done being drawn
	//checking if race is finished or if collision occured
	wire DoneDrawCar, DoneDrawBG, DoneDrawErase, FinishedRace, Collision;
	
	//checking if explosion, win screen, start screen has been drawn
	wire DoneDrawBoom, DoneDrawWinScreen, DoneDrawStartScreen;
	
	
	//--------------------------------------------------------------------------------------------------------
	wire[19:0] OneFrameCounter;
	
	//--------------------------------------------------------------------------------------------------------
	wire Enable1Frame;
	
	//Calls DelayCounter and feeds in a large count down number, clock, simreset-----------------, and OneFrameCounter---------------------
	//Delay Counter module gives enough time for the user to see the changes of the cars movement on the screen
	DelayCounter DC0(
		.countDownNum(20'd999_999), // SET TO 1 FOR SIMULATION PURPOSES
		.Clock(Clock),
		.simReset(simReset),
		.RDOut(OneFrameCounter));
	
	//Assigns EnableOneFrame to be true when OneFrameCounter is 0, otherwise False
	//When true, it allows for the car to move foward and background to be replaced
	assign EnableOneFrame = (OneFrameCounter == 20'd0) ? 1'b1 : 1'b0;
	
	//creates storage value for plotting the display
	wire plotWire;
	
	
	//calls the control function feeding it input for cock, reset, EnableOneFrame and the states for all game situations
	control C0(
		.Clock(Clock),
		.Resetn(Resetn),
		.EnableOneFrame(EnableOneFrame),
		.start(Start),
		.forward(moveForward),
		.right(moveRight),
		.left(moveLeft),
		.DoneDrawBG(DoneDrawBG),
		.DoneDrawCar(DoneDrawCar),
		.DoneDrawErase(DoneDrawErase),
		.FinishedRace(FinishedRace),
		.Collision(Collision),
		.DoneDrawBoom(DoneDrawBoom),
		.setResetSignals(setResetSignals),
		.startRace(startRace),
		.drawBG(drawBG),
		.drawCar(drawCar),
		.drawErase(drawErase),
		.move(move),
		.drawBoom(drawBoom),
		.plot(plotWire),
		.DoneDrawStartScreen(DoneDrawStartScreen), 
		.DoneDrawWinScreen(DoneDrawWinScreen),
		.drawStartScreen(drawStartScreen),
		.drawWinScreen(drawWinScreen));
		
	wire[8:0] xWire;
	wire[7:0] yWire;
		
	datapath D0(
		.Clock(Clock),
		.Resetn(Resetn),
		.moveForward(moveForward),
		.moveRight(moveRight),
		.moveLeft(moveLeft),
		.setResetSignals(setResetSignals),
		.startRace(startRace),
		.drawBG(drawBG),
		.drawCar(drawCar),
		.drawErase(drawErase),
		.move(move),
		.drawBoom(drawBoom),
		.DoneDrawBG(DoneDrawBG),
		.DoneDrawCar(DoneDrawCar),
		.DoneDrawErase(DoneDrawErase),
		.FinishedRace(FinishedRace),
		.Collision(Collision),
		.DoneDrawBoom(DoneDrawBoom),
		.colourDisplay(colourDisplay),
		.xDisplay(xWire),
		.yDisplay(yWire),
		.DoneDrawStartScreen(DoneDrawStartScreen), 
		.DoneDrawWinScreen(DoneDrawWinScreen),
		.drawStartScreen(drawStartScreen),
		.drawWinScreen(drawWinScreen));
	
	always@(posedge Clock) begin
		xDisplay <= xWire;
		yDisplay <= yWire;
		plotDisplay <= plotWire;
	end
	
	wire[27:0] timer;
	wire EnableOneSecond;
	
	SecondsCounter S0(
		.Clock(Clock),
		.simReset(simReset),
		.countDownNum(28'd49_999_999),
		.RDOut(timer));
		
	assign EnableOneSecond = (timer == 28'd0) ? 1'b1 : 1'b0;
	
	always@(posedge Clock) begin
		if(EnableOneSecond) begin
			if(!FinishedRace) secondsPassed <= secondsPassed + 8'd1;
			else secondsPassed <= secondsPassed;
		end
		else begin
			if(!Resetn || !Start) secondsPassed <= 8'd0;
			else secondsPassed <= secondsPassed;
		end
	end

endmodule
