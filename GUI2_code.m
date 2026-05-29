classdef GUI2_code < matlab.apps.AppBase
% Abid
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        Image                       matlab.ui.control.Image
        ErrorAnalysisButton         matlab.ui.control.Button
        DerivativesButton           matlab.ui.control.Button
        MeasurePointButton          matlab.ui.control.Button
        TrueDistanceEditField       matlab.ui.control.NumericEditField
        TrueDistanceEditFieldLabel  matlab.ui.control.Label
        RESETButton                 matlab.ui.control.Button
        MaterialsDropDown           matlab.ui.control.DropDown
        MaterialsDropDownLabel      matlab.ui.control.Label
        OrderforModelDropDown       matlab.ui.control.DropDown
        OrderforModelDropDownLabel  matlab.ui.control.Label
        ClearGraphButton            matlab.ui.control.Button
        PlotallGraphsButton         matlab.ui.control.Button
        StopMonitoringButton        matlab.ui.control.Button
        StartMonitoringButton       matlab.ui.control.Button
        InitializeArduinoButton     matlab.ui.control.Button
        UIAxes                      matlab.ui.control.UIAxes
    end

    % Custom private properties

    %Mina
    properties (Access = private)
        sensor = []               % DistanceSensor class object
        monitoring = false        % Flag to control loop
        simulationData = {};      %initialize all the values (data, count, trueValues, and measuredValues)
        simulationCount = 0;
        trueValues = [];
        measuredValues = [];
    end


    methods (Access = private)

        function z = forward_difference(app,t,d)         %create a function for Newton's forward difference that can be used later, output z(velocity) and inputs are time and distance

            t = t(:);
            d = d(:);

            n = length(d);
            v = zeros(1, n-1);
            for i = 1:n-1
                v(i) = (d(i+1) - d(i)) / (t(i+1) - t(i)); %equation for calculating Newton's forward difference
            end
            z=v;

        end


        function z = central_difference(app,t,d)     %create a fucntion for Newton's central difference that can be used later, output z(velocity) and inputs are time and distance

            t = t(:);
            d = d(:);

            n = length(d);
            v = zeros(1,n-2);
            for i = 2:n-1
                v(i-1) = (d(i+1)- d(i-1))/ (t(i+1) - t(i-1)); %equation for calcuating Newton's central difference
            end
            z =v;
        end


    end



    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: InitializeArduinoButton
        function InitializeArduinoButtonPushed(app, event)
            %ABID
            %Our pins for the Arduino Board, we can update if needed
            port = 'COM3';
            board = 'Uno';
            trig = 'D7'; %pin 7
            echo = 'D6'; %pin 6
            led = 'D3';  %pin 3
            app.sensor = DistanceSensor(port, board, trig, echo, led);            %use function from Arduino class
            disp('Sensor initialized successfully.');                             %if initialized properly display this message

        end

        % Button pushed function: StartMonitoringButton
        function StartMonitoringButtonPushed(app, event)
            %MUSTAKIM
            if isempty(app.sensor)                                       %make sure the sensor is initialized
                disp('Sensor not initialized yet.');
                return;
            end

            app.monitoring = true;                                       %will be used later for the while loop
            app.sensor.time_data = [];                                   %create an array for the time and distance: ...
            app.sensor.distance_data = [];


            % plot live graph, nan is our initial (not a number) value
            plotHandle = plot(app.UIAxes, nan, nan, '-b', 'LineWidth', 1.5);                  %plot our graph for live tracking with labels and title
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Distance (m)');
            title(app.UIAxes, 'Live Distance Data');

            tstart = tic;                                                  %starts timing



            % this is for the live graphing
            while app.monitoring                                           %will run until the sensor stops monitoring
                d = app.sensor.read();                                     % stores data from sensor
                t = toc(tstart);                                           %gets time values

                app.sensor.time_data(end+1) = t;
                app.sensor.distance_data(end+1) = d;

                set(plotHandle, 'XData', app.sensor.time_data, ...
                    'YData', app.sensor.distance_data);
                drawnow;

                %turn LED on if distance = inf, else keep it off

                if isinf(d)

                    app.sensor.setLed(1);
                else
                    app.sensor.setLed(0);
                end

                pause(0.1);
            end
            app.sensor.setLed(0);                                          %default value

        end

        % Button pushed function: StopMonitoringButton
        function StopMonitoringButtonPushed(app, event)
            %MUSTAKIM
            if isempty(app.sensor) || ~isvalid(app.sensor)                 %checks if sensor is initialized
                disp("Sensor is either not initialized or not valid");
                return;
            end

            app.monitoring = false;                                        % this will end the while loop for live graphing

            app.simulationCount = app.simulationCount + 1;                 %keep track of the simulation count

            materialName = app.MaterialsDropDown.Value;                    %get value of material name from the drop down menu


            %store the data then clear it
            app.simulationData{app.simulationCount} = struct('time', app.sensor.time_data, 'distance', app.sensor.distance_data, 'material', materialName);

            app.sensor.time_data = [];                                     %clear time data so it can be reused for the next simulation
            app.sensor.distance_data = [];                                 %clear sensor data so it can be reused for next simulation



        end

        % Button pushed function: PlotallGraphsButton
        function PlotallGraphsButtonPushed(app, event)
            %MINA

            colors = {'-b', '-r', '-g', '-m', '-c'};                       %colors for the functions in the graphs

            hold(app.UIAxes, 'on');

            for k = 1:app.simulationCount                                  %this will go through all the materials
                data = app.simulationData{k};
                plot(app.UIAxes, data.time, data.distance, colors{k}, 'LineWidth', 1.5);                %this will plot all the functions for the data stored
            end

            xlabel(app.UIAxes, 'Times(s)');
            ylabel(app.UIAxes, 'Distance(m)');
            title(app.UIAxes, 'Distance Vs Time For Multiple Simulations');
            legend_names = strings(1, app.simulationCount);

            for k = 1:app.simulationCount                                  %get the names of materials, for our legend
                legend_names(k) = app.simulationData{k}.material;
            end
            legend(app.UIAxes, legend_names);

            hold(app.UIAxes, 'off');


        end

        % Button pushed function: ClearGraphButton
        function ClearGraphButtonPushed(app, event)
            %ABID
            cla(app.UIAxes);                                               %clears graph
        end

        % Button pushed function: RESETButton
        function RESETButtonPushed(app, event)
            %ABID
            app.simulationData = {};
            app.simulationCount = 0;
            app.trueValues = [];
            app.measuredValues = [];
            cla(app.UIAxes);
            %RESET EVERYTHING IF SOMETHING GOES WRONG!
        end

        % Value changed function: OrderforModelDropDown
        function OrderforModelDropDownValueChanged(app, event)
            %MUSTAKIM
            value = app.OrderforModelDropDown.Value;                       %get order value from the drop down menu
            colors = {'-b', '-r', '-g', '-m', '-c'};



            switch value                                                   %convert the string values in our menu to a numer that can be used later on
                case '1st Order'
                    Order = 1;
                case '2nd Order'
                    Order = 2;
                case '3rd Order'
                    Order = 3;
            end


            materialName = app.MaterialsDropDown.Value;                    %get material name


            data = [];
            for k = 1:app.simulationCount                                  %find data for the material name we are looking for
                if strcmp(app.simulationData{k}.material, materialName)
                    data = app.simulationData{k};
                    break
                end
            end

            if isempty(data)                                               %checks if data exists
                disp(['No simulation data found for', materialName]);
                return;
            end

            p = polyfit(data.time, data.distance, Order);                  %use polyfit to generate the coefficients for the order desired
            t_fit = linspace(min(data.time), max(data.time), 200);
            y_fit = polyval(p, t_fit);                                     %use polyval to get the y values for the fitted curve

            % Plot the fitted polynomial, labels, title, and the legend
            cla(app.UIAxes);
            plot(app.UIAxes, t_fit, y_fit, colors{1}, 'LineWidth', 2);     %plot  the polynomial model


            xlabel(app.UIAxes, 'Time(s)');                                 %labels, title, and legend down in these comments
            ylabel(app.UIAxes, 'Distance(m)');
            title(app.UIAxes, ['Distance Vs Time ', value, 'Fit']);
            legend(app.UIAxes, materialName);

        end

        % Button pushed function: ErrorAnalysisButton
        function ErrorAnalysisButtonPushed(app, event)
            %MINA
            selectedMaterial = app.MaterialsDropDown.Value;                %get selected material from drop down menu


            trueValues = app.trueValues(:);                                %store values in property variables
            measuredValues = app.measuredValues(:);


            true_error = trueValues - measuredValues;                      % True Error formula
            rel_true_error = (true_error ./trueValues) *100;               % Relative true error formula


            nPoints = numel(measuredValues);                               %get number of points

            Approx_error = zeros(nPoints,3);                               %initialize approximate error and relative approximate error
            Rel_Approx_error = zeros(nPoints,3);

            for i = 1:3                                                    %get the approximate value( xi = 1st order, xi+1 = 2nd order...)
                p = polyfit(trueValues, measuredValues, i);
                yfit = polyval(p, trueValues);

                Approx_error(:,i) = measuredValues - yfit;                 %formula for approximate errors
                Rel_Approx_error(:, i) = (Approx_error(:,i)./yfit)*100;    %formula for relative approximate errors
            end


            % --- Plot errors ---
            cla(app.UIAxes);
            hold(app.UIAxes, 'on');                                        %allows all the graphs to be plotted at once

            %plot EVERYTHING, all errors

            plot(app.UIAxes, trueValues, true_error, '-b', 'LineWidth', 1.5, 'DisplayName', 'True Error (m)');
            plot(app.UIAxes, trueValues, Approx_error(:,1), '-r', 'LineWidth', 1.5, 'DisplayName', '1st Order AE (m)');
            plot(app.UIAxes, trueValues, Approx_error(:,2), '-g', 'LineWidth', 1.5, 'DisplayName', '2nd Order AE (m)');
            plot(app.UIAxes, trueValues, Approx_error(:,3), '-m', 'LineWidth', 1.5, 'DisplayName', '3rd Order AE (m)');

            % Relative errors
            plot(app.UIAxes, trueValues, rel_true_error, '--b', 'LineWidth', 1.5, 'DisplayName', 'Relative True Error (%)');
            plot(app.UIAxes, trueValues, Rel_Approx_error(:,1), '--r', 'LineWidth', 1.5, 'DisplayName', '1st Order Relative AE (%)');
            plot(app.UIAxes, trueValues, Rel_Approx_error(:,2), '--g', 'LineWidth', 1.5, 'DisplayName', '2nd Order Relative AE (%)');
            plot(app.UIAxes, trueValues, Rel_Approx_error(:,3), '--m', 'LineWidth', 1.5, 'DisplayName', '3rd Order Relative AE (%)');

            hold(app.UIAxes, 'off');

            xlabel(app.UIAxes, 'True Distance (m)');                               %labels, title, and legend
            ylabel(app.UIAxes, 'Error / Relative Error');
            title(app.UIAxes, ['Error Analysis - ', selectedMaterial]);
            legend(app.UIAxes, 'show');
            grid(app.UIAxes, 'on');


        end

        % Button pushed function: MeasurePointButton
        function MeasurePointButtonPushed(app, event)
            %MINA
            selectedMaterial = app.MaterialsDropDown.Value;                %get selected material from the drop down menu

            trueValue = app.TrueDistanceEditField.Value;                   % Get true distance (user input from ruler)

            measuredValue = app.sensor.read();                             % Read measured value from ultrasonic sensor

            app.trueValues(end+1) = trueValue;
            app.measuredValues(end+1) = measuredValue;

            app.simulationCount = app.simulationCount + 1;                 %increase simulation count
            app.simulationData{app.simulationCount} = struct('material', selectedMaterial, 'true', trueValue, 'measured', measuredValue);


            % Update and plot data
            cla(app.UIAxes);
            hold(app.UIAxes, 'on');                                        %allows multiple points to be graphed at once
            for k = 1:app.simulationCount
                appData = app.simulationData{k};
                plot(app.UIAxes, appData.true, appData.measured, 'o-');    %plot the true values against the measured values
            end
            hold(app.UIAxes, 'off');

            %title, and labels

            xlabel(app.UIAxes, 'True Distance (m)');
            ylabel(app.UIAxes, 'Measured Distance (m)');
            title(app.UIAxes, 'True vs Measured Distance');
        end

        % Button pushed function: DerivativesButton
        function DerivativesButtonPushed(app, event)
            %ABID
            if isempty(app.sensor)                                                    %check if sensor is initialized
                uialert(app.UIFigure, 'Sensor not initialized!', 'Error');
                return;
            end

            % Capture distance data
            duration = 5;                                                          % set duration for 5 seconds
            t = [];                                                                %include blank arrays for time and distance
            d = [];
            tstart = tic;                                                          %starts timing

            while toc(tstart) < duration
                d_curr = app.sensor.read();                                        %reads current sensor value
                t_curr = toc(tstart);                                              %gets current time
                t(end+1) = t_curr;                                                 %adds new value to end of time vector
                d(end+1) = d_curr;                                                 %adds new value to end of distance vector
                pause(0.05);
            end

            t = t(:);                                                              % ensures column vectors
            d = d(:);


            if isempty(app.trueValues) || isempty(app.measuredValues)
                corrected_d = d;
            else
                Order = 3;                                                         % use 3rd order for the corrected distances
                p = polyfit(app.trueValues, app.measuredValues, Order);            %gets coefficients for polynomial model
                corrected_d = polyval(p, d);                                       % corrected distances using polyval
            end

            % Derivatives
            v_forward = app.forward_difference(t, corrected_d);                    %use the functions we created earlier for Newton's central difference and forward difference
            v_central = app.central_difference(t, corrected_d);

            % Calculate average velocities:
            avg_forward = mean(v_forward);
            avg_central = mean(v_central);

            % Plot graph :
            cla(app.UIAxes);
            hold(app.UIAxes, 'on');                                                %holds graph to allow multiple things be plotted
            plot(app.UIAxes, t, corrected_d, '-b', 'LineWidth', 2, 'DisplayName', 'Distance (corrected)');
            plot(app.UIAxes, t(1:end-1), v_forward, '--r', 'LineWidth', 1.5, 'DisplayName', 'Forward Diff Velocity');
            plot(app.UIAxes, t(2:end-1), v_central, '--g', 'LineWidth', 1.5, 'DisplayName', 'Central Diff Velocity');
            hold(app.UIAxes, 'off');

            %labels, title, and legend
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Distance / Velocity (m / m/s)');
            title(app.UIAxes, 'Distance and Velocity Analysis');
            legend(app.UIAxes, 'show');
            grid(app.UIAxes, 'on');

            %use uialerts to show average forward velocity and average central velocity in the GUI


            uialert(app.UIFigure, ['Average Forward Velocity: ', num2str(avg_forward)], 'Forward Velocity', 'Icon', 'info');
            uialert(app.UIFigure, ['Average Central Velocity: ', num2str(avg_central)], 'Central Velocity', 'Icon', 'info');


        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 709 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Icon = fullfile(pathToMLAPP, 'wsu-primary-stacked-reversed300.jpg');

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {54, 46, 44, 56, '1.44x', 46, 33, 52, '1x', 37, 63};
            app.GridLayout.RowHeight = {22, 22, '2.13x', 22, '1.83x', 22, '1.22x', 22, 22, 22, 22, '1x', 22};
            app.GridLayout.ColumnSpacing = 7.66666666666667;
            app.GridLayout.Padding = [7.66666666666667 10 7.66666666666667 10];

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Layout.Row = [1 10];
            app.UIAxes.Layout.Column = [5 11];

            % Create InitializeArduinoButton
            app.InitializeArduinoButton = uibutton(app.GridLayout, 'push');
            app.InitializeArduinoButton.ButtonPushedFcn = createCallbackFcn(app, @InitializeArduinoButtonPushed, true);
            app.InitializeArduinoButton.BackgroundColor = [0.0745 0.6235 1];
            app.InitializeArduinoButton.FontWeight = 'bold';
            app.InitializeArduinoButton.Layout.Row = [1 2];
            app.InitializeArduinoButton.Layout.Column = [1 2];
            app.InitializeArduinoButton.Text = 'Initialize Arduino';

            % Create StartMonitoringButton
            app.StartMonitoringButton = uibutton(app.GridLayout, 'push');
            app.StartMonitoringButton.ButtonPushedFcn = createCallbackFcn(app, @StartMonitoringButtonPushed, true);
            app.StartMonitoringButton.BackgroundColor = [0 1 0];
            app.StartMonitoringButton.Layout.Row = 12;
            app.StartMonitoringButton.Layout.Column = [1 9];
            app.StartMonitoringButton.Text = 'Start Monitoring';

            % Create StopMonitoringButton
            app.StopMonitoringButton = uibutton(app.GridLayout, 'push');
            app.StopMonitoringButton.ButtonPushedFcn = createCallbackFcn(app, @StopMonitoringButtonPushed, true);
            app.StopMonitoringButton.BackgroundColor = [1 1 0.0667];
            app.StopMonitoringButton.Layout.Row = 13;
            app.StopMonitoringButton.Layout.Column = [1 9];
            app.StopMonitoringButton.Text = 'Stop Monitoring';

            % Create PlotallGraphsButton
            app.PlotallGraphsButton = uibutton(app.GridLayout, 'push');
            app.PlotallGraphsButton.ButtonPushedFcn = createCallbackFcn(app, @PlotallGraphsButtonPushed, true);
            app.PlotallGraphsButton.BackgroundColor = [1 0 1];
            app.PlotallGraphsButton.Layout.Row = 3;
            app.PlotallGraphsButton.Layout.Column = [1 2];
            app.PlotallGraphsButton.Text = 'Plot all Graphs';

            % Create ClearGraphButton
            app.ClearGraphButton = uibutton(app.GridLayout, 'push');
            app.ClearGraphButton.ButtonPushedFcn = createCallbackFcn(app, @ClearGraphButtonPushed, true);
            app.ClearGraphButton.BackgroundColor = [0.9294 0.6941 0.1255];
            app.ClearGraphButton.Layout.Row = 3;
            app.ClearGraphButton.Layout.Column = [3 4];
            app.ClearGraphButton.Text = 'Clear Graph';

            % Create OrderforModelDropDownLabel
            app.OrderforModelDropDownLabel = uilabel(app.GridLayout);
            app.OrderforModelDropDownLabel.Layout.Row = 9;
            app.OrderforModelDropDownLabel.Layout.Column = [1 2];
            app.OrderforModelDropDownLabel.Text = 'Order for Model';

            % Create OrderforModelDropDown
            app.OrderforModelDropDown = uidropdown(app.GridLayout);
            app.OrderforModelDropDown.Items = {'1st Order', '2nd Order', '3rd Order'};
            app.OrderforModelDropDown.ValueChangedFcn = createCallbackFcn(app, @OrderforModelDropDownValueChanged, true);
            app.OrderforModelDropDown.Layout.Row = 9;
            app.OrderforModelDropDown.Layout.Column = [3 4];
            app.OrderforModelDropDown.Value = '1st Order';

            % Create MaterialsDropDownLabel
            app.MaterialsDropDownLabel = uilabel(app.GridLayout);
            app.MaterialsDropDownLabel.HorizontalAlignment = 'center';
            app.MaterialsDropDownLabel.Layout.Row = 5;
            app.MaterialsDropDownLabel.Layout.Column = [1 2];
            app.MaterialsDropDownLabel.Text = 'Materials';

            % Create MaterialsDropDown
            app.MaterialsDropDown = uidropdown(app.GridLayout);
            app.MaterialsDropDown.Items = {'Cotton', 'Tin Foil', 'Book'};
            app.MaterialsDropDown.Layout.Row = 5;
            app.MaterialsDropDown.Layout.Column = [3 4];
            app.MaterialsDropDown.Value = 'Cotton';

            % Create RESETButton
            app.RESETButton = uibutton(app.GridLayout, 'push');
            app.RESETButton.ButtonPushedFcn = createCallbackFcn(app, @RESETButtonPushed, true);
            app.RESETButton.BackgroundColor = [1 0 0];
            app.RESETButton.FontWeight = 'bold';
            app.RESETButton.FontAngle = 'italic';
            app.RESETButton.Layout.Row = [1 2];
            app.RESETButton.Layout.Column = [3 4];
            app.RESETButton.Text = 'RESET';

            % Create TrueDistanceEditFieldLabel
            app.TrueDistanceEditFieldLabel = uilabel(app.GridLayout);
            app.TrueDistanceEditFieldLabel.HorizontalAlignment = 'center';
            app.TrueDistanceEditFieldLabel.Layout.Row = 6;
            app.TrueDistanceEditFieldLabel.Layout.Column = [1 2];
            app.TrueDistanceEditFieldLabel.Text = 'True Distance';

            % Create TrueDistanceEditField
            app.TrueDistanceEditField = uieditfield(app.GridLayout, 'numeric');
            app.TrueDistanceEditField.Layout.Row = 6;
            app.TrueDistanceEditField.Layout.Column = [3 4];

            % Create MeasurePointButton
            app.MeasurePointButton = uibutton(app.GridLayout, 'push');
            app.MeasurePointButton.ButtonPushedFcn = createCallbackFcn(app, @MeasurePointButtonPushed, true);
            app.MeasurePointButton.Layout.Row = 7;
            app.MeasurePointButton.Layout.Column = [1 2];
            app.MeasurePointButton.Text = 'Measure Point';

            % Create DerivativesButton
            app.DerivativesButton = uibutton(app.GridLayout, 'push');
            app.DerivativesButton.ButtonPushedFcn = createCallbackFcn(app, @DerivativesButtonPushed, true);
            app.DerivativesButton.Layout.Row = 11;
            app.DerivativesButton.Layout.Column = [1 4];
            app.DerivativesButton.Text = 'Derivatives';

            % Create ErrorAnalysisButton
            app.ErrorAnalysisButton = uibutton(app.GridLayout, 'push');
            app.ErrorAnalysisButton.ButtonPushedFcn = createCallbackFcn(app, @ErrorAnalysisButtonPushed, true);
            app.ErrorAnalysisButton.Layout.Row = 7;
            app.ErrorAnalysisButton.Layout.Column = [3 4];
            app.ErrorAnalysisButton.Text = 'Error Analysis';

            % Create Image
            app.Image = uiimage(app.GridLayout);
            app.Image.Layout.Row = [12 13];
            app.Image.Layout.Column = [10 11];
            app.Image.HorizontalAlignment = 'right';
            app.Image.ImageSource = 'waynelogo.png';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI2_code

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end