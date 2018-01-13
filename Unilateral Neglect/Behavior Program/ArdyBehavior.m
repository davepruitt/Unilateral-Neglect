function ardy = ArdyBehavior(varargin)

port = instrhwinfo('serial');                                               %Grab information about the available serial ports.
if isempty(port.SerialPorts)                                                %If no serial ports were found, show an error.
    errordlg('ERROR IN ARDYBEHAVIOR: There are no Arduinos connected to this computer.',...
        'Connection Error!');                                               %Show an error dialog.
end
port = port.SerialPorts;                                                    %Pair down the list of serial ports to only those available.
busyports = instrfind;                                                      %Grab all the ports currently in use.
if ~isempty(busyports)                                                      %If there are any ports currently in use...
    busyports = {busyports.Port};                                           %Make a list of their port addresses.
    if iscell(busyports{1})                                                 %If there's more than one busy port.
        busyports = busyports{1}';                                          %Kick out the extraneous port name parts.
    end
else                                                                        %Otherwise...
    busyports = {};                                                         %Make an empty list for comparisons.
end
listbox = [];                                                               %Create a matrix to hold a listbox handle, if the user specifies one.
checkreset = 1;                                                             %Make a variable to check whether we should ask the user if a port should be reset.   
if nargin < 1 || ~any(strcmpi('port',varargin(1:2:end)))                    %If the user didn't specify a COM port for the Arduino.
    if length(port) > 1                                                     %If there's more than one serial port available, ask the user which they'd like to use.
        pos = get(0,'ScreenSize');                                          %Grab the screensize.
        pos = [0.4*pos(3),0.3*pos(4),0.2*pos(3),0.4*pos(4)];                %Scale a figure position relative to the screensize.
        fig1 = figure;                                                      %Make a figure to ask the user which serial port they'd like to connect to.
        set(fig1,'Position',pos,'MenuBar','none','name','Select A Serial Port',...
            'numbertitle','off','color','w');                               %Set the properties of the figure.
        for i = 1:length(port)                                              %Step through each available serial port.
            if any(strcmpi(port{i},busyports))                              %If this serial port is busy...
                uicontrol(fig1,'style','pushbutton',...
                    'string',[port{i} ': busy (reset?)'],...
                    'units','normalized',...
                    'position',[.05 .95-i*.9*(1/length(port)) .9 .9*(1/length(port))],...
                    'fontweight','bold',...
                    'fontsize',14,...
                    'callback',...
                    ['guidata(gcbf,' num2str(i) '); uiresume(gcbf);']);     %Make a button for the port showing that it is busy.
            else                                                            %Otherwise...
                uicontrol(fig1,'style','pushbutton',...
                    'string',[port{i} ': available'],...
                    'units','normalized',...
                    'position',[.05 .95-i*.9*(1/length(port)) .9 .9*(1/length(port))],...
                    'fontweight','bold',...
                    'fontsize',14,...
                    'callback',...
                    ['guidata(gcbf,' num2str(i) '); uiresume(gcbf);']);     %Make a button for the port showing that it is available.
            end
        end
        uiwait(fig1);                                                       %Wait for the user to push a button on the pop-up figure.
        if ishandle(fig1)                                                   %If the user didn't close the figure without choosing a port...
            i = guidata(fig1);                                              %Grab the index of chosen port name from the figure.
            port = port{i};                                                 %Set the serial port to that chosen by the user.
            close(fig1);                                                    %Close the figure.
            checkreset = 0;                                                 %Don't ask the user later if they want to reset the chosen port.
        else                                                                %Otherwise, if the user closed the figure without choosing a port...
           port = [];                                                       %Set the chosen port to empty.
        end
    else                                                                    %Otherwise, if there's only one port.
        port = port{1};                                                     %Automatically set the serial port to the only.
    end
