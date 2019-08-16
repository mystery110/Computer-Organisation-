

module CPU(clk,rst, instr_read,instr_addr, instr_out,data_read, data_write,data_addr,data_in,data_out);
input 		clk,rst;

output	reg	instr_read;
output reg [31:0]   instr_addr;
input   [31:0]    instr_out;

output  reg   data_read,data_write;
output reg[31:0] data_addr;
output reg[31:0] data_in;
input  [31:0] data_out;

reg [31:0]   PC_add4;
reg [31:0] PC_addImm;
reg [31:0]	immediate;
reg [31:0] registerFile[31:0];
reg [6:0]  opcode;
reg [2:0]  func3;
reg [6:0]  func7;
reg [4:0]  rd,rs1,rs2;
reg [31:0] ALUOperand[1:0];

reg [2:0] ImmType;
reg [6:0]ALUControl;
reg RegWrite,Branch,PctoRegSrc,RDSrc,ALUSrc,MemRead,MemWrite,MemtoReg;
reg[2:0]ALUOP;

reg [1:0]branchCon;
reg [31:0]PctoRegWire;
reg [31:0]PcorALUOutWire;
reg [32:0]ALUOutput;
reg [31:0]rdData;
reg notFinish_cycle;

reg change;
reg [100:0]froze;

function [13:0]Control;
/*
	0,1,2)ImmType
		000:No Immediate
		001:I_Type
		010:S-Type
		011:B-Type
		100:U-Type
		101:J-Type
	3)RegWrite
	4)Branch
	5)PctoRegSrc (Whether PC+4(0) or PC+immediate(1) is passed) 
	6)RDSrc (Whether PC(0) or ALU output (1) is passed)
	7)ALUSrc (0 for rs2,1 for immediate field)
	8)MemRead
	9)MemWrite
	10)MemtoReg(1 for memory)
	11,12,13)ALUOP
		000:R_type
		010:I_Type
		011:I-type(lw)
		100:S_Type(Addition)
		110:B_type(Subtraction)

	ALUCon
		0000:NO_Op
		0001)Addition
		0010)subtraction
		0011)shift left
		0100)shift right(unsigned)
		0101)shift right(signed)
		0110)AND
		0111)OR
		1000)XOR
		1001)Addition with register zero
		1010)Compare
		1111)Error

	Compare function table
		000)set less than(signed)
		001)set less than (unsigned)
		010)Equal
		011)Not equal
		100)set larger than (signed)
		101)set larger than(unsigned)
*/
	input [6:0]opcode;
	reg [12:0]temp;
	begin
		case(opcode)
			7'b0110011://R-type
			begin
				Control[2:0]=3'b000;
				Control[3]=1'b1;
				Control[4]=1'b0;
				Control[5]=1'bx;
				Control[6]=1'b1;
				Control[7]=1'b0;
				Control[8]=1'b0;
				Control[9]=1'b0;
				Control[10]=1'b0;
				Control[13:11]=3'b000;
			end

			7'b0010011://I-type
			begin
				Control[2:0]=3'b001;
				Control[3]=1'b1;
				Control[4]=1'b0;
				Control[5]=1'bx;
				Control[6]=1'b1;
				Control[7]=1'b1;
				Control[8]=1'b0;
				Control[9]=1'b0;
				Control[10]=1'b0;
				Control[13:11]=3'b010;
			end

			7'b0000011://lw
			begin
				Control[2:0]=3'b001;
				Control[3]=1'b1;
				Control[4]=1'b0;
				Control[5]=1'bx;
				Control[6]=1'b1;
				Control[7]=1'b1;
				Control[8]=1'b1;
				Control[9]=1'b0;
				Control[10]=1'b1;
				Control[13:11]=3'b011;
			end

			7'b1100111://JALR
			begin
				Control[2:0]=3'b001;
				Control[3]=1'b1;
				Control[4]=1'b1;
				Control[5]=1'b0;
				Control[6]=1'b0;
				Control[7]=1'b1;
				Control[8]=1'b0;
				Control[9]=1'b0;
				Control[10]=1'b0;
				Control[13:11]=3'b010;
			end

			7'b0100011://S-type sw
			begin
				Control[2:0]=3'b010;
				Control[3]=1'b0;
				Control[4]=1'b0;
				Control[5]=1'bx;
				Control[6]=1'bx;
				Control[7]=1'b1;
				Control[8]=1'b0;
				Control[9]=1'b1;
				Control[10]=1'b0;
				Control[13:11]=3'b100;
			end

			7'b1100011://B_type
			begin
				Control[2:0]=3'b011;
				Control[3]=1'b0;
				Control[4]=1'b1;
				Control[5]=1'bx;
				Control[6]=1'bx;
				Control[7]=1'b0;
				Control[8]=1'b0;
				Control[9]=1'b0;
				Control[10]=1'b0;
				Control[13:11]=3'b110;
			end

			7'b0010111://U-type rd=PC+imm
			begin
				Control[2:0]=3'b100;
				Control[3]=1'b1;
				Control[4]=1'b0;
				Control[5]=1'bx;
				Control[6]=1'b1;
				Control[7]=1'b1;
				Control[8]=1'b0;
				Control[9]=1'b0;
				Control[10]=1'b0;
				Control[13:11]=3'b101;
			end

			7'b0110111://LUI:rd=imm
			begin
				Control[2:0]=3'b100;
				Control[3]=1'b1;
				Control[4]=1'b0;
				Control[5]=1'bx;
				Control[6]=1'b1;
				Control[7]=1'b1;
				Control[8]=1'b0;
				Control[9]=1'b0;
				Control[10]=1'b0;
				Control[13:11]=3'b001;
			end

			7'b1101111://J-type
			begin
				Control[2:0]=3'b101;
				Control[3]=1'b1;
				Control[4]=1'b1;
				Control[5]=1'b0;
				Control[6]=1'b0;
				Control[7]=1'bx;
				Control[8]=1'b0;
				Control[9]=1'b0;
				Control[10]=1'b0;
				Control[13:11]=3'bxxx;
			end

			default
			begin
				Control=14'b0;
			end
		endcase
	end
