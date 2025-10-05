function evalVisualRecons(algoList)

PlotColor{1}=[0,0.4470,0.7410];
PlotColor{2}=[0.9290,0.6940,0.1250];
PlotColor{3}=[0.6350,0.0780,0.1840];
plotList{1}=1:1:40;
plotList{2}=41:1:80;
plotList{3}=81:1:120;

stim=cell(1,length(algoList));
stimPre=cell(1,length(algoList));
meanCorr=zeros(length(plotList),length(algoList));
stdCorr=zeros(length(plotList),length(algoList));
meanMse=zeros(length(plotList),length(algoList));
stdMse=zeros(length(plotList),length(algoList));

for iAlgo=1:size(algoList,2)
    data=[algoList{iAlgo},'Result/V1V2_Ecc1to11_linComb_errFuncImageNonNegCon_1x1_figRecon.mat'];
    fprintf('loading ... %s \n',data);
    d=load(data); 
    stim{iAlgo}=d.StimFigTestAll;
    stimPre{iAlgo}=d.StimFigTestAllPre;
end
clear iAlgo data d
      
for iRun=1:length(plotList)
    StimTemp=cell(size(algoList,2),1);
    StimPreTemp=cell(size(algoList,2),1);

    for iAlgo=1:size(algoList,2)
    StimTemp{iAlgo}=stim{iAlgo}(plotList{iRun},:);
    StimPreTemp{iAlgo}=stimPre{iAlgo}(plotList{iRun},:);
    [msqerrTemp,corrValTemp,~]=calcErrCorr(StimTemp{iAlgo},StimPreTemp{iAlgo});

    meanCorr(iRun,iAlgo)=mean(corrValTemp);
    stdCorr(iRun,iAlgo)=std(corrValTemp);
    meanMse(iRun,iAlgo)=mean(msqerrTemp);
    stdMse(iRun,iAlgo)=std(msqerrTemp);
    clear corrValTemp msqerrTemp
    end
    clear iAlgo

    resol=sqrt(size(StimTemp{1},2));
    nSmpl=size(StimTemp{1},1);
    labelGroup=unique(StimTemp{1},'rows');
    labelGroupBack=labelGroup;
    indGroup=cell(size(labelGroup,1),1);

    % make better order for the figure
    switch iRun
        case 2
            labelGroup(1,:) = labelGroupBack(4,:);
            labelGroup(2,:) = labelGroupBack(2,:);
            labelGroup(3,:) = labelGroupBack(1,:);
            labelGroup(4,:) = labelGroupBack(3,:);
            labelGroup(5,:) = labelGroupBack(5,:);

            labelGroup(6,:) = labelGroupBack(8,:);
            labelGroup(7,:) = labelGroupBack(10,:);
            labelGroup(8,:) = labelGroupBack(6,:);
            labelGroup(9,:) = labelGroupBack(7,:);
            labelGroup(10,:) = labelGroupBack(9,:);
        case 3
            labelGroup(1,:) = labelGroupBack(3,:);
            labelGroup(2,:) = labelGroupBack(5,:);
            labelGroup(3,:) = labelGroupBack(1,:);
            labelGroup(4,:) = labelGroupBack(2,:);
            labelGroup(5,:) = labelGroupBack(4,:);
    end
    clear labelGroupBack

    for iSmp=1:nSmpl
    labelIdx=find(ismember(labelGroup,StimTemp{1}(iSmp,:),'rows'));
    switch labelIdx
            case 1
            indGroup{1}=[indGroup{1};iSmp];
            case 2
            indGroup{2}=[indGroup{2};iSmp];
            case 3
            indGroup{3}=[indGroup{3};iSmp];
            case 4
            indGroup{4}=[indGroup{4};iSmp];
            case 5
            indGroup{5}=[indGroup{5};iSmp];
            case 6
            indGroup{6}=[indGroup{6};iSmp];
            case 7
            indGroup{7}=[indGroup{7};iSmp];
            case 8
            indGroup{8}=[indGroup{8};iSmp];
            case 9
            indGroup{9}=[indGroup{9};iSmp];
            case 10
            indGroup{10}=[indGroup{10};iSmp];
    end
    end
    clear nSmpl iSmp labelIdx

    imgOri=[];
    imgRecon=cell(size(algoList,2),1);
    imgReconMeanAll=cell(size(algoList,2),1);
    for iAlgo=1:1:size(algoList,2)
        imgReconMeanAll{iAlgo}=cell(size(labelGroup,1),1);
        for iMean=1:size(labelGroup,1)
            imgReconMeanAll{iAlgo}{iMean}=0;
        end
    end
    clear iAlgo iMean

    % original images
    for iImg=1:size(labelGroup,1)
        indTemp=indGroup{iImg}(1);
        imgOri=[imgOri,reshape(StimTemp{1}(indTemp,:),resol,resol),ones(resol,1)];
    end
    clear iImg indTemp StimTemp
    % predicted images
    for iImg=1:size(labelGroup,1)
        imgTemp=cell(size(algoList,2),1);
        for iiImage=1:size(indGroup{iImg},1)
        indTemp=indGroup{iImg}(iiImage);
        for iAlgo=1:1:size(algoList,2)
            imgTemp{iAlgo}=[imgTemp{iAlgo};reshape(StimPreTemp{iAlgo}(indTemp,:),resol,resol);ones(1,resol)];
            imgReconMeanAll{iAlgo}{iImg}=imgReconMeanAll{iAlgo}{iImg}+reshape(StimPreTemp{iAlgo}(indTemp,:),resol,resol);
        end
        clear iAlgo
        end
        for iAlgo=1:1:size(algoList,2)
            imgRecon{iAlgo}=[imgRecon{iAlgo},imgTemp{iAlgo},ones(size(imgTemp{iAlgo},1),1)];
        end
        clear iAlgo iiImage indTemp imgTemp
    end
    clear iImg resol StimPreTemp
    
    % add the average image
    imgAlgoMean=cell(size(algoList,2),1);
    for iImg=1:size(labelGroup,1)
        for iAlgo=1:1:size(algoList,2)
            imgAlgoMean{iAlgo}=[imgAlgoMean{iAlgo},imgReconMeanAll{iAlgo}{iImg}/size(indGroup{iImg},1),ones(size(imgReconMeanAll{iAlgo}{iImg},1),1)];
        end
        clear iAlgo
    end
    clear iImg imgReconMeanAll
    for iAlgo=1:1:size(algoList,2)
        imgRecon{iAlgo}=[imgRecon{iAlgo};ones(5,size(imgRecon{iAlgo},2));imgAlgoMean{iAlgo}];
    end
    clear imgAlgoMean iAlgo

    % combine all the images
    imgAll=[];
    for iAlgo=1:1:size(algoList,2)
        if iAlgo==1
            imgAll=[imgAll,imgRecon{iAlgo}];
        else
            imgAll=[imgAll,ones(size(imgRecon{1},1),5),imgRecon{iAlgo}];
        end
    end
    imgOri=[ones(size(imgOri,1),round((size(imgAll,2)-size(imgOri,2))/2)),imgOri];
    imgOri=[imgOri,ones(size(imgOri,1),size(imgAll,2)-size(imgOri,2))];
    imgAll=[imgOri;ones(10,size(imgAll,2));imgAll];
    clear imgOri imgRecon indGroup labelGroup iAlgo

    f=figure;set(gcf,'color','white');
    colormap(gray);
    imagesc(imgAll,[0,1]);
    axis image;
    axis off;
    if iRun==2
        f.Position=[100,100,1500,520];
    else
        f.Position=[100,100,1300,520];
    end
    clear imgAll f
