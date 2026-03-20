function input_hash = compute_mb_cache_input_hash(spec)
%COMPUTE_MB_CACHE_INPUT_HASH Build a deterministic hash for MB cache inputs.

if nargin < 1 || isempty(spec)
    spec = struct();
end

input_hash = build_mb_eval_cache_key(spec);
end
