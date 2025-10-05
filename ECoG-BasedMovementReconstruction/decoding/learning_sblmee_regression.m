function [ww,NumFeaEff]=learning_sblmee_regression(X,Y,hh,Nlearn,aaMax)
% variational inference optimization by alternate updates ww & aa

QmeeCodeNum=20;
% convert to gpuArray
gpuDevice(1);
clear ans
X=gpuArray(X);
Y=gpuArray(Y);
hh=gpuArray(hh);

% initialization for ww and aa
ww=gpuArray(zeros(size(X,2),1)); % model parameter
aa=gpuArray(ones(size(X,2),1)); % relevance parameter

% effective index
IdxEff=gpuArray(1:1:size(X,2));
NumFeaEff=nan(Nlearn,1);

for ilearn=1:Nlearn
   % only use the effective parameters
   aaEff=aa(IdxEff);
   aaEffOld=aaEff;
   XEff=X(:,IdxEff);
   
   % w-step to optimize the model parameter ww with current aa
   wwEff=learning_qmee_fp(Y,diag(aaEff),XEff,hh,QmeeCodeNum);

   % compute the inverse Hessian matrix
   Err=Y-XEff*wwEff;
   XbbX=gpuArray(0);
   [CodeBookNum,CodeBookPos]=quantize_error(Err,QmeeCodeNum);
   for iCode=1:1:size(CodeBookNum,1)
      bb=exp(-0.5*(Err-CodeBookPos(iCode)).^2/hh).*((Err-CodeBookPos(iCode)).^2/hh-1)*CodeBookNum(iCode)/hh;
      XbbX=XbbX+XEff'*(repmat(bb,1,size(XEff,2)).*XEff);
   end
   clear bb iCode CodeBookNum CodeBookPos
   SEff=inv(-XbbX+diag(aaEff));
   clear Err XbbX
   
   % a-step to optimize the hyper-parameter aa
   aaEff=(1-aaEff.*diag(SEff))./(wwEff.^2);
   clear XEff SEff

   if max(abs(aaEff-aaEffOld)./aaEffOld)<0.01
        aaConvFlag=1;clear aaEffOld
    else
        aaConvFlag=0;clear aaEffOld
    end
 
   % prune ineffective parameters
   ww=gpuArray(zeros(size(X,2),1));
   ww(IdxEff)=wwEff;
   aa(IdxEff)=aaEff; % restore aa using the original dimension
   IdxEff=find(aa<aaMax); % find the effective index using the original dimension
   NumFeaEff(ilearn)=length(IdxEff);
   clear aaEff wwEff

   if ilearn>=2
   if aaConvFlag==1 && NumFeaEff(ilearn)==NumFeaEff(ilearn-1)
       break;
   end
   end

   if isempty(IdxEff)
       fprintf('No feature is survived!!\n');
       ww=zeros(size(X,2),1);
       break;
   end
end
    ww=gather(ww);
    IdxEff=gather(IdxEff);
    ww(setdiff(1:1:size(X,2),IdxEff))=0;
    NumFeaEff=length(IdxEff);
end

function ww=learning_qmee_fp(Y,diagaa,X,hh,QmeeCodeNum)
% use the fixed-point optimization for minimum-error-entropy regression
ww=(X'*X+diagaa)\(X'*Y);
for iifp=1:20
    CurrErr=Y-X*ww;
    [CodeBookNum,CodeBookPos]=quantize_error(CurrErr,QmeeCodeNum);
    % Sample generation from N to MN
    xxQmee=repmat(X,size(CodeBookNum,1),1);
    yyQmee=gpuArray(zeros(size(Y,1)*size(CodeBookNum,1),1));
    ExpW=gpuArray(zeros(size(Y,1)*size(CodeBookNum,1),1));
    for iCode=1:1:size(CodeBookNum,1)
    yyQmee((iCode-1)*size(Y,1)+1:iCode*size(Y,1),1)=Y-CodeBookPos(iCode);
    ExpW((iCode-1)*size(Y,1)+1:iCode*size(Y,1),1)=CodeBookNum(iCode)*exp(-(CurrErr-CodeBookPos(iCode)).^2/(2*hh));
    end
    ww=(xxQmee'*(repmat(ExpW,1,size(X,2)).*xxQmee)+diagaa*hh)\(xxQmee'*(ExpW.*yyQmee));
    clear ExpW CurrErr iCode xxQmee yyQmee CodeBookNum CodeBookPos
end
end

function [CodeBookNum,CodeBookPos]=quantize_error(CurrErr,QmeeCodeNum)
% Quantization of current error
    ErrRange=linspace(min(CurrErr),max(CurrErr),QmeeCodeNum+1);
    CodeBookNum=[];
    CodeBookPos=[];
    for iCode=1:1:QmeeCodeNum
        LowerBound=ErrRange(iCode);
        UpperBound=ErrRange(iCode+1);
        CountNum=sum(CurrErr>=LowerBound & CurrErr<=UpperBound);
        if CountNum~=0
        CodeBookNum=[CodeBookNum;CountNum];
        CodeBookPos=[CodeBookPos;mean(CurrErr(CurrErr>=LowerBound & CurrErr<=UpperBound))];
        end
        clear LowerBound UpperBound CountNum
    end
    clear ErrRange iCode
end