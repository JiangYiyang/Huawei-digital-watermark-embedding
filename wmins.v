`timescale 1ns / 1ps                                                                                                      
//////////////////////////////////////////////////////////////////////////////////                                        
// clolege:   UCAS                                                                                                            
// Engineer:  Jiang Yi Yang                                                                                                            
//                                                                                                                        
// Create Date: 2018/02/15 15:52:01                                                                                       
// Design Name: Watermark Insert                                                                                                          
// Module Name: wm_ins_4                                                                                               
// Target Devices: Xilinx xcvu9p-flgb2104-2-i                                                                                                       
// Tool Versions:  Vivado 2017.4   
//                                                                                                    
// Description:  This module is the basic module for 8*8 DFT with pipeline design.
//               Input_valid is the active signal that start this module, and vice
//               versa, the module will stop after the datas inputed before                                                                                                         
//               Input_valid turn to 0 are calculated and output from the ports.At 
//               the same time, output_valid will turn to 0.                                                                                                       
// Dependencies:                                                                                                          
//                                                                                                                        
// Revision: 4.0                                                                                                          
// Additional Comments: new function is added which expand the accuracy of 
//                      image_input from 8 bits to 8 + 10 bits.Also, inserts to rad                                                                                                    
//                      have been removed, and the mode select has been improved.                                                                                                 
//////////////////////////////////////////////////////////////////////////////////                                        
                                                                                                                          
                                                                                                                          
module wmins_4(                                                                                                               
                                                                                                     
input wire clk,                                                                                                           
input wire rst,      
                                                                                                     
input wire signed [18:1] image_1,//1+8+10  {signal,0-255}                                                                                                  
input wire signed [18:1] image_2,                                                                                                    
input wire signed [18:1] image_3,                                                                                                    
input wire signed [18:1] image_4,                                                                                                    
input wire signed [18:1] image_5,                                                                                                    
input wire signed [18:1] image_6,                                                                                                    
input wire signed [18:1] image_7,                                                                                                    
input wire signed [18:1] image_8,

input wire        [4:1]ins_M  ,
          
output reg signed[18:1] image_ins_1, 
output reg signed[18:1] image_ins_2, 
output reg signed[18:1] image_ins_3, 
output reg signed[18:1] image_ins_4, 
output reg signed[18:1] image_ins_5, 
output reg signed[18:1] image_ins_6, 
output reg signed[18:1] image_ins_7, 
output reg signed[18:1] image_ins_8, 

input wire ins_mode,//ins_mode == 1 means inserts one bit data in (1,1), == 0 means inserts 4 bits data in (2,3)(3,2)(8,3)(7,2)
input wire input_valid,  
output wire output_valid                                                                                                             
    );  
                                                                          
//w matrix                                                                                                            
reg signed [12:1] dft_real_w[64:1];  //1+1+10 {signal,0-1}                                                                                            
reg signed [12:1] dft_imag_w[64:1];                                                                                              
                                                                                       
reg signed [12:1] idft_real_w[64:1];  //1+1+10 {signal,0-1}                                                                                            
reg signed [12:1] idft_imag_w[64:1]; 
                                                                                        
//input pic matrix, real only                                                                                         
reg signed [19:1] image_data     [64:1]; //1+8+10  {signal,0-255}                                                                                              
reg signed [19:1] image_data_temp[64:1]; //1+8+10  {signal,0-255}                                                                                                                        
                                                                                                                      
//row dft                                                                                                             
reg signed [35:1] dft_imag_row[64:1]; //1+(8+3)+20                                                                                     
reg signed [35:1] dft_real_row[64:1]; 

reg signed [35:1] dft_imag_row_temp[64:1];                                                                                        
reg signed [35:1] dft_real_row_temp[64:1]; 

//clo dft                                                                                                 
reg signed [50:1] dft_imag_clo[64:1]; //1+(8+3+3)+30                                                                               
reg signed [50:1] dft_real_clo[64:1]; 

reg signed [50:1] dft_imag_clo_temp[64:1]; 
reg signed [50:1] dft_real_clo_temp[64:1]; 

//dft_clo buffer
reg signed [50:1] dft_imag_clo_buf1[64:1];                                                                                
reg signed [50:1] dft_real_clo_buf1[64:1]; 
            
reg signed [50:1] dft_imag_clo_buf2[64:1];                                                                                
reg signed [50:1] dft_real_clo_buf2[64:1];
            
reg signed [50:1] dft_imag_clo_buf3[64:1];                                                                                
reg signed [50:1] dft_real_clo_buf3[64:1];

reg [1:0] dft_buf_sig;
reg       rad_buf_sig;

reg [24:1]rad_1_buf1;
reg [24:1]rad_1_buf2;
reg [24:1]rad_11_buf1;
reg [24:1]rad_11_buf2;
reg [24:1]rad_18_buf1;
reg [24:1]rad_18_buf2;
reg [24:1]rad_50_buf1;
reg [24:1]rad_50_buf2;
reg [24:1]rad_59_buf1;
reg [24:1]rad_59_buf2;

reg [7:1] i;
                                                                                       
//row dft                                                                                                             
reg signed [60:1] idft_imag_row[64:1];                                                                                     
reg signed [60:1] idft_real_row[64:1];  

reg signed [60:1] idft_imag_row_temp[64:1];                                                                                     
reg signed [60:1] idft_real_row_temp[64:1];                                                                                       

//clo dft ,for ouput                                                                                                  
reg signed [40:1] idft_real_clo[64:1]; 
  
reg signed [40:1] idft_real_clo_temp [64:1];   
//state
                                                                                                                     
reg [2:0]  cur_state;   
reg [10:1] loop_cnt;

reg [4:1] cnt_ovalid;
                                                                                                
reg  [7:0] cnt_1_step;                                                                                                                               
wire [7:0] num_1_step_row [8:1] ;   
wire [7:0] num_1_step_clo [7:1] ;                                                                                        
     
wire signed [16:1] cos_temp1; 
wire signed [16:1] sin_temp1;     

//QIM
//M = |f(x,y)|    
reg signed [40:1] M_ins_1   ;
reg signed [40:1] M_ins_11  ;
reg signed [40:1] M_ins_18  ;
reg signed [40:1] M_ins_50  ;
reg signed [40:1] M_ins_59  ;  
 
reg signed [40:1] M_ins_1_temp    ;
reg signed [40:1] M_ins_11_temp   ;
reg signed [40:1] M_ins_18_temp   ;
reg signed [40:1] M_ins_50_temp   ;
reg signed [40:1] M_ins_59_temp   ;  
 
wire signed [24:1] sin_temp;
wire signed [24:1] cos_temp;

reg signed[24:1] rad_1  ; 
reg signed[24:1] rad_11 ;    
reg signed[24:1] rad_18 ;    
reg signed[24:1] rad_50 ;    
reg signed[24:1] rad_59 ;    

reg signed[45:1] M_1   ;                             
reg signed[45:1] M_11  ;    
reg signed[45:1] M_18  ;    
reg signed[45:1] M_50  ;    
reg signed[45:1] M_59  ;  

reg signed[24:1] rad_1_temp ;
reg signed[24:1] rad_11_temp;    
reg signed[24:1] rad_18_temp;    
reg signed[24:1] rad_50_temp;    
reg signed[24:1] rad_59_temp;    

reg signed[45:1] M_1_temp   ;                            
reg signed[45:1] M_11_temp  ;    
reg signed[45:1] M_18_temp  ;    
reg signed[45:1] M_50_temp  ;    
reg signed[45:1] M_59_temp  ;    

wire [24:1] dout_rad  ;                                         
reg  [80:1] tdata     ;           
reg  [24:1]  rad_1_2_5 ;

reg signed [40:1] mod_Mstep       [4:1];   
reg signed [40:1] mod_Mstep_s     [4:1]; 
reg signed [2:1] ins_M_t          [4:1];
                                
//量化调制步长  
parameter signed M_step = 14417920;  // M_step = 55  * 64
parameter signed rad_step = 110 ;   // 1.7  = 110 / 64


parameter signed p = 36'd8589934592;   //8 * 2 ^ 30                                                                                            
//parameter signed q = 1073741824 ;   //2 ^ 30
parameter signed q = 25'd8196 ; //8*1024*4   
//密钥
reg [6:1] img_ins_key[64:1];
         
//state                                                                            
parameter idle        = 3'b000;                                                                                       
parameter ins_1_step  = 3'b001;                                                                                       
                                                                                                                   
//assign num[] = cnt +  ; 
assign num_1_step_row[1] = cnt_1_step * 8 - 7 ; 
assign num_1_step_row[2] = cnt_1_step * 8 - 6 ; 
assign num_1_step_row[3] = cnt_1_step * 8 - 5 ; 
assign num_1_step_row[4] = cnt_1_step * 8 - 4 ; 
assign num_1_step_row[5] = cnt_1_step * 8 - 3 ; 
assign num_1_step_row[6] = cnt_1_step * 8 - 2 ; 
assign num_1_step_row[7] = cnt_1_step * 8 - 1 ; 
assign num_1_step_row[8] = cnt_1_step * 8     ;       
                                                                             
assign num_1_step_clo[1] = cnt_1_step + 8  ;                                                                                 
assign num_1_step_clo[2] = cnt_1_step + 16 ;                                                                                 
assign num_1_step_clo[3] = cnt_1_step + 24 ;                                                                                 
assign num_1_step_clo[4] = cnt_1_step + 32 ;                                                                                 
assign num_1_step_clo[5] = cnt_1_step + 40 ;                                                                                 
assign num_1_step_clo[6] = cnt_1_step + 48 ;                                                                                 
assign num_1_step_clo[7] = cnt_1_step + 56 ;   
                                                                                                                                                                           
assign output_valid = cnt_ovalid < 9 && cur_state != idle  ? 1 : 0;                                                                     
                                                                                                                                                                                                                                  
//input module                                                                                                        
always @(posedge clk) begin                                                                            
  if(rst == 1) begin
     cnt_1_step  <= 1   ;                                                                                                    
     cur_state   <= idle;      
     tdata       <= 0   ;
     dft_buf_sig <= 0   ;
     rad_buf_sig <= 0   ;
     cnt_ovalid  <= 0   ;
     loop_cnt    <= 0   ;
     rad_1_2_5   <= 0   ;
     rad_1  <= 0;
     rad_11 <= 0;
     rad_18 <= 0;
     rad_50 <= 0;
     rad_59 <= 0;
     M_1    <= 0;
     M_11   <= 0;
     M_18   <= 0;
     M_50   <= 0;
     M_59   <= 0;
     
     for(i = 1; i <= 64; i = i +1) begin
       img_ins_key[i]  <= 0;
       dft_real_clo[i] <= 0;
       dft_imag_clo[i] <= 0;
       dft_real_row[i] <= 0;
       dft_imag_row[i] <= 0;
       image_data[i]   <= 0;
     end
     
     idft_imag_w[1]  =12'b000000000000;
     idft_imag_w[2]  =12'b000000000000;
     idft_imag_w[3]  =12'b000000000000;
     idft_imag_w[4]  =12'b000000000000;
     idft_imag_w[5]  =12'b000000000000;
     idft_imag_w[6]  =12'b000000000000;
     idft_imag_w[7]  =12'b000000000000;
     idft_imag_w[8]  =12'b000000000000;
     idft_imag_w[9]  =12'b000000000000;
     idft_imag_w[10] =12'b001011010100;
     idft_imag_w[11] =12'b010000000000;
     idft_imag_w[12] =12'b001011010100;
     idft_imag_w[13] =12'b000000000000;
     idft_imag_w[14] =12'b110100101100;
     idft_imag_w[15] =12'b110000000000;
     idft_imag_w[16] =12'b110100101100;
     idft_imag_w[17] =12'b000000000000;
     idft_imag_w[18] =12'b010000000000;
     idft_imag_w[19] =12'b000000000000;
     idft_imag_w[20] =12'b110000000000;
     idft_imag_w[21] =12'b000000000000;
     idft_imag_w[22] =12'b010000000000;
     idft_imag_w[23] =12'b000000000000;
     idft_imag_w[24] =12'b110000000000;
     idft_imag_w[25] =12'b000000000000;
     idft_imag_w[26] =12'b001011010100;
     idft_imag_w[27] =12'b110000000000;
     idft_imag_w[28] =12'b001011010100;
     idft_imag_w[29] =12'b000000000000;
     idft_imag_w[30] =12'b110100101100;
     idft_imag_w[31] =12'b010000000000;
     idft_imag_w[32] =12'b110100101100;
     idft_imag_w[33] =12'b000000000000;
     idft_imag_w[34] =12'b000000000000;
     idft_imag_w[35] =12'b000000000000;
     idft_imag_w[36] =12'b000000000000;
     idft_imag_w[37] =12'b000000000000;
     idft_imag_w[38] =12'b000000000000;
     idft_imag_w[39] =12'b000000000000;
     idft_imag_w[40] =12'b000000000000;
     idft_imag_w[41] =12'b000000000000;
     idft_imag_w[42] =12'b110100101100;
     idft_imag_w[43] =12'b010000000000;
     idft_imag_w[44] =12'b110100101100;
     idft_imag_w[45] =12'b000000000000;
     idft_imag_w[46] =12'b001011010100;
     idft_imag_w[47] =12'b110000000000;
     idft_imag_w[48] =12'b001011010100;
     idft_imag_w[49] =12'b000000000000;
     idft_imag_w[50] =12'b110000000000;
     idft_imag_w[51] =12'b000000000000;
     idft_imag_w[52] =12'b010000000000;
     idft_imag_w[53] =12'b000000000000;
     idft_imag_w[54] =12'b110000000000;
     idft_imag_w[55] =12'b000000000000;
     idft_imag_w[56] =12'b010000000000;
     idft_imag_w[57] =12'b000000000000;
     idft_imag_w[58] =12'b110100101100;
     idft_imag_w[59] =12'b110000000000;
     idft_imag_w[60] =12'b110100101100;
     idft_imag_w[61] =12'b000000000000;
     idft_imag_w[62] =12'b001011010100;
     idft_imag_w[63] =12'b010000000000;
     idft_imag_w[64] =12'b001011010100;
     
     idft_real_w[1]  =12'b010000000000;
     idft_real_w[2]  =12'b010000000000;
     idft_real_w[3]  =12'b010000000000;
     idft_real_w[4]  =12'b010000000000;
     idft_real_w[5]  =12'b010000000000;
     idft_real_w[6]  =12'b010000000000;
     idft_real_w[7]  =12'b010000000000;
     idft_real_w[8]  =12'b010000000000;
     idft_real_w[9]  =12'b010000000000;
     idft_real_w[10] =12'b001011010100;
     idft_real_w[11] =12'b000000000000;
     idft_real_w[12] =12'b110100101100;
     idft_real_w[13] =12'b110000000000;
     idft_real_w[14] =12'b110100101100;
     idft_real_w[15] =12'b000000000000;
     idft_real_w[16] =12'b001011010100;
     idft_real_w[17] =12'b010000000000;
     idft_real_w[18] =12'b000000000000;
     idft_real_w[19] =12'b110000000000;
     idft_real_w[20] =12'b000000000000;
     idft_real_w[21] =12'b010000000000;
     idft_real_w[22] =12'b000000000000;
     idft_real_w[23] =12'b110000000000;
     idft_real_w[24] =12'b000000000000;
     idft_real_w[25] =12'b010000000000;
     idft_real_w[26] =12'b110100101100;
     idft_real_w[27] =12'b000000000000;
     idft_real_w[28] =12'b001011010100;
     idft_real_w[29] =12'b110000000000;
     idft_real_w[30] =12'b001011010100;
     idft_real_w[31] =12'b000000000000;
     idft_real_w[32] =12'b110100101100;
     idft_real_w[33] =12'b010000000000;
     idft_real_w[34] =12'b110000000000;
     idft_real_w[35] =12'b010000000000;
     idft_real_w[36] =12'b110000000000;
     idft_real_w[37] =12'b010000000000;
     idft_real_w[38] =12'b110000000000;
     idft_real_w[39] =12'b010000000000;
     idft_real_w[40] =12'b110000000000;
     idft_real_w[41] =12'b010000000000;
     idft_real_w[42] =12'b110100101100;
     idft_real_w[43] =12'b000000000000;
     idft_real_w[44] =12'b001011010100;
     idft_real_w[45] =12'b110000000000;
     idft_real_w[46] =12'b001011010100;
     idft_real_w[47] =12'b000000000000;
     idft_real_w[48] =12'b110100101100;
     idft_real_w[49] =12'b010000000000;
     idft_real_w[50] =12'b000000000000;
     idft_real_w[51] =12'b110000000000;
     idft_real_w[52] =12'b000000000000;
     idft_real_w[53] =12'b010000000000;
     idft_real_w[54] =12'b000000000000;
     idft_real_w[55] =12'b110000000000;
     idft_real_w[56] =12'b000000000000;
     idft_real_w[57] =12'b010000000000;
     idft_real_w[58] =12'b001011010100;
     idft_real_w[59] =12'b000000000000;
     idft_real_w[60] =12'b110100101100;
     idft_real_w[61] =12'b110000000000;
     idft_real_w[62] =12'b110100101100;
     idft_real_w[63] =12'b000000000000;
     idft_real_w[64] =12'b001011010100;
                                                                                                      
     dft_imag_w[1]  <=12'b000000000000;
     dft_imag_w[2]  <=12'b000000000000;
     dft_imag_w[3]  <=12'b000000000000;
     dft_imag_w[4]  <=12'b000000000000;
     dft_imag_w[5]  <=12'b000000000000;
     dft_imag_w[6]  <=12'b000000000000;
     dft_imag_w[7]  <=12'b000000000000;
     dft_imag_w[8]  <=12'b000000000000;
     dft_imag_w[9]  <=12'b000000000000;
     dft_imag_w[10] <=12'b110100101100;
     dft_imag_w[11] <=12'b110000000000;
     dft_imag_w[12] <=12'b110100101100;
     dft_imag_w[13] <=12'b000000000000;
     dft_imag_w[14] <=12'b001011010100;
     dft_imag_w[15] <=12'b010000000000;
     dft_imag_w[16] <=12'b001011010100;
     dft_imag_w[17] <=12'b000000000000;
     dft_imag_w[18] <=12'b110000000000;
     dft_imag_w[19] <=12'b000000000000;
     dft_imag_w[20] <=12'b010000000000;
     dft_imag_w[21] <=12'b000000000000;
     dft_imag_w[22] <=12'b110000000000;
     dft_imag_w[23] <=12'b000000000000;
     dft_imag_w[24] <=12'b010000000000;
     dft_imag_w[25] <=12'b000000000000;
     dft_imag_w[26] <=12'b110100101100;
     dft_imag_w[27] <=12'b010000000000;
     dft_imag_w[28] <=12'b110100101100;
     dft_imag_w[29] <=12'b000000000000;
     dft_imag_w[30] <=12'b001011010100;
     dft_imag_w[31] <=12'b110000000000;
     dft_imag_w[32] <=12'b001011010100;
     dft_imag_w[33] <=12'b000000000000;
     dft_imag_w[34] <=12'b000000000000;
     dft_imag_w[35] <=12'b000000000000;
     dft_imag_w[36] <=12'b000000000000;
     dft_imag_w[37] <=12'b000000000000;
     dft_imag_w[38] <=12'b000000000000;
     dft_imag_w[39] <=12'b000000000000;
     dft_imag_w[40] <=12'b000000000000;
     dft_imag_w[41] <=12'b000000000000;
     dft_imag_w[42] <=12'b001011010100;
     dft_imag_w[43] <=12'b110000000000;
     dft_imag_w[44] <=12'b001011010100;
     dft_imag_w[45] <=12'b000000000000;
     dft_imag_w[46] <=12'b110100101100;
     dft_imag_w[47] <=12'b010000000000;
     dft_imag_w[48] <=12'b110100101100;
     dft_imag_w[49] <=12'b000000000000;
     dft_imag_w[50] <=12'b010000000000;
     dft_imag_w[51] <=12'b000000000000;
     dft_imag_w[52] <=12'b110000000000;
     dft_imag_w[53] <=12'b000000000000;
     dft_imag_w[54] <=12'b010000000000;
     dft_imag_w[55] <=12'b000000000000;
     dft_imag_w[56] <=12'b110000000000;
     dft_imag_w[57] <=12'b000000000000;
     dft_imag_w[58] <=12'b001011010100;
     dft_imag_w[59] <=12'b010000000000;
     dft_imag_w[60] <=12'b001011010100;
     dft_imag_w[61] <=12'b000000000000;
     dft_imag_w[62] <=12'b110100101100;
     dft_imag_w[63] <=12'b110000000000;
     dft_imag_w[64] <=12'b110100101100;  
     
     dft_real_w[1]  <=12'b010000000000;
     dft_real_w[2]  <=12'b010000000000;
     dft_real_w[3]  <=12'b010000000000;
     dft_real_w[4]  <=12'b010000000000;
     dft_real_w[5]  <=12'b010000000000;
     dft_real_w[6]  <=12'b010000000000;
     dft_real_w[7]  <=12'b010000000000;
     dft_real_w[8]  <=12'b010000000000;
     dft_real_w[9]  <=12'b010000000000;
     dft_real_w[10] <=12'b001011010100;
     dft_real_w[11] <=12'b000000000000;
     dft_real_w[12] <=12'b110100101100;
     dft_real_w[13] <=12'b110000000000;
     dft_real_w[14] <=12'b110100101100;
     dft_real_w[15] <=12'b000000000000;
     dft_real_w[16] <=12'b001011010100;
     dft_real_w[17] <=12'b010000000000;
     dft_real_w[18] <=12'b000000000000;
     dft_real_w[19] <=12'b110000000000;
     dft_real_w[20] <=12'b000000000000;
     dft_real_w[21] <=12'b010000000000;
     dft_real_w[22] <=12'b000000000000;
     dft_real_w[23] <=12'b110000000000;
     dft_real_w[24] <=12'b000000000000;
     dft_real_w[25] <=12'b010000000000;
     dft_real_w[26] <=12'b110100101100;
     dft_real_w[27] <=12'b000000000000;
     dft_real_w[28] <=12'b001011010100;
     dft_real_w[29] <=12'b110000000000;
     dft_real_w[30] <=12'b001011010100;
     dft_real_w[31] <=12'b000000000000;
     dft_real_w[32] <=12'b110100101100;
     dft_real_w[33] <=12'b010000000000;
     dft_real_w[34] <=12'b110000000000;
     dft_real_w[35] <=12'b010000000000;
     dft_real_w[36] <=12'b110000000000;
     dft_real_w[37] <=12'b010000000000;
     dft_real_w[38] <=12'b110000000000;
     dft_real_w[39] <=12'b010000000000;
     dft_real_w[40] <=12'b110000000000;
     dft_real_w[41] <=12'b010000000000;
     dft_real_w[42] <=12'b110100101100;
     dft_real_w[43] <=12'b000000000000;
     dft_real_w[44] <=12'b001011010100;
     dft_real_w[45] <=12'b110000000000;
     dft_real_w[46] <=12'b001011010100;
     dft_real_w[47] <=12'b000000000000;
     dft_real_w[48] <=12'b110100101100;
     dft_real_w[49] <=12'b010000000000;
     dft_real_w[50] <=12'b000000000000;
     dft_real_w[51] <=12'b110000000000;
     dft_real_w[52] <=12'b000000000000;
     dft_real_w[53] <=12'b010000000000;
     dft_real_w[54] <=12'b000000000000;
     dft_real_w[55] <=12'b110000000000;
     dft_real_w[56] <=12'b000000000000;
     dft_real_w[57] <=12'b010000000000;
     dft_real_w[58] <=12'b001011010100;
     dft_real_w[59] <=12'b000000000000;
     dft_real_w[60] <=12'b110100101100;
     dft_real_w[61] <=12'b110000000000;
     dft_real_w[62] <=12'b110100101100;
     dft_real_w[63] <=12'b000000000000;
     dft_real_w[64] <=12'b001011010100;
  end
  else begin
    case(cur_state)
  	
      idle : begin
        if(input_valid == 1)
        
          cur_state <= ins_1_step;
   
      end
  
      ins_1_step : begin  
      	                     
      	if(cnt_1_step <= 8) begin            
      	                     
          //data input   1
          image_data_temp[ num_1_step_row[1]]   <= {1'b0,image_1};                                                                            
          image_data_temp[ num_1_step_row[2]]   <= {1'b0,image_2};                                                                            
          image_data_temp[ num_1_step_row[3]]   <= {1'b0,image_3};                                                                            
          image_data_temp[ num_1_step_row[4]]   <= {1'b0,image_4};                                                                            
          image_data_temp[ num_1_step_row[5]]   <= {1'b0,image_5};                                                                            
          image_data_temp[ num_1_step_row[6]]   <= {1'b0,image_6};                                                                            
          image_data_temp[ num_1_step_row[7]]   <= {1'b0,image_7};                                                                            
          image_data_temp[ num_1_step_row[8]]   <= {1'b0,image_8};            
          
          //dft_row  2
          dft_real_row_temp[num_1_step_row[1]]  <=  image_data[num_1_step_row[1]]* dft_real_w[1 ]+ image_data[num_1_step_row[2]]* dft_real_w[2 ]+ image_data[num_1_step_row[3]]* dft_real_w[3 ]+ image_data[num_1_step_row[4]]* dft_real_w[4 ]+ image_data[num_1_step_row[5]]* dft_real_w[5 ]+ image_data[num_1_step_row[6]]* dft_real_w[6 ]+ image_data[num_1_step_row[7]]* dft_real_w[7 ]+ image_data[num_1_step_row[8]]* dft_real_w[8 ];                                      
          dft_real_row_temp[num_1_step_row[2]]  <=  image_data[num_1_step_row[1]]* dft_real_w[9 ]+ image_data[num_1_step_row[2]]* dft_real_w[10]+ image_data[num_1_step_row[3]]* dft_real_w[11]+ image_data[num_1_step_row[4]]* dft_real_w[12]+ image_data[num_1_step_row[5]]* dft_real_w[13]+ image_data[num_1_step_row[6]]* dft_real_w[14]+ image_data[num_1_step_row[7]]* dft_real_w[15]+ image_data[num_1_step_row[8]]* dft_real_w[16];                                      
          dft_real_row_temp[num_1_step_row[3]]  <=  image_data[num_1_step_row[1]]* dft_real_w[17]+ image_data[num_1_step_row[2]]* dft_real_w[18]+ image_data[num_1_step_row[3]]* dft_real_w[19]+ image_data[num_1_step_row[4]]* dft_real_w[20]+ image_data[num_1_step_row[5]]* dft_real_w[21]+ image_data[num_1_step_row[6]]* dft_real_w[22]+ image_data[num_1_step_row[7]]* dft_real_w[23]+ image_data[num_1_step_row[8]]* dft_real_w[24];                                      
          dft_real_row_temp[num_1_step_row[4]]  <=  image_data[num_1_step_row[1]]* dft_real_w[25]+ image_data[num_1_step_row[2]]* dft_real_w[26]+ image_data[num_1_step_row[3]]* dft_real_w[27]+ image_data[num_1_step_row[4]]* dft_real_w[28]+ image_data[num_1_step_row[5]]* dft_real_w[29]+ image_data[num_1_step_row[6]]* dft_real_w[30]+ image_data[num_1_step_row[7]]* dft_real_w[31]+ image_data[num_1_step_row[8]]* dft_real_w[32];                                      
          dft_real_row_temp[num_1_step_row[5]]  <=  image_data[num_1_step_row[1]]* dft_real_w[33]+ image_data[num_1_step_row[2]]* dft_real_w[34]+ image_data[num_1_step_row[3]]* dft_real_w[35]+ image_data[num_1_step_row[4]]* dft_real_w[36]+ image_data[num_1_step_row[5]]* dft_real_w[37]+ image_data[num_1_step_row[6]]* dft_real_w[38]+ image_data[num_1_step_row[7]]* dft_real_w[39]+ image_data[num_1_step_row[8]]* dft_real_w[40];                                      
          dft_real_row_temp[num_1_step_row[6]]  <=  image_data[num_1_step_row[1]]* dft_real_w[41]+ image_data[num_1_step_row[2]]* dft_real_w[42]+ image_data[num_1_step_row[3]]* dft_real_w[43]+ image_data[num_1_step_row[4]]* dft_real_w[44]+ image_data[num_1_step_row[5]]* dft_real_w[45]+ image_data[num_1_step_row[6]]* dft_real_w[46]+ image_data[num_1_step_row[7]]* dft_real_w[47]+ image_data[num_1_step_row[8]]* dft_real_w[48];                                      
          dft_real_row_temp[num_1_step_row[7]]  <=  image_data[num_1_step_row[1]]* dft_real_w[49]+ image_data[num_1_step_row[2]]* dft_real_w[50]+ image_data[num_1_step_row[3]]* dft_real_w[51]+ image_data[num_1_step_row[4]]* dft_real_w[52]+ image_data[num_1_step_row[5]]* dft_real_w[53]+ image_data[num_1_step_row[6]]* dft_real_w[54]+ image_data[num_1_step_row[7]]* dft_real_w[55]+ image_data[num_1_step_row[8]]* dft_real_w[56];                                      
          dft_real_row_temp[num_1_step_row[8]]  <=  image_data[num_1_step_row[1]]* dft_real_w[57]+ image_data[num_1_step_row[2]]* dft_real_w[58]+ image_data[num_1_step_row[3]]* dft_real_w[59]+ image_data[num_1_step_row[4]]* dft_real_w[60]+ image_data[num_1_step_row[5]]* dft_real_w[61]+ image_data[num_1_step_row[6]]* dft_real_w[62]+ image_data[num_1_step_row[7]]* dft_real_w[63]+ image_data[num_1_step_row[8]]* dft_real_w[64];    
                
          dft_imag_row_temp[num_1_step_row[1]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[1] + image_data[num_1_step_row[2]]* dft_imag_w[2] + image_data[num_1_step_row[3]]* dft_imag_w[3] + image_data[num_1_step_row[4]]* dft_imag_w[4 ]+ image_data[num_1_step_row[5]] * dft_imag_w[5]+ image_data[num_1_step_row[6]]* dft_imag_w[6] + image_data[num_1_step_row[7]]* dft_imag_w[7] + image_data[num_1_step_row[8]]* dft_imag_w[8 ];                         
          dft_imag_row_temp[num_1_step_row[2]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[9] + image_data[num_1_step_row[2]]* dft_imag_w[10]+ image_data[num_1_step_row[3]]* dft_imag_w[11]+ image_data[num_1_step_row[4]]* dft_imag_w[12]+ image_data[num_1_step_row[5]]* dft_imag_w[13]+ image_data[num_1_step_row[6]]* dft_imag_w[14]+ image_data[num_1_step_row[7]]* dft_imag_w[15]+ image_data[num_1_step_row[8]]* dft_imag_w[16];                         
          dft_imag_row_temp[num_1_step_row[3]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[17]+ image_data[num_1_step_row[2]]* dft_imag_w[18]+ image_data[num_1_step_row[3]]* dft_imag_w[19]+ image_data[num_1_step_row[4]]* dft_imag_w[20]+ image_data[num_1_step_row[5]]* dft_imag_w[21]+ image_data[num_1_step_row[6]]* dft_imag_w[22]+ image_data[num_1_step_row[7]]* dft_imag_w[23]+ image_data[num_1_step_row[8]]* dft_imag_w[24];                         
          dft_imag_row_temp[num_1_step_row[4]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[25]+ image_data[num_1_step_row[2]]* dft_imag_w[26]+ image_data[num_1_step_row[3]]* dft_imag_w[27]+ image_data[num_1_step_row[4]]* dft_imag_w[28]+ image_data[num_1_step_row[5]]* dft_imag_w[29]+ image_data[num_1_step_row[6]]* dft_imag_w[30]+ image_data[num_1_step_row[7]]* dft_imag_w[31]+ image_data[num_1_step_row[8]]* dft_imag_w[32];                         
          dft_imag_row_temp[num_1_step_row[5]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[33]+ image_data[num_1_step_row[2]]* dft_imag_w[34]+ image_data[num_1_step_row[3]]* dft_imag_w[35]+ image_data[num_1_step_row[4]]* dft_imag_w[36]+ image_data[num_1_step_row[5]]* dft_imag_w[37]+ image_data[num_1_step_row[6]]* dft_imag_w[38]+ image_data[num_1_step_row[7]]* dft_imag_w[39]+ image_data[num_1_step_row[8]]* dft_imag_w[40];                         
          dft_imag_row_temp[num_1_step_row[6]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[41]+ image_data[num_1_step_row[2]]* dft_imag_w[42]+ image_data[num_1_step_row[3]]* dft_imag_w[43]+ image_data[num_1_step_row[4]]* dft_imag_w[44]+ image_data[num_1_step_row[5]]* dft_imag_w[45]+ image_data[num_1_step_row[6]]* dft_imag_w[46]+ image_data[num_1_step_row[7]]* dft_imag_w[47]+ image_data[num_1_step_row[8]]* dft_imag_w[48];                         
          dft_imag_row_temp[num_1_step_row[7]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[49]+ image_data[num_1_step_row[2]]* dft_imag_w[50]+ image_data[num_1_step_row[3]]* dft_imag_w[51]+ image_data[num_1_step_row[4]]* dft_imag_w[52]+ image_data[num_1_step_row[5]]* dft_imag_w[53]+ image_data[num_1_step_row[6]]* dft_imag_w[54]+ image_data[num_1_step_row[7]]* dft_imag_w[55]+ image_data[num_1_step_row[8]]* dft_imag_w[56];                         
          dft_imag_row_temp[num_1_step_row[8]]  <=  image_data[num_1_step_row[1]]* dft_imag_w[57]+ image_data[num_1_step_row[2]]* dft_imag_w[58]+ image_data[num_1_step_row[3]]* dft_imag_w[59]+ image_data[num_1_step_row[4]]* dft_imag_w[60]+ image_data[num_1_step_row[5]]* dft_imag_w[61]+ image_data[num_1_step_row[6]]* dft_imag_w[62]+ image_data[num_1_step_row[7]]* dft_imag_w[63]+ image_data[num_1_step_row[8]]* dft_imag_w[64];                         

          //dft_clo  3
          dft_real_clo_temp[cnt_1_step       ]  <=   dft_real_row[cnt_1_step]* dft_real_w[1] + dft_real_row[num_1_step_clo[1]]* dft_real_w[2] + dft_real_row[num_1_step_clo[2]]* dft_real_w[3] + dft_real_row[num_1_step_clo[3]]* dft_real_w[4] + dft_real_row[num_1_step_clo[4]]* dft_real_w[5] + dft_real_row[num_1_step_clo[5]]* dft_real_w[6] + dft_real_row[num_1_step_clo[6]]* dft_real_w[7] + dft_real_row[num_1_step_clo[7]]* dft_real_w[8] -(dft_imag_row[cnt_1_step]* dft_imag_w[1] + dft_imag_row[num_1_step_clo[1]]* dft_imag_w[2] + dft_imag_row[num_1_step_clo[2]]* dft_imag_w[3] + dft_imag_row[num_1_step_clo[3]]* dft_imag_w[4] + dft_imag_row[num_1_step_clo[4]]* dft_imag_w[5] + dft_imag_row[num_1_step_clo[5]]* dft_imag_w[6] + dft_imag_row[num_1_step_clo[6]]* dft_imag_w[7] + dft_imag_row[num_1_step_clo[7]]* dft_imag_w[8] );
          dft_real_clo_temp[num_1_step_clo[1]]  <=   dft_real_row[cnt_1_step]* dft_real_w[9] + dft_real_row[num_1_step_clo[1]]* dft_real_w[10]+ dft_real_row[num_1_step_clo[2]]* dft_real_w[11]+ dft_real_row[num_1_step_clo[3]]* dft_real_w[12]+ dft_real_row[num_1_step_clo[4]]* dft_real_w[13]+ dft_real_row[num_1_step_clo[5]]* dft_real_w[14]+ dft_real_row[num_1_step_clo[6]]* dft_real_w[15]+ dft_real_row[num_1_step_clo[7]]* dft_real_w[16]-(dft_imag_row[cnt_1_step]* dft_imag_w[9] + dft_imag_row[num_1_step_clo[1]]* dft_imag_w[10]+ dft_imag_row[num_1_step_clo[2]]* dft_imag_w[11]+ dft_imag_row[num_1_step_clo[3]]* dft_imag_w[12]+ dft_imag_row[num_1_step_clo[4]]* dft_imag_w[13]+ dft_imag_row[num_1_step_clo[5]]* dft_imag_w[14]+ dft_imag_row[num_1_step_clo[6]]* dft_imag_w[15]+ dft_imag_row[num_1_step_clo[7]]* dft_imag_w[16]);
          dft_real_clo_temp[num_1_step_clo[2]]  <=   dft_real_row[cnt_1_step]* dft_real_w[17]+ dft_real_row[num_1_step_clo[1]]* dft_real_w[18]+ dft_real_row[num_1_step_clo[2]]* dft_real_w[19]+ dft_real_row[num_1_step_clo[3]]* dft_real_w[20]+ dft_real_row[num_1_step_clo[4]]* dft_real_w[21]+ dft_real_row[num_1_step_clo[5]]* dft_real_w[22]+ dft_real_row[num_1_step_clo[6]]* dft_real_w[23]+ dft_real_row[num_1_step_clo[7]]* dft_real_w[24]-(dft_imag_row[cnt_1_step]* dft_imag_w[17]+ dft_imag_row[num_1_step_clo[1]]* dft_imag_w[18]+ dft_imag_row[num_1_step_clo[2]]* dft_imag_w[19]+ dft_imag_row[num_1_step_clo[3]]* dft_imag_w[20]+ dft_imag_row[num_1_step_clo[4]]* dft_imag_w[21]+ dft_imag_row[num_1_step_clo[5]]* dft_imag_w[22]+ dft_imag_row[num_1_step_clo[6]]* dft_imag_w[23]+ dft_imag_row[num_1_step_clo[7]]* dft_imag_w[24]);
          dft_real_clo_temp[num_1_step_clo[3]]  <=   dft_real_row[cnt_1_step]* dft_real_w[25]+ dft_real_row[num_1_step_clo[1]]* dft_real_w[26]+ dft_real_row[num_1_step_clo[2]]* dft_real_w[27]+ dft_real_row[num_1_step_clo[3]]* dft_real_w[28]+ dft_real_row[num_1_step_clo[4]]* dft_real_w[29]+ dft_real_row[num_1_step_clo[5]]* dft_real_w[30]+ dft_real_row[num_1_step_clo[6]]* dft_real_w[31]+ dft_real_row[num_1_step_clo[7]]* dft_real_w[32]-(dft_imag_row[cnt_1_step]* dft_imag_w[25]+ dft_imag_row[num_1_step_clo[1]]* dft_imag_w[26]+ dft_imag_row[num_1_step_clo[2]]* dft_imag_w[27]+ dft_imag_row[num_1_step_clo[3]]* dft_imag_w[28]+ dft_imag_row[num_1_step_clo[4]]* dft_imag_w[29]+ dft_imag_row[num_1_step_clo[5]]* dft_imag_w[30]+ dft_imag_row[num_1_step_clo[6]]* dft_imag_w[31]+ dft_imag_row[num_1_step_clo[7]]* dft_imag_w[32]);
          dft_real_clo_temp[num_1_step_clo[4]]  <=   dft_real_row[cnt_1_step]* dft_real_w[33]+ dft_real_row[num_1_step_clo[1]]* dft_real_w[34]+ dft_real_row[num_1_step_clo[2]]* dft_real_w[35]+ dft_real_row[num_1_step_clo[3]]* dft_real_w[36]+ dft_real_row[num_1_step_clo[4]]* dft_real_w[37]+ dft_real_row[num_1_step_clo[5]]* dft_real_w[38]+ dft_real_row[num_1_step_clo[6]]* dft_real_w[39]+ dft_real_row[num_1_step_clo[7]]* dft_real_w[40]-(dft_imag_row[cnt_1_step]* dft_imag_w[33]+ dft_imag_row[num_1_step_clo[1]]* dft_imag_w[34]+ dft_imag_row[num_1_step_clo[2]]* dft_imag_w[35]+ dft_imag_row[num_1_step_clo[3]]* dft_imag_w[36]+ dft_imag_row[num_1_step_clo[4]]* dft_imag_w[37]+ dft_imag_row[num_1_step_clo[5]]* dft_imag_w[38]+ dft_imag_row[num_1_step_clo[6]]* dft_imag_w[39]+ dft_imag_row[num_1_step_clo[7]]* dft_imag_w[40]);
          dft_real_clo_temp[num_1_step_clo[5]]  <=   dft_real_row[cnt_1_step]* dft_real_w[41]+ dft_real_row[num_1_step_clo[1]]* dft_real_w[42]+ dft_real_row[num_1_step_clo[2]]* dft_real_w[43]+ dft_real_row[num_1_step_clo[3]]* dft_real_w[44]+ dft_real_row[num_1_step_clo[4]]* dft_real_w[45]+ dft_real_row[num_1_step_clo[5]]* dft_real_w[46]+ dft_real_row[num_1_step_clo[6]]* dft_real_w[47]+ dft_real_row[num_1_step_clo[7]]* dft_real_w[48]-(dft_imag_row[cnt_1_step]* dft_imag_w[41]+ dft_imag_row[num_1_step_clo[1]]* dft_imag_w[42]+ dft_imag_row[num_1_step_clo[2]]* dft_imag_w[43]+ dft_imag_row[num_1_step_clo[3]]* dft_imag_w[44]+ dft_imag_row[num_1_step_clo[4]]* dft_imag_w[45]+ dft_imag_row[num_1_step_clo[5]]* dft_imag_w[46]+ dft_imag_row[num_1_step_clo[6]]* dft_imag_w[47]+ dft_imag_row[num_1_step_clo[7]]* dft_imag_w[48]);
          dft_real_clo_temp[num_1_step_clo[6]]  <=   dft_real_row[cnt_1_step]* dft_real_w[49]+ dft_real_row[num_1_step_clo[1]]* dft_real_w[50]+ dft_real_row[num_1_step_clo[2]]* dft_real_w[51]+ dft_real_row[num_1_step_clo[3]]* dft_real_w[52]+ dft_real_row[num_1_step_clo[4]]* dft_real_w[53]+ dft_real_row[num_1_step_clo[5]]* dft_real_w[54]+ dft_real_row[num_1_step_clo[6]]* dft_real_w[55]+ dft_real_row[num_1_step_clo[7]]* dft_real_w[56]-(dft_imag_row[cnt_1_step]* dft_imag_w[49]+ dft_imag_row[num_1_step_clo[1]]* dft_imag_w[50]+ dft_imag_row[num_1_step_clo[2]]* dft_imag_w[51]+ dft_imag_row[num_1_step_clo[3]]* dft_imag_w[52]+ dft_imag_row[num_1_step_clo[4]]* dft_imag_w[53]+ dft_imag_row[num_1_step_clo[5]]* dft_imag_w[54]+ dft_imag_row[num_1_step_clo[6]]* dft_imag_w[55]+ dft_imag_row[num_1_step_clo[7]]* dft_imag_w[56]);
          dft_real_clo_temp[num_1_step_clo[7]]  <=   dft_real_row[cnt_1_step]* dft_real_w[57]+ dft_real_row[num_1_step_clo[1]]* dft_real_w[58]+ dft_real_row[num_1_step_clo[2]]* dft_real_w[59]+ dft_real_row[num_1_step_clo[3]]* dft_real_w[60]+ dft_real_row[num_1_step_clo[4]]* dft_real_w[61]+ dft_real_row[num_1_step_clo[5]]* dft_real_w[62]+ dft_real_row[num_1_step_clo[6]]* dft_real_w[63]+ dft_real_row[num_1_step_clo[7]]* dft_real_w[64]-(dft_imag_row[cnt_1_step]* dft_imag_w[57]+ dft_imag_row[num_1_step_clo[1]]* dft_imag_w[58]+ dft_imag_row[num_1_step_clo[2]]* dft_imag_w[59]+ dft_imag_row[num_1_step_clo[3]]* dft_imag_w[60]+ dft_imag_row[num_1_step_clo[4]]* dft_imag_w[61]+ dft_imag_row[num_1_step_clo[5]]* dft_imag_w[62]+ dft_imag_row[num_1_step_clo[6]]* dft_imag_w[63]+ dft_imag_row[num_1_step_clo[7]]* dft_imag_w[64]);
                                                                       
          dft_imag_clo_temp[cnt_1_step       ]  <=   dft_imag_row[cnt_1_step]* dft_real_w[1] + dft_imag_row[num_1_step_clo[1]]* dft_real_w[2] + dft_imag_row[num_1_step_clo[2]]* dft_real_w[3] + dft_imag_row[num_1_step_clo[3]]* dft_real_w[4] + dft_imag_row[num_1_step_clo[4]]* dft_real_w[5] + dft_imag_row[num_1_step_clo[5]]* dft_real_w[6] + dft_imag_row[num_1_step_clo[6]]* dft_real_w[7] + dft_imag_row[num_1_step_clo[7]]* dft_real_w[8]  +dft_real_row[cnt_1_step]* dft_imag_w[1] + dft_real_row[num_1_step_clo[1]]* dft_imag_w[2] + dft_real_row[num_1_step_clo[2]]* dft_imag_w[3] + dft_real_row[num_1_step_clo[3]]* dft_imag_w[4] + dft_real_row[num_1_step_clo[4]]* dft_imag_w[5] + dft_real_row[num_1_step_clo[5]]* dft_imag_w[6] + dft_real_row[num_1_step_clo[6]]* dft_imag_w[7] + dft_real_row[num_1_step_clo[7]]* dft_imag_w[8] ;
          dft_imag_clo_temp[num_1_step_clo[1]]  <=   dft_imag_row[cnt_1_step]* dft_real_w[9] + dft_imag_row[num_1_step_clo[1]]* dft_real_w[10]+ dft_imag_row[num_1_step_clo[2]]* dft_real_w[11]+ dft_imag_row[num_1_step_clo[3]]* dft_real_w[12]+ dft_imag_row[num_1_step_clo[4]]* dft_real_w[13]+ dft_imag_row[num_1_step_clo[5]]* dft_real_w[14]+ dft_imag_row[num_1_step_clo[6]]* dft_real_w[15]+ dft_imag_row[num_1_step_clo[7]]* dft_real_w[16] +dft_real_row[cnt_1_step]* dft_imag_w[9] + dft_real_row[num_1_step_clo[1]]* dft_imag_w[10]+ dft_real_row[num_1_step_clo[2]]* dft_imag_w[11]+ dft_real_row[num_1_step_clo[3]]* dft_imag_w[12]+ dft_real_row[num_1_step_clo[4]]* dft_imag_w[13]+ dft_real_row[num_1_step_clo[5]]* dft_imag_w[14]+ dft_real_row[num_1_step_clo[6]]* dft_imag_w[15]+ dft_real_row[num_1_step_clo[7]]* dft_imag_w[16];
          dft_imag_clo_temp[num_1_step_clo[2]]  <=   dft_imag_row[cnt_1_step]* dft_real_w[17]+ dft_imag_row[num_1_step_clo[1]]* dft_real_w[18]+ dft_imag_row[num_1_step_clo[2]]* dft_real_w[19]+ dft_imag_row[num_1_step_clo[3]]* dft_real_w[20]+ dft_imag_row[num_1_step_clo[4]]* dft_real_w[21]+ dft_imag_row[num_1_step_clo[5]]* dft_real_w[22]+ dft_imag_row[num_1_step_clo[6]]* dft_real_w[23]+ dft_imag_row[num_1_step_clo[7]]* dft_real_w[24] +dft_real_row[cnt_1_step]* dft_imag_w[17]+ dft_real_row[num_1_step_clo[1]]* dft_imag_w[18]+ dft_real_row[num_1_step_clo[2]]* dft_imag_w[19]+ dft_real_row[num_1_step_clo[3]]* dft_imag_w[20]+ dft_real_row[num_1_step_clo[4]]* dft_imag_w[21]+ dft_real_row[num_1_step_clo[5]]* dft_imag_w[22]+ dft_real_row[num_1_step_clo[6]]* dft_imag_w[23]+ dft_real_row[num_1_step_clo[7]]* dft_imag_w[24];
          dft_imag_clo_temp[num_1_step_clo[3]]  <=   dft_imag_row[cnt_1_step]* dft_real_w[25]+ dft_imag_row[num_1_step_clo[1]]* dft_real_w[26]+ dft_imag_row[num_1_step_clo[2]]* dft_real_w[27]+ dft_imag_row[num_1_step_clo[3]]* dft_real_w[28]+ dft_imag_row[num_1_step_clo[4]]* dft_real_w[29]+ dft_imag_row[num_1_step_clo[5]]* dft_real_w[30]+ dft_imag_row[num_1_step_clo[6]]* dft_real_w[31]+ dft_imag_row[num_1_step_clo[7]]* dft_real_w[32] +dft_real_row[cnt_1_step]* dft_imag_w[25]+ dft_real_row[num_1_step_clo[1]]* dft_imag_w[26]+ dft_real_row[num_1_step_clo[2]]* dft_imag_w[27]+ dft_real_row[num_1_step_clo[3]]* dft_imag_w[28]+ dft_real_row[num_1_step_clo[4]]* dft_imag_w[29]+ dft_real_row[num_1_step_clo[5]]* dft_imag_w[30]+ dft_real_row[num_1_step_clo[6]]* dft_imag_w[31]+ dft_real_row[num_1_step_clo[7]]* dft_imag_w[32];
          dft_imag_clo_temp[num_1_step_clo[4]]  <=   dft_imag_row[cnt_1_step]* dft_real_w[33]+ dft_imag_row[num_1_step_clo[1]]* dft_real_w[34]+ dft_imag_row[num_1_step_clo[2]]* dft_real_w[35]+ dft_imag_row[num_1_step_clo[3]]* dft_real_w[36]+ dft_imag_row[num_1_step_clo[4]]* dft_real_w[37]+ dft_imag_row[num_1_step_clo[5]]* dft_real_w[38]+ dft_imag_row[num_1_step_clo[6]]* dft_real_w[39]+ dft_imag_row[num_1_step_clo[7]]* dft_real_w[40] +dft_real_row[cnt_1_step]* dft_imag_w[33]+ dft_real_row[num_1_step_clo[1]]* dft_imag_w[34]+ dft_real_row[num_1_step_clo[2]]* dft_imag_w[35]+ dft_real_row[num_1_step_clo[3]]* dft_imag_w[36]+ dft_real_row[num_1_step_clo[4]]* dft_imag_w[37]+ dft_real_row[num_1_step_clo[5]]* dft_imag_w[38]+ dft_real_row[num_1_step_clo[6]]* dft_imag_w[39]+ dft_real_row[num_1_step_clo[7]]* dft_imag_w[40];
          dft_imag_clo_temp[num_1_step_clo[5]]  <=   dft_imag_row[cnt_1_step]* dft_real_w[41]+ dft_imag_row[num_1_step_clo[1]]* dft_real_w[42]+ dft_imag_row[num_1_step_clo[2]]* dft_real_w[43]+ dft_imag_row[num_1_step_clo[3]]* dft_real_w[44]+ dft_imag_row[num_1_step_clo[4]]* dft_real_w[45]+ dft_imag_row[num_1_step_clo[5]]* dft_real_w[46]+ dft_imag_row[num_1_step_clo[6]]* dft_real_w[47]+ dft_imag_row[num_1_step_clo[7]]* dft_real_w[48] +dft_real_row[cnt_1_step]* dft_imag_w[41]+ dft_real_row[num_1_step_clo[1]]* dft_imag_w[42]+ dft_real_row[num_1_step_clo[2]]* dft_imag_w[43]+ dft_real_row[num_1_step_clo[3]]* dft_imag_w[44]+ dft_real_row[num_1_step_clo[4]]* dft_imag_w[45]+ dft_real_row[num_1_step_clo[5]]* dft_imag_w[46]+ dft_real_row[num_1_step_clo[6]]* dft_imag_w[47]+ dft_real_row[num_1_step_clo[7]]* dft_imag_w[48];
          dft_imag_clo_temp[num_1_step_clo[6]]  <=   dft_imag_row[cnt_1_step]* dft_real_w[49]+ dft_imag_row[num_1_step_clo[1]]* dft_real_w[50]+ dft_imag_row[num_1_step_clo[2]]* dft_real_w[51]+ dft_imag_row[num_1_step_clo[3]]* dft_real_w[52]+ dft_imag_row[num_1_step_clo[4]]* dft_real_w[53]+ dft_imag_row[num_1_step_clo[5]]* dft_real_w[54]+ dft_imag_row[num_1_step_clo[6]]* dft_real_w[55]+ dft_imag_row[num_1_step_clo[7]]* dft_real_w[56] +dft_real_row[cnt_1_step]* dft_imag_w[49]+ dft_real_row[num_1_step_clo[1]]* dft_imag_w[50]+ dft_real_row[num_1_step_clo[2]]* dft_imag_w[51]+ dft_real_row[num_1_step_clo[3]]* dft_imag_w[52]+ dft_real_row[num_1_step_clo[4]]* dft_imag_w[53]+ dft_real_row[num_1_step_clo[5]]* dft_imag_w[54]+ dft_real_row[num_1_step_clo[6]]* dft_imag_w[55]+ dft_real_row[num_1_step_clo[7]]* dft_imag_w[56];
          dft_imag_clo_temp[num_1_step_clo[7]]  <=   dft_imag_row[cnt_1_step]* dft_real_w[57]+ dft_imag_row[num_1_step_clo[1]]* dft_real_w[58]+ dft_imag_row[num_1_step_clo[2]]* dft_real_w[59]+ dft_imag_row[num_1_step_clo[3]]* dft_real_w[60]+ dft_imag_row[num_1_step_clo[4]]* dft_real_w[61]+ dft_imag_row[num_1_step_clo[5]]* dft_real_w[62]+ dft_imag_row[num_1_step_clo[6]]* dft_real_w[63]+ dft_imag_row[num_1_step_clo[7]]* dft_real_w[64] +dft_real_row[cnt_1_step]* dft_imag_w[57]+ dft_real_row[num_1_step_clo[1]]* dft_imag_w[58]+ dft_real_row[num_1_step_clo[2]]* dft_imag_w[59]+ dft_real_row[num_1_step_clo[3]]* dft_imag_w[60]+ dft_real_row[num_1_step_clo[4]]* dft_imag_w[61]+ dft_real_row[num_1_step_clo[5]]* dft_imag_w[62]+ dft_real_row[num_1_step_clo[6]]* dft_imag_w[63]+ dft_real_row[num_1_step_clo[7]]* dft_imag_w[64];     
       
           cnt_1_step <= cnt_1_step + 1;  
          
           //idft_row  7
           if(dft_buf_sig == 0) begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
              idft_real_row_temp[num_1_step_row[1]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[1] + dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[2] + dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[3] + dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[4] + dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[5] + dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[6] + dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[7] + dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[8] -(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[1] + dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[2] + dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[3] + dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[4] + dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[5] + dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[6] + dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[7] + dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[8] ))/p;                          
              idft_real_row_temp[num_1_step_row[2]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[9] + dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[10]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[11]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[12]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[13]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[14]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[15]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[16]-(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[9] + dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[10]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[11]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[12]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[13]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[14]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[15]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[16]))/p;                         
              idft_real_row_temp[num_1_step_row[3]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[17]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[18]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[19]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[20]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[21]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[22]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[23]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[24]-(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[17]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[18]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[19]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[20]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[21]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[22]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[23]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[24]))/p;                         
              idft_real_row_temp[num_1_step_row[4]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[25]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[26]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[27]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[28]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[29]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[30]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[31]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[32]-(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[25]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[26]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[27]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[28]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[29]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[30]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[31]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[32]))/p;                         
              idft_real_row_temp[num_1_step_row[5]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[33]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[34]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[35]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[36]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[37]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[38]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[39]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[40]-(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[33]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[34]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[35]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[36]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[37]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[38]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[39]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[40]))/p;                         
              idft_real_row_temp[num_1_step_row[6]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[41]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[42]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[43]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[44]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[45]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[46]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[47]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[48]-(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[41]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[42]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[43]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[44]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[45]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[46]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[47]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[48]))/p;                         
              idft_real_row_temp[num_1_step_row[7]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[49]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[50]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[51]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[52]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[53]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[54]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[55]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[56]-(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[49]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[50]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[51]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[52]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[53]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[54]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[55]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[56]))/p;                         
              idft_real_row_temp[num_1_step_row[8]]  <= ( dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[57]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[58]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[59]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[60]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[61]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[62]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[63]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[64]-(dft_imag_clo_buf1[num_1_step_row[1]]* idft_imag_w[57]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_imag_w[58]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_imag_w[59]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_imag_w[60]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_imag_w[61]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_imag_w[62]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_imag_w[63]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_imag_w[64]))/p;                         
                          
                          
              idft_imag_row_temp[num_1_step_row[1]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[1] + dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[2] + dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[3] + dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[4] + dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[5] + dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[6] + dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[7] + dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[8]  +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[1] + dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[2] + dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[3] + dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[4] + dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[5] + dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[6] + dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[7] + dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[8])/p;                         
              idft_imag_row_temp[num_1_step_row[2]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[9] + dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[10]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[11]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[12]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[13]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[14]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[15]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[16] +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[9] + dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[10]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[11]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[12]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[13]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[14]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[15]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[16])/p;                         
              idft_imag_row_temp[num_1_step_row[3]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[17]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[18]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[19]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[20]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[21]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[22]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[23]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[24] +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[17]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[18]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[19]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[20]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[21]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[22]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[23]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[24])/p;                         
              idft_imag_row_temp[num_1_step_row[4]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[25]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[26]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[27]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[28]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[29]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[30]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[31]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[32] +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[25]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[26]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[27]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[28]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[29]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[30]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[31]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[32])/p;                         
              idft_imag_row_temp[num_1_step_row[5]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[33]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[34]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[35]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[36]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[37]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[38]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[39]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[40] +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[33]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[34]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[35]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[36]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[37]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[38]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[39]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[40])/p;                         
              idft_imag_row_temp[num_1_step_row[6]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[41]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[42]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[43]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[44]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[45]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[46]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[47]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[48] +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[41]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[42]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[43]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[44]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[45]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[46]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[47]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[48])/p;                         
              idft_imag_row_temp[num_1_step_row[7]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[49]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[50]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[51]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[52]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[53]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[54]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[55]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[56] +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[49]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[50]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[51]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[52]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[53]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[54]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[55]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[56])/p;                         
              idft_imag_row_temp[num_1_step_row[8]]  <= ( dft_imag_clo_buf1[num_1_step_row[1]]* idft_real_w[57]+ dft_imag_clo_buf1[num_1_step_row[2]]* idft_real_w[58]+ dft_imag_clo_buf1[num_1_step_row[3]]* idft_real_w[59]+ dft_imag_clo_buf1[num_1_step_row[4]]* idft_real_w[60]+ dft_imag_clo_buf1[num_1_step_row[5]]* idft_real_w[61]+ dft_imag_clo_buf1[num_1_step_row[6]]* idft_real_w[62]+ dft_imag_clo_buf1[num_1_step_row[7]]* idft_real_w[63]+ dft_imag_clo_buf1[num_1_step_row[8]]* idft_real_w[64] +dft_real_clo_buf1[num_1_step_row[1]]* idft_imag_w[57]+ dft_real_clo_buf1[num_1_step_row[2]]* idft_imag_w[58]+ dft_real_clo_buf1[num_1_step_row[3]]* idft_imag_w[59]+ dft_real_clo_buf1[num_1_step_row[4]]* idft_imag_w[60]+ dft_real_clo_buf1[num_1_step_row[5]]* idft_imag_w[61]+ dft_real_clo_buf1[num_1_step_row[6]]* idft_imag_w[62]+ dft_real_clo_buf1[num_1_step_row[7]]* idft_imag_w[63]+ dft_real_clo_buf1[num_1_step_row[8]]* idft_imag_w[64])/p;                         
            //  D1 = dft_real_clo_buf1[num_1_step_row[1]]* idft_real_w[1];
            //  D2 = dft_real_clo_buf1[num_1_step_row[2]]* idft_real_w[2];
            //  D3 = dft_real_clo_buf1[num_1_step_row[3]]* idft_real_w[3];
            //  D4 = dft_real_clo_buf1[num_1_step_row[4]]* idft_real_w[4];
            //  D5 = dft_real_clo_buf1[num_1_step_row[5]]* idft_real_w[5];
            //  D6 = dft_real_clo_buf1[num_1_step_row[6]]* idft_real_w[6];
            //  D7 = dft_real_clo_buf1[num_1_step_row[7]]* idft_real_w[7];
            //  D8 = dft_real_clo_buf1[num_1_step_row[8]]* idft_real_w[8];
           end 
           else if(dft_buf_sig == 1) begin
             idft_real_row_temp[num_1_step_row[1]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[1] + dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[2] + dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[3] + dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[4] + dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[5] + dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[6] + dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[7] + dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[8]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[1] + dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[2] + dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[3] + dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[4] + dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[5] + dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[6] + dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[7] + dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[8] ))/p;                          
             idft_real_row_temp[num_1_step_row[2]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[9] + dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[10]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[11]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[12]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[13]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[14]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[15]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[16]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[9] + dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[10]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[11]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[12]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[13]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[14]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[15]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[16]))/p;                         
             idft_real_row_temp[num_1_step_row[3]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[17]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[18]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[19]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[20]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[21]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[22]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[23]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[24]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[17]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[18]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[19]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[20]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[21]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[22]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[23]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[24]))/p;                         
             idft_real_row_temp[num_1_step_row[4]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[25]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[26]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[27]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[28]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[29]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[30]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[31]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[32]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[25]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[26]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[27]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[28]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[29]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[30]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[31]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[32]))/p;                         
             idft_real_row_temp[num_1_step_row[5]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[33]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[34]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[35]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[36]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[37]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[38]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[39]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[40]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[33]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[34]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[35]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[36]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[37]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[38]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[39]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[40]))/p;                         
             idft_real_row_temp[num_1_step_row[6]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[41]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[42]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[43]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[44]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[45]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[46]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[47]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[48]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[41]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[42]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[43]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[44]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[45]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[46]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[47]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[48]))/p;                         
             idft_real_row_temp[num_1_step_row[7]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[49]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[50]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[51]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[52]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[53]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[54]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[55]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[56]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[49]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[50]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[51]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[52]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[53]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[54]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[55]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[56]))/p;                         
             idft_real_row_temp[num_1_step_row[8]]  <= ( dft_real_clo_buf2[num_1_step_row[1]]* idft_real_w[57]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_real_w[58]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_real_w[59]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_real_w[60]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_real_w[61]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_real_w[62]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_real_w[63]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_real_w[64]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[57]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_imag_w[58]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_imag_w[59]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_imag_w[60]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_imag_w[61]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_imag_w[62]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_imag_w[63]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_imag_w[64]))/p;                         
                        
             idft_imag_row_temp[num_1_step_row[1]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[1] + dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[2] + dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[3] + dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[4] + dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[5] + dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[6] + dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[7] + dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[8]  +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[1] + dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[2] + dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[3] + dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[4] + dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[5] + dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[6] + dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[7] + dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[8])/p;                         
             idft_imag_row_temp[num_1_step_row[2]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[9] + dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[10]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[11]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[12]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[13]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[14]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[15]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[16] +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[9] + dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[10]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[11]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[12]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[13]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[14]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[15]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[16])/p;                         
             idft_imag_row_temp[num_1_step_row[3]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[17]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[18]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[19]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[20]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[21]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[22]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[23]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[24] +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[17]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[18]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[19]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[20]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[21]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[22]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[23]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[24])/p;                         
             idft_imag_row_temp[num_1_step_row[4]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[25]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[26]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[27]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[28]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[29]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[30]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[31]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[32] +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[25]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[26]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[27]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[28]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[29]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[30]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[31]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[32])/p;                         
             idft_imag_row_temp[num_1_step_row[5]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[33]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[34]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[35]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[36]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[37]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[38]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[39]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[40] +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[33]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[34]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[35]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[36]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[37]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[38]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[39]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[40])/p;                         
             idft_imag_row_temp[num_1_step_row[6]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[41]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[42]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[43]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[44]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[45]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[46]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[47]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[48] +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[41]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[42]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[43]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[44]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[45]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[46]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[47]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[48])/p;                         
             idft_imag_row_temp[num_1_step_row[7]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[49]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[50]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[51]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[52]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[53]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[54]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[55]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[56] +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[49]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[50]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[51]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[52]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[53]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[54]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[55]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[56])/p;                         
             idft_imag_row_temp[num_1_step_row[8]]  <= ( dft_imag_clo_buf2[num_1_step_row[1]]* idft_real_w[57]+ dft_imag_clo_buf2[num_1_step_row[2]]* idft_real_w[58]+ dft_imag_clo_buf2[num_1_step_row[3]]* idft_real_w[59]+ dft_imag_clo_buf2[num_1_step_row[4]]* idft_real_w[60]+ dft_imag_clo_buf2[num_1_step_row[5]]* idft_real_w[61]+ dft_imag_clo_buf2[num_1_step_row[6]]* idft_real_w[62]+ dft_imag_clo_buf2[num_1_step_row[7]]* idft_real_w[63]+ dft_imag_clo_buf2[num_1_step_row[8]]* idft_real_w[64] +dft_real_clo_buf2[num_1_step_row[1]]* idft_imag_w[57]+ dft_real_clo_buf2[num_1_step_row[2]]* idft_imag_w[58]+ dft_real_clo_buf2[num_1_step_row[3]]* idft_imag_w[59]+ dft_real_clo_buf2[num_1_step_row[4]]* idft_imag_w[60]+ dft_real_clo_buf2[num_1_step_row[5]]* idft_imag_w[61]+ dft_real_clo_buf2[num_1_step_row[6]]* idft_imag_w[62]+ dft_real_clo_buf2[num_1_step_row[7]]* idft_imag_w[63]+ dft_real_clo_buf2[num_1_step_row[8]]* idft_imag_w[64])/p;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
           end 
           else if(dft_buf_sig == 2) begin
             idft_real_row_temp[num_1_step_row[1]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[1] + dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[2] + dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[3] + dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[4] + dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[5] + dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[6] + dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[7] + dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[8]-(dft_imag_clo_buf2[num_1_step_row[1]]* idft_imag_w[1]  + dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[2] + dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[3] + dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[4] + dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[5] + dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[6] + dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[7] + dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[8] ))/p;                          
             idft_real_row_temp[num_1_step_row[2]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[9] + dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[10]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[11]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[12]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[13]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[14]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[15]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[16]-(dft_imag_clo_buf3[num_1_step_row[1]]* idft_imag_w[9] + dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[10]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[11]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[12]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[13]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[14]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[15]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[16]))/p;                         
             idft_real_row_temp[num_1_step_row[3]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[17]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[18]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[19]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[20]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[21]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[22]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[23]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[24]-(dft_imag_clo_buf3[num_1_step_row[1]]* idft_imag_w[17]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[18]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[19]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[20]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[21]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[22]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[23]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[24]))/p;                         
             idft_real_row_temp[num_1_step_row[4]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[25]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[26]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[27]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[28]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[29]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[30]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[31]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[32]-(dft_imag_clo_buf3[num_1_step_row[1]]* idft_imag_w[25]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[26]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[27]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[28]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[29]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[30]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[31]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[32]))/p;                         
             idft_real_row_temp[num_1_step_row[5]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[33]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[34]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[35]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[36]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[37]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[38]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[39]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[40]-(dft_imag_clo_buf3[num_1_step_row[1]]* idft_imag_w[33]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[34]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[35]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[36]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[37]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[38]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[39]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[40]))/p;                         
             idft_real_row_temp[num_1_step_row[6]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[41]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[42]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[43]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[44]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[45]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[46]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[47]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[48]-(dft_imag_clo_buf3[num_1_step_row[1]]* idft_imag_w[41]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[42]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[43]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[44]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[45]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[46]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[47]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[48]))/p;                         
             idft_real_row_temp[num_1_step_row[7]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[49]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[50]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[51]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[52]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[53]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[54]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[55]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[56]-(dft_imag_clo_buf3[num_1_step_row[1]]* idft_imag_w[49]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[50]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[51]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[52]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[53]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[54]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[55]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[56]))/p;                         
             idft_real_row_temp[num_1_step_row[8]]  <= ( dft_real_clo_buf3[num_1_step_row[1]]* idft_real_w[57]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_real_w[58]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_real_w[59]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_real_w[60]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_real_w[61]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_real_w[62]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_real_w[63]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_real_w[64]-(dft_imag_clo_buf3[num_1_step_row[1]]* idft_imag_w[57]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_imag_w[58]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_imag_w[59]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_imag_w[60]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_imag_w[61]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_imag_w[62]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_imag_w[63]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_imag_w[64]))/p;                         
                        
             idft_imag_row_temp[num_1_step_row[1]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[1] + dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[2] + dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[3] + dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[4] + dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[5] + dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[6] + dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[7] + dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[8]  +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[1] + dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[2] + dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[3] + dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[4] + dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[5] + dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[6] + dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[7] + dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[8])/p;                         
             idft_imag_row_temp[num_1_step_row[2]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[9] + dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[10]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[11]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[12]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[13]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[14]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[15]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[16] +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[9] + dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[10]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[11]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[12]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[13]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[14]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[15]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[16])/p;                         
             idft_imag_row_temp[num_1_step_row[3]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[17]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[18]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[19]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[20]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[21]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[22]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[23]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[24] +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[17]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[18]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[19]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[20]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[21]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[22]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[23]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[24])/p;                         
             idft_imag_row_temp[num_1_step_row[4]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[25]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[26]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[27]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[28]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[29]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[30]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[31]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[32] +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[25]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[26]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[27]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[28]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[29]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[30]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[31]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[32])/p;                         
             idft_imag_row_temp[num_1_step_row[5]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[33]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[34]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[35]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[36]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[37]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[38]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[39]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[40] +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[33]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[34]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[35]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[36]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[37]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[38]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[39]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[40])/p;                         
             idft_imag_row_temp[num_1_step_row[6]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[41]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[42]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[43]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[44]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[45]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[46]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[47]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[48] +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[41]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[42]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[43]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[44]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[45]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[46]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[47]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[48])/p;                         
             idft_imag_row_temp[num_1_step_row[7]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[49]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[50]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[51]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[52]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[53]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[54]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[55]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[56] +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[49]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[50]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[51]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[52]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[53]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[54]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[55]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[56])/p;                         
             idft_imag_row_temp[num_1_step_row[8]]  <= ( dft_imag_clo_buf3[num_1_step_row[1]]* idft_real_w[57]+ dft_imag_clo_buf3[num_1_step_row[2]]* idft_real_w[58]+ dft_imag_clo_buf3[num_1_step_row[3]]* idft_real_w[59]+ dft_imag_clo_buf3[num_1_step_row[4]]* idft_real_w[60]+ dft_imag_clo_buf3[num_1_step_row[5]]* idft_real_w[61]+ dft_imag_clo_buf3[num_1_step_row[6]]* idft_real_w[62]+ dft_imag_clo_buf3[num_1_step_row[7]]* idft_real_w[63]+ dft_imag_clo_buf3[num_1_step_row[8]]* idft_real_w[64] +dft_real_clo_buf3[num_1_step_row[1]]* idft_imag_w[57]+ dft_real_clo_buf3[num_1_step_row[2]]* idft_imag_w[58]+ dft_real_clo_buf3[num_1_step_row[3]]* idft_imag_w[59]+ dft_real_clo_buf3[num_1_step_row[4]]* idft_imag_w[60]+ dft_real_clo_buf3[num_1_step_row[5]]* idft_imag_w[61]+ dft_real_clo_buf3[num_1_step_row[6]]* idft_imag_w[62]+ dft_real_clo_buf3[num_1_step_row[7]]* idft_imag_w[63]+ dft_real_clo_buf3[num_1_step_row[8]]* idft_imag_w[64])/p;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
           end 
          
      	   //idft_clo  8
           idft_real_clo_temp[cnt_1_step       ]  <=   (idft_real_row[cnt_1_step]* idft_real_w[1] + idft_real_row[num_1_step_clo[1]]* idft_real_w[2]  + idft_real_row[num_1_step_clo[2]]* idft_real_w[3] + idft_real_row[num_1_step_clo[3]]* idft_real_w[4] + idft_real_row[num_1_step_clo[4]]* idft_real_w[5] + idft_real_row[num_1_step_clo[5]]* idft_real_w[6] + idft_real_row[num_1_step_clo[6]]* idft_real_w[7] + idft_real_row[num_1_step_clo[7]]* idft_real_w[8]-(idft_imag_row[cnt_1_step]* idft_imag_w[1] + idft_imag_row[num_1_step_clo[1]]* idft_imag_w[2] + idft_imag_row[num_1_step_clo[2]]* idft_imag_w[3] + idft_imag_row[num_1_step_clo[3]]* idft_imag_w[4] + idft_imag_row[num_1_step_clo[4]]* idft_imag_w[5] + idft_imag_row[num_1_step_clo[5]]* idft_imag_w[6] + idft_imag_row[num_1_step_clo[6]]* idft_imag_w[7] + idft_imag_row[num_1_step_clo[7]]* idft_imag_w[8] )) /(q);
           idft_real_clo_temp[num_1_step_clo[1]]  <=   (idft_real_row[cnt_1_step]* idft_real_w[9] + idft_real_row[num_1_step_clo[1]]* idft_real_w[10] + idft_real_row[num_1_step_clo[2]]* idft_real_w[11]+ idft_real_row[num_1_step_clo[3]]* idft_real_w[12]+ idft_real_row[num_1_step_clo[4]]* idft_real_w[13]+ idft_real_row[num_1_step_clo[5]]* idft_real_w[14]+ idft_real_row[num_1_step_clo[6]]* idft_real_w[15]+ idft_real_row[num_1_step_clo[7]]* idft_real_w[16]-(idft_imag_row[cnt_1_step]* idft_imag_w[9] + idft_imag_row[num_1_step_clo[1]]* idft_imag_w[10]+ idft_imag_row[num_1_step_clo[2]]* idft_imag_w[11]+ idft_imag_row[num_1_step_clo[3]]* idft_imag_w[12]+ idft_imag_row[num_1_step_clo[4]]* idft_imag_w[13]+ idft_imag_row[num_1_step_clo[5]]* idft_imag_w[14]+ idft_imag_row[num_1_step_clo[6]]* idft_imag_w[15]+ idft_imag_row[num_1_step_clo[7]]* idft_imag_w[16]))/(q);
           idft_real_clo_temp[num_1_step_clo[2]]  <=   (idft_real_row[cnt_1_step]* idft_real_w[17]+ idft_real_row[num_1_step_clo[1]]* idft_real_w[18] + idft_real_row[num_1_step_clo[2]]* idft_real_w[19]+ idft_real_row[num_1_step_clo[3]]* idft_real_w[20]+ idft_real_row[num_1_step_clo[4]]* idft_real_w[21]+ idft_real_row[num_1_step_clo[5]]* idft_real_w[22]+ idft_real_row[num_1_step_clo[6]]* idft_real_w[23]+ idft_real_row[num_1_step_clo[7]]* idft_real_w[24]-(idft_imag_row[cnt_1_step]* idft_imag_w[17]+ idft_imag_row[num_1_step_clo[1]]* idft_imag_w[18]+ idft_imag_row[num_1_step_clo[2]]* idft_imag_w[19]+ idft_imag_row[num_1_step_clo[3]]* idft_imag_w[20]+ idft_imag_row[num_1_step_clo[4]]* idft_imag_w[21]+ idft_imag_row[num_1_step_clo[5]]* idft_imag_w[22]+ idft_imag_row[num_1_step_clo[6]]* idft_imag_w[23]+ idft_imag_row[num_1_step_clo[7]]* idft_imag_w[24]))/(q);
           idft_real_clo_temp[num_1_step_clo[3]]  <=   (idft_real_row[cnt_1_step]* idft_real_w[25]+ idft_real_row[num_1_step_clo[1]]* idft_real_w[26] + idft_real_row[num_1_step_clo[2]]* idft_real_w[27]+ idft_real_row[num_1_step_clo[3]]* idft_real_w[28]+ idft_real_row[num_1_step_clo[4]]* idft_real_w[29]+ idft_real_row[num_1_step_clo[5]]* idft_real_w[30]+ idft_real_row[num_1_step_clo[6]]* idft_real_w[31]+ idft_real_row[num_1_step_clo[7]]* idft_real_w[32]-(idft_imag_row[cnt_1_step]* idft_imag_w[25]+ idft_imag_row[num_1_step_clo[1]]* idft_imag_w[26]+ idft_imag_row[num_1_step_clo[2]]* idft_imag_w[27]+ idft_imag_row[num_1_step_clo[3]]* idft_imag_w[28]+ idft_imag_row[num_1_step_clo[4]]* idft_imag_w[29]+ idft_imag_row[num_1_step_clo[5]]* idft_imag_w[30]+ idft_imag_row[num_1_step_clo[6]]* idft_imag_w[31]+ idft_imag_row[num_1_step_clo[7]]* idft_imag_w[32]))/(q);
           idft_real_clo_temp[num_1_step_clo[4]]  <=   (idft_real_row[cnt_1_step]* idft_real_w[33]+ idft_real_row[num_1_step_clo[1]]* idft_real_w[34] + idft_real_row[num_1_step_clo[2]]* idft_real_w[35]+ idft_real_row[num_1_step_clo[3]]* idft_real_w[36]+ idft_real_row[num_1_step_clo[4]]* idft_real_w[37]+ idft_real_row[num_1_step_clo[5]]* idft_real_w[38]+ idft_real_row[num_1_step_clo[6]]* idft_real_w[39]+ idft_real_row[num_1_step_clo[7]]* idft_real_w[40]-(idft_imag_row[cnt_1_step]* idft_imag_w[33]+ idft_imag_row[num_1_step_clo[1]]* idft_imag_w[34]+ idft_imag_row[num_1_step_clo[2]]* idft_imag_w[35]+ idft_imag_row[num_1_step_clo[3]]* idft_imag_w[36]+ idft_imag_row[num_1_step_clo[4]]* idft_imag_w[37]+ idft_imag_row[num_1_step_clo[5]]* idft_imag_w[38]+ idft_imag_row[num_1_step_clo[6]]* idft_imag_w[39]+ idft_imag_row[num_1_step_clo[7]]* idft_imag_w[40]))/(q);
           idft_real_clo_temp[num_1_step_clo[5]]  <=   (idft_real_row[cnt_1_step]* idft_real_w[41]+ idft_real_row[num_1_step_clo[1]]* idft_real_w[42] + idft_real_row[num_1_step_clo[2]]* idft_real_w[43]+ idft_real_row[num_1_step_clo[3]]* idft_real_w[44]+ idft_real_row[num_1_step_clo[4]]* idft_real_w[45]+ idft_real_row[num_1_step_clo[5]]* idft_real_w[46]+ idft_real_row[num_1_step_clo[6]]* idft_real_w[47]+ idft_real_row[num_1_step_clo[7]]* idft_real_w[48]-(idft_imag_row[cnt_1_step]* idft_imag_w[41]+ idft_imag_row[num_1_step_clo[1]]* idft_imag_w[42]+ idft_imag_row[num_1_step_clo[2]]* idft_imag_w[43]+ idft_imag_row[num_1_step_clo[3]]* idft_imag_w[44]+ idft_imag_row[num_1_step_clo[4]]* idft_imag_w[45]+ idft_imag_row[num_1_step_clo[5]]* idft_imag_w[46]+ idft_imag_row[num_1_step_clo[6]]* idft_imag_w[47]+ idft_imag_row[num_1_step_clo[7]]* idft_imag_w[48]))/(q);
           idft_real_clo_temp[num_1_step_clo[6]]  <=   (idft_real_row[cnt_1_step]* idft_real_w[49]+ idft_real_row[num_1_step_clo[1]]* idft_real_w[50] + idft_real_row[num_1_step_clo[2]]* idft_real_w[51]+ idft_real_row[num_1_step_clo[3]]* idft_real_w[52]+ idft_real_row[num_1_step_clo[4]]* idft_real_w[53]+ idft_real_row[num_1_step_clo[5]]* idft_real_w[54]+ idft_real_row[num_1_step_clo[6]]* idft_real_w[55]+ idft_real_row[num_1_step_clo[7]]* idft_real_w[56]-(idft_imag_row[cnt_1_step]* idft_imag_w[49]+ idft_imag_row[num_1_step_clo[1]]* idft_imag_w[50]+ idft_imag_row[num_1_step_clo[2]]* idft_imag_w[51]+ idft_imag_row[num_1_step_clo[3]]* idft_imag_w[52]+ idft_imag_row[num_1_step_clo[4]]* idft_imag_w[53]+ idft_imag_row[num_1_step_clo[5]]* idft_imag_w[54]+ idft_imag_row[num_1_step_clo[6]]* idft_imag_w[55]+ idft_imag_row[num_1_step_clo[7]]* idft_imag_w[56]))/(q);
           idft_real_clo_temp[num_1_step_clo[7]]  <=   (idft_real_row[cnt_1_step]* idft_real_w[57]+ idft_real_row[num_1_step_clo[1]]* idft_real_w[58] + idft_real_row[num_1_step_clo[2]]* idft_real_w[59]+ idft_real_row[num_1_step_clo[3]]* idft_real_w[60]+ idft_real_row[num_1_step_clo[4]]* idft_real_w[61]+ idft_real_row[num_1_step_clo[5]]* idft_real_w[62]+ idft_real_row[num_1_step_clo[6]]* idft_real_w[63]+ idft_real_row[num_1_step_clo[7]]* idft_real_w[64]-(idft_imag_row[cnt_1_step]* idft_imag_w[57]+ idft_imag_row[num_1_step_clo[1]]* idft_imag_w[58]+ idft_imag_row[num_1_step_clo[2]]* idft_imag_w[59]+ idft_imag_row[num_1_step_clo[3]]* idft_imag_w[60]+ idft_imag_row[num_1_step_clo[4]]* idft_imag_w[61]+ idft_imag_row[num_1_step_clo[5]]* idft_imag_w[62]+ idft_imag_row[num_1_step_clo[6]]* idft_imag_w[63]+ idft_imag_row[num_1_step_clo[7]]* idft_imag_w[64]))/(q);
           
      	   //round 9
           image_ins_1 <=  idft_real_clo[cnt_1_step       ][18:1] ;
           image_ins_2 <=  idft_real_clo[num_1_step_clo[1]][18:1] ;
           image_ins_3 <=  idft_real_clo[num_1_step_clo[2]][18:1] ;
           image_ins_4 <=  idft_real_clo[num_1_step_clo[3]][18:1] ;
           image_ins_5 <=  idft_real_clo[num_1_step_clo[4]][18:1] ;
           image_ins_6 <=  idft_real_clo[num_1_step_clo[5]][18:1] ;
           image_ins_7 <=  idft_real_clo[num_1_step_clo[6]][18:1] ;
           image_ins_8 <=  idft_real_clo[num_1_step_clo[7]][18:1] ;
      	                    
           //cnt_1_step                    
           cnt_1_step <= cnt_1_step + 1;    
          
        end//if(cnt_1_step <= 8)  
        else begin
          cnt_1_step <= 1;
          
          if(dft_buf_sig < 2)
          dft_buf_sig <= dft_buf_sig  + 1;
          else
          dft_buf_sig <= 0;
          
          rad_buf_sig <= rad_buf_sig + 1;
          
          loop_cnt <= loop_cnt + 1;
          
          if(output_valid == 1 || input_valid == 1)
            cur_state  <=  ins_1_step;
          else
            cur_state <= idle;
          
          if(input_valid == 0 && cnt_ovalid < 9)
            cnt_ovalid = cnt_ovalid + 1;
          else if(input_valid == 0 && cnt_ovalid >= 9)
            cnt_ovalid = cnt_ovalid;
          else begin
            cnt_ovalid = 0;
          end             
          
          //data to reg          
          for(i = 1; i <= 64; i = i +1) begin       
            image_data[i]    <= image_data_temp[i];                  
            dft_real_clo[i]  <= dft_real_clo_temp[i];
            dft_imag_clo[i]  <= dft_imag_clo_temp[i]; 
            dft_real_row[i]  <= dft_real_row_temp[i];
            dft_imag_row[i]  <= dft_imag_row_temp[i]; 
            idft_imag_row[i] <= idft_imag_row_temp[i];               
            idft_real_row[i] <= idft_real_row_temp[i];              
            idft_real_clo[i] <= idft_real_clo_temp[i]; 
                          
          end                                      
          
          if(rad_buf_sig == 0) begin
            rad_1_buf1    <=  rad_1_temp  ; 
            rad_11_buf1   <=  rad_11_temp ;
            rad_18_buf1   <=  rad_18_temp ;
            rad_50_buf1   <=  rad_50_temp ;
            rad_59_buf1   <=  rad_59_temp ;
          end
          else begin      
            rad_1_buf2    <=  rad_1_temp  ; 
            rad_11_buf2    <=  rad_11_temp ;
            rad_18_buf2   <=  rad_18_temp ;
            rad_50_buf2   <=  rad_50_temp ;
            rad_59_buf2   <=  rad_59_temp ;
          end
          
          M_1      <=  M_1_temp  ;     
          M_11     <=  M_11_temp ;
          M_18     <=  M_18_temp ;          
          M_50     <=  M_50_temp ;
          M_59     <=  M_59_temp ;
          
          M_ins_1  <= M_ins_1_temp ; 
          M_ins_11 <= M_ins_11_temp ;
          M_ins_18 <= M_ins_18_temp ;
          M_ins_50 <= M_ins_50_temp ;
          M_ins_59 <= M_ins_59_temp ;

          
          if(dft_buf_sig == 0) begin
            for(i = 1; i <= 64; i = i +1) begin
                dft_imag_clo_buf1[i] <= dft_imag_clo[i];
                dft_real_clo_buf1[i] <= dft_real_clo[i];
            end
          end
          else if(dft_buf_sig == 1) begin
            for(i = 1; i <= 64; i = i +1) begin
              dft_imag_clo_buf2[i] <= dft_imag_clo[i];
              dft_real_clo_buf2[i] <= dft_real_clo[i];
            end
          end
          else if(dft_buf_sig == 2) begin
            for(i = 1; i <= 64; i = i +1) begin
              dft_imag_clo_buf3[i] <= dft_imag_clo[i];
              dft_real_clo_buf3[i] <= dft_real_clo[i];
            end
          end
       
        end
                
        case(cnt_1_step)
      	   
          1 : begin
          	  if(ins_mode == 0)begin
          	    //4 bits data insert
          	    //complex2radm 4
      	   		  tdata <= {dft_imag_clo[11][50:11],dft_real_clo[11][50:11]} ;
                
      	   		  //radm2complex 6
      	   		  rad_1_2_5 <=  rad_buf_sig ? rad_11_buf2 : rad_11_buf1 ;  
      	   		  
      	        //插入信息，具体处理在step1中是第五个步骤，信息插入的输入在第五步第一拍插入，在第二拍嵌入时被使用
             
                ins_M_t  [1] <= ins_M  [1]; 
                ins_M_t  [2] <= ins_M  [2]; 
                ins_M_t  [3] <= ins_M  [3];  
                ins_M_t  [4] <= ins_M  [4]; 
              end  
              else begin
                //ins_mode = 1, 1 bit data insert
          	    
          	    //complex2radm 4
      	   		  tdata <= {dft_imag_clo[1][50:11],dft_real_clo[1][50:11]} ;
                
      	   		  //radm2complex 6
      	   		  rad_1_2_5 <=  rad_buf_sig ? rad_1_buf2 : rad_1_buf1;  
      	   		  
      	   		  //插入信息，具体处理在step1中是第五个步骤，信息插入的输入在第五步第一拍插入，在第二拍嵌入时被使用
                ins_M_t  [1] <= ins_M  [1]; 
              end 
          end
          
        	 2 : begin
        	 	  if(ins_mode == 0)begin    
        	 	    //complex2radm 4
      	        rad_11_temp <= dout_rad ;
                  M_11_temp   <= dft_real_clo[11]/cos_temp1 ;
                
        	 	    //QIM 5
                mod_Mstep[1]    <=  M_11   / M_step      + ins_M_t[4]   ;
                mod_Mstep[2]    <=  M_18   / M_step      + ins_M_t[3]   ;
                mod_Mstep[3]    <=  M_50   / M_step      + ins_M_t[1]   ;
                mod_Mstep[4]    <=  M_59   / M_step      + ins_M_t[2]   ;
          
                //radm2complex 6
                if(dft_buf_sig == 2) begin                                      
                  dft_real_clo_buf1[11] <=   M_ins_11 * cos_temp * 256 ;   
                  dft_real_clo_buf1[63] <=   M_ins_11 * cos_temp * 256 ;   
                  dft_imag_clo_buf1[11] <=   M_ins_11 * sin_temp * 256 ;   
                  dft_imag_clo_buf1[63] <= - M_ins_11 * sin_temp * 256 ;  
                end            
                else if(dft_buf_sig == 0) begin
                  dft_real_clo_buf2[11] <=   M_ins_11 * cos_temp * 256 ;   
                  dft_real_clo_buf2[63] <=   M_ins_11 * cos_temp * 256 ;   
                  dft_imag_clo_buf2[11] <=   M_ins_11 * sin_temp * 256 ;   
                  dft_imag_clo_buf2[63] <= - M_ins_11 * sin_temp * 256 ;  
                end
                else  if(dft_buf_sig == 1)begin                         
                  dft_real_clo_buf3[11] <=   M_ins_11 * cos_temp * 256 ;   
                  dft_real_clo_buf3[63] <=   M_ins_11 * cos_temp * 256 ;   
                  dft_imag_clo_buf3[11] <=   M_ins_11 * sin_temp * 256 ;   
                  dft_imag_clo_buf3[63] <= - M_ins_11 * sin_temp * 256 ;
                end
                else begin end
              end
              else begin end                                                
          end                                                    
        	 
        	 3 : begin
        	       if(ins_mode == 0)begin 
        	       	 
        	       //complex2radm 4
      	   		  tdata <= {dft_imag_clo[18][50:11],dft_real_clo[18][50:11]} ;
                
                //radm2complex 6
                rad_1_2_5 <=  rad_buf_sig ? rad_18_buf2 : rad_18_buf1 ;
                end 
           	    else begin 
           	    end
          end
           
        	 4 : begin  
        	 	    if(ins_mode == 0)begin
        	 	      //complex2radm 4
      	   	      rad_18_temp <= dout_rad ;
                  M_18_temp <= dft_real_clo[18]/cos_temp1 ; 
                  
                  //radm2complex 6
                  if(dft_buf_sig == 2) begin                                      
                    dft_real_clo_buf1[18] <=   M_ins_18 * cos_temp * 256 ;   
                    dft_real_clo_buf1[56] <=   M_ins_18 * cos_temp * 256 ;   
                    dft_imag_clo_buf1[18] <=   M_ins_18 * sin_temp * 256 ;   
                    dft_imag_clo_buf1[56] <= - M_ins_18 * sin_temp * 256 ;  
                  end            
                  else if(dft_buf_sig == 0) begin
                    dft_real_clo_buf2[18] <=   M_ins_18 * cos_temp * 256 ;   
                    dft_real_clo_buf2[56] <=   M_ins_18 * cos_temp * 256 ;   
                    dft_imag_clo_buf2[18] <=   M_ins_18 * sin_temp * 256 ;   
                    dft_imag_clo_buf2[56] <= - M_ins_18 * sin_temp * 256 ;  
                  end
                  else  if(dft_buf_sig == 1)begin                         
                    dft_real_clo_buf3[18] <=   M_ins_18 * cos_temp * 256 ;   
                    dft_real_clo_buf3[56] <=   M_ins_18 * cos_temp * 256 ;   
                    dft_imag_clo_buf3[18] <=   M_ins_18 * sin_temp * 256 ;   
                    dft_imag_clo_buf3[56] <= - M_ins_18 * sin_temp * 256 ;
                  end
                  else begin end
                end   
                else begin end
                                                                 
          end
        	 
        	 5 : begin           
        	 	    if(ins_mode == 0)begin 
        	     	//complex2radm 4
      	   		  tdata <= {dft_imag_clo[50][50:11],dft_real_clo[50][50:11]} ;
                
      	   		  //radm2complex 6
                rad_1_2_5 <=  rad_buf_sig ? rad_50_buf2 : rad_50_buf1 ;  
                end 
        	 	    else begin
        	 	    end
          	  end
           
        	 6 : begin
        	 	    if(ins_mode == 0)begin
        	 	      //complex2radm 4                        
                  rad_50_temp <= dout_rad ;                  
                  M_50_temp   <= dft_real_clo[50]/cos_temp1 ;
                  
        	 	      //QIM 5    
        	         M_ins_11_temp   <= M_11    / M_step     * 220  +     mod_Mstep[1][1]  * 220  + 88 ;      //暂时采用floor
                  M_ins_18_temp   <= M_18    / M_step     * 220  +     mod_Mstep[2][1]  * 220  + 88 ;
                  M_ins_50_temp   <= M_50    / M_step     * 220  +     mod_Mstep[3][1]  * 220  + 88 ;
                  M_ins_59_temp   <= M_59    / M_step     * 220  +     mod_Mstep[4][1]  * 220  + 88 ;
                  
                  //radm2complex 6   
                  if(dft_buf_sig == 2) begin                                      
                    dft_real_clo_buf1[50] <=   M_ins_50 * cos_temp * 256 ;   
                    dft_real_clo_buf1[24] <=   M_ins_50 * cos_temp * 256 ;   
                    dft_imag_clo_buf1[50] <=   M_ins_50 * sin_temp * 256 ;   
                    dft_imag_clo_buf1[24] <= - M_ins_50 * sin_temp * 256 ;  
                  end            
                  else if(dft_buf_sig == 0) begin
                    dft_real_clo_buf2[50] <=   M_ins_50 * cos_temp * 256 ;   
                    dft_real_clo_buf2[24] <=   M_ins_50 * cos_temp * 256 ;   
                    dft_imag_clo_buf2[50] <=   M_ins_50 * sin_temp * 256 ;   
                    dft_imag_clo_buf2[24] <= - M_ins_50 * sin_temp * 256 ;  
                  end
                  else  if(dft_buf_sig == 1)begin                         
                    dft_real_clo_buf3[50] <=   M_ins_50 * cos_temp * 256 ;   
                    dft_real_clo_buf3[24] <=   M_ins_50 * cos_temp * 256 ;   
                    dft_imag_clo_buf3[50] <=   M_ins_50 * sin_temp * 256 ;   
                    dft_imag_clo_buf3[24] <= - M_ins_50 * sin_temp * 256 ;
                  end
                  else begin end
                   
                end else   
                  //QIM 5    
        	         M_ins_1_temp   <= (M_1    / (2 * M_step)     * 440       + mod_Mstep[1][1]  * 440) > 128*64+440-1 ? M_1    / (2 * M_step)     * 440       + mod_Mstep[1][1]  * 440 - 880  :   M_1    / (2 * M_step)     * 440       + mod_Mstep[1][1]  * 440  ;      //暂时采用floor
          end
                
          7 : begin      
          	    if(ins_mode == 0)begin 
          	    //complex2radm 4                                
                tdata <= {dft_imag_clo[59][50:11],dft_real_clo[59][50:11]} ; 
          
          	    //QIM 5
                
      	   		  //radm2complex 6
      	   		  rad_1_2_5 <=  rad_buf_sig ? rad_59_buf2 : rad_59_buf1;    
      	   		  end else begin
      	   		  end 
          end
             
          8 : begin
          	    if(ins_mode == 0)begin 
      	        //complex2radm 4
      	  	      rad_59_temp <= dout_rad ;
                  M_59_temp   <= dft_real_clo[59] / cos_temp1 ;
                    
                //radm2complex 6
                if(dft_buf_sig == 2) begin                                      
                  dft_real_clo_buf1[59] <=   M_ins_59 * cos_temp * 256 ;   
                  dft_real_clo_buf1[15] <=   M_ins_59 * cos_temp * 256 ;   
                  dft_imag_clo_buf1[59] <=   M_ins_59 * sin_temp * 256 ;   
                  dft_imag_clo_buf1[15] <= - M_ins_59 * sin_temp * 256 ;  
                end                                                   
                else if(dft_buf_sig == 0) begin                       
                  dft_real_clo_buf2[59] <=   M_ins_59 * cos_temp * 256 ;   
                  dft_real_clo_buf2[15] <=   M_ins_59 * cos_temp * 256 ;   
                  dft_imag_clo_buf2[59] <=   M_ins_59 * sin_temp * 256 ;   
                  dft_imag_clo_buf2[15] <= - M_ins_59 * sin_temp * 256 ;  
                end                                                   
                else  if(dft_buf_sig == 1)begin                           
                  dft_real_clo_buf3[59] <=   M_ins_59 * cos_temp * 256 ;   
                  dft_real_clo_buf3[15] <=   M_ins_59 * cos_temp * 256 ;   
                  dft_imag_clo_buf3[59] <=   M_ins_59 * sin_temp * 256 ;   
                  dft_imag_clo_buf3[15] <= - M_ins_59 * sin_temp * 256 ;
                end
                else begin end  
              end else begin end 
           end
      	    	
          default : begin end   
        endcase 
      end
    endcase//case
  end   //else  rst
end //always                                                                                                       
     
arctan inst1(
.y(tdata[80:41]),
.x(tdata[40:1]),
.rad(dout_rad)
);                                                                                                      
                        
cossin_16 inst2(
 .rad(dout_rad),
 .cos(cos_temp1),
 .sin(sin_temp1)
 );     
                                                                                 
cossin_24 inst3(
.rad(rad_1_2_5),
.cos(cos_temp),
.sin(sin_temp)
);      
                                                                                                                                                                                                                                       
endmodule                                                                                                                 

