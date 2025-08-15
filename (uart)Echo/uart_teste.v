/ uart_top.v — Tang Nano 20K
// Loopback de 64 bytes: ecoa cada byte recebido no UART

module uart_teste (
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx
);

    parameter CLK_FRE  = 27;       // MHz
    parameter UART_FRE = 115200;   // baud rate
    parameter MAX_LEN  = 64;       // tamanho máximo da frase

    wire rst_n = ~rst;

    // ===== UART RX =====
    wire [7:0] rx_data;
    wire       rx_data_valid;
    reg        rx_data_ready;

    // ===== UART TX =====
    reg  [7:0] tx_data;
    reg        tx_data_valid;
    wire       tx_data_ready;

    // ===== Buffer de linha =====
    reg [7:0] buffer [0:MAX_LEN-1];
    reg [$clog2(MAX_LEN):0] buf_len;

    // ===== Controle de envio da frase =====
    reg sending_line;
    reg [$clog2(MAX_LEN):0] send_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_ready <= 1'b0;
            tx_data_valid <= 1'b0;
            tx_data       <= 8'd0;
            buf_len       <= 0;
            sending_line  <= 1'b0;
            send_idx      <= 0;
        end else begin
            tx_data_valid <= 1'b0;
            rx_data_ready <= 1'b0;

            // Recebendo dados
            if (rx_data_valid && !sending_line) begin
                rx_data_ready <= 1'b1;

                // Se recebeu ENTER -> iniciar envio da linha armazenada
                if (rx_data == 8'h0D || rx_data == 8'h0A) begin
                    sending_line <= 1'b1;
                    send_idx     <= 0;

                    // Primeiro envia quebra de linha para fechar a digitação
                    if (tx_data_ready) begin
                        tx_data       <= 8'h0D; // CR
                        tx_data_valid <= 1'b1;
                    end else if (tx_data_ready) begin
                        tx_data       <= 8'h0A; // LF
                        tx_data_valid <= 1'b1;
                    end
                end
                else if (buf_len < MAX_LEN) begin
                    // Eco imediato do caractere digitado
                    if (tx_data_ready) begin
                        tx_data       <= rx_data;
                        tx_data_valid <= 1'b1;
                    end
                    // Armazena no buffer
                    buffer[buf_len] <= rx_data;
                    buf_len         <= buf_len + 1;
                end
            end

            // Enviando linha armazenada abaixo
            if (sending_line && tx_data_ready) begin
                if (send_idx < buf_len) begin
                    tx_data       <= buffer[send_idx];
                    tx_data_valid <= 1'b1;
                    send_idx      <= send_idx + 1;
                end
                else if (send_idx == buf_len) begin
                    tx_data       <= 8'h0D; // CR
                    tx_data_valid <= 1'b1;
                    send_idx      <= send_idx + 1;
                end
                else if (send_idx == buf_len + 1) begin
                    tx_data       <= 8'h0A; // LF
                    tx_data_valid <= 1'b1;
                    send_idx      <= send_idx + 1;
                end
                else begin
                    sending_line <= 1'b0;
                    buf_len      <= 0; // limpa para próxima frase
                end
            end
        end
    end

    // ===== UART RX =====
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

    // ===== UART TX =====
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