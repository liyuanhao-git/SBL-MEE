function [featureAll,dataTrajectory]=prepareFeatureWav(MonkName,NumSampling,iSess,ListName,NumChannel)

% load and store the ECoG data from all channels
for iChannel=1:NumChannel
    load(['../data/Monkey',MonkName,'/',ListName{iSess},'/ECoG_ch',num2str(iChannel),'.mat']);
    eval(['EcogTemp=ECoGData_ch',num2str(iChannel),';']);
    if iChannel==1
        dataEcog=zeros(size(EcogTemp,2),NumChannel);
    end
    dataEcog(:,iChannel)=EcogTemp';
    eval(['clear EcogTemp ECoGData_ch',num2str(iChannel)]);
end
clear iChannel

% load other data and compute the trajectory
load(['../data/Monkey',MonkName,'/',ListName{iSess},'/ECoG_time.mat'],'ECoGTime');
load(['../data/Monkey',MonkName,'/',ListName{iSess},'/Motion.mat'],'MotionData','MotionTime');
clear ListName

% downsampling on trajectory data
MovFs=10;
[dataTrajectory,MotionTime]=compute_trajectory(MotionData,MotionTime,MovFs);
clear MotionData MonkName

timeLagTemp=abs(ECoGTime-min(MotionTime));
[~,startPointEcog]=find(timeLagTemp==min(min(timeLagTemp)));
startPointEcog=startPointEcog-NumSampling*1.1+1;

timeLagTemp=abs(ECoGTime-max(MotionTime));
[~,endPointEcog]=find(timeLagTemp==min(min(timeLagTemp)));
clear timeLagTemp

ECoGTime=ECoGTime(startPointEcog:endPointEcog);
dataEcog=dataEcog(startPointEcog:endPointEcog,:);
clear startPointEcog endPointEcog

% band-pass filter
filterOrder=1000;
Wn=[0.2,400]/(1000/2);
bb=fir1(filterOrder,Wn,'bandpass');
dataEcogFilt=filtfilt(bb,1,dataEcog);
clear filterOrder Wn bb dataEcog

% common average reference
dataEcog=dataEcogFilt-repmat(mean(dataEcogFilt,2),1,size(dataEcogFilt,2));
clear dataEcogFilt

% null variable for feature preparation
IdxFrep=[1,3,5,8,11,14,17,20,23,26,28,30,32,34,36];
NumFreq=size(IdxFrep,2);
featureAll=zeros(size(dataTrajectory,1),NumChannel*10*NumFreq);

fprintf('Wavelet Transform start... \n');
for iSampling=1:size(MotionTime,2)
    if mod(iSampling,1000)==0
        fprintf('MovementIndex:  %d/%d \n',iSampling,size(MotionTime,2));
    end

    % compute the corresponding ECoG for each trajectory sampling
    timeLag=abs(ECoGTime-MotionTime(iSampling));
    [~,timeEcogTemp]=find(timeLag==min(min(timeLag)));
    clear timeLag

    % 0.5sec previous from sampling
    ecogTemp=dataEcog(timeEcogTemp-round(NumSampling*1.1)+1:timeEcogTemp,:);
    
    % feature variable for each channel
    featureChannel=zeros(1,NumChannel*10*NumFreq);

    for iChannel=1:NumChannel
    % wavelet transformation from 10-120Hz
    [wt,~]=cwt(ecogTemp(:,iChannel),'amor',1000,'FrequencyLimits',[10,120]);
    featureTemp=abs(wt(IdxFrep,:));
    featureTemp=featureTemp(:,NumSampling/10:NumSampling/10:NumSampling);

    % reshape the scalogram matrix
    featureChannel((iChannel-1)*10*NumFreq+1:iChannel*10*NumFreq)=reshape(featureTemp,1,10*NumFreq);
    clear wt featureTemp
    end
    featureAll(iSampling,:)=featureChannel;
    clear featureChannel iChannel timeEcogTemp ecogTemp
end
clear iSampling
end