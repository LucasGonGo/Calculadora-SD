module calc (
    input  logic clock,
    input  logic reset,
    input  logic [3:0] cmd,

    output logic [1:0] status,
    output logic [3:0] data,
    output logic [3:0] pos
);

    // Parametros locais para a FSM
    localparam ESPERA_A = 3'b000;       
    localparam ESPERA_B = 3'b001;
    localparam OP       = 3'b010;
    localparam RESULT   = 3'b011;
    localparam ERRO     = 3'b100;

    // Estado Atual / Proximo Estado
    logic [2:0] EA;
    logic [2:0] PE;
    
    // Guardar as entradas
    logic [26:0] digits;

    // Salva as entradas entre ESPERA_A e ESPERA_B
    logic [26:0] regA, regB, regAux;

    // Guarda a operação escolhida
    logic [3:0]  operacao;

    // Count para o calculo da multiplicação
    logic [26:0] count;

    // Ajudam a passar os valores e posições para os CTRL fazer a organização dos displays
    logic [3:0] values [7:0];
    logic [26:0] temp;
    


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
            status   <= 2'b10;   // 00 significa erro, 01 ocupado, e 10 pronto
            operacao <= 0;
            pos <= 4'b0000;
            end else begin

                case (EA)

                    ESPERA_A: 
                    begin
                        if( status == 2'b10) begin

                            if (cmd <= 4'd9) begin
                                digits <= (digits * 10) + cmd; // faz o deslocamento e adiciona
                                status <= 2'b01;               // coloca status como ocupado para passar os valores para os displays

                            end 

                            else if (cmd == 4'b1111)           // Backspace
                            begin
                                digits <= digits / 10; // corta o ultimo numero de digits
                                status <= 2'b01;       // coloca em ocupado para atualizar os displays
                            end 

                        end
                    end

                    OP: 
                    begin

                        if(cmd != operacao)
                        begin
                            regA <= digits; // Salva o valor em regA
                            digits <= 0;    // zera as entradas anteriores, prepara para receber o B futuramente   
                        
                        end
                        if(cmd > 4'd9 && cmd < 4'd13) // as operações estão em 10, 11 e 12
                        begin    
                            operacao <= cmd;                    // salva a entrada em operacao
                            status <= 2'b01;        // coloca em ocupado para apagar os displays
                        end                
                    end

                    ESPERA_B: 
                    begin
                        
                        if( status == 2'b10) 
                        begin
                            if (cmd <= 4'd9) 
                            begin
                                digits <= (digits * 10) + cmd; // Adiciona o novo dígito
                                status <= 2'b01;                // ocupado para att displays
                            end 
                            else if (cmd == 4'b1111)        // Backspace
                            begin
                                digits <= digits / 10; // Remove o último dígito
                                status <= 2'b01;        // att displays
                            end 
                            else if(cmd == 4'b1110) // se for ' = '
                            begin 
                                regB <= digits;     // Salva o valor em regB
                                digits <= 0;        // zera digits
                                status <= 2'b01;    // att displays
                            end
                        end
                    end

                    RESULT: 
                    begin
                        if (status == 2'b10) begin  // so faz se estiver pronto

                            case (operacao)         // ve qual operação foi escolhida
                                4'b1010:            // SOMA
                                begin 
                                    digits <= regA + regB;  // soma A e B
                                    status <= 2'b01;        // displays
                                end
                                4'b1011:            // SUBTRAÇÃO
                                begin 
                                    digits <= regA - regB;   // subtrai A e B
                                    status <= 2'b01;         // displays
                                end
                                4'b1100:            // MULTIPLICAÇÃO
                                begin 
                                    status <= 2'b01;          // coloca em ocupado para fazer a multiplicação
                                        if ((status == 2'b01) && (count == 0))  // se estiver ocupado e count for 0 (multiplicação não começou)
                                        begin
                                            count  <= (regA > regB) ? regB : regA;  // Define o menor valor como contador
                                            regAux <= (regA > regB) ? regA : regB;  // Define o maior valor para ficar somando
                                        end else if (count > 0)                     // Se count, agora com regA ou regB, for maior que 0 ... 
                                        begin
                                            digits <= digits + regAux; // soma o anterior com o valor de aux (maior dos regs)
                                            count  <= count - 1;       // decrementa o contador
                                        end else if (count == 0)       // se count chegar a 0 ...
                                        begin
                                            operacao <= 0;             // limpa a operação para entrar na atualização dos displays
                                            status <= 2'b01; // ocupado após mult
                                        end
                                end
                                default: begin
                                    
                                    // Erro
                                end
                            endcase

                        end
                    
                    end

                    ERRO: begin
                        status <= 2'b00; //status ERRO
                    end

                endcase
                    //LÓGICA PARA OS DISPLAYS
                // MEXEDOR DA POSIÇÃO
                    if (pos > 4'b0111) begin
                    // Reseta pos após todos os displays serem atualizados
                            pos <= 4'b0000;
                            status <= 2'b10;
                    end else 
                    
                    if (status == 00 || (status == 2'b01 && operacao != 4'b1100)) begin // se estiver em ERRO ou se estiver ocupado fora da multiplicação...
                    

                    if(pos == 0) begin temp = digits; end
                    // mapeia para o values o que estiver no digits, tudo isso combinacionalmente, errado mas não conseguimos de outra forma
    
                    values[pos] <= temp % 10; temp <= temp/10; // coloca em values[pos] o valor do digits correspondente, depois corta esse valor
                    

                    // Exibe os valores apenas se o status for ocupado, exceto durante a multi
                    data <= values[pos];
                    
                        
                
                    // Incrementa pos enquanto ocupado, passa para a proxima posição
                        pos <= pos + 1;
                    end

                    end 
        end

    // mudar as maquina de estados
    always_ff @(posedge clock) begin        // talvez seja melhor fazer com combinacional
       
        case (EA)
            ESPERA_A: begin
                if ((cmd > 4'd9)&&(cmd < 4'd11))begin       // se for um operador passa para OP, se for 1111 (backspace) mantem em ESPERA_A
                    PE <= OP;
                end
                else PE <= ESPERA_A;                        // se for um numero ou backspace mantem em ESPERA_A
            end

            OP: if(status == 4'b10 && cmd < 4'b1010) PE <= ESPERA_B;    // se estiver em PRONTO e não for operação, vai para ESPERA_B, possivel erro, não conseguimos resolver
            else PE <= OP;                                              // se for operação mantem em OP
                
            ESPERA_B: begin
            
                if (cmd == 4'b1110)                                     // se for ' = ' vai para RESULT
                begin
                    PE <= RESULT;
                end 

                else if (cmd >= 4'b1010 && cmd < 4'b1110)               // se for OP vai para ERRO
                begin
                    PE <= ERRO;
                end
                else PE <= ESPERA_B;                                   // se for qualquer outra coisa (0 - 9) fica em ESPERA_B

            end
            RESULT: begin
                if( status == 2'b10)begin                               // se estiver pronto, espera "limpar" os displays, possivel erro
                case (operacao)
                    4'b1010: PE <= ESPERA_A;                           //   se for ' + ' vai para ESPERA_A

                    4'b1011: PE <= ESPERA_A;                           //   se for ' - ' vai para ESPERA_A

                    4'b1100:begin                                      //   se for ' x ' ...
                        if (status != 2'b01 && count == 0)begin        //       se não estiver ocupado e count for 0 vai para ESPERA_A
                            PE <= ESPERA_A;
                        end
                        else begin
                            PE <= RESULT;                              // se não, fica em RESULT
                        end
                    end
                    default:
                        PE <= ERRO;                                    // se não for nenhuma operação disponivel, vai para ERRO

                endcase
                end else PE <= RESULT;                                 // se não estiver pronto, fica em RESULT (espera até o status de pronto)
            end

            ERRO:
                PE <= ERRO; //fica no erro até dar reset               // se der ERRO, espera o RESET

        endcase
    end



endmodule