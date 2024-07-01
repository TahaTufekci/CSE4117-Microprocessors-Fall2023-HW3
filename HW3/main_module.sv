module main_module (
                        input clk,
								input ps2c,
								input ps2d,
								output logic ground,
                        output logic [2:0] rgb,
								output logic hsync,
								output logic vsync
                   );

						 localparam    BEGINMEM = 12'h000,
											ENDMEM = 12'h7ff,
											X_SPACESHIP=12'ha00,
											Y_SPACESHIP=12'ha01,
											X_PLANET=12'hb00,
											Y_PLANET=12'hb01,
											BEGIN_SPACESHIP_BITMAP=12'hc00,
											END_SPACESHIP_BITMAP=12'hc0f,
											BEGIN_PLANET_BITMAP=12'hd00,
											END_PLANET_BITMAP=12'hd0f,
											KB_DATA=12'h900,
											KB_STATUS=12'h901;
logic [15:0] spaceship_bitmap [0:15];
logic [15:0] planet_bitmap [0:15];
logic [15:0] keyboard_data;
logic [15:0] x_s;
logic [15:0] y_s;
logic [15:0] x_p;
logic [15:0] y_p;
//====memory chip==============
logic [15:0] memory [0:511];
 
//=====cpu's input-output pins=====
logic [15:0] data_out;
logic [15:0] data_in;
logic [11:0] address;
logic memwt;
logic INT;    //interrupt pin
logic intack; //interrupt acknowledgement

vga_sync vga(.clk(clk), .hsync(hsync), .vsync(vsync), .rgb(rgb),.xs(x_s),.ys(y_s),.xp(x_p),.yp(y_p),.spaceship_bitmap(spaceship_bitmap),.planet_bitmap(planet_bitmap));
mammal m1( .clk(clk), .data_in(data_in), .data_out(data_out), .address(address), .memwt(memwt),.INT(INT), .intack(intack));
keyboard kb(.clk(clk), .ps2d(ps2d), .ps2c(ps2c), .ack(ack), .dout(keyboard_data));

//====multiplexer for cpu input======
always_comb
begin
		if ( (BEGINMEM<=address) && (address<=ENDMEM) )
		begin
			data_in=memory[address];
			ack = 0;
		end
		else if (address==KB_STATUS)
		begin
			data_in = keyboard_data;
			ack = 0;
		end
		else if (address==KB_DATA)
		begin
			data_in = keyboard_data;
			ack = 1;
		end
		else 
		begin
			data_in=16'hf345; //last else to generate combinatorial circuit.
			ack = 0;
		end
end
//=====multiplexer for cpu output=========== 
always_ff @(posedge clk) //data output port of the cpu
    if (memwt)
        if ( (BEGINMEM<=address) && (address<=ENDMEM))
               memory[address]<=data_out;
        else if ( address == X_SPACESHIP) 
               x_s<=data_out;
			else if ( address == Y_SPACESHIP) 
               y_s<=data_out;
			else if ( address == X_PLANET) 
               x_p<=data_out;
			else if ( address == Y_PLANET) 
               y_p<=data_out;
			else if ( (BEGIN_SPACESHIP_BITMAP<=address) && (address<=BEGIN_SPACESHIP_BITMAP +16)) 
               spaceship_bitmap[address-12'hc00]<=data_out;
			else if ( (BEGIN_PLANET_BITMAP<=address) && (address<=BEGIN_PLANET_BITMAP+16))
               planet_bitmap[address-12'hd00]<=data_out;
	initial 
		 begin
			  $readmemh("ram.dat", memory);
		 end
	endmodule