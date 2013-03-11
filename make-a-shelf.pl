#!/usr/bin/env perl
use strict;
use warnings;
use SVG;
use IO::All;

my $output_file = "shelf.svg";

# create an SVG object with a size of 200x200 pixels
my $svg = SVG->new(
    width  => "100cm",
    height => "80cm",
    viewBox => '0 0 1000 800',
);
$svg->title()->cdata('I am a title');

# use explicit element constructor to generate a group element
my $y = $svg->group(
    id    => 'group_y',
    style => {
        stroke => 'black',
        fill => 'none',
    },
);

my $inches_to_mm = sub { $_[0] * 25.4 };
my $material_thickness = 5.5; 

my ($shelf_height, $shelf_width, $shelf_depth);
if (!"Testing mode!") {
    $shelf_height = $inches_to_mm->(1);
    $shelf_width  = $inches_to_mm->(3);
    $shelf_depth  = $inches_to_mm->(3);
}
else {
    $shelf_height = $inches_to_mm->(7.25);
    $shelf_width  = $inches_to_mm->(38);
    $shelf_depth  = $inches_to_mm->(3.5);
}

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

my $smudge = 0.4;

my $shoulder_height = $shelf_height - $material_thickness;
my @support_points = (
    [0, 0], # 1
    [0, $shoulder_height], # 2
    [($shelf_depth / 3) - $smudge, $shoulder_height], # 3
    [($shelf_depth / 3) - $smudge, $shelf_height], # 4
    [($shelf_depth * 2 / 3) + $smudge,, $shelf_height], # 5
    [($shelf_depth * 2 / 3) + $smudge,, $shoulder_height], # 6
    [$shelf_depth, $shoulder_height], # 7
    [$shelf_depth, 0], # 8
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
    $x_offset += $shelf_depth + 10;
}

$x_offset = 10;
$y_offset = $shelf_height + 20;

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
    [ $shelf_width, 0], # 2
    [ $shelf_width, $shelf_depth / 3 ], # 3
    [ $shelf_width - $material_thickness, $shelf_depth / 3], # 4
    [ $shelf_width - $material_thickness, $shelf_depth * 2 / 3], # 5
    [ $shelf_width, $shelf_depth * 2 / 3], # 6
    [ $shelf_width, $shelf_depth ], # 7
    [ 0, $shelf_depth ], # 8
    [ 0, $shelf_depth * 2 / 3 ], # 9
    [ $material_thickness, $shelf_depth * 2 / 3 ], # 10
    [ $material_thickness, $shelf_depth / 3 ], # 11
    [ 0, $shelf_depth / 3 ], # 12
    [ 0, 0 ],
);
my $points = $svg->get_path(
    -type => 'polygon',
    -closed => 1,
    x => [ map { $x_offset + $_->[0] } @shelf_points ],
    y => [ map { $y_offset + $_->[1] } @shelf_points ],
);
$y->polygon(%$points);

my $half_way = $shelf_width / 2;
my @shelf_hole_points = (
    [ $half_way - ($material_thickness / 2), $shelf_depth / 3 ], # 1
    [ $half_way + ($material_thickness / 2), $shelf_depth / 3 ], # 2
    [ $half_way + ($material_thickness / 2), $shelf_depth * 2 / 3 ], # 3
    [ $half_way - ($material_thickness / 2), $shelf_depth * 2 / 3 ], # 3
    [ $half_way - ($material_thickness / 2), $shelf_depth / 3 ], # 3
);
$points = $svg->get_path(
    -type => 'polygon',
    -closed => 1,
    x => [ map { $x_offset + $_->[0] } @shelf_hole_points ],
    y => [ map { $y_offset + $_->[1] } @shelf_hole_points ],
);
$y->polygon(%$points);


# now render the SVG object, implicitly use svg namespace
io($output_file)->print($svg->xmlify);
print "Wrote to $output_file\n";
