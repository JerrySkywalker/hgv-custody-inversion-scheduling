function bcirc_pack = group_average_to_bcirc_stage10B(lag_pack, cfg)
%GROUP_AVERAGE_TO_BCIRC_STAGE10B
% Build first-column blocks for a block-circulant reference W_{r,0}.
%
% This stage is the first formal step away from template proxies:
%   - first-column blocks come from truth-side lag structure
%   - default uses active-anchor mean lag blocks
%
% Output:
%   first_col_blocks_3x3xP
%   source_mode
%   P

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10B_prepare_cfg(cfg);

    P = lag_pack.P;

    switch lower(string(cfg.stage10B.bcirc_firstcol_source))
        case "active_anchor_mean"
            first_col_blocks = lag_pack.lag_blocks_active_mean;

        case "anchor_relative"
            first_col_blocks = lag_pack.lag_blocks_ref;

        otherwise
            error('Unknown bcirc_firstcol_source: %s', string(cfg.stage10B.bcirc_firstcol_source));
    end

    if cfg.stage10B.force_symmetric
        for ell = 1:P
            first_col_blocks(:,:,ell) = 0.5 * (first_col_blocks(:,:,ell) + first_col_blocks(:,:,ell).');
        end
    end

    bcirc_pack = struct();
    bcirc_pack.P = P;
    bcirc_pack.source_mode = string(cfg.stage10B.bcirc_firstcol_source);
    bcirc_pack.first_col_blocks_3x3xP = first_col_blocks;
end