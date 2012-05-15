
/* Analog and Digital Input and Output Server for MATLAB    */
/* adapted from */
/* Giampiero Campa, Copyright 2009 The MathWorks, Inc       */
/* Modified by Erik Cheever, Swarthmore College, 2012       */

/* This file is meant to be used with the MATLAB arduino IO 
   package, however, it can be used from the IDE environment
   (or any other serial terminal) by typing commands like:
   
   P40 : assigns digital pin #4 as input
   P51 : assigns digital pin #5 as output
   P=1 : assigns digital pin #13 as output   
   
   d2  : reads digital pin #2 (c) 
   d4  : reads digital pin #4 (e) 
   D=0 : sets digital pin #13 (n) low
   D=1 : sets digital pin #13 (n) high
   D51 : sets digital pin #5 (f) high
   D50 : sets digital pin #5 (f) low
   A92 : sets digital pin #9 (j) to  50=ascii(2) over 255
   A9z : sets digital pin #9 (j) to 122=ascii(z) over 255
   a0  : reads analog pin #0 (a) 
   a5  : reads analog pin #5 (f) 

   RD  : sets analog reference to DEFAULT
   RI  : sets analog reference to INTERNAL
   RE  : sets analog reference to EXTERNAL
   
   S1z : sets servo #1 to 122=ascii(z) out of 250
   S>(ascii(252)) : update servos
   S=1 : sets LED on servo board.
     
   ??  : returns script type (1 = E5Shield)   */

#include <Wire.h>

#define UPDATESERVOS  14

boolean inString(String s, char c);  // function declaration
  
void setup() {
  /* Make sure all pins are put in high impedence state and 
     that their registers are set as low before doing anything.
     This puts the board in a known (and harmless) state     */
  int i;
  for (i=0;i<20;i++) {
    pinMode(i,INPUT);
    digitalWrite(i,0);
  }
  Serial.begin(115200);     // initialize serial 
  Wire.begin();                          
}

