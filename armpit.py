#!/usr/bin/env python
'''Terminal Utilities for Armpit Scheme controller'''
__author__ = '''Peng Shulin <trees_peng@163.com>'''
__version__ = '1.0'
__license__ = '''
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
'''

USAGE = ''' 
 *) enter interactive mode
    python armpit.py -d device-name
 *) read from files, evaluated line by line
    python armpit.py -d device-name file1 file2 ...
 *) program files into internal flash, erase flash if "-e" is set
    python armpit.py -d device-name -e -p file1 files2 ...
'''

import sys, os, time, serial, optparse, threading, Queue
import readline

DEFAULT_DEVICE = '/dev/ttyS0'
DEFAULT_BAUD = 9600
DEFAULT_TIMEOUT = 1 
PROMPT = 'ap> '

TIMEOUT = 1
TIMEOUT_ERASE = 5
TIMEOUT_ECHO = 0.5
TIMEOUT_WRITE_FILE = 1
TIMEOUT_PROMPT_SYNC = 1
BYTES_PER_WRITE = 64 

PRE_DEFINED_FUNCTION = '''\
(define (port-write-int int) (write-char (integer->char int) port))
(define (program lst) (for-each port-write-int lst))
''' 

class ArmpitException( Exception ):
    pass

class Armpit():
    def __init__(self, device ):
        try:
            self.port = serial.serial_for_url( device, \
                                      DEFAULT_BAUD, timeout=DEFAULT_TIMEOUT)
        except AttributeError:
            # for older version of pyserial
            self.port = serial.Serial(device, \
                                      DEFAULT_BAUD, timeout=DEFAULT_TIMEOUT)
        self.cmdBuff = ''
        self.rxBuff = ''
        self.queueResponse = Queue.Queue()
        self.echo = True
        self.thread = threading.Thread(target=self.threadRxListening)
        self.thread.setDaemon(1)
        self.thread.start()

    def threadRxListening(self):
        # the thread listens on RXD
        self.port.flushInput()
        self.rxBuff = ''
        while True:
            read = self.port.read(1)
            if not read:
                continue
            if read == '\r':
                # new line received
                self.queueResponse.put( self.rxBuff )
                if self.echo:
                    sys.stdout.write( '\n' )
                    sys.stdout.flush()
                self.echo = True
                self.rxBuff = ''
            else:
                self.rxBuff += read
                if self.echo:
                    sys.stdout.write( read )
                    sys.stdout.flush()
                if self.rxBuff == PROMPT:
                    # prompt is meet
                    self.queueResponse.put( PROMPT )
                    self.rxBuff = ''
               
    def clearRxBuffer( self ):
        # clear rx buffer
        self.rxBuff = ''
        while not self.queueResponse.empty():
            self.queueResponse.get()

    def sendTxLine( self, line ):
        # send line, ended with '\r'
        self.echo = False
        self.port.write( line )
        self.port.write( '\r' )
        self.port.flush()

    def evalLine( self, line, show=False ):
        # send line and wait for echo (should be same as line )
        if show:
            sys.stdout.write( line + '\n' )
        self.sendTxLine( line )
        try:
            while True:
                lineret = self.queueResponse.get( timeout=TIMEOUT_ECHO )
                if lineret == line:
                    return
                #else:
                #    print "INFO> previous response: %s"%l
        except:
            raise ArmpitException( "ERROR> evalLine timeout" )
 
    def checkPrompt(self):
        # wait for prompt
        ret = False
        try:
            while True:
                line = self.queueResponse.get( timeout=TIMEOUT_PROMPT_SYNC )
                if line == PROMPT:
                    # if queue is not empty, this may be the previous prompt
                    if self.queueResponse.empty():
                        ret = True
                        break
        except Queue.Empty:
            pass
        return ret

    def syncPrompt( self ):
        # send ETX(0x03) to stop curret line
        self.echo = False
        self.port.write( '\x03' )
        time.sleep( TIMEOUT_PROMPT_SYNC ) 
        if not self.checkPrompt():
            raise ArmpitException( "syncPrompt failed" )
        # clear response queue
        while not self.queueResponse.empty():
            self.queueResponse.get()
 
    def enterRepl(self):
        # enter read-evaluate-print-loop mode 
        while True:
            try:
                self.evalLine( raw_input().strip() )
            except ArmpitException, err:
                print err
                sys.exit(0)
            except:
                # exit program with Ctrl-C or Ctrl-D
                sys.exit(0)
    
    def evalFile( self, filename ):
        # evalulate single file
        for _line in open( filename, 'r' ).readlines():
            line = _line.rstrip()
            if line:
                if not line[0] in [' ', ';']:
                    self.checkPrompt()
                print line
                # eval the line
                self.evalLine( line )
        self.checkPrompt()

    def showInfo( self ):
        # show device infomation
        self.evalLine( '(files)', show=True )
        self.checkPrompt()
        self.evalLine( '(gc)', show=True )
        self.checkPrompt()

    def unlockFlash( self ):
        # unlockFlash flash
        self.evalLine( '(unlock)', show=True )
        assert self.queueResponse.get( timeout=TIMEOUT ) == '#t'
        self.checkPrompt()

    def eraseFlash( self ):
        # erase flash
        self.evalLine( '(erase)', show=True )
        assert self.queueResponse.get( timeout=TIMEOUT_ERASE ) == '#t'
        self.checkPrompt()

    def preProgram( self ):
        # some thing done before mass program
        for line in PRE_DEFINED_FUNCTION.splitlines():
            if line:
                self.evalLine( line.strip(), show=True )
                self.checkPrompt()

    def programFlash( self, filename ):
        # program files
        self.evalLine( '(open-output-file "%s" )'%filename, show=True )
        reply = self.queueResponse.get( timeout=TIMEOUT_WRITE_FILE )
        assert reply.find( 'throw' ) == -1
        port = int( reply )
        self.checkPrompt()
        
        # mass program integer lists 
        self.evalLine( '(define port %d)'%port, show=True )
        self.checkPrompt()
        fp = open(filename,'rb')
        vector = fp.read(BYTES_PER_WRITE)
        while vector:
            dat_str = ' '.join(['%d'%ord(i) for i in list(vector)])
            #print dat_str
            self.evalLine( '(program \'(%s))'%dat_str, show=True )
            self.checkPrompt()
            vector = fp.read(BYTES_PER_WRITE)
        
        self.evalLine( '(close-output-port %d)'%port, show=True )
        self.checkPrompt()

