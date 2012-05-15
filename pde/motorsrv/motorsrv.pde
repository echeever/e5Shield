
/* Analog and Digital Input and Output Server for MATLAB    */
/* Giampiero Campa, Copyright 2009 The MathWorks, Inc       */

/* This file is meant to be used with the MATLAB arduino IO 
   package, however, it can be used from the IDE environment
   (or any other serial terminal) by typing commands like:
   
   0e0   : assigns digital pin #4 (e) as input
   0f1   : assigns digital pin #5 (f) as output
   0n1   : assigns digital pin #13 (n) as output   
   
   1c    : reads digital pin #2 (c) 
   1e    : reads digital pin #4 (e) 
   2n0   : sets digital pin #13 (n) low
   2n1   : sets digital pin #13 (n) high
   2f1   : sets digital pin #5 (f) high
   2f0   : sets digital pin #5 (f) low
   4j2   : sets digital pin #9 (j) to  50=ascii(2) over 255
   4jz   : sets digital pin #9 (j) to 122=ascii(z) over 255
   3a    : reads analog pin #0 (a) 
   3f    : reads analog pin #5 (f) 

   5a    : reads status (attached/detached) of servo #1
   5b    : reads status (attached/detached) of servo #2
   6a1   : attaches servo #1
   8az   : moves servo #1 of 122 degrees (122=ascii(z))
   7a    : reads servo #1 angle
   6a0   : detaches servo #1

   A1z   : sets speed of motor #1 to 122 over 255  (122=ascii(z))
   A4A   : sets speed of motor #4 to 65 over 255 (65=ascii(A))
   B1f   : runs motor #1 forward (f=forward)
   B4b   : runs motor #1 backward (b=backward)
   B1r   : releases motor #1 (r=release)

   C12   : sets speed of stepper motor #1 to 50 rpm  (50=ascii(2))
   C2Z   : sets speed of stepper motor #2 to 90 rpm  (90=ascii(Z))
   D1fsz : does 122 steps on motor #1 forward in single (s) mode 
   D1biA : does 65 steps on motor #1 backward in interleave (i) mode 
   D2fdz : does 122 steps on motor #1 forward in double (d) mode 
   D2bmA : does 65 steps on motor #2 backward in microstep (m) mode 
   D1r   : releases motor #1 (r=release)
   D2r   : releases motor #2 (r=release)

   R0    : sets analog reference to DEFAULT
   R1    : sets analog reference to INTERNAL
   R2    : sets analog reference to EXTERNAL
  
   99    : returns script type (1 basic, 2 motor, 3 general) */

#include <AFMotor.h>
#include <Servo.h>

/* define internal for the MEGA as 1.1V (as as for the 328)  */
#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
#define INTERNAL INTERNAL1V1
#endif

/* create and initialize servos                              */
Servo servo1;
Servo servo2;

/* create and initialize motors                              */
AF_Stepper stm1(200, 1);
AF_Stepper stm2(200, 2);
AF_DCMotor dcm1(1, MOTOR12_64KHZ); // create motor #1, 64KHz pwm
AF_DCMotor dcm2(2, MOTOR12_64KHZ); // create motor #2, 64KHz pwm
AF_DCMotor dcm3(3, MOTOR12_64KHZ); // create motor #3, 64KHz pwm
AF_DCMotor dcm4(4, MOTOR12_64KHZ); // create motor #4, 64KHz pwm

void setup() {
  /* initialize serial                                       */
  Serial.begin(115200);
}


