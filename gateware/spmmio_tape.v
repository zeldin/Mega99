module spmmio_tape(input             clk,
		   input	     reset,
		   input	     clk_3mhz_en,
		   input [0:13]	     adr,
		   input	     cs,
		   input [0:3]	     sel,
		   input	     we,
		   input [0:31]	     d,
		   output reg [0:31] q,

		   output reg [0:15] tape_audio,
		   input	     cs1_cntrl,
		   input	     cs2_cntrl,
		   input	     mag_out);

   parameter  memory_size = 8192;

   localparam fifo_depth = 8;

   generate
      if (memory_size > 16384)
	initial $fatal("16384 is max tape memory size");
      if (memory_size < 1280)
	initial $fatal("memory size must be at least 1280");
      if ((memory_size & (memory_size - 1)) != 0)
	initial $fatal("memory size must be a power of 2");
   endgenerate

   reg        playing;
   reg        fmt_16bit;
   reg	      stereo;
   reg	      fmt_1bit;
   reg [0:10] sample_rate;
   reg [0:10] rate_counter;
   reg [13:0] head, tail; // Using big-endian bit numbering for head triggers a Vivado bug...
   reg	      data_available;
   reg	      data_fetched;
   reg [0:31] memory_reg;
   reg [0:31] audio_data;
   reg [0:4]  data_cnt;
   reg	      phase;

   reg        mag_out_last;
   reg [0:11] mag_period_counter;
   reg [0:5]  mag_sync_counter;
   reg	      mag_bit;
   reg [0:2]  mag_bit_cnt;
   reg [0:7]  mag_byte;
   reg	      mag_synced;
   reg	      new_mag_bit;
   reg	      new_mag_byte;
   reg	      mag_byte_lost;

   reg [0:7]  memory0 [0:(memory_size/4-1)];
   reg [0:7]  memory1 [0:(memory_size/4-1)];
   reg [0:7]  memory2 [0:(memory_size/4-1)];
   reg [0:7]  memory3 [0:(memory_size/4-1)];

   wire [0:8] stereo_mix8;
   wire [0:16] stereo_mix16;

   assign stereo_mix8 = { 1'b0, audio_data[0 +: 8] } +
			{ 1'b0, audio_data[8 +: 8] };
   assign stereo_mix16 = { audio_data[8], audio_data[8 +: 8], audio_data[0 +: 8] } +
			 { audio_data[24], audio_data[24 +: 8], audio_data[16 +: 8] };

   wire [0:15] memsize;
   assign memsize = memory_size;

   wire       mag_fifo_produce;
   wire	      mag_fifo_consume;
   wire	      mag_fifo_full;
   wire	      mag_fifo_empty;
   wire [0:9] mag_fifo_input;
   wire [0:9] mag_fifo_output;

   assign mag_fifo_produce = new_mag_byte && clk_3mhz_en;
   assign mag_fifo_consume = (cs && adr[0] == 1'b1 && !we &&
			      adr[11:13] == 3'h3 && !mag_fifo_empty);
   assign mag_fifo_input = { mag_byte, cs2_cntrl, cs1_cntrl };

   function integer log2;  // Actually floor(log2)+1
      input integer value;
      begin
         for (log2=0; value>0; log2=log2+1)
           value = value>>1;
      end
   endfunction

   localparam  memaddr_bits = log2(memory_size/4-1);

   genvar i;
   generate
      for (i=0; i<fifo_depth; i=i+1) begin : ENTRY
	 reg [0:9]  data;
	 wire [0:9] prev_data;
	 reg	    inuse;
	 wire	    prev_inuse;
	 wire	    next_inuse;
	 if (i == 0) begin
	    assign mag_fifo_full = inuse;
	    assign prev_data = mag_fifo_input;
	    assign prev_inuse = mag_fifo_produce;
	 end else begin
	    assign prev_data = ENTRY[i-1].data;
	    assign prev_inuse = ENTRY[i-1].inuse;
	    assign ENTRY[i-1].next_inuse = inuse;
	 end
	 if (i == fifo_depth-1) begin
	    assign mag_fifo_empty = ~inuse;
	    assign mag_fifo_output = data;
	    assign next_inuse = ~mag_fifo_consume;
	 end
	 always @(posedge clk) begin

	    if (mag_fifo_consume || (mag_fifo_produce & !inuse))
	      data <= (prev_inuse ? prev_data : mag_fifo_input);

	    if (reset)
	      inuse <= 1'b0;
	    else begin
	       if (mag_fifo_produce && !mag_fifo_consume)
		 inuse <= next_inuse;
	       if (mag_fifo_consume && !mag_fifo_produce)
		 inuse <= prev_inuse;
	    end
	 end
      end // block: ENTRY
   endgenerate

   always @(posedge clk)
     if (reset) begin
	tape_audio <= 16'h0000;
	playing <= 1'b0;
	fmt_16bit <= 1'b0;
	stereo <= 1'b0;
	fmt_1bit <= 1'b0;
	sample_rate <= 11'h7ff;
	rate_counter <= 11'd0;
	head <= 14'd0;
	tail <= 14'd0;
	data_available <= 1'b0;
	data_fetched <= 1'b0;
	phase <= 1'b0;
	mag_byte_lost <= 1'b0;
     end else begin
	if (!playing) begin
	   tape_audio <= 16'h0000;
	   rate_counter <= 11'd0;
	   data_available <= 1'b0;
	   phase <= 1'b0;
	end else if (clk_3mhz_en) begin
	   if (!cs1_cntrl)
	     tape_audio <= 16'h0000;
	   else if (|rate_counter)
	     rate_counter <= rate_counter - 11'd1;
	   else begin
	      rate_counter <= sample_rate;
	      if (data_available) begin
		 if (fmt_1bit) begin
		    tape_audio[1] <= 1'b1;
		    if (phase) begin
		       if (audio_data[0])
			 tape_audio[0] <= ~tape_audio[0];
		    end else begin
		       tape_audio[0] <= ~tape_audio[0];
		       audio_data <= { audio_data[1 +: 31], 1'b0 };
		       if (data_cnt == 5'd31)
			 data_available <= 1'b0;
		    end
		    phase <= ~phase;
		 end else
		   case({stereo, fmt_16bit})
		     2'b00: begin
			tape_audio <= { ~audio_data[0], audio_data[1 +: 7],
					audio_data[0 +: 8] };
			audio_data <= { audio_data[8 +: 24], 8'h00 };
			if (data_cnt == 5'h3)
			  data_available <= 1'b0;
		     end
		     2'b01: begin
			tape_audio <= { audio_data[8 +: 8], audio_data[0 +: 8] };
			audio_data <= { audio_data[16 +: 16], 16'h0000 };
			if (data_cnt == 5'h1)
			  data_available <= 1'b0;
		     end
		     2'b10: begin
			tape_audio <= { ~stereo_mix8[0], stereo_mix8[1 +: 7],
					stereo_mix8[0 +: 8] };
			audio_data <= { audio_data[16 +: 16], 16'h0000 };
			if (data_cnt == 5'h1)
			  data_available <= 1'b0;
		     end
		     2'b11: begin
			tape_audio <= { stereo_mix16[0 +: 16] };
			data_available <= 1'b0;
		     end
		   endcase // case ({stereo, fmt_16bit})
		 if (!phase)
		   data_cnt <= data_cnt + 5'h1;
	      end
	   end
	end
	if (playing && data_fetched) begin
	   audio_data <= memory_reg;
	   data_available <= 1'b1;
	   data_cnt <= 5'h0;
	end
	data_fetched <= 1'b0;
	if (playing && !data_available && !data_fetched &&
	    head != tail) begin
	   memory_reg <= { memory0[head[0 +: memaddr_bits]],
			   memory1[head[0 +: memaddr_bits]],
			   memory2[head[0 +: memaddr_bits]],
			   memory3[head[0 +: memaddr_bits]] };
	   data_fetched <= 1'b1;
	   head <= head + 14'd1;
	end

	if (cs && adr[0] == 1'b0 && we) begin
	 if (sel[0])
	   memory0[adr[13 -: memaddr_bits]] <= d[0 +: 8];
	 if (sel[1])
	   memory1[adr[13 -: memaddr_bits]] <= d[8 +: 8];
	 if (sel[2])
	   memory2[adr[13 -: memaddr_bits]] <= d[16 +: 8];
	 if (sel[3])
	   memory3[adr[13 -: memaddr_bits]] <= d[24 +: 8];
	end

	if (cs && adr[0] == 1'b1 && we) begin
	   if (sel[0])
	     case (adr[11:13])
	       3'h1: head[6 +: 8] <= d[0 +: 8];
	     endcase // case (adr[11:13])
	   if (sel[1])
	     case (adr[11:13])
	       3'h0: begin
		  fmt_1bit <= d[12];
		  stereo <= d[13];
		  fmt_16bit <= d[14];
		  playing <= d[15];
	       end
	       3'h1: head[0 +: 6] <= d[8 +: 6];
	     endcase // case (adr[11:13])
	   if (sel[2])
	     case (adr[11:13])
	       3'h0: sample_rate[0 +: 3] <= d[23 -: 3];
	       3'h1: tail[6 +: 8] <= d[16 +: 8];
	     endcase // case (adr[11:13])
	   if (sel[3])
	     case (adr[11:13])
	       3'h0: sample_rate[3 +: 8] <= d[24 +: 8];
	       3'h1: tail[0 +: 6] <= d[24 +: 6];
	     endcase // case (adr[11:13])
	end

	if (mag_fifo_consume)
	  mag_byte_lost <= 1'b0;
	else if (mag_fifo_produce && mag_fifo_full)
	  mag_byte_lost <= 1'b1;

     end // else: !if(reset)


   always @(posedge clk)
     if (reset) begin
	mag_period_counter <= 12'h000;
	mag_sync_counter <= 6'd0;
	mag_synced <= 1'b0;
	new_mag_bit <= 1'b0;
	new_mag_byte <= 1'b0;
     end else if (clk_3mhz_en) begin

	new_mag_byte <= 1'b0;
	if (new_mag_bit) begin
	   mag_byte <= { mag_byte[1:7], mag_bit };
	   if (mag_bit_cnt == 3'd7)
	     new_mag_byte <= 1'b1;
	   mag_bit_cnt <= mag_bit_cnt + 3'd1;
	end

	new_mag_bit <= 1'b0;
	if (mag_period_counter[0:3] == 4'b0001)
	  mag_bit <= 1'b0;
	if (mag_out != mag_out_last) begin
	   if (mag_period_counter[0:2] == 3'b100) begin
	      if (mag_synced)
		new_mag_bit <= 1'b1;
	      else if (mag_bit && (&mag_sync_counter)) begin
		 new_mag_bit <= 1'b1;
		 if (mag_bit_cnt == 3'd7)
		   mag_synced <= 1'b1;
	      end else if (mag_bit)
		mag_sync_counter <= 6'd0;
	      else begin
		 mag_bit_cnt <= 3'd0;
		 if (!(&mag_sync_counter))
		   mag_sync_counter <= mag_sync_counter + 6'd1;
	      end
	      mag_period_counter <= 12'h000;
	   end else if (mag_period_counter[0:3] == 4'b0100)
	     mag_bit <= 1'b1;
	   else begin
	      mag_synced <= 1'b0;
	      mag_sync_counter <= 6'd0;
	      mag_period_counter <= 12'h000;
	   end
	end else if (!(&mag_period_counter))
	  mag_period_counter <= mag_period_counter + 12'd1;
	else if (mag_synced) begin
	   mag_synced <= 1'b0;
	   mag_sync_counter <= 6'd0;
	   new_mag_bit <= 1'b1;
	end
	mag_out_last <= mag_out;
     end

   always @(*) begin
      q <= 32'h00000000;
      case (adr[11:13])
	3'h0: begin
	   q[12] <= fmt_1bit;
	   q[13] <= stereo;
	   q[14] <= fmt_16bit;
	   q[15] <= playing;
	   q[31 -: 11] <= sample_rate;
	end
	3'h1: begin
	   q[0 +: 14] <= head;
	   q[16 +: 14] <= tail;
	end
	3'h2: begin
	   q[0 +: 16] <= memsize;
	end
	3'h3: begin
	   q[0:1] <= { cs2_cntrl, cs1_cntrl };
	   q[4:5] <= mag_fifo_output[8 +: 2];
	   q[6] <= mag_byte_lost;
	   q[7] <= ~mag_fifo_empty;
	   q[8 +: 8] <= mag_fifo_output[0 +: 8];
	end
      endcase // case (adr[11:13])
   end

endmodule // spmmio_tape
