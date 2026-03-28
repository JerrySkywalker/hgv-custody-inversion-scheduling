function out = manual_smoke_stage14_state_equivalence_A1_legacy_prepivot_20260329(cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%MANUAL_SMOKE_STAGE14_STATE_EQUIVALENCE_A1_LEGACY_PREPIVOT_20260329
% Stage14 旧版探索归档（原 Stage14.2D）:
% 诊断 A1 在 RAAN offset = 0° 与 45° 下的 full state set 等价性。
%
% A1:
%   h=1000, i=40, P=8, T=6, F=1, Ns=48
%
% 诊断层次：
%   1) plane-set equivalence        : 只看 RAAN 集合
%   2) state-tuple equivalence      : 看 (raan_deg, M0_deg) 集合
%   3) position-set equivalence t=0 : 看 t=0 时所有卫星惯性位置点集
%
% 输出：
%   out.summary
%   out.walker0
%   out.walker45
%   out.state_table0
%   out.state_table45
%   out.position_table0
%   out.position_table45
%   out.nn_table

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    % ------------------------------------------------------------
    % 1) 固定 A1 配置
    % ------------------------------------------------------------
    cfg.stage03.h_km = 1000;
    cfg.stage03.i_deg = 40;
    cfg.stage03.P = 8;
    cfg.stage03.T = 6;
    cfg.stage03.F = 1;

    if ~isfield(overrides, 'raan_offset_deg')
        overrides.raan_offset_deg = 45;
    end
    if ~isfield(overrides, 'time_s')
        overrides.time_s = 0;
    end
    raan_offset_deg = overrides.raan_offset_deg;
    t0_s = overrides.time_s;

    % ------------------------------------------------------------
    % 2) 生成 walker0 / walker45
    % ------------------------------------------------------------
    walker0 = build_single_layer_walker_stage03(cfg);
    walker45 = local_apply_raan_offset(walker0, raan_offset_deg);

    % ------------------------------------------------------------
    % 3) state tuple tables
    % ------------------------------------------------------------
    state_table0 = local_build_state_table(walker0);
    state_table45 = local_build_state_table(walker45);

    % RAAN 集合比较（plane-set）
    plane_set0 = unique(state_table0.raan_deg);
    plane_set45 = unique(state_table45.raan_deg);
    plane_set_diff = local_vec_max_abs_diff(sort(plane_set0), sort(plane_set45));

    % (RAAN, M0) 集合比较
    tuple_set0 = sortrows(state_table0(:, {'raan_deg','M0_deg'}), {'raan_deg','M0_deg'});
    tuple_set45 = sortrows(state_table45(:, {'raan_deg','M0_deg'}), {'raan_deg','M0_deg'});
    tuple_set_diff = local_max_abs_diff_2col(tuple_set0, tuple_set45);

    % ------------------------------------------------------------
    % 4) t=0 位置点集
    % ------------------------------------------------------------
    satbank0 = propagate_constellation_stage03(walker0, t0_s);
    satbank45 = propagate_constellation_stage03(walker45, t0_s);

    P0 = squeeze(satbank0.r_eci_km(1,:,:)).';
    P45 = squeeze(satbank45.r_eci_km(1,:,:)).';

    position_table0 = array2table(P0, 'VariableNames', {'x_km','y_km','z_km'});
    position_table45 = array2table(P45, 'VariableNames', {'x_km','y_km','z_km'});
    position_table0.sat_id = (1:height(position_table0)).';
    position_table45.sat_id = (1:height(position_table45)).';

    % 位置点集“是否只是置换”的检查：
    % 对 P0 中每个点，找 P45 中最近邻；再反向做一次
    [idx01, d01] = local_nearest_neighbor(P0, P45);
    [idx10, d10] = local_nearest_neighbor(P45, P0);

    nn_table = table( ...
        (1:size(P0,1)).', ...
        idx01(:), ...
        d01(:), ...
        idx10(:), ...
        d10(:), ...
        'VariableNames', {'sat_id_ref','nearest_in_rot','dist_ref_to_rot_km','nearest_in_ref','dist_rot_to_ref_km'});

    % 如果位置点集完全相同（只是置换），那么最近邻距离应接近 0
    max_nn_dist_ref_to_rot = max(d01);
    max_nn_dist_rot_to_ref = max(d10);

    % 再做一个“若把 45° 旋转当作空间刚体旋转”后的比较
    % 即把 P0 整体绕 z 轴转 45°，再与 P45 比较
    P0_rot = local_rotate_about_z(P0, raan_offset_deg);
    [idx_rot, d_rot] = local_nearest_neighbor(P0_rot, P45);
    max_nn_dist_after_rigid_rotation = max(d_rot);

    rigid_nn_table = table( ...
        (1:size(P0_rot,1)).', ...
        idx_rot(:), ...
        d_rot(:), ...
        'VariableNames', {'sat_id_ref','nearest_in_rot','dist_after_rigid_rotation_km'});

    % ------------------------------------------------------------
    % 5) 汇总
    % ------------------------------------------------------------
    summary = struct();
    summary.raan_offset_deg = raan_offset_deg;
    summary.time_s = t0_s;
    summary.Ns = walker0.Ns;
    summary.P = walker0.P;
    summary.T = walker0.T;
    summary.F = walker0.F;

    summary.plane_set_max_abs_diff_deg = plane_set_diff;
    summary.tuple_set_max_abs_diff = tuple_set_diff;

    summary.max_nn_dist_ref_to_rot_km = max_nn_dist_ref_to_rot;
    summary.max_nn_dist_rot_to_ref_km = max_nn_dist_rot_to_ref;
    summary.max_nn_dist_after_rigid_rotation_km = max_nn_dist_after_rigid_rotation;

    summary.is_plane_set_equivalent = plane_set_diff < 1e-12;
    summary.is_state_tuple_equivalent = tuple_set_diff < 1e-12;
    summary.is_position_set_equivalent = max(max_nn_dist_ref_to_rot, max_nn_dist_rot_to_ref) < 1e-9;
    summary.is_rigid_rotation_equivalent = max_nn_dist_after_rigid_rotation < 1e-9;

    out = struct();
    out.summary = summary;
    out.walker0 = walker0;
    out.walker45 = walker45;
    out.state_table0 = state_table0;
    out.state_table45 = state_table45;
    out.position_table0 = position_table0;
    out.position_table45 = position_table45;
    out.nn_table = nn_table;
    out.rigid_nn_table = rigid_nn_table;

    fprintf('\n=== Stage14 旧版探索归档（原 Stage14.2D） A1 State Equivalence Check ===\n');
    fprintf('RAAN offset deg                  : %.6f\n', summary.raan_offset_deg);
    fprintf('time_s                           : %.6f\n', summary.time_s);
    fprintf('Ns                               : %d\n', summary.Ns);
    fprintf('P,T,F                            : (%d,%d,%d)\n', summary.P, summary.T, summary.F);
    fprintf('\n');
    fprintf('plane_set_max_abs_diff_deg       : %.12g\n', summary.plane_set_max_abs_diff_deg);
    fprintf('tuple_set_max_abs_diff           : %.12g\n', summary.tuple_set_max_abs_diff);
    fprintf('max_nn_dist_ref_to_rot_km        : %.12g\n', summary.max_nn_dist_ref_to_rot_km);
    fprintf('max_nn_dist_rot_to_ref_km        : %.12g\n', summary.max_nn_dist_rot_to_ref_km);
    fprintf('max_nn_dist_after_rigid_rotation : %.12g\n', summary.max_nn_dist_after_rigid_rotation_km);
    fprintf('\n');
    fprintf('is_plane_set_equivalent          : %d\n', logical(summary.is_plane_set_equivalent));
    fprintf('is_state_tuple_equivalent        : %d\n', logical(summary.is_state_tuple_equivalent));
    fprintf('is_position_set_equivalent       : %d\n', logical(summary.is_position_set_equivalent));
    fprintf('is_rigid_rotation_equivalent     : %d\n\n', logical(summary.is_rigid_rotation_equivalent));

    fprintf('--- state_table0 (head) ---\n');
    disp(state_table0(1:min(16,height(state_table0)), :));

    fprintf('--- state_table45 (head) ---\n');
    disp(state_table45(1:min(16,height(state_table45)), :));

    fprintf('--- nn_table (head) ---\n');
    disp(nn_table(1:min(16,height(nn_table)), :));

    fprintf('--- rigid_nn_table (head) ---\n');
    disp(rigid_nn_table(1:min(16,height(rigid_nn_table)), :));
