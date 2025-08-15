// uart_top.v — Tang Nano 20K
// Loopback de 8 bits: ecoa cada byte recebido no UART

module uart_teste (
    input  wire clk,       // clock do sistema
    input  wire rst,       // reset ativo alto
    input  wire uart_rx,   // pino RX
    output wire uart_tx    // pino TX
);

    // ===== Parâmetros (ajuste se necessário) =====
    parameter CLK_FRE  = 27;       // MHz (Tang Nano 20K = 27 MHz por padrão)
    parameter UART_FRE = 115200;   // baud rate

    // ===== Reset interno ativo em baixo (compatível com os IPs) =====
    wire rst_n = ~rst;

    // ===== Sinais UART RX =====
    wire [7:0] rx_data;
    wire       rx_data_valid;
    reg        rx_data_ready;

    // ===== Sinais UART TX =====
    reg  [7:0] tx_data;
    reg        tx_data_valid;
    wire       tx_data_ready;

    // ===== Máquina de handshake simples p/ loopback =====
    // Política:
    //  - Só consome o byte do RX quando o TX estiver pronto.
    //  - tx_data_valid é um pulso de 1 ciclo quando carregamos o byte.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data        <= 8'd0;
            tx_data_valid  <= 1'b0;
            rx_data_ready  <= 1'b0;
        end else begin
            // valores padrão a cada ciclo
            tx_data_valid  <= 1'b0;
            rx_data_ready  <= 1'b0;

            // se há byte válido no RX e o TX está pronto, ecoa
            if (rx_data_valid && tx_data_ready) begin
                tx_data       <= rx_data;
                tx_data_valid <= 1'b1; // pulso de 1 ciclo
                rx_data_ready <= 1'b1; // informa ao RX que consumimos o byte
            end
        end
    end

    // ===== Instância do receptor =====
    uart_rx #(
        .CLK_FRE  (CLK_FRE),
        .BAUD_RATE(UART_FRE)
    ) u_rx (
        .clk           (clk),
        .rst_n         (rst_n),
        .rx_data       (rx_data),
        .rx_data_valid (rx_data_valid),
        .rx_data_ready (rx_data_ready),
        .rx_pin        (uart_rx)
    );

    // ===== Instância do transmissor =====
    uart_tx #(
        .CLK_FRE  (CLK_FRE),
        .BAUD_RATE(UART_FRE)
    ) u_tx (
        .clk           (clk),
        .rst_n         (rst_n),
        .tx_data       (tx_data),
        .tx_data_valid (tx_data_valid),
        .tx_data_ready (tx_data_ready),
        .tx_pin        (uart_tx)
    );

endmodule
