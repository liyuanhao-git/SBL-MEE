function [ww,IdxEff]=learning_sblmee_classification(tt,X,nlearn)

% Initialization using correntropy-based model
[wwSbcl,~]=learning_sbcl_classification(tt,X,nlearn);
eeSbcl=tt-1./(1+exp(-X*wwSbcl));
Phi=[size(tt,1)-sum(eeSbcl<-0.5)-sum(eeSbcl>0.5),sum(eeSbcl<-0.5),sum(eeSbcl>0.5)]/size(tt,1);
clear wwSbcl eeSbcl

% Sample generation from N to MN
CodeBookPos=[0,-1,1];
xxQmee=repmat(X,size(CodeBookPos,2),1);
ttQmee=zeros(size(tt,1)*size(CodeBookPos,2),1);
PhiQmee=zeros(size(tt,1)*size(CodeBookPos,2),1);
for iCode=1:1:size(CodeBookPos,2)
    ttQmee((iCode-1)*size(tt,1)+1:iCode*size(tt,1),1)=tt-CodeBookPos(iCode);
    PhiQmee((iCode-1)*size(tt,1)+1:iCode*size(tt,1),1)=Phi(iCode);
end
clear iCode Phi tt CodeBookPos

% convert to gpuArray
gpuDevice(1);
hh=gpuArray(1);
X=gpuArray(X);
xxQmee=gpuArray(xxQmee);
ttQmee=gpuArray(ttQmee);
PhiQmee=gpuArray(PhiQmee);

% Initial value for A-step and W-step
aa=gpuArray(ones(size(X,2),1));
ww=gpuArray(zeros(size(X,2),1));
IdxEff=gpuArray(1:1:size(X,2));

for ilearn=1:nlearn
   % Effective parameters 
   aaEff=aa(IdxEff);
   wwEff=ww(IdxEff);
   xxQmeeEff=xxQmee(:,IdxEff);
   
   % W-step
   wwEff=w_rmee_adam(wwEff,aaEff,hh,xxQmeeEff,ttQmee,PhiQmee);

   % compute the inverse hessian matrix
   ppQmee=1./(1+exp(-xxQmeeEff*wwEff));
   eeQmee=ttQmee-ppQmee;
   bbQmee=PhiQmee.*exp(-0.5*eeQmee.^2/hh).*((eeQmee.^2/hh-1).*(ppQmee.^2).*((1-ppQmee).^2)+(1-2*ppQmee).*eeQmee.*ppQmee.*(1-ppQmee))/hh;
   SEff=inv(-xxQmeeEff'*diag(bbQmee)*xxQmeeEff+diag(aaEff));
   
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

function wFinal=w_rmee_adam(wInt,aa,hh,xxQmee,ttQmee,PhiQmee)
nn=gpuArray(size(xxQmee,2));
yita=gpuArray(1e-3);
beta1=gpuArray(0.9);
beta2=gpuArray(0.999);
vTemp=gpuArray(0);
mTemp=gpuArray(0);
wwTemp=wInt;
ObjFunc=gather(sum(PhiQmee.*exp(-0.5*(ttQmee-1./(1+exp(-xxQmee*wwTemp))).^2/hh))-0.5*wwTemp'*diag(aa)*wwTemp);

Nlearn=gpuArray(1000);
ilearn=gpuArray(1);
while 1
    if yita<1e-12
        break;
    end
    % prediction probability
    ppQmee=1./(1+exp(-xxQmee*wwTemp));
    qqQmee=1-ppQmee;
    eeQmee=ttQmee-1./(1+exp(-xxQmee*wwTemp));
    % gradient of regularized correntropy
    Grad=(sum(xxQmee.*repmat(PhiQmee.*exp(-0.5*eeQmee.^2/hh).*eeQmee.*ppQmee.*qqQmee,1,nn),1))'/hh-aa.*wwTemp;
    vTempNew=beta2*vTemp+(1-beta2)*Grad.^2;
    mTempNew=beta1*mTemp+(1-beta1)*Grad;
    GradAdam=(mTempNew/(1-beta1^ilearn))./(10^(-8)+(vTempNew/(1-beta2^ilearn)).^0.5);
    wwTempNew=wwTemp+yita*GradAdam;

    % objective function of regularized correntropy
    ObjFunc=[ObjFunc,gather(sum(PhiQmee.*exp(-0.5*(ttQmee-1./(1+exp(-xxQmee*wwTempNew))).^2/hh))-0.5*wwTempNew'*diag(aa)*wwTempNew)];
    if isnan(ObjFunc(end)) || ObjFunc(end)<ObjFunc(end-1)
        yita=yita/sqrt(10);
        ObjFunc(end)=[];
        clear wwTempNew vTempNew mTempNew
        continue;
    else
        wwTemp=wwTempNew;
        vTemp=vTempNew;
        mTemp=mTempNew;
        clear wwTempNew vTempNew mTempNew
    end
    if abs((ObjFunc(end)-ObjFunc(end-1))/ObjFunc(end-1))<1e-6
        break;
    end
    if ilearn>Nlearn
        break;
    end
    ilearn=ilearn+1;
end
wFinal=wwTemp;
end