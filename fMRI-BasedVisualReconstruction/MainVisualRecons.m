clc;
clear;

addpath('functions/');
% Train local decoders
% leave0->using all training data to train 100 pixel-wise classifiers
% leave1->10-fold cross validation to estimate combination coefficients
trainLocalDecoder({'1x1'},'V1V2','leave0','SBL');
trainLocalDecoder({'1x1'},'V1V2','leave1','SBL');
trainLocalDecoder({'1x1'},'V1V2','leave0','SBCL');
trainLocalDecoder({'1x1'},'V1V2','leave1','SBCL');
trainLocalDecoder({'1x1'},'V1V2','leave0','SBLMEE');
trainLocalDecoder({'1x1'},'V1V2','leave1','SBLMEE');

% Extract local decoders
extractDecoder({'1x1'},'leave0','SBL');
extractDecoder({'1x1'},'leave1','SBL');
extractDecoder({'1x1'},'leave0','SBCL');
extractDecoder({'1x1'},'leave1','SBCL');
extractDecoder({'1x1'},'leave0','SBLMEE');
extractDecoder({'1x1'},'leave1','SBLMEE');

% Reconstruct the visual stimulus
calCombCoef_figRecon_smlr('1x1','errFuncImageNonNegCon','V1V2','SBL');
figReconSmlr('1x1','errFuncImageNonNegCon','V1V2','SBL');
calCombCoef_figRecon_smlr('1x1','errFuncImageNonNegCon','V1V2','SBCL');
figReconSmlr('1x1','errFuncImageNonNegCon','V1V2','SBCL');
calCombCoef_figRecon_smlr('1x1','errFuncImageNonNegCon','V1V2','SBLMEE');
figReconSmlr('1x1','errFuncImageNonNegCon','V1V2','SBLMEE');

% Evaluation of visual stimulus reconstruction
evalVisualRecons({'SBL','SBCL','SBLMEE'});
rmpath('functions/');
fprintf('Finished!! \n');