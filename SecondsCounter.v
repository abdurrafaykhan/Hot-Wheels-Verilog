module SecondsCounter(
	input Clock, simReset,
	input[27:0] countDownNum,
	output reg[27:0] RDOut);
	
	always @ (posedge Clock)
		begin
			if (simReset)
				RDOut <= 28'd0;
			else if (RDOut == 28'd0)
				RDOut <= countDownNum;
			else
				RDOut <= RDOut - 28'd1;
		end

endmodule
