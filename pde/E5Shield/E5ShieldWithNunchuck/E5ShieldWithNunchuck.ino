
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

#define nchckAdd 0x52

boolean inString(String s, char c);  // function declaration

uint8_t outbuf[6]; // array to store arduino output
int cnt = 0;
int ledPin = 13;
int nunchIn = 0;  // Shows whether nunchuck has been initialized
  
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
  delay(1000);
  Wire.beginTransmission(0xC2);   // 0xC2 is servo controller
  Wire.write(8);                  // Write to Servo 8 (connected to an LED)
  Wire.write(251);                // Assign Servo value to 251, turning the LED on
  Wire.endTransmission();
  delay(300);                     // wait 3 msec
  Wire.beginTransmission(0xC2);
  Wire.write(8);
  Wire.write((byte)0x00);         // turn LED off (by setting Servo 8 to value 0), this
  Wire.endTransmission();         // flashing LED shows that there is communication
}                                 // between the computer and the board

void
nunchuck_init ()
{
  pinMode(ledPin, OUTPUT);
//  Serial.print ("\nStarting setup");
  Wire.begin ();		// join i2c bus with address 0x52
  digitalWrite (ledPin, HIGH);	// sets the LED on
  delay(100);
  Wire.beginTransmission (nchckAdd);	// transmit to device 0x52
  Wire.write ((byte)0xF0);		// sends memory address
  Wire.write ((byte)0x55);		// sends sent a zero.  
//  Wire.write ((byte)0x40);		// sends memory address
//  Wire.write ((byte)0x00);		// sends sent a zero.  
  Wire.endTransmission ();	        // stop transmitting
  digitalWrite (ledPin, LOW);	        // sets the LED off
//  Serial.print ("... Done.\n");
// indicates that nunchuck has been initialized any subsequent time nunchuck state is entered
  nunchIn = 1;
  delay(200);
}

void
send_zero ()
{
  Wire.beginTransmission (nchckAdd);	// transmit to device 0x52
  Wire.write ((byte)0x00);		// sends one byte
  Wire.endTransmission ();	// stop transmitting
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
    SERVOSET,      // Set servo #
    VOLTAGEREF,    // Voltage reference (for A/D)
    SCRIPTQUERY,    // Script Query
    NUNCHUCKIN     // Read array of nunchuck values
  } static state = WAITING;

  const String vpins = "23456789:;<=";   // Valid pin codes for I/O
  const String apins = "0123";           // Valid pin codes for analog in
  const String vsrvs = "012345678";     // Valid servo values

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
          case 'n':  state=NUNCHUCKIN;   break;
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
        if (inString(apins,val)) {
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
        
      //******************** NUNCHUCK INPUT **********************
      case NUNCHUCKIN:
        // send the initialization handshake if first time nunchuck state entered
        if (nunchIn==0) nunchuck_init ();
        Wire.requestFrom (nchckAdd, 6);  // request data from nunchuck
        while (Wire.available ())
          {
      //      outbuf[cnt] = nunchuk_decode_byte (Wire.read ());	// receive byte as an integer
//            Wire.read();
//            delay(200);
            outbuf[cnt] = Wire.read();
            digitalWrite (ledPin, HIGH);	// sets the LED on
            cnt++;
          };
      
        // If we did not recieve the 6 bytes, then show an error
        if (cnt != 6) {
          Serial.print('.');
          state=WAITING; // go back to WAIT
          break;         // state==NUNCHUCKIN done
        }
        else {
          Serial.print(outbuf[0]); Serial.print('\t');  // x-axis value of joystick
          Serial.print(outbuf[1]); Serial.print('\t');  // y-axis value of joystick
          // Accelerometer data is 10 bits long, so first 8 bits are read
          // and shifted over two places. The last two bits are then added
          // on from the outbuf[5] byte.
          // x-acceleration value
          Serial.print((outbuf[2]<<2)+((outbuf[5]>>2) & 3)); Serial.print('\t');
          // y-acceleration
          Serial.print((outbuf[3]<<2)+((outbuf[5]>>4) & 3)); Serial.print('\t');\
          // z-acceleration
          Serial.print((outbuf[4]<<2)+((outbuf[5]>>6) & 3)); Serial.print('\t');
          // byte outbuf[5] contains bits for z and c buttons
          // so we have to check the last two bits of outbuf[5]
          int z=0; int c=0;
          if (outbuf[5] & 1) z=1; if (outbuf[5] & 2) c=1;
          Serial.print(c); Serial.print('\t');  // z button
          Serial.print(z); Serial.print('\n');  // c button
          
          cnt = 0;
          send_zero (); // send the request for next bytes
          digitalWrite (ledPin, LOW);	// sets the LED on
          delay (200);
    
          state=WAITING; // go back to WAIT
          break;         // state==NUNCHUCKIN done
        }

      //******************* UNRECOGNIZED STATE *******************     
      default: state = WAITING;   // Go back to WAIT
      
    } // end switch on state s
  } // end if serial available  
} // end loop statement

// Function returns true if char "c" is in string "s"
boolean inString(String s, char c) {
  return (s.indexOf(c) != -1);
}
