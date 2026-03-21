function report = build_mb_frontier_coverage_report(run_outputs)
%BUILD_MB_FRONTIER_COVERAGE_REPORT Summarize frontier definition quality across MB runs.

if nargin < 1 || isempty(run_outputs)
    report = table();
    return;
end

rows = cell(0, 12);
for idx = 1:numel(run_outputs)
    wrapper = run_outputs(idx);
    runs = local_getfield_or(local_getfield_or(wrapper, 'run_output', struct()), 'runs', struct([]));
    for idx_run = 1:numel(runs)
        run = runs(idx_run);
        i_values = unique(local_table_column(local_getfield_or(run, 'design_table', table()), 'i_deg'), 'sorted');
        frontier = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'frontier_vs_i', table());
        sampled_count = numel(i_values);
        if isempty(frontier) || ~istable(frontier) || ~ismember('minimum_feasible_Ns', frontier.Properties.VariableNames)
            defined_count = 0;
            boundary_count = 0;
        else
            frontier = frontier(isfinite(frontier.minimum_feasible_Ns), :);
            defined_count = height(frontier);
            ns_max = local_resolve_ns_max(run);
            if isfinite(ns_max)
                boundary_count = sum(frontier.minimum_feasible_Ns >= ns_max - 1e-9);
            else
                boundary_count = 0;
            end
        end
        internal_count = max(defined_count - boundary_count, 0);
        if sampled_count > 0
            defined_ratio = defined_count / sampled_count;
        else
            defined_ratio = 0;
        end
        weakly_defined = defined_count <= 1 || internal_count == 0;
        truncated = boundary_count > 0;
        grade = local_grade(defined_count, internal_count, sampled_count, truncated);
        rows(end + 1, :) = { ... %#ok<AGROW>
            string(wrapper.mode), string(wrapper.sensor_group), string(local_getfield_or(run, 'family_name', "")), ...
            local_getfield_or(run, 'h_km', NaN), sampled_count, defined_count, internal_count, boundary_count, ...
            defined_ratio, weakly_defined, truncated, grade};
    end
end

report = cell2table(rows, 'VariableNames', {'semantic_mode', 'sensor_group', 'family_name', 'h_km', ...
    'sampled_inclination_count', 'frontier_defined_count', 'frontier_internal_count', 'frontier_boundary_count', ...
    'frontier_defined_ratio', 'frontier_weakly_defined', 'frontier_truncated_by_upper_bound', 'frontier_reliability_grade'});
report.semantic_mode = string(report.semantic_mode);
report.sensor_group = string(report.sensor_group);
report.family_name = string(report.family_name);
report.h_km = double(report.h_km);
report.sampled_inclination_count = double(report.sampled_inclination_count);
report.frontier_defined_count = double(report.frontier_defined_count);
report.frontier_internal_count = double(report.frontier_internal_count);
report.frontier_boundary_count = double(report.frontier_boundary_count);
report.frontier_defined_ratio = double(report.frontier_defined_ratio);
report.frontier_weakly_defined = logical(report.frontier_weakly_defined);
report.frontier_truncated_by_upper_bound = logical(report.frontier_truncated_by_upper_bound);
report.frontier_reliability_grade = string(report.frontier_reliability_grade);
report = sortrows(report, {'h_km', 'semantic_mode', 'sensor_group', 'family_name'});
end

function ns_max = local_resolve_ns_max(run)
expansion_state = local_getfield_or(run, 'expansion_state', struct());
effective_domain = local_getfield_or(expansion_state, 'effective_search_domain', struct());
ns_max = local_getfield_or(effective_domain, 'ns_search_max', NaN);
if ~isfinite(ns_max)
    Ns = local_table_column(local_getfield_or(run, 'design_table', table()), 'Ns');
    Ns = Ns(isfinite(Ns));
    if isempty(Ns)
        ns_max = NaN;
    else
        ns_max = max(Ns);
    end
end
end

function grade = local_grade(defined_count, internal_count, sampled_count, truncated)
if defined_count <= 0
    grade = "diagnostic_only";
elseif defined_count <= 1
    grade = "single_point_only";
elseif truncated || internal_count <= 0
    grade = "weak";
elseif sampled_count > 0 && (defined_count / sampled_count) < 0.5
    grade = "weak";
else
    grade = "good";
end
end

function values = local_table_column(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = [];
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
