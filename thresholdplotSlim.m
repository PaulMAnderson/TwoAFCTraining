function thresholdplotSlim(Data,handle)

%% Fixed data input
PlottingWindow=50;
Threshold=Data.Custom.Threshold;
SamplingValue=Data.Custom.SamplingValue;
nTrials=Data.nTrials;

%% CALCULUS
if nTrials>PlottingWindow
    PlotRange=nTrials-PlottingWindow:nTrials;
    PlotValue=SamplingValue(PlotRange); 
else
    PlotRange=1:Data.nTrials;
    PlotValue=SamplingValue(PlotRange);
end
 
%% PLOTTING (just using handles)
H=get(handle);

if PlotRange(end) > 1;
    set(handle,'Xlim',[PlotRange(1),PlotRange(end)]);
end

set(H.Children(2),'Xdata',PlotRange);
set(H.Children(2),'Ydata',PlotValue);
set(H.Children(1),'Xdata',[PlotRange(1) PlotRange(end)]);
set(H.Children(1),'Ydata',[Threshold(nTrials) Threshold(nTrials)]);

end