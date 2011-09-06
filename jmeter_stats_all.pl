#!/usr/bin/perl -w
#
#	Version: 	1.0 
#	Author: 	Dmitry Raidman
#	Date: 		30/08/2011
#	Updated: 	
#	
#	External Modules Text::CSV should be installed using: 
#	sudo yum install sudo yum install perl-Text-CSV.noarch 

use strict;
use warnings;
use Text::CSV;
use Time::Local;
use DateTime;

my $input_file = shift;
my $output_file = $input_file;
$output_file =~ s/\.\w+$//;
$output_file = $output_file . ".splunk";
my $csv = Text::CSV->new();
my $time_start = "";
my $time_finish = "";
my $timetaken = "";
my $lines_num = 0;
my $errors_num = 0;
my %err_hash = ();
my %err_timetaken = ();
my %calls = ();
my $column = 0;

if (!$input_file)
{
	print "Usage example: perl $0 <CSV filename>\n";
}
else
{
	$time_start = time();
	print "--------------------------------- Performance Report --------------------------------\n";
	print "*** Starting: [" . localtime($time_start) . "] - processing $input_file\n";

	open (CSV, "<", $input_file) or die $!;
	open(my_output_file, ">$output_file");

	while (<CSV>) {
		next if ($. == 1);
		if ($csv->parse($_)) {
			my @columns = $csv->fields();
			print my_output_file localtime($columns[0]/1000) . "\t" . "TimeTaken=$columns[1]" . "\t" . "ResponseCode=$columns[3]" . "\t" . "RequestType=\"$columns[2]\"" . "\t" . "UserProfile=\"$columns[5]\"" . "\t" . "ConcurentUsers=$columns[10]" . "\t" .  "Size=$columns[8]" . "\t" . "Status=$columns[7]" . "\t" . "ResponseMessage=$columns[4]" . "\t" . "Url=\"$columns[11]\"" . "\n";
			
			$calls{ $columns[11] }-> { $columns[3] . "\t" }++;
			
			$column	= $columns[1];				
			switch: {
                if ( $column <= 25 && $column > 0 ) { $err_timetaken{ '0 - 25(ms)' }++; }
				if ( $column <= 50 && $column > 25 ) { $err_timetaken{ '25 - 50(ms)' }++; }
				if ( $column <= 100 && $column > 50 ) { $err_timetaken{ '50 - 100(ms)' }++; }
				if ( $column <= 200 && $column > 100 ) { $err_timetaken{ '100 - 200(ms)' }++; }
				if ( $column <= 300 && $column > 200 ) { $err_timetaken{ '200 - 300(ms)' }++; }
				if ( $column <= 400 && $column > 300 ) { $err_timetaken{ '300 - 400(ms)' }++; }
				if ( $column <= 500 && $column > 400 ) { $err_timetaken{ '400 - 500(ms)' }++; }
				if ( $column <= 1000 && $column > 500 ) { $err_timetaken{ '0.5 - 1(sec)' }++; }
				if ( $column <= 1500 && $column > 1000 ) { $err_timetaken{ '1 - 1.5(sec)' }++; }
				if ( $column <= 2000 && $column > 1500 ) { $err_timetaken{ '1.5 - 2(sec)' }++; }
				if ( $column <= 2500 && $column > 2000 ) { $err_timetaken{ '2 - 2.5(sec)' }++; }
				if ( $column <= 3000 && $column > 2500 ) { $err_timetaken{ '2.5 - 3(sec)' }++; }
				if ( $column <= 3500 && $column > 3000 ) { $err_timetaken{ '3 - 3.5(sec)' }++; }
				if ( $column <= 4000 && $column > 3500 ) { $err_timetaken{ '3.5 - 4(sec)' }++; }
				if ( $column <= 4500 && $column > 4000 ) { $err_timetaken{ '4 - 4.5(sec)' }++; }
				if ( $column <= 5000 && $column > 4500 ) { $err_timetaken{ '4.5 - 5(sec)' }++; }
				if ( $column <= 10000 && $column > 5000 ) { $err_timetaken{ '5 - 10(sec)' }++; }
                if ( $column <= 15000 && $column > 10000 ) { $err_timetaken{ '10 - 15(sec)' }++; }
                if ( $column <= 20000 && $column > 15000 ) { $err_timetaken{ '15 - 20(sec)' }++; }
				if ( $column <= 30000 && $column > 20000 ) { $err_timetaken{ '20 - 30(sec)' }++; }
                if ( $column <= 60000 && $column > 30000 ) { $err_timetaken{ '30 - 60(sec)' }++; }
				if ( $column > 60000 ) { $err_timetaken{ '60+(sec)' }++; }
            }
			
			if ($columns[3] == 200)
			{
				$err_hash{ $columns[3]. " (". $columns[7] . ")" }++;
			}
			else
			{
				$err_hash{ $columns[3] . "\t" }++;
			}
			
			
			if ($columns[3] > 304)
			{
				$errors_num++;
			}
			$lines_num++;
		} else {
			my $err = $csv->error_input;
			print "Failed to parse line: $err";
		}
	}
	close (my_output_file);
	close CSV;
	$time_finish = time();
	print "*** Finished: [" . localtime($time_start) . "] - processing $input_file\n";
	print "*** Ellapsed proceesing time of $lines_num lines was: " . ($time_finish - $time_start) . " (sec)\n";
	print "*** Errors count: " . $errors_num . "\n";
	print "-------------------------------------------------------------------------------------\n";
	while ( my ($key, $value) = each(%err_hash) ) {
        print "* Response code: $key\t=>\t$value\t[" . sprintf("%.2f", ($value/$lines_num*100)) . "%] \n";
    }
	print "-------------------------------------------------------------------------------------\n";
	foreach my $key (sort {$err_timetaken{$b} <=> $err_timetaken{$a}} (keys(%err_timetaken))) {
		print "* Response times: $key\t=>\t" . $err_timetaken{$key} . "\t[" . sprintf("%.2f", ($err_timetaken{$key}/$lines_num*100)) . "%] \n";
	}
	print "-------------------------------------------------------------------------------------\n";
	# for my $call ( keys %calls ) { 
		# print "$call: \n"; 
		# for my $key ( keys %{ $calls{$call} } ) { 
			# print "$key=$calls{$call}{$key} "; 
		# } print "\n"; 
	# }
	print "-------------------------------------- FIN ------------------------------------------\n";
}
