%{
----------------------------------------------------------------------------
This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA
----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}

function TwoAFCTraining
% This protocol sets up the task for early training
% Written by Josh Sanders, 10/2014.
% Modified by Paul Masset, 02/2015.
% Modified by Michael Lagler, 05/2018.
% Modified by Paul Anderson, 10/2024.

% SETUP
% You will need:
% - A Pulse Pal with software installed on this computer
% - A BNC cable between Bpod's BNC Output 1 and Pulse Pal's Trigger channel 1
% - Left and right speakers connected to Pulse Pal's output channels 1 and 2 respectively

global BpodSystem

%% Task parameters
global TaskParameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters)) 
    % If not loading existing task settings we need to define them
    % Make 2 panel to save space
 
    
    TaskParameters.GUI.ClickSound           = 0;
    TaskParameters.GUI.PunSound             = 1;
    TaskParameters.GUI.PunLED               = 0;
    TaskParameters.GUI.GraceEndIndicator    = 1; % This controls the GraceEndIndicator sound (0 = OFF, 1 = ON)
    TaskParameters.GUI.StimulusDelayMin     = 0.15;
    TaskParameters.GUI.StimulusDelayMax     = 0.25;
    TaskParameters.GUI.StimulusDelayExp     = 0.2;
    TaskParameters.GUI.MinimumRewardDelay   = 0.01;
    TaskParameters.GUI.MaximumRewardDelay   = 0.03;
    TaskParameters.GUI.ExponentRewardDelay  = 0.02;
    TaskParameters.GUIPanels.Panel1 = {'ClickSound','PunSound','PunLED','GraceEndIndicator','StimulusDelayMin'...
        ,'StimulusDelayMax','StimulusDelayExp','MinimumRewardDelay','MaximumRewardDelay','ExponentRewardDelay'};    

    
    TaskParameters.GUI.RewardGrace          = 0.1;
    TaskParameters.GUI.TimeForResponse      = 30; % Time after sampling for subject to respond (s)
    TaskParameters.GUI.RewardAmountLeft     = 10;
    TaskParameters.GUI.RewardAmountRight    = 10;
    TaskParameters.GUI.StimulusDuration     = 0.6; % Duration of the sound
    TaskParameters.GUI.MaxMinimumSamplingDuration     = 0.55; % max Minimum sampling duration to have a valid trial
    TaskParameters.GUI.InitialMinimumSamplingDuration = 0.2; % Minimum sampling duration to have a valid trial at begining of session
    TaskParameters.GUI.SumRates             = 100; % Sum of the firing rates
    TaskParameters.GUI.MaxPortInTime        = 30;
    TaskParameters.GUI.EarlyTimeOut         = 5;
    TaskParameters.GUI.RewardBias           = 1; % This is reward counter bias to counteract choice bias
    TaskParameters.GUI.RewardBWindow        = 20;
    TaskParameters.GUI.RewardBFactor        = 1;
    TaskParameters.GUI.LongSamplingRew      = 2;
    TaskParameters.GUIPanels.Panel2 = {'RewardGrace','TimeForResponse','RewardAmountLeft','RewardAmountRight',...
        'StimulusDuration','MaxMinimumSamplingDuration','InitialMinimumSamplingDuration','SumRates',...
        'MaxPortInTime','EarlyTimeOut','RewardBias','RewardBWindow','RewardBFactor','LongSamplingRew'};   
    
    % These should maybe not be in the GUI?
    TaskParameters.GUI.MaxTrials            = 9999;
    TaskParameters.GUI.WindowSize           = 20;
    TaskParameters.GUI.Threshold            = 0.8;
    TaskParameters.GUI.StepSize             = 0.01;
    TaskParameters.GUI.Alpha                = 0.01;
    TaskParameters.GUIPanels.Panel3 = {'MaxTrials','WindowSize','Threshold','StepSize','Alpha'};   

% Initialize parameter GUI plugin
BpodParameterGUI('init', TaskParameters);

%% Initialize and program Pulse Pal
if ~BpodSystem.EmulatorMode

    global PulsePalSystem
    if isempty(PulsePalSystem) || (ishandle(PulsePalSystem) && ~isvalid(PulsePalSystem))
        try
            PulsePal 
        catch
            % error('Can''t initalise Pulsepal...')
        end
    end   
    
    load EarlyWithdrawalProgram.mat
    PulsePalEarlyWithdrawal=ParameterMatrix;
    load PIC_ClickProgram.mat
    ProgramPulsePal(ParameterMatrix);
    OriginalPulsePalMatrix=ParameterMatrix;
end
%% PRE-ALLOCATION
WindowSize = TaskParameters.GUI.WindowSize;
OKTrial(1:(WindowSize+1))=NaN;

%% Define trials
MaxTrials = 5000;
TrialTypes = ceil(rand(1,MaxTrials)*2);
BpodSystem.Data.Custom.TrialTypes = []; % The trial type of each trial completed will be added here

%% Create field for Data structure
BpodSystem.Data.Custom.MinimumSamplingDuration = TaskParameters.GUI.InitialMinimumSamplingDuration;
BpodSystem.Data.Custom.SamplingDuration = [];
BpodSystem.Data.Custom.Threshold = [];
BpodSystem.Data.Custom.WindowSize = [];
BpodSystem.Data.Custom.SamplingValue = [];
BpodSystem.Data.Custom.MinimumRewardDelay = [];
BpodSystem.Data.Custom.MaximumRewardDelay = [];
BpodSystem.Data.Custom.ExponentRewardDelay = [];
BpodSystem.Data.Custom.StimulusDelayMin = [];
BpodSystem.Data.Custom.StimulusDelayMax = [];
BpodSystem.Data.Custom.StimulusDelayExp = [];
BpodSystem.Data.Custom.SampledTrial = [];
BpodSystem.Data.Custom.LeftChoice = [];
BpodSystem.Data.Custom.RightChoice = [];
BpodSystem.Data.Custom.LongSamplingEvent = [];
BpodSystem.Data.Custom.RewardCounterBias = [];
BpodSystem.Data.Custom.RewardedTrial = [];
BpodSystem.Data.Custom.ChosenDirection = [];
BpodSystem.Data.Custom.TotalRewardGivenLeft = [];
BpodSystem.Data.Custom.TotalRewardGivenRight = [];
BpodSystem.Data.Custom.CurrentMeanRewardDelay = [];
BpodSystem.Data.Custom.CurrentWindow = [];