void loop() {
  
  /* variables declaration and initialization                */
  
  static int  s   = -1;    /* state                          */
  static int  pin = 13;    /* generic pin number             */
  static int  srv =  2;    /* generic servo number           */
  static int  dcm =  4;    /* generic dc motor number        */

  static int  stm =  2;    /* generic stepper motor number   */
  static int  dir =  0;    /* direction (stepper)            */
  static int  sty =  0;    /* style (stepper)                */

  int  val =  0;           /* generic value read from serial */
  int  agv =  0;           /* generic analog value           */
  int  dgv =  0;           /* generic digital value          */

  /* The following instruction constantly checks if anything 
     is available on the serial port. Nothing gets executed in 
     the loop if nothing is available to be read, but as soon 
     as anything becomes available, then the part coded after 
     the if statement (that is the real stuff) gets executed */

  if (Serial.available() >0) {

    /* whatever is available from the serial is read here    */
    val = Serial.read();
    
    /* This part basically implements a state machine that 
       reads the serial port and makes just one transition 
       to a new state, depending on both the previous state 
       and the command that is read from the serial port. 
       Some commands need additional inputs from the serial 
       port, so they need 2 or 3 state transitions (each one
       happening as soon as anything new is available from 
       the serial port) to be fully executed. After a command 
       is fully executed the state returns to its initial 
       value s=-1                                            */

    switch (s) {
		
    
      /* s=-1 means NOTHING RECEIVED YET ******************* */
      case -1:      

      /* calculate next state when s=-1                      */
      if (val>47 && val<90) {
	  /* the first received value indicates the mode       
           49 is ascii for 1, ... 90 is ascii for Z          
           s=0 is change-pin mode
           s=10 is DI;  s=20 is DO;  s=30 is AI;  s=40 is AO; 
           s=50 is servo status; s=60 is aervo attach/detach;  
           s=70 is servo read;   s=80 is servo write         
           s=90 is query script type (1 basic, 2 motor)      
           s=170 is dc motor set speed 
           s=180 is dc motor run/release         
           s=190 is stepper motor set speed 
           s=200 is stepper motor run/release         
           s=340 is change analog reference         
                                                             */
        s=10*(val-48);
      }
      
      /* the following statements are needed to handle 
         unexpected first values coming from the serial (if 
         the value is unrecognized then it defaults to s=-1) */
      if ((s>90 && s<170) || (s>200 && s!=340)) {
        s=-1;
      }
      
      /* the break statements gets out of the switch-case, so 
      /* we go back to line 97 and wait for new serial data  */
      break; /* s=-1 (initial state) taken care of           */
	  
     
      /* s=0 or 1 means CHANGE PIN MODE                      */
      
      case 0:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('t')=116, pin 19    */
      if (val>98 && val<117) {
        pin=val-97;                /* calculate pin          */
        s=1; /* next we will need to get 0 or 1 from serial  */
      } 
      else {
        s=-1; /* if value is not a pin then return to -1     */
      }
      break; /* s=0 taken care of                            */


      case 1:
      /* the third received value indicates the value 0 or 1 */ 
      if (val>47 && val<50) {
        /* set pin mode                                      */
        if (val==48) {
          pinMode(pin,INPUT);
        }
        else {
          pinMode(pin,OUTPUT);
        }
      }
      s=-1;  /* we are done with CHANGE PIN so go to -1      */
      break; /* s=1 taken care of                            */
      

      /* s=10 means DIGITAL INPUT ************************** */
      
      case 10:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('t')=116, pin 19    */
      if (val>98 && val<117) {
        pin=val-97;                /* calculate pin          */
        dgv=digitalRead(pin);      /* perform Digital Input  */
        Serial.println(dgv);       /* send value via serial  */
      }
      s=-1;  /* we are done with DI so next state is -1      */
      break; /* s=10 taken care of                           */
      

      /* s=20 or 21 means DIGITAL OUTPUT ******************* */
      
      case 20:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('t')=116, pin 19    */
      if (val>98 && val<117) {
        pin=val-97;                /* calculate pin          */
        s=21; /* next we will need to get 0 or 1 from serial */
      } 
      else {
        s=-1; /* if value is not a pin then return to -1     */
      }
      break; /* s=20 taken care of                           */

      case 21:
      /* the third received value indicates the value 0 or 1 */
      if (val>47 && val<50) {
        dgv=val-48;                /* calculate value        */
	digitalWrite(pin,dgv);     /* perform Digital Output */
      }
      s=-1;  /* we are done with DO so next state is -1      */
      break; /* s=21 taken care of                           */

	
      /* s=30 means ANALOG INPUT *************************** */
      
      case 30:
      /* the second received value indicates the pin 
         from abs('a')=97, pin 0, to abs('f')=102, pin 6,     
         note that these are the digital pins from 14 to 19  
         located in the lower right part of the board        */
      if (val>96 && val<103) {
        pin=val-97;                /* calculate pin          */
        agv=analogRead(pin);       /* perform Analog Input   */
	Serial.println(agv);       /* send value via serial  */
      }
      s=-1;  /* we are done with AI so next state is -1      */
      break; /* s=30 taken care of                           */
	

      /* s=40 or 41 means ANALOG OUTPUT ******************** */
      
      case 40:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('t')=116, pin 19    */
      if (val>98 && val<117) {
        pin=val-97;                /* calculate pin          */
        s=41; /* next we will need to get value from serial  */
      }
      else {
        s=-1; /* if value is not a pin then return to -1     */
      }
      break; /* s=40 taken care of                           */


      case 41:
      /* the third received value indicates the analog value */
      analogWrite(pin,val);        /* perform Analog Output  */
      s=-1;  /* we are done with AO so next state is -1      */
      break; /* s=41 taken care of                           */

      
      /* s=50 means SERVO STATUS (ATTACHED/DETACHED) ******* */
      
      case 50:
      /* the second received value indicates the servo number
         from abs('a')=97, servo1, on top, uses digital pin 10
         to abs('b')=98, servo2, bottom, uses digital pin 9  */
      if (val>96 && val<99) {
        srv=val-96;                /* calculate srv          */
        if (srv==1) dgv=servo1.attached();    /* read status */
        if (srv==2) dgv=servo2.attached(); 
        Serial.println(dgv);       /* send value via serial  */
      }
      s=-1;  /* we are done with servo status so return to -1*/
      break; /* s=50 taken care of                           */
      

      /* s=60 or 61 means SERVO ATTACH/DETACH ************** */
      
      case 60:
      /* the second received value indicates the servo number
         from abs('a')=97, servo1, on top, uses digital pin 10
         to abs('b')=98, servo2, bottom, uses digital pin 9  */
      if (val>96 && val<99) {
        srv=val-96;                /* calculate srv          */
        s=61; /* next we will need to get 0 or 1 from serial */
      } 
      else {
        s=-1; /* if value is not a servo then return to -1   */
      }
      break; /* s=60 taken care of                           */


      case 61:
      /* the third received value indicates the value 0 or 1 
         0 for detach and 1 for attach                       */
      if (val>47 && val<50) {
        dgv=val-48;                /* calculate value        */
        if (srv==1) {
          if (dgv) servo1.attach(10);      /* attach servo 1 */
          else servo1.detach();            /* detach servo 1 */
        }
        if (srv==2) {
          if (dgv) servo2.attach(9);       /* attach servo 2 */
          else servo2.detach();            /* detach servo 2 */
        }
      }
      s=-1;  /* we are done with servo attach/detach so -1   */
      break; /* s=61 taken care of                           */


      /* s=70 means SERVO READ ***************************** */
      
      case 70:
      /* the second received value indicates the servo number
         from abs('a')=97, servo1, on top, uses digital pin 10
         to abs('b')=98, servo2, bottom, uses digital pin 9  */
      if (val>96 && val<99) {
        srv=val-96;                /* calculate servo number */
        if (srv==1) agv=servo1.read();         /* read value */
        if (srv==2) agv=servo2.read();  
	Serial.println(agv);       /* send value via serial  */
      }
      s=-1;  /* we are done with servo read so go to -1 next */
      break; /* s=70 taken care of                           */


      /* s=80 or 81 means SERVO WRITE   ******************** */
      
      case 80:
      /* the second received value indicates the servo number
         from abs('a')=97, servo1, on top, uses digital pin 10
         to abs('b')=98, servo2, bottom, uses digital pin 9  */
      if (val>96 && val<99) {
        srv=val-96;                /* calculate servo number */
        s=81; /* next we will need to get value from serial  */
      }
      else {
        s=-1; /* if value is not a servo then return to -1   */
      }
      break; /* s=80 taken care of                           */


      case 81:
      /* the third received value indicates the servo angle  */
      if (srv==1) servo1.write(val);          /* write value */
      if (srv==2) servo2.write(val);        
      s=-1;  /* we are done with servo write so go to -1 next*/
      break; /* s=81 taken care of                           */



      /* s=90 means Query Script Type (1 basic, 2 motor)     */
      case 90:
      if (val==57) { 
        /* if string sent is 99  send script type via serial */
        Serial.println(2);
      }
      s=-1;  /* we are done with this so next state is -1    */
      break; /* s=90 taken care of                           */



      /* s=170 or 171 means DC MOTOR SET SPEED  ************ */
      
      case 170:
      /* the second received value indicates the motor number
         from abs('1')=49, motor1, to abs('4')=52, motor4    */
      if (val>48 && val<53) {
        dcm=val-48;                /* calculate motor number */
        s=171; /* next we will need to get value from serial */
      }
      else {
        s=-1; /* if value is not a motor then return to -1   */
      }
      break; /* s=170 taken care of                          */


      case 171:
      /* the third received value indicates the motor speed  */
      if (dcm==1) dcm1.setSpeed(val);
      if (dcm==2) dcm2.setSpeed(val);
      if (dcm==3) dcm3.setSpeed(val);
      if (dcm==4) dcm4.setSpeed(val);            
      s=-1;  /* we are done with servo write so go to -1 next*/
      break; /* s=171 taken care of                          */



      /* s=180 or 181 means DC MOTOR RUN/RELEASE  ********** */
      case 180:
      /* the second received value indicates the motor number
         from abs('1')=49, motor1, to abs('4')=52, motor4    */
      if (val>48 && val<53) {
        dcm=val-48;                /* calculate motor number */
        s=181; /* next we will need to get value from serial */
      }
      else {
        s=-1; /* if value is not a motor then return to -1   */
      }
      break; /* s=180 taken care of                          */

      case 181:
      /* the third received value indicates forward, backward,
         release, with characters 'f', 'b', 'r', respectively,
         that have ascii codes 102, 98 and 114               */
      if (dcm==1) {
        if (val==102) dcm1.run(FORWARD);
        if (val==98)  dcm1.run(BACKWARD);
        if (val==114) dcm1.run(RELEASE);
      }
      if (dcm==2) {
        if (val==102) dcm2.run(FORWARD);
        if (val==98)  dcm2.run(BACKWARD);
        if (val==114) dcm2.run(RELEASE);
      }
      if (dcm==3) {
        if (val==102) dcm3.run(FORWARD);
        if (val==98)  dcm3.run(BACKWARD);
        if (val==114) dcm3.run(RELEASE);
      }
      if (dcm==4) {
        if (val==102) dcm4.run(FORWARD);
        if (val==98)  dcm4.run(BACKWARD);
        if (val==114) dcm4.run(RELEASE);
      }
      s=-1;  /* we are done with motor run so go to -1 next  */
      break; /* s=181 taken care of                          */



      /* s=190 or 191 means STEPPER MOTOR SET SPEED  ******* */
      
      case 190:
      /* the second received value indicates the motor number
         from abs('1')=49, motor1, to abs('2')=50, motor4    */
      if (val>48 && val<51) {
        stm=val-48;                /* calculate motor number */
        s=191; /* next we will need to get value from serial */
      }
      else {
        s=-1; /* if value is not a stepper then return to -1 */
      }
      break; /* s=190 taken care of                          */


      case 191:
      /* the third received value indicates the speed in rpm */ 
      if (stm==1) stm1.setSpeed(val);
      if (stm==2) stm2.setSpeed(val);
            
      s=-1;  /* we are done with set speed so go to -1 next  */
      break; /* s=191 taken care of                          */



      /* s=200 or 201 means STEPPER MOTOR STEP/RELEASE  **** */
      
      case 200:
      /* the second received value indicates the motor number
         from abs('1')=49, motor1, to abs('2')=50, motor4    */
      if (val>48 && val<51) {
        stm=val-48;                /* calculate motor number */
        s=201;            /* we still need stuff from serial */
      }
      else {
        s=-1; /* if value is not a motor then return to -1   */
      }
      break; /* s=200 taken care of                          */


      case 201:
      /* the third received value indicates forward, backward,
         release, with characters 'f', 'b', 'r', respectively,
         that have ascii codes 102, 98 and 114               */
      switch (val) {
        
        case 102:
        dir=FORWARD;
        s=202;
        break;        
        
        case 98:
        dir=BACKWARD;
        s=202;
        break;        
        
        case 114: /* release and return to -1 here           */
        if (stm==1) stm1.release();
        if (stm==2) stm2.release();
        s=-1;        
        break;
        
        default:
        s=-1;  /* unrecognized  character, go to -1          */
        break;
      } 
      break; /* s=201 taken care of                          */


      case 202:
      /* the third received value indicates the style, single,
         double, interleave, microstep, 's', 'd', 'i', 'm'
         that have ascii codes 115,100,105 and 109           */
      switch (val) {
        
        case 115:
        sty=SINGLE;
        s=203;
        break;
        
        case 100:
        sty=DOUBLE;
        s=203;
        break;
        
        case 105:
        sty=INTERLEAVE;
        s=203;
        break;
        
        case 109:
        sty=MICROSTEP;
        s=203;
        break;
        
        default:
        s=-1;  /* unrecognized  character, go to -1          */
        break;
      } 
      break; /* s=201 taken care of                          */


      case 203:
      /* the last received value indicates the number of 
         steps,                                              */
      if (stm==1) stm1.step(val,dir,sty);  /* do the steps   */
      if (stm==2) stm2.step(val,dir,sty);
      s=-1;        /* we are done with step so go to -1 next */
      break;       /* s=203 taken care of                    */
      

      
      /* s=340 or 341 means ANALOG REFERENCE *************** */
      
      case 340:
      /* the second received value indicates the reference,
         which is encoded as is 0,1,2 for DEFAULT, INTERNAL  
         and EXTERNAL, respectively                          */
         
      switch (val) {
        
        case 48:
        analogReference(DEFAULT);
        break;        
        
        case 49:
        analogReference(INTERNAL);
        break;        
                
        case 50:
        analogReference(EXTERNAL);
        break;        
        
        default:                 /* unrecognized, no action  */
        break;
      } 

      s=-1;  /* we are done with this so next state is -1    */
      break; /* s=341 taken care of                          */



      /* ******* UNRECOGNIZED STATE, go back to s=-1 ******* */
      
      default:
      /* we should never get here but if we do it means we 
         are in an unexpected state so whatever is the second 
         received value we get out of here and back to s=-1  */
      
      s=-1;  /* go back to the initial state, break unneeded */



    } /* end switch on state s                               */

  } /* end if serial available                               */
  
} /* end loop statement                                      */

