function out = run_mb_semantic_dense_local(cfg, options)
%RUN_MB_SEMANTIC_DENSE_LOCAL Run local dense semantic comparison around the MB shell neighborhood.

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(options)
    options = struct();
end

sensor_group = char(string(local_getfield_or(options, 'sensor_group', 'baseline')));
family_set = local_resolve_family_set(local_getfield_or(options, 'family_set', {'nominal'}));
local_heights = reshape(local_getfield_or(options, 'dense_local_heights', [800, 850, 900, 950, 1000, 1050]), 1, []);
local_i_deg = reshape(local_getfield_or(options, 'dense_local_i_deg', 50:5:70), 1, []);
local_P = reshape(local_getfield_or(options, 'dense_local_P', 6:10), 1, []);
local_T = reshape(local_getfield_or(options, 'dense_local_T', [6, 8, 10, 12]), 1, []);
anchor_h_km = local_getfield_or(options, 'anchor_h_km', 1000);
F_fixed = local_getfield_or(options, 'F_fixed', 1);
use_parallel = logical(local_getfield_or(options, 'use_parallel', true));

common_options = struct( ...
    'sensor_group', sensor_group, ...
    'family_set', {family_set}, ...
    'heights_to_run', local_heights, ...
    'i_grid_deg', local_i_deg, ...
    'P_grid', local_P, ...
    'T_grid', local_T, ...
    'F_fixed', F_fixed, ...
    'use_parallel', use_parallel);

legacy_output = run_mb_legacydg_semantics(cfg, common_options);
closed_output = run_mb_closedd_semantics(cfg, common_options);
comparison = build_semantic_gap_tables(legacy_output, closed_output);

legacy_eval_table = local_vertcat_eval_tables(legacy_output.runs);
closed_eval_table = local_vertcat_eval_tables(closed_output.runs);

out = struct();
out.sensor_group = sensor_group;
out.family_set = {family_set};
out.local_heights = local_heights;
out.anchor_h_km = anchor_h_km;
out.legacy_output = legacy_output;
out.closed_output = closed_output;
out.comparison = comparison;
out.legacy_requirement_surface_hi = build_mb_requirement_surface(legacy_eval_table, 'i_deg', 'h_km');
out.closed_requirement_surface_hi = build_mb_requirement_surface(closed_eval_table, 'i_deg', 'h_km');
out.anchor_legacy_run = local_find_run_by_height(legacy_output.runs, anchor_h_km);
out.anchor_closed_run = local_find_run_by_height(closed_output.runs, anchor_h_km);
out.anchor_gap_pair = local_find_gap_pair(comparison.run_pairs, anchor_h_km);
out.summary = struct( ...
    'sensor_group', string(sensor_group), ...
    'family_name', string(family_set{1}), ...
    'anchor_h_km', anchor_h_km, ...
    'local_heights', local_heights, ...
    'local_i_deg', local_i_deg, ...
    'local_P', local_P, ...
    'local_T', local_T, ...
    'legacy_minimum_feasible_Ns_anchor', local_run_min(out.anchor_legacy_run), ...
    'closed_minimum_feasible_Ns_anchor', local_run_min(out.anchor_closed_run), ...
    'note', "Dense local refinement remains a discrete truth-field zoom around the semantic shell neighborhood. It is diagnostic, not a replacement for the global coarse semantic comparison.");
end

function eval_table = local_vertcat_eval_tables(run_bank)
tables = cell(numel(run_bank), 1);
cursor = 0;
for idx = 1:numel(run_bank)
    if isempty(run_bank(idx).eval_table)
        continue;
    end
    cursor = cursor + 1;
    tables{cursor} = run_bank(idx).eval_table;
end
tables = tables(1:cursor);
if isempty(tables)
    eval_table = table();
else
    eval_table = vertcat(tables{:});
end
end

function run = local_find_run_by_height(run_bank, h_km)
run = struct('h_km', h_km, 'aggregate', struct(), 'summary', struct(), 'eval_table', table(), 'feasible_table', table(), 'design_table', table(), 'family_name', "");
for idx = 1:numel(run_bank)
    if abs(run_bank(idx).h_km - h_km) < 1e-9
        run = run_bank(idx);
        return;
    end
end
end

function pair = local_find_gap_pair(run_pairs, h_km)
pair = struct('h_km', h_km, 'family_name', "", 'requirement_gap_table', table(), 'passratio_gap_table', table(), 'frontier_gap_table', table(), 'summary', struct());
for idx = 1:numel(run_pairs)
    if abs(run_pairs(idx).h_km - h_km) < 1e-9
        pair = run_pairs(idx);
        return;
    end
end
end

function value = local_run_min(run)
value = local_getfield_or(local_getfield_or(run, 'summary', struct()), 'minimum_feasible_Ns', missing);
end

function family_set = local_resolve_family_set(family_input)
tokens = cellstr(string(family_input));
tokens = cellfun(@(s) lower(strtrim(s)), tokens, 'UniformOutput', false);
if any(strcmp(tokens, 'all'))
    family_set = {'nominal', 'heading', 'critical'};
else
    family_set = unique(tokens, 'stable');
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
