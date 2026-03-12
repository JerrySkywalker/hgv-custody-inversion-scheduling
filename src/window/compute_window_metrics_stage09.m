function out = compute_window_metrics_stage09(Wr, cfg_or_stage09)
%COMPUTE_WINDOW_METRICS_STAGE09
% Unified Stage09.2 metric kernel for a single window information matrix Wr.
%
% Outputs the two formal window-level quantities:
%   DG = lambda_min(Wr) / gamma_eff
%   DA = sigma_A_req / sigma_A_proj
%
% Inputs
%   Wr              : window information matrix
%   cfg_or_stage09  : cfg or cfg.stage09-like structure
%
% Required fields in stage09 config
%   CA
%   sigma_A_req
%   gamma_source (descriptive only at this stage)
%   gamma_eff_scalar (optional)
%   wr_reg_eps
%   wr_eig_floor
%   wr_inv_mode
%   A_metric_mode
%   force_symmetric

    if nargin < 2
        error('compute_window_metrics_stage09 requires Wr and cfg_or_stage09.');
    end

    s9 = local_pick_stage09(cfg_or_stage09);

    validateattributes(Wr, {'numeric'}, {'2d','nonempty','finite','real'});

    [n1, n2] = size(Wr);
    if n1 ~= n2
        error('Wr must be square.');
    end

    % ------------------------------------------------------------
    % Keep both raw and stabilized versions
    % ------------------------------------------------------------
    Wr_raw = Wr;
    if s9.force_symmetric
        Wr_raw = 0.5 * (Wr_raw + Wr_raw.');
    end

    gamma_eff = local_resolve_gamma_eff_scalar(s9);

    % ------------------------------------------------------------
    % Zero-information / near-zero-information shortcut
    % ------------------------------------------------------------
    % If the whole window contains essentially no information,
    % return DG=0 and DA=0 directly, instead of letting regularization
    % create artificial floor values that destroy discrimination.
    tiny_info_thresh = 1e-12;
    if trace(Wr_raw) <= tiny_info_thresh || norm(Wr_raw, 'fro') <= tiny_info_thresh
        out = struct();
        out.Wr_used = Wr_raw;
        out.lambda_min_raw = 0;
        out.lambda_min_eff = 0;
        out.Wr_eigvals = zeros(n1,1);
        out.gamma_eff = gamma_eff;
        out.DG = 0;

        out.PA_lb = nan(size(s9.CA,1), size(s9.CA,1));
        out.PA_eigvals = nan(size(s9.CA,1),1);
        out.sigma_A_proj = inf;
        out.DA = 0;

        out.rank_Wr = 0;
        out.Wr_cond = inf;
        out.ok = true;
        out.note = "zero_information_window";
        return;
    end

    % ------------------------------------------------------------
    % Stabilized version for DG only
    % ------------------------------------------------------------
    Wr_used = Wr_raw;
    if s9.wr_reg_eps > 0
        Wr_used = Wr_used + s9.wr_reg_eps * eye(size(Wr_used));
    end

    wr_eigs = eig(Wr_used);
    wr_eigs = sort(real(wr_eigs(:)), 'ascend');

    lambda_min_raw = min(real(eig(Wr_raw)));
    lambda_min_eff = max(wr_eigs(1), s9.wr_eig_floor);

    DG = lambda_min_eff / gamma_eff;

    % ------------------------------------------------------------
    % IMPORTANT:
    % For DA, pass the RAW Wr into projected-accuracy computation,
    % so that regularization is applied only once inside
    % compute_projected_accuracy_stage09.
    % ------------------------------------------------------------
    proj = compute_projected_accuracy_stage09(Wr_raw, s9.CA, s9);
    sigma_A_proj = proj.sigma_A_proj;

    if ~isfinite(sigma_A_proj) || sigma_A_proj <= 0
        DA = 0;
    else
        DA = s9.sigma_A_req / sigma_A_proj;
    end

    out = struct();
    out.Wr_used = Wr_used;
    out.lambda_min_raw = lambda_min_raw;
    out.lambda_min_eff = lambda_min_eff;
    out.Wr_eigvals = wr_eigs;
    out.gamma_eff = gamma_eff;
    out.DG = DG;

    out.PA_lb = proj.PA_lb;
    out.PA_eigvals = proj.PA_eigvals;
    out.sigma_A_proj = sigma_A_proj;
    out.DA = DA;

    out.rank_Wr = proj.rank_Wr;
    out.Wr_cond = proj.Wr_cond;
    out.ok = isfinite(DG) && (isfinite(DA) || DA == 0) && proj.ok;
    out.note = local_build_note(out, proj.note);
end


function s9 = local_pick_stage09(cfg_or_stage09)

    if isstruct(cfg_or_stage09) && isfield(cfg_or_stage09, 'stage09')
        s9 = cfg_or_stage09.stage09;
    else
        s9 = cfg_or_stage09;
    end
end


function gamma_eff = local_resolve_gamma_eff_scalar(s9)

    if isfield(s9, 'gamma_eff_scalar') && ~isempty(s9.gamma_eff_scalar)
        gamma_eff = s9.gamma_eff_scalar;
    else
        % Stage09.2 only needs a scalar placeholder.
        % Stage09.3/09.4 will refine this through the real calibration path.
        gamma_eff = 1.0;
    end

    if ~isfinite(gamma_eff) || gamma_eff <= 0
        error('gamma_eff_scalar must be finite and > 0.');
    end
end


function note = local_build_note(out, proj_note)

    if ~out.ok
        note = "invalid_metric";
        return;
    end

    if isfield(out, 'note') && out.note == "zero_information_window"
        note = out.note;
        return;
    end

    if proj_note ~= "ok"
        note = "projected_accuracy:" + string(proj_note);
        return;
    end

    note = "ok";
end