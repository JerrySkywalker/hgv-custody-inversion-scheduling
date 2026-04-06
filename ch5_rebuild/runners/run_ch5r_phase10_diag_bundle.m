function out = run_ch5r_phase10_diag_bundle()
%RUN_CH5R_PHASE10_DIAG_BUNDLE
% R10 diagnostic bundle:
% - MG proxy
% - Vr proxy
% - NIS proxy
% - Chapter2-aligned posthoc FSM

addpath(fullfile(pwd, 'ch5_rebuild', 'diagnostics'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));

out10 = run_ch5r_phase10_li_backend_closedloop(struct( ...
    'save_outputs', true, ...
    'log_enable', false, ...
    'interval_steps', 30, ...
    'min_support_ratio', 0.5));

diag_out = ch5r_build_custody_diag_bundle('R10', out10);

out_dir = fullfile(out10.cfg.ch5r.output_root, 'phaseR10_diag_bundle');
files = plot_ch5r_custody_diag_bundle(diag_out, out_dir, 'off');

disp('=== [ch5r:R10-diag] summary ===')
disp(diag_out.fsm.summary)
disp(files)

out = struct();
out.phase = out10;
out.diag = diag_out;
out.files = files;
out.ok = true;
end
