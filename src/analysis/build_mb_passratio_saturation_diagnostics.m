function summary_table = build_mb_passratio_saturation_diagnostics(phasecurve_table, search_domain, options)
%BUILD_MB_PASSRATIO_SATURATION_DIAGNOSTICS Summarize pass-ratio saturation quality per semantic mode.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

[value_fields, semantic_labels] = local_resolve_value_fields(phasecurve_table, options);
h_km = local_resolve_context_value(phasecurve_table, options, 'h_km', NaN);
family_name = string(local_resolve_context_value(phasecurve_table, options, 'family_name', ""));
ns_min = local_resolve_search_bound(search_domain, phasecurve_table, 'min');
ns_max = local_resolve_search_bound(search_domain, phasecurve_table, 'max');
plot_xlim_ns = [ns_min, ns_max];
left_floor_tol = local_getfield_or(options, 'left_floor_tol', 0.05);
right_unity_tol = local_getfield_or(options, 'right_unity_tol', 0.98);

summary_table = table('Size', [numel(value_fields), 18], ...
    'VariableTypes', {'double', 'string', 'string', 'double', 'double', 'logical', 'logical', 'double', 'double', 'double', 'double', 'double', 'logical', 'logical', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'h_km', 'family_name', 'semantic_mode', 'search_ns_min', 'search_ns_max', ...
    'left_zero_reached', 'right_unity_reached', 'max_passratio', 'first_nonzero_ns', 'first_unity_ns', ...
    'num_distinct_passratio_levels', 'right_plateau_length', 'is_boundary_dominated', ...
    'is_search_domain_unsaturated', 'left_zero_score', 'right_one_score', ...
    'transition_center_score', 'diagnostic_note'});

for idx = 1:numel(value_fields)
    field_name = value_fields{idx};
    semantic_label = string(semantic_labels{idx});
    phase_sub = local_project_phasecurve(phasecurve_table, field_name);
    quality = check_mb_passratio_window_quality(phase_sub, plot_xlim_ns, struct( ...
        'left_floor_tol', left_floor_tol, ...
        'right_plateau_tol', right_unity_tol));

    max_passratio = local_safe_extreme(phase_sub.max_pass_ratio, 'max');
    first_nonzero_ns = local_first_threshold_ns(phase_sub, left_floor_tol, '>');
    first_unity_ns = local_first_threshold_ns(phase_sub, right_unity_tol, '>=');
    num_distinct_levels = numel(unique(round(phase_sub.max_pass_ratio(isfinite(phase_sub.max_pass_ratio)) * 1000) / 1000));
    plateau_length = local_right_plateau_length(phase_sub, right_unity_tol);
    boundary_dominated = logical(~quality.right_plateau_reached && quality.num_nonzero_curves > 0);
    unsaturated = logical(~quality.right_plateau_reached && quality.num_nonzero_curves > 0);

    summary_table(idx, :) = { ...
        h_km, ...
        family_name, ...
        semantic_label, ...
        ns_min, ...
        ns_max, ...
        logical(quality.left_zero_reached), ...
        logical(quality.right_plateau_reached), ...
        max_passratio, ...
        first_nonzero_ns, ...
        first_unity_ns, ...
        num_distinct_levels, ...
        plateau_length, ...
        boundary_dominated, ...
        unsaturated, ...
        quality.left_zero_score, ...
        quality.right_one_score, ...
        quality.transition_center_score, ...
        local_passratio_note(quality, max_passratio)};
end
end

function [value_fields, semantic_labels] = local_resolve_value_fields(phasecurve_table, options)
value_fields = local_getfield_or(options, 'value_fields', {});
semantic_labels = cellstr(string(local_getfield_or(options, 'semantic_labels', {})));
if isempty(value_fields)
    if istable(phasecurve_table) && ismember('max_pass_ratio', phasecurve_table.Properties.VariableNames)
        value_fields = {'max_pass_ratio'};
        semantic_labels = {'unknown'};
    else
        candidate_fields = phasecurve_table.Properties.VariableNames(contains(phasecurve_table.Properties.VariableNames, 'max_pass_ratio'));
        value_fields = cellstr(candidate_fields(:));
        semantic_labels = regexprep(value_fields, '^max_pass_ratio_?', '');
    end
end
if isempty(semantic_labels) || numel(semantic_labels) ~= numel(value_fields)
    semantic_labels = value_fields;
end
end

