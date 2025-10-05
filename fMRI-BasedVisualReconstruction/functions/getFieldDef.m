function out=getFieldDef(S,field,default)
% getFieldDef - returns either S.<field> or default
% out = getFieldDef(S, field, default)

% Check and get pars:
if ~exist('default','var') || isempty(default)
    default=[];
end

if ~exist('S','var') || isempty(S) || ~exist('field','var') || isempty(field)
    out=default;
    return;
end

% Return value:
out=default;
if isfield(S,field)
    out=S.(field);
end