module vga_sync
  (input logic        clk,
   output logic       hsync,
   output logic       vsync,
   output logic [2:0] rgb,
	input logic [15:0] spaceship_bitmap [0:15],
	input logic [15:0] planet_bitmap [0:15],
	input [15:0] xs,
	input [15:0] ys,
	input [15:0] xp,
	input [15:0] yp);
	
   logic pixel_tick, video_on;
   logic [9:0] h_count;
   logic [9:0] v_count;

   localparam HD       = 640, //horizontal display area
              HF       = 48,  //horizontal front porch
              HB       = 16,  //horizontal back porch
              HFB      = 96,  //horizontal flyback
              VD       = 480, //vertical display area
              VT       = 10,  //vertical top porch
              VB       = 33,  //vertical bottom porch
              VFB      = 2,   //vertical flyback
                  LINE_END = HF+HD+HB+HFB-1,
              PAGE_END = VT+VD+VB+VFB-1;

   always_ff @(posedge clk)
     pixel_tick <= ~pixel_tick; //25 MHZ signal is generated.


   //=====Manages hcount and vcount======
   always_ff @(posedge clk)
     if (pixel_tick) 
       begin
          if (h_count == LINE_END)
              begin
                  h_count <= 0;
                  if (v_count == PAGE_END)
                        v_count <= 0;
                  else
                     v_count <= v_count + 1;
               end
           else
               h_count <= h_count + 1;
        end
      
   //=====================color generation=================  
   //== origin of display area is at (h_count, v_count) = (0,0)===
	always_comb
        begin
             if((h_count < HD) && (v_count < VD))// if video on
				 begin
               rgb = 3'b010;
					if((h_count >= xp) && (h_count <= xp + 16) && (v_count >= yp) && (v_count <= yp + 16))
						if (planet_bitmap[v_count - yp][h_count - xp] == 1)
								begin
									rgb = 3'b110;
								end
					if((h_count > xs) && (h_count <= xs + 16) && (v_count > ys) && (v_count <= ys + 16))
						if (spaceship_bitmap[v_count - ys][h_count - xs] == 1)
							begin
								rgb = 3'b100;
							end
				 end
				 else
					rgb = 3'b0;
        end
		  
   //=======hsync and vsync will become 1 during flybacks.=======
   //== origin of display area is at (h_count, v_count) = (0,0)===
   assign hsync = (h_count >= (HD+HB) && h_count <= (HFB+HD+HB-1));
   assign vsync = (v_count >= (VD+VB) && v_count <= (VD+VB+VFB-1));

   initial
     begin
        h_count = 0;
        v_count = 0;
        pixel_tick = 0;
     end

endmodule