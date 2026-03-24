function out = pack_framework_snapshot_all_legacy()
opts = struct();
opts.snapshot_name = 'framework_snapshot_all_legacy';
opts.scope = 'all';
opts.code_only = false;
opts.include_outputs = true;
opts.include_chapter5 = true;
opts.include_legacy = true;

out = pack_framework_snapshot_core(opts);
end
