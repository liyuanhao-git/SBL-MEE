clc;
clear;
close all;

% Basic settings for decoding experiments
Nlearn=500;
aaMax=1e6;
TrainingRatio=2/3;
ListMonkey=cell(2,1);
ListMonkey{1}.MonkName='B';
ListMonkey{2}.MonkName='C';

for iMonkey=1:1:size(ListMonkey,1)
if strcmp(ListMonkey{iMonkey}.MonkName,'B')
load('../ListNameEpiduralB.mat','ListName');
else
load('../ListNameEpiduralC.mat','ListName');
end

% Prepare the dataset for all sessions
xxtrain_zsAll=cell(size(ListName,1)*3,1);
yytrain_zsAll=cell(size(ListName,1)*3,1);
xxtest_zsAll=cell(size(ListName,1)*3,1);
yytestAll=cell(size(ListName,1)*3,1);
meanyyTrainAll=zeros(size(ListName,1)*3,1);
stdyyTrainAll=zeros(size(ListName,1)*3,1);

for iSess=1:size(ListName,1)
fprintf('PrepareDataset ... RecordingSession: %d/%d\n',iSess,size(ListName,1));
load(['../preprocess/FeaMonk',ListMonkey{iMonkey}.MonkName,'Sess',num2str(iSess),'.mat'],'featureAll','dataTrajectory');
% Segment the dataset for training and testing
xtr=featureAll(1:round(size(featureAll,1)*TrainingRatio),:);
xte=featureAll(1+round(size(featureAll,1)*TrainingRatio):size(featureAll,1),:);
ttr=dataTrajectory(1:round(size(featureAll,1)*TrainingRatio),:);
tte=dataTrajectory(1+round(size(featureAll,1)*TrainingRatio):size(featureAll,1),:);
clear featureAll dataTrajectory

for iTraDim=1:size(ttr,2)
xxtrain=xtr;
yytrain=ttr(:,iTraDim);
xxtest=xte;
yytest=tte(:,iTraDim);

% Compute the Z-score of each matrix
meanxxTrain=mean(xxtrain);
meanyyTrain=mean(yytrain);
stdxxTrain=std(xxtrain);
stdyyTrain=std(yytrain);

xxtrain_zs=(xxtrain-(ones(size(xxtrain,1),1)*meanxxTrain))./(ones(size(xxtrain,1),1)*stdxxTrain);
yytrain_zs=(yytrain-(ones(size(yytrain,1),1)*meanyyTrain))./(ones(size(yytrain,1),1)*stdyyTrain);
xxtest_zs=(xxtest-(ones(size(xxtest,1),1)*meanxxTrain))./(ones(size(xxtest,1),1)*stdxxTrain);

yytestAll{(iSess-1)*3+iTraDim,1}=yytest;
xxtrain_zsAll{(iSess-1)*3+iTraDim,1}=xxtrain_zs;
yytrain_zsAll{(iSess-1)*3+iTraDim,1}=yytrain_zs;
xxtest_zsAll{(iSess-1)*3+iTraDim,1}=xxtest_zs;
meanyyTrainAll((iSess-1)*3+iTraDim)=meanyyTrain;
stdyyTrainAll((iSess-1)*3+iTraDim)=stdyyTrain;
clear xxtrain yytrain xxtest yytest meanxxTrain meanyyTrain stdxxTrain stdyyTrain
clear xxtrain_zs yytrain_zs xxtest_zs
end
clear xtr xte ttr tte iTraDim
end
clear iSess

