function out = compute_gap_metrics_stage09(t_s, num_visible, cfg_or_stage09)
%COMPUTE_GAP_METRICS_STAGE09
% Compute Stage09 time-gap metrics from visibility time history.
%
% Formal idea:
%   custody-active(k) := num_visible(k) >= visibility_min_for_custody
%   max_gap_s         := longest consecutive inactive interval
%   DT                := dt_crit_s / max_gap_s
%
% Inputs
%   t_s           : time vector [Nt x 1]
%   num_visible   : number of visible satellites [Nt x 1]
%   cfg_or_stage09: cfg or cfg.stage09-like struct
%
% Outputs
%   out.max_gap_s
%   out.num_gap_segments
%   out.custody_ratio
%   out.active_mask
%   out.DT
%   out.ok

    if nargin < 3
        error('compute_gap_metrics_stage09 requires t_s, num_visible, cfg_or_stage09.');
    end

    s9 = local_pick_stage09(cfg_or_stage09);

    t_s = t_s(:);
    num_visible = num_visible(:);

    if numel(t_s) ~= numel(num_visible)
        error('t_s and num_visible must have the same length.');
    end
    if numel(t_s) < 1
        error('t_s must be non-empty.');
    end

    active_mask = num_visible >= s9.visibility_min_for_custody;
    inactive_mask = ~active_mask;

    if numel(t_s) == 1
        dt_nominal = 0;
    else
        dt_nominal = median(diff(t_s));
    end

    % Find consecutive inactive segments
    d = diff([false; inactive_mask; false]);
    seg_start = find(d == 1);
    seg_end   = find(d == -1) - 1;

    num_seg = numel(seg_start);
    gap_lengths_s = zeros(num_seg, 1);

    for k = 1:num_seg
        i0 = seg_start(k);
        i1 = seg_end(k);
        if i1 <= i0
            gap_lengths_s(k) = dt_nominal;
        else
            gap_lengths_s(k) = max(t_s(i1) - t_s(i0), 0) + dt_nominal;
        end
    end

    if isempty(gap_lengths_s)
        max_gap_s = 0;
    else
        max_gap_s = max(gap_lengths_s);
    end

    if max_gap_s <= 0
        DT = inf;
    else
        DT = s9.dt_crit_s / max_gap_s;
    end

    out = struct();
    out.max_gap_s = max_gap_s;
    out.num_gap_segments = num_seg;
    out.gap_lengths_s = gap_lengths_s;
    out.custody_ratio = mean(active_mask, 'omitnan');
    out.active_mask = active_mask;
    out.DT = DT;
    out.ok = isfinite(DT) || isinf(DT);
end


function s9 = local_pick_stage09(cfg_or_stage09)

    if isstruct(cfg_or_stage09) && isfield(cfg_or_stage09, 'stage09')
        s9 = cfg_or_stage09.stage09;
    else
        s9 = cfg_or_stage09;
    end
end