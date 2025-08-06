function [decoder,basisMat,decoderName,cvIdx]=prepareDecoder_basisNormalized(totalRun,basePath,decoderName,basisNormMode,cvMode,imgCvRunSetIdx)

switch cvMode
  case 'trainCombFigRecon'
    imgCvRunSetIdx = [];
    cvIdx = createCvIdx_figRecon(totalRun,2,0);
  case 'figRecon'
    imgCvRunSetIdx = [];
    cvIdx = createCvIdx_figRecon(totalRun,0,0);
  case 'trainCombRandRecon'
    cvIdx = createCvIdx_randRecon(totalRun,2,2,imgCvRunSetIdx);
  case 'randRecon'
    cvIdx = createCvIdx_randRecon(totalRun,0,2,imgCvRunSetIdx);
  otherwise
    error('invalid cvMode');
end

switch basisNormMode 
  case 'noNorm'
    basisNormCoef = [1 1 1 1];
  case 'dimNorm'
    basisNormCoef = [numel(ones(1)) numel(ones(1,2)) numel(ones(2,1)) numel(ones(2,2))];
  case 'L2Norm'
    basisNormCoef = [norm(ones(1)) norm(ones(1,2)) norm(ones(2,1)) norm(ones(2,2))];
end

basisMat=[];
for j=1:length(cvIdx.training.runIdx)
    
  k=1;
  trainStr=cvIdx.training.runStr{j};

  if strfind(decoderName, '1x1')
    fname{k}=[basePath '1x1_' trainStr]; labelList{k}=[0 1]/basisNormCoef(1); k=k+1;
  end

  if isempty(imgCvRunSetIdx)
      fprintf('\nfname set complete: cv %d\n',j);
  else
      fprintf('\nfname set complete: %d -- cv %d\n',imgCvRunSetIdx, j);
  end
    
  % prepare decoder, basisMatrix
  decoIdx=1;
  for k=1:size(fname,2)
    fprintf('loading %s \n',fname{k});
    tmpDeco=load(fname{k});
    
    % decoder preparation.
    for dIdx = 1:size(tmpDeco.decoder,2)
      decoder{decoIdx,j}=tmpDeco.decoder{dIdx};
      decoder{decoIdx,j}.labelList=labelList{k};
      decoIdx=decoIdx + 1;
    end
    if j==totalRun(1)
      basisMat=[basisMat;tmpDeco.BasisMat];
    end
  end
end