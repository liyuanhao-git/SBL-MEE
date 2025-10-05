function [smpl,label,runIdxForSmpl,mskInOrigData]=getNoRestData(D,runIdxList)
%
% [In]
%   D : sample x voxel
%   runIdxList : [1 x nRunIdxList]
%
% [Out]
%   smpl :  [sample x voxel]
%   labels :  [sample x label] nLabels is number of decoder.
%   runIdxForSmpl :  [sample x 1] run index for each sample.

if nargin<2
  mode='all';
else
  mode='run';
end

% select smpl
smplMask=false(size(D.data,1),1);
runIdxForSmpl=false(size(D.data,1),1);
runDesignIdx=find(ismember(D.design_type,'run'));
if strcmp(mode,'all')
    smplMask(:)=true;
elseif strcmp(mode,'run')
    for runIdx=runIdxList
        smplMask(D.design(:,runDesignIdx)==runIdx)=1;
    end
end
runIdxForSmpl=D.design(:,runDesignIdx);

% get exclude rest mask
rest_label=find(cellfun(@any, strfind(D.label_def{ismember(D.label_type,'image')},'rest')));
noRestIdxMask = ~ismember(D.label(:,1),rest_label);

smpl=D.data(smplMask&noRestIdxMask,:);
label=D.label(smplMask&noRestIdxMask,:);
runIdxForSmpl=runIdxForSmpl(smplMask&noRestIdxMask,:);
mskInOrigData=smplMask&noRestIdxMask;
end