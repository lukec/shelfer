#!/usr/bin/env perl
use strict;
use warnings;
use SVG;
use IO::All;
use Getopt::Long;

my %p;
GetOptions( \%p,
    'height|h=s',
    'width|w=s',
    'depth|d=s',
    'output|o=s',
    'smudge|s=s',
) or usage();

$p{smudge} //= 1.417;
$p{output} //= 'shelf.svg';

# create an SVG object with a size of 200x200 pixels
# XXX This seems to not export into .dxf format very well.
# Loial says it defaults to 90dpi
my $svg = SVG->new(
    width  => "100cm",
    height => "80cm",
);
$svg->title()->cdata('I am a shelf');

# use explicit element constructor to generate a group element
my $y = $svg->group(
    id    => 'group_y',
    style => {
        stroke => 'black',
        fill => 'none',
    },
);

my $inches_to_dpi = sub { $_[0] * 90 };
my $material_thickness = 19.5;

#     25.4mm, but gap is 26.2 = 0.8mm -> 0.4mm tweak
#    +----+
#    |4  5|
# +--+    +--+
# |2  3  6  7|
# |          |
# |          |
# |          |
# |1        8|
# +----------+

my $shoulder_height = $p{height} - $material_thickness;
my @support_points = (
    [0, 0], # 1
    [0, $shoulder_height], # 2
    [($p{depth} / 3) - $p{smudge}, $shoulder_height], # 3
    [($p{depth} / 3) - $p{smudge}, $p{height}], # 4
    [($p{depth} * 2 / 3) + $p{smudge}, $p{height}], # 5
    [($p{depth} * 2 / 3) + $p{smudge}, $shoulder_height], # 6
    [$p{depth}, $shoulder_height], # 7
    [$p{depth}, 0], # 8
    [0,0],
);

my ($x_offset, $y_offset) = (10, 10);
# First, make the 3 supports
for (1 .. 3) {
    my $points = $svg->get_path(
        -type => 'polygon',
        -closed => 1,
        x => [ map { $x_offset + $_->[0] } @support_points ],
        y => [ map { $y_offset + $_->[1] } @support_points ],
    );
    $y->polygon(%$points);
    $x_offset += $p{depth} + 10;
}

$x_offset = 10;
$y_offset = $p{height} + 20;

# Now make the long shelf

# 1                                  2
# +----------------------------------+
# |12                                |
# +--+ 11        1+--+2         4 +--+ 3
#    |            |  |            |
# +--+ 10        4+--+3         5 +--+ 6
# |9                                 |
# +----------------------------------+ 7
# 8


my @shelf_points = (
    [ 0, 0], # 1
    [ $p{width}, 0], # 2
    [ $p{width}, $p{depth} / 3 ], # 3
    [ $p{width} - $material_thickness, $p{depth} / 3], # 4
    [ $p{width} - $material_thickness, $p{depth} * 2 / 3], # 5
    [ $p{width}, $p{depth} * 2 / 3], # 6
    [ $p{width}, $p{depth} ], # 7
    [ 0, $p{depth} ], # 8
    [ 0, $p{depth} * 2 / 3 ], # 9
    [ $material_thickness, $p{depth} * 2 / 3 ], # 10
    [ $material_thickness, $p{depth} / 3 ], # 11
    [ 0, $p{depth} / 3 ], # 12
    [ 0, 0 ],
);
my $points = $svg->get_path(
    -type => 'polygon',
    -closed => 1,
    x => [ map { $x_offset + $_->[0] } @shelf_points ],
    y => [ map { $y_offset + $_->[1] } @shelf_points ],
);
$y->polygon(%$points);

my $half_way = $p{width} / 2;
my @shelf_hole_points = (
    [ $half_way - ($material_thickness / 2), $p{depth} / 3 ], # 1
    [ $half_way + ($material_thickness / 2), $p{depth} / 3 ], # 2
    [ $half_way + ($material_thickness / 2), $p{depth} * 2 / 3 ], # 3
    [ $half_way - ($material_thickness / 2), $p{depth} * 2 / 3 ], # 3
    [ $half_way - ($material_thickness / 2), $p{depth} / 3 ], # 3
);
$points = $svg->get_path(
    -type => 'polygon',
    -closed => 1,
    x => [ map { $x_offset + $_->[0] } @shelf_hole_points ],
    y => [ map { $y_offset + $_->[1] } @shelf_hole_points ],
);
$y->polygon(%$points);

io($p{output})->print($svg->xmlify);
print "Wrote to $p{output}\n";
exit;



sub usage {
    die <<EOT }
USAGE: $0 [-w|--width=30] [-h|--height=8] [-d|--depth=5] [-o outputfilename]

  --smudge=1.5 - set this to half the width of the laser, in DPI

All dimensions should be specified in inches.  I know, right? Why not metric, the author is a Canadian, too.  Disgraceful.
EOT

__DATA__

if (!"Testing mode!") {
    $p{height} = $inches_to_dpi->(1);
    $p{width}  = $inches_to_dpi->(3);
    $p{depth}  = $inches_to_dpi->(3);
}
else {
    if (! "Tea shelf") {
        $p{height} = $inches_to_dpi->(7.25);
        $p{width}  = $inches_to_dpi->(38);
        $p{depth}  = $inches_to_dpi->(3.5);
    }
    elsif ("Baking Shelf") {
        $p{height} = $inches_to_dpi->(7.5);
        $p{width}  = $inches_to_dpi->(37);
        $p{depth}  = $inches_to_dpi->(8);
    }
}

