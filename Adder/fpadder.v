module fpadder (src1,src2, out);
	input  [31:0] src2;
	input  [31:0] src1;
	output reg [31:0] out;
	reg[7:0]expo_diff;
	reg smaller_element;
	reg [27:0]Final_ans;
	reg [27:0]Final_op1,Final_op2;
	reg [5:0]index;
function [7:0]diff;
	input[7:0]exponent1,exponent2;
	begin
		assign diff=exponent1-exponent2;
	end
endfunction

function [25:0]shifted_fraction;
	input smaller_element;
	input[22:0]fraction1,fraction2;
	input [7:0]expo_diff,exponent1,exponent2;
	reg implicit_one;
	reg[7:0]exponent;
	begin
		shifted_fraction[2:0]=3'd0;

		if(smaller_element)
		begin
			shifted_fraction[25:3]=fraction2;
			exponent=exponent2;
		end

		else
		begin
			shifted_fraction[25:3]=fraction1;
			exponent=exponent1;
		end

		if(exponent==0)
		begin
			implicit_one=1'd0;
			expo_diff=expo_diff-1;
		end
		else
		begin

			implicit_one=1'd1;
		end
		repeat (expo_diff)
		begin
			if(!shifted_fraction[0])
			begin
				if(shifted_fraction[1])
				begin
					shifted_fraction[0]=1'd1;
				end
			end
			else 
			begin
			end
			
			shifted_fraction[1]=shifted_fraction[2];
			shifted_fraction[2]=shifted_fraction[3];
			if(implicit_one==1)
			begin	
				shifted_fraction[25:3]={1'd1,shifted_fraction[25:4]};	
				implicit_one=1'd0;	
			end
			else 
			begin
				shifted_fraction[25:3]={1'd0,shifted_fraction[25:4]};
			end
		end
	end

endfunction

function set_smaller_element;
	input[7:0]exponent1,exponent2;
	input[22:0]fraction1,fraction2;
	begin
		if(exponent1>exponent2)
		begin
			set_smaller_element=1'd1;
		end
		else if(exponent1==exponent2)
		begin
			if(fraction1>fraction2)
			begin
				set_smaller_element=1'd1;
			end
			else
			begin
				set_smaller_element=1'd0;
			end
		end
		else
		begin
			set_smaller_element=1'd0;
		end
	end
endfunction

function [5:0]set_index_bit;
	input[4:0]fraction;
	input[5:0]index;
	begin
		if(fraction[4]==1)
		begin
			set_index_bit=index+1;
		end
		else if(fraction[3]==1)
		begin
			set_index_bit=index+2;
		end
		else if(fraction[2]==1)
		begin
			set_index_bit=index+3;
		end
		else if(fraction[1]==1)
		begin
			set_index_bit=index+4;
		end
		else if(fraction[0]==1)
		begin
			set_index_bit=index+5;
		end
	end
endfunction

function [33:0]Normalise;
	input[1:0]Decimal;
	input[22:0]fraction;
	input[7:0]exponent;
	input [2:0]GRS;
	reg [5:0]index;
begin
	if (Decimal[1]==1)
	begin

		if(exponent!=254)
		begin
			exponent=exponent+1;
			GRS[1]=GRS[2];
			GRS[2]=fraction[0];
			fraction={Decimal[0],fraction[22:1]};

			Normalise={exponent,fraction,GRS};	

		end
		else
		begin
			exponent=exponent+1;
			Normalise={exponent,23'd0,3'd0};
		end
	end
	
	else if(Decimal!=1)
	begin
		if(fraction[22:18]>0)
		begin
			index=6'd0;
			index=set_index_bit(fraction[22:18],index);
		end
		else if(fraction[17:13]>0)
		begin
			index=6'd5;
			index=set_index_bit(fraction[17:13],index);
		end
		else if(fraction[12:8]>0)
		begin
			index=6'd10;
			index=set_index_bit(fraction[12:8],index);
		end
		else if (fraction[7:3]>0)
		begin
			index=6'd15;
			index=set_index_bit(fraction[7:3],index);
		end
		else
		begin
			index=6'd20;
			index=set_index_bit({fraction[2:0],2'd0},index);
		end
		
		if(exponent>index)
		begin
			repeat(index)
			begin
				exponent=exponent-1'd1;
				fraction={fraction[21:0],GRS[2]};
				GRS[2]=GRS[1];
				GRS[1]=0;
			end
		end
		else 
		begin
			exponent=0;
			repeat(exponent)
			begin
				fraction={fraction[21:0],GRS[2]};
				GRS[2]=GRS[1];
				GRS[1]=0;
			end
		end
		Normalise={exponent,fraction,GRS};
	end
end
endfunction

always@(src1 or src2)
begin
	index=0;
	smaller_element=set_smaller_element(src1[30:23],src2[30:23],src1[22:0],src2[22:0]);//Find which element is smaller
	//Find the exponent different between two element
	
	if(smaller_element)
	//src1 is larger
	begin
		expo_diff=diff(src1[30:23],src2[30:23]);
		out[30:23]=src1[30:23];
		out[31]=src1[31];
		if(src1[30:23]>0)
		begin
			Final_op1={2'd1,src1[22:0],3'd0};
			if(expo_diff==0)
			begin
				Final_op2={2'd1,src2[22:0],3'd0};
			end
			else 
			begin
			end
		end
		else 
		begin
			Final_op1={2'd0,src1[22:0],3'd0};
			if(expo_diff==0)
			begin
				Final_op2={2'd0,src2[22:0],3'd0};
			end
			else 
			begin
			end
		end
	end

	else
	begin
	//src2 is larger
		expo_diff=diff(src2[30:23],src1[30:23]);
		out[30:23]=src2[30:23];
		out[31]=src2[31];
		if(src2[30:23]>0)
		begin
			Final_op1={2'd1,src2[22:0],3'd0};
			if(expo_diff==0)
			begin
				Final_op2={2'd1,src1[22:0],3'd0};
			end
			else
			begin
			end
		end

		else
		begin
			Final_op1={2'd0,src2[22:0],3'd0};
			if(expo_diff==0)
			begin
				Final_op2={2'd0,src1[22:0],3'd0};
			end
			else
 			begin
			end
		end

	end
	
	//If both exponent different >0,shift the fraction part of the smaller element to the right

	if(expo_diff>0)
	begin
		Final_op2={2'd0,shifted_fraction(smaller_element,src1[22:0],src2[22:0],expo_diff,src1[30:23],src2[30:23])};
		
	end
	else 
	begin
	end


	if(src1[31]==src2[31])
	begin
		Final_ans[27:0]=Final_op1[27:0]+Final_op2[27:0];
	end
	else
	begin
		Final_ans[27:0]=Final_op1[27:0]-Final_op2[27:0];
	end


	if(!(Final_ans[27]==0 && Final_ans[26]==1))
	begin
		{out[30:0],Final_ans[2:0]}=Normalise(Final_ans[27:26],Final_ans[25:3],out[30:23],Final_ans[2:0]);

	end
	else if(Final_ans[27]==0 && Final_ans[26]==1)
	begin
		if(out[30:23]==0)
		begin
			out[30:23]=out[30:23]+1;
		end
	out[22:0]=Final_ans[25:3];
	end	


	
	if(out[30:23]!=255)
	begin
	if(Final_ans[2:0]>4)
	begin
		Final_ans[27:3]=out[22:0]+1'd1;
	
		if(Final_ans[26])
		begin
			{out[30:0],Final_ans[2:0]}=Normalise(2'b10,Final_ans[25:3],out[30:23],Final_ans[2:0]);
		end
		else
		begin
			out[22:0]=Final_ans[25:3];
		end
	end
	else if(Final_ans[2:0]==4)
	begin
		if(out[0]==1)
		begin
			Final_ans[27:3]=out[22:0]+1'd1;
			if(Final_ans[26])
			begin
				{out[30:0],Final_ans[2:0]}=Normalise(2'b10,Final_ans[25:3],out[30:23],Final_ans[2:0]);
			end
			else
			begin
				out[22:0]=Final_ans[25:3];
			end
		end
	end
	else
	begin
	end
end

	if(out[30:0]==0)
	begin
		out[31]=0;
	end


end

endmodule
