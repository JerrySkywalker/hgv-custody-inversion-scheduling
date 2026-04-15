function out = resolve_ch5r_case_list(opts)
%RESOLVE_CH5R_CASE_LIST
% Resolve Chapter 5 case list from:
% - preset case_set = smoke / paper / full
% - family filter
% - explicit case_ids
%
% Output:
%   out.case_ids  : cellstr
%   out.registry  : filtered registry table
%   out.meta      : summary metadata

if nargin < 1 || isempty(opts)
    opts = struct();
end

suite = default_ch5r_suite_params();
registry = build_ch5r_case_registry();

if ~isfield(opts, 'case_set') || isempty(opts.case_set)
    opts.case_set = 'smoke';
end
if ~isfield(opts, 'family') || isempty(opts.family)
    opts.family = '';
end
if ~isfield(opts, 'case_ids') || isempty(opts.case_ids)
    opts.case_ids = {};
end

mask = true(height(registry),1);

% --------------------------------
% preset case_set
% --------------------------------
case_set_name = lower(string(opts.case_set));
switch case_set_name
    case "smoke"
        mask = mask & registry.include_in_smoke;
    case "paper"
        mask = mask & registry.include_in_paper;
    case "full"
        % no-op
    otherwise
        error('[ch5r:case-list] Unsupported case_set: %s', char(case_set_name));
end

% --------------------------------
% family filter
% --------------------------------
if ~isempty(opts.family)
    family_name = lower(string(opts.family));
    mask = mask & strcmpi(registry.family, family_name);
end

% --------------------------------
% explicit case_ids filter
% --------------------------------
if ~isempty(opts.case_ids)
    user_case_ids = cellstr(opts.case_ids);
    mask = mask & ismember(registry.case_id, user_case_ids);
end

reg2 = registry(mask,:);

out = struct();
out.case_ids = reg2.case_id(:)';
out.registry = reg2;
out.meta = struct();
out.meta.case_set = char(case_set_name);
out.meta.family = char(string(opts.family));
out.meta.n_cases = numel(out.case_ids);

disp(' ')
disp('=== [ch5r:case-list] resolve summary ===')
disp(['case_set : ' out.meta.case_set])
disp(['family   : ' out.meta.family])
disp(['n_cases  : ' num2str(out.meta.n_cases)])
disp(reg2(:, {'case_id','family','include_in_smoke','include_in_paper'}))
end
