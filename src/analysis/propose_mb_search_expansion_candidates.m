function candidates = propose_mb_search_expansion_candidates(profile, phasecurve_table, options)
%PROPOSE_MB_SEARCH_EXPANSION_CANDIDATES Propose finite auto-tune candidate domains for MB pass-ratio plots.

if nargin < 1 || isempty(profile)
    profile = get_mb_search_profile('mb_default');
end
if nargin < 2 || isempty(phasecurve_table)
    phasecurve_table = table();
end
if nargin < 3 || isempty(options)
    options = struct();
end

auto_tune = local_getfield_or(options, 'auto_tune', local_getfield_or(profile, 'auto_tune', struct()));
current_xlim = local_resolve_plot_xlim(local_getfield_or(profile, 'plot_xlim_ns', []), phasecurve_table);
[transition_low, transition_high, first_nonzero, last_zero, ns_min, ns_max] = local_transition_stats(phasecurve_table, current_xlim);

current = local_make_candidate("current_domain", profile, current_xlim, false, ...
    "Keep the current search and plotting domain.");

candidates = current;

if isfinite(first_nonzero) && first_nonzero > ns_min
    trim_left = max(ns_min, first_nonzero - local_ns_step(phasecurve_table));
    xlim_trim = [trim_left, current_xlim(2)];
    candidates(end + 1) = local_make_candidate("trim_left_xlim", profile, xlim_trim, false, ...
        "Trim excessive all-zero region on the left side of the pass-ratio curve.");
end

if isfinite(transition_low) && isfinite(transition_high)
    pad = max(local_ns_step(phasecurve_table), round(0.15 * max(transition_high - transition_low, 1)));
    xlim_focus = [max(ns_min, transition_low - pad), min(max(ns_max, current_xlim(2)), transition_high + pad)];
    candidates(end + 1) = local_make_candidate("focus_transition_xlim", profile, xlim_focus, false, ...
        "Center the main transition band inside the plotting window.");
end

expand_step_P = local_getfield_or(auto_tune, 'expand_step_P', 2);
expand_step_T = local_getfield_or(auto_tune, 'expand_step_T', 4);
max_P = local_getfield_or(auto_tune, 'max_P', max(profile.P_grid));
max_T = local_getfield_or(auto_tune, 'max_T', max(profile.T_grid));

expanded_P = local_expand_grid(profile.P_grid, expand_step_P, max_P);
expanded_T = local_expand_grid(profile.T_grid, expand_step_T, max_T);

if ~isequal(expanded_P, reshape(profile.P_grid, 1, []))
    cand = current;
    cand.name = "expand_P";
    cand.P_grid = expanded_P;
    cand.requires_search_expansion = true;
    cand.reason = "Expand Walker plane-count search to reveal later transition points.";
    candidates(end + 1) = cand;
end

if ~isequal(expanded_T, reshape(profile.T_grid, 1, []))
    cand = current;
    cand.name = "expand_T";
    cand.T_grid = expanded_T;
    cand.requires_search_expansion = true;
    cand.reason = "Expand Walker slot-count search to reveal later transition points.";
    candidates(end + 1) = cand;
end

if ~isequal(expanded_P, reshape(profile.P_grid, 1, [])) || ~isequal(expanded_T, reshape(profile.T_grid, 1, []))
    cand = current;
    cand.name = "expand_PT";
    cand.P_grid = expanded_P;
    cand.T_grid = expanded_T;
    cand.requires_search_expansion = true;
    cand.reason = "Jointly expand P/T search to bracket the full pass-ratio transition.";
    candidates(end + 1) = cand;
end

if isfinite(last_zero) && isfinite(transition_high)
    target_center = local_getfield_or(auto_tune, 'target_transition_center', 0.50);
    span = max(transition_high - last_zero, local_ns_step(phasecurve_table));
    half_width = max(span / 2, local_ns_step(phasecurve_table));
    x_center = last_zero + span / 2;
    total_width = max(round(half_width / max(target_center, eps) * 2), span + local_ns_step(phasecurve_table));
    xlim_centered = [max(ns_min, round(x_center - total_width / 2)), round(x_center + total_width / 2)];
    candidates(end + 1) = local_make_candidate("center_transition_xlim", profile, xlim_centered, false, ...
        "Recenter the plotting window so the transition sits near the middle of the figure.");
end

