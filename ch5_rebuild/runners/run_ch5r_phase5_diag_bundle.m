function out = run_ch5r_phase5_diag_bundle()
%RUN_CH5R_PHASE5_DIAG_BUNDLE
% R5 diagnostic bundle:
% - MG proxy + Chapter2-aligned FSM
% - NIS unavailable (NaN placeholder)

addpath(fullfile(pwd, 'ch5_rebuild', 'diagnostics'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));

out5 = run_ch5r_phase5_bubble_predictive(struct( ...
    'save_outputs', false, ...
    'log_enable', false));

diag_out = ch5r_build_custody_diag_bundle('R5', out5);

out_dir = fullfile(out5.cfg.ch5r.output_root, 'phaseR5_diag_bundle');
files = plot_ch5r_custody_diag_bundle(diag_out, out_dir, 'off');

disp('=== [ch5r:R5-diag] summary ===')
disp(diag_out.fsm.summary)
disp(files)

out = struct();
out.phase = out5;
out.diag = diag_out;
out.files = files;
out.ok = true;
end
