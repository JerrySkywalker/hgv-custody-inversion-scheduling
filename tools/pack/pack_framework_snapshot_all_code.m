function out = pack_framework_snapshot_all_code()
opts = struct();
opts.snapshot_name = 'framework_snapshot_all_code';
opts.scope = 'all';
opts.code_only = true;
opts.include_outputs = false;
opts.include_chapter5 = true;
opts.include_legacy = false;

out = pack_framework_snapshot_core(opts);
end
