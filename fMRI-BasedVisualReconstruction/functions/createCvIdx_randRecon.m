function cvIdx = createCvIdx_randRecon(totalRun, nRunOutLocal, nRunOutImg, imgCvRunSetIdx)

if mod(length(totalRun),nRunOutImg)
  error('totalRun num should be multiple of nRunOutImg');
end


imgCvNum=length(totalRun)/nRunOutImg;
imgCvRun=reshape(totalRun,nRunOutImg,imgCvNum);


localCvRun=setdiff(totalRun,imgCvRun(:,imgCvRunSetIdx));

if nRunOutLocal == 0
    trainingRun = localCvRun;  
  else

    if mod(length(localCvRun),nRunOutLocal)
      error('localCvRun num should be multiple of nRunOutLocal');
    end

    localCvNum = length(localCvRun)/nRunOutLocal;
    localCvRun=reshape(localCvRun,nRunOutLocal,localCvNum);

  
    for j = 1:localCvNum
      trainingRun(j,:) = setdiff(localCvRun(:),localCvRun(:,j))';
    end
end

for i = 1:size(trainingRun,1)
  trainingRunSet{i} = trainingRun(i,:);
  trainingRunSetStr{i} = strrep(num2str(trainingRunSet{i}, ' %1d'), ' ', '-');
  if nRunOutLocal == 0
    %localCvRunSet{i} =  imgCvRun(:,imgCvRunSetIdx)';
    %localCvRunSetStr{i} =  strrep(num2str(localCvRunSet{i}, ' %1d'), ' ', '-');

    localCvRunSet{i} =  [];
    localCvRunSetStr{i} =  [];
  else
    localCvRunSet{i} = localCvRun(:,i)';
    localCvRunSetStr{i} = strrep(num2str(localCvRunSet{i}, ' %1d'), ' ', '-');
  end
end

imgCvRunSet = imgCvRun(:,imgCvRunSetIdx)';
imgCvRunSetStr = strrep(num2str(imgCvRunSet, ' %1d'), ' ', '-');


cvIdx.training.runIdx = trainingRunSet;
cvIdx.training.runStr = trainingRunSetStr;

cvIdx.localTest.runIdx = localCvRunSet;
cvIdx.localTest.runStr = localCvRunSetStr;

cvIdx.imgTest.runIdx = imgCvRunSet;
cvIdx.imgTest.runStr = imgCvRunSetStr;