function out = stage12E_minimum_design_packager(inputs, cfg, overrides)
%STAGE12E_MINIMUM_DESIGN_PACKAGER Extract dissertation-facing minimum-design results.

startup();

if nargin < 1 || isempty(inputs)
    inputs = {};
end
if nargin < 2 || isempty(cfg)
    cfg = default_params();
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

cfg = milestone_common_defaults(cfg);

results = local_normalize_inputs(inputs);
[full_theta_table, feasible_theta_table, fail_partition_table] = local_collect_tables(results);
boundary_struct = extract_stage09_minimum_boundary(feasible_theta_table);

minimum_design_table = boundary_struct.theta_min_table;
if isempty(minimum_design_table)
    near_optimal_table = table();
    minimum_design = struct();
else
    minimum_design_table = sortrows(minimum_design_table, {'joint_margin', 'h_km', 'i_deg', 'P', 'T'}, ...
        {'descend', 'ascend', 'ascend', 'ascend', 'ascend'});
    minimum_design_table.objective_value = minimum_design_table.Ns;
    minimum_design_table.dominant_constraint = repmat(string(local_pick_top_fail(fail_partition_table)), height(minimum_design_table), 1);
    minimum_design_table.has_near_optimal_alternatives = repmat(height(minimum_design_table) > 1, height(minimum_design_table), 1);
    minimum_design = table2struct(minimum_design_table(1, :));

    near_optimal_mask = feasible_theta_table.Ns <= (boundary_struct.N_min_rob + 2);
    near_optimal_table = feasible_theta_table(near_optimal_mask, :);
end

out = struct();
out.cfg = cfg;
out.inputs = results;
out.overrides = overrides;
out.minimum_design = minimum_design;
out.minimum_design_table = minimum_design_table;
out.near_optimal_table = near_optimal_table;
out.boundary_table = boundary_struct.boundary_table;
out.dominant_constraint_distribution = local_fail_distribution(fail_partition_table);
out.full_theta_table = full_theta_table;
out.feasible_theta_table = feasible_theta_table;
out.fail_partition_table = fail_partition_table;
out.files = struct();
end

function results = local_normalize_inputs(inputs)
if iscell(inputs)
    results = inputs;
elseif isstruct(inputs)
    results = num2cell(inputs);
else
    results = {inputs};
end
end

function [full_theta_table, feasible_theta_table, fail_partition_table] = local_collect_tables(results)
full_rows = {};
feasible_rows = {};
fail_rows = {};
for k = 1:numel(results)
    r = results{k};
    if isfield(r, 'full_theta_table') && ~isempty(r.full_theta_table)
        Tfull = r.full_theta_table;
        if ~ismember('slice_source', Tfull.Properties.VariableNames)
            if isfield(r, 'slice_name')
                Tfull.slice_source = repmat(string(r.slice_name), height(Tfull), 1);
            elseif isfield(r, 'task_slice_id')
                Tfull.slice_source = repmat(string(r.task_slice_id), height(Tfull), 1);
            else
                Tfull.slice_source = repmat("unknown", height(Tfull), 1);
            end
        end
        full_rows{end+1, 1} = Tfull; %#ok<AGROW>
    end
    if isfield(r, 'feasible_theta_table') && ~isempty(r.feasible_theta_table)
        Tfeas = r.feasible_theta_table;
        if ~ismember('slice_source', Tfeas.Properties.VariableNames)
            if isfield(r, 'slice_name')
                Tfeas.slice_source = repmat(string(r.slice_name), height(Tfeas), 1);
            elseif isfield(r, 'task_slice_id')
                Tfeas.slice_source = repmat(string(r.task_slice_id), height(Tfeas), 1);
            else
                Tfeas.slice_source = repmat("unknown", height(Tfeas), 1);
            end
        end
        feasible_rows{end+1, 1} = Tfeas; %#ok<AGROW>
    end
    if isfield(r, 'fail_partition_table') && ~isempty(r.fail_partition_table)
        fail_rows{end+1, 1} = r.fail_partition_table; %#ok<AGROW>
    end
end

full_theta_table = table();
feasible_theta_table = table();
fail_partition_table = table();
if ~isempty(full_rows)
    full_theta_table = vertcat(full_rows{:});
end
if ~isempty(feasible_rows)
    feasible_theta_table = vertcat(feasible_rows{:});
end
if ~isempty(fail_rows)
    Tall = vertcat(fail_rows{:});
    [uTags, ~, ic] = unique(string(Tall.dominant_fail_tag));
    counts = accumarray(ic, Tall.count);
    fail_partition_table = table(uTags, counts, 'VariableNames', {'dominant_fail_tag', 'count'});
    fail_partition_table = sortrows(fail_partition_table, 'count', 'descend');
end
end

function distribution = local_fail_distribution(fail_partition_table)
distribution = struct();
if isempty(fail_partition_table)
    distribution.none = 0;
    return;
end
for k = 1:height(fail_partition_table)
    key = matlab.lang.makeValidName(char(string(fail_partition_table.dominant_fail_tag(k))));
    distribution.(key) = fail_partition_table.count(k);
end
end

function tag = local_pick_top_fail(fail_partition_table)
tag = "OK";
if ~isempty(fail_partition_table)
    tag = string(fail_partition_table.dominant_fail_tag(1));
end
end
