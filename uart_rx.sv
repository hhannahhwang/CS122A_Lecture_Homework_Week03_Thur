`include "clock_mul.sv"

module uart_rx #(
    parameter SRC_FREQ = 78600,
    parameter BAUDRATE = 9600 //the slowest it can go 
)(
    input clk,
    input rx,
    output reg rx_ready, 
    output reg [7:0] rx_data
);

// STATES: State of the state machine
localparam DATA_BITS = 8;
localparam 
    INIT = 0, 
    IDLE = 1,
    RX_DATA = 2,
    STOP = 3;

wire uart_clk;
reg [1:0] state = INIT;
reg [2:0] bit_count = 0;
reg [7:0] rx_shift_reg = 0;
reg rx_done_toggle = 0; 

// // CLOCK MULTIPLIER: Instantiate the clock multiplier
clock_mul #(
    .SRC_FREQ(SRC_FREQ),
    .OUT_FREQ(BAUDRATE)
) clk_gen (
    .src_clk(clk),
    .out_clk(uart_clk)
);

// // CROSS CLOCK DOMAIN: The rx_ready flag should only be set 1 one for one source 
// // clock cycle. Use the cross clock domain technique discussed in class to handle this.
reg sync_q1, sync_q2, sync_q3;

always @(posedge clk) begin
    sync_q1 <= rx_done_toggle;
    sync_q2 <= sync_q1;
    sync_q3 <= sync_q2;
    rx_ready <= (sync_q2 ^ sync_q3);
end

// // STATE MACHINE: Use the UART clock to drive that state machine that receves a byte from the rx signal
always @(posedge uart_clk) begin
    case (state)
        INIT: begin
            state <= IDLE;
        end

        IDLE: begin
            if (rx == 1'b0) begin // Start bit detected (logic low)
                state <= RX_DATA;
                bit_count <= 0;
            end
        end

        RX_DATA: begin
            rx_shift_reg[bit_count] <= rx; 
            if (bit_count == 7) begin
                state <= STOP;
            end else begin
                bit_count <= bit_count + 1;
            end
        end

        STOP: begin
            if (rx == 1'b1) begin //Stop bit (logic high)
                rx_data <= rx_shift_reg;
                rx_done_toggle <= ~rx_done_toggle; 
            end
            state <= IDLE;
        end
        
        default: state <= IDLE;
    endcase
end

endmodule