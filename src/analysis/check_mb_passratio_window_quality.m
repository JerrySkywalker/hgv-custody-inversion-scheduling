function quality = check_mb_passratio_window_quality(phasecurve_table, plot_xlim_ns, options)
%CHECK_MB_PASSRATIO_WINDOW_QUALITY Assess pass-ratio window quality across the full inclination family.

if nargin < 2 || isempty(plot_xlim_ns)
    plot_xlim_ns = local_resolve_xlim(phasecurve_table);
end
if nargin < 3 || isempty(options)
    options = struct();
end

quality = struct( ...
    'left_zero_score', 0, ...
    'right_one_score', 0, ...
    'transition_center_score', 0, ...
    'monotonicity_soft_score', 0, ...
    'plateau_score', 0, ...
    'left_zero_reached', false, ...
    'right_plateau_reached', false, ...
    'mid_transition_ok', false, ...
    'full_transition_resolved', false, ...
    'transition_ns_low_median', NaN, ...
    'transition_ns_high_median', NaN, ...
    'transition_ns_mid_median', NaN, ...
    'transition_center_ratio_median', NaN, ...
    'final_passratio_median', NaN, ...
    'final_passratio_min', NaN, ...
    'final_passratio_max', NaN, ...
    'num_inclinations', 0, ...
    'num_reaching_unity', 0, ...
    'num_nonzero_curves', 0, ...
    'reason', "No pass-ratio data available.", ...
    'per_i_table', table());

if isempty(phasecurve_table) || ~ismember('Ns', phasecurve_table.Properties.VariableNames) || ...
        ~ismember('max_pass_ratio', phasecurve_table.Properties.VariableNames)
    return;
end

if ismember('i_deg', phasecurve_table.Properties.VariableNames)
    i_values = unique(phasecurve_table.i_deg, 'sorted');
else
    i_values = 0;
    phasecurve_table.i_deg = zeros(height(phasecurve_table), 1);
end

row_cells = cell(numel(i_values), 1);
row_count = 0;
for idx = 1:numel(i_values)
    sub = phasecurve_table(phasecurve_table.i_deg == i_values(idx), :);
    curve = local_analyze_curve(sub, plot_xlim_ns, options);
    if isempty(curve)
        continue;
    end
    row_count = row_count + 1;
    row_cells{row_count} = curve;
end

if row_count == 0
    quality.reason = "No pass-ratio data falls inside the current plotting window.";
    return;
end

per_i = vertcat(row_cells{1:row_count});
quality.per_i_table = per_i;
quality.num_inclinations = height(per_i);
quality.num_reaching_unity = sum(per_i.reaches_unity);
quality.num_nonzero_curves = sum(per_i.has_nonzero_region);
quality.left_zero_score = mean(per_i.left_zero_score, 'omitnan');
quality.right_one_score = median(per_i.right_one_score, 'omitnan');
quality.transition_center_score = median(per_i.transition_center_score, 'omitnan');
quality.monotonicity_soft_score = mean(per_i.monotonicity_soft_score, 'omitnan');
quality.plateau_score = median(per_i.plateau_score, 'omitnan');
quality.transition_ns_low_median = median(per_i.transition_ns_low, 'omitnan');
quality.transition_ns_high_median = median(per_i.transition_ns_high, 'omitnan');
quality.transition_ns_mid_median = median(per_i.transition_ns_mid, 'omitnan');
quality.transition_center_ratio_median = median(per_i.transition_center_ratio, 'omitnan');
quality.final_passratio_median = median(per_i.right_value, 'omitnan');
quality.final_passratio_min = min(per_i.right_value, [], 'omitnan');
quality.final_passratio_max = max(per_i.right_value, [], 'omitnan');

quality.left_zero_reached = quality.left_zero_score >= 0.80;
quality.right_plateau_reached = quality.right_one_score >= 0.85 && ...
    (quality.num_reaching_unity >= ceil(0.4 * max(quality.num_inclinations, 1)) || quality.plateau_score >= 0.70);
quality.mid_transition_ok = quality.transition_center_score >= 0.65;
quality.full_transition_resolved = quality.left_zero_reached && quality.right_plateau_reached && quality.mid_transition_ok;

if quality.full_transition_resolved
    quality.reason = "The current domain covers the zero region, reaches a right-end plateau, and centers the transition band.";
elseif ~quality.left_zero_reached && ~quality.right_plateau_reached
    quality.reason = "The current domain misses both the low-pass floor and the unity plateau.";
