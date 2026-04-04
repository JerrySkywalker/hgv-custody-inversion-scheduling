function truth = build_ch5r_truth_from_stage02_engine(cfg)
%BUILD_CH5R_TRUTH_FROM_STAGE02_ENGINE  Minimal wrapper for future Stage02 integration.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params();
end

truth = struct();
truth.source = 'stage02_wrapper_placeholder';
truth.case_id = cfg.ch5r.target_case.case_id;
truth.family = cfg.ch5r.target_case.family;
truth.note = ['Placeholder wrapper. Future versions should call Stage02 truth ' ...
    'generation directly.'];
end