%% Initialize Live Display Plot
BpodSystem.ProtocolFigures.LiveDispFig = figure('Position',[900 450 1000 600],'name','Live session display','numbertitle','off','MenuBar','none','Resize','off');
ha = axes('units','normalized', 'position',[0 0 1 1]);
uistack(ha,'bottom');
% BG = imread('LiveSessionDataBG.bmp');
% image(BG); axis off;

%% Initialize Outcome Plots (sampling threshold and sampling duration)
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [0.075 0.66 0.9 0.25],'TickDir','out','YColor',[1 1 1],'XColor',[1 1 1],'FontSize',6);
% OutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',(TrialTypes==1)');
SideOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',(TrialTypes==1)');
%% Sampling Theshold Plot
BpodSystem.ProtocolFigures.LivePlot1 = axes('position',[0.07  0.20  0.42  0.375],'TickDir','out','YColor',[1 1 1],'XColor',[1 1 1],'FontSize',6);
plot(0,0,'-b','LineWidth',2);
hold on;
plot(0,0,'--k','LineWidth',2);
xlim([0 50]);
ylim([0 1]);ylim manual;
livePlot1Handle = BpodSystem.ProtocolFigures.LivePlot1;
set(livePlot1Handle,'YTickLabelMode','manual','YTickMode','manual','Box','off','TickDir','out');
set(livePlot1Handle.Title,'String','Sampling Threshold','FontSize',8,'Color','k','FontName','arial','fontweight','bold');
set(livePlot1Handle.YLabel,'String','% trials above threshold','FontSize',8,'Color','k','FontName','arial','fontweight','bold');
set(livePlot1Handle.XLabel,'String','trial #','FontSize',8,'Color','k','FontName','arial','fontweight','bold');

%% Sampling Distribution Plot
BpodSystem.ProtocolFigures.LivePlot2 = axes('position',[0.56  0.20  0.42  0.375],'TickDir','out','YColor',[1 1 1],'XColor',[1 1 1],'FontSize',6);
plot([0.2 0.2],[0 1],'--k','LineWidth',1);hold on
text(0.01,0.8,['Sampling Duration: ',num2str(0),'ms'],'FontSize',8,'Color','k');
text(0.01,0.75,['Sampling DropOuts: ',num2str(0),'%'],'FontSize',8,'Color','k');
text(0.01,0.7,['Long Sampling Events: ',num2str(0)],'FontSize',8,'Color','k');
plot(0,0,'-b','LineWidth',2);
xlim([0 0.6]);xlim manual;
ylim([0 1]);ylim manual;
livePlot2Handle = BpodSystem.ProtocolFigures.LivePlot2;
set(livePlot2Handle,'XTickLabelMode','manual','XTickMode','manual',...
    'YTickLabelMode','manual','YTickMode','manual','Box','off','Tickdir','out');
