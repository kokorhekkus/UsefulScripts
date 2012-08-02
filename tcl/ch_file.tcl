# $Id: ch_file.tcl,v 1.2 2008/10/12 14:40:11 krashad Exp $
#
# A module to help manipulate a text file

namespace eval ch_file {

	variable INFILE
	array set INFILE [list]
	set INFILE(file_present) 0

	# clears any previous file present,
	# no args
	namespace export clear

	# reads in the file to work with
	#   args: -a file token or a file path
	#         -type, which is TOKEN or PATH (defaults to PATH)
	#
	#   returns number of lines read in
	namespace export eat

	# deletes lines
	#   args: -a list of line numbers to delete, or a single
	#         line number to delete (we start from ZERO!)
	namespace export delete

	# inserts a line into the file in memory
	#   args: -a line number (we start from ZERO!)
	#         -a line
	#         -type, A or B, whether to insert the line 'A'fter or
	#          'B'efore the line number (defaults to A)
	namespace export insert

	# writes out the file in memory
	#   args: -a file name/path to which to write to.  If not provided
	#          attempt to use the original file path, which may or may
	#          not be present
	#         -an access arg to 'open', defaults to 'w'
	namespace export write

	# returns the number of lines in the file in memory, no args
	namespace export num_lines

	# returns a list of the line numbers which match a pattern
	#   args: -a pattern to match
	#         -type, which is S (string match) or R (regexp) (defaults to R)
	namespace export match

	# works on the file in memory to search and replace on every line
	#   args: -old expression
	#         -new expression
	#         -type, which is S (string map) or R (regsub) (defaults to S)
	namespace export sar

	# changes a line to the value given
	#   args: -line number
	#         -new value
	namespace export change

	# returns a line, or list of lines
	#   args: -a list of line numbers to get, or a single line number
	#          to get
	namespace export get

	# A quick example of stuff you might do:
	#
	# tclsh8.4 [~]cat test
	# a
	# bc
	# ghij
	#
	# tclsh8.4 [~]source ch_file.tcl
	# tclsh8.4 [~]ch_file::clear
	# 0
	# tclsh8.4 [~]ch_file::eat test
	# 3
	# tclsh8.4 [~]ch_file::insert 1 def A
	# tclsh8.4 [~]foreach line [ch_file::match {^a}] {ch_file::change $line "A"}
	#             (functionally equivalent to 'ch_file::sar {^a} A R')
	# tclsh8.4 [~]ch_file::write
	#
	# tclsh8.4 [~]cat test
	# A
	# bc
	# def
	# ghij
}


########################################################################
#                          EXPORTED PROCS                              #
########################################################################

# clears the file array
proc ch_file::clear {} {
	variable INFILE

	array set INFILE [list]
	set INFILE(file_present) 0
}

# this puts an entire file into an array of lines
proc ch_file::eat {f {type "PATH"}} {
	variable INFILE

	if {[_file_exists]} { error "File already present" }

	if {$type == "PATH"} {
		set INFILE(file_path) $f
		set f [open $f r]
	} else {
		set INFILE(file_path) ""
	}

	set line_num 0
	foreach line [split [read $f] \n] {
		set INFILE($line_num) $line
		incr line_num
	}
	close $f

	set INFILE(num_lines) [expr {$line_num - 1}]
	set INFILE(file_present) 1

	return $INFILE(num_lines)
}

# delete lines, this takes a list of line numbers (and will
# work if you just pass in a single line number too)
proc ch_file::delete {line_nums} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	array set INFILE2 [list]
	set c 0
	for {set i 0} {$i < $INFILE(num_lines)} {incr i} {
		if {[lsearch -exact $line_nums $i] == -1} {
			set INFILE2($c) $INFILE($i)
			incr c
		}
	}
	set INFILE2(num_lines) $c
	set INFILE2(file_present) 1

	array set INFILE [array get INFILE2]
}

# inserts a line - 'type' refers to whether to insert 'A'fter or 'B'efore
# the line number given
proc ch_file::insert {line_num line {type "A"}} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	if {$type == "A"} {
		set newline_num [expr {$line_num + 1}]
	} elseif {$type == "B"} {
		set newline_num $line_num
	} else {
		error "Incorrect type argument to ch_file::insert"
	}

	if {$type == "A"} {
		set type_desc "after"
	} else {
		set type_desc "before"
	}

	if {$line_num < 0 || $line_num >= $INFILE(num_lines)} {
		error "Cannot insert $type_desc line $line_num (no such line)"
	}

	array set INFILE2 [list]
	set c 0
	for {set i 0} {$i < [expr {$INFILE(num_lines) + 1}]} {incr i} {
		if {$i == $newline_num} {
			set INFILE2($c) $line
			set INFILE2([expr {$c + 1}]) $INFILE($i)
			incr c 2
		} else {
			set INFILE2($c) $INFILE($i)
			incr c
		}
	}

	set INFILE2(num_lines) [expr {$INFILE(num_lines) + 1}]
	set INFILE2(file_present) 1

	array set INFILE [array get INFILE2]
}

# write out the INFILE array as a file
proc ch_file::write {{path ""} {open_type "w"}} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	if {$path == ""} {
		if {$INFILE(file_path) != ""} {
			set path $INFILE(file_path)
		} else {
			# just use a default name
			set path "ch_file.out"
		}
	}

	set ftok [open $path $open_type]
	for {set i 0} {$i < $INFILE(num_lines)} {incr i} {
		puts $ftok $INFILE($i)
	}
	close $ftok
}


# get a line or lines
proc ch_file::get {line_nums} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	set l [list]
	foreach line $line_nums {
		if {[info exists INFILE($line)]} {
			lappend l $INFILE($line)
		} else {
			lappend l "NO SUCH LINE NUMBER"
		}
	}
	return $l
}

# get number of lines for file in memory
proc ch_file::num_lines {} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	return $INFILE(num_lines)
}

# do an search-and-replace on all lines in the file in memory
# Type S is string map style, R is regsub style
proc ch_file::sar {old new {type "S"}} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	for {set i 0} {$i < $INFILE(num_lines)} {incr i} {
		if {$type == "S"} {
			set INFILE($i) [string map $old $new $INFILE($i)]
		} elseif {$type == "R"} {
			regsub -all $old $INFILE($i) $new INFILE($i)
		} else {
			error "Incorrect type argument $type to ch_file::sar"
		}
	}
}

# return a list of all line numbers matching regexp
# Type S is string match style, R is regexp style
proc ch_file::match {pattern {type "R"}} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	set line_list [list]
	for {set i 0} {$i < $INFILE(num_lines)} {incr i} {
		if {$type == "S"} {
			if {[string match $pattern $INFILE($i)]} {
				lappend line_list $i
			}
		} elseif {$type == "R"} {
			if {[regexp $pattern $INFILE($i)]} {
				lappend line_list $i
			}
		} else {
			error "Incorrect type argument $type to ch_file::match"
		}
	}
	return $line_list
}

# change a line to something else
# WILL throw an error if line not present
proc ch_file::change {line_num new} {
	variable INFILE

	if {![_file_exists]} { error "No file present to work with" }

	if {[info exists INFILE($line_num)]} {
		set INFILE($line_num) $new
	} else {
		error "Line not present"
	}
}

########################################################################
#                        INTERNAL PROCS                                #
########################################################################

# checks there's a file in memory to work with
proc ch_file::_file_exists {} {
	variable INFILE

	if {$INFILE(file_present)} {
		return 1
	} else {
		return 0
	}
}
