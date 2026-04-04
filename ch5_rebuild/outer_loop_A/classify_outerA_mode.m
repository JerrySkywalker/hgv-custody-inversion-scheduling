function mode_out = classify_outerA_mode(outerA)
%CLASSIFY_OUTERA_MODE Classify outerA mode from \tilde{M}_R correction state.
%
% Inputs:
%   outerA : struct from compute_outerA_upper_bound_tildeMR
%
% Output:
%   mode_out.label
%   mode_out.code
%
% Codes:
%   1 -> safe
%   2 -> warn
%   3 -> repair
%   4 -> emergency

assert(isstruct(outerA), 'outerA must be a struct.');
required_fields = {'GammaA','gs','gg','gp'};
for i = 1:numel(required_fields)
    assert(isfield(outerA, required_fields{i}), 'outerA missing field: %s', required_fields{i});
end

GammaA = outerA.GammaA;
peak_comp = max([outerA.gs, outerA.gg, outerA.gp]);

if GammaA < 1.15 && peak_comp < 0.55
    label = 'safe';
    code = 1;
elseif GammaA < 1.40
    label = 'warn';
    code = 2;
elseif GammaA < 1.80
    label = 'repair';
    code = 3;
else
    label = 'emergency';
    code = 4;
end

mode_out = struct();
mode_out.label = label;
mode_out.code = code;
end
