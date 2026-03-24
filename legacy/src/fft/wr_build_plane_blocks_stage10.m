function out = wr_build_plane_blocks_stage10(vis_case, idx_start, idx_end, satbank, varargin)
%WR_BUILD_PLANE_BLOCKS_STAGE10 Build per-plane window information blocks.
%
% Compatible call forms:
%   out = wr_build_plane_blocks_stage10(vis_case, idx_start, idx_end, satbank, cfg)
%   out = wr_build_plane_blocks_stage10(vis_case, idx_start, idx_end, satbank, walker, cfg)
%
% Output fields (aligned with Stage10.1 script):
%   W_plane                    : 3x3xP per-plane accumulated information
%   measurement_count_by_plane : P x 1 visible-observation counts
%   measurement_count_total    : total visible-observation count
%   plane_trace               : trace of each plane block
%   plane_fro                 : fro norm of each plane block
%   active_plane_mask         : whether a plane contributes enough information
%   n_active_plane            : number of active planes
%   Wr_full                   : sum over planes
%   P, Ns, plane_id_of_sat    : metadata

    if nargin < 5
        error('wr_build_plane_blocks_stage10 requires at least 5 inputs.');
    end

    % ------------------------------------------------------------
    % Parse optional inputs
    % ------------------------------------------------------------
    if numel(varargin) == 1
        walker = [];
        cfg = varargin{1};
    elseif numel(varargin) == 2
        walker = varargin{1};
        cfg = varargin{2};
    else
        error('wr_build_plane_blocks_stage10 accepts either 5 or 6 inputs.');
    end

    cfg = stage10_prepare_cfg(cfg);

    % ------------------------------------------------------------
    % Resolve walker metadata
    % ------------------------------------------------------------
    if isempty(walker)
        if isfield(satbank, 'walker') && ~isempty(satbank.walker)
            walker = satbank.walker;
        else
            error('Walker metadata is required, either via satbank.walker or explicit walker input.');
        end
    end

    if ~isfield(walker, 'sat') || isempty(walker.sat)
        error('walker.sat is required.');
    end
    if ~isfield(walker, 'P') || isempty(walker.P)
        error('walker.P is required.');
    end
    if ~isfield(walker, 'Ns') || isempty(walker.Ns)
        error('walker.Ns is required.');
    end

    P = walker.P;
    Ns = walker.Ns;

    plane_id_of_sat = zeros(Ns,1);
    for s = 1:Ns
        plane_id_of_sat(s) = walker.sat(s).plane_id;
    end

    % ------------------------------------------------------------
    % Accumulate per-plane window information
    % ------------------------------------------------------------
    W_plane = zeros(3,3,P);
    measurement_count_by_plane = zeros(P,1);

    for k = idx_start:idx_end
        r_tgt = vis_case.r_tgt_eci_km(k,:);

        vis_idx = find(vis_case.visible_mask(k,:));
        if isempty(vis_idx)
            continue;
        end

        for jj = 1:numel(vis_idx)
            s = vis_idx(jj);
            p = plane_id_of_sat(s);

            r_sat = satbank.r_eci_km(k,:,s);
            Q = info_increment_angle_stage04(r_sat, r_tgt, cfg);

            W_plane(:,:,p) = W_plane(:,:,p) + Q;
            measurement_count_by_plane(p) = measurement_count_by_plane(p) + 1;
        end
    end

    if isfield(cfg.stage10, 'force_symmetric') && cfg.stage10.force_symmetric
        for p = 1:P
            W_plane(:,:,p) = 0.5 * (W_plane(:,:,p) + W_plane(:,:,p).');
        end
    end

    plane_trace = zeros(P,1);
    plane_fro = zeros(P,1);
    for p = 1:P
        plane_trace(p) = trace(W_plane(:,:,p));
        plane_fro(p) = norm(W_plane(:,:,p), 'fro');
    end

    % active threshold
    active_thresh = 0;
    if isfield(cfg.stage10, 'active_plane_min_trace') && ~isempty(cfg.stage10.active_plane_min_trace)
        active_thresh = cfg.stage10.active_plane_min_trace;
    end
    active_plane_mask = plane_trace > active_thresh;

    Wr_full = sum(W_plane, 3);
    if isfield(cfg.stage10, 'force_symmetric') && cfg.stage10.force_symmetric
        Wr_full = 0.5 * (Wr_full + Wr_full.');
    end

    out = struct();
    out.window_idx_start = idx_start;
    out.window_idx_end = idx_end;

    out.P = P;
    out.Ns = Ns;
    out.plane_id_of_sat = plane_id_of_sat;

    out.W_plane = W_plane;                           % <-- for stage10 main script
    out.plane_blocks_3x3xP = W_plane;               % <-- keep old name too

    out.measurement_count_by_plane = measurement_count_by_plane;
    out.measurement_count_total = sum(measurement_count_by_plane);

    out.plane_trace = plane_trace;
    out.plane_fro = plane_fro;
    out.active_plane_mask = active_plane_mask;
    out.n_active_plane = nnz(active_plane_mask);

    out.Wr_full = Wr_full;
end