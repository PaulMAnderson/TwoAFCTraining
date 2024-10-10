function samplingdistplotPokeInCenterSlim(Data,handle)

%% Fixed data input
CurrentEarlyWithdrawal=round(Data.Custom.CurrentEarlyWithdrawal(end)*100);
CurrentSamplingDuration=round(Data.Custom.CurrentSamplingDuration(end)*1000); % given in ms
LongSamplingEvent=sum(Data.Custom.LongSamplingEvent);

%% CALCULUS
[NSamplingTimes,STbins]=hist(Data.Custom.SamplingDuration,15);
SamplingDurationToPlot=min(Data.Custom.MinimumSamplingDuration(end),Data.Custom.MaxMinimumSamplingDuration(end));
 
%% PLOTTING (just using handles)
H=get(handle);

set(H.Children(1),'Xdata',STbins);
set(H.Children(1),'Ydata',NSamplingTimes/sum(NSamplingTimes));
set(H.Children(5),'Xdata',[SamplingDurationToPlot SamplingDurationToPlot]);
set(H.Children(5),'Ydata',[0 1]);
set(H.Children(2),'String',['Long Sampling Events: ',num2str(LongSamplingEvent)]);
set(H.Children(3),'String',['Sampling DropOuts: ',num2str(CurrentEarlyWithdrawal),' %']);
set(H.Children(4),'String',['Avg. Sampling: ',num2str(CurrentSamplingDuration),' ms']);

end