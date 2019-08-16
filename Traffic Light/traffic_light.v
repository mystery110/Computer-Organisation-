module traffic_light (clk,rst,pass,R,G,Y);
    input  clk,rst,pass;
    output R,G,Y;
    reg R,G,Y;
    reg[2:0] currentState,nextState;
    reg[10:0] tick;
    parameter [2:0]ST0=3'b000,
		   ST1=3'b001,
		   ST2=3'b010,
		   ST3=3'b011,
		   ST4=3'b100,
		   ST5=3'b101,
		   ST6=3'b110;
//write your code here
always @(posedge clk or rst or posedge pass)
begin 
	if(rst==1)
	begin
          tick<=0;
	  currentState<=ST0;
	end
	else if(clk)
	begin
	  tick<=tick+1'd1;
	  if(currentState<ST2)
	  begin
		if(tick==1023)
		begin
			tick<=0;
			currentState<=nextState;
		end
	  end
	  else if(currentState<ST6 & currentState>ST1)
	  begin
		if(tick==127)
		begin
			tick<=0;
			currentState<=nextState;
		end
	  end
	  else
	  begin
		if(tick==511)
		begin
			tick<=0;
			currentState<=nextState;
		end
	  end
	end
	if(pass==1)
	begin
		if(currentState!=ST0)
		begin
			currentState<=ST0;
			tick<=0;
		end
		else if(rst==0 & clk==0)
		begin 
			tick<=tick-1;
		end
	end
end

always @(currentState)
begin
	case(currentState)
		ST0:begin
			nextState<=ST2;
			R<=0;
			G<=1;
			Y<=0;
		    end
		ST1:begin
			nextState<=ST0;
			R<=1;
			G<=0;
			Y<=0;
		    end
		ST2:begin
			nextState<=ST3;
			R<=0;
			G<=0;
			Y<=0;
		    end
		ST3:begin
			nextState<=ST4;
			R<=0;
			G<=1;
			Y<=0;
		    end
		ST4:begin
			nextState<=ST5;
			R<=0;
			G<=0;
			Y<=0;
		    end
		ST5:begin
			nextState<=ST6;
			R<=0;
			G<=1;
			Y<=0;
		    end
		ST6:begin
			nextState<=ST1;
			R<=0;
			G<=0;
			Y<=1;
		    end
	endcase
end

endmodule
