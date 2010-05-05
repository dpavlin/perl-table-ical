#!/usr/bin/perl

use warnings;
use strict;

use LWP::Simple;
mirror('http://www.open.hr/dc2010/program.php','program.html');

use Data::Dump qw(dump);

use HTML::TreeBuilder;

my $tree = HTML::TreeBuilder->new;
$tree->parse_file('program.html');

use Data::ICal;
use Data::ICal::Entry::Event;
use Date::ICal;

our $date = {
	day => 4,
	month => 5, 
	year => 2010,
	hour => 9,
	min => 00,
	sec => 00,
};

our $calendar = Data::ICal->new();

sub dt_hhmm {
	my ( $hh, $mm ) = @_;
	my $d = $date;
	$d->{hour} = $hh;
	$d->{min} = $mm;
	Date::ICal->new( %$d )->ical;
}

sub add_event {
  my $vtodo = Data::ICal::Entry::Event->new();
  $vtodo->add_properties( @_ );
  $calendar->add_entry($vtodo);
}


sub parse_table {
	my $tree = shift;
	my $calendar;

	foreach my $tr ($tree->look_down('_tag', 'tr')) {
		my $nr = scalar $tr->content_list;
		my @cols = $tr->look_down('_tag', qr/(td|th)/ );
		warn "# $#cols [$nr] cols ",dump( map { $_->as_text } @cols );
		next if $#cols < 0;

		if ( $#cols == 0 ) {
			$date->{day}++;
		} else {
			my $interval = shift @cols;
			if ( $interval->as_text =~ m/(\d+):(\d+)\s+-\s+(\d+):(\d+)/ ) {
				add_event( summary => $_->as_text, description => $_->as_text,
					dtstart => dt_hhmm( $1, $2 ), dtend => dt_hhmm( $3, $4 ),
				) foreach @cols;
			} else {
				warn "SKIP";
			}
		}
	}
}

parse_table $_ foreach ( $tree->look_down('_tag', 'table' ) );
  
print $calendar->as_string;
