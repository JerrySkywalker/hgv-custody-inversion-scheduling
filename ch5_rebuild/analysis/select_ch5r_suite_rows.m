function [Tout, info] = select_ch5r_suite_rows(T, sel)
%SELECT_CH5R_SUITE_ROWS
% Filter suite raw table after full run.
%
% Supported selector fields:
%   methods               : {'R4','R9',...}
%   families              : {'nominal','heading',...}
%   case_ids              : {'N01','H04_+30',...}
%   actual_case_ids       : {...}
%   requested_case_ids    : {...}
%   base_nominal_cases    : {'N01','N04',...}
%   heading_offset_deg    : [0, 30, -30]
%   include_in_smoke      : true/false
%   include_in_paper      : true/false
%   exclude_case_ids      : {...}

if nargin < 2 || isempty(sel)
    sel = struct();
end

assert(istable(T), 'Input must be a table.');
T = ch5r_attach_case_metadata(T);

mask = true(height(T), 1);

if isfield(sel, 'methods') && ~isempty(sel.methods)
    mask = mask & ismember(string(T.method), string(sel.methods));
end

if isfield(sel, 'families') && ~isempty(sel.families)
    fam_col = local_pick_column(T, {'reg_family','family'});
    mask = mask & ismember(string(T.(fam_col)), string(sel.families));
end

if isfield(sel, 'case_ids') && ~isempty(sel.case_ids)
    cmask = false(height(T),1);
    for col = {'actual_case_id','requested_case_id','reg_case_id'}
        c = col{1};
        if ismember(c, T.Properties.VariableNames)
            cmask = cmask | ismember(string(T.(c)), string(sel.case_ids));
        end
    end
    mask = mask & cmask;
end

if isfield(sel, 'actual_case_ids') && ~isempty(sel.actual_case_ids) ...
        && ismember('actual_case_id', T.Properties.VariableNames)
    mask = mask & ismember(string(T.actual_case_id), string(sel.actual_case_ids));
end

if isfield(sel, 'requested_case_ids') && ~isempty(sel.requested_case_ids) ...
        && ismember('requested_case_id', T.Properties.VariableNames)
    mask = mask & ismember(string(T.requested_case_id), string(sel.requested_case_ids));
end

if isfield(sel, 'exclude_case_ids') && ~isempty(sel.exclude_case_ids)
    emask = false(height(T),1);
    for col = {'actual_case_id','requested_case_id','reg_case_id'}
        c = col{1};
        if ismember(c, T.Properties.VariableNames)
            emask = emask | ismember(string(T.(c)), string(sel.exclude_case_ids));
        end
    end
    mask = mask & ~emask;
end

if isfield(sel, 'base_nominal_cases') && ~isempty(sel.base_nominal_cases) ...
        && ismember('reg_base_nominal_case', T.Properties.VariableNames)
    mask = mask & ismember(string(T.reg_base_nominal_case), string(sel.base_nominal_cases));
end

if isfield(sel, 'heading_offset_deg') && ~isempty(sel.heading_offset_deg) ...
        && ismember('reg_heading_offset_deg', T.Properties.VariableNames)
    mask = mask & local_numeric_member(T.reg_heading_offset_deg, sel.heading_offset_deg, 1e-9);
end

if isfield(sel, 'include_in_smoke') && ~isempty(sel.include_in_smoke) ...
        && ismember('reg_include_in_smoke', T.Properties.VariableNames)
    mask = mask & (logical(T.reg_include_in_smoke) == logical(sel.include_in_smoke));
end

if isfield(sel, 'include_in_paper') && ~isempty(sel.include_in_paper) ...
        && ismember('reg_include_in_paper', T.Properties.VariableNames)
    mask = mask & (logical(T.reg_include_in_paper) == logical(sel.include_in_paper));
end

Tout = T(mask, :);

info = struct();
info.n_input_rows = height(T);
info.n_output_rows = height(Tout);
info.n_removed_rows = height(T) - height(Tout);
info.selection = sel;

case_col = local_pick_column(Tout, {'actual_case_id','requested_case_id','reg_case_id'});
fam_col = local_pick_column(Tout, {'reg_family','family'});

if ~isempty(case_col) && height(Tout) > 0
    info.case_ids = cellstr(unique(string(Tout.(case_col)), 'stable'));
else
    info.case_ids = {};
end

if ~isempty(fam_col) && height(Tout) > 0
    info.families = cellstr(unique(string(Tout.(fam_col)), 'stable'));
else
    info.families = {};
end

if height(Tout) > 0
    info.methods = cellstr(unique(string(Tout.method), 'stable'));
else
    info.methods = {};
end
end

function tf = local_numeric_member(x, vals, tol)
x = double(x(:));
vals = double(vals(:));
tf = false(size(x));
for i = 1:numel(vals)
    tf = tf | (abs(x - vals(i)) <= tol);
end
end

function col = local_pick_column(T, cands)
col = '';
for i = 1:numel(cands)
    if ismember(cands{i}, T.Properties.VariableNames)
        col = cands{i};
        return;
    end
end
end
