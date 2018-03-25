use strict;
use warnings;

use Test::More;
use Test::Git;

use File::chdir;
use Path::Tiny;

use Git::Raw::Repository;

my $r = test_repository;

my $repo = Git::Raw::Repository->open($r->git_dir);
isa_ok $repo, 'Git::Raw::Repository';

is path($repo->workdir) => path($r->work_tree),
    'worktree correct';
is path($repo->commondir) => path($r->run('rev-parse', '--git-common-dir')),
    'commondir correct';
ok $repo->is_worktree, 'is_worktree() correct';

done_testing;
