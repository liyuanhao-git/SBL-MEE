function [D,pars]=averageBlocks(D,pars)
% averageBlocks - averages data in each block for each channel (voxel)
% [D, pars] = averageBlocks(D, pars)
%
% Input:
%	D.data             - 2D matrix of any data ([time(sample) x space(voxel/channel)] format)
%   D.label            - condition labels of each sample ([time x 1] format)
%   D.design           - design matrix of experiment ([time x dtype] format)
%   D.design_type      - name of each design type ({1 x dtype] format)
% Optional:
%	pars.begin_off     - number of samples to remove from the beginning of each block
%	pars.end_off       - number of samples to remove from the end of each block
%   pars.target_labels - labels with which data samples are only averaged 
%	pars.verbose       - [1..3] = print detail level; 0 = no printing (default=1)
% Output:
%	D.data             - block averaged data
%   D.label            - labels for each averaged data
%   D.design           - design matrix of averaged samples
%
% Key:
%	nChans = # Channels, signals; voxels for fMRI; sensors for EEG; ~ space, patterns
%	nSamps = # Samples; nTRs, nVols, nTrials for fMRI (not MEG); ~ time
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
begin_off     = getFieldDef(pars,'begin_off',0);
end_off       = getFieldDef(pars,'end_off',0);
target_labels = getFieldDef(pars,'target_labels',unique(D.label(:,1))); % (new) edYM
verbose       = getFieldDef(pars,'verbose',1);

% make inds:
% block:
ind = find(strcmpi(D.design_type,'block'));
if isempty(ind)
    error('''block'' isn''t found in ''D.design_type''');
end
inds_blocks(2,:) = [find(diff(D.design(:,ind)))' size(D.design,1)];
inds_blocks(1,:) = [1 inds_blocks(2,1:end-1)+1];
num_blocks       = size(inds_blocks,2);
% run:
ind = find(strcmpi(D.design_type,'run'));
if ~isempty(ind)
    inds_runs(2,:) = [find(diff(D.design(:,ind)))' size(D.design,1)];
    inds_runs(1,:) = [1 inds_runs(2,1:end-1)+1];
end


% For UI:
if verbose
    fprintf(['\n' mfilename ' ------------------------------']);
    if verbose>=2
        fprintf('\n # blocks: \t%d',num_blocks);
        fprintf('\n begin_off:\t%d',begin_off);
        fprintf('\n end_off:  \t%d',end_off);
        fprintf('\n target_labels:  \t%d',target_labels);
    end
    fprintf('\n');
end

% Calculate average:
data_temp     = cell(num_blocks,1);
target_blocks = false(1,num_blocks);
for itb=1:num_blocks
    tmp = D.label(inds_blocks(1,itb):inds_blocks(2,itb),1); % edYM
    tmp = unique(tmp);
    if numel(tmp) ~= 1
        error('mutiple labels are contained in a single block');
    end
    
    if ismember(tmp,target_labels)
        target_blocks(itb) = 1;

        bi = inds_blocks(1,itb) + begin_off;
        ei = inds_blocks(2,itb) - end_off;
    
        if bi>ei
            if exist('inds_runs','var') && ismember(inds_blocks(2,itb),inds_runs(2,:))
                % last block of each run, this error may be caused by 'shiftData'
                fprintf('\nWarning: End-point of block averaging is smaller than begin-point\n Use only begin-point\n');
                ei = bi;
            else
                error('begin/end_off is too many to keep samples of block averaging');
            end
        end
    
        data_temp{itb} = mean(D.data(bi:ei,:),1);
    else
        data_temp{itb} = D.data(inds_blocks(1,itb):inds_blocks(2,itb),:);
    end
    clear tmp;
end

D.data = cell2mat(data_temp);

% Make use_vol_inds:
vol_inds = cell(1,num_blocks);
for itb=1:num_blocks
    if target_blocks(itb)
        vol_inds{itb} = inds_blocks(1,itb);
    else
        vol_inds{itb} = inds_blocks(1,itb):inds_blocks(2,itb);
    end
end
vol_inds = cell2mat(vol_inds);

% Make labels:
D.label = D.label(vol_inds,:); % (new) edYM

% Make design:
D.design = D.design(vol_inds,:);

% For 'P'ars-struct
if exist('P','var')
    P.(mfilename) = pars;
    pars          = P;
end