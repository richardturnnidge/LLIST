# LLIST
MOSlet for printing to a thermal printer from MOS/BBC Basic.

Put the latest bin file in your MOS folder which should be at the top level of your SC card. Rename it to <B>LLIST.bin</B>

Works from MOS, or any program that allows entry of MOS commands (eg. BBC Basic).

Type: <B>LLIST filename.txt</B> (also works with .bas file, or any text file)

It is currently set to 9600 baud rate as default. Include a second parameter for a different baud rate:

Type: <B>LLIST filename.txt  19200</B> 

Within BBC Basic (works with 24bit ADL as well as 16 bit version), use the '*' prefix to send the MOS command:

Type: <B>*LLIST filename.bas</B> or: <B>*LLIST filename.txt  19200</B> 

NOTE. Any standard baud rate can be used as a second parameter, 9600, 19200, 57600, etc. There is no error checking here, so only enter a proper number...

