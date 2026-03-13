function [summary_table, plane_table, lag_table] = summarize_stage10A_structure_stats(plane_pack, lag_pack, Wr_full, cfg)
%SUMMARIZE_STAGE10A_STRUCTURE_STATS
% Summarize truth-side structural diagnostics for one selected window.

    if nargin < 4
        cfg = default_params();
    end
    cfg = stage10A_prepare_cfg(cfg);

    P = plane_pack.P;
    epsH = cfg.stage10A.entropy_eps;

    plane_trace = plane_pack.plane_trace(:);
    plane_fro = plane_pack.plane_fro(:);
    meas_count = plane_pack.measurement_count_by_plane(:);
    active = plane_pack.active_plane_mask(:);

    total_trace = sum(plane_trace);
    total_meas = sum(meas_count);

    if total_trace > 0
        trace_share = plane_trace / total_trace;
    else
        trace_share = zeros(P,1);
    end

    if total_meas > 0
        meas_share = meas_count / total_meas;
    else
        meas_share = zeros(P,1);
    end

    % concentration / imbalance metrics
    active_ratio = nnz(active) / P;
    top1_trace_share = max(trace_share);
    top2_trace_share = sum(maxk(trace_share, min(2,P)));
    top3_trace_share = sum(maxk(trace_share, min(3,P)));

    % entropy normalized to [0,1] by log(P)
    if P > 1
        H_trace = -sum(trace_share .* log(trace_share + epsH)) / log(P);
        H_meas = -sum(meas_share .* log(meas_share + epsH)) / log(P);
    else
        H_trace = 0;
        H_meas = 0;
    end

    if mean(plane_trace) > 0
        cv_trace = std(plane_trace) / mean(plane_trace);
    else
        cv_trace = NaN;
    end

    if mean(meas_count) > 0
        cv_meas = std(meas_count) / mean(meas_count);
    else
        cv_meas = NaN;
    end

    % Anchor-relative lag summaries
    lag_trace_ref = lag_pack.lag_trace_ref(:);
    lag_trace_mean = lag_pack.lag_trace_active_mean(:);

    if sum(lag_trace_ref) > 0
        lag_trace_ref_share = lag_trace_ref / sum(lag_trace_ref);
    else
        lag_trace_ref_share = zeros(P,1);
    end
    if sum(lag_trace_mean) > 0
        lag_trace_mean_share = lag_trace_mean / sum(lag_trace_mean);
    else
        lag_trace_mean_share = zeros(P,1);
    end

    % A simple "cyclic dispersion" metric:
    % difference between anchor-relative lag profile and active-anchor mean profile.
    lag_profile_gap_l1 = sum(abs(lag_trace_ref_share - lag_trace_mean_share));
    lag_profile_gap_l2 = norm(lag_trace_ref_share - lag_trace_mean_share, 2);

    eig_full = sort(real(eig(0.5 * (Wr_full + Wr_full.'))), 'ascend');

    summary_table = table( ...
        P, nnz(active), active_ratio, ...
        total_meas, total_trace, ...
        max(plane_trace), min(plane_trace), mean(plane_trace), ...
        cv_trace, cv_meas, ...
        H_trace, H_meas, ...
        top1_trace_share, top2_trace_share, top3_trace_share, ...
        lag_pack.anchor_plane, lag_profile_gap_l1, lag_profile_gap_l2, ...
        eig_full(1), eig_full(2), eig_full(3), ...
        'VariableNames', { ...
            'P', 'n_active_plane', 'active_ratio', ...
            'measurement_count_total', 'trace_total', ...
            'trace_max', 'trace_min', 'trace_mean', ...
            'cv_trace', 'cv_meas', ...
            'entropy_trace_norm', 'entropy_meas_norm', ...
            'top1_trace_share', 'top2_trace_share', 'top3_trace_share', ...
            'anchor_plane', 'lag_profile_gap_l1', 'lag_profile_gap_l2', ...
            'lambda1_full', 'lambda2_full', 'lambda3_full'});

    plane_table = table( ...
        (1:P).', active, meas_count, plane_trace, plane_fro, trace_share, meas_share, ...
        'VariableNames', { ...
            'plane_id', 'active_flag', 'measurement_count', ...
            'trace_Wp', 'fro_Wp', 'trace_share', 'meas_share'});

    lag_table = table( ...
        lag_pack.lag_index, lag_pack.lag_plane_id_ref, ...
        lag_pack.lag_trace_ref, lag_pack.lag_fro_ref, ...
        lag_trace_ref_share, ...
        lag_pack.lag_trace_active_mean, lag_pack.lag_fro_active_mean, ...
        lag_trace_mean_share, ...
        'VariableNames', { ...
            'lag_index', 'plane_id_from_anchor', ...
            'lag_trace_ref', 'lag_fro_ref', 'lag_trace_ref_share', ...
            'lag_trace_active_mean', 'lag_fro_active_mean', 'lag_trace_active_mean_share'});
end