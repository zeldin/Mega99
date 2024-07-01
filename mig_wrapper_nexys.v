module mig_wrapper_nexys(input             clk_mem,
			 input		   rst_n,

			 inout [15:0]	   ddr2_dq,
			 inout [1:0]	   ddr2_dqs_n,
			 inout [1:0]	   ddr2_dqs_p,
			 output [12:0]	   ddr2_addr,
			 output [2:0]	   ddr2_ba,
			 output		   ddr2_ras_n,
			 output		   ddr2_cas_n,
			 output		   ddr2_we_n,
			 output [0:0]	   ddr2_ck_p,
			 output [0:0]	   ddr2_ck_n,
			 output [0:0]	   ddr2_cke,
			 output [0:0]	   ddr2_cs_n,
			 output [1:0]	   ddr2_dm,
			 output [0:0]	   ddr2_odt,

			 input		   cpu_clk,
			 input [2:31]	   wb_adr_i,
			 input [0:31]	   wb_dat_i,
			 output reg [0:31] wb_dat_o,
			 input		   wb_we_i,
			 input [0:3]	   wb_sel_i,
			 input		   wb_stb_i,
			 output		   wb_ack_o,
			 input		   wb_cyc_i);

   wire ui_clk, ui_clk_sync_rst;

   reg [2:0]   mem_cmd;
   reg	       mem_en;
   wire	       mem_rdy;

   wire	       mem_rd_data_end, mem_rd_data_valid;
   wire [63:0] mem_rd_data;

   reg [63:0]  mem_wdf_data;
   reg	       mem_wdf_end, mem_wdf_wren;
   reg [7:0]   mem_wdf_mask;
   wire	       mem_wdf_rdy;

   reg	       old_rstrobe;
   reg	       old_wstrobe;
   wire	       rstrobe;
   wire	       wstrobe;
   wire	       transaction_complete;

   assign wb_ack_o = wb_cyc_i && wb_stb_i && transaction_complete;
   assign rstrobe = wb_cyc_i && wb_stb_i && !wb_we_i && !wb_ack_o;
   assign wstrobe = wb_cyc_i && wb_stb_i && wb_we_i && !wb_ack_o;

   always @(posedge cpu_clk) begin
      old_rstrobe <= rstrobe;
      old_wstrobe <= wstrobe;
   end

   mig mig0(.ddr2_addr(ddr2_addr),
            .ddr2_ba(ddr2_ba),
            .ddr2_cas_n(ddr2_cas_n),
            .ddr2_ck_n(ddr2_ck_n),
            .ddr2_ck_p(ddr2_ck_p),
            .ddr2_cke(ddr2_cke),
            .ddr2_ras_n(ddr2_ras_n),
            .ddr2_we_n(ddr2_we_n),
            .ddr2_dq(ddr2_dq),
            .ddr2_dqs_n(ddr2_dqs_n),
            .ddr2_dqs_p(ddr2_dqs_p),
            .init_calib_complete(),

            .ddr2_cs_n(ddr2_cs_n),
            .ddr2_dm(ddr2_dm),
            .ddr2_odt(ddr2_odt),

            .app_addr(wb_adr_i[4:30]),
            .app_cmd(mem_cmd),
            .app_en(mem_en),
            .app_wdf_data(mem_wdf_data),
            .app_wdf_end(mem_wdf_end),
            .app_wdf_wren(mem_wdf_wren),
            .app_rd_data(mem_rd_data),
            .app_rd_data_end(mem_rd_data_end),
            .app_rd_data_valid(mem_rd_data_valid),
            .app_rdy(mem_rdy),
            .app_wdf_rdy(mem_wdf_rdy),
            .app_sr_req(1'b0),
            .app_ref_req(1'b0),
            .app_zq_req(1'b0),
            .app_sr_active(),
            .app_ref_ack(),
            .app_zq_ack(),
            .ui_clk(ui_clk),
            .ui_clk_sync_rst(ui_clk_sync_rst),

            .app_wdf_mask(mem_wdf_mask),

            .sys_clk_i(clk_mem),
            .sys_rst(rst_n));

   wire rstrobe_sync, wstrobe_sync;

   cdc_flag rs_sync(.a_rst_n(rst_n),
		    .a_clk(cpu_clk),
		    .a_flag(rstrobe & ~old_rstrobe),
		    .b_rst_n(~ui_clk_sync_rst),
		    .b_clk(ui_clk),
		    .b_flag(rstrobe_sync));

   cdc_flag ws_sync(.a_rst_n(rst_n),
		    .a_clk(cpu_clk),
		    .a_flag(wstrobe & ~old_wstrobe),
		    .b_rst_n(~ui_clk_sync_rst),
		    .b_clk(ui_clk),
		    .b_flag(wstrobe_sync));

   reg complete;

   cdc_flag complete_sync(.a_rst_n(~ui_clk_sync_rst),
			  .a_clk(ui_clk),
			  .a_flag(complete),
			  .b_rst_n(rst_n),
			  .b_clk(cpu_clk),
			  .b_flag(transaction_complete));

   reg [2:0] state;

   localparam STATE_IDLE = 3'h0;
   localparam STATE_PREREAD = 3'h1;
   localparam STATE_READ = 3'h2;
   localparam STATE_WRITE = 3'h4;
   localparam STATE_WRITEDATA_H = 3'h5;
   localparam STATE_WRITEDATA_L = 3'h6;

   localparam CMD_READ = 3'h1;
   localparam CMD_WRITE = 3'h0;

   always @(posedge ui_clk) begin
      if(ui_clk_sync_rst) begin
         wb_dat_o <= 32'h0;
      end else begin
         if (state == STATE_READ && mem_rd_data_valid ||
             state == STATE_PREREAD && mem_rdy && mem_rd_data_valid)
	   if (~mem_rd_data_end) begin
              if(~wb_adr_i[31])
		wb_dat_o <= { mem_rd_data[7:0], mem_rd_data[15:8],
			      mem_rd_data[23:16], mem_rd_data[31:24] };
	      else
                wb_dat_o <= { mem_rd_data[15:8], mem_rd_data[23:16],
                              mem_rd_data[31:24], mem_rd_data[39:32] };
           end
      end // else: !if(ui_clk_sync_rst)
   end // always @ (posedge ui_clk)

   always @(posedge ui_clk) begin
      if(ui_clk_sync_rst) begin
         state <= STATE_IDLE;
         complete <= 0;
         mem_cmd <= CMD_WRITE;
         mem_wdf_mask <= 8'hff;
         mem_wdf_data <= 64'h0;
         mem_wdf_wren <= 0;
         mem_wdf_end <= 0;
         mem_en <= 0;
      end else begin
         complete <= 0;

         case(state)

           STATE_IDLE: begin
              mem_wdf_wren <= 0;
              if(wstrobe_sync) begin
                 mem_en <= 1;
                 mem_cmd <= CMD_WRITE;
                 mem_wdf_end <= 0;
                 state <= STATE_WRITE;
              end
              else if(rstrobe_sync) begin
                 mem_en <= 1;
                 mem_cmd <= CMD_READ;
                 state <= STATE_PREREAD;
              end
           end
	   
           STATE_WRITEDATA_H: if(mem_wdf_rdy) begin
              if(~wb_adr_i[31]) begin
		 mem_wdf_mask <= { 4'b1111, ~wb_sel_i[3], ~wb_sel_i[2],
				   ~wb_sel_i[1], ~wb_sel_i[0] };
		 mem_wdf_data <= { 32'h0, wb_dat_i[24:31], wb_dat_i[16:23],
				   wb_dat_i[8:15], wb_dat_i[0:7] };
	      end else begin
                 mem_wdf_mask <= { 3'b111, ~wb_sel_i[3], ~wb_sel_i[2],
				   ~wb_sel_i[1], ~wb_sel_i[0], 1'b1 };
                 mem_wdf_data <= { 24'h0,  wb_dat_i[24:31], wb_dat_i[16:23],
				   wb_dat_i[8:15], wb_dat_i[0:7], 8'h0 };
              end
              mem_wdf_wren <= 1;
              state <= STATE_WRITEDATA_L;
           end // if (mem_wdf_rdy)

           STATE_WRITEDATA_L: if(mem_wdf_rdy) begin
              mem_wdf_mask <= 8'hff;
              mem_wdf_data <= 64'h0;
              mem_wdf_wren <= 1;

              mem_wdf_end <= 1;
              complete <= 1;
              state <= STATE_IDLE;
           end

           STATE_PREREAD: if(mem_rdy) begin
              mem_en <= 0;
              state <= STATE_READ;
              if(mem_rd_data_valid & mem_rd_data_end) begin
                 state <= STATE_IDLE;
                 complete <= 1;
              end
           end

           STATE_READ: begin
              if(mem_rd_data_valid & mem_rd_data_end) begin
                 state <= STATE_IDLE;
                 complete <= 1;
              end
           end
	   
           STATE_WRITE: begin
              if(mem_rdy) begin
                 mem_en <= 0;
                 state <= STATE_WRITEDATA_H;
              end
           end
         endcase
      end
   end // always @ (posedge ui_clk)

endmodule // mig_wrapper_nexys
