function diag_out = ch5r_build_custody_diag_bundle(phase_name, out_phase)
%CH5R_BUILD_CUSTODY_DIAG_BUNDLE
% Build unified Chapter2-aligned diagnostic bundle for R5/R9/R10.

disp(['[diag][' phase_name '] build bundle: start'])

diag_cfg = default_ch5r_diag_params();

diag_out = struct();
diag_out.phase_name = phase_name;
diag_out.diag_cfg = diag_cfg;
diag_out.case = out_phase.case;
diag_out.selection_trace = out_phase.selection_trace;
diag_out.time_s = out_phase.case.t_s(:);

disp(['[diag][' phase_name '] build bundle: MG proxy'])
diag_out.mg = ch5r_compute_mg_proxy_trace(out_phase.case, out_phase.selection_trace);

P_hist = [];
xpred_hist = [];
sigma_angle_rad = out_phase.cfg.ch5r.sensor_profile.sigma_angle_rad;

if isfield(out_phase.paths, 'mat_file') && ~isempty(out_phase.paths.mat_file) && isfile(out_phase.paths.mat_file)
    disp(['[diag][' phase_name '] build bundle: load P_hist/xpred_hist from mat'])
    S = load(out_phase.paths.mat_file, 'P_hist', 'xpred_hist');
    if isfield(S, 'P_hist');     P_hist = S.P_hist;     end
    if isfield(S, 'xpred_hist'); xpred_hist = S.xpred_hist; end
else
    disp(['[diag][' phase_name '] build bundle: no mat_file found, Vr/NIS may be unavailable'])
end

disp(['[diag][' phase_name '] build bundle: Vr proxy'])
diag_out.vr = ch5r_compute_vr_proxy_trace(P_hist, diag_cfg);

disp(['[diag][' phase_name '] build bundle: NIS proxy'])
diag_out.nis = ch5r_compute_nis_proxy_trace(out_phase.case, out_phase.selection_trace, xpred_hist, P_hist, sigma_angle_rad);

disp(['[diag][' phase_name '] build bundle: FSM posthoc'])
diag_out.fsm = ch5r_run_custody_fsm_posthoc(diag_out.vr, diag_out.mg, out_phase.case, diag_cfg);

diag_out.bubble = out_phase.bubble;

diag_out.rmse = nan(size(diag_out.time_s));
if isfield(out_phase.result, 'r9_tracking') && isfield(out_phase.result.r9_tracking, 'rmse_pos_km_series')
    diag_out.rmse = out_phase.result.r9_tracking.rmse_pos_km_series(:);
elseif isfield(out_phase.result, 'r10_tracking') && isfield(out_phase.result.r10_tracking, 'rmse_pos_km_series')
    diag_out.rmse = out_phase.result.r10_tracking.rmse_pos_km_series(:);
end

disp(['[diag][' phase_name '] build bundle: done'])
end
