function out = run_ch5r_phase8_branch_closedloop_real()
%RUN_CH5R_PHASE8_BRANCH_CLOSEDLOOP_REAL
% Real closed-loop branch for R8.6-real compare.

base = run_ch5r_phase8_5_outerB_continuous();

out = struct();
out.name = 'R8-like_closedloop_real';
out.cfg = base.cfg;
out.trace_data = base.trace_data;
out.summary = base.summary;
out.paths = base.paths;
end