max_candidate_count = local_getfield_or(auto_tune, 'max_candidate_count', numel(candidates));
keep_count = min(numel(candidates), max_candidate_count);
candidates = candidates(1:keep_count);
end

function candidate = local_make_candidate(name, profile, plot_xlim_ns, requires_search_expansion, reason)
candidate = struct();
candidate.name = string(name);
candidate.semantic_mode = string(local_getfield_or(profile, 'semantic_mode', "comparison"));
candidate.sensor_group_names = cellstr(string(local_getfield_or(profile, 'sensor_group_names', {'baseline'})));
candidate.height_grid_km = reshape(local_getfield_or(profile, 'height_grid_km', 1000), 1, []);
candidate.inclination_grid_deg = reshape(local_getfield_or(profile, 'inclination_grid_deg', []), 1, []);
candidate.P_grid = reshape(local_getfield_or(profile, 'P_grid', []), 1, []);
candidate.T_grid = reshape(local_getfield_or(profile, 'T_grid', []), 1, []);
candidate.plot_xlim_ns = reshape(plot_xlim_ns, 1, []);
candidate.requires_search_expansion = logical(requires_search_expansion);
candidate.reason = string(reason);
end

function [transition_low, transition_high, first_nonzero, last_zero, ns_min, ns_max] = local_transition_stats(phasecurve_table, current_xlim)
transition_low = NaN;
transition_high = NaN;
first_nonzero = NaN;
last_zero = NaN;
ns_min = NaN;
ns_max = NaN;

if isempty(phasecurve_table) || ~ismember('Ns', phasecurve_table.Properties.VariableNames)
    return;
end

[Ns, best_pass] = local_build_envelope(phasecurve_table);
if isempty(Ns)
    return;
end
ns_min = min(Ns);
ns_max = max(Ns);
mask = Ns >= current_xlim(1) & Ns <= current_xlim(2);
Ns = Ns(mask);
best_pass = best_pass(mask);
if isempty(Ns)
    return;
end

zero_tol = 0.02;
one_tol = 0.98;
idx_nonzero = find(best_pass > zero_tol, 1, 'first');
idx_zero = find(best_pass <= zero_tol, 1, 'last');
idx_one = find(best_pass >= one_tol, 1, 'first');

if ~isempty(idx_nonzero)
    first_nonzero = Ns(idx_nonzero);
    transition_low = first_nonzero;
end
if ~isempty(idx_zero)
    last_zero = Ns(idx_zero);
end
if ~isempty(idx_one)
    transition_high = Ns(idx_one);
elseif ~isempty(Ns)
    transition_high = Ns(end);
end
if isnan(transition_low) && isfinite(last_zero)
    transition_low = last_zero;
end
end

function [Ns, best_pass] = local_build_envelope(phasecurve_table)
Ns = unique(phasecurve_table.Ns(:), 'sorted');
best_pass = zeros(numel(Ns), 1);
for idx = 1:numel(Ns)
    mask = phasecurve_table.Ns == Ns(idx);
    best_pass(idx) = max(phasecurve_table.max_pass_ratio(mask));
end
end

function xlim_ns = local_resolve_plot_xlim(plot_xlim_ns, phasecurve_table)
if nargin >= 1 && numel(plot_xlim_ns) == 2 && all(isfinite(plot_xlim_ns))
    xlim_ns = reshape(plot_xlim_ns, 1, []);
    return;
end

if isempty(phasecurve_table) || ~ismember('Ns', phasecurve_table.Properties.VariableNames) || isempty(phasecurve_table)
    xlim_ns = [0, 1];
    return;
end

Ns = unique(phasecurve_table.Ns(:), 'sorted');
xlim_ns = [min(Ns), max(Ns)];
end

function grid_out = local_expand_grid(grid_in, step_size, max_value)
grid_out = reshape(grid_in, 1, []);
if isempty(grid_out) || grid_out(end) >= max_value
    return;
end
next_value = min(max_value, grid_out(end) + step_size);
if next_value > grid_out(end)
    grid_out = unique([grid_out, next_value], 'stable');
end
end

function step = local_ns_step(phasecurve_table)
step = 4;
if isempty(phasecurve_table) || ~ismember('Ns', phasecurve_table.Properties.VariableNames)
    return;
end
Ns = unique(phasecurve_table.Ns(:), 'sorted');
if numel(Ns) >= 2
    step = max(1, min(diff(Ns)));
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