set(livePlot2Handle.Title, 'String', 'Sampling Distribution', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(livePlot2Handle.YLabel, 'String', 'P(sampling duration)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(livePlot2Handle.XLabel, 'String', 'sampling duration (s)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');

%% Initialize Rest of Outcome Plots
pause(0.5)
BpodSystem.GUIHandles.ProtocolNameDisplay = uicontrol('Style','text','String',BpodSystem.Status.CurrentProtocolName,'Position',[170 67 175 18],'FontWeight','bold','FontSize',10,'ForegroundColor',[1 1 1],'BackgroundColor',[.45 .45 .45]);
BpodSystem.GUIHandles.SubjectNameDisplay = uicontrol('Style', 'text', 'String', BpodSystem.GUIData.SubjectName, 'Position', [170 40 175 18], 'FontWeight', 'bold', 'FontSize', 10, 'ForegroundColor', [1 1 1], 'BackgroundColor', [.45 .45 .45]);
BpodSystem.GUIHandles.starttime = uicontrol('Style', 'text', 'String', BpodSystem.GUIData.SettingsFileName, 'Position', [170 13 175 18], 'FontWeight', 'bold', 'FontSize', 10, 'ForegroundColor', [1 1 1], 'BackgroundColor', [.45 .45 .45]);
BpodSystem.GUIHandles.TrialNumberDisplay = uicontrol('Style','text','String','','Position',[520 67 105 18],'FontWeight','bold','FontSize',10,'ForegroundColor',[1 1 1],'BackgroundColor',[.44 .44 .44]);
BpodSystem.GUIHandles.TrialTypeDisplay = uicontrol('Style', 'text', 'String', '', 'Position', [520 40 105 18], 'FontWeight', 'bold', 'FontSize', 10, 'ForegroundColor', [1 1 1], 'BackgroundColor', [.44 .44 .44]);

%% Initialize Bias Plots (Choice and WT Bias)
BpodSystem.ProtocolFigures.Bias = figure('Position',[900 70 1000 450],'name','Bias Report','numbertitle','off','MenuBar','none','Resize','off');

%% Choice Bias Plot
BpodSystem.ProtocolFigures.ChoiceBias = axes('position',[0.05  0.1  0.275  0.65],'TickDir','out','YColor','k','XColor','k','FontSize',6);
plot(1,1,'r','MarkerSize',20);
hold on;
plot(1,1,'b','MarkerSize',20);
legend('Left Choices','Right Choices');
line([0,5000],[0.5,0.5],'Color','k','LineStyle','--');
text(1,1.25,['Choice Bias: ',num2str(0),' %-diff'],'FontSize',8,'Color','k');
text(1,1.2,['Reward Bias: ',num2str(0),' µl'],'FontSize',8,'Color','k');
text(1,1.15,['Left reward, total: ',num2str(0),' µl','; Left reward, current: ',num2str(0),' µl'],'FontSize',8,'Color','k');
text(1,1.1,['Right reward, total: ',num2str(0),' µl','; Right reward, current: ',num2str(0),' µl'],'FontSize',8,'Color','k');
text(1,1.35,['Trial: ',num2str(0)],'FontSize',12,'Color','k');
ylim([0 1]);ylim manual;
set(BpodSystem.ProtocolFigures.ChoiceBias,'YTickLabelMode','manual');
set(BpodSystem.ProtocolFigures.ChoiceBias,'YTickMode','manual');
set(BpodSystem.ProtocolFigures.ChoiceBias,'Box','off');
set(BpodSystem.ProtocolFigures.ChoiceBias,'Tickdir','out');
set(BpodSystem.ProtocolFigures.ChoiceBias,'YTick',0:0.1:1);
set(BpodSystem.ProtocolFigures.ChoiceBias,'YTickLabel',{'0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'});
ChoiceBiasAttribs = get(BpodSystem.ProtocolFigures.ChoiceBias);
set(ChoiceBiasAttribs.Title, 'String', 'Choice Bias', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(ChoiceBiasAttribs.YLabel, 'String', 'choice (%)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(ChoiceBiasAttribs.XLabel, 'String', 'trial #', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');

%% WT Bias Plot
BpodSystem.ProtocolFigures.WTBias = axes('position',[0.385  0.1  0.275  0.65],'TickDir','out','YColor','k','XColor','k','FontSize',6);
plot(1,1,'r','MarkerSize',20);
hold on;
plot(1,1,'b','MarkerSize',20);
legend('Left Choices','Right Choices');
text(1,1.25,['Left Reward Delay Drop Outs: ',num2str(0),' %'],'FontSize',8,'Color','k');
text(1,1.2,['Right Reward Delay Drop Outs: ',num2str(0),' %'],'FontSize',8,'Color','k');
text(1,1.15,['Mean Waiting Time: ',num2str(0),' s'],'FontSize',8,'Color','k');
ylim([0 1]);ylim manual;
xlim([0 50]);
set(BpodSystem.ProtocolFigures.WTBias,'YTickLabelMode','manual');
set(BpodSystem.ProtocolFigures.WTBias,'YTickMode','manual');
set(BpodSystem.ProtocolFigures.WTBias,'Box','off');
set(BpodSystem.ProtocolFigures.WTBias,'Tickdir','out');
set(BpodSystem.ProtocolFigures.WTBias,'YTick',0:0.1:1);
set(BpodSystem.ProtocolFigures.WTBias,'YTickLabel',{'0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'});
WTBiasAttribs = get(BpodSystem.ProtocolFigures.WTBias);
set(WTBiasAttribs.Title, 'String', 'Waiting Time Bias', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(WTBiasAttribs.YLabel, 'String', 'Reward Delay Drop Outs (%)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(WTBiasAttribs.XLabel, 'String', 'trial #', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    if BpodSystem.Status.BeingUsed == 1
        
        TaskParameters = BpodParameterGUI('sync',TaskParameters); % Sync parameters with BpodParameterGUI plugin
        
        % Define ValveTimes/RewardAmounts (this is to counterbias sidebias)
        if currentTrial > 1
            if TaskParameters.GUI.RewardBias == 0 || BpodSystem.Data.Custom.ChoiceBias(currentTrial-1) == 0
                BpodSystem.Data.Custom.RewardCounterBias(currentTrial) = 0;
                BpodSystem.Data.Custom.RewardAmountLeft(currentTrial) = TaskParameters.GUI.RewardAmountLeft;
                BpodSystem.Data.Custom.RewardAmountRight(currentTrial) = TaskParameters.GUI.RewardAmountRight;
                RL = GetValveTimes(BpodSystem.Data.Custom.RewardAmountLeft(currentTrial),1); % Update reward amounts
                RR = GetValveTimes(BpodSystem.Data.Custom.RewardAmountRight(currentTrial),3); % Update reward amounts
                LeftValveTime = RL;  % Update reward amounts
                RightValveTime = RR; % Update reward amounts
            else
                BpodSystem.Data.Custom.RewardCounterBias(currentTrial) = (abs(BpodSystem.Data.Custom.ChoiceBias(currentTrial-1))* ...
                    TaskParameters.GUI.RewardBFactor) * ((TaskParameters.GUI.RewardAmountLeft+TaskParameters.GUI.RewardAmountRight)/2);
                if BpodSystem.Data.Custom.ChoiceBias(currentTrial-1) > 0
                    BpodSystem.Data.Custom.RewardAmountLeft(currentTrial) = TaskParameters.GUI.RewardAmountLeft - BpodSystem.Data.Custom.RewardCounterBias(currentTrial);
                    BpodSystem.Data.Custom.RewardAmountRight(currentTrial) = TaskParameters.GUI.RewardAmountRight + BpodSystem.Data.Custom.RewardCounterBias(currentTrial);
                else
                    BpodSystem.Data.Custom.RewardAmountLeft(currentTrial) = TaskParameters.GUI.RewardAmountLeft + BpodSystem.Data.Custom.RewardCounterBias(currentTrial);
                    BpodSystem.Data.Custom.RewardAmountRight(currentTrial) = TaskParameters.GUI.RewardAmountRight - BpodSystem.Data.Custom.RewardCounterBias(currentTrial);
                end
                if BpodSystem.Data.Custom.RewardAmountLeft(currentTrial) == 0
                    RL=0;
                else
                    RL = GetValveTimes(BpodSystem.Data.Custom.RewardAmountLeft(currentTrial),1); % Update reward amounts
                end
                if BpodSystem.Data.Custom.RewardAmountRight(currentTrial) == 0
                    RR= 0;
                else
                   RR = GetValveTimes(BpodSystem.Data.Custom.RewardAmountRight(currentTrial),3); % Update reward amounts
                end
                LeftValveTime = RL;  % Update reward amounts
                RightValveTime = RR; % Update reward amounts
            end
        else
            BpodSystem.Data.Custom.RewardCounterBias(currentTrial) = 0;
            BpodSystem.Data.Custom.RewardAmountLeft(currentTrial) = TaskParameters.GUI.RewardAmountLeft;
            BpodSystem.Data.Custom.RewardAmountRight(currentTrial) = TaskParameters.GUI.RewardAmountRight;
            RL = GetValveTimes(BpodSystem.Data.Custom.RewardAmountLeft(currentTrial),1); % Update reward amounts
            RR = GetValveTimes(BpodSystem.Data.Custom.RewardAmountRight(currentTrial),3); % Update reward amounts
            LeftValveTime = RL;  % Update reward amounts
            RightValveTime = RR; % Update reward amounts
        end
        
        % Establish the reward delay
        RewardDelay = TruncatedExponential(TaskParameters.GUI.MinimumRewardDelay,TaskParameters.GUI.MaximumRewardDelay,TaskParameters.GUI.ExponentRewardDelay); % waiting time that we define
        
        % We add here a random pre-stimulus delay (maximum 0.2 sec)
        StimulusDelayDuration = TruncatedExponential(TaskParameters.GUI.StimulusDelayMin,TaskParameters.GUI.StimulusDelayMax,TaskParameters.GUI.StimulusDelayExp);
        
        % Generate ClickRate (here it will always be a prior of 50/50)
        ClickingRate=ceil(TaskParameters.GUI.SumRates/2);
        
        % Generate the fast and slow click trains
        RightClickTrain = GeneratePoissonClickTrain(ClickingRate, TaskParameters.GUI.StimulusDuration);
        LeftClickTrain = GeneratePoissonClickTrain(ClickingRate, TaskParameters.GUI.StimulusDuration);
        
        % Ensure that click train are not empty and align first click
        if ~isempty(RightClickTrain) && ~isempty(LeftClickTrain)
            RightClickTrain=RightClickTrain-RightClickTrain(1)+LeftClickTrain(1);
        elseif isempty(RightClickTrain) && ~isempty(LeftClickTrain)
            RightClickTrain=LeftClickTrain(1);
        elseif isempty(LeftClickTrain) && ~isempty(RightClickTrain)
            LeftClickTrain=RightClickTrain(1);
        else
            RightClickTrain=1/ClickingRate;
            LeftClickTrain=1/ClickingRate;
        end
        
        % Set the Valve times (this is defining the amount of reward)
        ValveCodeLeft = 1;
        ValveTimeLeft = LeftValveTime;
        ValveCodeRight = 4;
        ValveTimeRight = RightValveTime;
        
        % We are sending the ClickTrain to PulsePal
        if ~BpodSystem.EmulatorMode
            SendCustomPulseTrain(2,RightClickTrain,ones(1,length(RightClickTrain))*5);
            SendCustomPulseTrain(1,LeftClickTrain,ones(1,length(LeftClickTrain))*5);
        end        
        % Read out the minimum sampling duration variable
        MinimumSamplingDuration=BpodSystem.Data.Custom.MinimumSamplingDuration(currentTrial);
        
        % Assemble state matrix
        sma = NewStateMatrix();
        sma = SetGlobalTimer(sma,1,RewardDelay);
        sma = SetGlobalTimer(sma,2,TaskParameters.GUI.MaxPortInTime);
        if TaskParameters.GUI.PunLED == 1
            sma = SetGlobalTimer(sma,3,TaskParameters.GUI.EarlyTimeOut);
            PunLEDTime=0.1;
        else
            sma = SetGlobalTimer(sma,3,0.003);
            PunLEDTime=0;
        end
        
        % STATE: Wait for rat to poke in center port
        sma = AddState(sma,'Name','WaitForCenterPoke',...
            'Timer',0,...
            'StateChangeConditions',{'Port2In','DeliverStimulus'},...
            'OutputActions',{'PWM2',255}); % 255 stands for 100% brightness, 128 for 50% brightness
        
        %% State excluded, not needed for PokeInCenter
        % STATE: Delay after poke before stimulus starts
        sma = AddState(sma,'Name','Delay',...
            'Timer',StimulusDelayDuration,...
            'StateChangeConditions',{'Tup','DeliverStimulus','Port2Out','exit'},...
            'OutputActions',{});
        
        % STATE: Deliver the stimulus until minimum samplign time is reached
        sma = AddState(sma,'Name','DeliverStimulus',...
            'Timer',MinimumSamplingDuration,...
            'StateChangeConditions',{'Tup','StillSampling','Port2Out','EarlyWithdrawalKill'},...
            'OutputActions',{'BNCState',TaskParameters.GUI.ClickSound});
        
        % STATE: Kill sound if withdrew early
        sma = AddState(sma,'Name','EarlyWithdrawalKill',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','EarlyWithdrawalKill2'},...
            'OutputActions',{'BNCState',0});
        
        % STATE: Kill sound if withdrew early 2
        sma=AddState(sma,'Name','EarlyWithdrawalKill2',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','EarlyWithdrawal'},...
            'OutputActions',{'BNCState',TaskParameters.GUI.ClickSound});
        
        % STATE: Carry on delivering the stimulus
        sma = AddState(sma,'Name','StillSampling',...
            'Timer',TaskParameters.GUI.StimulusDuration-MinimumSamplingDuration,...
            'StateChangeConditions',{'Tup','RewardLongWaiting','Port2Out','WaitForResponseKill'},...
            'OutputActions',{'BNCState',TaskParameters.GUI.ClickSound});
        
        % STATE: Early withdrawal punishment with sound and flashing light
        sma=AddState(sma,'Name','EarlyWithdrawal',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','EarlyWithdrawalOn'},...
            'OutputActions',{'GlobalTimerTrig',3});
        
        % STATE: Early withdrawal punishment with sound and flashing light
        sma=AddState(sma,'Name','EarlyWithdrawalOn',...
            'Timer',PunLEDTime,...
            'StateChangeConditions',{'Tup','EarlyWithdrawalOff','GlobalTimer3_End','exit'},...
            'OutputActions',{'PWM2',TaskParameters.GUI.PunLED}); % 255 stands for 100% brightness, 128 for 50% brightness
        
        % STATE: Early withdrawal punishment with sound and flashing light
        sma=AddState(sma,'Name','EarlyWithdrawalOff',...
            'Timer',PunLEDTime,...
            'StateChangeConditions',{'Tup','EarlyWithdrawalOn','GlobalTimer3_End','exit'},...
            'OutputActions',{'PWM2',0});
        
        % STATE: Kill sound if waiting for response
        sma = AddState(sma,'Name','WaitForResponseKill',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForResponseKill2'},...
            'OutputActions',{'BNCState',0});
        
        % STATE: Kill sound if waiting for reponse
        sma = AddState(sma,'Name','WaitForResponseKill2',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForResponse'},...
            'OutputActions',{'BNCState',TaskParameters.GUI.ClickSound});
        
        % STATE: Wait for the rat to poke into one of the response ports
        sma = AddState(sma,'Name','WaitForResponse', ...
            'Timer',TaskParameters.GUI.TimeForResponse,...
            'StateChangeConditions',{'Tup','exit','Port1In','WaitForRewardStartLeft','Port3In','WaitForRewardStartRight'},...
            'OutputActions',{'PWM1',128,'PWM3',128}); % 255 stands for 100% brightness, 128 for 50% brightness
        
        % STATE: If correct side, wait for the reward to be delivered (= ResponseStart for correct trials)
        sma = AddState(sma,'Name','WaitForRewardStartLeft',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForRewardLeft'},...
            'OutputActions',{'GlobalTimerTrig',1});
        
        % STATE: If correct side, wait for the reward to be delivered
        sma = AddState(sma, 'Name','WaitForRewardLeft', ...
            'Timer',RewardDelay,...
            'StateChangeConditions',{'Tup','RewardLeft','Port1Out','WaitForRewardGraceL','GlobalTimer1_End','RewardLeft'},...
            'OutputActions',{});
        
        % STATE: If correct side, wait for the reward to be delivered
        sma = AddState(sma,'Name','WaitForRewardGraceL',...
            'Timer',TaskParameters.GUI.RewardGrace,...
            'StateChangeConditions',{'Tup','exit','Port1In','WaitForRewardLeft','GlobalTimer1_End','RewardLeft','Port3In','exit'},...
            'OutputActions',{});
        
        % STATE: If waited enough, reward gets delivered
        sma = AddState(sma, 'Name','RewardLeft', ...
            'Timer',ValveTimeLeft,...
            'StateChangeConditions',{'Tup','exit'},...
            'OutputActions',{'ValveState',ValveCodeLeft});
        
        % STATE: If correct side, wait for the reward to be delivered (= ResponseStart for correct trials)
        sma = AddState(sma,'Name','WaitForRewardStartRight',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForRewardRight'},...
            'OutputActions',{'GlobalTimerTrig',1});
        
        % STATE: If correct side, wait for the reward to be delivered
        sma = AddState(sma,'Name','WaitForRewardRight',...
            'Timer', RewardDelay,...
            'StateChangeConditions',{'Tup','RewardRight','Port3Out','WaitForRewardGraceR','GlobalTimer1_End','RewardRight'},...
            'OutputActions',{});
        
        % STATE: If correct side, wait for the reward to be delivered
        sma = AddState(sma,'Name','WaitForRewardGraceR',...
            'Timer',TaskParameters.GUI.RewardGrace,...
            'StateChangeConditions',{'Tup','exit','Port3In','WaitForRewardRight','GlobalTimer1_End','RewardRight','Port1In','exit'},...
            'OutputActions',{});
        
        % STATE: If waited enough, reward gets delivered
        sma = AddState(sma,'Name','RewardRight', ...
            'Timer',ValveTimeRight,...
            'StateChangeConditions',{'Tup', 'exit'},...
            'OutputActions',{'ValveState',ValveCodeRight});
        
        % STATE: Check for extra long waiting
        sma = AddState(sma,'Name','RewardLongWaiting',...
            'Timer',TaskParameters.GUI.LongSamplingRew-TaskParameters.GUI.StimulusDuration,...
            'StateChangeConditions',{'Tup','WaitForResponseKill2LW','Port2Out','WaitForResponseKill'},...
            'OutputActions',{'BNCState',0});
        
        % STATE: Kill sound if waiting for response (long wait)
        sma = AddState(sma,'Name','WaitForResponseKillLW',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForResponseKill2LW'},...
            'OutputActions',{'BNCState',0});
        
        % STATE: Kill sound if waiting for reponse (long wait)
        sma = AddState(sma,'Name','WaitForResponseKill2LW',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForResponseLW'},...
            'OutputActions',{'BNCState',TaskParameters.GUI.ClickSound});
        
        % STATE: Wait for the rat to poke into one of the response ports (long wait)
        sma = AddState(sma,'Name','WaitForResponseLW', ...
            'Timer',TaskParameters.GUI.TimeForResponse,...
            'StateChangeConditions',{'Tup','exit','Port1In','WaitForRewardStartLeftLW','Port3In','WaitForRewardStartRightLW'},...
            'OutputActions',{'PWM1',128,'PWM3',128}); % 255 stands for 100% brightness, 128 for 50% brightness
        
        % STATE: If correct side, wait for the reward to be delivered (=
        % ResponseStart for correct trials) (long wait)
        sma = AddState(sma,'Name','WaitForRewardStartLeftLW',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForRewardLeftLW'},...
            'OutputActions',{'GlobalTimerTrig',1});
        
        % STATE: If correct side, wait for the reward to be delivered (long wait)
        sma = AddState(sma, 'Name','WaitForRewardLeftLW', ...
            'Timer',RewardDelay,...
            'StateChangeConditions',{'Tup','RewardLeftLW','Port1Out','WaitForRewardGraceLLW','GlobalTimer1_End','RewardLeftLW'},...
            'OutputActions',{});
        
        % STATE: If correct side, wait for the reward to be delivered (long wait)
        sma = AddState(sma,'Name','WaitForRewardGraceLLW',...
            'Timer',TaskParameters.GUI.RewardGrace,...
            'StateChangeConditions',{'Tup','exit','Port1In','WaitForRewardLeftLW','GlobalTimer1_End','RewardLeftLW','Port3In','exit'},...
            'OutputActions',{});
        
        % STATE: If waited enough, reward gets delivered (long wait)
        sma = AddState(sma, 'Name','RewardLeftLW', ...
            'Timer',ValveTimeLeft*5,...
            'StateChangeConditions',{'Tup','exit'},...
            'OutputActions',{'ValveState',ValveCodeLeft});
        
        % STATE: If correct side, wait for the reward to be delivered (=
        % ResponseStart for correct trials) (long wait)
        sma = AddState(sma,'Name','WaitForRewardStartRightLW',...
            'Timer',0,...
            'StateChangeConditions',{'Tup','WaitForRewardRightLW'},...
            'OutputActions',{'GlobalTimerTrig',1});
        
        % STATE: If correct side, wait for the reward to be delivered (long wait)
        sma = AddState(sma,'Name','WaitForRewardRightLW',...
            'Timer', RewardDelay,...
            'StateChangeConditions',{'Tup','RewardRightLW','Port3Out','WaitForRewardGraceRLW','GlobalTimer1_End','RewardRightLW'},...
            'OutputActions',{});
        
        % STATE: If correct side, wait for the reward to be delivered (long wait)
        sma = AddState(sma,'Name','WaitForRewardGraceRLW',...
            'Timer',TaskParameters.GUI.RewardGrace,...
            'StateChangeConditions',{'Tup','exit','Port3In','WaitForRewardRightLW','GlobalTimer1_End','RewardRightLW','Port1In','exit'},...
            'OutputActions',{});
        
        % STATE: If waited enough, reward gets delivered (long wait)
        sma = AddState(sma,'Name','RewardRightLW', ...
            'Timer',ValveTimeRight*5,...
            'StateChangeConditions',{'Tup', 'exit'},...
            'OutputActions',{'ValveState',ValveCodeRight});
        
        % Run all that
        SendStateMatrix(sma); %try_SendStateMatrix(sma); 
        RawEvents = RunStateMatrix;
        
        % Compute the data we need
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            
            % Store first data that doesn't need computation
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data.RawEvents.Trial;
            
            % Play GraceEndIndicator Sound
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForResponse(1)) ...
                    && (isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRight(1)) && ...
                    isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeft(1))))
                if TaskParameters.GUI.GraceEndIndicator == 1
                    if ~BpodSystem.EmulatorMode
                        ProgramPulsePal(PulsePalEarlyWithdrawal);
                        TriggerPulsePal('11');
                        pause(0.05);
                        ProgramPulsePal(OriginalPulsePalMatrix);
                    end
                end
            end
            
            % Play the early withdrawal sound and give early withdrawal TimeOut
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.EarlyWithdrawalKill(1)) || isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(1)))
                if TaskParameters.GUI.PunSound == 1
                    %% Changing peep sound to white noise after early withdrawal
                    % ProgramPulsePal(PulsePalEarlyWithdrawal);
                    % TriggerPulsePal('11');
                    if ~BpodSystem.EmulatorMode
                        NoiseWaveVoltages=randn(1,1000)*0.5; % 200ms white noise waveform
                        ProgramPulsePalParam(1,12,1); % Sets output channel 1 to use custom train 1
                        ProgramPulsePalParam(2,12,2); % Sets output channel 2 to use custom train 1
                        SendCustomWaveform(1,0.0002,NoiseWaveVoltages); % Uploads noise waveform. Samples are played at 5khz.
                        SendCustomWaveform(2,0.0002,NoiseWaveVoltages); % Uploads noise waveform. Samples are played at 5khz.
                        TriggerPulsePal('11'); % Soft-triggers channels 1 and 2
                        
                        pause(TaskParameters.GUI.EarlyTimeOut); % This is the early withdrawal timeout
                        ProgramPulsePal(OriginalPulsePalMatrix);
                    end
                else
                    pause(TaskParameters.GUI.EarlyTimeOut); % This is the early withdrawal timeout
                end
            end
            
            % Update SettingsParameter from the GUI
            BpodSystem.Data.Custom.StimulusDelayDuration(currentTrial) = StimulusDelayDuration;
            BpodSystem.Data.Custom.StimulusDelayMin(currentTrial) = TaskParameters.GUI.StimulusDelayMin;
            BpodSystem.Data.Custom.StimulusDelayMax(currentTrial) = TaskParameters.GUI.StimulusDelayMax;
            BpodSystem.Data.Custom.StimulusDelayExp(currentTrial) = TaskParameters.GUI.StimulusDelayExp;
            BpodSystem.Data.Custom.RewardDelay(currentTrial) = RewardDelay; % Adds the reward delay
            BpodSystem.Data.Custom.RewardGrace(currentTrial) = TaskParameters.GUI.RewardGrace;
            BpodSystem.Data.Custom.TimeForReponse(currentTrial) = TaskParameters.GUI.TimeForResponse ; % Time after sampling for subject to respond (s)
            
            % Now compute sampling duration and update minumum one
            % Sampling duration
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.EarlyWithdrawal(1))
                % Early withdrwal
                SamplingDuration=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(2)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(1);
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StillSampling(1))
                % Normal withdrwal
                SamplingDuration=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StillSampling(2)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(1);
            else
                SamplingDuration=0.05; % Dummy value for the first trial, if early withdrawal
            end
            
            % This is to check, if MinSamplingDuration can be increased
            WindowSize=TaskParameters.GUI.WindowSize; % Number of trials to check back
            Threshold=TaskParameters.GUI.Threshold; % Number of trials above threshold in the window
            StepSize=TaskParameters.GUI.StepSize; % Increase next MinSamplingDuration by StepSize
            
            SamplingDurationS=[BpodSystem.Data.Custom.SamplingDuration SamplingDuration];
            
            if currentTrial>WindowSize
                Range=currentTrial-(WindowSize):currentTrial;
                OKTrial(Range)= ~isnan(SamplingDurationS(Range)) & SamplingDurationS(Range)>BpodSystem.Data.Custom.MinimumSamplingDuration(currentTrial);
                SamplingValue=mean(OKTrial(currentTrial-(WindowSize):currentTrial));
                if SamplingValue>Threshold
                    MinimumSamplingDurationNew=min(TaskParameters.GUI.MaxMinimumSamplingDuration,BpodSystem.Data.Custom.MinimumSamplingDuration(currentTrial)+StepSize);
                end
            else
                MinimumSamplingDurationNew=TaskParameters.GUI.InitialMinimumSamplingDuration;
                OKTrial(currentTrial)=~isnan(SamplingDurationS(currentTrial)) & SamplingDurationS(currentTrial)>BpodSystem.Data.Custom.MinimumSamplingDuration(currentTrial);
                SamplingValue=mean(OKTrial(1:currentTrial));
            end
            
            % Adds the extra stuff
            BpodSystem.Data.Custom.SamplingDuration(currentTrial)=SamplingDuration;
            BpodSystem.Data.Custom.MinimumSamplingDuration(currentTrial+1)=MinimumSamplingDurationNew;
            BpodSystem.Data.Custom.MaxMinimumSamplingDuration(currentTrial)=TaskParameters.GUI.MaxMinimumSamplingDuration;
            BpodSystem.Data.nTrials=currentTrial;
            BpodSystem.Data.Custom.Threshold(currentTrial)=Threshold;
            BpodSystem.Data.Custom.WindowSize(currentTrial)=WindowSize;
            BpodSystem.Data.Custom.SamplingValue(currentTrial)=SamplingValue;
            
            % Adds the minimum sampling duration
            % Datafields(currentTrial); % Updates the data fields
            if BpodSystem.Data.Custom.SamplingDuration(currentTrial)>BpodSystem.Data.Custom.MinimumSamplingDuration(currentTrial)
                BpodSystem.Data.Custom.SampledTrial(currentTrial)=1;
            else
                BpodSystem.Data.Custom.SampledTrial(currentTrial)=0;
            end
            
            % Defining Left and Right Trials
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeft(1)) || ...
                        ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeftLW(1)))
                BpodSystem.Data.Custom.LeftChoice(currentTrial) = 1;
                BpodSystem.Data.Custom.RightChoice(currentTrial) = 0;
                BpodSystem.Data.Custom.ChosenDirection(currentTrial) = 1;
            elseif (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRight(1)) || ...
                        ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRightLW(1)))
                BpodSystem.Data.Custom.LeftChoice(currentTrial) = 0;
                BpodSystem.Data.Custom.RightChoice(currentTrial) = 1;
                BpodSystem.Data.Custom.ChosenDirection(currentTrial) = 2;
            else
                BpodSystem.Data.Custom.LeftChoice(currentTrial) = NaN;
                BpodSystem.Data.Custom.RightChoice(currentTrial) = NaN;
                BpodSystem.Data.Custom.ChosenDirection(currentTrial) = 3;
            end
            
            % Calculating Choice Bias
            RewardBiasWindow = TaskParameters.GUI.RewardBWindow;
            if currentTrial > RewardBiasWindow
                BpodSystem.Data.Custom.LeftBias(currentTrial)=nanmean(BpodSystem.Data.Custom.LeftChoice(currentTrial-RewardBiasWindow:currentTrial));
                BpodSystem.Data.Custom.RightBias(currentTrial)=nanmean(BpodSystem.Data.Custom.RightChoice(currentTrial-RewardBiasWindow:currentTrial));
            else
                BpodSystem.Data.Custom.LeftBias(currentTrial)=0;
                BpodSystem.Data.Custom.RightBias(currentTrial)=0;
            end
            BpodSystem.Data.Custom.ChoiceBias(currentTrial)=BpodSystem.Data.Custom.LeftBias(currentTrial)-BpodSystem.Data.Custom.RightBias(currentTrial);
         
            % This is to compute wheter it was a rewarded trial
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRight(1)) || ...
                        ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeft(1))) || ...
                        (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRightLW(1)) || ...
                        ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeftLW(1))) 
                BpodSystem.Data.Custom.RewardedTrial(currentTrial)=1;
            else
                BpodSystem.Data.Custom.RewardedTrial(currentTrial)=0;
            end
            
            % Counting Long Sampling Events
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRightLW(1)) || ...
                        ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeftLW(1)))
                BpodSystem.Data.Custom.LongSamplingEvent(currentTrial) = 1;
            else
                BpodSystem.Data.Custom.LongSamplingEvent(currentTrial) = 0;
            end
            
            % Calculate total amount of reward given so far in µl
            if currentTrial >= 2
                if  BpodSystem.Data.Custom.ChosenDirection(currentTrial) == 1
                    if BpodSystem.Data.Custom.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.Custom.LongSamplingEvent(currentTrial) == 0
                        BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial-1)+BpodSystem.Data.Custom.RewardAmountLeft(currentTrial);
                        BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial-1);
                    elseif BpodSystem.Data.Custom.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.Custom.LongSamplingEvent(currentTrial) == 1
                        BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial-1)+BpodSystem.Data.Custom.RewardAmountLeft(currentTrial)*5;
                        BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial-1);
                    else
                        BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial-1);
                        BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial-1);
                    end
                elseif BpodSystem.Data.Custom.ChosenDirection(currentTrial) == 2
                    if BpodSystem.Data.Custom.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.Custom.LongSamplingEvent(currentTrial) == 0
                        BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial-1);
                        BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial-1)+BpodSystem.Data.Custom.RewardAmountRight(currentTrial);
                    elseif BpodSystem.Data.Custom.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.Custom.LongSamplingEvent(currentTrial) == 1
                        BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial-1);
                        BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial-1)+BpodSystem.Data.Custom.RewardAmountRight(currentTrial)*5;
                    else
                        BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial-1);
                        BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial-1);
                    end
                else
                    BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial-1);
                    BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial-1);
                end
            else
                if BpodSystem.Data.Custom.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.Custom.ChosenDirection(currentTrial) == 1
                    BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.Custom.RewardAmountLeft(currentTrial);
                    BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=0;
                elseif BpodSystem.Data.Custom.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.Custom.ChosenDirection(currentTrial) == 2
                    BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=0;
                    BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.Custom.RewardAmountRight(currentTrial);
                else
                    BpodSystem.Data.Custom.TotalRewardGivenRight(currentTrial)=0;
                    BpodSystem.Data.Custom.TotalRewardGivenLeft(currentTrial)=0;
                end
            end
            
            % Get the 2 different types of correct catch Trials
            if ((~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStartRight(1)) || ...
                    ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStartLeft(1))) && ...
                    (isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRight(1)) && ...
                    isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeft(1))))
                BpodSystem.Data.Custom.CorrectCatchTrial_type2(currentTrial)=1;
            else
                BpodSystem.Data.Custom.CorrectCatchTrial_type2(currentTrial)=0;
            end

            % Define window for current trial read outs
            BpodSystem.Data.Custom.CurrentWindow(currentTrial) = 20;
            CurrentWindow=BpodSystem.Data.Custom.CurrentWindow(currentTrial);
            
            % Current Sampling ReadOuts
            EndTrial = currentTrial;
            if currentTrial > CurrentWindow+1
                BpodSystem.Data.Custom.CurrentEarlyWithdrawal(currentTrial)=nanmean(BpodSystem.Data.Custom.SampledTrial(EndTrial-CurrentWindow:EndTrial)==0);
                BpodSystem.Data.Custom.CurrentSamplingDuration(currentTrial)=nanmean(BpodSystem.Data.Custom.SamplingDuration(EndTrial-CurrentWindow:EndTrial));
                BpodSystem.Data.Custom.CurrentCorrectWTDropOutsLeft(currentTrial)= ...
                    round((sum(BpodSystem.Data.Custom.CorrectCatchTrial_type2(EndTrial-CurrentWindow:EndTrial)==1 & BpodSystem.Data.Custom.ChosenDirection(EndTrial-CurrentWindow:EndTrial)==1)/ ...
                    BpodSystem.Data.nTrials)*100);
                BpodSystem.Data.Custom.CurrentCorrectWTDropOutsRight(currentTrial)= ...
                    round((sum(BpodSystem.Data.Custom.CorrectCatchTrial_type2(EndTrial-CurrentWindow:EndTrial)==1 & BpodSystem.Data.Custom.ChosenDirection(EndTrial-CurrentWindow:EndTrial)==2)/ ...
                    BpodSystem.Data.nTrials)*100);
                BpodSystem.Data.Custom.CurrentMeanRewardDelay(currentTrial)=nanmean(BpodSystem.Data.Custom.RewardDelay(EndTrial-CurrentWindow:EndTrial));
            else
                BpodSystem.Data.Custom.CurrentEarlyWithdrawal(currentTrial)=0;
                BpodSystem.Data.Custom.CurrentSamplingDuration(currentTrial)=0;
                BpodSystem.Data.Custom.CurrentCorrectWTDropOutsLeft(currentTrial)=0;
                BpodSystem.Data.Custom.CurrentCorrectWTDropOutsRight(currentTrial)=0;
                BpodSystem.Data.Custom.CurrentMeanRewardDelay(currentTrial)=0;
            end
            
            % Getting trials that did not get rewarded (because rat was not waiting long enough)
            BpodSystem.Data.Custom.RewardedLeftTrials(currentTrial)=(~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeft(1)));
            BpodSystem.Data.Custom.RewardedRightTrials(currentTrial)=(~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRight(1)));
            BpodSystem.Data.Custom.NonRewardedLeftTrials(currentTrial)=(~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardLeft(1)) && isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeft(1)));
            BpodSystem.Data.Custom.NonRewardedRightTrials(currentTrial)=(~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardRight(1)) && isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRight(1)));
            BpodSystem.Data.Custom.NonRewardedLeftTrialsPerc(currentTrial)=sum(BpodSystem.Data.Custom.NonRewardedLeftTrials)/(sum(BpodSystem.Data.Custom.RewardedLeftTrials)+sum(BpodSystem.Data.Custom.NonRewardedLeftTrials));
            BpodSystem.Data.Custom.NonRewardedRightTrialsPerc(currentTrial)=sum(BpodSystem.Data.Custom.NonRewardedRightTrials)/(sum(BpodSystem.Data.Custom.RewardedRightTrials)+sum(BpodSystem.Data.Custom.NonRewardedRightTrials));
            
            % Saving the data we need
            BpodSystem.Data.TrialSettings(currentTrial) = TaskParameters.GUI; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            BpodSystem.Data.Custom.TrialTypes(currentTrial)=TrialTypes(currentTrial); % Adds the trial type of the current trial to data
            BpodSystem.Data.Custom.LeftClickRate(currentTrial)=ClickingRate; % Adds the value of fast click rate
            BpodSystem.Data.Custom.RightClickRate(currentTrial)=ClickingRate; % Adds the value of slow click rate
            BpodSystem.Data.Custom.RightClickTrain{currentTrial}=RightClickTrain; % Adds the timestamps of fast click train
            BpodSystem.Data.Custom.LeftClickTrain{currentTrial}=LeftClickTrain; % Adds the timestamps of slow click train
            
            % Update all the plots
            UpdateOutcomePlot(TrialTypes,BpodSystem.Data);
            UpdatePsycoPlot(BpodSystem.Data);
        end
        if BpodSystem.Status.BeingUsed == 0
            % Save all the new data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file (100518 disabled saving to Dropbox)
        end
        if BpodSystem.Status.Pause == 1
            % Save all the new data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file (100518 disabled saving to Dropbox)
        end
    end
