% FYP7331
% agent_test.m
% By Moyang Feng
% Example of roverControl APIs with connection to VREP
% v0.2 Update 2021.3.8
% By Liuxin Shen
% Using host class object to represent host side of the system
% Using udp protocal to simulate message transmission from host to agent

clear all;
close all;
clc;

% initialisation
sim=remApi('remoteApi');
sim.simxFinish(-1); % close all opened connections
clientID=sim.simxStart('127.0.0.1',19997,true,true,5000,5);

% Start UDP host on port 4012
hostudp=host(4012,5000);

% connection successful
if (clientID>-1)
    % create rover controller object with 3 rovers
    rc = roverControl(sim,clientID);
    disp('Connected to client.');
    % start simulation
    sim.simxStartSimulation(clientID,sim.simx_opmode_oneshot);
    disp('Simulation Started. Type "help" for available commands. Type "quit" to stop simulation.');
    sim.simxAddStatusbarMessage(clientID,'Hello CoppeliaSim!',sim.simx_opmode_oneshot);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % set the number of rovers in the simulation
    roverCount = 3;

    % initiate rovers
    rovers = rc.initRovers(roverCount);
    
    % print current state of each rover and reset their motors
    for i = 1:roverCount
        rovers(i).printInfo();
        rc.stop(rovers(i));
    end
    
    % initiate laser sensor
    [returnCode,detectionState,detectedPoint] = rc.getLaserReading(rovers(1),sim.simx_opmode_streaming);
    
    % initiate camera
    [returnCode,resolution,image] = rc.getCameraImage(rovers(1),0,sim.simx_opmode_streaming);
    
    % get position and orientation of rover
    [returnCode,roverPos] = rc.getRoverPos(rovers(1),sim.simx_opmode_streaming);
    [returnCode,roverOri] = rc.getRoverOri(rovers(1),sim.simx_opmode_streaming);
    
    % UDP communication example
    %send msg from host to rover 1
    hostudp.setRemotePort(5011);
    data=" returnCode = rc.setRoverCoordinate(rovers(1),-0.25,-2.25,150);";
    fwrite(hostudp.u,data);
%     hostudp.writeUDP(" returnCode = rc.setRoverCoordinate(rovers(1),-0.25,-2.25,150);");
%     disp(fread(rovers(1).u)');
    msg=char(rovers(1).readUDP()');
    disp(msg);
    %feedback msg from rover 1 to host
    feedback=msg;
    rovers(1).writeUDP(feedback);
    received = fread(hostudp.u);
    disp(received');
    eval(msg);
%     rovers(2).writeUDP(host);
%     received = fread(host,3);
%     disp(received);
%     
%     fwrite(rovers(1).u,1:10);
%     received = fread(host,10);
%     disp(received);
%     
    % motion control examples
    % [x,y,angle]
%     returnCode = rc.setRoverCoordinate(rovers(1),-0.25,-2.25,150);
    
    returnCode = rc.setRoverCoordinate(rovers(2),1.25,-1.25,150);
    returnCode = rc.setRoverCoordinate(rovers(3),-1.75,-1.25,150);
    
    % Main loop
%     while 1
%         
%         a=input('Rover positions = '); %5 rovers [x1 y1 a1 x2 y2 a2 x3 y3 a3] 
%     
%         if (a == 0)
%             break;
%         end
% 
%         packedData=sim.simxPackFloats(a);
%         [returnCode]=sim.simxWriteStringStream(clientID,'roverCoordinates',packedData,sim.simx_opmode_oneshot); 
%         
%         % laser sensor processing
%         [returnCode,detectionState,detectedPoint] = rc.getLaserReading(rovers(1),sim.simx_opmode_buffer);
%         if detectionState && returnCode == sim.simx_return_ok
%             distance = abs(norm(detectedPoint) - 0.145);
%             theta = 180 * atan(detectedPoint(1)/detectedPoint(3)) / pi;
%             fprintf('%.4fm %.2fdegrees\n',distance,theta); % 0.15m bias
%         end
%         
%         % rover position and orientation
%         [returnCode,roverPos] = rc.getRoverPos(rovers(1),sim.simx_opmode_buffer);
%         [returnCode,roverOri] = rc.getRoverOri(rovers(1),sim.simx_opmode_buffer);
%         disp(roverPos);
%         disp(roverOri);
%         
%         % timestep
%         pause(0.1);
%     end
    
    % camera test
%     for i = 1:100
%         [returnCode,resolution,image] = rc.getCameraImage(rovers(1),0,sim.simx_opmode_buffer);
%         imshow(image);
%         pause(0.1);
%     end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while 1
        command=input('FYP7331 >> ','s');
        if strcmp(command,'quit')
            break;
        elseif strcmp(command,'help')
            disp('quit - Stop simulation');
        else
            disp('Invalid command!');
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Stop UDP echo server

    hostudp.delete();
    
    % clean up rovers
    for i = 1:roverCount
        rc.stop(rovers(i));
        rovers(i).delete();
    end

    % stop simulation
    sim.simxStopSimulation(clientID,sim.simx_opmode_blocking);
    disp('Simulation Stopped.');
    % close the connection to CoppeliaSim
    sim.simxFinish(clientID);
else
    disp('Connection failed.');
end

sim.delete(); % call the destructor 