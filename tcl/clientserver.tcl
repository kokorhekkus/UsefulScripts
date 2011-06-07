#!/usr/bin/tclsh

# Set server running with 'tclsh clientserver.tcl server'
# Set client running with 'tclsh clientserver.tcl client'
#
# Type what needs to be executed at client cmd line , e.g.
# 'test_func' below, this will be evaluated by the server
# and the result returned to the client

set host localhost
set port 11673

if {[lindex $argv 0] == "server"} {
	puts "Server started..."
	socket -server server $port
} else {
	set chan [socket $host $port]
	fconfigure $chan -buffering line
	fileevent $chan readable [list client_read $chan]
	fileevent stdin readable [list client_send $chan]
}

# Server procs
proc server {chan addr port} {
	fconfigure $chan -buffering line
	while {[gets $chan line]>=0} {
		catch $line res
		# local logging
		puts $line->$res
		puts $chan $res
	}
	close $chan
}

# An example of a proc to be executed serverside,
# with the return value passed back to the client
proc test_func {} {
	return [expr {5 + 3}]
}

# Client procs
proc client_read chan {
	if {[eof $chan]} {
		close $chan
		exit
	}
	gets $chan line
	puts <-$line
}
proc client_send chan {
	gets stdin line
	puts $chan $line
}

# End of procs
vwait forever