end
end

end % End main function - PokeInCenter

function UpdateOutcomePlot(TrialTypes,Data)
    global BpodSystem

    Outcomes = zeros(1,Data.nTrials);
    TrialTypesNew=TrialTypes;
    TrialTypesNew(find(Data.Custom.ChosenDirection==1 | Data.Custom.ChosenDirection==2))= ...
        Data.Custom.ChosenDirection(find(Data.Custom.ChosenDirection==1 | Data.Custom.ChosenDirection==2));

    for x = 1:Data.nTrials
        if ~isnan(Data.RawEvents.Trial{1,x}.States.RewardLeft(1)) || ~isnan(Data.RawEvents.Trial{1,x}.States.RewardRight(1))
            Outcomes(x) = 1;
        elseif Data.Custom.LongSamplingEvent(x) == 1
            Outcomes(x) = -1;
        elseif ~isnan(Data.RawEvents.Trial{1,x}.States.EarlyWithdrawalKill)
            Outcomes(x) = 0;
        end
    end
    SideOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,mod(TrialTypesNew,2)',Outcomes);
end

% PM Plots
function UpdatePsycoPlot(Data)
global BpodSystem

    LiveDispFig = BpodSystem.ProtocolFigures.LiveDispFig;
    LivePlot1 = BpodSystem.ProtocolFigures.LivePlot1;
    LivePlot2 = BpodSystem.ProtocolFigures.LivePlot2;
    Bias = BpodSystem.ProtocolFigures.Bias;
    ChoiceBiasFig = BpodSystem.ProtocolFigures.ChoiceBias;
    WTBiasFig = BpodSystem.ProtocolFigures.WTBias;

    % Sampling Theshhold Plot
    figure(LiveDispFig);
    subplot(LivePlot1);
    thresholdplotSlim(Data,LivePlot1);

    % Sampling Duration Histogram
    figure(LiveDispFig);
    subplot(LivePlot2);
    samplingdistplotPokeInCenterSlim(Data,LivePlot2);

    % Choice Bias Plot
    figure(Bias);
    subplot(ChoiceBiasFig);
    choicebiasplotPokeInCenterSlim(Data,ChoiceBiasFig);

    % WT Bias Plot
    figure(Bias);
    subplot(WTBiasFig);
    WTbiasplotPokeInCenterSlim(Data,WTBiasFig);
end

% function try_SendStateMatrix(sma)
%     try
%         SendStateMatrix(sma)
%     catch
%         disp('SendStateMatrix failed, Bpod communication error, trying again')
%         try_SendStateMatrix(sma)
%     end
% end