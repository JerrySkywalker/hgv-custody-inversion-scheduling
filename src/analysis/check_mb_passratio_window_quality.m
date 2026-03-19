function quality = check_mb_passratio_window_quality(phasecurve_table, plot_xlim_ns, options)
%CHECK_MB_PASSRATIO_WINDOW_QUALITY Assess pass-ratio window quality across the full inclination family.

if nargin < 2 || isempty(plot_xlim_ns)
    plot_xlim_ns = local_resolve_xlim(phasecurve_table);
end
if nargin < 3 || isempty(options)
    options = struct();
end

quality = local_empty_quality(plot_xlim_ns);

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
    quality.stop_reason_suggestion = "insufficient_valid_curves";
    return;
end

per_i = vertcat(row_cells{1:row_count});
quality.per_i_table = per_i;
quality.num_inclinations = height(per_i);
quality.num_valid_curves = sum(per_i.num_points >= 1);
quality.num_lineworthy_curves = sum(per_i.num_points >= 2);
quality.num_reaching_unity = sum(per_i.reaches_unity);
quality.num_nonzero_curves = sum(per_i.has_nonzero_region);
quality.num_curves_saturated = sum(per_i.right_plateau_reached);
quality.num_curves_with_transition = sum(per_i.has_transition_band);
quality.unique_ns_count = numel(unique(local_collect_numeric(per_i, 'Ns_values')));
quality.left_zero_score = mean(per_i.left_zero_score, 'omitnan');
quality.right_one_score = median(per_i.right_one_score, 'omitnan');
quality.transition_center_score = median(per_i.transition_center_score, 'omitnan');
quality.transition_width_score = median(per_i.transition_width_score, 'omitnan');
quality.monotonicity_soft_score = mean(per_i.monotonicity_soft_score, 'omitnan');
quality.plateau_score = median(per_i.plateau_score, 'omitnan');
quality.saturation_score = median(per_i.saturation_score, 'omitnan');
quality.domain_efficiency_penalty = mean(per_i.domain_efficiency_penalty, 'omitnan');
quality.transition_ns_low_median = median(per_i.transition_ns_low, 'omitnan');
quality.transition_ns_high_median = median(per_i.transition_ns_high, 'omitnan');
quality.transition_ns_mid_median = median(per_i.transition_ns_mid, 'omitnan');
quality.transition_center_ratio_median = median(per_i.transition_center_ratio, 'omitnan');
quality.transition_width_ratio_median = median(per_i.transition_width_ratio, 'omitnan');
quality.final_passratio_median = median(per_i.right_value, 'omitnan');
quality.final_passratio_min = min(per_i.right_value, [], 'omitnan');
quality.final_passratio_max = max(per_i.right_value, [], 'omitnan');
visible_ns = local_collect_numeric(per_i, 'Ns_values');
quality.visible_ns_min = local_safe_min(visible_ns);
quality.visible_ns_max = local_safe_max(visible_ns);
quality.no_feasible_point_found = quality.num_nonzero_curves == 0;
quality.only_single_point_visible = quality.unique_ns_count < 2 || quality.num_lineworthy_curves == 0;
quality.insufficient_valid_curves = quality.num_valid_curves < 2 || quality.num_lineworthy_curves < 2;

required_transition_curves = max(1, ceil(0.25 * max(quality.num_valid_curves, 1)));
required_saturated_curves = max(1, ceil(0.25 * max(quality.num_valid_curves, 1)));

quality.left_zero_reached = quality.left_zero_score >= 0.80;
quality.right_plateau_reached = quality.right_one_score >= 0.85 && ...
    quality.num_curves_saturated >= required_saturated_curves;
quality.mid_transition_ok = quality.transition_center_score >= 0.60;
quality.transition_width_ok = quality.transition_width_score >= 0.35 && ...
    quality.num_curves_with_transition >= required_transition_curves;
