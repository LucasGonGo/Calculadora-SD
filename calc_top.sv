module calc_top(
    input logic [3:0] cmd,
    input logic reset,
    input logic clock,
    // aqui nesses displays sera possivel verificar os numeros da calc
    output logic [6:0] displays [7:0],
    output logic [1:0] status
);

    logic [3:0] data;
    logic [3:0] pos;

calc calculadera (
    .clock(clock), 
    .reset(reset), 
    .cmd(cmd), 
    .status(status),
    .data(data), 
    .pos(pos)
);

ctrl controladoro (
    .clock(clock),
    .reset(reset),
    .dig(data),
    .pos(pos),
    .displays(displays)
);

endmodule