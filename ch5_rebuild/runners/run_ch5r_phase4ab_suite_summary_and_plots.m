function out = run_ch5r_phase4ab_suite_summary_and_plots(opts)
%RUN_CH5R_PHASE4AB_SUITE_SUMMARY_AND_PLOTS
% Convenience wrapper for Phase 4A + 4B.

if nargin < 1 || isempty(opts)
    opts = struct();
end

if ~isfield(opts, 'suite_source') || isempty(opts.suite_source)
    error('run_ch5r_phase4ab_suite_summary_and_plots:MissingSource', ...
        'opts.suite_source is required.');
end

if ~isfield(opts, 'visible_mode') || isempty(opts.visible_mode)
    opts.visible_mode = 'off';
end

outA = run_ch5r_phase4a_suite_summary(struct( ...
    'suite_source', opts.suite_source));

outB = run_ch5r_phase4b_suite_plots(struct( ...
    'summary_source', outA, ...
    'visible_mode', opts.visible_mode));

out = struct();
out.ok = true;
out.phase4a = outA;
out.phase4b = outB;
end
