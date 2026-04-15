function tag = ch5r_make_artifact_tag(ch5case, stamp, extra_tokens)
%CH5R_MAKE_ARTIFACT_TAG
% Build a stable file tag carrying case / family / constellation / window info.
%
% Example:
%   case-N01_family-nominal_Ns-96_w-60_mode-centered-full-only_theta-star_20260415_213001

if nargin < 2 || isempty(stamp)
    stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
end
if nargin < 3
    extra_tokens = {};
end

if ischar(extra_tokens) || isstring(extra_tokens)
    extra_tokens = cellstr(string(extra_tokens));
elseif ~iscell(extra_tokens)
    error('extra_tokens must be char/string/cell.');
end

case_id = local_get_field(ch5case, {'target_case','case_id'}, 'unknown_case');
family  = local_get_field(ch5case, {'target_case','family'},  'unknown_family');
Ns      = local_get_field(ch5case, {'theta','Ns'}, NaN);
wlen    = local_get_field(ch5case, {'window','length_s'}, NaN);
wmode   = local_get_field(ch5case, {'window','mode'}, 'unknown_mode');

tokens = { ...
    ['case-'   local_clean(case_id)], ...
    ['family-' local_clean(family)], ...
    ['Ns-'     local_clean(local_num2str(Ns))], ...
    ['w-'      local_clean(local_num2str(wlen))], ...
    ['mode-'   local_clean(wmode)]};

for i = 1:numel(extra_tokens)
    tokens{end+1} = local_clean(extra_tokens{i}); %#ok<AGROW>
end

tokens{end+1} = stamp;
tag = strjoin(tokens, '_');
end

function v = local_get_field(S, path_cells, default_value)
v = default_value;
try
    cur = S;
    for i = 1:numel(path_cells)
        key = path_cells{i};
        if isstruct(cur) && isfield(cur, key)
            cur = cur.(key);
        else
            return;
        end
    end
    v = cur;
catch
    v = default_value;
end
end

function s = local_num2str(x)
if isnumeric(x)
    if isscalar(x) && isfinite(x)
        s = num2str(x);
    else
        s = 'nan';
    end
else
    s = char(string(x));
end
end

function s = local_clean(x)
s = char(string(x));
s = strtrim(s);
s = regexprep(s, '[^A-Za-z0-9_\-]+', '-');
s = regexprep(s, '-+', '-');
s = regexprep(s, '_+', '_');
s = regexprep(s, '(^[-_]+|[-_]+$)', '');
if isempty(s)
    s = 'na';
end
end
