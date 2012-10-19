"""
external test suite for ngaro implementations
-----------------------------------------------
Copyright (c) 2012 Michal J Wallace
Available to the public under the ISC license.
-----------------------------------------------
This test suite depends on implementation of a 
switch, --dump, which dumps the internal state
of the interpreter to stdout on completion, in 
the following format:

 chr( 1 )  # ascii start of header
   'dbg'
 chr( 2 )  # ascii start of text
   str( ip )
 chr( 30 ) # ascii record separator
   ' '.join( str( i ) for i in data_stack )
 chr( 30 )
   ' '.join( str( i ) for i in addr_stack )
 chr( 30 )
   ' '.join( str( i ) for i in ram )
 chr( 3 )  # ascii end of text

By default, the tests expect the ngaro interpreter
to be invoked with the command "./retro". To override
this, set the NGARO_PATH environment variable.

For example, in bash:

  export NGARO_CMD='python /path/to/retro.py'

The command invoked for each test will then be:

  python /path/to/retro.py --dump ngarotest.img

"""
import unittest, os, array, sys
NGARO_CMD = os.environ.get( "NGARO_CMD", './retro' )
NGARO_IMG = os.environ.get( "NGARO_IMG", './ngarotest.img' )


# opcode list and helper functions

ops = {
  "nop"   : 0,   "lit"   : 1,   "dup"   : 2,    "drop"  : 3,
  "swap"  : 4,   "push"  : 5,   "pop"   : 6,    "loop"  : 7,
  "jump"  : 8,   ";"     : 9,   "<jump" : 10,   ">jump" : 11,
  "!jump" : 12,  "=jump" : 13,  "@"     : 14,   "!"     : 15 ,
  "+"     : 16,  "-"     : 17,  "*"     : 18,   "/mod"  : 19,
  "and"   : 20,  "or"    : 21,  "xor"   : 22,   "<<"    : 23,
  ">>"    : 24,  "0;"    : 25,  "1+"    : 26,   "1-"    : 27,
  "in"    : 28,  "out"   : 29,  "wait"  : 30,
}


def is_int( x ):
  res = True
  try: int( x )
  except ValueError: res = False
  return res


def trim( s ):
  """
  strips leading indentation from a multi-line string.
  for saving bandwidth while making code look nice
  """
  lines = string.split( s, "\n" )
  # strip leading blank line
  if lines[0] == "": lines = lines[ 1: ]
  # strip indentation
  indent = len( lines[ 0 ]) - len( lines[ 0 ].lstrip( ))
  for i in range( len( lines )): lines[ i ] = lines[ i ][ indent: ]
  return '\n'.join( lines )


# assembler

def assemble( src ):
  """
  :: str -> Either [ int ] ValueError

  """
  res  = []
  labels = {}
  here = 0
  for ln, line in enumerate( src.split( "\n" )):
    if line.startswith( "#" ): pass
    else:
      for word in line.split( ):
        if word.startswith( ":" ): labels[ word[ 1: ]] = here
        else:
          here += 1
          if is_int( word ): res.append( int( word ))
          elif word in labels: res.append( labels[ word ])
          else: raise ValueError( "invalid word '%s' on line %i"
                                  % ( word, ln + 1 ))
          pass
        pass
      pass
    pass
  return res


# save_image

INT32_FMT = ''
for ch in 'hil': 
  if array.array( ch ).itemsize == 4: INT32_FMT = ch
if not INT32_FMT:
  print "couldn't find a 32-bit int in your python's array module."
  print "sorry -- you'll need to update the save_image function or"
  print "use a differnt python version."
  print
  print "see http://docs.python.org/library/array.html#module-array"
  sys.exit()

def save_image( ints ):
  """
  write a list of ints as 32-bit binary values
  """
  arr = array.array( INT32_FMT, ints )
  img = open( NGARO_IMG, 'wb' )
  arr.tofile( img )
  img.close( )


# run

def run( src ):
  """
  run the ngaro interpreter and investigate its state
  """
  save_image( assemble( src ))

# test suite

class NgaroTests( unittest.TestCase ):
    
  def tearDown( self ): # runs after each test
    os.unlink( NGARO_IMG )

  def test_NOP( self ): # nop
    vm = runcode( 'nop' )
    self.assertEquals( [], vm.data )
    self.assertEquals( [], vm.addr )
    self.assertEquals( [0], vm.ram )


# stack operations

  def test_LIT( self ): # lit
    pass

  def test_DUP( self ): # dup
    pass

  def test_DROP( self ): # drop
    pass

  def test_SWAP( self ): # swap
    pass

  def test_PUSH( self ): # push
    pass

  def test_POP( self ): # pop
    pass

# flow control

  def test_LOOP( self ): # loop
    pass

  def test_JUMP( self ): # jump
    pass

  def test_RETURN( self ): # ;
    pass

  def test_LT_JUMP( self ): # <jump
    pass

  def test_GT_JUMP( self ): # >jump
    pass

  def test_NE_JUMP( self ): # !jump
    pass

  def test_EQ_JUMP( self ): # =jump
    pass

  def test_ZERO_EXIT( self ): # 0;
    pass

  def test_CALL( self ): # opcodes above 30
    pass

# arithmetic operations

  def test_ADD( self ): # +
    pass

  def test_SUBTRACT( self ): # -
    pass

  def test_MULTIPLY( self ): # *
    pass

  def test_DIVMOD( self ): # /mod
    pass

  def test_INC( self ): # 1+
    pass

  def test_DEC( self ): # 1-
    pass

# logical / bitwise operations

  def test_AND( self ): # and
    pass

  def test_OR( self ): # or
    pass

  def test_XOR( self ): # xor
    pass

  def test_SHL( self ): # <<
    pass

  def test_SHR( self ): # >>
    pass

# I/O operations

  def test_FETCH( self ): # @
    pass

  def test_STORE( self ): # !
    pass

  def test_IN( self ): # in
    pass

  def test_OUT( self ): # out
    pass

  def test_WAIT( self ): # wait
    pass



if __name__=="__main__":
  unittest.main()
