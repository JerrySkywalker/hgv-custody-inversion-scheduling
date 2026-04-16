function out = run_ch5r_phase4c_paper_pipeline(opts)
%RUN_CH5R_PHASE4C_PAPER_PIPELINE
% Convenience wrapper for Phase 4C paper set pipeline.

if nargin < 1 || isempty(opts)
    opts = struct();
end

opts.case_set = 'paper';
out = run_ch5r_phase4c_batch_pipeline(opts);
end
