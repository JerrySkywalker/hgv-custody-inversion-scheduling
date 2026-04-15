function out = run_ch5r_phase4_diag_bundle()
%RUN_CH5R_PHASE4_DIAG_BUNDLE
% R4 diagnostic bundle:
% - run tracking-greedy baseline
% - run Koopman diagnostic replay on fixed selection trace
% - build Chapter2-aligned posthoc diagnostic bundle
% - output the same 3 figures as R3/R5/R9/R10

addpath(fullfile(pwd, 'ch5_rebuild', 'diagnostics'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));

disp('[diag][R4] phase runner: start')
disp('[diag][R4] phase runner: run Phase R4 tracking baseline')

out4 = run_ch5r_phase4_tracking_baseline();

if isfield(out4, 'replay') && isstruct(out4.replay)
    disp('[diag][R4] phase runner: reuse replay from phase runner')
    replay = out4.replay;
    if isfield(replay, 'paths') && isfield(replay.paths, 'mat_file') && ~isempty(replay.paths.mat_file)
        out4.paths.mat_file = replay.paths.mat_file;
    end
else
    disp('[diag][R4] phase runner: run R4 Koopman diagnostic replay')
    replay = ch5r_run_selection_replay_koopman('R4', out4, true, true);
    out4.paths.mat_file = replay.paths.mat_file;
end

disp('[diag][R4] phase runner: build diagnostic bundle')
diag_out = ch5r_build_custody_diag_bundle('R4', out4);

out_dir = fullfile(out4.cfg.ch5r.output_root, 'phaseR4_diag_bundle');
disp(['[diag][R4] phase runner: plot to ' out_dir])
artifact_tag = local_diag_tag('R4', out4.case);
files = plot_ch5r_custody_diag_bundle(diag_out, out_dir, 'off', artifact_tag);

disp('=== [ch5r:R4-diag] summary ===')
disp(diag_out.fsm.summary)
disp(files)

out = struct();
out.phase = out4;
out.replay = replay;
out.diag = diag_out;
out.files = files;
out.ok = true;

disp('[diag][R4] phase runner: done')
end

function tag = local_diag_tag(phase_name, ch5case)
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = [lower(phase_name) '_' ch5r_make_artifact_tag(ch5case, stamp, {'diag-bundle'})];
end
