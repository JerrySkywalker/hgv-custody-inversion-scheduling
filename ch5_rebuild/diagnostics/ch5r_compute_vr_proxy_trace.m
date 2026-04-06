function vr = ch5r_compute_vr_proxy_trace(P_hist, diag_cfg)
%CH5R_COMPUTE_VR_PROXY_TRACE
% Current-shell Vr proxy:
%   Vr = 0.5 * log(det(P_pos))
% where P_pos is the 3x3 position covariance block.
%
% If P_hist is unavailable, returns all-NaN trace and mode='unavailable'.

vr = struct();
vr.value = [];
vr.valid = [];
vr.mode = 'unavailable';

if nargin < 1 || isempty(P_hist)
    return;
end

Nt = size(P_hist, 3);
vr.value = nan(Nt,1);
vr.valid = false(Nt,1);
vr.mode = 'position_cov_logdet';

for k = 1:Nt
    Pk = P_hist(:,:,k);
    if ~all(isfinite(Pk(:)))
        continue;
    end

    Ppos = 0.5 * (Pk(1:3,1:3) + Pk(1:3,1:3)');
    Ppos = Ppos + diag_cfg.vr_eps_det * eye(3);

    d = det(Ppos);
    if isfinite(d) && d > 0
        vr.value(k) = 0.5 * log(d);
        vr.valid(k) = true;
    end
end
end
