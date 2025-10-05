function [trainingRunSet,trainingRunSetStr]=createCvIdx_nLeaveUnique(totalRun,nRunOutLocal,nRunOutImg)

if nRunOutImg==0 && nRunOutLocal==0
    trainingRunMat=totalRun;  
else

    if mod(length(totalRun),nRunOutImg)
        error('totalRun num should be multiple of nRunOutImg');
    end
    
    imgCvNum=length(totalRun)/nRunOutImg;
    imgCvRun=reshape(totalRun,nRunOutImg,imgCvNum);
    
    trainingRunMat=[];

    for i=1:imgCvNum
        localCvRun=setdiff(totalRun,imgCvRun(:,i));
        
        if nRunOutLocal==0
            trainingRunMat=[trainingRunMat; localCvRun];  
        else
            if mod(length(localCvRun),nRunOutLocal)
                error('localCvRun num should be multiple of nRunOutLocal');
            end
            
            localCvNum=length(localCvRun)/nRunOutLocal;
            localCvRun=reshape(localCvRun,nRunOutLocal,localCvNum);
            
            for j=1:localCvNum
                trainingRun(j,:)=setdiff(localCvRun(:),localCvRun(:,j))';
            end
            
            trainingRunMat=[trainingRunMat; trainingRun];
        end
    end
end

trainingRunMat=unique(trainingRunMat,'rows');

for i=1:size(trainingRunMat,1)
  trainingRunSet{i}=trainingRunMat(i,:);
  trainingRunSetStr{i}=strrep(num2str(trainingRunSet{i}, ' %1d'), ' ', '-');
end
end