def main():
    PARSER = optparse.OptionParser( usage=USAGE, description=__doc__ )

    PARSER.add_option("-d",
        dest = "device",
        action = "store",
        type = "string",
        help = "serial port device",
        default = DEFAULT_DEVICE,
    )
 
    PARSER.add_option("-e",
        dest = "erase",
        action = "store_true",
        help = "erase flash",
        default = False 
    )

    PARSER.add_option("-p",
        dest = "program",
        action = "store_true",
        help = "and program files",
        default = False
    )
    
    (options, args) = PARSER.parse_args()

    if not options.device:
        PARSER.error("No device assigned")
    
    ARMPIT = Armpit( options.device )
    ARMPIT.syncPrompt()
    #ARMPIT.showInfo()

    if options.erase or options.program:
        # flash operation
        ARMPIT.unlockFlash()
        if options.erase:
            ARMPIT.eraseFlash()
        if options.program:
            if not args:
                sys.stderr.write( "no file to be programed\n" )
                sys.exit(1)
            # program files
            ARMPIT.preProgram()
            for filename in args:
                if os.path.isfile( filename ):
                    ARMPIT.programFlash( filename )

    elif args:
        # eval files
        for filename in args:
            if os.path.isfile( filename ):
                ARMPIT.evalFile( filename )
    else:
        readline.clear_history()
        # interactive mode
        ARMPIT.enterRepl()



if __name__ == '__main__':
    main()

