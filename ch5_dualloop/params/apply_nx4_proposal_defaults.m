function cfg = apply_nx4_proposal_defaults(cfg)
%APPLY_NX4_PROPOSAL_DEFAULTS
% NX-4 first round defaults for proposal-only layer.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

if ~isfield(cfg.ch5, 'nx4_proposal_enable') || isempty(cfg.ch5.nx4_proposal_enable)
    cfg.ch5.nx4_proposal_enable = true;
end

if ~isfield(cfg.ch5, 'nx4_reference_k') || isempty(cfg.ch5.nx4_reference_k)
    cfg.ch5.nx4_reference_k = 1;
end

if ~isfield(cfg.ch5, 'nx4_library_pair_cap') || isempty(cfg.ch5.nx4_library_pair_cap)
    cfg.ch5.nx4_library_pair_cap = 10;
end

if ~isfield(cfg.ch5, 'nx4_current_pair_cap') || isempty(cfg.ch5.nx4_current_pair_cap)
    cfg.ch5.nx4_current_pair_cap = 20;
end

if ~isfield(cfg.ch5, 'nx4_topk') || isempty(cfg.ch5.nx4_topk)
    cfg.ch5.nx4_topk = 4;
end
end
