classdef DistanceSensor < handle      %call by reference changes actual values not copy
    properties (Access = private)     %declare private properties
        arduino
        sensor
        led
    end
    
    properties (Access = public)    %make a list of the properties that we can change
        port
        board
        trigger
        echo
        time_data        % time array
        distance_data    % distance array
    end
    
    methods
        %make constructor to initialize our Arduino parts
        function obj = DistanceSensor(port, board, trigger, echo, led)
            obj.port = port;
            obj.board = board;
            obj.trigger = trigger;
            obj.echo = echo;
            obj.led = led;

            obj.arduino = arduino(port, board, 'Libraries', 'Ultrasonic');
            obj.sensor  = ultrasonic(obj.arduino, trigger, echo);
            configurePin(obj.arduino, obj.led, 'DigitalOutput');
            
            % Initialize arrays
            obj.time_data = [];
            obj.distance_data = [];
        end
        
        % Read distance to check if infinite 
        function val = read(obj)
            val = readDistance(obj.sensor);
            if ~isfinite(val)
                warning('No echo received (returned Inf).');
            end
        end

        % Set LED on/off (needed by GUI)
        function setLed(obj, state)
            writeDigitalPin(obj.arduino, obj.led, logical(state));
        end
        
        % Monitor distance with live plotting and LED
        function monitorDistance(obj, total_time, time_interval)
            time_start = tic;

            figure;
            hold on; grid on;
            xlabel('Time (s)');
            ylabel('Distance (m)');
            title('Live Distance Monitoring');

            % Clear previous data
            obj.time_data = [];
            obj.distance_data = [];

            % Plot handle for smooth updating and live tracking
            Plot = plot(nan, nan, '-b', 'LineWidth', 1.5);


            %use tic to start timer and toc to stop
            while toc(time_start) < total_time
                distance = obj.read();
                time = toc(time_start);

                % Save data in object
                obj.time_data(end+1) = time;
                obj.distance_data(end+1) = distance;

                % Update plot
                set(Plot, 'XData', obj.time_data, 'YData', obj.distance_data);
                drawnow;

                % LED logic: turn the LED on if distance value is inf
                if isfinite(distance)
                    writeDigitalPin(obj.arduino, obj.led, 1);
                else
                    writeDigitalPin(obj.arduino, obj.led, 0);
                end

                pause(time_interval);
            end

            % Turn off LED at the end
            writeDigitalPin(obj.arduino, obj.led, 0);
       end
    end
end