end
clear stim stimPre plotList iRun

%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%
f=figure;set(gcf,'color','white');
f.Position=[100,100,580,700];
subplot(2,1,1);
hold on;
numgroups=size(meanCorr,1);
numbars=size(meanCorr,2);
groupwidth=min(0.8,numbars/(numbars+1.5));
b=bar(meanCorr,'grouped');
for i=1:numbars
    b(i).FaceColor=PlotColor{i};
end
for iGroup=1:numgroups
    for iBar=1:numbars
    x=(1:numgroups)-groupwidth/2+(2*iBar-1)*groupwidth/(2*numbars);
    errorbar(x(iGroup),meanCorr(iGroup,iBar),stdCorr(iGroup,iBar),'Color',[0,0,0] ,'Marker','none','MarkerSize',10,'linestyle',':','lineWidth',1);
    end
end
xlabel('Figure Image Category');
ylabel('Correlation');
legend(algoList,'Location','southeast');
set(gca,'XLim',[0.5,numgroups+0.5]);
set(gca,'XTick',1:1:numgroups);
set(gca,'XTickLabel',{'Geometric','Alphabet Layout 1','Alphabet Layout 2'});
set(gca,'YLim',[0,1.25]);
set(gca,'YTick',0:0.2:1);
set(gca,'YTickLabel',0:0.2:1);
set(gca,'TickDir','out');
set(gca,'TickLength',[.005,.005]);
set(gca,'XGrid','on');
set(gca,'YGrid','on');
set(gca,'GridLineStyle','-');
set(gca,'GridLineWidth',1);
set(gca,'GridColor',[0,0,0]);
set(gca,'GridAlpha',0.1);
box on;
set(gca,'LineWidth',1.2,'FontName','calibri','fontsize',12);

%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%
subplot(2,1,2);
hold on;
numgroups=size(meanMse,1);
numbars=size(meanMse,2);
groupwidth=min(0.8, numbars/(numbars+1.5));
b=bar(meanMse,'grouped');
for i=1:numbars
    b(i).FaceColor=PlotColor{i};
end
for iGroup=1:numgroups
    for iBar=1:numbars
    x=(1:numgroups)-groupwidth/2+(2*iBar-1)*groupwidth/(2*numbars);
    errorbar(x(iGroup),meanMse(iGroup,iBar),stdMse(iGroup,iBar),'Color',[0 0 0],'Marker','none','MarkerSize',10,'linestyle',':','lineWidth',1);
    end
end
xlabel('Figure Image Category');
ylabel('MSE');
set(gca,'XLim',[0.5,numgroups+0.5]);
set(gca,'XTick',1:1:numgroups);
set(gca,'XTickLabel',{'Geometric','Alphabet Layout 1','Alphabet Layout 2'});
set(gca,'YLim',[0,0.3]);
set(gca,'YTick',0:0.05:0.3);
set(gca,'YTickLabel',0:0.05:0.3);
set(gca,'TickDir','out');
set(gca,'TickLength',[.005,.005]);
set(gca,'XGrid','on');
set(gca,'YGrid','on');
set(gca,'GridLineStyle','-');
set(gca,'GridLineWidth',1);
set(gca,'GridColor',[0,0,0]);
set(gca,'GridAlpha',0.1);
box on;
set(gca,'LineWidth',1.2,'FontName','calibri','fontsize',12);
end