module calc (
    input  logic clock,
    input  logic reset,
    input  logic [3:0] cmd,

    output logic [1:0] status,
    output logic [3:0] data,
    output logic [3:0] pos,
    output logic [2:0] EA,
    output logic [2:0] PE
);

    // Parametros locais para a FSM
    localparam ESPERA_A = 3'b000;       
    localparam ESPERA_B = 3'b001;
    localparam OP       = 3'b010;
    localparam RESULT   = 3'b011;
    localparam ERRO     = 3'b100;

    // Estado Atual / Proximo Estado
 
    
    // Guardar as entradas
    logic [26:0] digits;

    //habilitar a impressão
    logic enable;

    

    // Salva as entradas entre ESPERA_A e ESPERA_B
    logic [26:0] regA, regB, regAux;

    // Guarda a operação escolhida
    logic [3:0]  operacao;

    // Count para o calculo da multiplicação
    logic [26:0] count;

    // Ajudam a passar os valores e posições para os CTRL fazer a organização dos displays
  
    logic [26:0] temp;

    logic reset_temp;                       // guarda o valor do reset
    logic negedge_reset;                    // vou usar na FSM pra achar a borda de descida do reset
    always_ff @(posedge clock or posedge reset) begin   // vai guardar o valor do reset
        if(reset) begin
            reset_temp <= 1;
        end else begin
            reset_temp <= 0;
        end
    end
    assign negedge_reset = (reset_temp == 1) && (reset == 0);   // checa se teve borda de descida no reset, se estava em 1 e agora é 0 então teve borda de descida
    
    // Bloco sequencial: atualização do estado
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            EA <= ESPERA_A;
        end else begin
            EA <= PE;
        end
    end

// Bloco sequencial: lógica da operação
always_ff @(posedge clock or posedge reset) begin
    if (reset) begin        // reset, zera tudo
        digits   <= 0;      
        regA     <= 0;
        regB     <= 0;
        regAux   <= 0;
        count    <= 0;
        temp     <= 0;
        status   <= 2'b10;   // 00 significa erro, 01 ocupado, 10 pronto e 11 imprimindo
        operacao <= 0;
        pos <= 0;
    end else begin

        // LÓGICA PARA OS DISPLAYS
        if (enable) begin
            if (pos == 4'd8) begin
                pos <= 0;
                enable <= 0;
                status <= 2'b10;
                temp <= digits; // recupera o temp pra receber mais digitos
            end else begin
                data <= temp % 10;
                temp <= temp / 10;
                pos <= pos + 1;
                
            end
        end else begin
            case (EA)

                ESPERA_A: begin
                        if (cmd <= 4'd9) begin
                            digits <= (digits * 10) + cmd;
                            status <= 2'b11;
                            temp <= (temp * 10) + cmd;
                            enable <= 1;
                        end else if (cmd == 4'b1111) begin // Backspace
                            digits <= digits / 10;
                            temp <= temp / 10;
                            status <= 2'b11;
                            enable <= 1;
                        end
                        // indo para o OP
                        else if ((cmd > 4'd9)&&(cmd < 4'd13)) begin
                            regA <= digits;
                            digits <= 0;
                            temp <= 0;
                            status <= 2'b11;
                            enable <= 1;

                        end
                end

                OP: begin
                    if (cmd >= 4'd10) begin
                        operacao <= cmd; // Atribuição não bloqueante
                        $display("Estado OP: cmd = %b, operacao = %b", cmd, operacao); // Debug
                    end else begin
                        $display("Estado OP: cmd fora do intervalo, cmd = %b", cmd); // Debug
                    end
                end

                ESPERA_B: begin
                        if (cmd <= 4'd9) begin
                            digits <= (digits * 10) + cmd;
                            status <= 2'b11;
                            temp <= (temp * 10) + cmd;
                            enable <= 1;
                        end else if (cmd == 4'b1111) begin // Backspace
                            digits <= digits / 10;
                            temp <= temp / 10;
                            status <= 2'b11;
                            enable <= 1;
                        end else if (cmd == 4'b1110) begin // '='
                            regB <= digits;
                            digits <= 0;
                            temp <= 0;
                            status <= 2'b11;
                            enable <= 1;
                        end
                end

                RESULT: begin
                    case (operacao)
                        4'b1010: begin // SOMA
                            digits <= regA + regB;
                            temp <= regA + regB;
                            status <= 2'b11;
                            enable <= 1;
                        end

                        4'b1011: begin // SUBTRAÇÃO
                            digits <= regA - regB;
                            temp <= regA - regB;
                            status <= 2'b11;
                            enable <= 1;
                        end

                        4'b1100: begin // MULTIPLICAÇÃO deixa pra dps
                            if (status == 2'b10 && count == 0) begin
                                count  <= (regA > regB) ? regB : regA;
                                regAux <= (regA > regB) ? regA : regB;
                                status <= 2'b01;
                            end else if (count > 0) begin
                                temp <= temp + regAux;
                                count  <= count - 1;
                            end else if (count == 0) begin
                                operacao <= 0;
                                status <= 2'b11;
                                enable <= 1;
                            end
                        end

                        default: begin
                            // Erro
                        end
                    endcase
                end

                ERRO: begin
                    status <= 2'b00; // status ERRO
                end

            endcase
        end
    end
end

        

    // mudar as maquina de estados
    always_comb begin        // talvez seja melhor fazer com combinacional
    if(negedge_reset)begin PE = ESPERA_A;end
    else if (!enable)begin
        case (EA)
            ESPERA_A: begin
                if ((cmd > 4'd9)&&(cmd < 4'd13))begin       // se for um operador passa para OP, salva tudo, e ja imprime, se for 1111 (backspace) mantem em ESPERA_A
                    PE = OP;
                end
                else PE = ESPERA_A;                        // se for um numero ou backspace mantem em ESPERA_A
            end

            OP: begin 
                $display("PE = %b, Operacao = %b", PE, operacao);
                if (operacao >= 4'd10 && cmd != operacao) begin
                            PE = ESPERA_B; 
            end else PE = OP;
                        
            end                                   // confia, ele vai cair em OP, armazena a operação e pula fora, foge, se nao for uma operaçao, volta pra OP               
            ESPERA_B: begin
            
                if (cmd == 4'b1110)                                     // se for ' = ' vai para RESULT
                begin
                    PE = RESULT;
                end else if((cmd < 4'd9)||(cmd == 4'b1111)) begin
                    PE = ESPERA_B;                                   // se for ' backspace ' vai pra 
                end else begin 
                    PE <= ERRO; 
                end                                // se for qualquer outra coisa (0 - 9) ou OP(fica esperando um caractere) fica em ESPERA_B
            end
            RESULT: begin
                case (operacao)
                    4'b1010:begin
                            PE = RESULT;                          
                    end
                    4'b1011: begin
                            PE = RESULT;                          
                    end
                    4'b1100:begin                                      //   se for ' x ' ...
                        if (operacao == 0)begin        //       se não estiver ocupado e count for 0 vai para ESPERA_A
                            PE = ESPERA_A;
                        end
                        else begin
                            PE = RESULT;                              // se não, fica em RESULT
                        end
                    end
                    default:
                        PE = RESULT;                                    // se não for nenhuma operação disponivel, volta pra RESULT

                endcase
            end 

            default: begin
                PE = ERRO; //fica no erro até dar reset               // se der ERRO, espera o RESET
            end
        endcase
       end
    end



endmodule