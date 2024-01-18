# LLIST
MOSlet for printing to a thermal printer from mos/basic.
Currently set to 9600 baud rate as default.
Include a second param for a different baud rate

Put the latest bin file in your MOS folder. Rename it to LLIST.bin

Works from MOS, or any program that allows entry of MOS commands (eg. bbcbasic).

Type: <B>LLIST filename.txt</B> (also works with .bas files)

Type: LLIST filename.txt  19200 (to change baud rate)

Within BBCBasic (works with 24bit ADL as well as 16 bit version):

Type: *LLIST filename.bas

NOTE. Any standard baud rate can be used as a second parameter, 9600, 19200, 57600, etc. There is no error checking here, so only enter a proper number...

