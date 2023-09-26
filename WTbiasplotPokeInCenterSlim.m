function WTbiasplotPokeInCenterSlim(Data,handle)

%% Fixed data input
PlottingWindow=50;
nTrials=Data.nTrials;
CurrentCorrectWTDropOutsLeft=Data.Custom.CurrentCorrectWTDropOutsLeft(end);
CurrentCorrectWTDropOutsRight=Data.Custom.CurrentCorrectWTDropOutsRight(end);
CurrentMeanRewardDelay=round(Data.Custom.CurrentMeanRewardDelay(end)*100)/100;
NonRewardedLeftTrialsPerc=Data.Custom.NonRewardedLeftTrialsPerc;
NonRewardedRightTrialsPerc=Data.Custom.NonRewardedRightTrialsPerc;

%% CALCULUS
if nTrials>PlottingWindow
    PlotRange=nTrials-PlottingWindow:nTrials;
    NonRewardedLeftTrialsPercPlotRange=NonRewardedLeftTrialsPerc(PlotRange); 
    NonRewardedRightTrialsPercPlotRange=NonRewardedRightTrialsPerc(PlotRange); 
else
    PlotRange=1:nTrials;
    NonRewardedLeftTrialsPercPlotRange=NonRewardedLeftTrialsPerc(PlotRange);
    NonRewardedRightTrialsPercPlotRange=NonRewardedRightTrialsPerc(PlotRange); 
end

%% PLOTTING (just using handles)
H=get(handle);

if PlotRange(end) > 1;
    set(handle,'Xlim',[PlotRange(1),PlotRange(end)]);
end

set(H.Children(5),'Xdata',PlotRange);
set(H.Children(5),'Ydata',NonRewardedLeftTrialsPercPlotRange);
set(H.Children(4),'Xdata',PlotRange);
set(H.Children(4),'Ydata',NonRewardedRightTrialsPercPlotRange);
set(H.Children(1),'String',['Left Reward Delay Drop Outs: ',num2str(CurrentCorrectWTDropOutsLeft), ' %']);
set(H.Children(2),'String',['Right Reward Delay Drop Outs: ',num2str(CurrentCorrectWTDropOutsRight),' %']);
set(H.Children(3),'String',['Mean Reward Delay: ',num2str(CurrentMeanRewardDelay),' s']);

if nTrials>PlottingWindow;
    set(H.Children(1),'Position',[PlotRange(1),1.1,0]);
    set(H.Children(2),'Position',[PlotRange(1),1.15,0]);
    set(H.Children(3),'Position',[PlotRange(1),1.2,0]);
end
end