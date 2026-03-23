function segments = build_mb_polyline_segments_from_defined_points(x, y, is_defined, max_gap_for_connect)
%BUILD_MB_POLYLINE_SEGMENTS_FROM_DEFINED_POINTS Build broken-line segments over defined points only.

if nargin < 3 || isempty(is_defined)
    is_defined = isfinite(x) & isfinite(y);
end
if nargin < 4 || isempty(max_gap_for_connect)
    max_gap_for_connect = inf;
end

x = reshape(double(x), [], 1);
y = reshape(double(y), [], 1);
is_defined = reshape(logical(is_defined), [], 1);
valid_mask = isfinite(x) & isfinite(y) & is_defined;

segments = cell(0, 1);
if isempty(x) || ~any(valid_mask)
    return;
end

run_start = NaN;
prev_index = NaN;
for idx = 1:numel(x)
    if ~valid_mask(idx)
        [segments, run_start, prev_index] = local_flush_segment(segments, run_start, prev_index, x, y);
        continue;
    end
    if ~isfinite(run_start)
        run_start = idx;
        prev_index = idx;
        continue;
    end
    current_gap = abs(x(idx) - x(prev_index));
    if current_gap > max_gap_for_connect
        [segments, run_start, prev_index] = local_flush_segment(segments, run_start, prev_index, x, y);
        run_start = idx;
        prev_index = idx;
        continue;
    end
    prev_index = idx;
end

[segments, ~, ~] = local_flush_segment(segments, run_start, prev_index, x, y);
end

function [segments, run_start, prev_index] = local_flush_segment(segments, run_start, prev_index, x, y)
if isfinite(run_start) && isfinite(prev_index)
    segment = struct();
    segment.x = x(run_start:prev_index);
    segment.y = y(run_start:prev_index);
    segments{end + 1, 1} = segment; %#ok<AGROW>
end
run_start = NaN;
prev_index = NaN;
end
