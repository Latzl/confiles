#!/usr/bin/perl

# TODO: this script is written by deepseek, make tests
use strict;
use warnings;
use File::Find;
use Cwd qw(realpath);
use File::Spec;
use Fcntl ':mode';

sub mode_to_permission {
    my $mode = shift;
    my $str  = '';

    if    ( S_ISDIR($mode) )  { $str .= 'd' }
    elsif ( S_ISLNK($mode) )  { $str .= 'l' }
    elsif ( S_ISBLK($mode) )  { $str .= 'b' }
    elsif ( S_ISCHR($mode) )  { $str .= 'c' }
    elsif ( S_ISFIFO($mode) ) { $str .= 'p' }
    elsif ( S_ISSOCK($mode) ) { $str .= 's' }
    else                      { $str .= '-' }

    $str .= ( $mode & S_IRUSR ) ? 'r' : '-';
    $str .= ( $mode & S_IWUSR ) ? 'w' : '-';
    $str .= ( $mode & S_IXUSR ) ? 'x' : '-';

    $str .= ( $mode & S_IRGRP ) ? 'r' : '-';
    $str .= ( $mode & S_IWGRP ) ? 'w' : '-';
    $str .= ( $mode & S_IXGRP ) ? 'x' : '-';

    $str .= ( $mode & S_IROTH ) ? 'r' : '-';
    $str .= ( $mode & S_IWOTH ) ? 'w' : '-';
    $str .= ( $mode & S_IXOTH ) ? 'x' : '-';

    return $str;
}

die "Usage: $0 dir1 dir2 [dir3 ...]\n" if @ARGV < 2;
my @orig_dirs = @ARGV;

my %dir_map;
my @abs_dirs;
for my $dir (@orig_dirs) {
    die "Error: '$dir' is not a directory\n" unless -d $dir;
    my $abs = realpath($dir);
    push @abs_dirs, $abs;
    $dir_map{$abs} = $dir;
}

my %perms;

for my $i ( 0 .. $#abs_dirs ) {
    find(
        {
            wanted => sub {
                return if -l $_;
                my $full_path = $File::Find::name;
                my $rel_path = File::Spec->abs2rel( $full_path, $abs_dirs[$i] );
                $rel_path = '.' if $rel_path eq '';

                my $mode     = ( stat($full_path) )[2] or return;
                my $perm_str = mode_to_permission($mode);

                $perms{$rel_path} //= [];
                $perms{$rel_path}[$i] = $perm_str;
            },
            no_chdir => 1
        },
        $abs_dirs[$i]
    );
}

for my $rel_path ( sort keys %perms ) {
    my $arr = $perms{$rel_path};
    my %seen;

    for my $perm ( grep { defined } @$arr ) {
        $seen{$perm}++;
    }
    next if keys %seen <= 1;

    for my $i ( 0 .. $#abs_dirs ) {
        next unless defined $arr->[$i];

        my $display_path =
            $rel_path eq '.'
          ? $dir_map{ $abs_dirs[$i] }
          : File::Spec->catfile( $dir_map{ $abs_dirs[$i] }, $rel_path );

        print "$arr->[$i] $display_path\n";
    }
    print "\n" if grep { defined } @$arr;
}
