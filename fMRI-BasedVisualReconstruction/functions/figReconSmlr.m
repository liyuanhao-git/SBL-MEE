function figReconSmlr(DecoCombType,OptMode,roiArea,AlgoName)
% Reconstruction of figure image using optimized combination coefficient

%%% Exp parameter setting
onVal=1;
resol=10;
RandRun=1:20;
FigRun=21:32;
PredMode='maxProbLabel';
BasisNormMode='dimNorm'; 

%%% Model setting
roiEcc='Ecc1to11';
roiName=[roiArea '_' roiEcc];

cvModeImgRecon='figRecon';
weightDir=[AlgoName 'Result'];

%%% wOfDecoder file name
weightFname=[roiName '_linComb_' OptMode '_' DecoCombType '_figReconW.mat'];
%%% save file name
saveFname=[roiName '_linComb_' OptMode '_' DecoCombType '_figRecon.mat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load preprocessed mat file, extracted decoder mat file and combination coefficient
fnameD=[roiName '_1x1_preprocessed'];
fprintf(['loading ... ' fnameD ' \n']);
load(fnameD,'D');
D_1x1=D;

DecoderPath=[AlgoName,'Decoder/leave0_'];
[DecoderAllCv,BasisMat,~,CvSet]=prepareDecoder_basisNormalized(RandRun, DecoderPath,DecoCombType,BasisNormMode,cvModeImgRecon);

fnameW=[weightDir,'/',weightFname];
fprintf(['loading combination coefficient ... ',fnameW,' \n']);
load(fnameW,'w_decoder');
clear weightDir weightFname fnameW

% extract data of figure image
[SmpFigTest,StimFigTest]=getNoRestData(D_1x1,FigRun);
LabelFigTest=StimFigTest(:,1);
StimFigTest=StimFigTest(:,2:end)/onVal;

StimFigTestAll=[];
xFigTestAll=[];
LabelFigTestAll=[];
for iCv=1:size(DecoderAllCv,2)

  fprintf('runs for local train: %s, run for reconstruction test: %s\n',CvSet.training.runStr{iCv}, strrep(num2str(FigRun, ' %1d'), ' ', '-'));
  decoder=DecoderAllCv(:,iCv);

  % predict each decoder.
  for iDeco=1:size(decoder,1)
      if strcmp(decoder{iDeco}.model,'slr121a')      
          LabelPreFigTest(:,iDeco)=predictSmlr(decoder{iDeco},SmpFigTest,PredMode);
      else
          error('invalid model');
      end
  end

  for iPix=1:(resol^2)
    nSmp=size(LabelPreFigTest,1);
    LabelPreinPix=repmat(BasisMat(:,iPix),1,nSmp).*LabelPreFigTest';
    xFigTest(iPix,:,:)=LabelPreinPix; %% [nPixel x nDecoder x nSmpl]
  end

  StimFigTestAll=[StimFigTestAll;StimFigTest];
  xFigTestAll=cat(3,xFigTestAll,xFigTest);
  LabelFigTestAll=[LabelFigTestAll,LabelFigTest];
end

for iSmp=1:size(xFigTestAll,3)
    StimFigTestAllPre(iSmp,:)=xFigTestAll(:,:,iSmp)*w_decoder;
end

saveVars={'decoder','BasisMat','w_decoder','DecoderAllCv',...
	    'LabelFigTestAll','StimFigTestAll','StimFigTestAllPre',...
	    'RandRun','FigRun','PredMode','BasisNormMode'};

saveDir=[AlgoName,'Result'];
save([saveDir '/' saveFname],saveVars{:});