quality.full_transition_resolved = quality.left_zero_reached && quality.right_plateau_reached && ...
    quality.mid_transition_ok && quality.transition_width_ok && ...
    ~quality.only_single_point_visible && ~quality.insufficient_valid_curves;

quality.recommended_search_ns_min = local_recommended_ns_min(quality, plot_xlim_ns);
quality.recommended_search_ns_max = local_recommended_ns_max(quality, plot_xlim_ns);
quality.recommended_plot_xlim_ns = [quality.recommended_search_ns_min, quality.recommended_search_ns_max];
quality.stop_reason_suggestion = local_stop_reason_suggestion(quality);
quality.reason = local_quality_reason(quality);
end

function quality = local_empty_quality(plot_xlim_ns)
quality = struct( ...
    'left_zero_score', 0, ...
    'right_one_score', 0, ...
    'transition_center_score', 0, ...
    'transition_width_score', 0, ...
    'saturation_score', 0, ...
    'monotonicity_soft_score', 0, ...
    'plateau_score', 0, ...
    'domain_efficiency_penalty', 1, ...
    'left_zero_reached', false, ...
    'right_plateau_reached', false, ...
    'mid_transition_ok', false, ...
    'transition_width_ok', false, ...
    'full_transition_resolved', false, ...
    'transition_ns_low_median', NaN, ...
    'transition_ns_high_median', NaN, ...
    'transition_ns_mid_median', NaN, ...
    'transition_center_ratio_median', NaN, ...
    'transition_width_ratio_median', NaN, ...
    'final_passratio_median', NaN, ...
    'final_passratio_min', NaN, ...
    'final_passratio_max', NaN, ...
    'visible_ns_min', NaN, ...
    'visible_ns_max', NaN, ...
    'num_inclinations', 0, ...
    'num_valid_curves', 0, ...
    'num_lineworthy_curves', 0, ...
    'num_reaching_unity', 0, ...
    'num_nonzero_curves', 0, ...
    'num_curves_saturated', 0, ...
    'num_curves_with_transition', 0, ...
    'unique_ns_count', 0, ...
    'no_feasible_point_found', false, ...
    'only_single_point_visible', false, ...
    'insufficient_valid_curves', false, ...
    'recommended_search_ns_min', local_resolve_bound(plot_xlim_ns, 1, NaN), ...
    'recommended_search_ns_max', local_resolve_bound(plot_xlim_ns, 2, NaN), ...
    'recommended_plot_xlim_ns', reshape(local_default_xlim(plot_xlim_ns), 1, []), ...
    'stop_reason_suggestion', "no_feasible_point_found", ...
    'reason', "No pass-ratio data available.", ...
    'per_i_table', table());
end

function row = local_analyze_curve(sub, plot_xlim_ns, options)
curve_i_deg = sub.i_deg(1);
sub = sortrows(sub, 'Ns', 'ascend');
sub = groupsummary(sub, 'Ns', 'max', 'max_pass_ratio');
sub.Properties.VariableNames{'max_max_pass_ratio'} = 'max_pass_ratio';

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
plateau_fraction = sum(tail_span >= right_plateau_tol) / max(numel(tail_span), 1);
plateau_score = max(0, min(1, 1 - tail_std / 0.05)) * max(right_one_score, plateau_fraction);
right_plateau_reached = right_value >= right_plateau_tol && plateau_score >= 0.60;
if ~right_plateau_reached
    right_plateau_reached = ~isempty(find(pass >= right_plateau_tol, 1, 'first')) && plateau_score >= 0.50;
end
if right_plateau_reached
    saturation_score = min(1, 0.55 * right_one_score + 0.45 * plateau_score);
else
    saturation_score = min(1, 0.70 * right_one_score + 0.30 * plateau_score);
end

