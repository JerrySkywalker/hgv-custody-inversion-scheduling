function slice_result = slice_service(truth_result, slice_spec)
if nargin < 1 || ~isstruct(truth_result) || ~isfield(truth_result, 'table')
    error('slice_service:InvalidInput', ...
        'truth_result with table field is required.');
end

if nargin < 2 || ~isstruct(slice_spec)
    slice_spec = struct();
end

slice_mode = 'PT';
if isfield(slice_spec, 'mode') && ~isempty(slice_spec.mode)
    slice_mode = upper(string(slice_spec.mode));
end

tbl = truth_result.table;

switch char(slice_mode)
    case 'PT'
        vars = {'design_id','P','T','Ns','joint_margin','is_feasible','fail_reason'};
    case 'HI'
        vars = {'design_id','h_km','i_deg','Ns','joint_margin','is_feasible','fail_reason'};
    otherwise
        error('slice_service:UnsupportedMode', ...
            'Unsupported slice mode: %s', slice_mode);
end

slice_table = tbl(:, vars);

slice_result = struct();
slice_result.mode = char(slice_mode);
slice_result.table = slice_table;
slice_result.row_count = height(slice_table);
slice_result.meta = struct('status', 'ok');
end
