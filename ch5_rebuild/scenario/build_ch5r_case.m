function ch5case = build_ch5r_case(cfg)
%BUILD_CH5R_CASE
% Build a real Phase-R4 case using:
% - real Stage02 truth
% - fixed real constellation from theta_star
% - real Stage03 visibility / LOS geometry

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(false);
end

truth = build_ch5r_truth_from_stage02_engine(cfg);
satbank = build_ch5r_satbank_from_stage03_engine(cfg, truth);
candidates = build_ch5r_candidates(cfg, truth, satbank);

window_length_s = 60;
if isfield(cfg.ch5r, 'window_length_s')
    window_length_s = cfg.ch5r.window_length_s;
end
dt = truth.t_s(2) - truth.t_s(1);
window_length_steps = max(1, round(window_length_s / dt));

ch5case = struct();
ch5case.truth = truth;
ch5case.satbank = satbank;
ch5case.candidates = candidates;
ch5case.t_s = truth.t_s(:);
ch5case.dt = dt;
ch5case.window = struct();
ch5case.window.length_s = window_length_s;
ch5case.window.length_steps = window_length_steps;
ch5case.gamma_req = cfg.ch5r.gamma_req;
ch5case.target_case = struct('case_id', truth.case_id, 'family', truth.family);
ch5case.meta = struct();
ch5case.meta.note = 'Real R4 case: real Stage02 truth + fixed theta_star constellation + real visible pair candidates.';
end