endfunction

function[31:0]Immediate;
	input[3:0]ImmType;
	input[31:0]ImmField;
	input [2:0]func3;
	begin
		case(ImmType)
		3'b001://I-Type
		begin
			if(func3==3'b011)
			begin
				Immediate[31:11]={21{ImmField[31]}}	;	
				Immediate[10:0]=ImmField[30:20];

			end
			else if(func3!=3'b001 && func3!=3'b101) 
			begin
				Immediate[31:11]={21{ImmField[31]}}	;	
				Immediate[10:0]=ImmField[30:20];
			end
			else
			begin
				Immediate[31:4]={28{ImmField[24]}};
				Immediate[3:0]=ImmField[23:20];
			end
		end

		3'b010://S-Type
		begin
			Immediate[31:11]={21{ImmField[31]}};
			Immediate[10:5]=ImmField[30:25];
			Immediate[4:0]=ImmField[11:7];
		end

		3'b011://B-Type
		begin
			Immediate[31:12]={20{ImmField[31]}};
			Immediate[11]=ImmField[7];
			Immediate[10:5]=ImmField[30:25];
			Immediate[4:1]=ImmField[11:8];
			Immediate[0]=0;
		end

		3'b100://U-Type
		begin
			Immediate[31:19]={13{ImmField[31]}};
			Immediate[18:0]=ImmField[30:12];
		end

		3'b101://J-Type
		begin
			Immediate[31:20]={13{ImmField[31]}};
			Immediate[19:12]=ImmField[19:12];
			Immediate[11]=ImmField[20];
			Immediate[10:1]=ImmField[30:21];
			Immediate[0]=0;
		end

		default:
		begin
			ImmField=32'd1;
		end
		endcase
	end
endfunction

function[6:0]ALUCon;
	input [2:0]ALUOPFunc;//Seperate to variable juz in case
	input [2:0]func3Func;
	input [6:0]func7Func;

	reg [2:0]compareFunc;
	begin
		case(ALUOPFunc)
		
		3'b000://R-Type
		begin
			case(func3Func)
			
			3'b000:
			begin
				compareFunc=3'bxxx;
				if(func7Func==0)
				begin
					ALUCon[3:0]=4'b0001;
				end

				else if(func7Func==7'b0100000)
				begin
					ALUCon[3:0]=4'b0010;
				end

				else 
				begin
					ALUCon[3:0]=4'b1111;
				end	
			end

			3'b001:
			begin
				compareFunc=3'bxxx;
				ALUCon[3:0]=4'b0011;
			end

			3'b010:
			begin
				ALUCon[3:0]=4'b1010;
				compareFunc=3'b000;
			end

			3'b011:
			begin
				ALUCon[3:0]=4'b1010;
				compareFunc=3'b001;
			end

			3'b100:
			begin
				ALUCon[3:0]=4'b1000;
				compareFunc=3'bxxx;
			end

			3'b101:
			begin
				compareFunc=3'bxxx;
				if(func7Func==0)
				begin
					ALUCon[3:0]=4'b0100;
				end

				else if(func7Func==7'b0100000)
				begin
					ALUCon[3:0]=4'b0101;
				end

				else begin
					ALUCon[3:0]=4'b1111;
				end
			end

			3'b110:
			begin
				ALUCon[3:0]=4'b0111;
				compareFunc=3'bxxx;
			end

			3'b111:
			begin
				ALUCon[3:0]=4'b0110;
				compareFunc=3'bxxx;
			end

			default:
			begin
				ALUCon[3:0]=4'b1111;
				compareFunc=3'bxxx;
			end
			endcase
		end

		3'b001://U_type load upper immediate
		begin
			compareFunc=3'bxxx;
			ALUCon[3:0]=4'b1001;
		end
		3'b010://I-Type
		begin
			case(func3Func)

			3'b000:
			begin
				compareFunc=3'bxxx;
				ALUCon[3:0]=4'b0001;
			end

			3'b001:
			begin
				compareFunc=3'bxxx;
				ALUCon[3:0]=4'b0011;
			end

			3'b010:
			begin
				compareFunc=3'b000;
				ALUCon[3:0]=4'b1010;
			end

			3'b011:
			begin
				compareFunc=3'b001;
				ALUCon[3:0]=4'b1010;
			end

			3'b100:
			begin
				compareFunc=3'bxxx;
				ALUCon[3:0]=4'b1000;
			end

			3'b101:
			begin
				if(func7Func==0)
				begin
					compareFunc=3'bxxx;
					ALUCon[3:0]=4'b0100;
				end

				else if(func7Func==7'b0100000)
				begin
					compareFunc=3'bxxx;
					ALUCon[3:0]=4'b0101;
				end

				else begin
					compareFunc=3'bxxx;
					ALUCon[3:0]=4'b1111;
				end
			end

			3'b110:
			begin
				compareFunc=3'bxxx;
				ALUCon[3:0]=4'b0111;
			end

			3'b111:
			begin
				compareFunc=3'bxxx;
				ALUCon[3:0]=4'b0110;
			end

			default
			begin
					compareFunc=3'bxxx;
					ALUCon[3:0]=4'b1111;
			end
			endcase
		end

		3'b011://I-Type(Lw)
		begin
			compareFunc=3'bxxx;
			ALUCon[3:0]=4'b0001;
		end

		3'b100://S-Type
		begin
			compareFunc=3'bxxx;
			ALUCon[3:0]=4'b0001;
		end

		3'b101:
		begin
			compareFunc=3'bxxx;
			ALUCon[3:0]=4'b1011;
		end
		3'b110://B-Type
		begin
			ALUCon[3:0]=4'b1010;	

			case(func3Func)
			3'b000:
			begin
				compareFunc=3'b010;
			end

			3'b001:
			begin
				compareFunc=3'b011;
			end

			3'b100:
			begin
				compareFunc=3'b000;
			end

			3'b101:
			begin
				compareFunc=3'b100;
			end

			3'b110:
			begin
				compareFunc=3'b001;
			end

			3'b111:
			begin
				compareFunc=3'b101;	
			end

			default
			begin
				ALUCon[3:0]=4'b1111;
			end
			endcase
		end

		default:
		begin
				ALUCon[3:0]=4'b1111;
		end
		endcase

		ALUCon[6:4]=compareFunc;
	end
endfunction

function[32:0]ALU;
	input[6:0]ALUControlFunc;
	input[31:0]Operand1;
	input[31:0]Operand2;

	reg ZeroSignal;
	reg signed [31:0]signed_operand;
	begin
		case(ALUControlFunc[3:0])

		4'b0001://Addition
		begin
			ZeroSignal=0;
			ALU[31:0]=$signed(Operand1)+$signed(Operand2);
		end

		4'b0010://Subtraction
		begin
			ZeroSignal=0;
			ALU[31:0]=$signed(Operand1)-$signed(Operand2);
		end

		4'b0011://Shift left
		begin
			ZeroSignal=0;
			ALU[31:0]=Operand1;
			repeat(Operand2[4:0])
			begin
				ALU[31:0]=ALU[31:0]<<1;
			end
		end

		4'b0100://Shift Right(unsigned)
		begin
			ZeroSignal=0;
			ALU[31:0]=Operand1;
			repeat(Operand2[4:0])
			begin
				ALU[31:0]=$unsigned(ALU[31:0])>>1;
			end
		end

		4'b0101://Shifted Right(signed)
		begin
			ZeroSignal=0;
			signed_operand=Operand1;
			repeat(Operand2[4:0])
			begin
				signed_operand=signed_operand>>>1;
			end
			if(signed_operand==32'hffffffff)
			begin
				ALU[31:0]=0;
			end
			else begin
				ALU[31:0]=signed_operand;
			end
		end

		4'b0110://AND
		begin
			ZeroSignal=0;
			ALU[31:0]=Operand1&Operand2;
		end

		4'b0111://OR
		begin
			ZeroSignal=0;
			ALU[31:0]=Operand1|Operand2;
		end

		4'b1000://XOR
		begin
			ZeroSignal=0;
			ALU[31:0]=Operand1^Operand2;
		end

		4'b1001://Addition with register zero
		begin
			ZeroSignal=0;
			ALU[31:12]=Operand2;
			ALU[11:0]=0;
		end

		4'b1010://Compare
		begin
			ALU[31:0]=0;
			case(ALUControlFunc[6:4])

			3'b000://set less than (signed)
			begin
				if(Operand1==Operand2)
				begin
					ZeroSignal=0;
				end
				else if($signed(Operand1)<$signed(Operand2))
				begin
					ZeroSignal=1;
				end
				else begin
					ZeroSignal=0;
				end
			end

			3'b001://set less than(unsigned)
			begin
				if(Operand1==Operand2)
				begin
					ZeroSignal=0;
				end
				
				else if(Operand1>Operand2)
				begin
					ZeroSignal=0;
				end

				else begin
					ZeroSignal=1;
				end
			end

			3'b010://Equal
			begin
				if(Operand1==Operand2)
				begin
					ZeroSignal=1;
				end

				else begin
					ZeroSignal=0;
				end
			end

			3'b011://not euqal
			begin
				if(Operand1!=Operand2)
				begin
					ZeroSignal=1;
				end

				else begin
					ZeroSignal=0;
				end
			end

			3'b100://set larger than (signed )
			begin

				if(Operand1==Operand2)
				begin
					ZeroSignal=1;
				end
				else if($signed(Operand1)>$signed(Operand2))
				begin
					ZeroSignal=1;
				end
				else begin
					ZeroSignal=0;
				end
			end

			3'b101://set larger than (unsigned)
			begin
				if(Operand2==Operand1)
				begin
					ZeroSignal=1;
				end
				else if(Operand1[31]!=Operand2[31])
				begin
					Operand1=~Operand1;
					Operand1=Operand1+1;
				end

				if(Operand1>=Operand2)
				begin
					ZeroSignal=1;
				end

				else begin
					ZeroSignal=0;
				end
			end

			default:
			begin
				ZeroSignal=0;
			end
			endcase
			ALU[31:0]=ZeroSignal;
		end

		4'b1011:
		begin
			ALU[31:12]=Operand2[19:0];
			ALU[11:0]=12'd0;
			signed_operand[31:0]={31{ALU[31]}};
			{signed_operand,ALU}=Operand1+{signed_operand,ALU};
		end

		default:
		begin
			ZeroSignal=0;
			ALU[31:0]=0;
		end
		endcase
	ALU={ZeroSignal,ALU[31:0]};
	end
endfunction

function[1:0]BranchCon;
	input branchSignal;	
	input ZeroSignalFunc;
	input [2:0]ImmTypeFunc;
	begin
		case(ImmType)

		3'b001:
		begin
			BranchCon=2'b10;
		end

		3'b011:
		begin
			if(ZeroSignalFunc==1)
			begin
				BranchCon=2'b01;
			end

			else begin
				BranchCon=2'b00;
			end
		end

		3'b101:
		begin
			BranchCon=2'b01;
		end

		default:
		begin
			BranchCon=2'b11;
		end
		endcase
		if(branchSignal==0)
		begin
			BranchCon=2'b00;
		end
	end
endfunction


initial
begin
	registerFile[0]=0;
	instr_read=1;
	instr_addr=32'd0;
	notFinish_cycle=0;
	froze=0;
end

always@(posedge clk or rst)
begin

	
	if(change==0)
	begin
		change=1;
	end
	else 
	begin
		change=0;
	end

end

always@(instr_out  or change)
begin
	if(data_read && RegWrite && rd!=0)
	begin		
		registerFile[rd]=data_out;
	end

	if(notFinish_cycle==0 &&  froze<1)
	begin
		opcode=instr_out[6:0];
		rd=instr_out[11:7];
		func3=instr_out[14:12];
		rs1=instr_out[19:15];
		rs2=instr_out[24:20];
		func7=instr_out[31:25];
		PC_add4=instr_addr+32'd4;
		{ALUOP,MemtoReg,MemWrite,MemRead,ALUSrc,RDSrc,PctoRegSrc,Branch,RegWrite,ImmType}=Control(opcode);
		data_read=MemRead;
		data_write=MemWrite;
		immediate=Immediate(ImmType,{instr_out[31:7],7'd0},func3);

		ALUControl=ALUCon(ALUOP,func3,func7);
		ALUOperand[0]=registerFile[rs1];
		ALUOperand[1]=registerFile[rs2];
		if(opcode==7'b0010111)
		begin
			ALUOperand[0]=instr_addr;
		end

		//ALU Part
		if(ALUSrc==1)
		begin
			ALUOperand[1]=immediate;
		end

		ALUOutput=ALU(ALUControl,ALUOperand[0],ALUOperand[1]);
		PC_addImm=instr_addr+immediate;

		//Setting pc to reg wire 
		if(PctoRegSrc)
		begin
			PctoRegWire=PC_addImm;
		end
		else begin
			PctoRegWire=PC_add4;
		end

		//Setting pc or alu out 
		if(RDSrc)
		begin
			PcorALUOutWire=ALUOutput[31:0];
		end
		else begin
			PcorALUOutWire=PctoRegWire;
		end

		//Determining whether this instruction need to stall until next cycle

		if(data_write||data_read)
		begin
			notFinish_cycle=1;

			data_addr=ALUOutput[31:0];
			data_in=registerFile[rs2];
		end

		if(MemtoReg==0 && rd!=0 && RegWrite==1)
		begin
			registerFile[rd]=PcorALUOutWire;
		end

		else 
		begin
		end

		//Branch 
		if(Branch==1)
		begin
			branchCon=BranchCon(Branch,ALUOutput[32],ImmType);
		end
		else begin
			branchCon=2'b00;
		end

		case(branchCon)
		
		2'b00:
		begin
			instr_addr=PC_add4;

		end

		2'b01:
		begin
			instr_addr=PC_addImm;
		end

		2'b10:
		begin
			instr_addr=ALUOutput[31:0];
		end
		endcase

	end

	else begin
		notFinish_cycle=0;
	end

end
endmodule