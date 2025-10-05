function [ww,NumFeaEff,IdxHist]=learning_sbcl_regression(X,Y,hh,Nlearn,aaMax)
% variational inference optimization by alternate updates ww & aa

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
IdxHist=cell(Nlearn,1);

for ilearn=1:Nlearn
   % only use the effective parameters
   aaEff=aa(IdxEff);
   aaEffOld=aaEff;
   XEff=X(:,IdxEff);
   wwEff=ww(IdxEff);
   
   % w-step to optimize the model parameter ww with current aa
   diagaa=diag(aaEff);
   ObjFuncFp=gather(hh*sum(exp(-(Y-XEff*wwEff).^2/(2*hh)))-sum(wwEff.^2.*diag(diagaa))/2);
   for iifp=1:10
     ExpWX=repmat(exp(-(Y-XEff*wwEff).^2/(2*hh)),1,size(XEff,2)).*XEff;
     wwEff=(ExpWX'*XEff+diagaa)\(ExpWX'*Y);
     ObjFuncFp=[ObjFuncFp,gather(hh*sum(exp(-(Y-XEff*wwEff).^2/(2*hh)))-sum(wwEff.^2.*diag(diagaa))/2)];
     if abs(ObjFuncFp(end)-ObjFuncFp(end-1))/abs(ObjFuncFp(end-1))<1e-4
        break;
     end
   end
   clear diagaa ObjFuncFp iifp ExpWX

   % compute the inverse Hessian matrix
   bb=exp(-0.5*(Y-XEff*wwEff).^2/hh).*((Y-XEff*wwEff).^2/hh-1)/hh;
   SEff=inv(-XEff'*(repmat(bb,1,size(XEff,2)).*XEff)+diag(aaEff));
   
   % a-step to optimize the hyper-parameter aa
   aaEff=(1-aaEff.*diag(SEff))./(wwEff.^2);
   clear XEff SEff bb

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
   IdxHist{ilearn}=gather(IdxEff);
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