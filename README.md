
Extension to Delphi's built-in TFileStream that allows fmAppend and fmAppendExisting open modes.

(C) 2018 HeartWare

Distributed under Creative Commons License CC-BY-SA.

Generally speaking this grants you a limited right to use this software - also commercial use - as long as you
attribute the author in your documentation. Also, if you change the software (f.ex. to suit your specific needs)
you must make available your modifications under a license not stricter than the original license the work was
distributed under.

Read more here:

https://en.wikipedia.org/wiki/Attribution_(copyright) - BY (Attribution)
https://en.wikipedia.org/wiki/Share-alike - SA (Share-Alike)

Requirements: A UNICODE Delphi compiler (ie. Delphi 2010 or later).

Usage: Simply include the HeartWare.FileStream unit in your project. Your existing code should continue to work as
previously, but you now have a few extra Modes that you can use:

fmAppend		- Opens (or creates) the file and moves the file pointer to the end of the file, ready to append
			  data to the file.
fmAppendExisting	- Opens an existing file in Append mode. Identical to fmAppend, except that the call fails with
			  an exception if the file does not already exist.

In addition to these two new modes, the new TFileStream also supports overloaded constructors that allow you to specify
an Encoding scheme to use for writing text to the file. Since the main usage for appending files is LOG files, I have
made a few extensions that makes it easier to do so:

TFileStream.WriteLine(CONST S : STRING)			- Writes the string to the file
TFileStream.WriteLine(CONST Format : STRING ;
		      CONST Args : ARRAY OF CONST)	- Writes a formatted string to the file (like Format function)
TFileStream.TW						- The built-in TTextWriter. You can use this to access all
							  the other methods of the internal TTextWriter. The above two
							  methods are simply gateways to the appropriate overloaded
							  TW.WriteLine.
CLASS VAR TFileStream.DefaultEncoding			- Use this to once and for all specify the default encoding to
							  use on all created TFileStream instances. If not set by you
							  if will default to TEncoding.Default (ANSI on Windows, UTF-8
							  on MAC).
FUNCTION DefEncoding : TEncoding			- VIRTUAL function that allows you another method of specifying
							  default encoding. If you have the need for various encodings
							  on different TFileStream instances, you can subclass the
							  new TFileStream with your own and OVERRIDE this function.
							  Do NOT call the inherited function, unless you want to
							  only have your own implemtation active in certain configurations.
FUNCTION CreateTextWriter(Encoding : TEncoding)		- VIRTUAL function that you can override in a subclassed
							  TFileStream if you need a specific TTextWriter descendant
							  instead of the default one used (TStreamWriter).

Beisdes these extensions, there is also these VIRTUAL methods:

FUNCTION DefaultShare(Mode : Cardinal)			- For CONSTRUCTOR calls that don't have a Sharing parameter,
							  this VIRTUAL function is called to determine the default
							  sharing mode. As it is, it will return fmShareDenyWrite
							  for fmAppend and fmAppendExisting modes, and fmShareCompat
							  for other modes.

