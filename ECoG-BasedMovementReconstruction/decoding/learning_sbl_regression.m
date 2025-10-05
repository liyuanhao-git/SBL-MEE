function [ww,NumFeaEff]=learning_sbl_regression(X,Y,Nlearn,aaMax)
% optimize the marginal likelihood P(Y|aa,sigma2) w.r.t. aa & sigma2

% convert to gpuArray
gpuDevice(1);
clear ans
X=gpuArray(X);
Y=gpuArray(Y);

% initialization for the hyper-parameters sigma2 and aa
sigma2=gpuArray(1);
aa=gpuArray(ones(size(X,2),1));

%effective index
IdxEff=gpuArray(1:1:size(X,2));
NumFeaEff=nan(Nlearn,1);

for ilearn=1:Nlearn
    % only use the effective parameters
    aaEff=aa(IdxEff);
    aaEffOld=aaEff;
    XEff=X(:,IdxEff);

    % compute the posterior covariance and mean value for ww
    postCov=inv(XEff'*XEff/sigma2+diag(aaEff));
    postMean=postCov*XEff'*Y/sigma2;

    % optimize the hyper-parameters for marginal likelihood (type-II)
    gamma=1-aaEff.*diag(postCov); % MacKay's effective numbers
    aaEff=gamma./(postMean.^2);  % fixed-point update aa
    sigma2=(norm(Y-XEff*postMean))^2/(size(XEff,1)-sum(gamma));
    clear XEff postCov postMean gamma

    if max(abs(aaEff-aaEffOld)./aaEffOld)<0.01
        aaConvFlag=1;clear aaEffOld
    else
        aaConvFlag=0;clear aaEffOld
    end

    % prune ineffective parameters
    aa(IdxEff)=aaEff; % restore aa using the original dimension
    IdxEff=find(aa<aaMax); % find the effective index using the original dimension
    NumFeaEff(ilearn)=length(IdxEff);
    clear aaEff

    if ilearn>=2
    if aaConvFlag==1 && NumFeaEff(ilearn)==NumFeaEff(ilearn-1)
        break;
    end
    end

    if isempty(IdxEff)
        fprintf('No Feature Survived!!\n');
        break;
    end
end
    aaEff=aa(IdxEff);
    XEff=X(:,IdxEff);
    IdxEff=gather(IdxEff);
    ww=zeros(size(X,2),1);
    ww(IdxEff)=gather((XEff'*XEff/sigma2+diag(aaEff))\(XEff'*Y/sigma2));
    NumFeaEff=length(IdxEff);
end