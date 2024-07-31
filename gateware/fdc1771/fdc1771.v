module fdc1771
  #(parameter SECTOR_SIZE_CODE = 2'd1) // sec size 0=128, 1=256, 2=512, 3=1024
   ( input				 clk,
     input				 clk_3mhz_en,

     /* CPU interface */
     input				 mr,
     input [7:0]			 dal_in,
     output reg [7:0]			 dal_out,
     input [1:0]			 a,
     input				 cs,
     input				 re,
     input				 we,
     output reg				 irq,
     output reg				 drq,
     output reg				 hld,
     input				 hlt,

     /* Drive interface */
     input				 tr00,
     input				 ip,
     input				 wprt,
     input				 ready,
     output reg				 wd,
     output reg				 wg,
     output reg				 dirc,
     output reg				 step,

     /* Mock drive interface */
     input				 byte_clk,
     input				 header_clk,
     input				 sector_header_match,

     /* Disk image interface */
     output reg [(6+SECTOR_SIZE_CODE):0] data_pos,
     output [7:0]			 data_write_d,
     output reg				 data_write_strobe,
     input [7:0]			 data_read_d,
     output reg				 data_read_strobe,
     output reg				 header_read_strobe,
     output reg				 data_transfer_read_strobe,
     output reg                          data_transfer_write_strobe,
     input				 data_transfer_ack,

     output [7:0]			 track,
     output [7:0]			 sector,
     output [7:0]			 cmd
);

   reg [7:0]  cmd_reg;
   reg [7:0]  track_reg;
   reg [7:0]  sector_reg;
   reg [7:0]  data_reg;
   reg [2:0]  byte_cnt;
   reg	      busy;
   reg	      lost_data;
   reg	      data_enabled;
   reg	      transfer_complete;
   reg	      transfer_pending;
   reg	      sector_found;
   reg	      rnf;
   reg	      crc_error;
   reg	      write_fault;
   reg [1:0]  auto_hld_release_cnt;
   reg [2:0]  rnf_cnt;
   reg [2:0]  step_state;
   reg [7:0]  step_cnt;
   reg [16:0] step_delay;
   reg [16:0] step_delay_target;

   reg	     new_cmd;
   reg	     ready_last;
   reg	     we_last;
   reg	     re_last;
   reg	     data_transfer_ack_last;
   reg [7:0] data_prev;
   reg	     prev_data_avail;

   wire	     rw_end;
   wire	     clear_drq;

   assign data_write_d = data_reg;
   assign track = track_reg;
   assign sector = sector_reg;
   assign cmd = cmd_reg;

   assign rw_end = (we_last && !(cs & we)) || (re_last && !(cs & re));
   assign clear_drq = (rw_end && a == 2'b11);

   always @(cmd[1:0])
     case (cmd[1:0])
       2'b00: step_delay_target = 17'd21476;
       2'b01: step_delay_target = 17'd21476;
       2'b10: step_delay_target = 17'd35794;
       2'b11: step_delay_target = 17'd71590;
     endcase // case (cmd[1:0])

   always @(posedge clk) begin
      ready_last <= ready;
      we_last <= cs & we;
      re_last <= cs & re;
      data_transfer_ack_last <= data_transfer_ack;
   end

   always @(posedge clk)
     if (mr) begin
	irq <= 1'b0;
	drq <= 1'b0;
	hld <= 1'b0;
	wd <= 1'b0;
	wg <= 1'b0;
	dirc <= 1'b0;
	step <= 1'b0;

	track_reg <= 8'h00;
	sector_reg <= 8'h00;
	data_reg <= 8'h00;
	cmd_reg <= 8'h00;
	busy <= 1'b0;
	lost_data <= 1'b0;
	new_cmd <= 1'b0;
	data_enabled <= 1'b0;
	data_write_strobe <= 1'b0;
	data_read_strobe <= 1'b0;
	header_read_strobe <= 1'b0;
	data_transfer_read_strobe <= 1'b0;
	data_transfer_write_strobe <= 1'b0;
	rnf <= 1'b0;
	crc_error <= 1'b0;
	write_fault <= 1'b0;
	auto_hld_release_cnt <= 2'd0;
	rnf_cnt <= 3'd0;
	prev_data_avail <= 1'b0;
	step_cnt <= 8'h00;
	
     end else begin

	if (prev_data_avail)
	  data_prev <= data_read_d;
	prev_data_avail <= data_read_strobe | header_read_strobe;
	
	data_write_strobe <= 1'b0;
	data_read_strobe <= 1'b0;
	header_read_strobe <= 1'b0;
	data_transfer_read_strobe <= 1'b0;
	data_transfer_write_strobe <= 1'b0;

	if (re_last && !(cs & re) && a == 2'b00)
	  irq <= 1'b0;

	if (ip && |auto_hld_release_cnt) begin
	   if (auto_hld_release_cnt == 2'd1)
	     hld <= 1'b0;
	   auto_hld_release_cnt <= auto_hld_release_cnt - 2'd1;
	end

	if (clear_drq)
	  drq <= 1'b0;

	if (new_cmd) begin

	   new_cmd <= 1'b0;
	   data_enabled <= 1'b0;
	   drq <= 1'b0;
	   irq <= 1'b0;
	   step <= 1'b0;
	   lost_data <= 1'b0;
	   data_pos <= 0;
	   byte_cnt <= 3'd7;
	   transfer_complete <= 1'b0;
	   transfer_pending <= 1'b0;
	   sector_found <= 1'b0;
           rnf <= 1'b0;
	   crc_error <= 1'b0;
	   write_fault <= 1'b0;
	   auto_hld_release_cnt <= 2'd3;
	   rnf_cnt <= 3'd0;
	   step_cnt <= 8'h00;

	   if (!cmd_reg[7]) begin
	      // Type I
	      hld <= cmd_reg[3];
	      if (cmd_reg[6:5] == 2'b00) begin
		 step_state <= 3'd0;
		 if (!cmd_reg[4]) begin
		    track_reg <= 8'hff;
		    data_reg <= 8'h00;
		 end
	      end else begin
		 if (cmd_reg[6])
		   dirc <= cmd_reg[5];
		 if (cmd_reg[4])
		   step_state <= 3'd1;
		 else
		   step_state <= 3'd2;
	      end
	   end else if (!cmd_reg[6]) begin
	      // Type II
	      rnf_cnt <= 3'd6;
	   end else if (cmd_reg[5:4] == 2'b01) begin
	      // Type IV
	      if (cmd_reg[3])
		irq <= 1'b1;
	   end else begin
	      // Type III
	      if (!cmd_reg[5])
		rnf_cnt <= 3'd6;
	   end
	end else if (busy) begin

	   if (data_transfer_ack_last && !data_transfer_ack &&
	       transfer_pending) begin
	      transfer_pending <= 1'b0;
	      transfer_complete <= 1'b1;
	   end

	   if (data_enabled && byte_clk) begin
	      if (drq && !clear_drq)
		lost_data <= 1'b1;
	      drq <= 1'b1;
	   end

	   if (byte_clk && |byte_cnt)
	      byte_cnt <= byte_cnt - 3'd1;

	   if (!cmd_reg[7]) begin
	      // Type I
	      case (step_state)
		3'd0: begin //A
		   if (data_reg == track_reg)
		     step_state <= 3'd4;
		   else begin
		      if (data_reg > track_reg)
			dirc <= 1'b0;
		      else
			dirc <= 1'b1;
		      step_state <= 3'd1;
		   end
		end // case: 3'd0
		3'd1: begin // B
		   if (dirc)
		     track_reg <= track_reg - 8'h01;
		   else
		     track_reg <= track_reg + 8'h01;
		   step_state <= 3'd2;
		end
		3'd2: begin // C
		   step_delay <= 17'd0;
		   if (dirc && tr00) begin
		      track_reg <= 8'h00;
		      step_state <= 3'd4;
		   end else if (step_cnt == 8'hff && cmd[7:4] == 4'b0000) begin
		      rnf <= 1'b1;
		      busy <= 1'b0;
		      irq <= 1'b1;
		   end else begin
		      step <= 1'b1;
		      step_cnt <= step_cnt + 8'd1;
		      step_state <= 3'd3;
		   end
		end // case: 3'd2
		3'd3: begin // delay state
		   if (clk_3mhz_en) begin
		      step_delay <= step_delay + 17'd1;
		      if (step_delay == step_delay_target) begin
			 step_delay <= 17'd0;
			 if (step)
			   step <= 1'b0;
			 else
			   step_state <= ( cmd[6:5] == 2'b00 ? 3'd0 : 3'd4 );
		      end
		   end // if (clk_3mhz_en)
		end // case: 3'd3
		3'd4: begin // D
		   // FIXME: implement verify
		   busy <= 1'b0;
		   irq <= 1'b1;
		end
	      endcase // case (step_state)
	   end else if (!cmd_reg[6]) begin
	      // Type II
	      if (sector_header_match)
		sector_found <= 1'b1;

	      if (!cmd_reg[5]) begin
		 // Read Command
		 if (sector_found && !transfer_pending && !transfer_complete)
		   begin
		      transfer_pending <= 1'b1;
		      data_transfer_read_strobe <= 1'b1;
		   end
		  if (byte_clk && transfer_complete && !(|byte_cnt)) begin
		     if (data_enabled)
		       data_reg <= data_prev;
		     if (data_enabled && !(|data_pos)) begin
			data_enabled <= 1'b0;
			busy <= 1'b0;
			irq <= 1'b1;
		     end else begin
			data_enabled <= 1'b1;
			data_read_strobe <= 1'b1;
		     end
		  end
		  if (prev_data_avail)
		     data_pos <= data_pos + 1;
	      end else begin
		 // Write Command
		 if (byte_clk && byte_cnt == 3'd1) begin
		    drq <= 1'b1;
		    data_enabled <= 1'b1;
		 end
		 if (data_enabled && byte_clk)
		   data_write_strobe <= 1'b1;
		 if (data_enabled && data_write_strobe)
		   data_pos <= data_pos + 1;
		 if (data_enabled && byte_clk && !(|(~data_pos))) begin
		    drq <= 1'b0;
		    data_enabled <= 1'b0;
		 end
		 if (!transfer_pending && !transfer_complete && sector_found)
		   begin
		      transfer_pending <= 1'b1;
		      data_transfer_write_strobe <= 1'b1;
		   end
		 if (transfer_complete) begin
		    busy <= 1'b0;
		    irq <= 1'b1;
		 end
	      end
	   end else
	     case (cmd_reg[5:4])
	       2'b00: begin
		  // Read address
		  if (header_clk)
		    sector_found <= 1'b1;
		  if (byte_clk && sector_found && !(|byte_cnt)) begin
		     if (data_enabled)
		       data_reg <= data_prev;
		     if (data_pos == 6) begin
			data_enabled <= 1'b0;
			busy <= 1'b0;
			irq <= 1'b1;
		     end else begin
			data_enabled <= 1'b1;
			header_read_strobe <= 1'b1;
		     end
		  end
		  if (prev_data_avail)
		     data_pos <= data_pos + 1;
	       end
	       2'b10: begin
		  // Read track
		  // TODO: implement ?
		  busy <= 1'b0;
		  irq <= 1'b1;
	       end
	       2'b11: begin
		  // Write track
		  // TODO: implement ?
		  busy <= 1'b0;
		  irq <= 1'b1;
		  write_fault <= 1'b1;
	       end
	       2'b01: ; // Can't happen; force interrupt is never busy...
	     endcase // case (cmd_reg[5:4])

	   if (ip && |rnf_cnt) begin
	      if (rnf_cnt == 3'd1 && !sector_found) begin
		 rnf <= 1'b1;
		 busy <= 1'b0;
		 irq <= 1'b1;
	      end
	      rnf_cnt <= rnf_cnt - 3'd1;
	   end

	end // if (busy)

	if (cmd_reg[7:4] == 4'b1101) begin
	   // Type IV
	   if (cmd_reg[0] && ready && !ready_last)
	     irq <= 1'b1;
	   if (cmd_reg[1] && !ready && ready_last)
	     irq <= 1'b1;
	   if (cmd_reg[2] && ip)
	     irq <= 1'b1;
	end

	if (cs & we)
	  case (a)
	    2'b00:
	      if (!we_last) begin
		 cmd_reg <= dal_in;
		 new_cmd <= 1'b1;
		 if (dal_in[7:4] == 4'b1101)
		   busy <= 1'b0;
		 else
		   busy <= 1'b1;
	      end
	    2'b01: track_reg <= dal_in;
	    2'b10: sector_reg <= dal_in;
	    2'b11: if (drq || !busy) data_reg <= dal_in;
	  endcase // case (a)

     end

   always @(posedge clk)
     if (cs & re)
       case (a)
	 2'b00: begin
	    dal_out[7] <= ~ready;
            if (cmd_reg[7:6] == 2'b11 && cmd_reg[4] == 1'b0)
              // Read address / Read track
              dal_out[6:5] <= 2'b00;
            else if (cmd_reg[7:5] == 3'b100)
              // Read
              dal_out[6:5] <= 2'b00; // FIXME: record type
            else begin
               // Other
               dal_out[6] <= wprt;
               if (~cmd_reg[7])
                 dal_out[5] <= hld & hlt;
               else
                 dal_out[5] <= write_fault;
            end
            if (cmd_reg[7:5] == 3'b111)
              dal_out[4:3] <= 2'b00;
            else
              dal_out[4:3] <= { rnf, crc_error };
	    if (~cmd_reg[7]) begin
	       // Type I command
	       dal_out[2] <= tr00;
	       dal_out[1] <= ip;
	    end else begin
	       // Other
	       dal_out[2] <= lost_data;
	       dal_out[1] <= drq;
	    end
	    dal_out[0] <= busy;
	 end
	 2'b01: dal_out <= track_reg;
	 2'b10: dal_out <= sector_reg;
	 2'b11: dal_out <= data_reg;
       endcase // case (a)

endmodule // fdc1771
