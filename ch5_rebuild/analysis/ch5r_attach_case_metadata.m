function T = ch5r_attach_case_metadata(T)
%CH5R_ATTACH_CASE_METADATA
% Attach registry metadata to suite raw table.
%
% Added columns:
%   reg_case_id
%   reg_family
%   reg_include_in_smoke
%   reg_include_in_paper
%   reg_base_nominal_case
%   reg_heading_offset_deg

assert(istable(T), 'Input must be a table.');

existing_needed = {'reg_case_id','reg_family','reg_include_in_smoke', ...
    'reg_include_in_paper','reg_base_nominal_case','reg_heading_offset_deg'};
if all(ismember(existing_needed, T.Properties.VariableNames))
    return;
end

registry = build_ch5r_case_registry();
R_case_id = string(registry.case_id);
R_family  = string(registry.family);
R_smoke   = logical(registry.include_in_smoke);
R_paper   = logical(registry.include_in_paper);
R_base    = string(registry.base_nominal_case);
R_head    = registry.heading_offset_deg;

map = containers.Map('KeyType', 'char', 'ValueType', 'double');
for i = 1:numel(R_case_id)
    map(char(R_case_id(i))) = i;
end

key_col = local_pick_key_column(T);
assert(~isempty(key_col), 'Cannot find case key column in suite table.');

n = height(T);
reg_case_id = repmat("", n, 1);
reg_family = repmat("", n, 1);
reg_include_in_smoke = false(n, 1);
reg_include_in_paper = false(n, 1);
reg_base_nominal_case = repmat("", n, 1);
reg_heading_offset_deg = nan(n, 1);

keys = string(T.(key_col));

for i = 1:n
    key = char(keys(i));
    if isKey(map, key)
        k = map(key);
        reg_case_id(i) = R_case_id(k);
        reg_family(i) = R_family(k);
        reg_include_in_smoke(i) = R_smoke(k);
        reg_include_in_paper(i) = R_paper(k);
        reg_base_nominal_case(i) = R_base(k);
        reg_heading_offset_deg(i) = R_head(k);
    end
end

T.reg_case_id = reg_case_id;
T.reg_family = reg_family;
T.reg_include_in_smoke = reg_include_in_smoke;
T.reg_include_in_paper = reg_include_in_paper;
T.reg_base_nominal_case = reg_base_nominal_case;
T.reg_heading_offset_deg = reg_heading_offset_deg;
end

function key_col = local_pick_key_column(T)
key_col = '';
cands = {'actual_case_id','requested_case_id'};
for i = 1:numel(cands)
    if ismember(cands{i}, T.Properties.VariableNames)
        key_col = cands{i};
        return;
    end
end
end
