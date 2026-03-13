function chk = check_bcirc_consistency_stage10B(Wbcirc, first_col_blocks, truth_blocks, cfg)
%CHECK_BCIRC_CONSISTENCY_STAGE10B
% Check internal consistency of the bcirc reconstruction and compare against
% a truth-side reduced block matrix.
%
% Inputs:
%   Wbcirc         : full reconstructed bcirc matrix (3P x 3P)
%   first_col_blocks : 3x3xP first-column blocks
%   truth_blocks   : 3x3xP truth-side lag blocks used as reduced reference
%
% Output:
%   chk with:
%     self_firstcol_err_fro
%     bcirc_vs_truth_reduced_fro
%     bcirc_vs_truth_reduced_2
%     truth_reduced_matrix
%     lambda_min_bcirc
%     lambda_min_truth_reduced

    if nargin < 4
        cfg = default_params();
    end
    cfg = stage10B_prepare_cfg(cfg);

    [~, ~, P] = size(first_col_blocks);

    % self-consistency: extract first column back from Wbcirc
    self_err2 = 0;
    self_errF = 0;
    for i = 1:P
        row_idx = (3*(i-1)+1):(3*i);
        col_idx = 1:3;
        Bij = Wbcirc(row_idx, col_idx);
        D = Bij - first_col_blocks(:,:,i);
        self_err2 = max(self_err2, norm(D, 2));
        self_errF = self_errF + norm(D, 'fro')^2;
    end
    self_errF = sqrt(self_errF);

    % truth-side reduced matrix built from the supplied truth_blocks
    Wtruth_red = reconstruct_bcirc_matrix_stage10B(truth_blocks, cfg);

    Dred = Wbcirc - Wtruth_red;

    chk = struct();
    chk.self_firstcol_err_2 = self_err2;
    chk.self_firstcol_err_fro = self_errF;

    chk.truth_reduced_matrix = Wtruth_red;
    chk.bcirc_vs_truth_reduced_fro = norm(Dred, 'fro');
    chk.bcirc_vs_truth_reduced_2 = norm(Dred, 2);

    chk.lambda_min_bcirc = min(real(eig(0.5*(Wbcirc + Wbcirc.'))));
    chk.lambda_min_truth_reduced = min(real(eig(0.5*(Wtruth_red + Wtruth_red.'))));
end