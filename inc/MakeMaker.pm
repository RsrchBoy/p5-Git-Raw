package inc::MakeMaker;

use Moose;
use Config;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;

	my $template = <<'TEMPLATE';
use strict;
use warnings;

use Devel::CheckLib;

my $def = '';
my $lib = '';
my $inc = '';

my %os_specific = (
	'freebsd' => {
		'ssh2' => {
			'inc' => ['/usr/local/include'],
			'lib' => ['/usr/local/lib']
		}
	}
);

if (check_lib(lib => 'ssl')) {
	$def .= ' -DGIT_SSL';
	$lib .= ' -lssl -lcrypto';

	print "SSL support enabled\n";
} else {
	print "SSL support disabled\n";
}

if (check_lib(lib => 'ssh2')) {
	my $os = $^O;

	if (my $os_params = $os_specific{$os}) {
		if (my $ssh2 = $os_params -> {'ssh2'}) {
			if (my $ssh2inc = $ssh2 -> {'inc'}) {
				$inc .= ' -I'.join (' -I', @$ssh2inc);
			}

			if (my $ssh2lib = $ssh2 -> {'lib'}) {
				$lib .= ' -L'.join (' -L', @$ssh2lib);
			}
		}
	}

	$def .= ' -DGIT_SSH';
	$lib .= ' -lssh2';

	print "SSH support enabled\n";
} else {
	print "SSH support disabled\n";
}

my @deps = glob 'deps/libgit2/deps/{http-parser,zlib}/*.c';
my @srcs = glob 'deps/libgit2/src/{*.c,transports/*.c,xdiff/*.c}';
push @srcs, 'deps/libgit2/src/hash/hash_generic.c';

if ($^O eq 'MSWin32') {
	push @srcs, glob 'deps/libgit2/src/{win32,compat}/*.c';
	push @srcs, 'deps/libgit2/deps/regex/regex.c';

	$inc .= ' -Ideps/libgit2/deps/regex';
	$def .= ' -DWIN32 -D_WIN32_WINNT=0x0501 -D__USE_MINGW_ANSI_STDIO=1';
} else {
	push @srcs, glob 'deps/libgit2/src/unix/*.c'
}

my @objs = map { substr ($_, 0, -1) . 'o' } (@deps, @srcs);

sub MY::c_o {
	return <<'EOS'
.c$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.c -o $@
EOS
}

# This Makefile.PL for {{ $distname }} was generated by Dist::Zilla.
# Don't edit it but the dist.ini used to construct it.
{{ $perl_prereq ? qq[BEGIN { require $perl_prereq; }] : ''; }}
use strict;
use warnings;
use ExtUtils::MakeMaker {{ $eumm_version }};
{{ $share_dir_block[0] }}
my {{ $WriteMakefileArgs }}

$WriteMakefileArgs{DEFINE} .= $def;
$WriteMakefileArgs{LIBS}   .= $lib;
$WriteMakefileArgs{INC}    .= $inc;
$WriteMakefileArgs{OBJECT} .= ' ' . join ' ', @objs;

unless (eval { ExtUtils::MakeMaker->VERSION(6.56) }) {
	my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
	my $pp = $WriteMakefileArgs{PREREQ_PM};

	for my $mod (keys %$br) {
		if (exists $pp -> {$mod}) {
			$pp -> {$mod} = $br -> {$mod}
				if $br -> {$mod} > $pp -> {$mod};
		} else {
			$pp -> {$mod} = $br -> {$mod};
		}
	}
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker -> VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
{{ $share_dir_block[1] }}
TEMPLATE

	return $template;
};

override _build_WriteMakefile_args => sub {
	my $inc = '-Ideps/libgit2 -Ideps/libgit2/src -Ideps/libgit2/include -Ideps/libgit2/deps/http-parser -Ideps/libgit2/deps/zlib';
	my $def = '-DNO_VIZ -DSTDC -DNO_GZIP -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE';

	my $bits = $Config{longsize} == 4 ? '-m32' : '';
	my $ccflags = "$bits -Wall -Wno-unused-variable -Wdeclaration-after-statement";

	if ($^O eq 'darwin') {
		$ccflags .= ' -Wno-deprecated-declarations'
	}

	return +{
		%{ super() },
		INC	=> "-I. $inc",
		LIBS	=> "-lrt",
		DEFINE	=> $def,
		CCFLAGS	=> $ccflags,
		OBJECT	=> '$(O_FILES)',
	}
};

__PACKAGE__ -> meta -> make_immutable;
