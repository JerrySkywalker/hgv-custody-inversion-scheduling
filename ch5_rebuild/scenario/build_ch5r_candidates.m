function candidates = build_ch5r_candidates(cfg, ch5case)
%BUILD_CH5R_CANDIDATES  Minimal candidate wrapper for future scheduling phases.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params();
end
if nargin < 2 || isempty(ch5case)
    ch5case = build_ch5r_case(cfg);
end

N = numel(ch5case.time_s);

candidates = struct();
candidates.source = 'candidate_wrapper_placeholder';
candidates.time_s = ch5case.time_s;
candidates.count_per_step = repmat(ch5case.theta.Ns, N, 1);
candidates.note = ['Placeholder wrapper. Future versions should enumerate visible or ' ...
    'admissible satellites at each time step.'];
end
