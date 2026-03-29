function out = stage14_joint_phase_orientation_formal_package(raw_in, post_in, cfg)
%STAGE14_JOINT_PHASE_ORIENTATION_FORMAL_PACKAGE
% Stage14.4 formal wrapper for final package export.

    if nargin < 1 || isempty(raw_in)
        error('raw_in is required.');
    end
    if nargin < 2 || isempty(post_in)
        error('post_in is required.');
    end
    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end

    legacy_name = local_resolve_legacy_formal_package();
    assert(~isempty(legacy_name), ...
        'Stage14.4 wrapper cannot find legacy A1 formal package function.');

    out = feval(legacy_name, raw_in.raw, post_in, cfg);

    fprintf('\n=== Stage14.4 Formal Package ===\n');
    fprintf('legacy source    : %s\n', legacy_name);
    if isfield(out, 'files')
        disp(out.files)
    end
end

function name = local_resolve_legacy_formal_package()
    candidates = { ...
        'manual_smoke_stage14_A1_formal_package_legacy_prepivot_20260329', ...
        'manual_smoke_stage14_A1_formal_package' ...
        };
    name = "";
    for k = 1:numel(candidates)
        if exist(candidates{k}, 'file') == 2
            name = string(candidates{k});
            return;
        end
    end
end
