if 0 {
#
# Ngaro VM for TCL 8.5 
#  
#
ABOUT 
2013-01-02 Original code by Charles Childers from Ngaro VM, the Lua 5.2 and Perl versions 
2013-01-02 Modified by erider in tcl 8.5

Issues: 
  We are reading in an extra byte from retroImage which is a null char :-(

}
interp alias {} push {} lappend

# Helper functions 
proc pop {name} {
  upvar 1 $name stack
  if {![llength $stack]} {error underflow}
  set res [lindex $stack end]
  set stack [lreplace $stack [set stack end] end] 
  set res
}
proc swap {name} {
  upvar 1 $name stack
  push stack [pop stack] [pop stack]
}

# Variables
set ip 0                ;# instruction pointer
set stack {}            ;# data stack
set address {}          ;# return stack
set memory {}           ;# simulated ram
set ports {}            ;# io ports

# Support Code 

proc rxSaveImage {} {
  global memory
  set fp [open retroImage w]
  fconfigure $fp -translation binary 
  for {set i 0} {$i < [lindex $memory 3]} {incr i} {
    puts -nonewline $fp [binary format i [lindex $memory $i]]
  }
  close $fp 
}

proc rxHandleDevices {} { 
  global ports stack ip 
  set i 0 
  if {[lindex $ports 0] == 0} {
      lset ports 0 1
      if {[lindex $ports 1] == 1} {
	  set i [read stdin 1]
	  lset ports 1 [scan $i %c]
	  if {[lindex $ports 1] == 13} {
	    lset ports 1 10
	  }
      }
      if {[lindex $ports 2] == 1} {
	if {[lindex $stack end] < 0} {
	  puts -nonewline "..."
	} else {
	puts -nonewline  [format %c [lindex $stack end]]
	}
	pop stack
	lset ports 2 0 
      }
      if {[lindex $ports 4] == 1} {
	rxSaveImage
	lset ports 4 0 
      }
      switch -- [lindex $ports 5] {
	-1 { lset ports 5 1000000 }
	-2 { lset ports 5 0 }
	-3 { lset ports 5 0 }
	-4 { lset ports 5 0 }  
	-5 { lset ports 5 [llength $stack] }
	-6 { lset ports 5 [llength $address] }
	-7 { lset ports 5 0 }
	-8 { lset ports 5 [clock seconds] }
	-9 { set ip 1000000 }
	-10 { lset ports 5 0 }
	-11 { lset ports 5 0 }
	-12 { lset ports 5 0 }
	-13 { lset ports 5 0 }
      }
   }
}

proc rxProcessOpcode {} {
  global ip memory stack ports address 
  set opcode [lindex $memory $ip] 
  set a 0 
  set b 0 

  if { ($opcode >= 0) && ($opcode <= 30)} {
    switch -- $opcode {
      1 { incr ip; push stack [lindex $memory $ip] } ;# lit 
      2 { push stack [lindex $stack end] } ;# dup 
      3 { pop stack } ;# drop 
      4 { swap stack } ;# swap 
      5 { push address [pop stack] } ;# push  
      6 { push stack [pop address] } ;# pop  
      7 { 
	  push stack [expr [pop stack] - 1]  
	  if {([lindex $stack end] != 0) && ([lindex $stack end] > -1)} { 
	     incr ip; set ip [expr {[lindex $memory $ip] - 1}]
	  } else { 
	    incr ip; pop stack
	  }
	} ;# loop 
      8 { 
	  incr ip
	  set ip [expr {[lindex $memory $ip] - 1}]
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	} ;# jump 
      9 {
	  set ip [pop address] 
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	} ;# return 
      10 {
	  incr ip 
	  if {[lindex $stack end-1] > [lindex $stack end] } { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
          pop stack; pop stack
	 } ;# >= jump 
      11 {
	  incr ip 
	  if {[lindex $stack end-1] < [lindex $stack end]} { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
	  pop stack; pop stack
	 } ;# <= jump 
      12 {
	  incr ip 
	  if {[lindex $stack end-1] != [lindex $stack end] } { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
	  pop stack; pop stack 
	 } ;# != jump 
      13 {
	  incr ip 
	  if {[lindex $stack end-1] == [lindex $stack end] } { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
	  pop stack; pop stack
	 } ;# == jump
      14 { push stack [lindex $memory [pop stack]] } ;# @
      15 { lset memory [pop stack] [pop stack] } ;# ! 
      16 { push stack [expr {[pop stack] + [pop stack]}] } ;# + 
      17 { push stack [expr {[pop stack] - [pop stack]}] } ;# - 
      18 { push stack [expr {[pop stack] * [pop stack]}] } ;# *
      19 {
	  set a [pop stack]; set b [pop stack]
	  push stack [expr {floor($b / $a)}]  
	  push stack [expr $b % $a]; swap stack 
	 } ;# /mod 
      20 { push stack [expr {[pop stack] & [pop stack]}]  } ;# & 
      21 { push stack [expr {[pop stack] | [pop stack]}]  } ;# or 
      22 { push stack [expr {[pop stack] ^ [pop stack]}]  } ;# xor 
      23 { push stack [expr {[pop stack] << [pop stack]}] } ;# << 
      24 { push stack [expr {[pop stack] >> [pop stack]}] } ;# >>
      25 {
	  if {[lindex $stack end] == 0} {
	    pop stack; set ip [pop address]
	  } ;# 0; 
	 }
      26 { push stack [expr {[pop stack] + 1}] } ;# inc  
      27 { push stack [expr {[pop stack] - 1}] } ;# dec 
      28 {
	  set a [pop stack] 
	  push stack [lindex $ports $a] 
	  lset ports $a 0 
	 } ;# in 
      29 { lset ports [pop stack] [pop stack] } ;# out 
      30 { rxHandleDevices } ;# wait 
    } 
      
  } else { 
      push address $ip
      set ip [expr {[lindex $memory $ip] - 1}]
      if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
      if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
    } ;# call 
}

proc rxInitialize {} { 
  global memory ports
  set i 0
  while {$i < 1000000} { lappend memory 0; incr i }
  set i 0
  while {$i < 12} { lappend ports 0; incr i  }
}
  
proc rxLoadImage {} {
  global memory
  set i 0 
  set fp [open retroImage r]
  fconfigure $fp -translation binary 
  while {![eof $fp]} {
    binary scan [read $fp 4] i d 
    lset memory $i [expr {int($d)}]
    incr i 
  }
  close $fp 
}

proc rxMain {} { 
  global ip memory stack address ports 
  rxInitialize
  rxLoadImage 
  while {$ip < 1000000} { 
    rxProcessOpcode; incr ip 
  }
}

# Let start it up 
rxMain 

