function diag_cfg = default_ch5r_diag_params()
%DEFAULT_CH5R_DIAG_PARAMS
% Unified diagnostic layer aligned to Chapter 2 paper-consistent FSM:
% - main state variables: Vr, MG
% - NIS is diagnostic only
%
% Current-shell interpretation:
% - MG proxy is built from rolling window Fisher information on position
% - eps_req is aligned to current bubble threshold gamma_req
% - Vr proxy uses position covariance if available
% - if Vr unavailable, FSM falls back to MG-only mode

diag_cfg = struct();

% MG warning band
diag_cfg.beta_eps = 1.20;

% Vr online baseline params
diag_cfg.alpha_base = 0.05;
diag_cfg.alpha_mad  = 0.05;
diag_cfg.kV         = 3.0;
diag_cfg.mad_floor  = 1e-6;

% Vr proxy numerical guard
diag_cfg.vr_eps_det = 1e-12;

% NIS proxy diagnostic thresholding
diag_cfg.nis_dof = 4;
diag_cfg.nis_warn_quantile = 0.95;

% plotting
diag_cfg.plot_visible = 'off';
diag_cfg.save_outputs = true;
end
