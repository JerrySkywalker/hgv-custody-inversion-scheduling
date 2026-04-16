function T = ch5r_backfill_suite_rmse_from_mat(T)
%CH5R_BACKFILL_SUITE_RMSE_FROM_MAT
% Backfill mean/final RMSE columns from per-case MAT files when suite CSV
% has NaN values.
%
% Robust behavior:
% 1) First try reading existing result.rX_tracking fields.
% 2) If missing (old MAT files), rebuild a minimal out_phase struct and
%    recompute true RMSE via replay helper.

if ~istable(T)
    error('Input must be a table.');
end

required_cols = {'method','mat_file','mean_rmse_pos_km','final_rmse_pos_km'};
for i = 1:numel(required_cols)
    assert(ismember(required_cols{i}, T.Properties.VariableNames), ...
        'Missing required column: %s', required_cols{i});
end

for i = 1:height(T)
    need_mean = ~isfinite(T.mean_rmse_pos_km(i));
    need_final = ~isfinite(T.final_rmse_pos_km(i));

    if ~(need_mean || need_final)
        continue;
    end

    method_tag = upper(char(string(T.method(i))));
    mat_file = char(string(T.mat_file(i)));

    if isempty(mat_file) || ~isfile(mat_file)
        continue;
    end

    try
        S = load(mat_file);
    catch
        warning('[ch5r_backfill_suite_rmse_from_mat] Failed to load MAT: %s', mat_file);
        continue;
    end

    % --------------------------------
    % path 1: read existing tracking fields
    % --------------------------------
    tracking = local_extract_tracking_from_loaded_struct(S, method_tag);

    if local_tracking_has_rmse(tracking)
        if need_mean
            T.mean_rmse_pos_km(i) = tracking.mean_rmse_pos_km;
        end
        if need_final
            T.final_rmse_pos_km(i) = tracking.final_rmse_pos_km;
        end
        continue;
    end

    % --------------------------------
    % path 2: recompute replay from old phase MAT
    % --------------------------------
    try
        out_phase = local_build_out_phase_from_loaded_struct(S, mat_file);

        if isempty(out_phase)
            continue;
        end

        [tracking2, ~] = ch5r_compute_true_rmse_replay(method_tag, out_phase, false, false);

        if local_tracking_has_rmse(tracking2)
            if need_mean
                T.mean_rmse_pos_km(i) = tracking2.mean_rmse_pos_km;
            end
            if need_final
                T.final_rmse_pos_km(i) = tracking2.final_rmse_pos_km;
            end
        end

    catch ME
        warning('[ch5r_backfill_suite_rmse_from_mat] Replay backfill failed for %s (%s): %s', ...
            method_tag, mat_file, ME.message);
    end
end
end

function tracking = local_extract_tracking_from_loaded_struct(S, method_tag)
tracking = struct();

if ~isfield(S, 'result') || ~isstruct(S.result)
    return;
end

switch method_tag
    case 'R4'
        if isfield(S.result, 'r4_tracking')
            tracking = S.result.r4_tracking;
        end
    case 'R5'
        if isfield(S.result, 'r5_tracking')
            tracking = S.result.r5_tracking;
        end
    case 'R9'
        if isfield(S.result, 'r9_tracking')
            tracking = S.result.r9_tracking;
        end
    case 'R10'
        if isfield(S.result, 'r10_tracking')
            tracking = S.result.r10_tracking;
        end
end
end

function tf = local_tracking_has_rmse(tracking)
tf = isstruct(tracking) && ...
     isfield(tracking, 'mean_rmse_pos_km') && ...
     isfield(tracking, 'final_rmse_pos_km') && ...
     isfinite(tracking.mean_rmse_pos_km) && ...
     isfinite(tracking.final_rmse_pos_km);
end

function out_phase = local_build_out_phase_from_loaded_struct(S, mat_file)
% Try to reconstruct the minimal struct expected by ch5r_compute_true_rmse_replay.
out_phase = [];

if ~isfield(S, 'cfg') || ~isfield(S, 'result')
    return;
end

% selection_trace is required by replay
if ~isfield(S, 'selection_trace')
    return;
end

% case may be stored as ch5case
if isfield(S, 'case') && isstruct(S.case)
    ch5case = S.case;
elseif isfield(S, 'ch5case') && isstruct(S.ch5case)
    ch5case = S.ch5case;
else
    return;
end

out_phase = struct();
out_phase.cfg = S.cfg;
out_phase.case = ch5case;
out_phase.selection_trace = S.selection_trace;
out_phase.result = S.result;
out_phase.paths = struct('mat_file', mat_file);
end
