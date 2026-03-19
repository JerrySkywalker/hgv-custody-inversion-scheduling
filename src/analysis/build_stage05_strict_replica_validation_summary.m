function [validation_table, validation_meta] = build_stage05_strict_replica_validation_summary(strict_output, cfg, options)
%BUILD_STAGE05_STRICT_REPLICA_VALIDATION_SUMMARY Compare strict replica curves against original Stage05 curves.

if nargin < 2 || isempty(cfg)
    cfg = default_params();
end
if nargin < 3 || isempty(options)
    options = struct();
end

original_tol = local_getfield_or(options, 'validation_tol', 1e-12);
[original_out, original_meta] = local_load_or_run_original_stage05(options);
original_refs = load_stage05_reference_defaults(cfg);
original_eval_table = local_normalize_original_stage05_grid(original_out.grid);
original_envelope = build_mb_stage05_semantic_envelope(original_eval_table, original_refs.h_fixed_km, original_refs.inclination_grid_deg);

strict_runs = strict_output.runs;
validation_chunks = cell(numel(strict_runs), 1);
chunk_cursor = 0;

for idx = 1:numel(strict_runs)
    run = strict_runs(idx);
    strict_envelope = run.aggregate.dg_envelope(:, {'h_km', 'i_deg', 'Ns', 'max_pass_ratio'});
    strict_envelope = renamevars(strict_envelope, {'Ns', 'max_pass_ratio'}, {'Ns_grid', 'passratio_strictReplica'});

    original_same_height = original_envelope(original_envelope.h_km == run.h_km, {'h_km', 'i_deg', 'Ns', 'max_pass_ratio'});
    if isempty(original_same_height) && isscalar(unique(original_envelope.h_km))
        original_same_height = original_envelope(:, {'h_km', 'i_deg', 'Ns', 'max_pass_ratio'});
        original_same_height.h_km(:) = run.h_km;
    end
    original_same_height = renamevars(original_same_height, {'Ns', 'max_pass_ratio'}, {'Ns_grid', 'passratio_stage05_original'});

    merged = outerjoin(original_same_height, strict_envelope, ...
        'Keys', {'h_km', 'i_deg', 'Ns_grid'}, 'MergeKeys', true, 'Type', 'full');
    merged.passratio_stage05_original = local_fill_missing(merged.passratio_stage05_original);
    merged.passratio_strictReplica = local_fill_missing(merged.passratio_strictReplica);
    merged.abs_diff = abs(merged.passratio_stage05_original - merged.passratio_strictReplica);
    merged.height_km = merged.h_km;
    merged.inclination_deg = merged.i_deg;
    merged.max_abs_diff_over_curve = local_groupwise_max_abs_diff(merged);
    merged = movevars(merged, {'height_km', 'inclination_deg', 'Ns_grid', 'passratio_stage05_original', 'passratio_strictReplica', 'abs_diff', 'max_abs_diff_over_curve'}, 'Before', 1);
    merged = removevars(merged, {'h_km', 'i_deg'});
    chunk_cursor = chunk_cursor + 1;
    validation_chunks{chunk_cursor} = sortrows(merged, {'height_km', 'inclination_deg', 'Ns_grid'});
end

if chunk_cursor == 0
    validation_table = table();
else
    validation_table = vertcat(validation_chunks{1:chunk_cursor});
end

validation_meta = struct();
validation_meta.reference_output_file = string(local_getfield_or(original_meta, 'reference_output_file', ""));
validation_meta.reference_stage02_file = string(local_getfield_or(original_out, 'stage02_file', ""));
validation_meta.reference_stage04_file = string(local_getfield_or(original_out, 'stage04_file', ""));
validation_meta.reference_table_file = string(local_getfield_or(original_out, 'table_file', ""));
validation_meta.reference_feasible_table_file = string(local_getfield_or(original_out, 'feasible_table_file', ""));
validation_meta.max_abs_diff = local_table_max_or_zero(validation_table, 'abs_diff');
validation_meta.max_curve_abs_diff = local_table_max_or_zero(validation_table, 'max_abs_diff_over_curve');
validation_meta.validation_tol = original_tol;
validation_meta.validation_pass = validation_meta.max_curve_abs_diff <= original_tol;
validation_meta.reference_defaults_tag = string(original_refs.reference_tag);
end

function [out, meta] = local_load_or_run_original_stage05(options)
cfg_stage05 = default_params();
cfg_stage05.project_stage = 'stage05_nominal_walker_search';
cfg_stage05 = configure_stage_output_paths(cfg_stage05);
meta = struct('reference_output_file', "");

listing = find_stage_cache_files(cfg_stage05.paths.cache, 'stage05_nominal_walker_search_*.mat');
if isempty(listing) || logical(local_getfield_or(options, 'force_rebuild_original', false))
    out = stage05_nominal_walker_search(cfg_stage05, struct('disable_live_progress', true));
    if isfield(out, 'table_file')
        meta.reference_output_file = string(out.table_file);
    end
    return;
end

[~, idx_latest] = max([listing.datenum]);
reference_output_file = fullfile(listing(idx_latest).folder, listing(idx_latest).name);
loaded = load(reference_output_file);
if ~isfield(loaded, 'out')
    error('Latest Stage05 cache is invalid: missing out struct.');
end
out = loaded.out;
meta.reference_output_file = string(reference_output_file);
end

function eval_table = local_normalize_original_stage05_grid(grid_table)
eval_table = grid_table;
if ismember('feasible_flag', eval_table.Properties.VariableNames) && ~ismember('feasible', eval_table.Properties.VariableNames)
    eval_table = renamevars(eval_table, 'feasible_flag', 'feasible');
end
end

function data = local_fill_missing(data)
if isempty(data)
    return;
end
mask = isnan(data);
data(mask) = 0;
end

function max_diff = local_groupwise_max_abs_diff(T)
max_diff = zeros(height(T), 1);
keys = unique(T(:, {'height_km', 'inclination_deg'}), 'rows');
for idx = 1:height(keys)
    mask = T.height_km == keys.height_km(idx) & T.inclination_deg == keys.inclination_deg(idx);
    max_diff(mask) = max(T.abs_diff(mask), [], 'omitnan');
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function value = local_table_max_or_zero(T, field_name)
value = 0;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
x = T.(field_name);
x = x(isfinite(x));
if isempty(x)
    return;
end
value = max(x);
end
