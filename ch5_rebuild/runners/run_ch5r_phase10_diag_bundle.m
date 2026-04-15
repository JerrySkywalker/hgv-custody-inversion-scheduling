function out = run_ch5r_phase10_diag_bundle()
%RUN_CH5R_PHASE10_DIAG_BUNDLE

addpath(fullfile(pwd, 'ch5_rebuild', 'diagnostics'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));

disp('[diag][R10] phase runner: start')
disp('[diag][R10] phase runner: run Phase R10 Li-style backend')

out10 = run_ch5r_phase10_li_backend_closedloop(struct( ...
    'save_outputs', true, ...
    'log_enable', true, ...
    'interval_steps', 30, ...
    'min_support_ratio', 0.5));

disp('[diag][R10] phase runner: build diagnostic bundle')
diag_out = ch5r_build_custody_diag_bundle('R10', out10);

out_dir = fullfile(out10.cfg.ch5r.output_root, 'phaseR10_diag_bundle');
disp(['[diag][R10] phase runner: plot to ' out_dir])
artifact_tag = local_diag_tag('R10', out10.case);
files = plot_ch5r_custody_diag_bundle(diag_out, out_dir, 'off', artifact_tag);

disp('=== [ch5r:R10-diag] summary ===')
disp(diag_out.fsm.summary)
disp(files)

out = struct();
out.phase = out10;
out.diag = diag_out;
out.files = files;
out.ok = true;

disp('[diag][R10] phase runner: done')
end

function tag = local_diag_tag(phase_name, ch5case)
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = [lower(phase_name) '_' ch5r_make_artifact_tag(ch5case, stamp, {'diag-bundle'})];
end
