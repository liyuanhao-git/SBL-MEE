function cvIdx = createCvIdx_figRecon(totalRun, nRunOutLocal, nRunOutImg)


if nRunOutImg~=0
  error('this function is only for figure reconstruction mode. use other function to create img CV index list.');
end


if nRunOutLocal==0
  trainingRun=totalRun;    
  localCvRun=[];

  for i=1:size(trainingRun,1)
    trainingRunSet{i}=trainingRun(i,:);
    trainingRunSetStr{i}=strrep(num2str(trainingRunSet{i}, ' %1d'), ' ', '-');
  end

  localCvRunSet=[];
  localCvRunSetStr=[];

else
  if mod(length(totalRun),nRunOutLocal)
    error('totalRun num should be multiple of nRunOutLocal');
  end
  localCvNum=length(totalRun)/nRunOutLocal;
  localCvRun=reshape(totalRun,nRunOutLocal,localCvNum);
  
   for i=1:localCvNum
      trainingRun(i,:)=setdiff(totalRun,localCvRun(:,i))';
   end

   for i=1:size(trainingRun,1)
     trainingRunSet{i} = trainingRun(i,:);
     trainingRunSetStr{i} = strrep(num2str(trainingRunSet{i}, ' %1d'), ' ', '-');
  
     localCvRunSet{i} = localCvRun(:,i)';
     localCvRunSetStr{i} = strrep(num2str(localCvRunSet{i}, ' %1d'), ' ', '-');
   end
end


imgCvRunSet=[];
imgCvRunSetStr=[];

cvIdx.training.runIdx=trainingRunSet;
cvIdx.training.runStr=trainingRunSetStr;

cvIdx.localTest.runIdx=localCvRunSet;
cvIdx.localTest.runStr=localCvRunSetStr;

cvIdx.imgTest.runIdx=imgCvRunSet;
cvIdx.imgTest.runStr=imgCvRunSetStr;
end