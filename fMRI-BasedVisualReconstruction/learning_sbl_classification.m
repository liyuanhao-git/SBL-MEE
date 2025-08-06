function [ww,IdxEff]=learning_sbl_classification(tt,X,nlearn)
% Learning parameters of ARD-sparse logistic regression model.
gpuDevice(1);
aa=gpuArray(ones(size(X,2),1));
ww=gpuArray(zeros(size(X,2),1));
IdxEff=gpuArray(1:1:size(X,2));
tt=gpuArray(tt);
X=gpuArray(X);

for ilearn=1:nlearn
   % Effective parameters
   aaEff=aa(IdxEff);
   wwEff=ww(IdxEff);
   XEff=X(:,IdxEff);
   
   % W-step
   wwEff=w_mle_adam(wwEff,tt,aaEff,XEff);

   % compute the inverse hessian matrix
   pp=1./(1+exp(-XEff*wwEff));
   bb=pp.*(1-pp);
   SEff=inv(XEff'*diag(bb)*XEff+diag(aaEff));
   
   % A-step
   aaEff=(1-aaEff.*diag(SEff))./(wwEff.^2);
 
   % Prune ineffective parameters
   ww=gpuArray(zeros(size(X,2),1));
   ww(IdxEff)=wwEff;
   aa(IdxEff)=aaEff;
   IdxEff=find(aa<1e8);

   if isempty(IdxEff)
       ww=zeros(size(X,2),1);
       break;
   end
end
    ww=gather(ww);
    IdxEff=gather(IdxEff);
    ww(setdiff(1:1:size(X,2),IdxEff))=0;
end

function wFinal=w_mle_adam(wInt,tt,aa,X)
yita=gpuArray(0.0003);
beta1=gpuArray(0.9);
beta2=gpuArray(0.999);
vTemp=gpuArray(0);
mTemp=gpuArray(0);
wTemp=wInt;
nlearn=gpuArray(800);

for ilearn=1:nlearn
    % prediction probability
    pp=1./(1+exp(-X*wTemp));
    
    % gradient of regularized loglikelihood
    Grad=-X'*(tt-pp)+aa.*wTemp;
    
    vTempNew=beta2*vTemp+(1-beta2)*Grad.^2;
    mTempNew=beta1*mTemp+(1-beta1)*Grad;
    
    mHat=mTempNew/(1-beta1^ilearn);
    vHat=vTempNew/(1-beta2^ilearn);

    wTemp=wTemp-yita*mHat./(10^(-8)+vHat.^0.5);
    vTemp=vTempNew;
    mTemp=mTempNew;
end
    wFinal=wTemp;
end