% Load the kernel bandwidths
load(['KernelMonk',ListMonkey{iMonkey}.MonkName,'Sbcl.mat'],'hhSbcl');
load(['KernelMonk',ListMonkey{iMonkey}.MonkName,'SblMee.mat'],'hhSblMee');
% Learn the model parameters
wwSblAll=cell(size(ListName,1)*3,1);
wwSbclAll=cell(size(ListName,1)*3,1);
wwSblMeeAll=cell(size(ListName,1)*3,1);
for iRep=1:1:size(ListName,1)*3
    fprintf('LearnParameter ... ResponseProgress: %d/%d\n',iRep,size(ListName,1)*3);
    % Learn the parameters (SBL)
    [wwSblAll{iRep},~]=learning_sbl_regression(xxtrain_zsAll{iRep},yytrain_zsAll{iRep},Nlearn,aaMax);
    % Learn the parameters (SBCL)
    [wwSbclAll{iRep},~]=learning_sbcl_regression(xxtrain_zsAll{iRep},yytrain_zsAll{iRep},hhSbcl(iRep),Nlearn,aaMax);
    % Learn the parameters (SBL-MEE)
    [wwSblMeeAll{iRep},~]=learning_sblmee_regression(xxtrain_zsAll{iRep},yytrain_zsAll{iRep},hhSblMee(iRep),Nlearn,aaMax);
end
clear iRep xxtrain_zsAll yytrain_zsAll hhSbcl hhSblMee

% Compute and store regression results
ResAllSess=cell(size(ListName,1),1);
for iSess=1:1:size(ListName,1)
ResCurrSess=cell(3,1);
for iTraDim=1:3
    xxtest_zs=xxtest_zsAll{(iSess-1)*3+iTraDim,1};
    meanyyTrain=meanyyTrainAll((iSess-1)*3+iTraDim);
    stdyyTrain=stdyyTrainAll((iSess-1)*3+iTraDim);
    yytest=yytestAll{(iSess-1)*3+iTraDim,1};

    % Performance evaluation (SBL)
    [~,CorrTestSbl,RmseTestSbl]=prediction_eval(wwSblAll{(iSess-1)*3+iTraDim,1},xxtest_zs,meanyyTrain,stdyyTrain,yytest);
    ResCurrSess{iTraDim}.CorrTestSbl=CorrTestSbl;
    ResCurrSess{iTraDim}.RmseTestSbl=RmseTestSbl;
    clear CorrTestSbl RmseTestSbl

    % Performance evaluation (SBCL)
    [~,CorrTestSbcl,RmseTestSbcl]=prediction_eval(wwSbclAll{(iSess-1)*3+iTraDim,1},xxtest_zs,meanyyTrain,stdyyTrain,yytest);
    ResCurrSess{iTraDim}.CorrTestSbcl=CorrTestSbcl;
    ResCurrSess{iTraDim}.RmseTestSbcl=RmseTestSbcl;
    clear CorrTestSbcl RmseTestSbcl

    % Performance evaluation (SBL-MEE)
    [~,CorrTestSblMee,RmseTestSblMee]=prediction_eval(wwSblMeeAll{(iSess-1)*3+iTraDim,1},xxtest_zs,meanyyTrain,stdyyTrain,yytest);
    ResCurrSess{iTraDim}.CorrTestSblMee=CorrTestSblMee;
    ResCurrSess{iTraDim}.RmseTestSblMee=RmseTestSblMee;
    clear CorrTestSblMee RmseTestSblMee
    clear xxtest_zs meanyyTrain stdyyTrain yytest
end
ResAllSess{iSess}=ResCurrSess;
clear iTraDim ResCurrSess
end
clear iSess ListName xxtest_zsAll meanyyTrainAll stdyyTrainAll yytestAll wwSblAll wwSbclAll wwSblMeeAll
save(['ResMonk',ListMonkey{iMonkey}.MonkName,'SessAll.mat']);
clear ResAllSess
end
clear iMonkey

% Decoding performance illustration
CorrTestSbl=cell(3,1);
RmseTestSbl=cell(3,1);
CorrTestSbcl=cell(3,1);
RmseTestSbcl=cell(3,1);
CorrTestSblMee=cell(3,1);
RmseTestSblMee=cell(3,1);

for iMonkey=1:1:size(ListMonkey,1)
if strcmp(ListMonkey{iMonkey}.MonkName,'B')
load('../ListNameEpiduralB.mat','ListName');
else
load('../ListNameEpiduralC.mat','ListName');
end

