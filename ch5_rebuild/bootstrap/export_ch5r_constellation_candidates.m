function out = export_ch5r_constellation_candidates(opts)
%EXPORT_CH5R_CONSTELLATION_CANDIDATES
% Export Top-K constellation candidates for Chapter 5 based on Stage05 tables.
%
% This function is deliberately light-touch:
% - it does NOT modify any Phase runner
% - it only reads current Stage05 tables / R0 bootstrap outputs
% - it produces a candidate table for theta_star / theta_plus selection

if nargin < 1 || isempty(opts)
    opts = struct();
end

startup('force', true);

opts = local_apply_defaults(opts);

project_root = pwd;
stage05_tables_dir = fullfile(project_root, 'outputs', 'stage', 'stage05', 'tables');
out_dir = fullfile(project_root, 'outputs', 'ch5_rebuild', 'phaseR0_bootstrap');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

r0 = run_ch5r_phase0_bootstrap_smoke();
bundle = r0.bundle;

feasible_csv = local_find_latest_file(stage05_tables_dir, 'stage05_feasible_sorted_*.csv');
if isempty(feasible_csv)
    error('[ch5r:candidates] No stage05_feasible_sorted_*.csv found in %s', stage05_tables_dir);
end

T = readtable(feasible_csv);
T = local_normalize_candidate_table(T);

if opts.pass_ratio_eq_one_only
    T = T(T.pass_ratio >= 1 - 1e-12, :);
end

T = sortrows(T, {'Ns','DG','pass_ratio'}, {'ascend','descend','descend'});
T.rank = transpose(1:height(T));
T = movevars(T, 'rank', 'Before', 1);

if height(T) == 0
    error('[ch5r:candidates] Candidate table is empty after filtering.');
end

topK = min(opts.top_k, height(T));
star_candidates = T(1:topK, :);

plus_candidates = T;
if ~isempty(opts.exclude_same_as_star_default)
    star_default = local_struct_to_signature(bundle.theta_star);
    keep_mask = true(height(plus_candidates),1);
    for i = 1:height(plus_candidates)
        sig_i = local_row_to_signature(plus_candidates(i,:));
        if strcmp(sig_i, star_default)
            keep_mask(i) = false;
        end
    end
    plus_candidates = plus_candidates(keep_mask,:);
end
topK_plus = min(opts.top_k, height(plus_candidates));
plus_candidates = plus_candidates(1:topK_plus, :);

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
star_csv = fullfile(out_dir, ['ch5r_theta_star_candidates_' stamp '.csv']);
plus_csv = fullfile(out_dir, ['ch5r_theta_plus_candidates_' stamp '.csv']);
writetable(star_candidates, star_csv);
writetable(plus_candidates, plus_csv);

disp(' ')
disp('=== [ch5r:candidates] export summary ===')
disp(['stage05 feasible csv : ' feasible_csv])
disp(['star candidate csv   : ' star_csv])
disp(['plus candidate csv   : ' plus_csv])
disp(['candidate count      : ' num2str(height(T))])
disp(['topK exported        : ' num2str(topK)])

disp('--- theta_star candidates ---')
disp(star_candidates(:, {'rank','h_km','i_deg','P','T','F','Ns','DG','pass_ratio'}))

disp('--- theta_plus candidates ---')
disp(plus_candidates(:, {'rank','h_km','i_deg','P','T','F','Ns','DG','pass_ratio'}))

out = struct();
out.ok = true;
out.r0 = r0;
out.bundle = bundle;
out.stage05_feasible_csv = feasible_csv;
out.star_candidates = star_candidates;
out.plus_candidates = plus_candidates;
out.paths = struct( ...
    'star_csv', star_csv, ...
    'plus_csv', plus_csv, ...
    'output_dir', out_dir);
end

function opts = local_apply_defaults(opts)
if ~isfield(opts, 'top_k') || isempty(opts.top_k)
    opts.top_k = 5;
end
if ~isfield(opts, 'pass_ratio_eq_one_only') || isempty(opts.pass_ratio_eq_one_only)
    opts.pass_ratio_eq_one_only = true;
end
if ~isfield(opts, 'exclude_same_as_star_default') || isempty(opts.exclude_same_as_star_default)
    opts.exclude_same_as_star_default = true;
end
end

function T = local_normalize_candidate_table(T)
T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames, 'ReplacementStyle', 'delete');

T.h_km = local_pick_numeric_column(T, {'h_km','hFixedKm','h'});
T.i_deg = local_pick_numeric_column(T, {'i_deg','i','inc_deg','inclination_deg'});
T.P = local_pick_numeric_column(T, {'P'});
T.T = local_pick_numeric_column(T, {'T'});
T.F = local_pick_numeric_column(T, {'F'}, 1);
T.Ns = local_pick_numeric_column(T, {'Ns','N_s','satellite_count'});
T.DG = local_pick_numeric_column(T, {'D_G_min','DG','best_DG','metric_DG'});
T.pass_ratio = local_pick_numeric_column(T, {'pass_ratio','passRate','feasible_ratio'}, 1);

T = T(:, {'h_km','i_deg','P','T','F','Ns','DG','pass_ratio'});
end

function v = local_pick_numeric_column(T, candidates, default_value)
if nargin < 3
    default_value = [];
end

for i = 1:numel(candidates)
    c = candidates{i};
    idx = find(strcmpi(T.Properties.VariableNames, c), 1);
    if ~isempty(idx)
        v = T{:, idx};
        return;
    end
end

if isempty(default_value)
    error('[ch5r:candidates] Required column missing. Tried: %s', strjoin(candidates, ', '));
end

v = repmat(default_value, height(T), 1);
end

function file_path = local_find_latest_file(folder_path, pattern)
S = dir(fullfile(folder_path, pattern));
if isempty(S)
    file_path = '';
    return;
end
[~, idx] = max([S.datenum]);
file_path = fullfile(folder_path, S(idx).name);
end

function sig = local_struct_to_signature(S)
sig = sprintf('h=%g|i=%g|P=%g|T=%g|F=%g|Ns=%g', ...
    local_get_struct_field(S, 'h_km', NaN), ...
    local_get_struct_field(S, 'i_deg', NaN), ...
    local_get_struct_field(S, 'P', NaN), ...
    local_get_struct_field(S, 'T', NaN), ...
    local_get_struct_field(S, 'F', NaN), ...
    local_get_struct_field(S, 'Ns', NaN));
end

function sig = local_row_to_signature(Trow)
sig = sprintf('h=%g|i=%g|P=%g|T=%g|F=%g|Ns=%g', ...
    Trow.h_km(1), Trow.i_deg(1), Trow.P(1), Trow.T(1), Trow.F(1), Trow.Ns(1));
end

function v = local_get_struct_field(S, name, default_value)
if isstruct(S) && isfield(S, name)
    v = S.(name);
else
    v = default_value;
end
end
