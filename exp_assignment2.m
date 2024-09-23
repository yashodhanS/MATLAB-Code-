% making sure that we are starting on a clear workspace
close all;
clearvars;
Screen('CloseAll');
sca;

InitializePsychSound(1);
nrchannels = 2;
freq = 48000;
repetitions = 1;
beepLengthSecs = 0.3;
beepPauseTime = 1;
startCue = 0;
waitForDeviceStart = 1;
pahandle = PsychPortAudio('Open', [], 1, 1, freq, nrchannels);
PsychPortAudio('Volume', pahandle, 0.5);
myBeep = MakeBeep(500, beepLengthSecs, freq);
PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
HideCursor;

% This will setup all necessary psychtoolbox functionalities
PsychDefaultSetup(2);

% initialising the random seed;
rand('seed', sum(100 * clock));

% Skipping some diagnistic tests so as to bypass some errors. Use this line
% only when you are debugging/preparing/testing the script. These are necessary
% tests when you do a real experiment. So remove this line when you are
% doing serious stuff.
%Screen('Preference', 'SkipSyncTests', 1)
Screen('Preference', 'SkipSyncTests',1)
screenNumber = max(Screen('Screens')); % This will set the screen number to external monitor, if there is one.

% Define black, white and black
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);
res = get(0,'screensize');

currentFolder = pwd;

sub_no = input('Enter the subject ID - ');

defaultFileName = fullfile(currentFolder, '*.csv');
[baseFileName, folder] = uiputfile(defaultFileName, 'Specify a filename ');

%this line will open the psychtoolbox screen
[window,windowRect]=PsychImaging('OpenWindow', screenNumber , black);%, [0 0 res(3)/2 res(4)/2]);

% a very important line; this is necessary to present/draw stimulus from background to the monitor screen
Screen('Flip', window);

% Flip interval is the time taken to refresh the screen. For a monitor with
% 60 Hz refresh rate, the flip interval will be 0.0167 seconds, or 16 milliseconds
ifi = Screen('GetFlipInterval', window);

% Font size of the test; 60 is very high; 22 is a small readable size
Screen('TextSize', window, 20);

% Checking the maximum priority level; this should ideally be 1 for windows and Linux, 9
% for MacOS,
topPriorityLevel = MaxPriority(window);

% storing the cordinates of the centre of the screen
[xCenter, yCenter] = RectCenter(windowRect);


% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Defining some keys for later use
esc = KbName('ESCAPE');
lKey = KbName('LeftArrow');
rKey = KbName('RightArrow');
uKey = KbName('UpArrow');

%initialisation
sub=[];
rt_vector = [];
trial_vector = [];
sub_age = [];
sub_gen = [];
responseKey = []; 
QuadrantType = [];
Accuracy_2 = [];
Accuracy_1 = [];
Matching = [];

%giving colors a name for later use
rcolor = [255 0 0];
gcolor = [0 255 0];
bcolor = [0 0 255];
white = [255 255 255];
pw = 3;
timeBetweenTrials = 1;
breakAfterTrials = 240;

triangleSize = 50; % Adjust as needed

baseTriangle = [
    0, -triangleSize; % Top vertex
    -triangleSize/2, triangleSize/2; % Bottom-left vertex
    triangleSize/2, triangleSize/2 % Bottom-right vertex
];

% Pre-define left (90°) and right (270°) directions
directions = [90, 270]; % 270 for left, 90 for right

% Define 8 locations (2 in each quadrant, aligned horizontally) for Visual
% Search 
locations = [
    xCenter - 250, yCenter - 250; % Top-left quadrant (left triangle)
    xCenter - 150, yCenter - 250; % Top-left quadrant (right triangle)
    
    xCenter + 150, yCenter - 250; % Top-right quadrant (left triangle)
    xCenter + 250, yCenter - 250; % Top-right quadrant (right triangle)
    
    xCenter - 250, yCenter + 250; % Bottom-left quadrant (left triangle)
    xCenter - 150, yCenter + 250; % Bottom-left quadrant (right triangle)
    
    xCenter + 150, yCenter + 250; % Bottom-right quadrant (left triangle)
    xCenter + 250, yCenter + 250  % Bottom-right quadrant (right triangle)
];

