clc;
clear;
close all;

NumSampling=500;
ListMonkey=cell(2,1);
ListMonkey{1}.MonkName='B';
ListMonkey{2}.MonkName='C';

for iMonkey=1:1:size(ListMonkey,1)
if strcmp(ListMonkey{iMonkey}.MonkName,'B')
load('../ListNameEpiduralB.mat','ListName','NumChannel');
else
load('../ListNameEpiduralC.mat','ListName','NumChannel');
end

for iSess=1:size(ListName,1)
fprintf('RecordingSession: %d/%d\n',iSess,size(ListName,1));
[featureAll,dataTrajectory]=prepareFeatureWav(ListMonkey{iMonkey}.MonkName,NumSampling,iSess,ListName,NumChannel);
save(['FeaMonk',ListMonkey{iMonkey}.MonkName,'Sess',num2str(iSess),'.mat'],'featureAll','dataTrajectory');
clear featureAll dataTrajectory
end
clear iSess ListName NumChannel
end