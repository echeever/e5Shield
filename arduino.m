classdef arduino < handle
    
    % This class defines an "arduino" object
    % Giampiero Campa, Aug 2010, Copyright 2009 The MathWorks, Inc.
    
    properties (SetAccess=private,GetAccess=private)
        aser   % Serial Connection
        pins   % Pin Status Vector
        srvs   % Servo Status Vector
        mspd   % Motor Speed Status
        sspd   % Servo Speed Status
        mots   % Motor Server Running on the Arduino Board
    end
    
    properties (Hidden=true)
        chks = false;  % Checks serial connection before every operation
        chkp = true;   % Checks parameters before every operation
    end
    
    methods
        
        % constructor, connects to the board and creates an arduino object
        function a=arduino(comPort)
            
            % check nargin
            if nargin<1,
                comPort='DEMO';
                disp('Note: a DEMO connection will be created');
                disp('Use a the com port, e.g. ''COM5'' as input argument to connect to the real board');
            end
            
            % check port
            if ~ischar(comPort),
                error('The input argument must be a string, e.g. ''COM8'' ');
            end
            
            % check if we are already connected
            if isa(a.aser,'serial') && isvalid(a.aser) && strcmpi(get(a.aser,'Status'),'open'),
                disp(['It looks like Arduino is already connected to port ' comPort ]);
                disp('Delete the object to force disconnection');
                disp('before attempting a connection to a different port.');
                return;
            end
            
            % check whether serial port is currently used by MATLAB
            if ~isempty(instrfind({'Port'},{comPort})),
                disp(['The port ' comPort ' is already used by MATLAB']);
                disp(['If you are sure that Arduino is connected to ' comPort]);
                disp('then delete the object, execute:');
                disp(['  delete(instrfind({''Port''},{''' comPort '''}))']);
                disp('to delete the port, disconnect the cable, reconnect it,');
                disp('and then create a new arduino object');
                error(['Port ' comPort ' already used by MATLAB']);
            end
            
            % define serial object
            a.aser=serial(comPort,'BaudRate',115200);
            
            % connection
            if strcmpi(get(a.aser,'Port'),'DEMO'),
                % handle demo mode
                
                fprintf(1,'Demo mode connection .');
                for i=1:5,
                    fprintf(1,'.');
                    pause(1);
                end
                fprintf(1,'\n');
                pause(1);
                
                % chk is equal to 3, (general server running)
                chk=3;
                
            else
                % actual connection
                
                % open port
                try
                    fopen(a.aser);
                catch ME,
                    disp(ME.message)
                    delete(a);
                    error(['Could not open port: ' comPort]);
                end
                
                % it takes several seconds before any operation could be attempted
                
                fprintf(1,'Attempting connection .');
                for i=1:7,
                    fprintf(1,'.');
                    pause(1);
                end
                fprintf(1,'\n');
                
                % query script type
                fwrite(a.aser,[57 57],'uchar');
                chk=fscanf(a.aser,'%d');
                
                % exit if there was no answer
                if isempty(chk)
                    delete(a);
                    error('Connection unsuccessful, please make sure that the Arduino is powered on, running either srv.pde, adiosrv.pde or mororsrv.pde, and that the board is connected to the indicated serial port. You might also try to unplug and re-plug the USB cable before attempting a reconnection.');
                end
                
            end
            
            % check returned value
            if chk==1,
                disp('Basic I/O Script detected !');
            elseif chk==2,
                disp('Motor Shield Script detected !');
            elseif chk==3,
                disp('General Script detected !');
            else
                delete(a);
                error('Unknown Script. Please make sure that either adiosrv.pde or motorsrv.pde are running on the Arduino');
            end
            
            % sets a.mots flag
            a.mots=chk-1;
            
            % set a.aser tag
            a.aser.Tag='ok';
            
            % initialize pin vector (-1 is unassigned, 0 is input, 1 is output)
            a.pins=-1*ones(1,19);
            
            % initialize servo vector (-1 is unknown, 0 is detached, 1 is attached)
            a.srvs=0*ones(1,2);
            
            % initialize motor vector (0 to 255 is the speed)
            a.mspd=0*ones(1,4);
            
            % initialize stepper vector (0 to 255 is the speed)
            a.sspd=0*ones(1,2);
            
            % notify successful installation
            disp('Arduino successfully connected !');
            
        end % arduino
        
        % distructor, deletes the object
        function delete(a)
            
            % if it is a serial, valid and open then close it
            if isa(a.aser,'serial') && isvalid(a.aser) && strcmpi(get(a.aser,'Status'),'open'),
                if ~isempty(a.aser.Tag),
                    try
                        % trying to leave it in a known unharmful state
                        for i=2:19,
                            a.pinMode(i,'output');
                            a.digitalWrite(i,0);
                            a.pinMode(i,'input');
                        end
                    catch ME
                        % disp but proceed anyway
                        disp(ME.message);
                        disp('Proceeding to deletion anyway');
                    end
                    
                end
                fclose(a.aser);
            end
            
            % if it's an object delete it
            if isobject(a.aser),
                delete(a.aser);
            end
            
            
        end % delete
        
        % disp, displays the object
        function disp(a) % display
            if isvalid(a),
                if isa(a.aser,'serial') && isvalid(a.aser),
                    disp(['<a href="matlab:help arduino">arduino</a> object connected to ' a.aser.port ' port']);
                    if a.mots==2,
                        disp('General Shield Server running on the arduino board');
                        disp(' ');
                        a.servoStatus
                        a.motorSpeed
                        a.stepperSpeed
                        disp(' ');
                        disp('Servo Methods: <a href="matlab:help servoStatus">servoStatus</a> <a href="matlab:help servoAttach">servoAttach</a> <a href="matlab:help servoDetach">servoDetach</a> <a href="matlab:help servoRead">servoRead</a> <a href="matlab:help servoWrite">servoWrite</a>');
                        disp('DC Motors and Stepper Methods: <a href="matlab:help motorSpeed">motorSpeed</a> <a href="matlab:help motorRun">motorRun</a> <a href="matlab:help stepperSpeed">stepperSpeed</a> <a href="matlab:help stepperStep">stepperStep</a>');
                        disp(' ');
                        a.pinMode
                        disp(' ');
                        disp('Pin IO Methods: <a href="matlab:help pinMode">pinMode</a> <a href="matlab:help digitalRead">digitalRead</a> <a href="matlab:help digitalWrite">digitalWrite</a> <a href="matlab:help analogRead">analogRead</a> <a href="matlab:help analogWrite">analogWrite</a>');
                    elseif a.mots==1,
                        disp('Motor Shield Server running on the arduino board');
                        disp(' ');
                        a.servoStatus
                        a.motorSpeed
                        a.stepperSpeed
                        disp(' ');
                        disp('Servo Methods: <a href="matlab:help servoStatus">servoStatus</a> <a href="matlab:help servoAttach">servoAttach</a> <a href="matlab:help servoDetach">servoDetach</a> <a href="matlab:help servoRead">servoRead</a> <a href="matlab:help servoWrite">servoWrite</a>');
                        disp('DC Motors and Stepper Methods: <a href="matlab:help motorSpeed">motorSpeed</a> <a href="matlab:help motorRun">motorRun</a> <a href="matlab:help stepperSpeed">stepperSpeed</a> <a href="matlab:help stepperStep">stepperStep</a>');
                    else
                        disp('IO Server running on the arduino board');
                        disp(' ');
                        a.pinMode
                        disp(' ');
                        disp('Pin IO Methods: <a href="matlab:help pinMode">pinMode</a> <a href="matlab:help digitalRead">digitalRead</a> <a href="matlab:help digitalWrite">digitalWrite</a> <a href="matlab:help analogRead">analogRead</a> <a href="matlab:help analogWrite">analogWrite</a>');
                    end
                    disp(' ');
                else
                    disp('<a href="matlab:help arduino">arduino</a> object connected to an invalid serial port');
                    disp('Please delete the arduino object');
                    disp(' ');
                end
            else
                    disp('Invalid <a href="matlab:help arduino">arduino</a> object');
                    disp('Please clear the object and instantiate another one');
                    disp(' ');
            end
        end
        
        % pin mode, changes pin mode
        function pinMode(a,pin,str)
            
            % a.pinMode(pin,str); specifies the pin mode of a digital pins.
            % The first argument before the function name, a, is the arduino object.
            % The first argument, pin, is the number of the digital pin (2 to 19).
            % The second argument, str, is a string that can be 'input' or 'output',
            % Called with one argument, as a.pin(pin) it returns the mode of
            % the digital pin, called without arguments, prints the mode of all the
            % digital pins. Note that the digital pins from 0 to 13 are located on
            % the upper right part of the board, while the digital pins from 14 to 19
            % are better known as "analog input" pins and are located in the lower
            % right corner of the board.
            %
            % Examples:
            % a.pinMode(11,'output') % sets digital pin #11 as output
            % a.pinMode(10,'input')  % sets digital pin #10 as input
            % val=a.pinMode(10);     % returns the status of digital pin #10
            % a.pinMode(5);          % prints the status of digital pin #5
            % a.pinMode;             % prints the status of all pins
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin>3,
                    error('This function cannot have more than 3 arguments, object, pin and str');
                end
                
                % if pin argument is there check it
                if nargin>1,
                    errstr=arduino.checknum(pin,'pin number',2:19);
                    if ~isempty(errstr), error(errstr); end
                end
                
                % if str argument is there check it
                if nargin>2,
                    errstr=arduino.checkstr(str,'pin mode',{'input','output'});
                    if ~isempty(errstr), error(errstr); end
                end
                
            end
            
            % perform the requested action
            if nargin==3,
                
                % check a.aser for validity if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'valid');
                    if ~isempty(errstr), error(errstr); end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE PIN MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % assign value
                if lower(str(1))=='o', val=1; else val=0; end
                
                if strcmpi(get(a.aser,'Port'),'DEMO'),
                    % handle demo mode here
                    
                    % minimum digital output delay
                    pause(0.0014);
                    
                else
                    % do the actual action here
                    
                    % check a.aser for openness if a.chks is true
                    if a.chks,
                        errstr=arduino.checkser(a.aser,'open');
                        if ~isempty(errstr), error(errstr); end
                    end
                    
                    % send mode, pin and value
                    fwrite(a.aser,[48 97+pin 48+val],'uchar');
                    
                end
                
                % detach servo 1 or 2 if pins 10 or 9 are used
                if pin==10 || pin==9, a.servoDetach(11-pin); end
                
                % store 0 for input and 1 for output
                a.pins(pin)=val;
                
            elseif nargin==2,
                % print pin mode for the requested pin
                
                mode={'UNASSIGNED','set as INPUT','set as OUTPUT'};
                disp(['Digital Pin ' num2str(pin) ' is currently ' mode{2+a.pins(pin)}]);
                
            else
                % print pin mode for each pin
                
                mode={'UNASSIGNED','set as INPUT','set as OUTPUT'};
                for i=2:19;
                    disp(['Digital Pin ' num2str(i,'%02d') ' is currently ' mode{2+a.pins(i)}]);
                end
                
            end
            
        end % pinmode
        
        % digital read
        function val=digitalRead(a,pin)
            
            % val=a.digitalRead(pin); performs digital input on a given arduino pin.
            % The first argument before the function name, a, is the arduino object.
            % The argument pin, is the number of the digital pin (2 to 19)
            % where the digital input needs to be performed. Note that the digital pins
            % from 0 to 13 are located on the upper right part of the board, while the
            % digital pins from 14 to 19 are better known as "analog input" pins and
            % are located in the lower right corner of the board.
            %
            % Example:
            % val=a.digitalRead(4); % reads pin #4
            %
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=2,
                    error('Function must have the "pin" argument');
                end
                
                % check pin
                errstr=arduino.checknum(pin,'pin number',2:19);
                if ~isempty(errstr), error(errstr); end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM DIGITAL INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO'),
                % handle demo mode
                
                % minimum digital input delay
                pause(0.0074);
                
                % output 0 or 1 randomly
                val=round(rand);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode and pin
                fwrite(a.aser,[49 97+pin],'uchar');
                
                % get value
                val=fscanf(a.aser,'%d');
                
            end
            
        end % digitalread
        
        % digital write
        function digitalWrite(a,pin,val)
            
            % a.digitalWrite(pin,val); performs digital output on a given pin.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, pin, is the number of the digital pin (2 to 19)
            % where the digital output needs to be performed.
            % The third argument, val, is the value (either 0 or 1) for the output
            % Note that the digital pins from 0 to 13 are located on the upper right part
            % of the board, while the digital pins from 14 to 19 are better known as
            % "analog input" pins and are located in the lower right corner of the board.
            %
            % Examples:
            % a.digitalWrite(13,1); % sets pin #13 high
            % a.digitalWrite(13,0); % sets pin #13 low
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=3,
                    error('Function must have the "pin" and "val" arguments');
                end
                
                % check pin
                errstr=arduino.checknum(pin,'pin number',2:19);
                if ~isempty(errstr), error(errstr); end
                
                % check val
                errstr=arduino.checknum(val,'value',0:1);
                if ~isempty(errstr), error(errstr); end
                
                % get object name
                if isempty(inputname(1)), name='object'; else name=inputname(1); end
                
                % pin should be configured as output
                if a.pins(pin)~=1,
                    warning('MATLAB:Arduino:digitalWrite',['If digital pin ' num2str(pin) ' is set as input, digital output takes place only after using ' name' '.pinMode(' num2str(pin) ',''output''); ']);
                end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM DIGITAL OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO'),
                % handle demo mode
                
                % minimum digital output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode, pin and value
                fwrite(a.aser,[50 97+pin 48+val],'uchar');
                
            end
            
        end % digitalwrite
        
        % analog read
        function val=analogRead(a,pin)
            
            % val=a.analogRead(pin); Performs analog input on a given arduino pin.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, pin, is the number of the analog input pin (0 to 5)
            % where the analog input needs to be performed. The returned value, val,
            % ranges from 0 to 1023, with 0 corresponding to an input voltage of 0 volts,
            % and 1023 to a reference value that is typically 5 volts (this voltage can
            % be set up by the analogReference function). Therefore, assuming a range
            % from 0 to 5 V the resolution is .0049 volts (4.9 mV) per unit.
            % Note that the analog input pins 0 to 5 are also known as digital pins
            % from 14 to 19, and are located on the lower right corner of the board.
            % Specifically, analog input pin 0 corresponds to digital pin 14, and analog
            % input pin 5 corresponds to digital pin 19. Performing analog input does
            % not affect the digital state (high, low, digital input) of the pin.
            %
            % Example:
            % val=a.analogRead(0); % reads analog input pin # 0
            %
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=2,
                    error('Function must have the "pin" argument');
                end
                
                % check pin
                errstr=arduino.checknum(pin,'analog input pin number',0:5);
                if ~isempty(errstr), error(errstr); end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM ANALOG INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO'),
                % handle demo mode
                
                % minimum analog input delay
                pause(0.0074);
                
                % output a random value between 0 and 1023
                val=round(1023*rand);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode and pin
                fwrite(a.aser,[51 97+pin],'uchar');
                
                % get value
                val=fscanf(a.aser,'%d');
                
            end
            
        end % analogread
        
        % function analog write
        function analogWrite(a,pin,val)
            
            % a.analogWrite(pin,val); Performs analog output on a given arduino pin.
            % The first argument before the function name, a, is the arduino object.
            % The first argument, pin, is the number of the DIGITAL pin where the analog
            % (PWM) output needs to be performed. Allowed pins for AO are 3,5,6,9,10,11
            % The second argument, val, is the value from 0 to 255 for the level of
            % analog output. Note that the digital pins from 0 to 13 are located on the
            % upper right part of the board.
            %
            % Examples:
            % a.analogWrite(11,90); % sets pin #11 to 90/255
            % a.analogWrite(3,10); % sets pin #3 to 10/255
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=3,
                    error('Function must have the "pin" and "val" arguments');
                end
                
                % check pin
                errstr=arduino.checknum(pin,'pwm pin number',[3 5 6 9 10 11]);
                if ~isempty(errstr), error(errstr); end
                
                % check val
                errstr=arduino.checknum(val,'analog output level',0:255);
                if ~isempty(errstr), error(errstr); end
                
                % get object name
                if isempty(inputname(1)), name='object'; else name=inputname(1); end
                
                % pin should be configured as output
                if a.pins(pin)~=1,
                    warning('MATLAB:Arduino:analogWrite',['If digital pin ' num2str(pin) ' is set as input, pwm output takes place only after using ' name '.pinMode(' num2str(pin) ',''output''); ']);
                end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM ANALOG OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO'),
                % handle demo mode
                
                % minimum analog output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode, pin and value
                fwrite(a.aser,[52 97+pin val],'uchar');
                
            end
            
        end % analogwrite
        
        % servo attach
        function servoAttach(a,num)
            
            % a.servoAttach(num); attaches a servo to the corresponding pwm pin.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the servo, which can be either 1
            % (top servo, uses digital pin 10 for pwm), or 2 (bottom servo, uses digital
            % pin 9 for pwm).
            %
            % Example:
            % a.servoAttach(1); % attach servo #1
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=2,
                    error('Function must have the "num" argument');
                end
                
                % check servo number
                errstr=arduino.checknum(num,'servo number',[1 2]);
                if ~isempty(errstr), error(errstr); end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ATTACH SERVO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                % handle demo mode
                
                % minimum digital output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode, num and value (1 for attach)
                fwrite(a.aser,[54 96+num 48+1],'uchar');
                
            end
            
            % store the servo statur
            a.srvs(num)=1;
            
            % update pin status to unassigned
            a.pins(11-num)=-1;
            
        end % servoattach
        
        % servo detach
        function servoDetach(a,num)
            
            % a.servoDetach(num); detaches a servo from its corresponding pwm pin.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the servo, which can be either 1
            % (top servo, uses digital pin 10 for pwm), or 2 (bottom servo, uses digital
            % pin 9 for pwm).
            %
            % Examples:
            % a.servoDetach(1); % detach servo #1
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=2,
                    error('Function must have the "num" argument');
                end
                
                % check servo number
                errstr=arduino.checknum(num,'servo number',[1 2]);
                if ~isempty(errstr), error(errstr); end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%% DETACH SERVO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                % handle demo mode
                
                % minimum digital output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode, num and value (0 for detach)
                fwrite(a.aser,[54 96+num 48+0],'uchar');
                
            end
            
            a.srvs(num)=0;
            
        end % servodetach
        
        % servo status
        function val=servoStatus(a,num)
            
            % a.servoStatus(num); Reads the status of a servo (attached/detached)
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the servo, which can be either 1
            % (top servo, uses digital pin 10 for pwm), or 2 (bottom servo,
            % uses digital pin 9 for pwm).
            % The returned value is either 1 (servo attached) or 0 (servo detached),
            % Called without output arguments, the function prints a string specifying
            % the status of the servo. Called without input arguments, the function
            % either returns the status vector or prints the status of each servo.
            %
            % Examples:
            % val=a.servoStatus(1); % return the status of servo #1
            % a.servoStatus(1); % prints the status of servo #1
            % a.servoStatus; % prints the status of both servos
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check nargin if a.chkp is true
            if a.chkp,
                if nargin>2,
                    error('Function cannot have more than one argument (servo number) beyond the object name');
                end
            end
            
            % with no arguments calls itself recursively for both servos
            if nargin==1,
                if nargout>0,
                    val(1)=a.servoStatus(1);
                    val(2)=a.servoStatus(2);
                    return
                else
                    a.servoStatus(1);
                    a.servoStatus(2);
                    return
                end
            end
            
            % check servo number if a.chkp is true
            if a.chkp,
                errstr=arduino.checknum(num,'servo number',[1 2]);
                if ~isempty(errstr), error(errstr); end
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ASK SERVO STATUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                % handle demo mode
                
                % minimum digital input delay
                pause(0.0074);
                
                % gets value from the servo state vector
                val=a.srvs(num);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode and num
                fwrite(a.aser,[53 96+num],'uchar');
                
                % get value
                val=fscanf(a.aser,'%d');
                
            end
            
            % updates the servo state vector
            a.srvs(num)=val;
            
            if nargout==0,
                str={'DETACHED','ATTACHED'};
                disp(['Servo ' num2str(num) ' is ' str{1+val}]);
                clear val
                return
            end
            
        end % servostatus
        
        % servo read
        function val=servoRead(a,num)
            
            % val=a.servoRead(num); reads the angle of a given servo.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the servo, which can be either
            % 1 (top servo, uses digital pin 10 for pwm), or 2 (bottom servo, uses
            % digital pin 9 for pwm). The returned value is the angle in degrees,
            % typically from 0 to 180. Returns Random results if motor shield is not
            % connected.
            %
            % Example:
            % val=a.servoRead(1); % reads angle from servo #1
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=2,
                    error('Function must have the servo number argument');
                end
                
                % check servo number
                errstr=arduino.checknum(num,'servo number',[1 2]);
                if ~isempty(errstr), error(errstr); end
                
                % check status
                if a.srvs(num)~=1,
                    error(['Servo ' num2str(num) ' is not attached, please use a.servoAttach(' num2str(num) ') to attach it']);
                end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% READ SERVO ANGLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                % handle demo mode
                
                % minimum analog input delay
                pause(0.0074);
                
                % output a random value between 0 and 180
                val=round(180*rand);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode and num
                fwrite(a.aser,[55 96+num],'uchar');
                
                % get value
                val=fscanf(a.aser,'%d');
                
            end
            
        end % servoread
        
        % servo write
        function servoWrite(a,num,val)
            
            % a.servoWrite(num,val); writes an angle on a given servo.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the servo, which can be
            % either 1 (top servo, uses digital pin 10 for pwm), or 2 (bottom servo,
            % uses digital pin 9 for pwm). The third argument is the angle in degrees,
            % typically from 0 to 180. Returns Random results if motor shield is not
            % connected.
            %
            % Example:
            % a.servoWrite(1,45); % rotates servo #1 of 45 degrees
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=3,
                    error('Function must have the servo number and angle arguments');
                end
                
                % check servo number
                errstr=arduino.checknum(num,'servo number',[1 2]);
                if ~isempty(errstr), error(errstr); end
                
                % check angle value
                errstr=arduino.checknum(val,'angle',0:180);
                if ~isempty(errstr), error(errstr); end
                
                % check status
                if a.srvs(num)~=1,
                    error(['Servo ' num2str(num) ' is not attached, please use a.servoAttach(' num2str(num) ') to attach it']);
                end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% WRITE ANGLE TO SERVO %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                % handle demo mode
                
                % minimum analog output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode, num and value
                fwrite(a.aser,[56 96+num val],'uchar');
                
            end
            
        end % servowrite
        
        % motor speed
        function val=motorSpeed(a,num,val)
            
            % val=a.motorSpeed(num,val); sets the speed of a DC motor.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the motor, which can go
            % from 1 to 4 (the motor ports are numbered on the motor shield).
            % The third argument is the speed from 0 (stopped) to 255 (maximum), note
            % that depending on the motor speeds of at least 60 might be necessary
            % to actually run it. Called with one argument, as a.motorSpeed(num),
            % it returns the speed at which the given motor is set to run. If there
            % is no output argument it prints the speed of the motor.
            % Called without arguments, itprints the speed of each motor.
            % Note that you must use the command a.motorRun to actually run
            % the motor at the given speed, either forward or backwards.
            % Returns Random results if motor shield is not connected.
            %
            % Examples:
            % a.motorSpeed(4,200)      % sets speed of motor 4 as 200/255
            % val=a.motorSpeed(1);     % returns the speed of motor 1
            % a.motorSpeed(3);         % prints the speed of motor 3
            % a.motorSpeed;            % prints the speed of all motors
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin>3,
                    error('This function cannot have more than 3 arguments, arduino object, motor number and speed');
                end
                
                % if motor number is there check it
                if nargin>1,
                    errstr=arduino.checknum(num,'motor number',1:4);
                    if ~isempty(errstr), error(errstr); end
                end
                
                % if speed argument is there check it
                if nargin>2,
                    errstr=arduino.checknum(val,'speed',0:255);
                    if ~isempty(errstr), error(errstr); end
                end
                
            end
            
            % perform the requested action
            if nargin==3,
                
                % check a.aser for validity if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'valid');
                    if ~isempty(errstr), error(errstr); end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%% SET MOTOR SPEED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                    % handle demo mode
                    
                    % minimum analog output delay
                    pause(0.0014);
                    
                else
                    
                    % check a.aser for openness if a.chks is true
                    if a.chks,
                        errstr=arduino.checkser(a.aser,'open');
                        if ~isempty(errstr), error(errstr); end
                    end
                    
                    % send mode, num and value
                    fwrite(a.aser,[65 48+num val],'uchar');
                    
                end
                
                % store speed value in case it needs to be retrieved
                a.mspd(num)=val;
                
                % clear val if is not needed as output
                if nargout==0,
                    clear val;
                end
                
            elseif nargin==2,
                
                if nargout==0,
                    % print speed value
                    disp(['The speed of motor number ' num2str(num) ' is set to: ' num2str(a.mspd(num)) ' over 255']);
                else
                    % return speed value
                    val=a.mspd(num);
                end
                
            else
                
                if nargout==0,
                    % print speed value for each motor
                    for num=1:4,
                        disp(['The speed of motor number ' num2str(num) ' is set to: ' num2str(a.mspd(num)) ' over 255']);
                    end
                else
                    % return speed values
                    val=a.mspd;
                end
                
            end
            
        end % motorspeed
        
        % motor run
        function motorRun(a,num,dir)
            
            % a.motorRun(num,dir); runs a given DC motor.
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the motor, which can go
            % from 1 to 4 (the motor ports are numbered on the motor shield).
            % The third argument, dir, should be a string that can be 'forward' 
            % (runs the motor forward) 'backward' (runs the motor backward) 
            % or 'release', (stops the motor). Note that since version 3.0, 
            % a +1 is interpreted as 'forward', a 0 is interpreted 
            % as 'release', and a -1 is interpreted as 'backward'.  
            % Returns Random results if motor shield is not connected.
            %
            % Examples:
            % a.motorRun(1,'forward');      % runs motor 1 forward
            % a.motorRun(3,'backward');     % runs motor 3 backward
            % a.motorRun(2,-1);             % runs motor 2 backward
            % a.motorRun(1,'release');      % releases motor 1
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=3,
                    error('Function must have 3 arguments, object, motor number and direction');
                end
                
                % check motor number
                errstr=arduino.checknum(num,'motor number',1:4);
                if ~isempty(errstr), error(errstr); end
                
            end
            
            % allows for direction to be set by 1,0,-1 
            if isnumeric(dir) && isscalar(dir),
                switch dir
                    case 1,
                        dir='forward';
                    case 0,
                        dir='release';
                    case -1,
                        dir='backward';
                end
            end
             
            % check direction if a.chkp is true
            if a.chkp,
                errstr=arduino.checkstr(dir,'direction',{'forward','backward','release'});
                if ~isempty(errstr), error(errstr); end
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% RUN THE MOTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots ==0,
                % handle demo mode
                
                % minimum analog output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode, num and value
                fwrite(a.aser,[66 48+num abs(dir(1))],'uchar');
                
            end
            
        end % motorrun
        
        % stepper speed
        function val=stepperSpeed(a,num,val)
            
            % val=a.stepperSpeed(num,val); sets the speed of a given stepper motor
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the stepper motor,
            % which can go from 1 to 4 (the motor ports are numbered on the motor shield).
            % The third argument is the RPM speed from 1 (minimum) to 255 (maximum).
            % Called with one argument, as a.stepperSpeed(num), it returns the
            % speed at which the given motor is set to run. If there is no output
            % argument it prints the speed of the stepper motor.
            % Called without arguments, itprints the speed of each stepper motor.
            % Note that you must use the command a.stepperStep to actually run
            % the motor at the given speed, either forward or backwards (or release
            % it). Returns Random results if motor shield is not connected.
            %
            % Examples:
            % a.stepperSpeed(2,50)      % sets speed of stepper 2 as 50 rpm
            % val=a.stepperSpeed(1);     % returns the speed of stepper 1
            % a.stepperSpeed(2);         % prints the speed of stepper 2
            % a.stepperSpeed;            % prints the speed of both steppers
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin>3,
                    error('This function cannot have more than 3 arguments, object, stepper number and speed');
                end
                
                % if stepper number is there check it
                if nargin>1,
                    errstr=arduino.checknum(num,'stepper number',1:2);
                    if ~isempty(errstr), error(errstr); end
                end
                
                % if speed argument is there check it
                if nargin>2,
                    errstr=arduino.checknum(val,'speed',0:255);
                    if ~isempty(errstr), error(errstr); end
                end
                
            end
            
            % perform the requested action
            if nargin==3,
                
                % check a.aser for validity if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'valid');
                    if ~isempty(errstr), error(errstr); end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%% SET STEPPER SPEED %%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                    % handle demo mode
                    
                    % minimum analog output delay
                    pause(0.0014);
                    
                else
                    
                    % check a.aser for openness if a.chks is true
                    if a.chks,
                        errstr=arduino.checkser(a.aser,'open');
                        if ~isempty(errstr), error(errstr); end
                    end
                    
                    % send mode, num and value
                    fwrite(a.aser,[67 48+num val],'uchar');
                    
                end
                
                % store speed value in case it needs to be retrieved
                a.sspd(num)=val;
                
                % clear val if is not needed as output
                if nargout==0,
                    clear val;
                end
                
            elseif nargin==2,
                
                if nargout==0,
                    % print speed value
                    disp(['The speed of stepper number ' num2str(num) ' is set to: ' num2str(a.sspd(num)) ' over 255']);
                else
                    % return speed value
                    val=a.sspd(num);
                end
                
            else
                
                if nargout==0,
                    % print speed value for each stepper
                    for num=1:2,
                        disp(['The speed of stepper number ' num2str(num) ' is set to: ' num2str(a.sspd(num)) ' over 255']);
                    end
                else
                    % return speed values
                    val=a.sspd;
                end
                
            end
            
        end % stepperspeed
        
        % stepper step
        function stepperStep(a,num,dir,sty,steps)
            
            % a.stepperStep(num,dir,sty,steps); rotates a given stepper motor
            % The first argument before the function name, a, is the arduino object.
            % The second argument, num, is the number of the stepper motor, which is
            % either 1 or 2. The third argument, the direction, is a string that can
            % be 'forward' (runs the motor forward) 'backward' (runs the motor backward)
            % or 'release', (stops and releases the motor). Note that since version 3.0, 
            % a +1 is interpreted as 'forward', a 0 is interpreted as 'release', 
            % and a -1 is interpreted as 'backward'. Unless the direction is 'release', 
            % then two more argument are needed: the fourth one is the style,
            % which is a string specifying the style of the motion, and can be 'single'
            % (only one coil activated at a time), 'double' (2 coils activated, gives
            % an higher torque and power consumption) 'interleave', (alternates between
            % single and double to get twice the resolution and half the speed), and
            % 'microstep' (the coils are driven in PWM for a smoother motion).
            % The final argument is the number of steps that the motor has
            % to complete.
            % Returns Random results if motor shield is not connected.
            %
            % Examples:
            % % rotates stepper 1 forward of 100 steps in interleave mode
            % a.stepperStep(1,'forward','double',100);
            % % rotates stepper 2 forward of 50 steps in double mode
            % a.stepperStep(1,'forward','double',50);
            % % rotates stepper 2 backward of 50 steps in single mode
            % a.stepperStep(2,'backward','single',50);
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin>5 || nargin <3,
                    error('Function must have at least 3 and no more than 5 arguments');
                end
                
                % check stepper number
                errstr=arduino.checknum(num,'stepper number',1:2);
                if ~isempty(errstr), error(errstr); end
                
            end
            
            % allows for direction to be set by 1,0,-1 
            if isnumeric(dir) && isscalar(dir),
                switch dir
                    case 1,
                        dir='forward';
                    case 0,
                        dir='release';
                    case -1,
                        dir='backward';
                end
            end
             
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check direction
                errstr=arduino.checkstr(dir,'direction',{'forward','backward','release'});
                if ~isempty(errstr), error(errstr); end
                
                % if it is not released must have all arguments
                if ~strcmpi(dir,'release') && nargin~=5,
                    error('Either the motion style or the number of steps are missing');
                end
                
                % can't move forward or backward if speed is set to zero
                if ~strcmpi(dir,'release') && a.stepperSpeed(num)<1,
                    error('The stepper speed has to be greater than zero for the stepper to move');
                end
                
                % check motion style
                if nargin>3,
                    % check direction
                    errstr=arduino.checkstr(sty,'motion style',{'single','double','interleave','microstep'});
                    if ~isempty(errstr), error(errstr); end
                else
                    sty='single';
                end
                
                % check number of steps
                if nargin==5,
                    errstr=arduino.checknum(steps,'number of steps',0:255);
                    if ~isempty(errstr), error(errstr); end
                else
                    steps=0;
                end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ROTATE THE STEPPER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO') || a.mots==0,
                % handle demo mode
                
                % minimum analog output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                % send mode, num and value
                fwrite(a.aser,[68 48+num abs(dir(1)) abs(sty(1)) steps],'uchar');
                
            end
            
        end % stepperstep
        
        % function analog reference
        function analogReference(a,str)
            
            % a.analogReference(str); Changes voltage reference on analog input pins
            % The first argument before the function name, a, is the arduino object.
            % The second argument, str, is one of these strings: 'default', 'internal' 
            % or 'external'. This sets the reference voltage used at the top of the 
            % input ranges.
            %
            % Examples:
            % a.analogReference('default'); % sets default reference
            % a.analogReference('internal'); % sets internal reference
            % a.analogReference('external'); % sets external reference
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % check arguments if a.chkp is true
            if a.chkp,
                
                % check nargin
                if nargin~=2,
                    error('Function must have the "reference" argument');
                end
                
                % check val
                errstr=arduino.checkstr(str,'reference',{'default','internal','external'});
                if ~isempty(errstr), error(errstr); end
                
            end
            
            % check a.aser for validity if a.chks is true
            if a.chks,
                errstr=arduino.checkser(a.aser,'valid');
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%% CHANGE ANALOG INPUT REFERENCE %%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(get(a.aser,'Port'),'DEMO'),
                % handle demo mode
                
                % minimum analog output delay
                pause(0.0014);
                
            else
                
                % check a.aser for openness if a.chks is true
                if a.chks,
                    errstr=arduino.checkser(a.aser,'open');
                    if ~isempty(errstr), error(errstr); end
                end
                
                if lower(str(1))=='e', num=2;
                elseif lower(str(1))=='i', num=1;
                else num=0;
                end
                
                % send mode, pin and value
                fwrite(a.aser,[82 48+num],'uchar');
                
            end
            
            
        end % analogreference
        
    end % methods
    
    methods (Static) % static methods
        
        function errstr=checknum(num,description,allowed)
            
            % errstr=arduino.checknum(num,description,allowed); Checks numeric argument.
            % This function checks the first argument, num, described in the string
            % given as a second argument, to make sure that it is real, scalar,
            % and that it is equal to one of the entries of the vector of allowed
            % values given as a third argument. If the check is successful then the
            % returned argument is empty, otherwise it is a string specifying
            % the type of error.
            
            % initialize error string
            errstr=[];
            
            % check num for type
            if ~isnumeric(num),
                errstr=['The ' description ' must be numeric'];
                return
            end
            
            % check num for size
            if numel(num)~=1,
                errstr=['The ' description ' must be a scalar'];
                return
            end
            
            % check num for realness
            if ~isreal(num),
                errstr=['The ' description ' must be a real value'];
                return
            end
            
            % check num against allowed values
            if ~any(allowed==num),
                
                % form right error string
                if numel(allowed)==1,
                    errstr=['Unallowed value for ' description ', the value must be exactly ' num2str(allowed(1))];
                elseif numel(allowed)==2,
                    errstr=['Unallowed value for ' description ', the value must be either ' num2str(allowed(1)) ' or ' num2str(allowed(2))];
                elseif max(diff(allowed))==1,
                    errstr=['Unallowed value for ' description ', the value must be an integer going from ' num2str(allowed(1)) ' to ' num2str(allowed(end))];
                else
                    errstr=['Unallowed value for ' description ', the value must be one of the following: ' mat2str(allowed)];
                end
                
            end
            
        end % checknum
        
        function errstr=checkstr(str,description,allowed)
            
            % errstr=arduino.checkstr(str,description,allowed); Checks string argument.
            % This function checks the first argument, str, described in the string
            % given as a second argument, to make sure that it is a string, and that
            % its first character is equal to one of the entries in the cell of
            % allowed characters given as a third argument. If the check is successful
            % then the returned argument is empty, otherwise it is a string specifying
            % the type of error.
            
            % initialize error string
            errstr=[];
            
            % check string for type
            if ~ischar(str),
                errstr=['The ' description ' argument must be a string'];
                return
            end
            
            % check string for size
            if numel(str)<1,
                errstr=['The ' description ' argument cannot be empty'];
                return
            end
            
            % check str against allowed values
            if ~any(strcmpi(str,allowed)),
                
                % make sure this is a hozizontal vector
                allowed=allowed(:)';
                
                % add a comma at the end of each value
                for i=1:length(allowed)-1,
                    allowed{i}=['''' allowed{i} ''', '];
                end
                
                % form error string
                errstr=['Unallowed value for ' description ', the value must be either: ' allowed{1:end-1} 'or ''' allowed{end} ''''];
                return
            end
            
        end % checkstr
        
        function errstr=checkser(ser,chk)
            
            % errstr=arduino.checkser(ser,chk); Checks serial connection argument.
            % This function checks the first argument, ser, to make sure that either:
            % 1) it is a valid serial connection (if the second argument is 'valid')
            % 3) it is open (if the second argument is 'open')
            % If the check is successful then the returned argument is empty,
            % otherwise it is a string specifying the type of error.
            
            % initialize error string
            errstr=[];
            
            % check serial connection
            switch lower(chk),
                
                case 'valid',
                    
                    % make sure is valid
                    if ~isvalid(ser),
                        disp('Serial connection invalid, please recreate the object to reconnect to a serial port.');
                        errstr='Serial connection invalid';
                        return
                    end
                    
                case 'open',
                    
                    % check openness
                    if ~strcmpi(get(ser,'Status'),'open'),
                        disp('Serial connection not opened, please recreate the object to reconnect to a serial port.');
                        errstr='Serial connection not opened';
                        return
                    end
                    
                    
                otherwise
                    
                    % complain
                    error('second argument must be either ''valid'' or ''open''');
                    
            end
            
        end % chackser
        
    end % static methods
    
end % class def