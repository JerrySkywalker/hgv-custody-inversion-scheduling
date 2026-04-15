function out = resolve_ch5r_case_list(opts)
%RESOLVE_CH5R_CASE_LIST
% Resolve Chapter 5 case list from:
% - preset case_set = smoke / paper / full
% - family filter
% - explicit case_ids
%
% Output:
%   out.case_ids  : cellstr row vector
%   out.registry  : filtered registry table
%   out.meta      : summary metadata
%
% Design note:
% This file intentionally avoids ALL local helper subfunctions.
% A previous version used file-local helper functions such as
% local_is_missing(...), which behaved inconsistently when the resolver
% was re-entered from another function context in MATLAB. This flat version
% is more verbose but much more robust.

if nargin < 1 || builtin('isempty', opts)
    opts = struct();
end

suite = default_ch5r_suite_params();
registry = build_ch5r_case_registry();

% --------------------------------
% normalize case_set
% --------------------------------
if ~isfield(opts, 'case_set')
    case_set_name = 'smoke';
else
    tmp = opts.case_set;
    if isstring(tmp)
        if builtin('isempty', tmp) || all(strlength(tmp) == 0)
            case_set_name = 'smoke';
        else
            case_set_name = lower(char(tmp(1)));
        end
    elseif ischar(tmp)
        if builtin('isempty', tmp)
            case_set_name = 'smoke';
        else
            case_set_name = lower(tmp);
        end
    else
        if builtin('isempty', tmp)
            case_set_name = 'smoke';
        else
            case_set_name = lower(char(string(tmp)));
        end
    end
end

% --------------------------------
% normalize family
% --------------------------------
if ~isfield(opts, 'family')
    family_name = '';
else
    tmp = opts.family;
    if isstring(tmp)
        if builtin('isempty', tmp) || all(strlength(tmp) == 0)
            family_name = '';
        else
            family_name = lower(char(tmp(1)));
        end
    elseif ischar(tmp)
        if builtin('isempty', tmp)
            family_name = '';
        else
            family_name = lower(tmp);
        end
    else
        if builtin('isempty', tmp)
            family_name = '';
        else
            family_name = lower(char(string(tmp)));
        end
    end
end

% --------------------------------
% normalize explicit case_ids
% --------------------------------
user_case_ids = {};

if isfield(opts, 'case_ids')
    tmp = opts.case_ids;

    if ~(builtin('isempty', tmp))
        % unwrap one level of nested cell, e.g. {{'N01','H04_+30'}}
        if iscell(tmp) && numel(tmp) == 1 && iscell(tmp{1})
            tmp = tmp{1};
        end

        if isstring(tmp)
            user_case_ids = cellstr(tmp(:)).';
        elseif ischar(tmp)
            user_case_ids = {tmp};
        elseif iscell(tmp)
            user_case_ids = cell(size(tmp));
            for i = 1:numel(tmp)
                user_case_ids{i} = char(string(tmp{i}));
            end
        else
            error('[ch5r:case-list] Unsupported case_ids type: %s', class(tmp));
        end

        % strip empty items
        keep = true(size(user_case_ids));
        for i = 1:numel(user_case_ids)
            keep(i) = ~(builtin('isempty', user_case_ids{i}));
        end
        user_case_ids = user_case_ids(keep);
    end
end

mask = true(height(registry), 1);

% --------------------------------
% preset case_set
% --------------------------------
switch case_set_name
    case 'smoke'
        mask = mask & registry.include_in_smoke;
    case 'paper'
        mask = mask & registry.include_in_paper;
    case 'full'
        % no-op
    otherwise
        error('[ch5r:case-list] Unsupported case_set: %s', case_set_name);
end

% --------------------------------
% family filter
% --------------------------------
if ~(builtin('isempty', family_name))
    mask = mask & strcmpi(registry.family, family_name);
end

% --------------------------------
% explicit case_ids filter
% --------------------------------
if ~(builtin('isempty', user_case_ids))
    mask = mask & ismember(registry.case_id, user_case_ids);
end

reg2 = registry(mask, :);

out = struct();
out.case_ids = reshape(reg2.case_id, 1, []);
out.registry = reg2;
out.meta = struct();
out.meta.case_set = case_set_name;
out.meta.family = family_name;
out.meta.n_cases = numel(out.case_ids);

disp(' ')
disp('=== [ch5r:case-list] resolve summary ===')
disp(['case_set : ' out.meta.case_set])
disp(['family   : ' out.meta.family])
disp(['n_cases  : ' num2str(out.meta.n_cases)])
disp(reg2(:, {'case_id','family','include_in_smoke','include_in_paper'}))
end
