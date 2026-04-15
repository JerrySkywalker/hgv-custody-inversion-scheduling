function out = run_ch5r_phase5_diag_bundle()
%RUN_CH5R_PHASE5_DIAG_BUNDLE

addpath(fullfile(pwd, 'ch5_rebuild', 'diagnostics'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));

disp('[diag][R5] phase runner: start')
disp('[diag][R5] phase runner: run Phase R5 baseline')

out5 = run_ch5r_phase5_bubble_predictive(struct( ...
    'save_outputs', false, ...
    'log_enable', true));

if isfield(out5, 'replay') && isstruct(out5.replay)
    disp('[diag][R5] phase runner: reuse replay from phase runner')
    replay = out5.replay;
    if isfield(replay, 'paths') && isfield(replay.paths, 'mat_file') && ~isempty(replay.paths.mat_file)
        out5.paths.mat_file = replay.paths.mat_file;
    end
else
    disp('[diag][R5] phase runner: run R5 Koopman diagnostic replay')
    replay = ch5r_run_selection_replay_koopman('R5', out5, true, true);
    out5.paths.mat_file = replay.paths.mat_file;
end

disp('[diag][R5] phase runner: build diagnostic bundle')
diag_out = ch5r_build_custody_diag_bundle('R5', out5);

out_dir = fullfile(out5.cfg.ch5r.output_root, 'phaseR5_diag_bundle');
disp(['[diag][R5] phase runner: plot to ' out_dir])
artifact_tag = local_diag_tag('R5', out5.case);
files = plot_ch5r_custody_diag_bundle(diag_out, out_dir, 'off', artifact_tag);

disp('=== [ch5r:R5-diag] summary ===')
disp(diag_out.fsm.summary)
disp(files)

out = struct();
out.phase = out5;
out.replay = replay;
out.diag = diag_out;
out.files = files;
out.ok = true;

disp('[diag][R5] phase runner: done')
end

function tag = local_diag_tag(phase_name, ch5case)
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = [lower(phase_name) '_' ch5r_make_artifact_tag(ch5case, stamp, {'diag-bundle'})];
end