function phase_sub = local_project_phasecurve(phasecurve_table, value_field)
base_fields = intersect({'h_km', 'family_name', 'i_deg', 'Ns'}, phasecurve_table.Properties.VariableNames, 'stable');
phase_sub = phasecurve_table(:, base_fields);
if ismember(value_field, phasecurve_table.Properties.VariableNames)
    phase_sub.max_pass_ratio = phasecurve_table.(value_field);
else
    phase_sub.max_pass_ratio = NaN(height(phasecurve_table), 1);
end
if ~ismember('i_deg', phase_sub.Properties.VariableNames)
    phase_sub.i_deg = zeros(height(phase_sub), 1);
end
if ~ismember('Ns', phase_sub.Properties.VariableNames)
    phase_sub.Ns = NaN(height(phase_sub), 1);
end
end

function value = local_resolve_context_value(phasecurve_table, options, field_name, fallback)
value = local_getfield_or(options, field_name, fallback);
if ~isequaln(value, fallback)
    return;
end
if istable(phasecurve_table) && ismember(field_name, phasecurve_table.Properties.VariableNames) && ~isempty(phasecurve_table)
    column = phasecurve_table.(field_name);
    value = column(1);
end
end

function bound = local_resolve_search_bound(search_domain, phasecurve_table, mode_name)
if strcmpi(mode_name, 'min')
    bound = local_getfield_or(search_domain, 'ns_search_min', NaN);
else
    bound = local_getfield_or(search_domain, 'ns_search_max', NaN);
end
if isfinite(bound)
    return;
end
if isempty(phasecurve_table) || ~ismember('Ns', phasecurve_table.Properties.VariableNames)
    bound = NaN;
    return;
end
Ns = phasecurve_table.Ns(isfinite(phasecurve_table.Ns));
if isempty(Ns)
    bound = NaN;
elseif strcmpi(mode_name, 'min')
    bound = min(Ns);
else
    bound = max(Ns);
end
end

function value = local_safe_extreme(values, mode_name)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
elseif strcmpi(mode_name, 'min')
    value = min(values);
else
    value = max(values);
end
end

function ns_value = local_first_threshold_ns(phasecurve_table, threshold, relation)
ns_value = NaN;
if isempty(phasecurve_table)
    return;
end
phasecurve_table = sortrows(phasecurve_table, 'Ns');
switch relation
    case '>'
        mask = phasecurve_table.max_pass_ratio > threshold;
    otherwise
        mask = phasecurve_table.max_pass_ratio >= threshold;
end
mask = mask & isfinite(phasecurve_table.Ns);
if any(mask)
    ns_value = min(phasecurve_table.Ns(mask));
end
end

function plateau_length = local_right_plateau_length(phasecurve_table, threshold)
plateau_lengths = [];
if isempty(phasecurve_table) || ~all(ismember({'i_deg', 'Ns', 'max_pass_ratio'}, phasecurve_table.Properties.VariableNames))
    plateau_length = NaN;
    return;
end

i_values = unique(phasecurve_table.i_deg, 'sorted');
for idx = 1:numel(i_values)
    Ti = sortrows(phasecurve_table(phasecurve_table.i_deg == i_values(idx), :), 'Ns');
    if isempty(Ti)
        continue;
    end
    mask = Ti.max_pass_ratio >= threshold;
    if ~any(mask)
        plateau_lengths(end + 1, 1) = 0; %#ok<AGROW>
        continue;
    end
    last_false = find(~mask, 1, 'last');
    if isempty(last_false)
        start_idx = 1;
    else
        start_idx = last_false + 1;
    end
    plateau_lengths(end + 1, 1) = Ti.Ns(end) - Ti.Ns(start_idx); %#ok<AGROW>
end

if isempty(plateau_lengths)
    plateau_length = NaN;
else
    plateau_length = median(plateau_lengths, 'omitnan');
end
end

function note = local_passratio_note(quality, max_passratio)
if quality.no_feasible_point_found
    note = "no nonzero pass-ratio region was found within the current search domain";
elseif quality.only_single_point_visible
    note = "only a single visible N_s point remains inside the current search domain";
elseif ~quality.right_plateau_reached
    note = "unity plateau not reached within current search domain";
elseif max_passratio < 0.98
    note = "pass-ratio remains below unity within the current search domain";
else
    note = "pass-ratio curve reaches a stable right-side plateau within the current search domain";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
