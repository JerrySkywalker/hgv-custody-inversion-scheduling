function sol = select_static_plus_solution(stage05_info, theta_star, cfg)
%SELECT_STATIC_PLUS_SOLUTION  Select a lightly redundant theta_plus.

if nargin < 3 || isempty(cfg)
    cfg = default_params();
end

T = table();
if isfield(stage05_info, 'feasible_table') && istable(stage05_info.feasible_table)
    T = stage05_info.feasible_table;
end

if isempty(T)
    sol = theta_star;
    sol.source = 'fallback_to_theta_star_no_stage05_table';
    return;
end

T2 = local_normalize_table(T, cfg);
if isempty(T2)
    sol = theta_star;
    sol.source = 'fallback_to_theta_star_empty_normalize';
    return;
end

mask = T2.Ns > theta_star.Ns;
T3 = T2(mask, :);

if isempty(T3)
    sol = theta_star;
    sol.source = 'fallback_to_theta_star_no_redundant_solution';
    return;
end

[~, idx] = sortrows([T3.Ns, -T3.DG, -T3.pass_ratio], [1 2 3]);
row = T3(idx(1), :);

sol = struct();
sol.source = 'stage05_redundant_feasible_table';
sol.h_km = double(row.h_km(1));
sol.i_deg = double(row.i_deg(1));
sol.P = double(row.P(1));
sol.T = double(row.T(1));
sol.F = double(row.F(1));
sol.Ns = double(row.Ns(1));
sol.DG = double(row.DG(1));
sol.pass_ratio = double(row.pass_ratio(1));
sol.case_id = local_pick_case_id(row, cfg);
end

function T2 = local_normalize_table(T, cfg)
T2 = table();

P = local_pick_numeric_column(T, {'P', 'num_planes'});
Ts = local_pick_numeric_column(T, {'T', 'sats_per_plane'});
i_deg = local_pick_numeric_column(T, {'i_deg', 'inclination_deg'});
h_km = local_pick_numeric_column(T, {'h_km', 'altitude_km'});
F = local_pick_numeric_column(T, {'F', 'phase_factor'});
DG = local_pick_numeric_column(T, {'D_G_min', 'best_DG_median', 'DG', 'D_G'});
pass_ratio = local_pick_numeric_column(T, {'pass_ratio', 'feasible_ratio'});

n = local_common_length({P, Ts, i_deg, h_km, F, DG, pass_ratio});
if n == 0
    return;
end

T2.P = int32(P(1:n));
T2.T = int32(Ts(1:n));
T2.i_deg = i_deg(1:n);
T2.h_km = h_km(1:n);
T2.F = int32(F(1:n));
T2.DG = DG(1:n);
T2.pass_ratio = pass_ratio(1:n);
T2.Ns = double(T2.P) .* double(T2.T);

if ismember('case_id', T.Properties.VariableNames)
    T2.case_id = T.case_id(1:n);
else
    T2.case_id = repmat({cfg.ch5r.bootstrap.default_case_id}, n, 1);
end
end

function v = local_pick_numeric_column(T, names)
v = [];
for i = 1:numel(names)
    name = names{i};
    if ismember(name, T.Properties.VariableNames)
        raw = T.(name);
        if isnumeric(raw)
            v = double(raw(:));
            return;
        end
    end
end
end

function n = local_common_length(arr)
lens = zeros(1, numel(arr));
for i = 1:numel(arr)
    if isempty(arr{i})
        n = 0;
        return;
    end
    lens(i) = numel(arr{i});
end
n = min(lens);
end

function case_id = local_pick_case_id(row, cfg)
case_id = cfg.ch5r.bootstrap.default_case_id;
if ismember('case_id', row.Properties.VariableNames)
    val = row.case_id(1);
    if iscell(val)
        case_id = val{1};
    else
        case_id = char(string(val));
    end
end
end
