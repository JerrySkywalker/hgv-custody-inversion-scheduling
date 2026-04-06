function sel = select_pair_r10_li_interval(cfg, ch5case, k0, x_pred, model)
%SELECT_PAIR_R10_LI_INTERVAL
% Li-style interval relay scheduler:
% 1) coarse selection by interval visibility support
% 2) refined selection by interval logdet(Y)

Nt = numel(ch5case.t_s);
k1 = min(k0 + cfg.ch5r.r10.interval_steps - 1, Nt);

% build union candidate set over the interval
pair_all = [];
for k = k0:k1
    pk = ch5case.candidates.pair_bank{k};
    if ~isempty(pk)
        pair_all = [pair_all; pk]; %#ok<AGROW>
    end
end

if isempty(pair_all)
    error('No candidate pairs found in interval [%d,%d].', k0, k1);
end

pair_all = unique(pair_all, 'rows');

scores = cell(size(pair_all,1),1);
support_ratio = zeros(size(pair_all,1),1);
support_steps = zeros(size(pair_all,1),1);
logdetY = -inf(size(pair_all,1),1);

for i = 1:size(pair_all,1)
    s = score_pair_interval_detY_r10(cfg, ch5case, k0, k1, pair_all(i,:), x_pred, model);
    scores{i} = s;
    support_ratio(i) = s.support_ratio;
    support_steps(i) = s.support_steps;
    logdetY(i) = s.logdetY;
end

nSteps = k1 - k0 + 1;
full_idx = find(support_steps == nSteps);

if ~isempty(full_idx)
    coarse_idx = full_idx;
    coarse_mode = 'full_support';
else
    coarse_idx = find(support_ratio >= cfg.ch5r.r10.min_support_ratio);
    if isempty(coarse_idx)
        [~, coarse_idx] = max(support_steps);
        coarse_mode = 'max_support_fallback';
    else
        coarse_mode = 'ratio_support_fallback';
    end
end

[~, rel_idx] = max(logdetY(coarse_idx));
best_idx = coarse_idx(rel_idx);
best = scores{best_idx};

sel = struct();
sel.k0 = k0;
sel.k1 = k1;
sel.pair = best.pair;
sel.score = best.logdetY;
sel.support_steps = best.support_steps;
sel.support_ratio = best.support_ratio;
sel.coarse_mode = coarse_mode;
sel.name = 'r10_li_interval_pair';
sel.Y_interval = best.Y_interval;
sel.candidate_count = size(pair_all,1);
sel.coarse_count = numel(coarse_idx);
end
