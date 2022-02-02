module IrDA( clk, RXD, TXD, SD, led, ledGreen, rxd_p);
	input  wire clk;
	input  wire RXD;
	output wire TXD;
	output wire SD;
	output [3:0] led = 4'b0000;
	output ledGreen;
	output  wire rxd_p;

	parameter AGG          = 3'b000;
	parameter PAUSE        = 3'b001;
	parameter SEND_DATA    = 3'b010;
	parameter SEND_COMMAND = 3'b011;
	parameter SEND_0       = 3'b100;
	parameter SEND_1       = 3'b101;
	parameter IDLE         = 3'b110;

	parameter data         = 32'hFF00FB04;
	
	reg [24:0] counter      = 0;  //Counter for tramsission 38 kz
	reg [24:0] counterTrans = 0;  //Counter for ms counting
	reg active = 0;		          //Boolean variable for active
 
	reg [2:0] phase = 0;
	reg [6:0] i = 0;

	
	// Activate IRda SD=0
	assign SD  = 1'b0;
	assign rxd_p = RXD;   // For debuging RXD
	

	// Send transmission Frecuency pulse of 38KHz
	always @ ( posedge clk )
	begin
		if (active == 1)
		begin
			counter = counter + 1;
			if (counter < 158 ) TXD <= 1'b1;
			else if ( counter <  316 ) TXD <= 1'b0;
			else if ( counter == 316 ) counter = 0;
		end
	end

	always @( posedge clk ) 
	begin
		case (phase)

		IDLE:
			begin
				active = 0;
				i=0;
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
						phase <= PAUSE;
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
						phase <= SEND_DATA;
					end
			end
		SEND_DATA:
			begin
				if (i > 32) 
					begin 
						i=0;
						phase <= IDLE;
					end
				else if (data[i] == 1) phase <= SEND_1;
				else phase <= SEND_0;			
			end 

		SEND_0:
			begin
				counterTrans = counterTrans + 1;
				if      (counterTrans <  6750  ) active = 1;
				else if (counterTrans <  13500 ) active = 0;
				else
					begin
						active = 0;   // L-Pause
						counterTrans = 0;
						i = i + 1;
						phase <= SEND_DATA;
					end
			end

		SEND_1:
			begin
				counterTrans = counterTrans + 1;
				if      (counterTrans <  6750  ) active = 1;
				else if (counterTrans <  27000 ) active = 0;
				else
					begin
						active = 0;   // L-Pause
						counterTrans = 0;
						i = i + 1;
						phase <= SEND_DATA;
					end
			end
		endcase
	end

endmodule