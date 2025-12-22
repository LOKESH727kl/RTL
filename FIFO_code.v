/////////////////////////       FIFO         ////////////////////////

module fifo_32byte_4byte(
    input fifo_clk,						// FIFO clock
    input fifo_rst_n,					// Active-low reset
    input data_valid, 					// Incoming data valid signal
	input [31:0] data,					// Incoming 32-bit data
  	output logic fifo_out_valid,
  	output logic [31:0] fifo_out          // FIFO read output
);

  	logic fifo_wr_en;         // Write enable
    logic fifo_rd_en;         // Read enable
    logic fifo_full;          // FIFO full flag
    logic fifo_empty;         // FIFO empty flag

 	logic [2:0] wr_ptr;       // 3-bit write pointer (0–7)
    logic [2:0] rd_ptr;       // 3-bit read pointer (0–7)
    logic [3:0] count;        // Stores number of valid words (0–8)
	
	logic [31:0] fifo_mem [0:7]; 			// FIFO Memory 8 words

    assign fifo_full  = (count == 4'h8); 		//FIFO full when 8 entries stored
    assign fifo_empty = (count == 4'h0);   		// FIFO empty when count = 0


	
	assign fifo_wr_en =  data_valid  &&  !fifo_full;     // Write happens when input data is valid and FIFO is not full

    assign fifo_rd_en =  !fifo_empty && !fifo_wr_en;// Reads happens when FIFO is not empty and write is not active

				
			// Write Pointer Update

always_ff @(posedge fifo_clk or negedge fifo_rst_n) 
  if(!fifo_rst_n)		wr_ptr <= 3'h0;
  else if (fifo_wr_en)	wr_ptr <= wr_ptr + 3'h1;

			//Read Pointer Update

always_ff @(posedge fifo_clk or negedge fifo_rst_n)  
  if(!fifo_rst_n)		rd_ptr <= 3'h0;
  else if (fifo_rd_en)	rd_ptr <= rd_ptr + 3'h1;

 			
  // FIFO Count Logic
  
always_ff @(posedge fifo_clk or negedge fifo_rst_n) begin
  if (!fifo_rst_n)
    	count <= 4'd0;
  else begin
    	case ({fifo_wr_en, fifo_rd_en})
          2'b10: if (!fifo_full)  count <= count + 1;
          2'b01: if (!fifo_empty) count <= count - 1;
          default: count <= count;
        endcase
  end
end
  
  // FIFO Memory Write
  
always_ff @(posedge fifo_clk)  
  	if (fifo_wr_en)	fifo_mem[wr_ptr] <= data;

				
	// FIFO Output Logic (READ)
always_ff @(posedge fifo_clk or negedge fifo_rst_n)  
  if(!fifo_rst_n)		    {fifo_out_valid,fifo_out} <= 33'h0;
  else if (fifo_rd_en)	{fifo_out_valid,fifo_out} <= {1'b1,fifo_mem[rd_ptr]};
  else  				        {fifo_out_valid,fifo_out} <= 33'h0;
endmodule


/////////////////////////     TEST BENCH        ////////////////////////


module fifo_32byte_4byte_tb;

    logic fifo_clk;						
    logic fifo_rst_n;				
    logic data_valid;				
    logic [31:0] data;					
    logic [31:0] fifo_out;

    // DUT Instance
    fifo_32byte_4byte dut(
        .fifo_clk(fifo_clk),
        .fifo_rst_n(fifo_rst_n),
        .data_valid(data_valid),
        .data(data),
        .fifo_out(fifo_out)
    );

    // Clock Generation
    initial begin
        fifo_clk = 0;
        forever #5 fifo_clk = ~fifo_clk;    // 10ns clock
    end

    // Stimulus
    initial begin
        fifo_rst_n = 0;
        data_valid = 0;
        data = 32'h0;

        // Release Reset
        #20;
        @(posedge fifo_clk);
        fifo_rst_n = 1;

        // -------------------------
        // WRITE 8 WORDS INTO FIFO
        // -------------------------
      repeat (8) begin
            @(posedge fifo_clk);
            data_valid = 1;
            data = $urandom;   // random 32-bit values
        end

        // Stop write
        @(posedge fifo_clk);
        data_valid = 0;
        data = 32'h0;

        // Wait for reads to occur
      repeat (20) @(posedge fifo_clk);
      repeat (8) begin
            @(posedge fifo_clk);
            data_valid = 1;
            data = $urandom;   // random 32-bit values
        end

       // Stop write
        @(posedge fifo_clk);
        data_valid = 0;
        data = 32'h0;

        // Wait for reads to occur
      repeat (20) @(posedge fifo_clk);
        $finish;
    end

    // Monitor Output
    initial begin
        $monitor("T=%0t | rst=%0b | data_valid=%0b | data=%h | fifo_out=%h",
                 $time, fifo_rst_n, data_valid, data, fifo_out);
    end

    // Dump VCD for GTKWave
    initial begin
        $dumpfile("dump.vcd"); 
        $dumpvars(0, fifo_32byte_4byte_tb);
    end

endmodule