function [bitsSharpPort] = findBitsSharpPort
%FINDBITSSHARPPORT   searches through all ports to find Bits#.
%   BSPORT = findBitsSharpPort will return the address of the Bits# USB-CDC
%   serial port if connected.

% History:
% 2011/11 CA
% 2012/05 EW
% 2013/02 JT
% Cambridge Research Systems Ltd. 

% Init to all-empty return arguments:
bitsSharpPort = [];

% If using MicrosoftWindows 
if ispc,   
    % For OS/X and Linux, it is easy to get all existing ports, while for
    % Windows, there seems no way to get the list. So we try all possible
    % ports one by one. Fortunately, it won't take much time if a port
    % doesn't exist.
    
    % Cycle through list of all possible candidates COM1 to COM256 and
    % assign each a 'handle' for later use
    for l = 1:256
        ports(l) = serial(['COM' num2str(l)]); %#ok<AGROW,TNMLP>
    end
    
    % If using Mac OSX
elseif ismac
    % list of possible candidates
    names = dir('/dev/tty.usb*');
    if size(names,1)==0,
        error(['Could not find any ports of the form /dev/tty.usb*/n',...
            'Is Bits# connected?'])
    end
    % cycle through possible candidates and assign each a 'handle' for
    % later use
    for l = 1:length(names)
        ports(l) = serial(['/dev/' names(l).name]); %#ok<AGROW,TNMLP>
    end
    
    % If using UNIX
elseif isunix
    % list of possible candidates
    names = dir('/dev/ttyACM*');
    if size(names,1)==0,
        error(['Could not find any ports of the form /dev/ttyACM*/n',...
            'Is Bits# connected?'])
    end
    % cycle through possible candidates and assign each a 'handle' for
    % later use
    for l = 1:length(names)
        ports(l) = serial(['/dev/' names(l).name]); %#ok<AGROW,TNMLP>
    end
else
    error(['Failed to find the Bits# com port. Could not determine the ',...
        'operating system.'])
end

% Disable output of IOPort during probe-run:
oldverbosity=IOPort('Verbosity', 0);

% Set a flag indicating that the right port is found. Init with false.
foundRightPort = false; 

% cycle through each port (will stop when it gets to the right port)
for i=1:length(ports)
    
    % 'try' so that even if later code raises an error, ports will still be
    % closed properly, preventing problems with future attempts to open
    % them.
    try
        % Try to open:
        fopen(ports(i));
        % If the port does not exist, attempting to open it will raise an
        % error. This can then be used to indicate the function should
        % proceed to the next iteration of the loop.
    catch ME %#ok<NASGU>
        continue
    end
    
    % If no error is raised, port exists and is opened, so the script can
    % continue.
    
    % 'try' so that even if later code raises an error, ports will still be
    % closed properly, preventing problems with future attempts to open
    % them.
    try
        
        % The command '#ProductType' is a Bits# command and will return
        % '#ProductType;Bits_Sharp;' if the port is the Bits# port. Note
        % that all Bits# commands are preceded by either a 'sharp' (#) or
        % dollar ($). These are interchangable. a '#' symbold on a mac
        % keyboard is 'Alt + 3'. Also, the '13' is the terminator
        % character. 13 represents a carriage return and should be included
        % at the end of every Bits# command to indicate the end of the
        % command.
%         Command=['#ProductType' 13];
%         
%         for k = 1:length(Command)
%             fprintf(ports(i), Command(k));
%         end
        fprintf(ports(i), ['#ProductType' 13]);
        % pause for a brief, arbitrary period, to allow the command time to
        % be sent and a reply returned, reducing the possibility that the
        % code will progress before a reply has been received, erroneously
        % concluding Bits# is not connected to that port.
        pause(0.1)
        
        % If information is available to read, it suggests a reply has been
        % received. If no information is available to read, the current
        % port is not the Bits# port and therefore no further action is
        % required for the current port.
        if ports(i).BytesAvailable > 0
            
            % fscanf will read the information available to read in the
            % outputbuffer.
            myAnswer = fscanf(ports(i));
            
            % Compare the string now assigned to myAnswer with the expected
            % response of '#ProductType; Bits_Sharp;'). If they match,
            % bitsSharpPort is the current port and the function can
            % terminate. If these strings do not match, the current port is
            % not the Bits# port and the script should continue to the next
            % iteration of the loop.
            if ~isempty(strfind(myAnswer,'#ProductType;Bits_Sharp;')),
                bitsSharpPort = ports(i).Port;
                fclose(ports(i));
                foundRightPort = true;
                break
            end
        end
        
        % After all possible ports have been tried, or after the loop was
        % broken early if the correct port was found, close all ports to
        % prevent problems when trying to open these ports in the future.
        fclose(ports(i));
        
        % If an error is raised during the above code, ensure the ports are
        % properly closed before aborting the script, otherwise there may
        % be problems when attempting to reopen the ports in the future.
    catch ME %#ok<NASGU>
        fclose(ports(i));
    end
    
end

if ~foundRightPort,
    error('Could not find a port that responds like a Bits#..')
end

% Restore output of IOPort after probe-run:
IOPort('Verbosity', oldverbosity);


