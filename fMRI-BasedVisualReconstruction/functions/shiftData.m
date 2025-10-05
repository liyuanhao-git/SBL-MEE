function [D,pars]=shiftData(D,pars)
% [D, pars] = shiftData(D, pars)
%
% Delete first 'shift' points of D.data and last 'shift' points of D.labesl in each run.
%
% Input:
%   D.data        - 2D matrix of any data ([time(sample) x space(voxel/channel)] format)
% Optional:
%   pars.shift    - number to shift data: should be positive
%   		        (relative to labels)
%   pars.verbose  - [1..3] = print detail level; 0 = no printing (default=1)
% Output:
%   D.data        - shifted data
%   D.label       - labels of shifted sample
%   D.design      - design matrix of shifted sample

% Check and get pars:
if ~exist('D','var') || isempty(D)
    error('''D''ata-struct must be specified');
end
if ~exist('pars','var'),	pars = [];      end

if isfield(pars,mfilename)      % unnest, if needed
    P    = pars;
    pars = P.(mfilename);
end

if ~isfield(pars,'shift')
    error('ERROR: shift value is not specified.');
else
    shift   = getFieldDef(pars,'shift',0);
end
if shift<0
    error('pars.shift should be positive!'); %% YM100410
end

verbose = getFieldDef(pars,'verbose',1);

% For UI:
if verbose
    fprintf(['\n' mfilename ' ------------------------------']);
    fprintf('\n Shifting data forwards by %d samples (normal for fMRI data)\n', shift);
end

% Make inds:
% run:
ind = find(strcmpi(D.design_type,'run'));
if isempty(ind),	ind = 1;    end
inds_runs(2,:) = [find(diff(D.design(:,ind)))' size(D.design,1)];
inds_runs(1,:) = [1 inds_runs(2,1:end-1)+1];

% block:
ind = find(strcmpi(D.design_type,'block'));
if isempty(ind),    ind = 2;    end
inds_blocks(2,:) = [find(diff(D.design(:,ind)))' size(D.design,1)];
inds_blocks(1,:) = [1 inds_blocks(2,1:end-1)+1];

% Shift data:
num_runs        = size(inds_runs,2);
inds_del_data   = zeros(num_runs*shift,1);
inds_del_labels = zeros(num_runs*shift,1);
if isfield(D,'inds_trial')
    D.inds_trial2 = [];
end
for itr=1:num_runs
    bi = inds_runs(1,itr);
    ei = inds_runs(2,itr);
    
    inds_del_data(shift*(itr-1)+1:shift*itr)   = bi:bi+shift-1; %YF
    inds_del_labels(shift*(itr-1)+1:shift*itr) = ei-shift+1:ei; %YF
    
    ind_blocks_in                     = find(inds_blocks(1,:)>=bi & inds_blocks(1,:)<ei);
    inds_blocks(:,ind_blocks_in)      = inds_blocks(:,ind_blocks_in) - (itr-1)*shift;
    inds_blocks(2,ind_blocks_in(end)) = inds_blocks(2,ind_blocks_in(end)) - shift;


    if isfield(D,'inds_trial')
        D.inds_trial{itr} = D.inds_trial{itr} - (itr-1)*shift;
        D.inds_trial{itr}(2,end) = D.inds_trial{itr}(2,end) - shift;
        D.inds_trial2 = [D.inds_trial2 D.inds_trial{itr}];        
    end
    
    inds_runs(1,itr) = bi - (itr-1)*shift;
    inds_runs(2,itr) = ei - itr*shift;
end

D.data(inds_del_data,:)     = [];
D.label(inds_del_labels,:)  = [];
D.design(inds_del_labels,:) = [];

% For 'P'ars-struct
if exist('P','var')
    P.(mfilename) = pars;
    pars          = P;
end