function items = generate_monte_carlo_angle_bundle(base_items, num_samples, varargin)
%GENERATE_MONTE_CARLO_ANGLE_BUNDLE Generate Monte Carlo angle-perturbed bundle.
%
%   items = GENERATE_MONTE_CARLO_ANGLE_BUNDLE(base_items, num_samples)
%
%   This first version only attaches angle perturbation samples into the
%   payload. It does not yet propagate dynamics.

p = inputParser;
addRequired(p, 'base_items', @istable);
addRequired(p, 'num_samples', @(x) isnumeric(x) && isscalar(x) && (x >= 1));

addParameter(p, 'class_name', "mc", @(x) ischar(x) || isstring(x));
addParameter(p, 'generator_id', "mc_angle_bundle", @(x) ischar(x) || isstring(x));
addParameter(p, 'variation_kind', "mc_angle", @(x) ischar(x) || isstring(x));
addParameter(p, 'angle_sigma_deg', 5, @(x) isnumeric(x) && isscalar(x) && (x >= 0));
addParameter(p, 'rng_seed', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));

parse(p, base_items, num_samples, varargin{:});
opts = p.Results;

required_vars = { ...
    'traj_id','class_name','bundle_id','source_kind','generator_id', ...
    'base_traj_id','sample_id','variation_kind','payload'};

for k = 1:numel(required_vars)
    if ~ismember(required_vars{k}, base_items.Properties.VariableNames)
        error('generate_monte_carlo_angle_bundle:MissingVariable', ...
            'base_items is missing required variable: %s', required_vars{k});
    end
end

if ~isempty(opts.rng_seed)
    rng(opts.rng_seed);
end

num_samples = double(opts.num_samples);
sigma = double(opts.angle_sigma_deg);

n_base = height(base_items);
n_total = n_base * num_samples;

traj_id = strings(n_total,1);
class_name = repmat(string(opts.class_name), n_total, 1);
bundle_id = strings(n_total,1);
source_kind = repmat("generator", n_total, 1);
generator_id = repmat(string(opts.generator_id), n_total, 1);
base_traj_id = strings(n_total,1);
sample_id = zeros(n_total,1);
variation_kind = repmat(string(opts.variation_kind), n_total, 1);
payload = cell(n_total,1);

row = 0;
for i = 1:n_base
    base_id = string(base_items.traj_id(i));
    base_payload = base_items.payload{i};
    this_bundle_id = base_id + "_mc_angle";

    deltas = sigma .* randn(num_samples, 1);

    for j = 1:num_samples
        row = row + 1;

        traj_id(row) = sprintf('%s_mc_%03d', char(base_id), j);
        bundle_id(row) = this_bundle_id;
        base_traj_id(row) = base_id;
        sample_id(row) = j;

        new_payload = base_payload;
        new_payload.base_traj_id = char(base_id);
        new_payload.bundle_id = char(this_bundle_id);
        new_payload.mc_angle_delta_deg = deltas(j);
        new_payload.sample_id = j;

        payload{row} = new_payload;
    end
end

items = make_trajectory_item_table( ...
    traj_id, class_name, bundle_id, source_kind, generator_id, ...
    base_traj_id, sample_id, variation_kind, payload);
end
