function out = run_online_policy_from_pair_bank(cfg, ch5case, policy_name)
%RUN_ONLINE_POLICY_FROM_PAIR_BANK
% Online full-run skeleton for external policies on native pair_bank.
%
% Supported policy_name:
%   'pta'
%   'observability_family'
%   'danger_weighted_gain'

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

log_enable = true;
log_every_k = 10;
if isfield(cfg, 'r85f2') && isfield(cfg.r85f2, 'logging')
    if isfield(cfg.r85f2.logging, 'enable')
        log_enable = logical(cfg.r85f2.logging.enable);
    end
    if isfield(cfg.r85f2.logging, 'every_k')
        log_every_k = cfg.r85f2.logging.every_k;
    end
end

horizon_steps = 1;
if isfield(ch5case, 'window') && isfield(ch5case.window, 'length_steps')
    horizon_steps = ch5case.window.length_steps;
end

danger_opts = struct();
danger_opts.eta_switch = 500;
danger_opts.lookahead_steps = horizon_steps;
if isfield(cfg, 'r85f4a') && isfield(cfg.r85f4a, 'danger_weighted_gain')
    if isfield(cfg.r85f4a.danger_weighted_gain, 'eta_switch')
        danger_opts.eta_switch = cfg.r85f4a.danger_weighted_gain.eta_switch;
    end
    if isfield(cfg.r85f4a.danger_weighted_gain, 'lookahead_steps')
        danger_opts.lookahead_steps = cfg.r85f4a.danger_weighted_gain.lookahead_steps;
    end
end

selection_trace = cell(n_steps,1);
tic_all = tic;

if log_enable
    fprintf('[R8.5f.2][policy=%s] online full-run start: n_steps=%d horizon_steps=%d parallel=%s\n', ...
        policy_name, n_steps, horizon_steps, string(local_yesno(use_parallel)));
end

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
    rec.aux = [];

    if isempty(pairs_k)
        rec.mode = "empty";
        rec.stepTime = toc(t0);
        rec.elapsed = toc(tic_all);
        selection_trace{k} = rec;

        if log_enable && local_should_log_step(k, n_steps, log_every_k)
            fprintf('[R8.5f.2][policy=%s][k=%d/%d][empty] nPairs=0 stepTime=%.3fs elapsed=%.3fs parallel=%s\n', ...
                policy_name, k, n_steps, rec.stepTime, rec.elapsed, string(local_yesno(use_parallel)));
        end
        continue;
    end

    nPairs = size(pairs_k,1);
    scores = -inf(nPairs,1);
    J_pairs = cell(nPairs,1);
    AUX = cell(nPairs,1);

    selection_trace_prefix = selection_trace;

    if use_parallel && nPairs > 1 && ~strcmp(policy_name, 'danger_weighted_gain')
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
                case 'danger_weighted_gain'
                    [scores(idx), AUX{idx}] = score_pair_online_danger_weighted_gain( ...
                        ch5case, selection_trace_prefix, pair_bank, pair, k, danger_opts);
                    J_pairs{idx} = AUX{idx}.J_pair;
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
    rec.aux = AUX{best_idx};

    selection_trace{k} = rec;

    if log_enable && local_should_log_step(k, n_steps, log_every_k)
        fprintf('[R8.5f.2][policy=%s][k=%d/%d][select] nPairs=%d bestPair=[%d %d] score=%.6g stepTime=%.3fs elapsed=%.3fs parallel=%s\n', ...
            policy_name, k, n_steps, nPairs, rec.best_pair(1), rec.best_pair(2), ...
            rec.score, rec.stepTime, rec.elapsed, string(local_yesno(use_parallel && ~strcmp(policy_name, 'danger_weighted_gain'))));
    end
end

out = struct();
out.selection_trace = selection_trace;
out.summary = local_build_summary(selection_trace, policy_name, use_parallel && ~strcmp(policy_name, 'danger_weighted_gain'));

if log_enable
    fprintf('[R8.5f.2][policy=%s] online full-run done: mean_step_time=%.3fs max_step_time=%.3fs mean_nPairs=%.3f max_nPairs=%d parallel=%s\n', ...
        policy_name, out.summary.mean_step_time, out.summary.max_step_time, ...
        out.summary.mean_nPairs, out.summary.max_nPairs, string(local_yesno(out.summary.parallel_enabled)));
end
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

function tf = local_should_log_step(k, n_steps, every_k)
tf = (k == 1) || (k == n_steps) || (mod(k-1, every_k) == 0);
end

function s = local_yesno(tf)
if tf
    s = "yes";
else
    s = "no";
end
end
