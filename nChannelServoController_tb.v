`timescale 1 ns/100 ps
module nChannelServoController_tb;			//testbench module

reg clock;
reg [7:0]control;
reg [1:0]address;
reg load;
wire [3:0] pwm;

nChannelServoController nChannelServoController_dut(
	.clock(clock),
	.control(control),
	.address(address),
	.load(load),
	.pwm(pwm)
);
localparam CLOCK_FREQ=50000000;
real HALF_CLOCK_PERIOD = 1000000000.0 / ($itor(CLOCK_FREQ) *2.0); //HALF_CLOCK_PERIOD in nanoseconds
integer i;						//integers i,j are used for looping
integer j;
integer previous_pwm=0;
real duty_cycle;					//stores duty cycle width
initial begin
	$display("Simulation Started\t %d ns",$time); 
	load=1'b0;
	clock=1'b0;
	control=8'b11111111;	
	#HALF_CLOCK_PERIOD;
	clock=~clock;
	#HALF_CLOCK_PERIOD;
	for(j=0;j<4;j=j+1) begin			//loop to verify for all values of address
		address=j;
		load=1'b0;
		for(i=0;i<=2*(CLOCK_FREQ/50);i=i+1)begin 
			load=1'b1;
			clock=~clock;
			#HALF_CLOCK_PERIOD;
			if(pwm==(1+(2*j)) && previous_pwm==0) begin  //pwm transition from 0 to 1 
				$display("Time at the beginning of new pwm cycle: %d ns",$time);
				duty_cycle=$time;
				previous_pwm=1;
			end
			if(pwm==0 && previous_pwm==1) begin //pwm transition from 1 to 0
				$display("Time at the end of duty cycle: %d ns",$time);
				previous_pwm=0;
				duty_cycle=$time - duty_cycle;
				if(duty_cycle >= 500000 && duty_cycle <= 2500000) begin	//output duty cycle verification
					$display("SUCCESS!");
				end
				else begin
					$display("FAIL!");
				end
				load=1'b0;
			end
		end
	end
end
endmodule