idx_nonzero = find(pass > left_floor_tol, 1, 'first');
idx_last_zero = find(pass <= left_floor_tol, 1, 'last');
idx_first_one = find(pass >= right_plateau_tol, 1, 'first');
transition_mask = pass > left_floor_tol & pass < right_plateau_tol;
transition_count = sum(transition_mask);

if isempty(idx_last_zero) && ~isempty(idx_nonzero)
    transition_ns_low = Ns(idx_nonzero);
elseif ~isempty(idx_last_zero)
    transition_ns_low = Ns(idx_last_zero);
else
    transition_ns_low = Ns(1);
end

if ~isempty(idx_first_one)
    transition_ns_high = Ns(idx_first_one);
elseif ~isempty(idx_nonzero)
    transition_ns_high = Ns(end);
else
    transition_ns_high = NaN;
end

if isfinite(transition_ns_low) && isfinite(transition_ns_high)
    transition_width = max(transition_ns_high - transition_ns_low, 0);
    transition_ns_mid = (transition_ns_low + transition_ns_high) / 2;
    transition_center_ratio = (transition_ns_mid - plot_xlim_ns(1)) / window_width;
    transition_center_score = max(0, 1 - abs(transition_center_ratio - target_transition_center) / 0.5);
    transition_width_ratio = transition_width / window_width;
    transition_width_score = local_transition_width_score(transition_width_ratio, transition_count, numel(Ns));
else
    transition_width = NaN;
    transition_ns_mid = NaN;
    transition_center_ratio = NaN;
    transition_center_score = 0;
    transition_width_ratio = NaN;
    transition_width_score = 0;
end

has_transition_band = transition_count >= 2 || (isfinite(transition_width) && transition_width > 0);

informative_idx = find(pass > left_floor_tol);
if isempty(informative_idx)
    informative_span = 0;
else
    informative_span = max(Ns(informative_idx(end)) - Ns(informative_idx(1)), 0);
end
domain_efficiency_penalty = max(0, min(1, 1 - informative_span / window_width));
if has_transition_band
    domain_efficiency_penalty = 0.75 * domain_efficiency_penalty;
end

row = table( ...
    curve_i_deg, ...
    logical(any(pass > left_floor_tol)), ...
    logical(~isempty(idx_first_one)), ...
    logical(right_plateau_reached), ...
    logical(has_transition_band), ...
    numel(Ns), ...
    {reshape(Ns, 1, [])}, ...
    left_value, ...
    right_value, ...
    left_zero_score, ...
    right_one_score, ...
    transition_center_score, ...
    transition_width_score, ...
    saturation_score, ...
    monotonicity_soft_score, ...
    plateau_score, ...
    domain_efficiency_penalty, ...
    transition_ns_low, ...
    transition_ns_high, ...
    transition_ns_mid, ...
    transition_center_ratio, ...
    transition_width, ...
    transition_width_ratio, ...
    'VariableNames', { ...
        'i_deg', ...
        'has_nonzero_region', ...
        'reaches_unity', ...
        'right_plateau_reached', ...
        'has_transition_band', ...
        'num_points', ...
        'Ns_values', ...
        'left_value', ...
        'right_value', ...
        'left_zero_score', ...
        'right_one_score', ...
        'transition_center_score', ...
        'transition_width_score', ...
        'saturation_score', ...
        'monotonicity_soft_score', ...
        'plateau_score', ...
        'domain_efficiency_penalty', ...
        'transition_ns_low', ...
        'transition_ns_high', ...
        'transition_ns_mid', ...
        'transition_center_ratio', ...
        'transition_width', ...
        'transition_width_ratio'});
end

function score = local_transition_width_score(width_ratio, transition_count, num_points)
if ~isfinite(width_ratio) || width_ratio <= 0
    if transition_count >= 2
        score = 0.20;
    else
        score = 0;
    end
    return;
end

target_ratio = 0.25;
score = max(0, 1 - abs(width_ratio - target_ratio) / max(target_ratio, eps));
if transition_count >= 2
    score = min(1, score + 0.15);
