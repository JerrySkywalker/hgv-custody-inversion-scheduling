function eps_pack = compute_eps_sb_stage10D(Wtruth, A0, cfg)
%COMPUTE_EPS_SB_STAGE10D
% Compute symmetry-breaking norms between truth full matrix Wtruth (3x3)
% and the embedded zero-mode baseline A0 (3x3).
%
% Outputs:
%   eps_sb_2
%   eps_sb_fro
%   D = Wtruth - A0

    if nargin < 3
        cfg = default_params();
    end
    cfg = stage10D_prepare_cfg(cfg);

    Wtruth = real(Wtruth);
    Wtruth = 0.5 * (Wtruth + Wtruth.');

    A0 = real(A0);
    A0 = 0.5 * (A0 + A0.');

    D = Wtruth - A0;

    eps_pack = struct();
    eps_pack.D = D;
    eps_pack.eps_sb_2 = norm(D, 2);
    eps_pack.eps_sb_fro = norm(D, 'fro');
end