module display
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,	
		SW,	// On Board Keys
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
		GPIO_1,
		LEDR
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;	
	input [9:0] SW;
	output reg [9:0] LEDR;
	inout [35:0] GPIO_1;
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	wire [10:0] x_gyro, y_gyro, z_gyro;
	wire [10:0] x_initial, y_initial, z_initial;

	wire resetn;
	assign resetn = KEY[1];
	
	wire [4:0] randNum;
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [8:0] colour;
	wire [8:0] x;
	wire [7:0] y;
	reg writeEn;
	initial writeEn = 0;
	
	integer decimalRandNumber;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour_reg),
			.x(count_x),
			.y(count_y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "Initial.mif"; 
			
	rand_num_gen x2(.clock(clock), .reset_n(KEY[3]), .dataOut(randNum)); 
	
	gpiotest g1(SW[9:0], GPIO_1[35:0], KEY[3:0], x_gyro[10:0], y_gyro[10:0], z_gyro[10:0], CLOCK_50, x_initial[10:0], y_initial[10:0], z_initial[10:0]);
	
	seg7Display x5(.A(x_initial[3:0]),.hex(HEX0));
	seg7Display y5(.A(x_initial[7:4]),.hex(HEX1));
	seg7Display z5(.A(x_initial[10:8]),.hex(HEX2));
	
	seg7Display x1(.A(z_initial[3:0]),.hex(HEX3));
	seg7Display y1(.A(z_initial[7:4]),.hex(HEX4));
	seg7Display z1(.A(z_initial[10:8]),.hex(HEX5));
	 	
	always@(randNum)
		decimalRandNumber = (2**4)*randNum[4] + (2**3)*randNum[3] + (2**2)*randNum[2] + (2**1)*randNum[1] + (2**0)*randNum[0];
		
	always@(*)
	begin
	LEDR[9] = decimalRandNumber[4];
	LEDR[8] = decimalRandNumber[3];
	LEDR[7] = decimalRandNumber[2];
	LEDR[6] = decimalRandNumber[1];
	LEDR[5] = decimalRandNumber[0];
	if(decimalRandNumber > 0 & decimalRandNumber <= 10)
	begin
		LEDR[0] = 1;
		LEDR[1] = 0;
		LEDR[2] = 0;
	end
	else if(decimalRandNumber > 10 & decimalRandNumber <= 20)
	begin
		LEDR[0] = 0;
		LEDR[1] = 1;
		LEDR[2] = 0;
	end
	else if(decimalRandNumber > 20 & decimalRandNumber <= 31)
	begin
		LEDR[0] = 0;
		LEDR[1] = 0;
		LEDR[2] = 1;
	end
	else 
	begin
		LEDR[0] = 0;
		LEDR[1] = 0;
		LEDR[2] = 0;
	end
	end
	
	// Display random number on the hex display
	//seg7Display hex0(.A(randNum[3:0]), .hex(HEX0));
	//seg7Display hex1(.A(randNum[4]), .hex(HEX1));	
	

	wire clock=~KEY[0];
	reg [16:0] address_reg;
	reg [8:0] count_x;
	reg [7:0] count_y;
	reg done;
	
	wire [8:0] colour_left;
	wire [8:0] colour_right;
	wire [8:0] colour_bottom;
	wire [8:0] colour_game_over;
	reg [16:0] address_left;
	
	reg [8:0] colour_reg;
	reg reset;
	
	//initial reset = 0;
	initial done = 1;
	initial count_x = 0;
	initial count_y = 0;
	//initial address = 0;

	top_left_shot display_test(
		.address(address_reg),
		.clock(CLOCK_50),
		.data(8'b0),
		.wren(1'b0),
		.q(colour_left)
		);

	top_right_shot display_test1(
		.address(address_reg),
		.clock(CLOCK_50),
		.data(8'b0),
		.wren(1'b0),
		.q(colour_right)
		);

	bottom_right_shot display_test2(
		.address(address_reg),
		.clock(CLOCK_50),
		.data(8'b0),
		.wren(1'b0),
		.q(colour_bottom)
		);
		
/*	game_over display_test3(
		.address(address_reg),
		.clock(CLOCK_50),
		.data(8'b0),
		.wren(1'b0),
		.q(colour_game_over)
		); */
		
	 reg [2:0] current_state, next_state;
	 
    localparam  S_LOAD_LEFT_WAIT = 3'd0,
                S_LOAD_LEFT = 3'd1,
                S_LOAD_RIGHT_WAIT = 3'd2,
                S_LOAD_RIGHT = 3'd3,
					 S_BRIGHT_WAIT = 3'd4,
					 S_BRIGHT = 3'd5,
					 S_GAME_OVER = 3'd6,
					 S_GAME_OVER_WAIT = 3'd7;
					 
	reg left, right, bright, game_over;
		always @(*)
		 begin: enable_signals
			  left = 1'b0;
			  right = 1'b0;
			  bright = 1'b0;
			  game_over = 1'b0;

			  case (current_state)
					S_LOAD_LEFT: 
						begin
							left = 1'b1;
						 end
					S_LOAD_RIGHT: 
						begin
							 right = 1'b1;
						 end
					S_BRIGHT: 
						begin
							bright = 1'b1;
						end
					S_GAME_OVER: 
						begin
							game_over = 1'b1;
						end
				endcase
		end
					 
					 
	 always@(posedge CLOCK_50)
		 begin: state_FFs
			if(decimalRandNumber > 0 & decimalRandNumber <= 10) 
				current_state <= S_LOAD_LEFT;
			else if(decimalRandNumber > 10 & decimalRandNumber <= 20)
				current_state <= S_LOAD_RIGHT;
			else if(decimalRandNumber > 20 & decimalRandNumber <= 31)
				current_state <= S_BRIGHT;
			/* else if(SW[6])
				current_state <= S_GAME_OVER; */
		 end 
		 
	always @(posedge CLOCK_50)
	begin
		// Select which image to display
		if(left == 1'b1)
			begin
				colour_reg <= colour_left;
				if(!clock)
					done = 0;
			end
		else if(right == 1'b1)
			begin
				colour_reg <= colour_right;
				if(!clock)
					done = 0;
			end	
		else if(bright == 1'b1)
			begin
				colour_reg <= colour_bottom;
				if(!clock)
					done = 0;
			end	
	/*	else if(game_over == 1'b1)
			begin
				colour_reg <= colour_game_over;
				if(!clock)
					done = 0;
			end	*/
		else
			begin
				done = 1;
				colour_reg <= 0;
			end
	
		// Print image to screen
		if(!done & clock) 
		begin
			address_reg <= address_reg + 1;
			count_x <= count_x + 1;
			writeEn <= 1;
			if(count_x >= 9'b100111111) //319
				begin
					count_y <= count_y +1;
					count_x <= 0;
				end
			if(count_y >= 8'b11110001) // 241
				begin
					writeEn <= 0;
					done = 1;
				end
		end
		
		// Automatically reset the registers after printing
		else
		begin
			colour_reg <= 0;
			address_reg <= 0;
			count_x <= 0;
			count_y <= 0;
		end
	end
endmodule

module rand_num_gen(input clock, input reset_n, output reg [4:0] dataOut);

	reg [4:0] data_next;

	always @* 
		begin
	  		data_next[4] = dataOut[4]^dataOut[1];
	  		data_next[3] = dataOut[3]^dataOut[0];
	  		data_next[2] = dataOut[2]^data_next[4];
	  		data_next[1] = dataOut[1]^data_next[3];
	 		data_next[0] = dataOut[0]^data_next[2];
		end

	always @(posedge clock or negedge reset_n)
	  if(!reset_n)
		 dataOut <= 5'h1f;
	  else
		 dataOut <= data_next;

endmodule

module gpiotest (SW,GPIO_1,,KEY, x_in, y_in, z_in, CLOCK_50, x_initial, y_initial, z_initial);
	input [9:0] SW;
	inout [35:0] GPIO_1;
	input [3:0] KEY;

	input CLOCK_50;
	wire [10:0]inputGPIO;
	wire [10:0]OutputGPIO;
	wire reset;
	assign reset=~KEY[0];
		
	reg [10:0] xreg;
	reg [10:0] outreg;
	initial outreg = 0;
	
	reg ld_x, ld_y, ld_z, go;
	
	reg [25:0] counter;
	initial counter = 25'b0;
	reg done;
	initial done = 0;
	
	output reg [10:0] x_in, y_in, z_in;
	output reg [10:0] x_initial, y_initial, z_initial;
	reg [5:0] current_state, next_state;
	
	
	wire setX, setY, setZ;
	assign setX = GPIO_1[11]; // digital pin 13
	assign setY = GPIO_1[19]; // analog pin A0
	assign setZ = GPIO_1[21]; // analog pin A1

	wire [10:0]bits;
	assign bits[0] = GPIO_1[0];
	assign bits[1] = GPIO_1[1];
	assign bits[2] = GPIO_1[2];
	assign bits[3] = GPIO_1[3];
	assign bits[4] = GPIO_1[4];
	assign bits[5] = GPIO_1[5];
	assign bits[6] = GPIO_1[13];
	assign bits[7] = GPIO_1[7];
	assign bits[8] = GPIO_1[8];
	assign bits[9] = GPIO_1[9];
	assign bits[10] = GPIO_1[10];
	
	
	localparam  S_LOAD_X  				= 5'd0,
               S_LOAD_X_WAIT  		= 5'd1,
               S_LOAD_Y        		= 5'd2,
               S_LOAD_Y_WAIT   		= 5'd3,
					S_LOAD_Z					= 5'd4,
					S_LOAD_Z_WAIT			= 5'd5;
					
					
    always @(*)
    begin: enable_signals
      ld_x = 1'b0;
		ld_y = 1'b0;
      ld_z = 1'b0;
		go = 1'b0;

        case (current_state)
            S_LOAD_X: begin
					ld_x = 1'b1;
                end
				S_LOAD_Y: begin
					ld_y = 1'b1;
					end
				S_LOAD_Z: begin
					ld_z = 1'b1;
					end
        endcase
    end 
	 
	 always@(posedge CLOCK_50)
		 begin: state_FFs
				if(setX) 
					current_state <= S_LOAD_X;
				else if(setY) 
					current_state <= S_LOAD_Y;
				else if(setZ)
					current_state <= S_LOAD_Z;
				else
					current_state <= S_LOAD_X_WAIT;
		 end 
	
	 always@(posedge CLOCK_50) 
		 begin
            if(ld_x)
                x_in <= bits;
            if(ld_y)
                y_in <= bits; 
            if(ld_z)
                z_in <= bits;
		 end
	
	always@(posedge CLOCK_50)
		begin
			if(counter == 25'b10111110101111000010000000 & !done)
				begin
					x_initial <= x_in;
					y_initial <= y_in;
					z_initial <= z_in;
					done <= 1;
				end
			else
				counter = counter + 1'b1;
		end
endmodule

module seg7Display(input[3:0] A, output reg [6:0] hex);
	always @(*)
	begin
		case(A)
			4'h0: hex = 7'b1000000;
			4'h1: hex = 7'b1111001;
			4'h2: hex = 7'b0100100;
			4'h3: hex = 7'b0110000;
			4'h4: hex = 7'b0011001;
			4'h5: hex = 7'b0010010;
			4'h6: hex = 7'b0000010;
			4'h7: hex = 7'b1111000;
			4'h8: hex = 7'b0000000;
			4'h9: hex = 7'b0010000;
			4'hA: hex = 7'b0001000;
			4'hB: hex = 7'b0000011;
			4'hC: hex = 7'b1000110;
			4'hD: hex = 7'b0100001;
			4'hE: hex = 7'b0000110;
			4'hF: hex = 7'b0001110;
			default: hex = 7'b1000000;
		endcase
	end
endmodule