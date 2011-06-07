#!/usr/bin/tclsh

# simple example of using http and tdom packages to screen-scrape,
# by turning possibly crap HTML into a DOM tree and parsing it

package require http
package require tdom

set url "http://www.google.co.uk"

set tok [::http::geturl $url]
set dat [::http::data  $tok]

set dom [dom parse -html $dat]
set root [$dom documentElement]

# show entire page as XML
#puts [$root asXML]

# get all tables
set tables [$root getElementsByTagName table]

# get head
set head_node [$root firstChild]

# get body
set body_node [$head_node nextSibling]

# get title element
set node [$head_node firstChild]
set node [$node nextSibling]

puts [$node asXML]
puts [$node text]

# Alternately, use XPath to do above
set node [$root selectNodes head/title/text()]
puts "Using XPath:"
puts [$node asXML]