void loop() {  
  // variables declaration and initialization 
  static int  pin = 13;    // generic pin or servo number

  int  val =  0;    // generic value read from serial 
  int  agv =  0;    // generic analog value
  int  dgv =  0;    // generic digital value

  enum myStates {  // These are the state in the state machine.
    WAITING,       // Default mode, do nothing
    PINMODE,       // Get pin #
    PINSET,        // Set pin mode
    DIGITALIN,     // Read pin value
    DIGITALOUT,    // Get pin #
    DIGITALSET,    // Set pin high or low
    ANALOGIN,      // Read pin value
    ANALOGOUT,     // Get pin #
    ANALOGSET,     // Set pin level (PWM)
    SERVOOUT,      // Get servo #
    SERVOSET,      
    // Set servo #
    VOLTAGEREF,    // Voltage reference (for A/D)
    SCRIPTQUERY  // Script Query
  } static state = WAITING;
  
  const String vpins = "23456789:;<=";   // Valid pin codes for I/O
  const String apins = "0123";           // Valid pin codes for analog in
  const String vsrvs = "01234567=>";      // Valid servo values

  /* The following instruction constantly checks if anything 
     is available on the serial port. Nothing gets executed in
     the loop if nothing is available to be read, but as soon 
     as anything becomes available, then the part coded after 
     the if statement (that is the real stuff) gets executed */
  if (Serial.available() > 0) {
    val = Serial.read();  // Read next character from serial port
    
    /* This part basically implements a state machine that   
       reads the serial port and makes just one transition 
       to a new state, depending on both the previous state 
       and the command that is read from the serial port. 
       Some commands need additional inputs from the serial 
       port, so they need 2 or 3 state transitions (each one
       happening as soon as anything new is available from 
       the serial port) to be fully executed. After a command 
       is fully executed the state returns to its initial 
       value state=WAITING                                    */
    switch (state) {		
      // ****************** WAITING ****************************
      case WAITING:     
        switch (val) {
          case 'P':  state=PINMODE;      break;
          case 'd':  state=DIGITALIN;    break;
          case 'D':  state=DIGITALOUT;   break;
          case 'a':  state=ANALOGIN;     break;
          case 'A':  state=ANALOGOUT;    break;
          case 'S':  state=SERVOOUT;     break;
          case 'R':  state-VOLTAGEREF;   break;
          case '?':  state=SCRIPTQUERY;  break;
        }
        break;
        
      //********************** Pin Mode ************************
      case PINMODE:
        if (inString(vpins,val)) {      // pin # is '0' + pin
            pin=val-'0';                // calculate pin
            state=PINSET;               // next state (below)
        } 
        else state=WAITING; // if value is not a pin then WAIT 
        break; // state==PINMODE done
  
      case PINSET:
        /* the third received value indicates the value 0 or 1 */
        if (inString("01",val)) {
          if (val=='0') pinMode(pin,INPUT);  // Set pin mode
          else          pinMode(pin,OUTPUT);
        }
        state=WAITING; // Go back to WAIT
        break;         // // state==PINSET done
      
      //******************* DIGITAL INPUT *********************     
      case DIGITALIN:
        if (inString(vpins,val)) {   // pin # is '0' + pin
          pin=val-'0';               // calculate pin
          dgv=digitalRead(pin);      // perform Digital Input
          Serial.println(dgv);       // send value via serial
        }
        state = WAITING;             // Go back to WAIT
        break;                       // state==DIGITALIN done
      
      //******************* DIGITAL OUTPUT ********************     
      case DIGITALOUT:
        if (inString(vpins,val)) {   // pin # is '0' + pin
          pin=val-'0';               // calculate pin
          state=DIGITALSET;          // next state (below)
        } 
        else state=WAITING; // if value is not a pin then WAIT
        break; // state==DIGITALOUT done

      case DIGITALSET:
        if (inString("01",val)) {  // 3rd received value is 0 or 1
          if (val=='0') digitalWrite(pin,0);  // Set pin level
          else          digitalWrite(pin,1);
        }
        state=WAITING;              // Go back to WAIT
        break;                      // state==DIGITALSET done

      //******************* ANALOG INPUT **********************     
      case ANALOGIN:
        if (inString("abcdef",val)) {
          pin=val-'0';               // calculate pin
          agv=analogRead(pin);       // perform Analog Input
  	  Serial.println(agv);       // send value via serial
        }
        state = WAITING;             // Go back to WAIT
        break; // state==ANALOGIN is done

      //******************* ANALOG OUTPUT *********************     
      case ANALOGOUT:
        if (inString(vpins,val)) {   // pin # is '0' + pin
          pin=val-'0';               // calculate pin
          state = ANALOGSET;         // next state (below)
        }
        else state = WAITING;        // Go back to WAIT
        break; // state==ANALOGOUT is done

      case ANALOGSET:
        analogWrite(pin,val);        // perform Analog Output
        state = WAITING;             // Go back to WAIT
        break; // state==ANALOGSET is done
           
      //******************** SERVO OUTPUT *********************     
      case SERVOOUT:
        if (inString(vsrvs,val)) {   // servo # is '0' + pin
          pin=val-'0';               // calculate servo #
          state = SERVOSET;          // next state (below)
        }
        else state = WAITING;        // Go back to WAIT
        break; // state==SERVOOUT is done

      case SERVOSET:
        Wire.beginTransmission(0xC2);   // 0xC2 is servo controller
        Wire.write(pin);                // Write Servo #
        Wire.write(val);                // Write Servo Value
        Wire.endTransmission();
        state = WAITING;                // Go back to WAIT
        break; // state==SERVOSET is done
           
      //******************* VOLTAGE REFERENCE ******************     
      case VOLTAGEREF:
        switch (val) {
          case 'D':  analogReference(DEFAULT);    break;        
          case 'I':  analogReference(INTERNAL);   break;        
          case 'E':  analogReference(EXTERNAL);   break;        
          default:  break;
        } 
        state = WAITING;             // Go back to WAIT
        break; // state==VOTLTAGEREGF is done

      //******************* SCRIPT QUERY *************************     
      case SCRIPTQUERY:
        if (val=='?') Serial.println(1);
        state = WAITING;             // Go back to WAIT
        break; // state==SCRIPTQUERY is done

      //******************* UNRECOGNIZED STATE *******************     
      default: state = WAITING;   // Go back to WAIT
      
    } // end switch on state s
  } // end if serial available  
} // end loop statement

// Function returns true if char "c" is in string "s"
boolean inString(String s, char c) {
  return (s.indexOf(c) != -1);
}
