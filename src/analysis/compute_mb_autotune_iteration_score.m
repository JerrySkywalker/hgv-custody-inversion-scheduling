function score_result = compute_mb_autotune_iteration_score(profile, phasecurve_table, quality, options)
%COMPUTE_MB_AUTOTUNE_ITERATION_SCORE Score an auto-tune iteration from family-wide pass-ratio quality metrics.

if nargin < 4 || isempty(options)
    options = struct();
end
if nargin < 3 || isempty(quality)
    quality = check_mb_passratio_window_quality(phasecurve_table, local_getfield_or(profile, 'Ns_xlim_plot', []), options);
end

plot_xlim_ns = reshape(local_getfield_or(profile, 'Ns_xlim_plot', local_getfield_or(profile, 'plot_xlim_ns', [])), 1, []);
if isempty(plot_xlim_ns)
    plot_xlim_ns = local_resolve_xlim(phasecurve_table);
end

score_value = 0;
score_value = score_value + 24 * quality.left_zero_score;
score_value = score_value + 30 * quality.right_one_score;
score_value = score_value + 16 * quality.transition_center_score;
score_value = score_value + 10 * quality.monotonicity_soft_score;
score_value = score_value + 10 * quality.plateau_score;
score_value = score_value + 10 * min(quality.num_reaching_unity / max(quality.num_inclinations, 1), 1);

if quality.num_nonzero_curves == 0
    score_value = score_value - 35;
end
if quality.final_passratio_median < 0.50
    score_value = score_value - 20 * (0.50 - quality.final_passratio_median);
end
if ~quality.left_zero_reached
    score_value = score_value - 8;
end
if ~quality.right_plateau_reached
    score_value = score_value - 12;
end
if ~quality.mid_transition_ok
    score_value = score_value - 6;
end

score_result = struct( ...
    'score', score_value, ...
    'quality', quality, ...
    'has_low_region', logical(quality.left_zero_reached), ...
    'has_high_region', logical(quality.right_plateau_reached), ...
    'transition_ns_low', quality.transition_ns_low_median, ...
    'transition_ns_high', quality.transition_ns_high_median, ...
    'transition_ns_mid', quality.transition_ns_mid_median, ...
    'window_mid', mean(plot_xlim_ns), ...
    'window_width', max(diff(plot_xlim_ns), eps), ...
    'left_margin_ratio', local_margin_ratio(plot_xlim_ns, quality.transition_ns_low_median, 'left'), ...
    'right_margin_ratio', local_margin_ratio(plot_xlim_ns, quality.transition_ns_high_median, 'right'), ...
    'state', local_score_state(quality), ...
    'reason', string(quality.reason));
end

function ratio = local_margin_ratio(plot_xlim_ns, transition_ns, side)
if isempty(plot_xlim_ns) || numel(plot_xlim_ns) ~= 2 || ~isfinite(transition_ns)
    ratio = NaN;
    return;
end
width = max(diff(plot_xlim_ns), eps);
switch lower(side)
    case 'left'
        ratio = max((transition_ns - plot_xlim_ns(1)) / width, 0);
    case 'right'
        ratio = max((plot_xlim_ns(2) - transition_ns) / width, 0);
    otherwise
        ratio = NaN;
end
end

function state = local_score_state(quality)
if quality.full_transition_resolved
    state = "success";
elseif quality.num_nonzero_curves == 0
    state = "all_zero";
elseif quality.right_plateau_reached
    state = "plateau_without_center";
else
    state = "needs_expansion";
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
