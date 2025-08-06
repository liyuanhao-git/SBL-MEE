function calCombCoef_figRecon_smlr(DecoCombType,OptMode,roiArea,AlgoName)
% Minimizing reconstruction error using combination coefficient

%%% Exp parameter setting
onVal=1;
resol=10;
RandRun=1:20;
FigRun=21:32;
PredMode='maxProbLabel';
BasisNormMode='dimNorm';
roiEcc='Ecc1to11';
roiName=[roiArea '_' roiEcc];
cvModeImgRecon='trainCombFigRecon';

SaveDir=[AlgoName,'Result'];
SaveFname=[roiName '_linComb_' OptMode '_' DecoCombType '_figReconW.mat'];

%%% Load preprocessed mat file and extracted decoder mat file
fnameData=[roiName,'_1x1_preprocessed'];
fprintf(['loading ... ' fnameData ' \n']);
load(fnameData,'D');
D_1x1=D;

DecoderPath=[AlgoName,'Decoder/leave1_'];
[DecoderAllCv,BasisMat,~,Cv_set]=prepareDecoder_basisNormalized(RandRun,DecoderPath,DecoCombType,BasisNormMode,cvModeImgRecon);
% extract data of figure image
[SmpFigTest,StimFigTest]=getNoRestData(D_1x1,FigRun);
LabelFigTest=StimFigTest(:,1);
StimFigTest=StimFigTest(:,2:end)/onVal;

StimLocalTestAll=[];
xLocalTestAll=[];
LabelLocalTestAll=[];
StimFigTestAll=[];
xFigTestAll=[];
LabelFigTestAll=[];

for iCv=1:size(DecoderAllCv,2)

    LocalTestRun=Cv_set.localTest.runIdx{iCv};
    if any(ismember(LocalTestRun,Cv_set.imgTest.runIdx)) ||...
            any(ismember(LocalTestRun,Cv_set.training.runIdx{iCv})) || ...
            any(ismember(Cv_set.training.runIdx{iCv},Cv_set.imgTest.runIdx))
        error('test and training runs are overlapping');
    end

    fprintf('runs for local train: %s, runs for basis combination: %s, run for reconstruction test: %s\n',...
        Cv_set.training.runStr{iCv},Cv_set.localTest.runStr{iCv},Cv_set.imgTest.runStr);

    decoder=DecoderAllCv(:,iCv);

    % localTest
    [SmpLocalTest,StimLocalTest]=getNoRestData(D_1x1,LocalTestRun);
    LabelLocalTest=StimLocalTest(:,1);
    StimLocalTest=StimLocalTest(:,2:end)/onVal;

    % predict each decoder.
    for iDeco=1:size(decoder,1)
        if strcmp(decoder{iDeco}.model,'slr121a')
            LabelPreLocalTest(:,iDeco)=predictSmlr(decoder{iDeco},SmpLocalTest,PredMode);
            LabelPreFigTest(:,iDeco)=predictSmlr(decoder{iDeco},SmpFigTest,PredMode);
        else
            error('invalid model');
        end
    end

    for iPix=1:(resol^2)
        nSmp=size(LabelPreLocalTest,1);
        LabelPreinPix=repmat(BasisMat(:,iPix),1,nSmp).*LabelPreLocalTest';
        xLocalTest(iPix,:,:)=LabelPreinPix;

        nSmp=size(LabelPreFigTest,1);
        LabelPreinPix=repmat(BasisMat(:,iPix),1,nSmp).*LabelPreFigTest';
        xFigTest(iPix,:,:)=LabelPreinPix;
    end

    StimLocalTestAll=[StimLocalTestAll;StimLocalTest];
    xLocalTestAll=cat(3,xLocalTestAll,xLocalTest);
    LabelLocalTestAll=[LabelLocalTestAll,LabelLocalTest];

    StimFigTestAll=[StimFigTestAll;StimFigTest];
    xFigTestAll=cat(3,xFigTestAll,xFigTest);
    LabelFigTestAll=[LabelFigTestAll,LabelFigTest];
end

y=StimLocalTestAll';
x=xLocalTestAll;
errFunc='errFuncImage';
w0=zeros(size(x,2),1);
lb=zeros(size(x,2),1);
iterNum=1000;
Display='iter';
options=optimset('GradObj','on','MaxIter',iterNum,'Display',Display);
[w_decoder,~]=fmincon(errFunc,w0,[],[],[],[],lb,[],[],options,y,x);

for iSmp=1:size(xLocalTestAll,3)
    StimLocalTestAllPre(iSmp,:)=xLocalTestAll(:,:,iSmp)*w_decoder;
end
for iSmp = 1:size(xFigTestAll,3)
    StimFigTestAllPre(iSmp,:)=xFigTestAll(:,:,iSmp)*w_decoder;
end

saveVars={'decoder','BasisMat','w_decoder', 'DecoderAllCv',...
    'LabelLocalTestAll','StimLocalTestAll','StimLocalTestAllPre', ...
    'LabelFigTestAll','StimFigTestAll','StimFigTestAllPre', ...
    'RandRun','FigRun','PredMode','BasisNormMode'};

if ~exist(SaveDir,'dir')
    mkdir(SaveDir)
end
save([SaveDir,'/',SaveFname],saveVars{:});