function out = manual_smoke_stage14_los_matrix_compare_A1_legacy_prepivot_20260329(cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%MANUAL_SMOKE_STAGE14_LOS_MATRIX_COMPARE_A1_LEGACY_PREPIVOT_20260329
% Stage14 旧版探索归档（原 Stage14.2E）:
% 对 A1 在 RAAN offset = 0° / 45° 下做单时刻 LOS 与信息矩阵对比。
%
% 目标：
%   1) 固定一个 nominal case
%   2) 固定一个时刻
%   3) 比较 visible set / LOS unit vectors / single-time information matrix
%
% 默认：
%   - A1: h=1000, i=40, P=8, T=6, F=1
%   - 使用 nominal family 中第 1 个 case
%   - 使用 t = 0 s
%
% 输出：
%   out.summary
%   out.visible_table0
%   out.visible_table45
%   out.W0
%   out.W45
%   out.eig0
%   out.eig45

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    if ~isfield(overrides, 'raan_offset_deg')
        overrides.raan_offset_deg = 45;
    end
    if ~isfield(overrides, 'case_index')
        overrides.case_index = 1;
    end
    if ~isfield(overrides, 'time_s')
        overrides.time_s = 0;
    end

    raan_offset_deg = overrides.raan_offset_deg;
    case_index = overrides.case_index;
    time_s = overrides.time_s;

    % ------------------------------------------------------------
    % 1) 固定 A1 构型
    % ------------------------------------------------------------
    cfg.stage03.h_km = 1000;
    cfg.stage03.i_deg = 40;
    cfg.stage03.P = 8;
    cfg.stage03.T = 6;
    cfg.stage03.F = 1;

    % ------------------------------------------------------------
    % 2) 读取 Stage02 nominal family
    % ------------------------------------------------------------
    d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
    assert(~isempty(d2), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

    [~, idx2] = max([d2.datenum]);
    stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
    S2 = load(stage02_file);
    assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
        'Invalid Stage02 cache: missing out.trajbank.nominal');

    trajs_nominal = S2.out.trajbank.nominal;
    assert(case_index >= 1 && case_index <= numel(trajs_nominal), 'case_index out of range.');

    traj_case = trajs_nominal(case_index);
    case_id = string(traj_case.case.case_id);

    % ------------------------------------------------------------
    % 3) 构造 0° / 45° 两个星座并传播到指定时刻
    % ------------------------------------------------------------
    walker0 = build_single_layer_walker_stage03(cfg);
    walker45 = local_apply_raan_offset(walker0, raan_offset_deg);

    satbank0 = propagate_constellation_stage03(walker0, time_s);
    satbank45 = propagate_constellation_stage03(walker45, time_s);

    % ------------------------------------------------------------
    % 4) 目标状态插值到指定时刻
    % ------------------------------------------------------------
    rtgt_km = local_interp_target_position(traj_case, time_s);

    % ------------------------------------------------------------
    % 5) 计算可见集与 LOS 单位向量 + 单时刻信息矩阵
    %    这里直接复用 is_visible_stage03，保证与当前工程口径一致
    % ------------------------------------------------------------
    [visible_table0, W0] = local_build_visible_table_and_W(rtgt_km, satbank0, cfg);
    [visible_table45, W45] = local_build_visible_table_and_W(rtgt_km, satbank45, cfg);

    eig0 = sort(eig(W0), 'ascend');
    eig45 = sort(eig(W45), 'ascend');

    % ------------------------------------------------------------
    % 6) 汇总
    % ------------------------------------------------------------
    summary = struct();
    summary.stage02_file = stage02_file;
    summary.case_index = case_index;
    summary.case_id = case_id;
    summary.time_s = time_s;
    summary.raan_offset_deg = raan_offset_deg;

    summary.num_visible_0 = height(visible_table0);
    summary.num_visible_45 = height(visible_table45);

    summary.W0 = W0;
    summary.W45 = W45;
    summary.eig0 = eig0;
    summary.eig45 = eig45;

    summary.lambda_min_0 = eig0(1);
    summary.lambda_min_45 = eig45(1);
    summary.lambda_min_diff = eig45(1) - eig0(1);

    summary.fro_diff_W = norm(W45 - W0, 'fro');

    out = struct();
    out.summary = summary;
    out.visible_table0 = visible_table0;
    out.visible_table45 = visible_table45;
    out.W0 = W0;
    out.W45 = W45;
    out.eig0 = eig0;
    out.eig45 = eig45;

    fprintf('\n=== Stage14 旧版探索归档（原 Stage14.2E） A1 LOS / W_t Compare ===\n');
    fprintf('Stage02 cache      : %s\n', stage02_file);
    fprintf('case_index         : %d\n', case_index);
    fprintf('case_id            : %s\n', case_id);
    fprintf('time_s             : %.6f\n', time_s);
    fprintf('raan_offset_deg    : %.6f\n', raan_offset_deg);
    fprintf('\n');
    fprintf('num_visible_0      : %d\n', summary.num_visible_0);
    fprintf('num_visible_45     : %d\n', summary.num_visible_45);
    fprintf('lambda_min_0       : %.12g\n', summary.lambda_min_0);
    fprintf('lambda_min_45      : %.12g\n', summary.lambda_min_45);
    fprintf('lambda_min_diff    : %.12g\n', summary.lambda_min_diff);
    fprintf('fro_diff_W         : %.12g\n\n', summary.fro_diff_W);

    fprintf('--- eig0 ---\n');
    disp(eig0.');

    fprintf('--- eig45 ---\n');
    disp(eig45.');

    fprintf('--- visible_table0 (head) ---\n');
    disp(visible_table0(1:min(16,height(visible_table0)), :));

    fprintf('--- visible_table45 (head) ---\n');
    disp(visible_table45(1:min(16,height(visible_table45)), :));
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

function rtgt_km = local_interp_target_position(traj_case, time_s)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    t = traj_case.traj.t_s(:);
    r = traj_case.traj.r_eci_km;

    x = interp1(t, r(:,1), time_s, 'linear', 'extrap');
    y = interp1(t, r(:,2), time_s, 'linear', 'extrap');
    z = interp1(t, r(:,3), time_s, 'linear', 'extrap');
    rtgt_km = [x, y, z];
end

function [visible_table, W] = local_build_visible_table_and_W(rtgt_km, satbank, cfg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    % satbank.r_eci_km: Nt x 3 x Ns；当前这里只传单时刻
    rsat = squeeze(satbank.r_eci_km(1,:,:)).';   % Ns x 3
    Ns = size(rsat,1);

    sat_id = (1:Ns).';
    visible = false(Ns,1);
    range_km = nan(Ns,1);
    los_ux = nan(Ns,1);
    los_uy = nan(Ns,1);
    los_uz = nan(Ns,1);

    W = zeros(3,3);

    for k = 1:Ns
        r_sat_km = rsat(k,:);
        tf = is_visible_stage03(r_sat_km, rtgt_km, cfg);

        % 与 Stage03 口径保持一致：LOS 方向取 target - sat
        los_km = rtgt_km - r_sat_km;
        rho = norm(los_km);
        u = los_km / max(rho, eps);

        visible(k) = tf;
        range_km(k) = rho;
        los_ux(k) = u(1);
        los_uy(k) = u(2);
        los_uz(k) = u(3);

        if tf
            % 几何型单时刻信息矩阵近似：
            % H = I - u u^T
            Hk = eye(3) - (u(:) * u(:).');
            W = W + Hk;
        end
    end

    visible_table = table(sat_id, visible, range_km, los_ux, los_uy, los_uz);
    visible_table = visible_table(visible_table.visible, :);
end

