function [D,pars]=normByBaseline(D,pars)
% normByBaseline - normalizes data by its baseline (within each break)
% [D, pars] = normByBaseline(D, pars)
%
% Normalizes each channel (voxel) of data by subtracting and dividing the average
% of each channel's baseline (within each break), as defined by baseConds.
%
% Inputs:
%   D.data          - 2D matrix data of any type (fMRI,MEG,...)
% Optional:
%   D.design        - design matrix of experiment ([time x dtype] format)
%   pars.base_conds - array of baseline condition numbers (default = [1])
%   pars.zero_thres - threshold below which the baseline chan is considered zero,
%                     in which case, chan is set to zero
%	pars.breaks     - [2 x N] matrix of break points for piecewise normalization;
%	                  rows: 1-begin points, 2-end points; may contain just begin or end;
%   pars.break_run  - use 'inds_runs' as 'breaks' (1, default), or not (0)
%   pars.verbose   - [1..3] print detail level 0=no printing (default: 1)
%   pars.mode       - baseline nomarlization mode
%                     0: subtraction of and division by a mean (i.e. %signal change, default)
%                     1: only division by a mean
%                     2: only subtraction of a mean
%                     3: subtraction of a mean and division by a std (i.e. z-score);
% Ouput:
%   D.data          - normlized data, same dims
%
% ----------------------------------------------------------------------------------------
% Created by members of
%     ATR Intl. Computational Neuroscience Labs, Dept. of Neuroinformatics

% Check and get pars:
if ~exist('D','var') || isempty(D),     error('Wrong args');    end
if ~exist('pars','var'),                pars = [];              end

if isfield(pars,mfilename)  % unnest, if need
    P    = pars;
    pars = P.(mfile);
end
base_conds = getFieldDef(pars,'base_conds',1);
zero_thres = getFieldDef(pars,'zero_thres',1);
breaks     = getFieldDef(pars,'breaks',[]);
break_run  = getFieldDef(pars,'break_run',1);
verbose    = getFieldDef(pars,'verbose',1);
mode       = getFieldDef(pars,'mode',0);

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

uniq_conds = unique(D.label(:,1)); % (new) edYM
inds_conds = cell(length(uniq_conds),1);
for itc=1:length(uniq_conds)
    inds_conds{itc} = find(D.label(:,1)==uniq_conds(itc))'; % (new) edYM
end

% For UI:
if verbose
    fprintf(['\n' mfilename ' ------------------------------']);
end

% Main loop:
for itb=1:num_breaks
    bi = breaks(1,itb);
    ei = breaks(2,itb);
    
    % Pull section (run) out:
    data_temp = D.data(bi:ei,:);

    % Find indexes of base condition:
    ind_use = zeros([1 length(bi:ei)]); % (new) ed SI
    for i=base_conds % (new) ed SI
        tmp_use  = ismember(bi:ei,inds_conds{i}); % (new) ed SI
        ind_use = tmp_use | ind_use; % (new) ed SI
    end % (new) ed SI
    clear i tmp_use; % (new) ed SI

    % Calc baseline:
    baseline = mean(data_temp(ind_use,:),1);
    sd = std(data_temp(ind_use,:),[],1);

    % Find baseline indexes ~= 0 (to avoid dividing by them):
    if mode == 0 || mode == 1
        zero_ind  = find(abs(baseline) <= zero_thres);    
    elseif mode == 3
        zero_ind  = find(abs(sd) <= zero_thres);        
    else
        zero_ind = [];
    end

    num_zeros = numel(zero_ind);
    if num_zeros>1      % If there are some zero values in the baseline
        error('\n ERROR: %d baselines indexes near zero (abs<%g)!',num_zeros,zero_thres);
    end

    % mean mat
    baseline_mat = repmat(baseline,size(data_temp,1),1);
    % sd mat
    sd_mat = repmat(sd,size(data_temp,1),1);

    switch mode
      case 0
        % percent-signal change
        data_temp    = 100 * (data_temp - baseline_mat) ./ baseline_mat;      
      case 1
        % division by mean only
        data_temp    = 100 * data_temp ./ baseline_mat;  
      case 2
        % subtraction of mean only
         data_temp    = data_temp - baseline_mat;   
      case 3
        % z-score
        data_temp    = (data_temp - baseline_mat) ./ sd_mat;              
    end

    % Set zero_ind data to zero:
    if num_zeros>1,      data_temp(zero_ind) = 0;     end
    
    % Put normalized section (run) back:
    D.data(bi:ei,:) = data_temp;
end

% User feedback:
fprintf('\n');

% For 'P'ars-struct
if exist('P','var')
    P.(mfilename) = pars;
    pars          = P;
end