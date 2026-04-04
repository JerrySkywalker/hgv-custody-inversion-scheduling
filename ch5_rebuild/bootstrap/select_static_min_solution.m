function sol = select_static_min_solution(stage05_info, cfg)
%SELECT_STATIC_MIN_SOLUTION  Select theta_star from Stage05 feasible results.

if nargin < 2 || isempty(cfg)
    cfg = default_params();
end

T = table();
if isfield(stage05_info, 'feasible_table') && istable(stage05_info.feasible_table)
    T = stage05_info.feasible_table;
end

if isempty(T)
    sol = local_default_solution(cfg, 'default_stage05');
    return;
end

T2 = local_normalize_table(T, cfg);
if isempty(T2)
    sol = local_default_solution(cfg, 'default_stage05_after_empty_normalize');
    return;
end

[~, idx] = sortrows([T2.Ns, -T2.DG, -T2.pass_ratio], [1 2 3]);
row = T2(idx(1), :);

sol = local_row_to_solution(row, 'stage05_feasible_table');
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

function sol = local_default_solution(cfg, source_name)
sol = struct();
sol.source = source_name;
sol.h_km = cfg.stage05.h_fixed_km;
sol.i_deg = cfg.stage05.i_grid_deg(1);
sol.P = cfg.stage05.P_grid(1);
sol.T = cfg.stage05.T_grid(1);
sol.F = cfg.stage05.F_fixed;
sol.Ns = sol.P * sol.T;
sol.DG = NaN;
sol.pass_ratio = NaN;
sol.case_id = cfg.ch5r.bootstrap.default_case_id;
end

function sol = local_row_to_solution(row, source_name)
sol = struct();
sol.source = source_name;
sol.h_km = double(row.h_km(1));
sol.i_deg = double(row.i_deg(1));
sol.P = double(row.P(1));
sol.T = double(row.T(1));
sol.F = double(row.F(1));
sol.Ns = double(row.Ns(1));
sol.DG = double(row.DG(1));
sol.pass_ratio = double(row.pass_ratio(1));
if ismember('case_id', row.Properties.VariableNames)
    val = row.case_id(1);
    if iscell(val)
        sol.case_id = val{1};
    else
        sol.case_id = char(string(val));
    end
else
    sol.case_id = 'N01';
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
