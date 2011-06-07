#!/usr/bin/tclsh

# this monitors free space on a box, and when a
# threshold is reached, emails someone a warning
#
# "logs" to stdout, so when you set it up, redirect
# stdout to where you want the log file to be.
#
# meant to be run as a cron job
#
# uses a bit of a hack for email, not EZ-SMTP or
# whatever it is we normally use.  Hence, you'll
# need a properly configured sendmail.  Basically,
# will only run on Linux and SunOS/Solaris, but easy
# to make work with other *nixes.

##########
# CONFIG #
##########

# address to send warnings to
global SEND_ADDRESS
set SEND_ADDRESS "krashad@orbisuk.com"

# percentage of disc space left at which a warning
# is emailed to $SEND_ADDRESS
set WARN_PCT 10

# run on filesystem where this inode resides,
# takes values like "", ".", "/tmp", ...
set INODE "/"

##############
# PROCEDURES #
##############

#
# find used percentage of a directory
#
proc used_pct {{inode ""}} {
	global tcl_platform

	if {$inode == ""} {
		set inode [pwd]
	}

	# default Linux options
	set executable df
	set options ""

	switch $tcl_platform(os) {
        SunOS {
			# "broad-sense" SunOS; includes Solaris.
			set options -k
        }
		Linux -
		default {
			# empty
		}
	}

	if [catch {eval exec $executable $options $inode | tail -1} line] {
		puts [exec date]
		puts "df error: $line"
		return "ERR"
	}

	regexp { ([0-9][0-9])% } $line match pct
	if {[string is integer $pct]} {
		return $pct
	} else {
		error "$pct is not an integer"
	}
}

#
# send warning mail
#
proc tsend_mail {{pct ""} {inode ""}} {
	global SEND_ADDRESS

	# set up email
	set address $SEND_ADDRESS
	set subject "Disk Space Warning!"
	set this_box [exec uname -n]
	set body "Disk usage warning triggered from $this_box\n\n"

	if {$inode == ""} {
		set inode [pwd]
	}

	if {$pct == ""} {
		set body "${body}No percentage of used space available"
	} else {
		set body "${body}Percentage space used: $pct ($inode)"
	}

	# send mail
    set tmail [open "|mail $address" r+]
	puts $tmail "Subject: ${subject}\n"
	puts $tmail $body
	close $tmail
}

########
# MAIN #
########

set root_used_pct [used_pct $INODE]

if {$root_used_pct != "ERR"} {
	set free_pct [expr {100 - $root_used_pct}]

	if {$free_pct <= $WARN_PCT} {
		if [catch {tsend_mail $free_pct $INODE} msg] {
			puts [exec date]
			puts $msg
		} else {
			puts [exec date]
			puts "Low disk space:- ${free_pct} percent free (${INODE})."
		}
	} else {
		puts [exec date]
		puts "${free_pct} percent free (${INODE})."
	}
}
