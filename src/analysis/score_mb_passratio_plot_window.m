function score_result = score_mb_passratio_plot_window(phasecurve_table, plot_xlim_ns, options)
%SCORE_MB_PASSRATIO_PLOT_WINDOW Heuristically score a pass-ratio plotting window.

if nargin < 2 || isempty(plot_xlim_ns)
    plot_xlim_ns = local_resolve_xlim(phasecurve_table);
end
if nargin < 3 || isempty(options)
    options = struct();
end

score_result = struct( ...
    'score', -inf, ...
    'has_low_region', false, ...
    'has_high_region', false, ...
    'transition_ns_low', NaN, ...
    'transition_ns_high', NaN, ...
    'transition_ns_mid', NaN, ...
    'window_mid', mean(plot_xlim_ns), ...
    'window_width', diff(plot_xlim_ns), ...
    'left_margin_ratio', NaN, ...
    'right_margin_ratio', NaN, ...
    'reason', "No pass-ratio data available.");

if isempty(phasecurve_table) || ~ismember('Ns', phasecurve_table.Properties.VariableNames) || ~ismember('max_pass_ratio', phasecurve_table.Properties.VariableNames)
    return;
end

[Ns, best_pass] = local_build_envelope(phasecurve_table);
mask = Ns >= plot_xlim_ns(1) & Ns <= plot_xlim_ns(2);
Ns = Ns(mask);
best_pass = best_pass(mask);
if isempty(Ns)
    score_result.reason = "The plotting window does not overlap the evaluated N_s grid.";
    return;
end

zero_tol = local_getfield_or(options, 'zero_tol', 0.02);
one_tol = local_getfield_or(options, 'one_tol', 0.98);
target_transition_center = local_getfield_or(options, 'target_transition_center', 0.50);
required_low_margin = local_getfield_or(options, 'required_low_margin', 0.10);
required_high_margin = local_getfield_or(options, 'required_high_margin', 0.10);

idx_last_zero = find(best_pass <= zero_tol, 1, 'last');
idx_first_nonzero = find(best_pass > zero_tol, 1, 'first');
idx_first_one = find(best_pass >= one_tol, 1, 'first');

if ~isempty(idx_last_zero)
    score_result.has_low_region = true;
    score_result.transition_ns_low = Ns(idx_last_zero);
elseif ~isempty(idx_first_nonzero)
    score_result.transition_ns_low = Ns(idx_first_nonzero);
end

if ~isempty(idx_first_one)
    score_result.has_high_region = true;
    score_result.transition_ns_high = Ns(idx_first_one);
else
    score_result.transition_ns_high = Ns(end);
end

if isnan(score_result.transition_ns_low)
    score_result.transition_ns_low = Ns(1);
end

score_result.transition_ns_mid = (score_result.transition_ns_low + score_result.transition_ns_high) / 2;
score_result.window_mid = mean(plot_xlim_ns);
score_result.window_width = max(plot_xlim_ns(2) - plot_xlim_ns(1), eps);
score_result.left_margin_ratio = max((score_result.transition_ns_low - plot_xlim_ns(1)) / score_result.window_width, 0);
score_result.right_margin_ratio = max((plot_xlim_ns(2) - score_result.transition_ns_high) / score_result.window_width, 0);

transition_width_ratio = max(score_result.transition_ns_high - score_result.transition_ns_low, 0) / score_result.window_width;
center_error = abs((score_result.transition_ns_mid - plot_xlim_ns(1)) / score_result.window_width - target_transition_center);
flat_penalty = max(score_result.left_margin_ratio - 0.35, 0) + max(score_result.right_margin_ratio - 0.35, 0);

score_value = 0;
score_value = score_value + 25 * double(score_result.has_low_region);
score_value = score_value + 25 * double(score_result.has_high_region);
score_value = score_value + 10 * min(score_result.left_margin_ratio / max(required_low_margin, eps), 1);
score_value = score_value + 10 * min(score_result.right_margin_ratio / max(required_high_margin, eps), 1);
score_value = score_value + 15 * (1 - min(abs(transition_width_ratio - 0.35) / 0.35, 1));
score_value = score_value - 30 * center_error;
score_value = score_value - 15 * flat_penalty;

score_result.score = score_value;
score_result.reason = local_build_reason(score_result);
end

function [Ns, best_pass] = local_build_envelope(phasecurve_table)
Ns = unique(phasecurve_table.Ns(:), 'sorted');
best_pass = zeros(numel(Ns), 1);
for idx = 1:numel(Ns)
    mask = phasecurve_table.Ns == Ns(idx);
    best_pass(idx) = max(phasecurve_table.max_pass_ratio(mask));
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

function reason = local_build_reason(score_result)
parts = strings(0, 1);
if score_result.has_low_region
    parts(end + 1) = "covers the zero-pass region";
else
    parts(end + 1) = "misses the zero-pass region";
end
if score_result.has_high_region
    parts(end + 1) = "covers the unity-pass region";
else
    parts(end + 1) = "does not yet reach unity pass ratio";
end
parts(end + 1) = sprintf('transition midpoint = %.1f, window midpoint = %.1f', score_result.transition_ns_mid, score_result.window_mid);
reason = strjoin(parts, '; ');
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
