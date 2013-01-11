if 0 {
#
# Ngaro VM for TCL 8.5 
#  
#
ABOUT 
2013-01-02 Original code by Charles Childers from Ngaro VM for Lua 5.2 and Perl 
2013-01-02 Modified by erider in tcl 

Issues: 
  rxLoadImage is reading in an extra byte which is a null char :-(

}

# Helper functions 
interp alias {} push {} lappend

proc pop {name} {
  upvar 1 $name stack
  set res [lindex $stack end]
  set stack [lreplace $stack [set stack end] end] 
  set res
}

# Variables
set ip 0                ;# instruction pointer
set sp 0                ;# stack pointer
set rp 0                ;# return pointer
set i 0                 ;# generic loop index 
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
  global ports stack sp rp ip i
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
	if {[lindex $stack $sp] < 0} {
	  puts -nonewline "..."
	} else {
	puts -nonewline  [format %c [lindex $stack $sp]]
	}
	incr sp -1 
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
	-5 { lset ports 5 $sp }
	-6 { lset ports 5 $rp }
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
  global ip memory stack ports sp address rp 
  set opcode [lindex $memory $ip] 
  set a 0 
  set b 0 

  if { ($opcode >= 0) && ($opcode <= 30)} {
    switch -- $opcode {
      1 { incr sp; incr ip; lset stack $sp [lindex $memory $ip] }
      2 { incr sp; lset stack $sp [lindex $stack [expr {$sp - 1}]] }
      3 { incr sp -1 } 
      4 { 
	set a [lindex $stack $sp]
	lset stack $sp [lindex $stack [expr {$sp - 1}]]
	lset stack [expr {$sp - 1}] $a 
	}
      5 { incr rp; lset address $rp [lindex $stack $sp]; incr sp -1 } 
      6 { incr sp; lset stack $sp [lindex $address $rp]; incr rp -1 } 
      7 { 
	  lset stack $sp [expr [lindex $stack $sp] - 1]
	  if {([lindex $stack $sp] != 0) && ([lindex $stack $sp] > -1)} { 
	     incr ip; set ip [expr {[lindex $memory $ip] - 1}]
	  } else { 
	    incr ip; incr sp -1 
	  }
	}
      8 { 
	  incr ip
	  set ip [expr {[lindex $memory $ip] - 1}]
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	}
      9 {
	  set ip [lindex $address $rp]
	  incr rp -1 
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	  if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
	}
      10 {
	  incr ip 
	  if {[lindex $stack [expr $sp - 1]] > [lindex $stack $sp] } { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
	  incr sp -2 
	 }
      11 {
	  incr ip 
	  if {[lindex $stack [expr $sp - 1]] < [lindex $stack $sp]} { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
	  incr sp -2 
	 }
      12 {
	  incr ip 
	  if {[lindex $stack [expr $sp - 1]] != [lindex $stack $sp] } { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
	  incr sp -2 
	 }
      13 {
	  incr ip 
	  if {[lindex $stack [expr $sp - 1]] == [lindex $stack $sp] } { 
	    set ip [expr [lindex $memory $ip] - 1] 
	  }
	  incr sp -2 
	 }
      14 {
	  lset stack $sp [lindex $memory [lindex $stack $sp]]
	 }
      15 {
	  lset memory [lindex $stack $sp] [lindex $stack [expr {$sp - 1}]]; incr sp -2 
	 }
      16 {
	  lset stack [expr $sp - 1] [expr ([lindex $stack $sp]) + ([lindex $stack [expr $sp - 1]])]
	  incr sp -1 
	 }
      17 {
	  lset stack [expr $sp - 1] [expr ([lindex $stack $sp]) - ([lindex $stack [expr $sp - 1]])]
	  incr sp -1 
	 }
      18 {
	  lset stack [expr $sp - 1] [expr [lindex $stack $sp] * [lindex $stack [expr $sp - 1]]]
	  incr sp -1  
	 }
      19 {
	  set a [lindex $stack $sp]; set b [lindex $stack [expr $sp - 1]]
	  lset stack $sp [expr {floor($b / $a)}]  
	  lset stack [expr $sp - 1] [expr $b % $a] 
	 }
      20 {
	  set a [lindex $stack $sp]; set b [lindex $stack [expr $sp - 1]]
	  incr sp -1; lset stack $sp [expr $b & $a]
	 }
      21 {
	  set a [lindex $stack $sp]; set b [lindex $stack [expr $sp - 1]]
	  incr sp -1; lset stack $sp [expr $b | $a]
	 }
      22 {
	  set a [lindex $stack $sp]; set b [lindex $stack [expr $sp - 1]]
	  incr sp -1; lset stack $sp [expr $b ^ $a]
	 }
      23 {
	  set a [lindex $stack $sp]; set b [lindex $stack [expr $sp - 1]]
	  incr sp -1; lset stack $sp [expr $b << $a]
	 }
      24 {
	  set a [lindex $stack $sp]; set b [lindex $stack [expr $sp - 1]]
	  incr sp -1; lset stack $sp [expr $b >> $a]
	 }
      25 {
	  if {[lindex $stack $sp] == 0} {
	    incr sp -1; set ip [lindex $address $rp]; incr rp -1
	  }
	 }
      26 {
	  lset stack $sp [expr [lindex $stack $sp] + 1] 
	 }
      27 {
	  lset stack $sp [expr [lindex $stack $sp] - 1]
	 }
      28 {
	  set a [lindex $stack $sp] 
	  lset stack $sp [lindex $ports $a] 
	  lset ports $a 0 
	 }
      29 {
	  lset ports [lindex $stack $sp] [lindex $stack [expr $sp - 1]]; incr sp -2 
	 }
      30 { rxHandleDevices }
    } 
      
  } else { 
      incr rp
      lset address $rp $ip
      set ip [expr [lindex $memory $ip] - 1]
      if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
      if {[lindex $memory [expr $ip + 1]] == 0} { incr ip } 
    }
}

proc rxInitialize {} {
  global memory stack address ports
  set i 0 
  while {$i < 1000000} { 
    lappend memory 0 
    incr i 
  }
  set i 0 
  while {$i < 12} {
    lappend stack 0 
    lappend address 0
    lappend ports 0 
    incr i 
  }
  while {$i < 128} { 
    lappend stack 0 
    lappend address 0
    incr i 
  }
  while {$i < 1024} {
    lappend address 0
    incr i 
  }
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
  global ip 
  rxInitialize
  rxLoadImage 
  while {$ip < 1000000} { 
    rxProcessOpcode; incr ip 
  }
}

# Let start it up 
rxMain 

