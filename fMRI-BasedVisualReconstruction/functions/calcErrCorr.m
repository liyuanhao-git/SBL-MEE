function [msqerr,corrVal,corrPval]=calcErrCorr(stim,stimPre)
msqerr=mean((stim-stimPre).^2,2);
for smplIdx=1:size(stim,1)
    if sum(stim(smplIdx,:))~=0
        [tmpCorr,tmpPval]=corrcoef(stim(smplIdx,:),stimPre(smplIdx,:));
        corrVal(smplIdx,1)=tmpCorr(1,2);
        corrPval(smplIdx,1)=tmpPval(1,2);
    else    
        corrVal(smplIdx,1)=0;
        corrPval(smplIdx,1)=0;
    end
end
msqerr=msqerr(:);
corrVal=corrVal(:);
corrPval=corrPval(:);
end