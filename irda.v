module IrDA( clk, RXD, TXD, SD, led, ledGreen, rxd_p);
	input  wire clk;
	input  wire RXD;		//RXD IrDA reception pin
	output wire TXD;		//TXD IrDa transmission pin
	output wire SD;			//Send enable pin
	output [3:0] led = 4'b0000;
	output ledGreen;		
	output  wire rxd_p;		//Pin that copy RXD to be able to see the signal in the oscilloscope


	// states of the finite state machine
	parameter AGG          = 3'b000;		// Sending AGG signal. 9 ms transmitting
	parameter PAUSE        = 3'b001;		// 4.5 ms waiting after AGG
	parameter SEND_DATA    = 3'b010;		// Sending data (data and commands)
	parameter SEND_0       = 3'b011;		// Sending bit 0
	parameter SEND_1       = 3'b100;		// Sending bit 1
	parameter IDLE         = 3'b101;		// Idle status

	parameter data         = 32'hFF00FB04;  // Program + LG TV remote control
	
	reg [24:0] counter      = 0;  // Counter for tramsission 38 kz
	reg [24:0] counterTrans = 0;  // Counter for ms counting for code sending
	reg active = 0;		          // Boolean variable for active. If active is 1, pulses of 38Khz are sent by TXD Pin
 
	reg [2:0] status = 0;		  // Variable to control the in which status of the sending information are we. Case control. 
	reg [6:0] bitnum = 0;			  // Variable to control the bit number is been sending

	
	
	assign SD  = 1'b0;	  // Activate IRda SD=0
	assign rxd_p = RXD;   // For debuging RXD
	

	// Send transmission Frecuency pulse of 38KHz block
	always @ ( posedge clk )
	begin
		if (active == 1)
		begin
			counter = counter + 1;
			if (counter < 25 ) TXD <= 1'b1;             //  316 ~= 26 us   2us ~= 25 pulsos
			else if ( counter <  316 ) TXD <= 1'b0;
			else if ( counter == 316 ) counter = 0;
		end
	end

	always @( posedge clk ) 
	begin
		case (status)
		IDLE:
			begin
				active = 0;
				bitnum=0;
				counterTrans = 0;
			end
		AGG:
			begin
				counterTrans = counterTrans + 1;
				if   (counterTrans <  108000) active = 1;   // AGG Pulse
				else
					begin
						active = 0;   // L-Pause
						counterTrans = 0;
						status <= PAUSE;
					end
			end
		PAUSE:
			begin
				counterTrans = counterTrans + 1;
				if   (counterTrans <  54000) active = 0;   // AGG Pulse
				else
					begin
						active = 0;   // L-Pause
						counterTrans = 0;
						status <= SEND_DATA;
					end
			end
		SEND_DATA:
			begin
				if (bitnum > 32)       // Finish transmission and send an stop signal
					begin 
						bitnum=0;
						status <= IDLE;
					end
				else if (data[bitnum] == 1) status <= SEND_1;
				else                        status <= SEND_0;			
			end 

		SEND_0:
			begin
				counterTrans = counterTrans + 1;
				if      (counterTrans <  6750  ) active = 1;	//  562.5us pulse
				else if (counterTrans <  13500 ) active = 0;	//  562.5us space
				else
					begin
						active = 0;   				// Not really needed, already 0
						counterTrans = 0;			// Restart transmission bit counter
						bitnum = bitnum + 1;
						status <= SEND_DATA;
					end
			end

		SEND_1:
			begin
				counterTrans = counterTrans + 1;
				if      (counterTrans <  6750  ) active = 1;	// 562.5us pulse
				else if (counterTrans <  27000 ) active = 0;    // 1687.5us space 
				else
					begin
						active = 0;   			// Not really needed, already 0
						counterTrans = 0;
						bitnum = bitnum + 1;
						status <= SEND_DATA;
					end
			end
		endcase
	end

endmodule