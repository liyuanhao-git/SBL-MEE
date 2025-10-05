function [D, pars] = fmri_selectRoi(D, pars)
% fmri_selectRoi - selects roi sets specified by 'rois_use'
% [D, pars] = fmri_selectRoi(D, pars)
%
% Given an array of cells containing ROI indexes (rois_inds) and a same sized cell array
% with 0 or 1 for cell use (rois_use), this returns the data within the selected ROI.
%
% Input:
%   D.roi                 - voxel included ROIs ([rtype x space] format)
%   pars.rois_use         - cell array specifying use ROI (1), or not (0)
%                           if nested cell array, pars of 'within_operation' and 'across_operation' are used
% Optional:
%   pars.within_operation - method to merge within each list of 'rois_use':
%                           and(0), or(1, default), xor(2)
%   pars.across_operation - method to merge among lists of 'rois_use' (default:0)
%   pars.not_list         - add 'NOT' to each list when merge them:
%                           0=no, 1=yes (default:0)
%   pars.verbose          - [1..3] print detail level 0=no printing (default: 1)
% Output:
%   D.data                - data within the selected ROI ([time(sample) x space(voxel/channel)] format)
%   D.xyz                 - X,Y,Z-coordinate values within the selected ROI ([3(x,y,z) x space] format)
%   D.stat                - statistic within the selected ROI ([stype x space] format)
%
% Example:
%   pars.rois_use = {{1 1 1 0 0 0}; {0 0 0 1 1 1}};
%   pars.not_list = [0 1];
%       -> (roi1 | roi2 | roi3) & ~(roi4 | roi5 | roi6)
%
% ----------------------------------------------------------------------------------------
% Created by members of
%     ATR Intl. Computational Neuroscience Labs, Dept. of Neuroinformatics

% Check and get pars:
if ~exist('D','var') || isempty(D)
    error('''D''ata-struct must be specified');
end
if ~exist('pars','var'),    pars = [];      end

if isfield(pars,mfilename)      % unnest, if needed
    P    = pars;
    pars = P.(mfilename);
end
rois_use         = getFieldDef(pars,'rois_use',[]);
within_operation = getFieldDef(pars,'within_operation',1);
across_operation = getFieldDef(pars,'across_operation',0);
not_list         = getFieldDef(pars,'not_list',[]);
verbose          = getFieldDef(pars,'verbose',1);

% If 'rois_use' is absent, use all rois:
if isempty(rois_use)
    rois_use = repmat({1},1,size(D.roi,1));
end

if ~iscell(rois_use{1})
    rois_use = {rois_use};
end

% For UI:
if verbose
    fprintf(['\n' mfilename ' ------------------------------']);
end

% Select ROIs:
num_list = numel(rois_use);

% merge within lists:
inds_use  = cell(num_list,1);
rois_inds = [];
for itl=1:num_list
    rois = D.roi(logical([rois_use{itl}{:}]),:);
    if itl==1
        rois_inds = [rois_use{1}{:}];
    else
        rois_inds = rois_inds | [rois_use{itl}{:}];
    end
    for itr=1:size(rois,1)
        if itr==1
            inds_use{itl} = rois(1,:);
        else
            switch lower(within_operation)
                case {'and', 0}
                    inds_use{itl} = inds_use{itl} & rois(itr,:);
                case {'or', 1}
                    inds_use{itl} = inds_use{itl} | rois(itr,:);
                case {'xor', 2}
                    inds_use{itl} = xor(inds_use{itl},rois(itr,:));
                otherwise
                        error('''within_operation'' should be 0-2');
            end
        end
    end
end

% add not to lists:
if ~isempty(not_list)
    for itl=1:num_list
        if not_list(itl)
            inds_use{itl} = ~inds_use{itl};
        end
    end
end

% merge among lists:
for itl=2:num_list
    switch lower(across_operation)
        case {'and', 0}
            inds_use{1} = inds_use{1} & inds_use{itl};
        case {'or', 1}
            inds_use{1} = inds_use{1} | inds_use{itl};
        case {'xor', 2}
            inds_use{1} = xor(inds_use{1},inds_use{itl});
        otherwise
                error('''across_operation'' should be 0-2');
    end
end
inds_use = logical(inds_use{1});

num_all = size(D.roi,2);
num_use = length(find(inds_use));

% Select data within ROIs:
D.data = D.data(:,inds_use);
if isfield(D,'xyz'),    D.xyz  = D.xyz(:,inds_use);     end
if isfield(D,'stat'),   D.stat = D.stat(:,inds_use);    end
D.roi  = D.roi(logical(rois_inds),inds_use);

% User feedback:
if verbose
    fprintf('\n %d selected out of %d total voxels\n', num_use, num_all);
end

% For 'P'ars-struct
if exist('P','var')
    P.(mfilename) = pars;
    pars          = P;
end