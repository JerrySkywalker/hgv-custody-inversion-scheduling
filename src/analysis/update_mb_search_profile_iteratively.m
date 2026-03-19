function [next_profile, action] = update_mb_search_profile_iteratively(profile, quality, options)
%UPDATE_MB_SEARCH_PROFILE_ITERATIVELY Expand or shift an MB search profile based on pass-ratio quality gaps.

if nargin < 3 || isempty(options)
    options = struct();
end

next_profile = merge_mb_search_profile_overrides(profile, struct(), "");
action = struct('name', "hold", 'reason', "Current profile already satisfies the update rule.");

P_values = reshape(local_getfield_or(next_profile, 'P_values', local_getfield_or(next_profile, 'P_grid', [])), 1, []);
T_values = reshape(local_getfield_or(next_profile, 'T_values', local_getfield_or(next_profile, 'T_grid', [])), 1, []);
plot_xlim_ns = reshape(local_getfield_or(next_profile, 'Ns_xlim_plot', local_getfield_or(next_profile, 'plot_xlim_ns', [])), 1, []);

max_P = local_getfield_or(options, 'max_P', max(P_values));
max_T = local_getfield_or(options, 'max_T', max(T_values));
step_P = local_getfield_or(options, 'expand_step_P', 2);
step_T = local_getfield_or(options, 'expand_step_T', 4);
min_P = max(2, local_getfield_or(options, 'min_P', 2));
min_T = max(2, local_getfield_or(options, 'min_T', 2));

if quality.no_feasible_point_found || quality.only_single_point_visible || quality.insufficient_valid_curves
    if max(T_values) < max_T
        T_values = unique([T_values, min(max_T, T_values(end) + step_T)], 'stable');
        action.name = "expand_T_upper";
        action.reason = "Expand the slot-count upper bound because the current domain does not yet expose a reliable transition band.";
    elseif max(P_values) < max_P
        P_values = unique([P_values, min(max_P, P_values(end) + step_P)], 'stable');
        action.name = "expand_P_upper";
        action.reason = "Expand the plane-count upper bound because the current domain does not yet expose a reliable transition band.";
    end
end

if ~quality.right_plateau_reached
    if max(T_values) < max_T
        T_values = unique([T_values, min(max_T, T_values(end) + step_T)], 'stable');
        action.name = "expand_T_upper";
        action.reason = "Extend the Walker slot-count upper bound to search for the missing right-end plateau.";
    elseif max(P_values) < max_P
        P_values = unique([P_values, min(max_P, P_values(end) + step_P)], 'stable');
        action.name = "expand_P_upper";
        action.reason = "Extend the Walker plane-count upper bound to search for the missing right-end plateau.";
    end
end

if ~quality.left_zero_reached && action.name == "hold"
    if min(T_values) > min_T
        T_values = unique([max(min_T, T_values(1) - step_T), T_values], 'stable');
        action.name = "expand_T_lower";
        action.reason = "Extend the Walker slot-count lower bound to expose the near-zero left floor.";
    elseif min(P_values) > min_P
        P_values = unique([max(min_P, P_values(1) - step_P), P_values], 'stable');
        action.name = "expand_P_lower";
        action.reason = "Extend the Walker plane-count lower bound to expose the near-zero left floor.";
    end
end

if action.name == "hold" && (~quality.mid_transition_ok || ~quality.transition_width_ok) && ...
        isfinite(quality.transition_ns_low_median) && isfinite(quality.transition_ns_high_median)
    current_width = max(diff(plot_xlim_ns), 1);
    transition_width = max(quality.transition_ns_high_median - quality.transition_ns_low_median, 1);
    target_center = local_getfield_or(options, 'target_transition_center', 0.50);
    desired_width = max(current_width, round(transition_width / max(0.30, target_center)));
    desired_width = max(desired_width, round(transition_width / 0.35));
    transition_mid = quality.transition_ns_mid_median;
    left = round(transition_mid - desired_width * target_center);
    right = round(left + desired_width);
    plot_xlim_ns = [max(0, left), max(right, left + 1)];
    action.name = "recenter_xlim";
    action.reason = "Shift and widen the plotting window so the visible transition band sits closer to the middle.";
end

if action.name == "hold" && quality.domain_efficiency_penalty > 0.75 && ...
        isfinite(quality.transition_ns_low_median) && isfinite(quality.transition_ns_high_median)
    transition_width = max(quality.transition_ns_high_median - quality.transition_ns_low_median, 1);
    pad = max(4, round(0.75 * transition_width));
    left = floor(quality.transition_ns_low_median - pad);
    right = ceil(quality.transition_ns_high_median + pad);
    plot_xlim_ns = [max(0, left), max(right, left + 8)];
    action.name = "tighten_focus_xlim";
    action.reason = "Reduce excessive flat margins so the transition occupies a more informative fraction of the figure.";
end

ns_max = max(P_values) * max(T_values);
ns_min = min(P_values) * min(T_values);
if isempty(plot_xlim_ns) || numel(plot_xlim_ns) ~= 2
    plot_xlim_ns = [ns_min, ns_max];
else
    plot_xlim_ns(1) = min(plot_xlim_ns(1), ns_min);
    plot_xlim_ns(2) = max(plot_xlim_ns(2), ns_max);
end

if quality.only_single_point_visible
    min_width = max(16, step_T * max(min(P_values), 1));
    plot_xlim_ns(1) = max(0, min(plot_xlim_ns(1), ns_min));
    plot_xlim_ns(2) = max(plot_xlim_ns(2), plot_xlim_ns(1) + min_width);
end

next_profile = merge_mb_search_profile_overrides(next_profile, struct( ...
    'P_grid', reshape(P_values, 1, []), ...
    'T_grid', reshape(T_values, 1, []), ...
    'P_values', reshape(P_values, 1, []), ...
    'T_values', reshape(T_values, 1, []), ...
    'plot_xlim_ns', reshape(plot_xlim_ns, 1, []), ...
    'Ns_xlim_plot', reshape(plot_xlim_ns, 1, [])), "iterative_update");
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
