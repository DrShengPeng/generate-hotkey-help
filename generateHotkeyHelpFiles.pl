#!/usr/bin/perl
# extract hotkey definitions in .ahk(m4s) files and write them into corresponding help files

chdir "$ENV{'HOME'}/d/git/ahk/output" || die "cannot open ahk directory: $!";

my @ahkFiles = glob "*.ahk"; $rdir = "$ENV{'HOME'}/d/git/ahk/doc";
my $totalFile = 0, $totalHelpFile = 0, $totalHK = 0, $totalHS = 0, $totalIf = 0;
my $HR = "================================================================================\n";
my $HRLen = length($HR)-1;


foreach $ahkFile (@ahkFiles) {
	# skip if module file
    next if $ahkFile =~ /_[a-zA-Z].*.ahk/;
    &extractHotkeysAndWrite($ahkFile);
}
print "$HR\nprocessed $totalFile files and generated $totalHelpFile help files:\n$totalIf #If directives.\n$totalHK HotKeys (exclude those defined with the HOTKEY command).\n$totalHS HotStrings.\n\n";
    
sub extractHotkeysAndWrite {
    my ($file) = @_; $nHK = 0, $nHS = 0, $nIf = 0;
    $totalHelpFile += 1;

    open file, $file || die "Cant open $file!\n";
    open helpFile, ">", "$rdir/help/$file" . ".txt" || die "Cant open hotkeys file!\n";

    while (<file>) {
        chomp();
        if (/#if/i) { # general if directive
            $nIf += 1;
            if (/#if.*;(.*)/i) {
                my $comment=$1; my $ifHRShort = $HRLen - length("==== $comment ");
                my $ifHR = "\n==== $comment " . ( "="x$ifHRShort );
                print helpFile  $ifHR . "\n";
            }
        } elsif (/::(.*)::(.*)/) {
			my $hotstr = $1, $expansion = $2;
			$expansion =~ s/^\s*;\s*(.*)/$1/;
            if ( $nHS & 1 ) {
                printf helpFile "%20s      %s\n", $hotstr, $expansion;
            } else {
                printf helpFile "%20s------%s\n", $hotstr, $expansion;
            }
            $nHS += 1; 
		} elsif (/^([^:]*)::/) { # hotkey must have comments to be processed
			my $hotkey = $1, $comments = "none";
			$hotkey =~ s/\+/Shift + /; # `+' should be processed first
			$hotkey =~ s/\^/Ctrl + /;
			$hotkey =~ s/#/Win + /;
			$hotkey =~ s/!/Alt + /;
			$hotkey =~ s/>/R/g; # might have multiple specification of sides
			$hotkey =~ s/</L/g;
			$hotkey =~ s/&/+/;
            # hotkey might be as long as 'lwin + lctrl + lalt + lshift + printscreen'
            if ( $nHK & 1 ) {
                printf helpFile "%20s      %s\n", $hotkey, $comment;
            } else {
                printf helpFile "%20s------%s\n", $hotkey, $comment;
            }
            $nHK += 1;
		}
    }

    # if nothing defined here
    if ($nHK + $nHS == 0) {
        print "Nothing defined in $file\n";
    }

    print helpFile "\n\n$HR\n$nIf #If directives.\n$nHK HotKeys.\n$nHS HotStrings.\n\n";
    $totalFile += 1; $totalHK += $nHK; $totalHS += $nHS; $totalIf += $nIf;
    close file; close helpFile;
}

system "todos $rdir/help/*";
exit 0;