end
if nargin > 0                                                               %If the user specified some property values.
    for i = 1:2:length(varargin)                                            %Step through each pair of input arguments.
        if ~ischar(varargin{i}) || ...
                ~any(strcmpi(varargin{i},{'port','listbox'}))               %If the property name is invalid, show an error.
        end
        if length(varargin) < i + 1                                         %If there's no matching property value for the property name, show an error.
            error(['ERROR IN ARDYBEHAVIOR: No matching property value for ''' varargin{i} '''.']);
        end
        if strcmpi(varargin{i},'port')                                      %If the user specified the COM port...
            if ~ischar(varargin{i+1})                                       %If the entered port isn't a string, show an error.
                error('ERROR IN ARDYBEHAVIOR: The specified serial port address must be a string, e.g. ''COM8''.');
            end
            if ~any(strcmpi(varargin{1},port))                              %If the specified port doesn't exist on this computer, show an error.
                error(['ERROR IN ARDYBEHAVIOR: Serial port ''' varargin{1} ''' doesn''t exist on this computer.']);
            end
            port = varargin{i+1};                                           %Set the port to that specified by the user.
        else                                                                %Otherwise, if the user specified a listbox handle.
            listbox = varargin{i+1};                                        %Save the listbox handle to write messages to.
        end
    end        
end
if ~isempty(port) && checkreset && any(strcmpi(port,busyports))            	%If that serial port is busy...
    i = questdlg(['Serial port ''' port ''' is busy. Reset and use this port?'],...
        ['Reset ''' port '''?'],'Reset','Cancel','Reset');                   %Ask the user if they want to reset the busy port.
    if strcmpi(i,'Cancel')                                                  %If the user selected "Cancel"...
        port = [];                                                          %...set the selected port to empty.
    end
end
if isempty(port)                                                            %If no port was selected.
    warning('ArdyBehavior:NoPortChosen','No serial port chosen for ArdyBehavior. Connection to the Arduino was aborted.');    %Show a warning.
    ardy = [];                                                              %Set the function output to empty.
    return;                                                                 %Exit the ArdyBehavior function.
end
ardy.port = port;                                                           %Save the port address to the output structure.
if any(strcmpi(port,busyports))                                             %If the specified port is already busy...
    i = find(strcmpi(port,busyports));                                      %Find the index of the specified ports in the list of all busy ports.
    temp = instrfind;                                                       %Grab all the open serial connections.
    fclose(temp(i));                                                        %Close the busy serial connection.
    delete(temp(i));                                                        %Delete the existing serial connection.
end
serialcon = serial(port,'baudrate',115200);                                 %Set up the serial connection on the specified port.
try                                                                         %Try to open the serial port for communication.
    fopen(serialcon);                                                       %Open the serial port.
catch                                                                       %If no connection could be made to the serial port...
    delete(serialcon);                                                      %...delete the serial object...
    error(['ERROR IN ARDYBEHAVIOR: Could not open a serial connection on port ''' port '''.']);    %...and show an error.
end
message = 'Connecting to the Arduino...';                                   %Create the beginning of message to show the user.
if isempty(listbox)                                                         %If the user didn't specify a listbox...
    pos = get(0,'ScreenSize');                                              %Grab the screensize.
    pos = [0.3*pos(3),0.55*pos(4),0.4*pos(3),0.1*pos(4)];                   %Scale a figure position relative to the screensize.
    fig1 = figure;                                                          %Make a figure to show the progress of the Arduino connection.
    set(fig1,'Position',pos,'MenuBar','none','name','Arduino Connection',...
        'numbertitle','off');                                               %Set the properties of the figure.
    t = uicontrol(fig1,'style','text',...
    'string',message,...
	'units','normalized',...
	'position',[.01 .01 .98 .98],...
    'fontweight','bold',...
    'horizontalalignment','left',...
    'fontsize',14,...
    'backgroundcolor',get(fig1,'color'));                                   %Make a text label to show the Arduino connection status.
else                                                                        %Otherwise, if the user specified a listbox...
    t = 0;                                                                 %Create a dummy handle for the non-existent text label.
    set(listbox,'string',message,'value',1);                                %Show the Arduino connection status in the listbox.
end
tic;                                                                        %Start a timer.
while toc < 10                                                              %Loop for 10 seconds to wait for the Arduino to initialize.
    if serialcon.BytesAvailable > 0                                         %If there's bytes available on the serial line...
        break                                                               %Break out of the waiting loop.
    else                                                                    %Otherwise...
        message(end+1) = '.';                                               %Add a period to the end of the message.
        if ishandle(t) && isempty(listbox)                                  %If the user hasn't closed the figure and hasn't specified a listbox...
            set(t,'string',message);                                        %Update the message in the text label on the figure.
        elseif ~isempty(listbox)                                            %Or, if the user did specify a listbox...
            set(listbox,'string',message,'value',[]);                       %Update the message in the listbox.
        end
        pause(0.5);                                                         %Pause for 500 milliseconds.
    end
end
if serialcon.BytesAvailable > 0                                             %if there's a reply on the serial line.
    temp = fscanf(serialcon,'%c',serialcon.BytesAvailable);                 %Read the reply into a temporary matrix.
end
tic;                                                                        %Start a timer.
while toc < 10;                                                             %Loop for 10 seconds or until a reply is noted.
    fwrite(serialcon,'A','uchar');                                          %Send the check status code to the Arduino board.
    if serialcon.BytesAvailable > 0                                         %If there's bytes available on the serial line...
        message = [message 'Connected!'];                                   %Add to the message to show that the connection was successful.
        if ishandle(t) && isempty(listbox)                                  %If the user hasn't closed the figure and hasn't specified a listbox...
            set(t,'string',message);                                        %Update the message in the text label on the figure.
        elseif ~isempty(listbox)                                            %Or, if the user did specify a listbox...
            set(listbox,'string',message,'value',[]);                       %Update the message in the listbox.
        end
        break                                                               %Break out of the waiting loop.
    else                                                                    %Otherwise...
        message(end+1) = '.';                                               %Add a period to the end of the message.
        if ishandle(t) && isempty(listbox)                                  %If the user hasn't closed the figure and hasn't specified a listbox...
            set(t,'string',message);                                        %Update the message in the text label on the figure.
        elseif ~isempty(listbox)                                            %Or, if the user did specify a listbox...
            set(listbox,'string',message,'value',[]);                       %Update the message in the listbox.
        end
        pause(0.5);                                                         %Pause for 500 milliseconds.
    end
end
while serialcon.BytesAvailable > 0                                          %Loop through the replies on the serial line.
    pause(0.01);                                                            %Pause for 50 milliseconds.
    temp = fscanf(serialcon,'%d');                                          %Read each reply, replacing the last.
end
if isempty(temp) || temp ~= 555                                             %If no status reply was received...
    delete(serialcon);                                                      %...delete the serial object and show an error.
    fprintf(1,'COULD NOT CONNECT!\n');                                      %End the connection message with an error.
    error(['ERROR IN ARDYBEHAVIOR: Could not connect to the Arduino board.' ...
        '  Check to make sure the Arduino is connected to the specified serial'...
        ' port and that it is running the ArdyBehavior.pde sketch.']);  %...and show an error.
else                                                                        %Otherwise...
    disp('Arduino is connected and ArdyBehavior.pde is detected as running.'); %Show that the connection was successful.
end       

%Basic status functions.
ardy.check_serial = @()check_serial(serialcon);                             %Set the function for checking the serial connection.
ardy.check_sketch = @()check_sketch(serialcon);                             %Set the function for checking that the ArdyBehavior sketch is running.
ardy.check_version = @()simple_return(serialcon,'B',[]);                    %Set the function for checking which version of the ArdyBehavior sketch is loaded.
ardy.booth = @()simple_return(serialcon,'CA',[]);                           %Set the function for returning the booth number saved on the Arduino.
ardy.set_booth = @(int)long_command(serialcon,'Dnn',[],int);                   %Set the function for setting the booth number saved on the Arduino.
ardy.serialcon = serialcon;                                                 %Save the handle for the serial connection for debugging purposes.
ardy.clear = @()clear_serial(serialcon);                                    %Set the function for clearing the serial line.

%LED queueing functions.
ardy.queue = @()long_return(serialcon,'K',[]);                              %Set the function for reading back the currently queued LEDs on the Arduino.
ardy.led_delay = @()simple_return(serialcon,'G',[]);                        %Set the function for reading the current trigger-to-LED delay setting on the Arduino.
% ardy.led_dur = @()simple_return(serialcon,'E',[]);                          %Set the function for reading the current LED duration setting on the Arduino.
ardy.led_isi = @()simple_return(serialcon,'I',[]);                          %Set the function for reading the current onset-to-onset inter-LED interval setting on the Arduino.
ardy.set_queue = @(leds)set_leds(serialcon,leds);                           %Set the function for setting the LED queue on the Arduino.
ardy.set_led_delay = @(int)long_command(serialcon,'Hnn',[],int);               %Set the function for setting the current trigger-to-LED delay setting on the Arduino.
% ardy.set_led_dur = @(int)long_command(serialcon,'Fnn',[],int);                 %Set the function for setting the current LED duration setting on the Arduino.
ardy.set_led_isi = @(i, int)long_command(serialcon,'Jnn',int);                 %Set the function for setting the current onset-to-onset inter-LED interval setting on the Arduino.
ardy.enable = @(i)simple_command(serialcon,'Mi',i);                         %Set the function for enabling or disabling LED presentation.
ardy.check_enable = @()simple_return(serialcon,'N',[]);                     %Set the function for checking the enable/disable status on the Arduino.

%Behavioral control functions.
ardy.play_bad_sound = @(i)simple_command(serialcon,'a', 1);                 %Set the function for playing a bad sound on the Arduino
ardy.play_good_sound = @(i)simple_command(serialcon,'b', 1);                %Set the function for playing a good sound on the Arduino
ardy.digital_ir = @(i)simple_return(serialcon,'1i',i);                      %Set the function for checking the digital state of the behavioral IR inputs on the Arduino.
ardy.analog_ir = @(i)simple_return(serialcon,'2i',i);                       %Set the function for checking the analog reading on the behavioral IR inputs on the Arduino.
ardy.feed = @(i)simple_command(serialcon,'3i',i);                           %Set the function for triggering food/water delivery.
ardy.feed_dur = @()simple_return(serialcon,'4',[]);                         %Set the function for checking the current feeding/water trigger duration on the Arduino.
ardy.set_feed_dur = @(int)long_command(serialcon,'5nn',[],int);                %Set the function for setting the feeding/water trigger duration on the Arduino.
ardy.stim = @()simple_command(serialcon,'6',[]);                            %Set the function for sending a trigger to the stimulation trigger output.
ardy.stim_dur = @()simple_return(serialcon,'7',[]);                         %Set the function for checking the current stimulation trigger duration on the Arduino.
ardy.set_stim_dur = @(int)long_command(serialcon,'8nn',[],int);                %Set the function for setting the stimulation trigger duration on the Arduino.
ardy.cage_lights = @(i)simple_command(serialcon,'9i',i);                    %Set the function for turning the overhead cage lights on/off.
ardy.led_on = @(i)simple_command(serialcon,':i',i);                         %Set the function for turning cage LEDs on.
ardy.led_off = @(i)simple_command(serialcon,';i',i);                        %Set the function for turning cage LEDs off.
ardy.led_dur = @()simple_return(serialcon,'<',[]);                          %Set the function for checking the current cage LED duration on the Arduino.
ardy.set_led_dur = @(int)long_command(serialcon,'=nn',[],int);                 %Set the function for setting the cage LED duration on the Arduino.
ardy.set_led_intensity = @(int)long_command(serialcon,'-nn',[],int);           %Set the function for setting the cage LED intensity on the Arduino.
ardy.set_single_led_duration = @(i, int)long_command(serialcon,'*i@nn',i,int); %Set the function for setting the LED duration of any individual LED.
ardy.set_single_led_intensity = @(i, int)long_command(serialcon,'*i#nn',i,int);%Set the function for setting the LED intensity of any individual LED.

%Streaming functions
ardy.stream_enable = @(i)simple_command(serialcon,'gi',i);            %Set the function for enabling or disabling the stream.
ardy.set_stream_period = @(int)long_command(serialcon,'enn',[],int);  %Set the function for setting the stream period.
ardy.stream_period = @()simple_return(serialcon,'f',[]);              %Set the function for checking the current stream period.
ardy.set_stream_ir = @(i)simple_command(serialcon,'ci',i);            %Set the function for setting which IR input is read out in the stream.
ardy.stream_ir = @()simple_return(serialcon,'d',[]);                  %Set the function for checking the current stream IR input.
ardy.read_stream = @()read_stream(serialcon);                         %Set the function for reading values from the stream.
ardy.clear = @()clear_stream(serialcon);                              %Set the function for clearing the serial line prior to streaming.


pause(2);                                                                   %Pause for 2 second.
if isempty(listbox) && ishandle(fig1)                                       %If the Arduino connection messagebox is still open...
    close(fig1);                                                            %Close the figure.
end
if serialcon.BytesAvailable > 0                                             %If there's any junk leftover on the serial line...
    fscanf(serialcon,'%d',serialcon.BytesAvailable);                        %Remove all of the replies from the serial line.
end


%% This function checks the status of the serial connection.
function output = check_serial(serialcon)
if isa(serialcon,'serial') && isvalid(serialcon) && ...
        strcmpi(get(serialcon,'status'),'open')                             %Check the serial connection...
    output = 1;                                                             %Return an output of one.
    disp(['Serial port ''' serialcon.Port ''' is connected and open.']);    %Show that everything checks out on the command line.
else                                                                        %If the serial connection isn't valid or open.
    output = 0;                                                             %Return an output of zero.
    warning('ArdyBehavior:NonresponsivePort',...
        'The serial port is not responding to status checks!');             %Show a warning.
end


%% This function checks to see if the ArdyBehavior.pde sketch is current running on the Arduino.
function output = check_sketch(serialcon)
fwrite(serialcon,'A','uchar');                                              %Send the check status code to the Arduino board.
output = fscanf(serialcon,'%d');                                            %Check the serial line for a reply.
if output == 222                                                            %If the Arduino returned the number 111...
    output = 1;                                                             %...show that the Arduino connection is good.
else                                                                        %Otherwise...
    output = 0;                                                             %...show that the Arduino connection is bad.
end


%% This function sends the specified command to the Arduino, replacing any "i" characters with the specified input number.
function simple_command(serialcon,command,i)
command(command == 'i') = char(i);                                          %Convert the specified input number to a string.
fwrite(serialcon,command,'uchar');                                          %Send the command to the Arduino board.


%% This function sends the specified command to the Arduino, replacing any "i" characters with the specified input number.
function output = simple_return(serialcon,command,i)
command(command == 'i') = char(i);                                          %Convert the specified input number to a string.
fwrite(serialcon,command,'uchar');                                          %Send the command to the Arduino board.
while serialcon.BytesAvailable == 0 && toc < 1                              %Loop for one second or until there's a reply on the serial line.
    pause(0.001);                                                           %Pause for 1 millisecond to keep from overwhelming the processor.
end
pause(0.005);                                                               %Pause for 5 milliseconds.
output = fscanf(serialcon,'%d');                                            %Read each byte and save it to the output matrix.


%% This function sends the specified command to the Arduino, replacing any "i" characters with the specified input number.
function output = long_return(serialcon,command,i)
command(command == 'i') = char(i);                                          %Convert the specified input number to a string.
fwrite(serialcon,command,'uchar');                                          %Send the command to the Arduino board.
while serialcon.BytesAvailable == 0 && toc < 1                              %Loop for one second or until there's a reply on the serial line.
    pause(0.001);                                                           %Pause for 1 millisecond to keep from overwhelming the processor.
end
output = [];                                                                %Create an empty matrix to hold the serial line reply.
pause(0.005);                                                               %Pause for 5 milliseconds.
while serialcon.BytesAvailable > 0                                          %Loop as long as there's bytes available on the serial line...
    output(end+1) = fscanf(serialcon,'%d');                                 %Read each byte and save it to the output matrix.
end


%% This function sends commands with 16-bit integers broken up into 2 characters encoding each byte.
function long_command(serialcon,command,i,int)     
command(command == 'i') = num2str(i);
i = dec2bin(typecast(int16(int), 'uint16'),16);                             %Convert the 16-bit integer to a 16-bit binary string.
byteA = bin2dec(i(1:8));                                                    %Find the character that codes for the first byte.
byteB = bin2dec(i(9:16));                                                   %Find the character that codes for the second byte.
i = findstr(command,'nn');                                                  %Find the spot for the 16-bit integer bytes in the command.
command(i:i+1) = char([byteA, byteB]);                                      %Insert the byte characters into the command.
fwrite(serialcon,command,'uchar');                                          %Send the command to the Arduino board.


%% This function sets the LEDs in the queue on the Arduino.
function set_leds(serialcon,leds)
if ~isempty(leds)                                                          %If the LED list isn't empty...
    command = ['L' char(length(leds)) char(leds(:)') 'A'];                %Create the load-LED command.
    fwrite(serialcon,command,'uchar');                                      %Send the command to the Arduino board.
end

%% This function clears any residual streaming data from the serial line prior to streaming.
function clear_serial(serialcon)
tic;                                                                        %Start a timer.
while serialcon.BytesAvailable == 0 && toc < 0.05                           %Loop for 50 milliseconds or until there's a reply on the serial line.
    pause(0.001);                                                           %Pause for 1 millisecond to keep from overwhelming the processor.
end
while serialcon.BytesAvailable > 0                                          %Loop as long as there's bytes available on the serial line...
    fscanf(serialcon,'%d');                                                 %Read each byte and discard it.
end

%% This function reads in the values from the data stream when streaming is enabled.
function output = read_stream(serialcon)
tic;                                                                        %Start a timer.
while serialcon.BytesAvailable == 0 && toc < 0.05                           %Loop for 50 milliseconds or until there's a reply on the serial line.
    pause(0.001);                                                           %Pause for 1 millisecond to keep from overwhelming the processor.
end
output = [];                                                                %Create an empty matrix to hold the serial line reply.
while serialcon.BytesAvailable > 0                                          %Loop as long as there's bytes available on the serial line...
    try
        streamdata = fscanf(serialcon,'%d')';
        output(end+1,:) = streamdata(1:2);                                  %Read each byte and save it to the output matrix.
    catch
    end
end


%% This function clears any residual streaming data from the serial line prior to streaming.
function clear_stream(serialcon)
tic;                                                                        %Start a timer.
while serialcon.BytesAvailable == 0 && toc < 0.05                           %Loop for 50 milliseconds or until there's a reply on the serial line.
    pause(0.001);                                                           %Pause for 1 millisecond to keep from overwhelming the processor.
end
while serialcon.BytesAvailable > 0                                          %Loop as long as there's bytes available on the serial line...
    fscanf(serialcon,'%d');                                                 %Read each byte and discard it.
end