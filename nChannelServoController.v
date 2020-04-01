//Pre-processor macro for calculating ADDR_WIDTH
`define clog2(x) (\
   (x <= 2) ? 1 : \
   (x <= 4) ? 2 : \
   (x <= 8) ? 3 : \
   (x <= 16) ? 4 : \
   (x <= 32) ? 5 : \
   (x <= 64) ? 6 : \
   (x <= 128) ? 7 : \
   (x <= 256) ? 8 : \
   (x <= 512) ? 9 : \
   (x <= 1024) ? 10 : \
   (x <= 2048) ? 11 : \
   (x <= 4096) ? 12 : 16 )

//Top-level entity nChannelServoController  
module nChannelServoController #(			
	parameter channels=4,					//Parameters of module are declared
	parameter ADDR_WIDTH=`clog2(channels)
)
(								//Inputs and outputs are defined
	input clock,										
	input [7:0] control,					//8 bit pwm input
	input [ADDR_WIDTH-1:0] address,				//2 bit address input
	input load,						//1 bit load input
	output [channels-1:0] pwm,				//N channel pwm output
	output reg [6:0] decodedValue1,				//hexadecimal value of LSB 4 bits
	output reg [6:0] decodedValue2				//hexadecimal value of MSB 4 bits
);
//wire is used to connect output of frequencyDivider to input of singleChannelServo
wire enable;
//frequencyDivider module is instantiated										
frequencyDivider FrequencyDivider(			
	.clock(clock),
	.dividedClock(enable)
);

genvar i;							//variable to be used in generate block
integer x;							//variable to control for loop 
reg [channels-1:0] load_value;					//gives load to the selected channel
always @ (control) begin
	case(control[3:0])					//converts binary to output hexadecimal  
		4'b0000: decodedValue1=7'b1000000;
		4'b0001: decodedValue1=7'b1111001;
		4'b0010: decodedValue1=7'b0100100;
		4'b0011: decodedValue1=7'b0110000;
		4'b0100: decodedValue1=7'b0011001;
		4'b0101: decodedValue1=7'b0010010;
		4'b0110: decodedValue1=7'b0000010;
		4'b0111: decodedValue1=7'b0111000;
		4'b1000: decodedValue1=7'b0000000;
		4'b1001: decodedValue1=7'b0011000;
		4'b1010: decodedValue1=7'b1001000;
		4'b1011: decodedValue1=7'b0000011;
		4'b1100: decodedValue1=7'b0100111;
		4'b1101: decodedValue1=7'b0100000;
		4'b1110: decodedValue1=7'b0000100;
		4'b1111: decodedValue1=7'b0001110;
	endcase
	case(control[7:4])					//converts binary to output hexadecimal 
		4'b0000: decodedValue2=7'b1000000;
		4'b0001: decodedValue2=7'b1111001;
		4'b0010: decodedValue2=7'b0100100;
		4'b0011: decodedValue2=7'b0110000;
		4'b0100: decodedValue2=7'b0011001;
		4'b0101: decodedValue2=7'b0010010;
		4'b0110: decodedValue2=7'b0000010;
		4'b0111: decodedValue2=7'b0111000;
		4'b1000: decodedValue2=7'b0000000;
		4'b1001: decodedValue2=7'b0011000;
		4'b1010: decodedValue2=7'b1001000;
		4'b1011: decodedValue2=7'b0000011;
		4'b1100: decodedValue2=7'b0100111;
		4'b1101: decodedValue2=7'b0100000;
		4'b1110: decodedValue2=7'b0000100;
		4'b1111: decodedValue2=7'b0001110;
	endcase
end

always @ (load or address) begin				//executed when the input load or address changes
	for(x=0;x<channels;x=x+1) begin					
		if((address==x[ADDR_WIDTH-1:0])&load) begin	//load value is assigned to channel corresponding to input address
			load_value[x]=1'b1;									
		end
		else begin
			load_value[x]=1'b0;			//load for all channels other than selected channel is given 0
		end
	end
end

generate
	for(i=0;i<channels;i=i+1) begin : servo			//singleChannelServo modules are instantiated using generate block
		singleChannelServo servoMotor_loop(
			.enable(enable),
			.load(load_value[i]),
			.control(control),
			.pwm(pwm[i])
		);
	end
endgenerate
endmodule
//frequencyDivider module
module frequencyDivider#(
	parameter frequency=50000000
)
(
	input clock,
	output reg dividedClock
);
integer count=0;
integer countmax=frequency/256000;				//number of cycles of given signal in half time period of 128 kHz signal
integer counttotal=frequency/128000;				//number of cycles of given signal in a 128 kHz signal
always @ (posedge clock) begin
	if(count==(counttotal)) begin
		count=0;
	end
	count=count+1;
	if(count<=(countmax)) begin				//output signal is 1'b1 for half time period of 128 kHz signal
		dividedClock=1'b1;
	end
	else begin						//output signal is 1'b1 for second half time period of 128 kHz signal
		dividedClock=1'b0;
	end
end
endmodule
//singleChannelServo module
module singleChannelServo(
	input enable,						//input is output of frquencyDivider module
	input load,						//input from nChannelServoController module
	input [7:0] control,					//input from nChannelServoController module
	output reg pwm						//1 bit pwm output
);
integer counter=0;						//counts the number of cycles of signal
integer countermax=0;		 				//countermax holds number of cycles for duty cycle
integer countertotal=2560;					//number of cycles for a complete 20 ms signal
always @ (posedge enable) begin
	if(load==1'b1) begin
		countermax=(64+control);			//64+control is the total number of cycles of 128 kHz signal in duty cycle
	end
	else begin
		pwm=1'b0;
	end
	if(counter==(countertotal)) begin
		counter=0;
	end
	counter=counter+1;
	if(counter<=(countermax)) begin
		pwm=1'b1;
	end
	else begin
		pwm=1'b0;
	end
end
endmodule
