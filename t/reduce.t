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
use Test::More tests => 32;

my $basedir = catdir(dirname(__FILE__), 'bk');

{
    my $today = epoch('2018-11-30 03:00:00');
    init($today);
    $today++;
    system(catdir(dirname(__FILE__), "../reduce.sh -m 3 -d 5 -t $today $basedir"));
    is scalar files($basedir), 8, 'right amount';
    ok -d "$basedir/20180901T030000";
    ok -d "$basedir/20181001T030000";
    ok -d "$basedir/20181101T030000";
    ok -d "$basedir/20181125T030000";
    ok -d "$basedir/20181126T030000";
    ok -d "$basedir/20181127T030000";
    ok -d "$basedir/20181128T030000";
    ok -d "$basedir/20181129T030000";
    rmtree($basedir);
}

{
    my $today = epoch('2018-11-02 03:00:00');
    init($today);
    $today++;
    system(catdir(dirname(__FILE__), "../reduce.sh -m 3 -d 5 -t $today $basedir"));
    is scalar files($basedir), 7, 'right amount';
    ok -d "$basedir/20180901T030000";
    ok -d "$basedir/20181001T030000";
    ok -d "$basedir/20181028T030000";
    ok -d "$basedir/20181029T030000";
    ok -d "$basedir/20181030T030000";
    ok -d "$basedir/20181031T030000";
    ok -d "$basedir/20181101T030000";
    rmtree($basedir);
}

# case: -d is bigger than -m
{
    my $today = epoch('2018-11-30 03:00:00');
    init($today);
    $today++;
    system(catdir(dirname(__FILE__), "../reduce.sh -d 35 -m 1 -t $today $basedir"));
    is scalar files($basedir), 30, 'right amount';
    ok -d "$basedir/20181031T030000";
    ok -d "$basedir/20181129T030000";
    rmtree($basedir);
}

# case: -m is omitted
{
    my $today = epoch('2018-11-30 03:00:00');
    init($today);
    $today++;
    system(catdir(dirname(__FILE__), "../reduce.sh -d 2 -t $today $basedir"));
    is scalar files($basedir), 8, 'right amount';
    ok -d "$basedir/20180601T030000";
    ok -d "$basedir/20180701T030000";
    ok -d "$basedir/20180801T030000";
    ok -d "$basedir/20180901T030000";
    ok -d "$basedir/20181001T030000";
    ok -d "$basedir/20181101T030000";
    ok -d "$basedir/20181128T030000";
    ok -d "$basedir/20181129T030000";
    rmtree($basedir);
}

# case: -d is omitted
{
    my $today = epoch('2018-11-30 03:00:00');
    init($today);
    $today++;
    system(catdir(dirname(__FILE__), "../reduce.sh -m 2 -t $today $basedir"));
    is scalar files($basedir), 61, 'right amount';
    ok -d "$basedir/20180930T030000";
    ok -d "$basedir/20181129T030000";
    rmtree($basedir);
}

sub files {
    my $dir = shift;
    opendir(my $dh, $dir);
    my @files = sort grep {$_ !~ /^\./} readdir $dh;
    closedir($dh);
    return @files;
}

sub format_date {
    my ($s, $m, $h, $md, $mon, $y) = @_;
    return sprintf(
            "%04d%02d%02dT%02d%02d%02d", $y + 1900, $mon + 1, $md, $h, $m, $s);
}

sub epoch {
  my $str = shift;
  $str =~ qr{(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)};
  return timelocal($6, $5, $4, $3, $2 - 1, $1 - 1900);
}

sub init {
    mkdir $basedir if ! -d $basedir;
    
    my $today = shift;
    my $ts = timelocal(0, 0, 3, (localtime($today))[3..5]);
    
    foreach (1..190) {
        $ts -= 86400;
        my $f = catdir($basedir, format_date(localtime($ts)));
        mkdir($f);
        open my $fh, '>', catdir($f, 'a.txt');
        close $fh;
        utime($ts, $ts, $f);
    }
}
