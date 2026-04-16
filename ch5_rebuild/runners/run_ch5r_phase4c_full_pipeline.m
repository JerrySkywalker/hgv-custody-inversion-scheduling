function out = run_ch5r_phase4c_full_pipeline(opts)
%RUN_CH5R_PHASE4C_FULL_PIPELINE
% Convenience wrapper for Phase 4C full set pipeline.

if nargin < 1 || isempty(opts)
    opts = struct();
end

opts.case_set = 'full';
out = run_ch5r_phase4c_batch_pipeline(opts);
end
