
module Seven_segment_LED_Display_Controller(
    input clk, // 100 Mhz clock source on Basys 3 FPGA
    input reset, // reset
    output reg [3:0] Anode_on, // anode signals of the 7-segment LED display
    output reg [6:0] LED_out,// cathode patterns of the 7-segment LED display
    output reg alarm_led ,
    output reg led_sec
    );
    reg [26:0] one_second_counter; // counter for generating 1 second clock enable
    
    reg [4:0]alarm_h;
    reg [5:0]alarm_m,alarm_s;
    
    wire one_sec_en;// one second enable for counting numbers
    reg [5:0] sec,min;
    reg [4:0] hour; 
    reg [3:0] LED_BCD;
    reg [19:0] refresh; // 20-bit for creating 10.5ms refresh period or 380Hz refresh rate
             // the first 2 MSB bits for creating 4 LED-activating signals with 2.6ms digit period
    
    
    wire [1:0] Led_activate; 
               //counts and activates the 7 segment leds one-by-on after some 2.3 ms to make use of persistance of vision of eye
    
    //alarm time set
    
    initial
        begin
        led_sec<=0;
        alarm_h<=14;
        alarm_m<=08;
        alarm_s<=0;
        alarm_led<=0;
        end
    // glow the led corresponding to alarm at the time set
    always@(*)
    begin
    if(alarm_h==hour && alarm_m==min)
            alarm_led <= 1; 
    else
             alarm_led<=0;
     end
     
    
    
    
    always @(posedge clk or posedge reset)
    begin
        if(reset==1)
            one_second_counter <= 0;
        else begin
            if(one_second_counter >=99999999) 
                 one_second_counter <= 0;
            else
              
              begin
                one_second_counter <= one_second_counter + 1;
                            if(one_second_counter <=49999999) // to blink an led for half a sec to indicate seconds
                                 led_sec <= 1;
                            else
                                led_sec <= 0;
                        
                                 
               end 
        end
    end 
    initial             //random initialization
    begin
        sec <= 0;
        min <= 07;
        hour <= 14;
      
    end
    assign one_sec_en = (one_second_counter==99999999)?1:0;
    always @(posedge clk or posedge reset)
    begin
        if(reset==1)
        begin
            
            sec <= 0;
            min <= 0;
            hour <= 0;
        end
        else if(one_sec_en==1) 
		begin
            sec <= sec + 1;
            if(sec == 59)
            begin
                sec = 0;
                min = min +1;
                if(min == 59)
                begin
                    min = 0;
                    hour = hour + 1;
                    if(hour == 23)
                    begin
                        hour = 0;
                    end
                end    
            end
         end 
    end
    always @(posedge clk or posedge reset)
    begin 
        if(reset==1)
            refresh <= 0;
        else
            refresh <= refresh + 1;
    end 
    assign Led_activate = refresh[19:18];
    // digit refresh period of 2.6ms
    // decoder to generate anode signals 
    always @(*)
    begin
        case(Led_activate)
        2'b00: begin
            Anode_on = 4'b0111;
			LED_BCD = (hour / 10) % 10;		//tens digit of hours 
            // the first digit of the 16-bit number
              end
        2'b01: begin
            Anode_on = 4'b1011;
			LED_BCD = hour % 10;		//unit digit of hours
            // the second digit of the 16-bit number
              end
        2'b10: begin
            Anode_on = 4'b1101;            
            LED_BCD = (min / 10) % 10;		//tens digit of minutes
			// the third digit of the 16-bit number
                end
        2'b11: begin
            Anode_on = 4'b1110;
            LED_BCD = (min % 10);		//minutes digit of minutes
			// the fourth digit of the 16-bit number    
               end
        endcase
    end
    // 7-segment LED display patterns
    always @(*)
    begin
        case(LED_BCD)
        4'b0000: LED_out = 7'b0000001; // "0"     
        4'b0001: LED_out = 7'b1001111; // "1" 
        4'b0010: LED_out = 7'b0010010; // "2" 
        4'b0011: LED_out = 7'b0000110; // "3" 
        4'b0100: LED_out = 7'b1001100; // "4" 
        4'b0101: LED_out = 7'b0100100; // "5" 
        4'b0110: LED_out = 7'b0100000; // "6" 
        4'b0111: LED_out = 7'b0001111; // "7" 
        4'b1000: LED_out = 7'b0000000; // "8"     
        4'b1001: LED_out = 7'b0000100; // "9" 
         
        default: LED_out = 7'b0000001; // "0"
        endcase
