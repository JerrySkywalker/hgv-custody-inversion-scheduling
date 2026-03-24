function out = compute_projected_accuracy_stage09(Wr, CA, cfg_or_stage09)
%COMPUTE_PROJECTED_ACCURACY_STAGE09
% Compute the task-direction projected lower-bound covariance and the
% corresponding projected accuracy metric from a window information matrix Wr.
%
% Formal objects:
%   P_A_lb      = C_A * inv(Wr) * C_A'
%   sigma_A_proj:
%       - sqrt(max eig(P_A_lb))     if A_metric_mode = 'max_eig_rms'
%       - sqrt(trace(P_A_lb))       if A_metric_mode = 'trace_rms'
%
% Inputs
%   Wr              : window information matrix (n x n)
%   CA              : task projection matrix (m x n)
%   cfg_or_stage09  : either cfg (with cfg.stage09) or cfg.stage09
%
% Output fields
%   out.Wr_used
%   out.Wr_eigvals
%   out.Wr_cond
%   out.Wr_inv
%   out.PA_lb
%   out.PA_eigvals
%   out.sigma_A_proj
%   out.rank_Wr
%   out.ok
%   out.note

    if nargin < 3
        error('compute_projected_accuracy_stage09 requires Wr, CA, cfg_or_stage09.');
    end

    s9 = local_pick_stage09(cfg_or_stage09);

    validateattributes(Wr, {'numeric'}, {'2d','nonempty','finite','real'});
    validateattributes(CA, {'numeric'}, {'2d','nonempty','finite','real'});

    [n1, n2] = size(Wr);
    if n1 ~= n2
        error('Wr must be square.');
    end

    [mCA, nCA] = size(CA);
    if nCA ~= n1
        error('CA size mismatch: CA is %d x %d, but Wr is %d x %d.', mCA, nCA, n1, n2);
    end

    Wr_used = Wr;

    if s9.force_symmetric
        Wr_used = 0.5 * (Wr_used + Wr_used.');
    end

    if s9.wr_reg_eps > 0
        Wr_used = Wr_used + s9.wr_reg_eps * eye(size(Wr_used));
    end

    [V, D] = eig(Wr_used);
    wr_eigvals = real(diag(D));
    wr_eigvals = wr_eigvals(:);
    wr_eigvals_sorted = sort(wr_eigvals, 'ascend');

    % rank estimate based on floored positive eigenvalues
    rank_Wr = sum(wr_eigvals_sorted > s9.wr_eig_floor);

    % condition number estimate
    pos_eigs = wr_eigvals_sorted(wr_eigvals_sorted > s9.wr_eig_floor);
    if isempty(pos_eigs)
        Wr_cond = inf;
    else
        Wr_cond = max(pos_eigs) / min(pos_eigs);
    end

    switch lower(string(s9.wr_inv_mode))
        case "eig_floor"
            inv_eigs = 1 ./ max(wr_eigvals, s9.wr_eig_floor);
            Wr_inv = V * diag(inv_eigs) * V.';
            Wr_inv = real(0.5 * (Wr_inv + Wr_inv.'));
        case "pinv"
            Wr_inv = pinv(Wr_used);
            Wr_inv = real(0.5 * (Wr_inv + Wr_inv.'));
        otherwise
            error('Unsupported wr_inv_mode: %s', string(s9.wr_inv_mode));
    end

    PA_lb = CA * Wr_inv * CA.';
    if s9.force_symmetric
        PA_lb = 0.5 * (PA_lb + PA_lb.');
    end

    [~, Dpa] = eig(PA_lb);
    PA_eigvals = real(diag(Dpa));
    PA_eigvals = sort(PA_eigvals(:), 'ascend');

    switch lower(string(s9.A_metric_mode))
        case "max_eig_rms"
            sigma_A_proj = sqrt(max(PA_eigvals(end), 0));
        case "trace_rms"
            sigma_A_proj = sqrt(max(trace(PA_lb), 0));
        otherwise
            error('Unsupported A_metric_mode: %s', string(s9.A_metric_mode));
    end

    out = struct();
    out.Wr_used = Wr_used;
    out.Wr_eigvals = wr_eigvals_sorted;
    out.Wr_cond = Wr_cond;
    out.Wr_inv = Wr_inv;
    out.PA_lb = PA_lb;
    out.PA_eigvals = PA_eigvals;
    out.sigma_A_proj = sigma_A_proj;
    out.rank_Wr = rank_Wr;
    out.ok = isfinite(sigma_A_proj) && sigma_A_proj >= 0;
    out.note = local_build_note(out);
end


function s9 = local_pick_stage09(cfg_or_stage09)

    if isstruct(cfg_or_stage09) && isfield(cfg_or_stage09, 'stage09')
        s9 = cfg_or_stage09.stage09;
    else
        s9 = cfg_or_stage09;
    end
end


function note = local_build_note(out)

    if ~out.ok
        note = "invalid_sigma";
        return;
    end

    if isinf(out.Wr_cond)
        note = "rank_deficient_or_nearly_singular";
        return;
    end

    if out.rank_Wr < numel(out.Wr_eigvals)
        note = "partially_rank_deficient";
        return;
    end

    note = "ok";
end