for iTraDim=1:3
load(['ResMonk',ListMonkey{iMonkey}.MonkName,'SessAll.mat'],'ResAllSess');
for iSess=1:1:size(ListName,1)
% Performance evaluation (SBL)
CorrTestSbl{iTraDim}=[CorrTestSbl{iTraDim},ResAllSess{iSess}{iTraDim}.CorrTestSbl];
RmseTestSbl{iTraDim}=[RmseTestSbl{iTraDim},ResAllSess{iSess}{iTraDim}.RmseTestSbl];

% Performance evaluation (SBCL)
CorrTestSbcl{iTraDim}=[CorrTestSbcl{iTraDim},ResAllSess{iSess}{iTraDim}.CorrTestSbcl];
RmseTestSbcl{iTraDim}=[RmseTestSbcl{iTraDim},ResAllSess{iSess}{iTraDim}.RmseTestSbcl];

% Performance evaluation (SBL-MEE)
CorrTestSblMee{iTraDim}=[CorrTestSblMee{iTraDim},ResAllSess{iSess}{iTraDim}.CorrTestSblMee];
RmseTestSblMee{iTraDim}=[RmseTestSblMee{iTraDim},ResAllSess{iSess}{iTraDim}.RmseTestSblMee];
end
clear iSess ResAllSess
end
clear iTraDim ListName
end
clear iMonkey

ColorPlot{1}=[0,0.4470,0.7410];
ColorPlot{2}=[0.8500,0.3250,0.0980];
ColorPlot{3}=[0.4940,0.1840,0.5560];
for iMetric=1:1:2
f=figure;set(gcf,'color','white');
f.Position=[100,100,1000,340];
for iTraDim=1:3
switch iMetric
    case 1
        DataAlgo{1}=CorrTestSbl{iTraDim};
        DataAlgo{2}=CorrTestSbcl{iTraDim};
        DataAlgo{3}=CorrTestSblMee{iTraDim};
        TitleText='Correlation';
    case 2
        DataAlgo{1}=RmseTestSbl{iTraDim};
        DataAlgo{2}=RmseTestSbcl{iTraDim};
        DataAlgo{3}=RmseTestSblMee{iTraDim};
        TitleText='RMSE';
end
subplot(1,3,iTraDim);
hold on;
b=bar([mean(DataAlgo{1}),mean(DataAlgo{2}),mean(DataAlgo{3})],0.6,'FaceColor','flat','EdgeColor','none');
meanVal=[mean(DataAlgo{1}),mean(DataAlgo{2}),mean(DataAlgo{3})];
stdVal=[std(DataAlgo{1}),std(DataAlgo{2}),std(DataAlgo{3})];
for iAlgo=1:1:3
b.CData(iAlgo,:)=(ColorPlot{iAlgo}+[1,1,1])/2;
errorbar(iAlgo,meanVal(iAlgo),stdVal(iAlgo),'Color',[0,0,0],'LineStyle','none','CapSize',10,'LineWidth',0.8);
plot(iAlgo+0.06*randn(20,1),DataAlgo{iAlgo},'.','Color',ColorPlot{iAlgo},'MarkerSize',10);
end
clear iAlgo meanVal stdVal b
title([TitleText,'-DOF',num2str(iTraDim)]);
set(gca,'XLim',[0.5,3.5]);
set(gca,'XTick',1:1:3);
set(gca,'XTickLabel',{'SBL','SBCL','SBL-MEE'});
set(gca,'TickLength',[.005,.005]);
set(gca,'LineWidth',1.2,'FontName','calibri','fontsize',12);
clear DataAlgo TitleText
end
clear iTraDim f
end
clear iMetric ColorPlot
clear CorrTestSbl RmseTestSbl
clear CorrTestSbcl RmseTestSbcl
clear CorrTestSblMee RmseTestSblMee
fprintf('Finished!! \n');