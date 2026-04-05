function out = run_online_policy_from_pair_bank(cfg, ch5case, policy_name)
%RUN_ONLINE_POLICY_FROM_PAIR_BANK
% R8.5f.2 online full-run skeleton for external policies on native pair_bank.
%
% Outputs:
%   selection_trace{k}.best_pair / J_pair / score / nPairs / mode / stepTime

assert(isstruct(cfg), 'cfg must be struct.');
assert(isstruct(ch5case), 'ch5case must be struct.');
assert(ischar(policy_name) || isstring(policy_name), 'policy_name must be char or string.');

policy_name = char(string(policy_name));
pair_bank = ch5case.candidates.pair_bank;
n_steps = numel(pair_bank);

use_parallel = false;
if isfield(cfg, 'r85f2') && isfield(cfg.r85f2, 'parallel') && isfield(cfg.r85f2.parallel, 'enable')
    use_parallel = logical(cfg.r85f2.parallel.enable);
end

horizon_steps = 1;
if isfield(ch5case, 'window') && isfield(ch5case.window, 'length_steps')
    horizon_steps = ch5case.window.length_steps;
end

selection_trace = cell(n_steps,1);
tic_all = tic;

for k = 1:n_steps
    pairs_k = pair_bank{k};
    t0 = tic;

    rec = struct();
    rec.step_index = k;
    rec.policy = string(policy_name);
    rec.mode = "select";
    rec.nPairs = size(pairs_k,1);
    rec.best_pair = [];
    rec.J_pair = [];
    rec.score = NaN;
    rec.stepTime = NaN;
    rec.elapsed = NaN;

    if isempty(pairs_k)
        rec.mode = "empty";
        rec.stepTime = toc(t0);
        rec.elapsed = toc(tic_all);
        selection_trace{k} = rec;
        continue;
    end

    nPairs = size(pairs_k,1);
    scores = -inf(nPairs,1);
    J_pairs = cell(nPairs,1);

    if use_parallel && nPairs > 1
        parfor idx = 1:nPairs
            pair = pairs_k(idx,:);
            switch policy_name
                case 'pta'
                    scores(idx) = score_pair_online_pta(ch5case, pair_bank, pair, k, horizon_steps);
                    [~, J_pairs{idx}] = score_pair_online_observability_family(ch5case, pair, k);
                case 'observability_family'
                    [scores(idx), J_pairs{idx}] = score_pair_online_observability_family(ch5case, pair, k);
                otherwise
                    error('Unsupported policy_name: %s', policy_name);
            end
        end
    else
        for idx = 1:nPairs
            pair = pairs_k(idx,:);
            switch policy_name
                case 'pta'
                    scores(idx) = score_pair_online_pta(ch5case, pair_bank, pair, k, horizon_steps);
                    [~, J_pairs{idx}] = score_pair_online_observability_family(ch5case, pair, k);
                case 'observability_family'
                    [scores(idx), J_pairs{idx}] = score_pair_online_observability_family(ch5case, pair, k);
                otherwise
                    error('Unsupported policy_name: %s', policy_name);
            end
        end
    end

    [best_score, best_idx] = max(scores);
    rec.best_pair = pairs_k(best_idx,:);
    rec.J_pair = J_pairs{best_idx};
    rec.score = best_score;
    rec.stepTime = toc(t0);
    rec.elapsed = toc(tic_all);

    selection_trace{k} = rec;
end

out = struct();
out.selection_trace = selection_trace;
out.summary = local_build_summary(selection_trace, policy_name, use_parallel);
end

function summary = local_build_summary(selection_trace, policy_name, use_parallel)
n_steps = numel(selection_trace);
n_empty = 0;
step_times = zeros(n_steps,1);
nPairs_series = zeros(n_steps,1);

for k = 1:n_steps
    rec = selection_trace{k};
    step_times(k) = rec.stepTime;
    nPairs_series(k) = rec.nPairs;
    if rec.mode == "empty"
        n_empty = n_empty + 1;
    end
end

summary = struct();
summary.policy = string(policy_name);
summary.n_steps = n_steps;
summary.n_empty_steps = n_empty;
summary.mean_step_time = mean(step_times);
summary.max_step_time = max(step_times);
summary.mean_nPairs = mean(nPairs_series);
summary.max_nPairs = max(nPairs_series);
summary.parallel_enabled = use_parallel;
end
