`timescale 1ns/100ps

module tb_calc_top;

  // Inputs
  logic clock = 0;
  logic reset;
  logic [3:0] cmd;

  // Outputs
  logic [6:0] displays [7:0];
  logic [1:0] status;
  logic [2:0] EA;
  logic [2:0] PE;
  
  

  // Instância do DUT (Device Under Test)
  calc_top calc_top (
    .clock(clock),
    .reset(reset),
    .cmd(cmd),
    .displays(displays),
    .status(status),
    .EA(EA),
    .PE(PE)
  );

  // Geração de clock
  always #1 clock = ~clock;

  initial begin
    reset = 1; #2;
    reset = 0; 

  // // Teste 1: 123 + 1 =
  //   cmd = 4'd1; #20; // 1
  //   cmd = 4'd2; #20; // 2
  //   cmd = 4'd3; #20; // 3
  //   cmd = 4'b1010; #30; // +
  //   cmd = 4'd1; #20; // 1
  //   cmd = 4'b1110; #60; // 124
    
  //   #20;
  //   reset = 1; #2;
  //   reset = 0;


  // // Teste 2: 50 - 15 =
  //   cmd = 4'd5; #20;
  //   cmd = 4'd0; #20;
  //   cmd = 4'b1011; #20;
  //   cmd = 4'd1; #20;
  //   cmd = 4'd5; #20;
  //   cmd = 4'b1110; #20;

  //   #20;
  //   reset = 1; #2;
  //   reset = 0; 


  // Teste 3: 6 * 2 =
   cmd = 4'd6; #20;
   cmd = 4'b1100; #20;
   cmd = 4'd2; #20;
   cmd = 4'b1110; #100; // demora mais pra fazer a multiplicação

    #20;
    reset = 1; #2;
    reset = 0; 


    // // Teste 4: 456 -> backspace -> 45
    // cmd = 4'd4; #20;
    // cmd = 4'd5; #20;
    // cmd = 4'd6; #20;
    // cmd = 4'b1111; #30;
    // cmd = 4'b1110; #60;  

    #20;
    $finish;

  end


endmodule