% Define positions for the quadrants for dot probe task
quadrantPositions = [
    xCenter - 200, yCenter - 200;  % Quadrant 1
    xCenter + 200, yCenter - 200;  % Quadrant 2
    xCenter - 200, yCenter + 200;  % Quadrant 3
    xCenter + 200, yCenter + 200   % Quadrant 4
    ];


% Randomly assign high, low, and intermediate probability quadrants
quadrantAssignments = randperm(4); % Randomize the order of the 4 quadrants

highProbQuadrant = quadrantAssignments(1); % High probability quadrant (37.5%)
lowProbQuadrant = quadrantAssignments(2); % Low probability quadrant (12.5%)
intermediateProbQuadrants = quadrantAssignments(3:4); % Intermediate probability quadrants (25%)

% Run experiment for 5 trials
numTrials = 3;
targetQuadrantHistory = zeros(1, numTrials); % To record target quadrant in each trial

instruction = ['Instruction'];

DrawFormattedText(window, instruction,'center', 'center', white);
Screen(window, 'Flip');
pause(1);
KbWait();

for trial = 1:numTrials
    % Set up probabilities for the target quadrant
    condi_ran = randperm(100);
    rep_ran = randperm(100);

    if condi_ran(1) > 66
        con = 3; % Intermediate probability
    elseif condi_ran(1) < 67
        if rep_ran(1) > 65
            con = 2; % Low probability
        else
            con = 1; % High probability
        end
    end

    % Assign the target quadrant based on 'con'
    if con == 1
        targetQuadrant = highProbQuadrant; % High probability quadrant
        quadrantType = 'H';
    elseif con == 2
        targetQuadrant = lowProbQuadrant; % Low probability quadrant
        quadrantType = 'L';
    else
        targetQuadrant = randsample(intermediateProbQuadrants, 1); % One of the intermediate probability quadrants
        quadrantType = 'I';
    end

    
    targetQuadrantHistory(trial) = targetQuadrant; % Store the target quadrant

    % Initialize an array to hold the rotation angles for all triangles
    rotationAngles = zeros(1, 8); % Pre-allocate rotation angles array

    % Loop over quadrants for Visual Search 
    for quadrant = 1:4
        % Get the two indices corresponding to the current quadrant
        indices = (quadrant-1)*2 + 1 : quadrant*2;
        
        if quadrant == targetQuadrant
            % For the target quadrant, both triangles face the same direction (left or right)
            targetDirection = directions(randi(2)); % Randomly choose left (270°) or right (90°)
            rotationAngles(indices) = targetDirection; % Assign the same direction to both triangles
        else
            % For other quadrants, randomly decide:
            % 1. Either face away from each other (opposite directions)
            % 2. Or face towards each other (same direction)
            faceCondition = randi(2); % 1 for away, 2 for towards

            if faceCondition == 1
                % Face away from each other (one left, one right)
                rotationAngles(indices(1)) = directions(1); % Right (90°)
                rotationAngles(indices(2)) = directions(2); % Left (270°)
            else
                % Face towards each other (both left or both right)
                rotationAngles(indices(1)) = directions(2); % Left (270°)
                rotationAngles(indices(2)) = directions(1); % Right (90°)
            end
        end
    end
    
    % Dot Probe Task Part 1: Display 'e' before triangle task
    firstEQuad = randi(4); % Randomly select quadrant for first 'e'
    ePosition1 = quadrantPositions(firstEQuad, :); % Get position for the first 'e'
    
    % Draw the first 'e' in the selected quadrant
    DrawFormattedText(window, 'e', ePosition1(1), ePosition1(2), [1 1 1]); 
    Screen('Flip', window);
    
    % Wait for 300ms
    WaitSecs(1);

    % Draw the triangles with their assigned directions for Visual Search 
    for triangle = 1:8
        % Get the current location and rotation angle
        loc = locations(triangle, :);
        angle = rotationAngles(triangle);
        
        % Rotate the triangle by the specified angle
        rotatedTriangle = RotateTriangle(baseTriangle, angle);
        
        % Translate the triangle to the desired location
        translatedTriangle = [rotatedTriangle(:, 1) + loc(1), rotatedTriangle(:, 2) + loc(2)];
        
        % Draw the triangle
        Screen('FillPoly', window, [1 0 0], translatedTriangle); % Red color
    end

    % Flip to the screen to show the stimuli
    startTime = Screen('Flip', window);

    rt = 0;
    resp = 0;

    % Collect participant's response (left or right)
    % Assuming key responses: 'LeftArrow' for left, 'RightArrow' for right, 'Escape' to exit

   % Wait for a response
    responseMade = false;
     % Store which key was pressed
    while ~responseMade
        [~, keyCode] = KbStrokeWait;
        if strcmp(KbName(keyCode), 'Escape')
            sca;
            return;
        elseif strcmp(KbName(keyCode), 'LeftArrow')
            responseKey = 'Left';
            responseMade = true;
            responseangle = 270;
        elseif strcmp(KbName(keyCode), 'RightArrow')
            responseKey = 'Right';
            responseMade = true;
            responseangle = 90;
        end
    end

    

    % Determine if the response is correct
    if responseangle == targetDirection && targetDirection == 90
        accuracy_2 = 1;
    elseif responseangle == targetDirection && targetDirection == 270
        accuracy_2 = 1;
    else
        PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
        accuracy_2 = 0;
    end

    % Display feedback for 1 second
    Screen('Flip', window);
    WaitSecs(1);

    
    % Dot Probe Task Part 2: Display 'e' after triangle task
    secondEQuad = randi(4); % Randomly select quadrant for second 'e'
    ePosition2 = quadrantPositions(secondEQuad, :); % Get position for the second 'e'
    
    % Draw the second 'e' in the selected quadrant
    DrawFormattedText(window, 'e', ePosition2(1), ePosition2(2), [1 1 1]);
    Screen('Flip', window);
    
    % Wait for a response: same ('s') or different ('d')
    responseMade = false;
    while ~responseMade
        [~, keyCode] = KbStrokeWait;
        if strcmp(KbName(keyCode), 'Escape')
            clear all
            close all
            sca;
            return;
        elseif strcmp(KbName(keyCode), 's')  % 's' for same
            responseMade = true;
            if secondEQuad == firstEQuad
           
                accuracy_1 = 1;
            else
                PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
                accuracy_1 = 0;
            end
        elseif strcmp(KbName(keyCode), 'd')  % 'd' for different
            responseMade = true;
            if secondEQuad ~= firstEQuad
                
                accuracy_1 = 1;
            else
                PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
                accuracy_1 = 0;
            end
        end
    end
    
    if firstEQuad == targetQuadrant %Testing if the memory probe and Target appear in same quadrant 
        match = 'm'; 
    else
        match = 'n';
    end 

 % Provide a short break after a certain number of trials
    if mod(trial,breakAfterTrials) == 0
        Screen('DrawText',window,'Break time. Press space bar when you''re ready to continue', xCenter, yCenter, white);
        Screen('Flip',window)
        % Wait for subject to press spacebar
        while 1
            [keyIsDown,secs,keyCode] = KbCheck;
            if keyCode(KbName('space')) == 1
                break
            end
        end
    else

        % Pause between trials
        if timeBetweenTrials == 0
            while 1 % Wait for space
                [keyIsDown,secs,keyCode] = KbCheck;
                if keyCode(KbName('space'))==1
                    break
                end
            end
        else
            WaitSecs(timeBetweenTrials);
        end
    end

    QuadrantType = cat(1,QuadrantType,quadrantType);
    Accuracy_2 = cat(1, Accuracy_2,accuracy_2);
    Accuracy_1 = cat(1, Accuracy_1, accuracy_1);
    Matching = cat(1, Matching, match);

end

% Close the window after 5 trials
Screen('CloseAll');
close all;
sca;
return

% Function to rotate the triangle
function rotated = RotateTriangle(vertices, angle)
    % Convert angle to radians
    rad = deg2rad(angle);
    
    % Rotation matrix
    rotationMatrix = [
        cos(rad), -sin(rad);
        sin(rad), cos(rad)
    ];
    
    % Apply the rotation matrix to the vertices
    rotated = (rotationMatrix * vertices')';
end