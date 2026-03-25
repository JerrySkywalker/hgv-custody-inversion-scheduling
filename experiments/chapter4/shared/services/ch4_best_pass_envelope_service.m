function envelope_result = ch4_best_pass_envelope_service(grid_table, slice_spec)
%CH4_BEST_PASS_ENVELOPE_SERVICE Build the Stage05-style best-pass envelope.
% Inputs:
%   grid_table  : table with at least Ns and pass_ratio
%   slice_spec  : optional struct of exact-match slice filters, e.g. struct('i_deg', 60)
%
% Output:
%   envelope_result : struct with Ns, best_pass, best_joint_margin, argmax_design_id, envelope_table

if nargin < 2 || isempty(slice_spec)
    slice_spec = struct();
end

envelope_table = build_best_envelope( ...
    grid_table, 'Ns', 'pass_ratio', slice_spec, 'max');
if ismember('pass_ratio', envelope_table.Properties.VariableNames)
    envelope_table = renamevars(envelope_table, 'pass_ratio', 'best_pass');
end

envelope_result = struct();
envelope_result.Ns = envelope_table.Ns;
envelope_result.best_pass = envelope_table.best_pass;
envelope_result.best_joint_margin = envelope_table.best_joint_margin;
envelope_result.argmax_design_id = envelope_table.argmax_design_id;
envelope_result.envelope_table = envelope_table;
envelope_result.slice_spec = slice_spec;
end
