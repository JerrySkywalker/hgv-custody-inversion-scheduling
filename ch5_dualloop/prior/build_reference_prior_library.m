function prior_lib = build_reference_prior_library(caseData, cfg)
%BUILD_REFERENCE_PRIOR_LIBRARY
% Build a lightweight static-like reference template library from anchor times.
%
% Output fields per template:
%   anchor_idx
%   ref_ids
%   visible_ids
%   dual_support_ratio
%   single_support_ratio
%   zero_support_ratio
%   longest_single_support_steps
%   longest_zero_support_steps

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

N = numel(caseData.time.t);

if ~isfield(cfg.ch5, 'prior_anchor_count') || isempty(cfg.ch5.prior_anchor_count)
    cfg.ch5.prior_anchor_count = 5;
end

anchor_idx = unique(round(linspace(1, N, cfg.ch5.prior_anchor_count)));
prior_lib = struct( ...
    'anchor_idx', {}, ...
    'ref_ids', {}, ...
    'visible_ids', {}, ...
    'dual_support_ratio', {}, ...
    'single_support_ratio', {}, ...
    'zero_support_ratio', {}, ...
    'longest_single_support_steps', {}, ...
    'longest_zero_support_steps', {});

for i = 1:numel(anchor_idx)
    k = anchor_idx(i);
    visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);

    if isempty(visible_ids)
        continue;
    end

    ref_ids = select_reference_template_dualloop(caseData, k, cfg);
    if isempty(ref_ids)
        continue;
    end

    d = compute_support_window_proxy_dualloop(caseData, ref_ids, k, cfg);

    tpl = struct();
    tpl.anchor_idx = k;
    tpl.ref_ids = ref_ids(:).';
    tpl.visible_ids = visible_ids(:).';
    tpl.dual_support_ratio = d.dual_support_ratio;
    tpl.single_support_ratio = d.single_support_ratio;
    tpl.zero_support_ratio = d.zero_support_ratio;
    tpl.longest_single_support_steps = d.longest_single_support_steps;
    tpl.longest_zero_support_steps = d.longest_zero_support_steps;

    prior_lib(end+1) = tpl; %#ok<AGROW>
end
end
