function [result,P]=modelSwitch(D,P,models,AlgoName)
% Performs classifcation or regression listed in 'models' (in order) on
% 'data' with all parameters in 'P' (including weights) using 'labels'
% (if available); P.mode switches between train and test modes.
%
% Input:
%	D.data   - any data accepted by 'models' (below)
%	D.label  - labels matching samples of 'data'; don't use for test mode
%	P        - structure containing all parameters of 'models' as fields;
%              should be nested as P.<models> (e.g. P.ica_amh)
%	models   - array of strings of the modeling functions to be called;
%	           this may be any function listed below or any function
%	           in the user's path that conforms with this format:
%              [results, pars] = myClassifier(D, pars);
%
% Optional:
%   P.modelSwitch.mode
%            - 1: train, or 2: test; if specified, pass to all 'models'
%
% Output:
%	result   - cell array of 'results' structs returned by models, with fields:
%       .model       - names of used model
%       .pred        - predicted labels
%       .label       - defined labels
%       .dec_val     - decision values
%       .weight      - weights (and bias)
%       .freq_table  - frequency table
%       .correct_per - percent correct
%  P.<function>  - modified parameters of 'procs' and 'models'

pars=getFieldDef(P,mfilename,[]);
mode=getFieldDef(pars,'mode',[]);

% Put strings in cell array of strings
if ischar(models)
    models=cellstr(models);
end

% Loop through processing steps in models cell array
result=cell(length(models),1);
for itm=1:length(models)
    model=models{itm};
    
    if exist(model,'file')==2
        pars=getFieldDef(P,model,[]);
        if isempty(mode)==0
            pars.mode=mode;
        end
        [result{itm},pars]=slr121a(D,pars,AlgoName);
        P.(model)=pars;
    else
        fprintf('\n modelSwitch ERROR: did not find ''%s'', skipped!\n',model);
    end
end