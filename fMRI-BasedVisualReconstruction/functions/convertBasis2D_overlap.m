function [dataNew,W]=convertBasis2D_overlap(data,orgDim,basisMini)
%function [dataNew, W] = convertBasis2D_overlap2(data, orgDim, basisMini)
%
% Input:
%	data - [nSmpl x nBasis] data matrix. nBasis must be interger^2
%       orgDim - [resolH resolW]
%	basisMini - new basis matrix
%
% Output:
%	dataNew  - [nSmpl x nBasisNew] converted data matrix
%
% [Caution!!]
% Zero of basisMini means that any value is ok.
% In case of basisMini is [0 1; 1 0].
% [1 1; 1 1], [1 1; 1 0], [0 1; 1 1] and [0 1; 1 0] are converted to same val.
%
% 2006/11/18 Created By: Hajime Uchida
% modified by YM --- fix imcompatibility of 'resol = sqrt(size(data,1))'.
% This sometimes caused floating number for the following matrix index.
% 2007/02/13 no-regularization by HU
% modified by Yoichi Miyawaki 2012/04/29 for compatibility for new data format

% check input parameter
if nargin<3
  basisMini=ones(2);
end

%resol = sqrt(size(data,1));
resolH=orgDim(1);
resolW=orgDim(2);
basisSizeH=size(basisMini,1);
basisSizeW=size(basisMini,2);
nBasisNew=(resolH-basisSizeH+1)*(resolW-basisSizeW+1);

% create basis convert matrix
W=zeros(nBasisNew,resolH,resolW);
basisIdx=1;
for posW=1:(resolW-basisSizeW+1)
  for posH=1:(resolH-basisSizeH+1)
    W(basisIdx,posH:posH+basisSizeH-1,posW:posW+basisSizeW-1)=basisMini;
    basisIdx=basisIdx+1;
  end
end
W=reshape(W,nBasisNew,resolH*resolW);

% convert
dataNew=data*W';

return