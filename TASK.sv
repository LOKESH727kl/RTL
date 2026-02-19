module task_1(
    input clkA,
    input clkB,
    input rst_n,
	input sigA,
    output logic out
);
    logic q1_out;
    logic d_in;
    assign d_in = sigA ^ q1_out;

always_ff @(posedge clkA or negedge rst_n)
    if(!rst_n)  q1_out <= 0;
    else        q1_out <= d_in;

logic [2:0] q2_out;

always_ff @(posedge clkB or negedge rst_n) 
  if (!rst_n) q2_out <= 3'h0;
  else  		q2_out <= {q2_out[1:0], q1_out};   

assign out = q2_out[2] ^ q2_out[1];
endmodule


/*
module task_1(
    input clkA,
    input clkB,
    input rst_n,
	input sigA,
    output logic out
);
    logic q1_out;
    logic q2_out;
    logic q3_out;
    logic q4_out;
    logic d_in;

	assign d_in = sigA ^ q1_out;

	
always_ff @(posedge clkA or negedge rst_n)
    if(!rst_n)  q1_out <= 1'b0;
    else        q1_out <= d_in;
  
always_ff @(posedge clkB or negedge rst_n)
    if(!rst_n)  q2_out <= 1'b0;
    else        q2_out <= q1_out;

always_ff @(posedge clkB or negedge rst_n)
    if(!rst_n)  q3_out <= 1'b0;
    else        q3_out <= q2_out; 

always_ff @(posedge clkB or negedge rst_n)
    if(!rst_n)  q4_out <= 1'b0;
    else        q4_out <= q3_out;    

assign out = q4_out ^ q3_out;

endmodule




	// =========================================================
    // 						TEST_BENCH
    // =========================================================

module task_1_tb;
  logic clkA;
  logic clkB;
  logic rst_n;
  logic sigA;
  wire out;

    
task_1 dut(
  .clkA(clkA),
  .clkB(clkB),
  .rst_n(rst_n),
  .sigA(sigA),
  .out(out)
);
  
 always #5 clkA = ~ clkA; 
 always #7 clkB = ~ clkB;

  initial begin
	clkA = 0;
	clkB = 0;
	rst_n = 0; 
	sigA = 0;
end

initial begin 
  @(posedge clkA); 	rst_n = 1'b1;
  @(posedge clkA) ; sigA = 0;
  @(posedge clkA) ; sigA = 1;
#100 $finish;
end
initial begin
  $monitor("time = %0t |clk_A = %d | |clk_B = %d | reset = %d | sigA =  %d  | out = %d  ",$time ,clkA, clkB,rst_n,sigA,out);
end
  
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule





module up_down_cnt(
		input cnt_clk,
		input cnt_rst_n,
		input up_pulse,
		input down_pulse,
		input load_pulse,
		input load_en,
		//input [16:0] load_value,
		output logic [16:0] count_out,
		output logic out_pulse
);
always_ff @ (posedge cnt_clk or negedge cnt_rst_n)begin
	if(!cnt_rst_n) count_out <= 17'h0;
	else begin 
		if(load_en) 
			if(load_pulse )		count_out <= 17'h15180;
			count_out <= (count_out == 17'h0 & a_load_pulse) ? 17'h15180  : count_out - {16'h0, down_pulse & a_load_pulse};
			

		else 
			if(up_pulse)	count_out <= (count_out == 17'h15180)? 17'h0 : count_out + 17'b1;
	end
end
assign out_pulse = ((count_out == 17'h100)  | (count_out == 17'hE10) |(count_out == 17'h15180));
endmodule