end

function walker2 = local_apply_raan_offset(walker, raan_offset_deg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    walker2 = walker;
    for k = 1:numel(walker2.sat)
        walker2.sat(k).raan_deg = mod(walker2.sat(k).raan_deg + raan_offset_deg, 360);
    end
end

function T = local_build_state_table(walker)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    Ns = walker.Ns;
    plane_id = zeros(Ns,1);
    sat_id_in_plane = zeros(Ns,1);
    raan_deg = zeros(Ns,1);
    M0_deg = zeros(Ns,1);

    for k = 1:Ns
        plane_id(k) = walker.sat(k).plane_id;
        sat_id_in_plane(k) = walker.sat(k).sat_id_in_plane;
        raan_deg(k) = mod(walker.sat(k).raan_deg, 360);
        M0_deg(k) = mod(walker.sat(k).M0_deg, 360);
    end

    T = table(plane_id, sat_id_in_plane, raan_deg, M0_deg);
end

function d = local_vec_max_abs_diff(a, b)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    assert(numel(a) == numel(b), 'Vector size mismatch.');
    d = max(abs(a(:) - b(:)));
end

function d = local_max_abs_diff_2col(T1, T2)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    assert(height(T1) == height(T2), 'Tuple height mismatch.');
    A = T1{:, :};
    B = T2{:, :};
    d = max(abs(A(:) - B(:)));
end

function [idx_nn, dist_nn] = local_nearest_neighbor(Pref, Ptest)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    n = size(Pref,1);
    m = size(Ptest,1);
    idx_nn = zeros(n,1);
    dist_nn = zeros(n,1);

    for i = 1:n
        pi = Pref(i,:);
        d2 = zeros(m,1);
        for j = 1:m
            diff = Ptest(j,:) - pi;
            d2(j) = sum(diff.^2);
        end
        [d2min, jmin] = min(d2);
        idx_nn(i) = jmin;
        dist_nn(i) = sqrt(d2min);
    end
end

function Prot = local_rotate_about_z(P, angle_deg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    a = deg2rad(angle_deg);
    Rz = [cos(a), -sin(a), 0;
          sin(a),  cos(a), 0;
          0,       0,      1];
    Prot = (Rz * P.').';
end

