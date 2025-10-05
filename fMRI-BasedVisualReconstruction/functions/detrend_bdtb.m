function [D, pars] = detrend_bdtb(D, pars)
% detrend_bdtb - calls detrend on data along time dimension with options
% [D, pars] = detrend_bdtb(D, pars)
%
% Calls detrend on data along time dimension, optionally subtracting mean
% and detrending piecewise between breaks' begin and end points.
%
% Input:
%   D.data         - 2D matrix of any data ([time(sample) x space(voxel/channel)] format)
% Optional:
%   D.design       - design matrix of experiment ([time x dtype] format)
%   pars.sub_mean  - subtract mean? 0=no (default); 1=yes
%   pars.method    - 'linear' subtract linear fit (default); 'constant' sub just mean
%   pars.breaks    - [2 x N] matrix of break points for piecewise detrend;
%                    rows: 1-begin points, 2-end points; may contain just begin or end;
%   pars.break_run - use 'inds_runs' as 'breaks' (1, default), or not (0)
%   pars.verbose   - [1..3] = print detail level; 0 = no printing (default=1)
% Output:
%   D.data         - detrended data
%
% ----------------------------------------------------------------------------------------
% Created by members of
%     ATR Intl. Computational Neuroscience Labs, Dept. of Neuroinformatics


% Check and get pars:
if ~exist('D','var') || isempty(D)
    error('''D''ata-struct must be specified');
end
if ~exist('pars','var'),	pars = [];      end

if isfield(pars,mfilename)      % unnest, if needed
    P    = pars;
    pars = P.(mfilename);
end
sub_mean  = getFieldDef(pars,'sub_mean',0);
method    = getFieldDef(pars,'method','linear');
breaks    = getFieldDef(pars,'breaks',[]);
break_run = getFieldDef(pars,'break_run',1);
verbose   = getFieldDef(pars,'verbose',1);

if isempty(breaks)
    if break_run
        ind = find(strcmpi(D.design_type,'run'));
        if isempty(ind),    ind = 1;    end
        breaks(2,:) = [find(diff(D.design(:,ind)))' size(D.design,1)];
        breaks(1,:) = [1 breaks(2,1:end-1)+1];
    else
        breaks      = [1;size(D.data,1)];
    end
end
num_breaks = size(breaks,2);

% For UI:
if verbose
    fprintf(['\n' mfilename ' ------------------------------']);
    if verbose>=2
        fprintf('\n # breaks:\t%d',num_breaks);
        fprintf('\n sub_mean:\t%d',sub_mean);
        fprintf('\n method:  \t%s',method);
    end
    fprintf('\n');
end

% Detrend
for itb=1:num_breaks
    bi = breaks(1,itb);
    ei = breaks(2,itb);
    
    data_temp1 = D.data(bi:ei,:);
    data_temp2 = detrend(data_temp1,method);
    
    if sub_mean==0
        data_temp2 = data_temp2 + repmat(mean(data_temp1,1),size(data_temp1,1),1);
    end
    
    D.data(bi:ei,:) = data_temp2;
end

% For 'P'ars-struct
if exist('P','var')
    P.(mfilename) = pars;
    pars          = P;
end