end
if num_points < 4
    score = 0.80 * score;
end
end

function reason = local_quality_reason(quality)
switch char(string(quality.stop_reason_suggestion))
    case 'success_balanced_window'
        reason = "The current domain exposes the near-zero floor, reaches a right-side plateau, and keeps the transition reasonably centered.";
    case 'no_feasible_point_found'
        reason = "No nonzero pass-ratio region was found within the current search domain.";
    case 'only_single_point_visible'
        reason = "Only a single visible N_s point remains inside the current plotting/search window.";
    case 'insufficient_valid_curves'
        reason = "Too few valid curves remain inside the current domain to support a reliable explanatory figure.";
    case 'limit_reached_without_right_plateau'
        reason = "The visible transition keeps rising toward the right boundary and has not yet formed a stable right-side plateau.";
    otherwise
        reason = "The transition band exists but remains too narrow or too close to a boundary for a balanced explanatory figure.";
end
end

function code = local_stop_reason_suggestion(quality)
if quality.no_feasible_point_found
    code = "no_feasible_point_found";
elseif quality.only_single_point_visible
    code = "only_single_point_visible";
elseif quality.insufficient_valid_curves
    code = "insufficient_valid_curves";
elseif quality.full_transition_resolved
    code = "success_balanced_window";
elseif ~quality.right_plateau_reached
    code = "limit_reached_without_right_plateau";
else
    code = "limit_reached_insufficient_transition";
end
end

function ns_min = local_recommended_ns_min(quality, plot_xlim_ns)
base = local_resolve_bound(plot_xlim_ns, 1, NaN);
if quality.no_feasible_point_found || ~isfinite(quality.visible_ns_min)
    ns_min = base;
    return;
end

anchor = quality.transition_ns_low_median;
if ~isfinite(anchor)
    anchor = quality.visible_ns_min;
end
span = max(quality.transition_ns_high_median - quality.transition_ns_low_median, 8);
ns_min = max(quality.visible_ns_min, floor(anchor - 0.5 * span));
if isfinite(base)
    ns_min = min(ns_min, base);
end
end

function ns_max = local_recommended_ns_max(quality, plot_xlim_ns)
base = local_resolve_bound(plot_xlim_ns, 2, NaN);
if quality.no_feasible_point_found || ~isfinite(quality.visible_ns_max)
    ns_max = base;
    return;
end

anchor = quality.transition_ns_high_median;
if ~isfinite(anchor)
    anchor = quality.visible_ns_max;
end
span = max(quality.transition_ns_high_median - quality.transition_ns_low_median, 8);
ns_max = ceil(anchor + span);
ns_max = max(ns_max, quality.visible_ns_max);
if isfinite(base)
    ns_max = max(ns_max, base);
end
end

function values = local_collect_numeric(per_i, field_name)
values = [];
if isempty(per_i) || ~ismember(field_name, per_i.Properties.VariableNames)
    return;
end
raw = per_i.(field_name);
if isnumeric(raw)
    values = raw(:);
    return;
end
if iscell(raw)
    for idx = 1:numel(raw)
        values = [values; reshape(raw{idx}, [], 1)]; %#ok<AGROW>
    end
end
end

function value = local_safe_min(values)
if isempty(values)
    value = NaN;
else
    value = min(values, [], 'omitnan');
end
end

function value = local_safe_max(values)
if isempty(values)
    value = NaN;
else
    value = max(values, [], 'omitnan');
end
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

function bound = local_resolve_bound(bounds, idx, fallback)
if numel(bounds) >= idx && isfinite(bounds(idx))
    bound = bounds(idx);
else
    bound = fallback;
end
end

function bounds = local_default_xlim(bounds)
if numel(bounds) == 2 && all(isfinite(bounds))
    bounds = reshape(bounds, 1, []);
else
    bounds = [0, 1];
end
end
