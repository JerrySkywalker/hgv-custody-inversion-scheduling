function tbl = build_candidate_score_table_at_step(ch5case, selection_trace_prefix, step_index, danger_opts)
%BUILD_CANDIDATE_SCORE_TABLE_AT_STEP
% R8X.2:
%   Build candidate score table at one step under shared pair_bank.

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace_prefix), 'selection_trace_prefix must be cell.');
assert(isnumeric(step_index) && isscalar(step_index), 'step_index invalid.');

if nargin < 4 || isempty(danger_opts)
    danger_opts = struct();
end

assert(isfield(ch5case, 'candidates') && isfield(ch5case.candidates, 'pair_bank'), 'pair_bank missing.');
pair_bank = ch5case.candidates.pair_bank;
assert(step_index >= 1 && step_index <= numel(pair_bank), 'step_index out of range.');

pairs_k = pair_bank{step_index};
nPairs = size(pairs_k,1);
assert(nPairs >= 1, 'No candidates at requested step.');

pair_sat_1 = zeros(nPairs,1);
pair_sat_2 = zeros(nPairs,1);
obs_score = NaN(nPairs,1);
pta_score = NaN(nPairs,1);
danger_score = NaN(nPairs,1);

for i = 1:nPairs
    pair = pairs_k(i,:);
    pair_sat_1(i) = pair(1);
    pair_sat_2(i) = pair(2);

    [obs_score(i), ~] = score_pair_online_observability_family(ch5case, pair, step_index);
    pta_score(i) = score_pair_online_pta(ch5case, pair_bank, pair, step_index, ch5case.window.length_steps);
    [danger_score(i), ~] = score_pair_online_danger_weighted_gain(ch5case, selection_trace_prefix, pair_bank, pair, step_index, danger_opts);
end

tbl = table( ...
    (1:nPairs)', ...
    pair_sat_1, ...
    pair_sat_2, ...
    obs_score, ...
    pta_score, ...
    danger_score, ...
    'VariableNames', { ...
        'candidate_index', ...
        'pair_sat_1', ...
        'pair_sat_2', ...
        'obs_score', ...
        'pta_score', ...
        'danger_score'});
end
