module up_down_cnt(
	input cnt_clk,
	input cnt_rst,
	input cnt_in0,
	input cnt_in1,
	output logic [3:0] count_out
);

	logic and_out, or_out,Q0,Q1,cnt_en;
 
always_ff @ (posedge cnt_clk or negedge cnt_rst)begin
	if(!cnt_rst) begin
		Q0 <= 4'h0;
		Q1 <= 4'h0;end
   	else begin
 		and_out <= ~cnt_in0 & cnt_in0;
		Q1 <= or_out;
	end  
end
	assign or_out = and_out | cnt_in1;
	assign cnt_en = Q1;
always_ff @ (posedge cnt_clk or negedge cnt_rst)begin
	if(!cnt_rst) count_out <= 4'h0;
	else begin
		if(cnt_en) begin
			if(count_out == 4'hf)  count_out <= 4'h0;
			else count_out <= count_out + 4'h1;
			end

		else begin
			if(count_out == 4'h0)  count_out <= 4'hf;
			else count_out <= count_out - 4'h1;
			end
	end
end
endmodule
