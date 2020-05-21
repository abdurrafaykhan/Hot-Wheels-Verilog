module DelayCounter(

	//Calls DelayCounter and feeds in a large count down number, clock, simreset-----------------, and OneFrameCounter---------------------
	input Clock, simReset,
	input[19:0] countDownNum,
	output reg[19:0] RDOut);
	
	//with every iteration of posedge clock
	always @ (posedge Clock)
		begin
		
			//if simReset is true, then set RDOut to 0
			if (simReset)
				RDOut <= 20'd0;
				
			//if RDOut is 0, set RDOut to the countdown number
			else if (RDOut == 20'd0)
				RDOut <= countDownNum;
			//if simreset is false, and RDOut is not 0, then decrease RDOut by 1
			else
				RDOut <= RDOut - 20'd1;
		end

endmodule