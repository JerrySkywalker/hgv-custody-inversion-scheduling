function out = run_ch5r_phase9_diag_bundle()
%RUN_CH5R_PHASE9_DIAG_BUNDLE

addpath(fullfile(pwd, 'ch5_rebuild', 'diagnostics'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));

disp('[diag][R9] phase runner: start')
disp('[diag][R9] phase runner: run Phase R9 closed-loop')

out9 = run_ch5r_phase9_r9_closedloop(struct( ...
    'alpha_tau', 0.5, ...
    'save_outputs', true, ...
    'log_enable', true));

disp('[diag][R9] phase runner: build diagnostic bundle')
diag_out = ch5r_build_custody_diag_bundle('R9', out9);

out_dir = fullfile(out9.cfg.ch5r.output_root, 'phaseR9_diag_bundle');
disp(['[diag][R9] phase runner: plot to ' out_dir])
artifact_tag = local_diag_tag('R9', out9.case);
files = plot_ch5r_custody_diag_bundle(diag_out, out_dir, 'off', artifact_tag);

disp('=== [ch5r:R9-diag] summary ===')
disp(diag_out.fsm.summary)
disp(files)

out = struct();
out.phase = out9;
out.diag = diag_out;
out.files = files;
out.ok = true;

disp('[diag][R9] phase runner: done')
end

function tag = local_diag_tag(phase_name, ch5case)
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = [lower(phase_name) '_' ch5r_make_artifact_tag(ch5case, stamp, {'diag-bundle'})];
end
