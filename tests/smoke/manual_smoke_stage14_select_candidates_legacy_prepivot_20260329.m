function out = manual_smoke_stage14_select_candidates_legacy_prepivot_20260329(cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%MANUAL_SMOKE_STAGE14_SELECT_CANDIDATES_LEGACY_PREPIVOT_20260329
% Stage14 旧版探索归档（原 Stage14.1D）:
% 从最新 Stage05 cache 中筛选适合做 Stage14 RAAN sweep 的候选设计点。
%
% 当前目标：
%   1) 不改主链；
%   2) 不画图；
%   3) 直接基于 Stage05 grid / feasible_table / frontier_table 做设计点筛选；
%   4) 输出若干候选表，供后续 Stage14 旧版探索归档（原 Stage14.1C） / 14.2 使用。
%
% 候选点类别：
%   A. infeasible but closest-to-threshold by D_G_min
%   B. top by D_G_mean
%   C. frontier / best_table based candidates
%   D. same Ns with multiple (P,T)
%
% 输出：
%   out.summary
%   out.grid
%   out.candidates
%
% 使用方式：
%   out = manual_smoke_stage14_select_candidates();
%   disp(out.candidates.closest_by_DGmin)
%   disp(out.candidates.top_by_DGmean)
%   disp(out.candidates.sameNs_multiPT)

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    % ------------------------------------------------------------
    % 1) 参数
    % ------------------------------------------------------------
    if ~isfield(overrides, 'topk')
        overrides.topk = 10;
    end
    if ~isfield(overrides, 'sameNs_topk')
        overrides.sameNs_topk = 20;
    end
    if ~isfield(overrides, 'Ns_focus')
        overrides.Ns_focus = [];
    end

    % ------------------------------------------------------------
    % 2) 读取最新 Stage05 cache
    % ------------------------------------------------------------
    d5 = find_stage_cache_files(cfg.paths.cache, 'stage05_nominal_walker_search_*.mat');
    assert(~isempty(d5), 'No Stage05 cache found. Please run stage05_nominal_walker_search first.');

    [~, idx5] = max([d5.datenum]);
    stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);
    S5 = load(stage05_file);

    assert(isfield(S5, 'out'), 'Invalid Stage05 cache: missing out');
    assert(isfield(S5.out, 'grid'), 'Stage05 cache missing out.grid');

    grid = S5.out.grid;

    % 兼容后续绘图/分析阶段存下来的 table
    feasible_table = table();
    frontier_table = table();
    best_table = table();

    if isfield(S5.out, 'feasible_table')
        feasible_table = S5.out.feasible_table;
    end
    if isfield(S5.out, 'frontier_table')
        frontier_table = S5.out.frontier_table;
    end
    if isfield(S5.out, 'best_table')
        best_table = S5.out.best_table;
    end

    % 必要列检查
    must_have = {'h_km','i_deg','P','T','F','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag','rank_score'};
    for k = 1:numel(must_have)
        assert(ismember(must_have{k}, grid.Properties.VariableNames), ...
            'Stage05 grid missing column: %s', must_have{k});
    end

    % ------------------------------------------------------------
    % 3) 基础清洗
    % ------------------------------------------------------------
    G = grid;
    G = G(isfinite(G.D_G_min) & isfinite(G.D_G_mean) & isfinite(G.pass_ratio), :);
    G = sortrows(G, {'Ns','i_deg','P','T'});

    % 仅保留“单层静态搜索”的主列，便于后续 sweep 直接拿来用
    core_cols = intersect({'h_km','i_deg','P','T','F','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag','rank_score'}, ...
                          G.Properties.VariableNames, 'stable');
    Gcore = G(:, core_cols);

    % ------------------------------------------------------------
    % 4) 候选 A：最接近阈值的不可行点（按 D_G_min 降序）
    % ------------------------------------------------------------
    A = Gcore(~Gcore.feasible_flag, :);
    A = sortrows(A, {'D_G_min','D_G_mean','pass_ratio','Ns'}, {'descend','descend','descend','ascend'});
    A = local_take_topk(A, overrides.topk);

    % ------------------------------------------------------------
    % 5) 候选 B：按 D_G_mean 排前的不可行点
    % ------------------------------------------------------------
    B = Gcore(~Gcore.feasible_flag, :);
    B = sortrows(B, {'D_G_mean','D_G_min','pass_ratio','Ns'}, {'descend','descend','descend','ascend'});
    B = local_take_topk(B, overrides.topk);

    % ------------------------------------------------------------
    % 6) 候选 C：如果有 frontier/best_table，则直接保留其核心列
    % ------------------------------------------------------------
    C_frontier = local_reduce_optional_table(frontier_table);
    C_best = local_reduce_optional_table(best_table);
    C_feasible = local_reduce_optional_table(feasible_table);

    % ------------------------------------------------------------
    % 7) 候选 D：同一 Ns 下存在多个 (P,T) 的点
    % 目的：后续同 Ns 比较不同构型的 RAAN 敏感性
    % 规则：
    %   - 先按 Ns 分组
    %   - 找出 n_unique_PT >= 2 的 Ns
    %   - 每个 Ns 内按 D_G_mean 降序取若干代表点
    % ------------------------------------------------------------
    D = table();
    unique_Ns = unique(Gcore.Ns);

    rowsD = cell(0,1);
    for ii = 1:numel(unique_Ns)
        Ns0 = unique_Ns(ii);
        if ~isempty(overrides.Ns_focus) && ~ismember(Ns0, overrides.Ns_focus)
            continue;
        end

        sub = Gcore(Gcore.Ns == Ns0, :);
        if isempty(sub)
            continue;
        end

        pt_pairs = unique([sub.P, sub.T], 'rows');
        if size(pt_pairs,1) < 2
            continue;
        end

        sub = sortrows(sub, {'D_G_mean','D_G_min','pass_ratio'}, {'descend','descend','descend'});
        n_take = min(height(sub), overrides.sameNs_topk);
        sub = sub(1:n_take, :);

        tag = repmat("sameNs_multiPT", height(sub), 1);
        sub.tag = tag;
        D = [D; sub]; %#ok<AGROW>
    end

    if ~isempty(D)
        D = sortrows(D, {'Ns','D_G_mean','D_G_min'}, {'ascend','descend','descend'});
    end

    % ------------------------------------------------------------
    % 8) 候选 E：每个 Ns 选一个“最接近边界”的点
    % 规则：不可行点中，按 D_G_min 最大者选
    % ------------------------------------------------------------
    E = table();
    for ii = 1:numel(unique_Ns)
        Ns0 = unique_Ns(ii);
        sub = Gcore(Gcore.Ns == Ns0 & ~Gcore.feasible_flag, :);
        if isempty(sub)
            continue;
        end

        sub = sortrows(sub, {'D_G_min','D_G_mean','pass_ratio'}, {'descend','descend','descend'});
        best_row = sub(1,:);
        E = [E; best_row]; %#ok<AGROW>
    end

    if ~isempty(E)
        E = sortrows(E, {'Ns','D_G_min','D_G_mean'}, {'ascend','descend','descend'});
    end

    % ------------------------------------------------------------
    % 9) 汇总
    % ------------------------------------------------------------
    summary = struct();
    summary.stage05_file = stage05_file;
    summary.n_grid = height(grid);
    summary.n_grid_valid = height(Gcore);
    summary.n_feasible = sum(Gcore.feasible_flag);
    summary.n_infeasible = sum(~Gcore.feasible_flag);
    summary.unique_Ns = unique(Gcore.Ns).';
    summary.topk = overrides.topk;
    summary.sameNs_topk = overrides.sameNs_topk;

    candidates = struct();
    candidates.closest_by_DGmin = A;
    candidates.top_by_DGmean = B;
    candidates.frontier = C_frontier;
    candidates.best = C_best;
    candidates.feasible = C_feasible;
    candidates.sameNs_multiPT = D;
    candidates.best_per_Ns = E;

    out = struct();
    out.summary = summary;
    out.grid = Gcore;
    out.candidates = candidates;

    fprintf('\n=== Stage14 旧版探索归档（原 Stage14.1D） Candidate Selection from Stage05 ===\n');
    fprintf('Stage05 cache   : %s\n', stage05_file);
    fprintf('n_grid          : %d\n', summary.n_grid);
    fprintf('n_grid_valid    : %d\n', summary.n_grid_valid);
    fprintf('n_feasible      : %d\n', summary.n_feasible);
    fprintf('n_infeasible    : %d\n', summary.n_infeasible);
    fprintf('unique Ns count : %d\n', numel(summary.unique_Ns));
    fprintf('topk            : %d\n', summary.topk);
    fprintf('sameNs_topk     : %d\n\n', summary.sameNs_topk);

    fprintf('--- closest_by_DGmin ---\n');
    disp(local_pretty_head(A, min(10,height(A))));

    fprintf('--- top_by_DGmean ---\n');
    disp(local_pretty_head(B, min(10,height(B))));

    fprintf('--- best_per_Ns ---\n');
    disp(local_pretty_head(E, min(15,height(E))));

    if ~isempty(D)
        fprintf('--- sameNs_multiPT ---\n');
        disp(local_pretty_head(D, min(20,height(D))));
    end
end

function T = local_take_topk(T, k)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    if isempty(T)
        return;
    end
    T = T(1:min(k,height(T)), :);
end

function Tred = local_reduce_optional_table(T)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    if isempty(T) || ~istable(T)
        Tred = table();
        return;
    end

    keep = intersect({'h_km','i_deg','P','T','F','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag','rank_score'}, ...
                     T.Properties.VariableNames, 'stable');
    if isempty(keep)
        Tred = T;
    else
        Tred = T(:, keep);
    end
end

function Tout = local_pretty_head(T, n)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    if isempty(T)
        Tout = T;
        return;
    end

    keep = intersect({'h_km','i_deg','P','T','F','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag','rank_score'}, ...
                     T.Properties.VariableNames, 'stable');
    Tout = T(1:min(n,height(T)), keep);
end

