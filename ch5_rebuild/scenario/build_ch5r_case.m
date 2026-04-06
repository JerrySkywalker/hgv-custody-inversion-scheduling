function ch5case = build_ch5r_case(cfg)
%BUILD_CH5R_CASE
% Build a real Chapter-5 case using:
% - real Stage02 truth
% - fixed real constellation from theta_star
% - real Stage03 visibility / LOS geometry

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(true);
end

if ~isfield(cfg, 'ch5r') || ~isfield(cfg.ch5r, 'theta_star') || isempty(cfg.ch5r.theta_star)
    cfg = default_ch5r_params(true);
end

truth = build_ch5r_truth_from_stage02_engine(cfg);
satbank = build_ch5r_satbank_from_stage03_engine(cfg, truth);
candidates = build_ch5r_candidates(cfg, truth, satbank);

window_length_s = cfg.ch5r.window_length_s;
window_mode = cfg.ch5r.window_mode;

assert(numel(truth.t_s) >= 2, '[ch5r] truth.t_s must contain at least two steps.');
dt = truth.t_s(2) - truth.t_s(1);
window_length_steps = max(1, round(window_length_s / dt));

left_steps = floor((window_length_steps - 1) / 2);
right_steps = window_length_steps - 1 - left_steps;

ch5case = struct();
ch5case.truth = truth;
ch5case.satbank = satbank;
ch5case.candidates = candidates;
ch5case.t_s = truth.t_s(:);
ch5case.time_s = truth.t_s(:);
ch5case.dt = dt;

ch5case.window = struct();
ch5case.window.length_s = window_length_s;
ch5case.window.length_steps = window_length_steps;
ch5case.window.mode = window_mode;
ch5case.window.left_steps = left_steps;
ch5case.window.right_steps = right_steps;
ch5case.window.exclude_incomplete_edges = cfg.ch5r.window_exclude_incomplete_edges;

ch5case.gamma_req = cfg.ch5r.gamma_req;
ch5case.target_case = struct('case_id', truth.case_id, 'family', truth.family);

ch5case.theta = cfg.ch5r.theta_star;
ch5case.meta = struct();
ch5case.meta.note = 'Real case: Stage02 truth + theta_star fixed constellation + centered full-only window semantics.';
end
