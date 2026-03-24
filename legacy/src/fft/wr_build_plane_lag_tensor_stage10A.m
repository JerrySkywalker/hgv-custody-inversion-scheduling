function lag_pack = wr_build_plane_lag_tensor_stage10A(plane_pack, cfg)
%WR_BUILD_PLANE_LAG_TENSOR_STAGE10A
% Build truth-side relative-lag views from per-plane blocks.
%
% This is NOT yet the formal bcirc reference.
% It is a diagnostic object for Stage10.A:
%   - choose a reference plane (anchor)
%   - reorder the per-plane truth blocks by relative lag
%   - also compute a circular-shift averaged lag profile over active anchors
%
% Output:
%   lag_blocks_ref(:,:,ell)      : truth blocks ordered by lag from anchor plane
%   lag_trace_ref(ell)           : trace profile in lag coordinates
%   lag_blocks_active_mean       : lag profile averaged over active anchors
%   lag_trace_active_mean
%   anchor_plane
%   lag_index

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10A_prepare_cfg(cfg);

    if isfield(plane_pack, 'W_plane')
        W_plane = plane_pack.W_plane;
    elseif isfield(plane_pack, 'plane_blocks_3x3xP')
        W_plane = plane_pack.plane_blocks_3x3xP;
    else
        error('plane_pack must contain W_plane or plane_blocks_3x3xP.');
    end

    P = plane_pack.P;
    active = plane_pack.active_plane_mask(:);
    active_idx = find(active);

    if isempty(active_idx)
        anchor_plane = 1;
    else
        switch lower(string(cfg.stage10A.anchor_mode))
            case "max_trace_active"
                [~, imax] = max(plane_pack.plane_trace(:));
                anchor_plane = imax;
            case "first_active"
                anchor_plane = active_idx(1);
            case "manual"
                anchor_plane = cfg.stage10A.manual_anchor_plane;
                if anchor_plane < 1 || anchor_plane > P
                    error('cfg.stage10A.manual_anchor_plane out of range.');
                end
            otherwise
                error('Unknown anchor_mode: %s', string(cfg.stage10A.anchor_mode));
        end
    end

    lag_blocks_ref = zeros(3,3,P);
    lag_trace_ref = zeros(P,1);
    lag_fro_ref = zeros(P,1);
    lag_plane_id_ref = zeros(P,1);

    for ell = 1:P
        p = mod(anchor_plane - 1 + (ell - 1), P) + 1;
        lag_blocks_ref(:,:,ell) = W_plane(:,:,p);
        lag_trace_ref(ell) = trace(W_plane(:,:,p));
        lag_fro_ref(ell) = norm(W_plane(:,:,p), 'fro');
        lag_plane_id_ref(ell) = p;
    end

    % Mean lag profile over all active anchors
    lag_blocks_active_mean = zeros(3,3,P);
    if isempty(active_idx)
        nAnchor = 0;
    else
        nAnchor = numel(active_idx);
        for ia = 1:nAnchor
            p0 = active_idx(ia);
            for ell = 1:P
                p = mod(p0 - 1 + (ell - 1), P) + 1;
                lag_blocks_active_mean(:,:,ell) = lag_blocks_active_mean(:,:,ell) + W_plane(:,:,p);
            end
        end
        lag_blocks_active_mean = lag_blocks_active_mean / nAnchor;
    end

    if cfg.stage10A.force_symmetric
        for ell = 1:P
            lag_blocks_ref(:,:,ell) = 0.5 * (lag_blocks_ref(:,:,ell) + lag_blocks_ref(:,:,ell).');
            lag_blocks_active_mean(:,:,ell) = 0.5 * (lag_blocks_active_mean(:,:,ell) + lag_blocks_active_mean(:,:,ell).');
        end
    end

    lag_trace_active_mean = zeros(P,1);
    lag_fro_active_mean = zeros(P,1);
    for ell = 1:P
        lag_trace_active_mean(ell) = trace(lag_blocks_active_mean(:,:,ell));
        lag_fro_active_mean(ell) = norm(lag_blocks_active_mean(:,:,ell), 'fro');
    end

    lag_pack = struct();
    lag_pack.P = P;
    lag_pack.anchor_plane = anchor_plane;
    lag_pack.active_idx = active_idx;
    lag_pack.n_active = numel(active_idx);

    lag_pack.lag_index = (0:P-1).';
    lag_pack.lag_plane_id_ref = lag_plane_id_ref;

    lag_pack.lag_blocks_ref = lag_blocks_ref;
    lag_pack.lag_trace_ref = lag_trace_ref;
    lag_pack.lag_fro_ref = lag_fro_ref;

    lag_pack.lag_blocks_active_mean = lag_blocks_active_mean;
    lag_pack.lag_trace_active_mean = lag_trace_active_mean;
    lag_pack.lag_fro_active_mean = lag_fro_active_mean;
end