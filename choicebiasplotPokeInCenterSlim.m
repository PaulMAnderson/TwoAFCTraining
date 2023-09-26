function choicebiasplotPokeInCenterSlim(Data,handle)

%% Fixed data input
PlottingWindow=50;
LeftBias=Data.Custom.LeftBias;
RightBias=Data.Custom.RightBias;
ChoiceBias=round(Data.Custom.ChoiceBias(end)*100);
RewardBias=round(Data.Custom.RewardCounterBias(end)*10)/10;
TotalRewardGivenLeft=round(Data.Custom.TotalRewardGivenLeft(end)*10)/10;
TotalRewardGivenRight=round(Data.Custom.TotalRewardGivenRight(end)*10)/10;
RewardAmountLeft=round(Data.Custom.RewardAmountLeft(end)*10)/10;
RewardAmountRight=round(Data.Custom.RewardAmountRight(end)*10)/10;
nTrials=Data.nTrials;

%% CALCULUS
if nTrials>PlottingWindow;
    PlotRange=nTrials-PlottingWindow:nTrials;
    LeftBiasPlotValue=LeftBias(PlotRange); 
    RightBiasPlotValue=RightBias(PlotRange); 
else
    PlotRange=1:nTrials;
    LeftBiasPlotValue=LeftBias(PlotRange);
    RightBiasPlotValue=RightBias(PlotRange); 
end


%% PLOTTING (just using handles)
H=get(handle);

if PlotRange(end) > 1;
    set(handle,'Xlim',[PlotRange(1),PlotRange(end)]);
end

set(H.Children(8),'Xdata',PlotRange);
set(H.Children(8),'Ydata',LeftBiasPlotValue);
set(H.Children(7),'Xdata',PlotRange);
set(H.Children(7),'Ydata',RightBiasPlotValue);
set(H.Children(2),'String',['Right reward, total: ',num2str(TotalRewardGivenRight),' µl','; Right reward, current: ',num2str(RewardAmountRight),' µl']);
set(H.Children(3),'String',['Left reward, total: ',num2str(TotalRewardGivenLeft),' µl','; Left reward, current: ',num2str(RewardAmountLeft),' µl']);
set(H.Children(4),'String',['Reward Bias: ',num2str(RewardBias),' µl']);
set(H.Children(5),'String',['Choice Bias: ',num2str(ChoiceBias),' %-diff']);
set(H.Children(1),'String',['Trial: ',num2str(nTrials)]);

if nTrials>PlottingWindow
    set(H.Children(2),'Position',[PlotRange(1),1.1,0]);
    set(H.Children(3),'Position',[PlotRange(1),1.15,0]);
    set(H.Children(4),'Position',[PlotRange(1),1.2,0]);
    set(H.Children(5),'Position',[PlotRange(1),1.25,0]);
    set(H.Children(1),'Position',[PlotRange(1),1.35,0]);
end
end