use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use File::Path 'rmtree';
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Time::Local;
use Test::More;
use Test::More tests => 21;

my $basedir = catdir(dirname(__FILE__), 'bk');
mkdir $basedir if ! -d $basedir;

my $targetdir = catdir(dirname(__FILE__), 'bkt');
{
    mkdir $targetdir if ! -d $targetdir;
    open my $fh, ">", catdir($targetdir, 'a.txt');
    close $fh;
}

# 3:00 AM today
my $ts = timelocal(0, 0, 3, (localtime(time()))[3..5]);

foreach (1..100) {
    $ts -= 86400;
    my $f = catdir($basedir, format_date(localtime($ts)));
    mkdir($f);
    open my $fh, '>', catdir($f, 'a.txt');
    close $fh;
    utime($ts, $ts, $f);
}

# test: basic
{
    system(catdir(dirname(__FILE__), "../backup.sh $basedir $targetdir"));
    
    my @files = files($basedir);
    is(scalar @files, 101, 'right amount of files');
    my @files2 = files(catdir($basedir, $files[-1]));
    is(scalar @files2, 2, 'right amount of files');
    is $files2[0], 'backup.log', 'right file name';
    is $files2[1], 'bkt', 'right directory name';
    my @files3 = files(catdir($basedir, $files[-1], $files2[1]));
    is(scalar @files3, 1, 'right amount of files');
    is $files3[0], 'a.txt', 'right file name';
}

# test2: basic once more
{
    sleep(1);
    system(catdir(dirname(__FILE__), "../backup.sh $basedir $targetdir"));
    
    my @files = files($basedir);
    is(scalar @files, 102, 'right amount of files');
    my @files2 = files(catdir($basedir, $files[-1]));
    is $files2[0], 'backup.log', 'right file name';
    is $files2[1], 'bkt', 'right directory name';
    my @files3 = files(catdir($basedir, $files[-1], $files2[1]));
    is(scalar @files3, 1, 'right amount of files');
    is $files3[0], 'a.txt', 'right file name';
}

# test3: with monthly option
{
    sleep(1);
    system(catdir(dirname(__FILE__), "../backup.sh -m 5 $basedir $targetdir"));
    
    my @files = files($basedir);
    is(scalar @files, 8, 'right amount of files');
    my @files2 = files(catdir($basedir, $files[-1]));
    is $files2[0], 'backup.log', 'right file name';
    is $files2[1], 'bkt', 'right directory name';
    my @files3 = files(catdir($basedir, $files[-1], $files2[1]));
    is(scalar @files3, 1, 'right amount of files');
    is $files3[0], 'a.txt', 'right file name';
}
<>;

# test3: with daily option
{
    sleep(1);
    system(catdir(dirname(__FILE__), "../backup.sh -d 5 $basedir $targetdir"));
    
    my @files = files($basedir);
    is(scalar @files, 8, 'right amount of files');
    my @files2 = files(catdir($basedir, $files[-1]));
    is $files2[0], 'backup.log', 'right file name';
    is $files2[1], 'bkt', 'right directory name';
    my @files3 = files(catdir($basedir, $files[-1], $files2[1]));
    is(scalar @files3, 1, 'right amount of files');
    is $files3[0], 'a.txt', 'right file name';
}

# test3: with option once more
{
    sleep(1);
    system(catdir(dirname(__FILE__), "../backup.sh -d 5 $basedir $targetdir"));
    
    my @files = files($basedir);
    is(scalar @files, 9, 'right amount of files');
    my @files2 = files(catdir($basedir, $files[-1]));
    is $files2[0], 'backup.log', 'right file name';
    is $files2[1], 'bkt', 'right directory name';
    my @files3 = files(catdir($basedir, $files[-1], $files2[1]));
    is(scalar @files3, 1, 'right amount of files');
    is $files3[0], 'a.txt', 'right file name';
}

# cleanup
END {
    rmtree($basedir);
    rmtree($targetdir);
}

sub files {
    my $dir = shift;
    opendir(my $dh, $dir);
    my @files = sort grep {$_ !~ /^\./} readdir $dh;
    closedir($dh);
    return @files;
}

sub format_date {
    my ($s, $m, $h, $md, $mon, $y) = localtime($ts);
    return sprintf(
            "%04d%02d%02dT%02d%02d%02d", $y + 1900, $mon + 1, $md, $h, $m, $s);
}