elseif ~quality.left_zero_reached
    quality.reason = "The current domain starts too late and misses a clean near-zero pass-ratio floor.";
elseif ~quality.right_plateau_reached
    quality.reason = "The current domain has not yet reached a stable right-end unity plateau.";
else
    quality.reason = "The transition band is visible but not centered in the plotting window.";
end
end

function row = local_analyze_curve(sub, plot_xlim_ns, options)
sub = sortrows(sub, 'Ns', 'ascend');
Ns = sub.Ns(:);
pass = sub.max_pass_ratio(:);
mask = Ns >= plot_xlim_ns(1) & Ns <= plot_xlim_ns(2);
Ns = Ns(mask);
pass = pass(mask);
if isempty(Ns)
    row = table();
    return;
end

left_floor_tol = local_getfield_or(options, 'left_floor_tol', 0.05);
right_plateau_tol = local_getfield_or(options, 'right_plateau_tol', 0.95);
target_transition_center = local_getfield_or(options, 'target_transition_center', 0.50);
window_width = max(plot_xlim_ns(2) - plot_xlim_ns(1), eps);
tail_count = min(3, numel(pass));
head_count = min(3, numel(pass));

left_value = mean(pass(1:head_count), 'omitnan');
right_value = mean(pass(end - tail_count + 1:end), 'omitnan');
left_zero_score = max(0, min(1, 1 - left_value / max(left_floor_tol, eps)));
right_one_score = max(0, min(1, right_value / max(right_plateau_tol, eps)));

neg_diff = max(-diff(pass), 0);
total_variation = sum(abs(diff(pass)));
if total_variation <= eps
    monotonicity_soft_score = 1;
else
    monotonicity_soft_score = max(0, 1 - sum(neg_diff) / total_variation);
end

tail_span = pass(end - tail_count + 1:end);
tail_std = std(tail_span, 1, 'omitnan');
plateau_score = max(0, min(1, 1 - tail_std / 0.05)) * right_one_score;

idx_nonzero = find(pass > left_floor_tol, 1, 'first');
idx_last_zero = find(pass <= left_floor_tol, 1, 'last');
idx_first_one = find(pass >= right_plateau_tol, 1, 'first');
if isempty(idx_last_zero) && ~isempty(idx_nonzero)
    transition_ns_low = Ns(idx_nonzero);
elseif ~isempty(idx_last_zero)
    transition_ns_low = Ns(idx_last_zero);
else
    transition_ns_low = Ns(1);
end

if ~isempty(idx_first_one)
    transition_ns_high = Ns(idx_first_one);
else
    transition_ns_high = NaN;
end

if isfinite(transition_ns_low) && isfinite(transition_ns_high)
    transition_ns_mid = (transition_ns_low + transition_ns_high) / 2;
    transition_center_ratio = (transition_ns_mid - plot_xlim_ns(1)) / window_width;
    transition_center_score = max(0, 1 - abs(transition_center_ratio - target_transition_center) / 0.5);
else
    transition_ns_mid = NaN;
    transition_center_ratio = NaN;
    transition_center_score = 0;
end

row = table( ...
    sub.i_deg(1), ...
    logical(any(pass > left_floor_tol)), ...
    logical(~isempty(idx_first_one)), ...
    left_value, ...
    right_value, ...
    left_zero_score, ...
    right_one_score, ...
    transition_center_score, ...
    monotonicity_soft_score, ...
    plateau_score, ...
    transition_ns_low, ...
    transition_ns_high, ...
    transition_ns_mid, ...
    transition_center_ratio, ...
    'VariableNames', { ...
        'i_deg', ...
        'has_nonzero_region', ...
        'reaches_unity', ...
        'left_value', ...
        'right_value', ...
        'left_zero_score', ...
        'right_one_score', ...
        'transition_center_score', ...
        'monotonicity_soft_score', ...
        'plateau_score', ...
        'transition_ns_low', ...
        'transition_ns_high', ...
        'transition_ns_mid', ...
        'transition_center_ratio'});
end

function xlim_ns = local_resolve_xlim(phasecurve_table)
if isempty(phasecurve_table) || ~ismember('Ns', phasecurve_table.Properties.VariableNames) || isempty(phasecurve_table)
    xlim_ns = [0, 1];
    return;
end
Ns = unique(phasecurve_table.Ns(:), 'sorted');
xlim_ns = [min(Ns), max(Ns)];
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
