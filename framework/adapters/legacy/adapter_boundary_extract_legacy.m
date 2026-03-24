function boundary_result = adapter_boundary_extract_legacy(eval_rows)
% Minimal adapter placeholder for legacy minimum-boundary extraction.

if nargin < 1
    eval_rows = [];
end

boundary_result = struct();
boundary_result.rows = eval_rows;
boundary_result.meta = struct('source', 'legacy', 'status', 'placeholder');
end
