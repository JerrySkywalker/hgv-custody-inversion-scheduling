function out = pack_framework_snapshot_all()
opts = struct();
opts.snapshot_name = 'framework_snapshot_all';
opts.scope = 'all';
opts.code_only = false;
opts.include_outputs = true;
opts.include_chapter5 = true;
opts.include_legacy = false;

out = pack_framework_snapshot_core(opts);
end
