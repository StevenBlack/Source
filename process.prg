*==============================================================================
* Program:			Process.prg
* Purpose:			The main routine that drives the entire process of
*						generating a CHM file for HackFox
* Author:			Doug Hennig
* Last revision:	04/01/2002
* Parameters:		tlNoHTMLGen - .T. to not generate HTML files from Word
*						(if these files already exist)
*					tcSkeleton  - the file to process (optional: if it isn't
*						passed, "*.*" is used)
*					tcDirectory - the location of the Word documents (optional:
*						if it isn't passed, the FinalWordDocs subdirectory of
*						the current directory is assumed)
*					tcOriginals - the location of the unchanged Word documents;
*						these documents are only used if a Word document for a
*						given topic isn't found in tcDirectory (optional: if it
*						isn't passed, the OriginalDocs subdirectory of the
*						current directory is assumed)
*					tcWordDocs  - where to put Word documents to process
*						(optional: if it isn't passed, the WordDocs
*						subdirectory of the current directory is assumed)
*					tcHTMLDir   - where to put HTML files generated by Word
*						(optional: if it isn't passed, the HTMLDocs
*						subdirectory of the current directory is assumed)
*					tcCHMDir    - where to put processed HTML files and the CHM
*						file (optional: if it isn't passed, the HTMLHelp
*						subdirectory of the current directory is assumed)
*					tcLogFile   - the file to log deletions or conflicts to
*						(optional: if it isn't passed, HackFoxLog.log in the
*						current directory is used)
* Returns:			.T. if everything worked
* Environment in:	none
* Environment out:	HTML files have been created from Word documents and
*						cleaned up and processed extensively
*					the CHM file may have been created, although it be
*						incomplete if there were problems with some files
*					if any problems occurred, they're logged in the log file,
*						which is automatically displayed at the end
* Notes:			1. This process uses the following tables:
*						CONTENT: a list of all files except Section 4
*						REPLSTRS: "bad" text to look for
*					2. To use this process, create the following directories:
*						FinalWordDocs: contains the final copy of all changed
*							Word documents and graphic files
*						OriginalDocs: contains the final copy of all unchanged
*							Word documents and graphic files (those that
*							weren't edited in this version of HackFox)
*						WordDocs: originally empty, this will be filled with
*							all Word files to process
*						HTMLDocs: originally empty, but this process will fill
*							them with HTML files converted from Word. This is
*							just a temporary directory that makes testing
*							easier by allowing the Word-to-HTML conversion step
*							to be skipped if necessary
*						HTMLHelp: originally empty, this directory will contain
*							copies of all processed files and the final CHM
*						Section0: files that should be copied to HTMLDocs (eg.
*							graphics files, HTML files)
*==============================================================================

lparameters tlNoHTMLGen, ;
	tcSkeleton, ;
	tcDirectory, ;
	tcOriginals, ;
	tcWordDocs, ;
	tcHTMLDir, ;
	tcCHMDir, ;
	tcLogFile
local lcSkeleton, ;
	lcDir, ;
	lcOriginals, ;
	lcWordDocs, ;
	lcHTMLDir, ;
	lcCHMDir, ;
	lcLogFile, ;
	lcTopicsTable, ;
	lcContentsTable, ;
	loProcess, ;
	loIterator
#include Assemble.H

* Handle the parameters.

lcSkeleton = iif(vartype(tcSkeleton) = 'C' and not empty(tcSkeleton), ;
	lower(tcSkeleton), '*.*')
lcDir      = iif(vartype(tcDirectory) = 'C' and not empty(tcDirectory), ;
	tcDirectory, 'FinalWordDocs')
if empty(lcDir) or not directory(lcDir)
	messagebox('Directory ' + lcDir + ' not found.')
	return .F.
endif empty(lcDir) ...
lcOriginals = iif(vartype(tcOriginals) = 'C' and not empty(tcOriginals), ;
	tcOriginals, 'OriginalDocs')
if empty(lcOriginals) or not directory(lcOriginals)
	messagebox('Directory ' + lcOriginals + ' not found.')
	return .F.
endif empty(lcOriginals) ...
lcWordDocs = iif(vartype(tcWordDocs) = 'C' and not empty(tcWordDocs), ;
	tcWordDocs, 'WordDocs')
if empty(lcWordDocs)
	messagebox('Directory ' + lcWordDocs + ' not specified.')
	return .F.
endif empty(lcWordDocs)
if not directory(lcWordDocs)
	md (lcWordDocs)
endif not directory(lcWordDocs)
lcHTMLDir = iif(vartype(tcHTMLDir) = 'C' and not empty(tcHTMLDir), tcHTMLDir, ;
	'HTMLDocs')
if empty(lcHTMLDir)
	messagebox('Directory ' + lcHTMLDir + ' not specified.')
	return .F.
endif empty(lcHTMLDir)
if not directory(lcHTMLDir)
	md (lcHTMLDir)
endif not directory(lcHTMLDir)
lcCHMDir = iif(vartype(tcCHMDir) = 'C' and not empty(tcCHMDir), tcCHMDir, ;
	'HTMLHelp')
if empty(lcCHMDir)
	messagebox('Directory ' + lcCHMDir + ' not specified.')
	return .F.
endif empty(lcCHMDir)
if not directory(lcCHMDir)
	md (lcCHMDir)
endif not directory(lcCHMDir)
lcDir       = addbs(fullpath(lcDir))
lcOriginals = addbs(fullpath(lcOriginals))
lcWordDocs  = addbs(fullpath(lcWordDocs))
lcHTMLDir   = addbs(fullpath(lcHTMLDir))
lcCHMDir    = addbs(fullpath(lcCHMDir))
lcLogFile   = iif(vartype(tcLogFile) = 'C' and not empty(tcLogFile), ;
	tcLogFile, 'HackFoxLog.log')

* Set a few environmental things.

set escape on
set safety off

* Open the topics and contents tables.

close tables all
lcTopicsTable   = 'newallcandf'
lcContentsTable = 'contents'
use (lcTopicsTable) alias TOPICS in 0
use (lcContentsTable) in 0
set filter to NGROUP <> 0 in TOPICS

* Erase the log file so we start with a clean slate.

erase (lcLogFile)

* Copy files from Section0 to the lcWordDocs file. We'll get all files in the
* Section0 directory using a FileIterator and use the CopyFile process class to
* do the work.

if not tlNoHTMLGen
	erase (lcWordDocs + lcSkeleton)
	loProcess  = newobject('CopyFile', 'assemble.vcx')
	loIterator = newobject('FileIterator', 'assemble.vcx')
	with loIterator
		.oProcess   = loProcess
		.cDirectory = 'Section0\'
		.cWriteDir  = lcWordDocs
		.cLogFile   = lcLogFile
		.GetFiles()
		.Process('Copying files from Section0...')
	endwith

* Copy changed Word documents to the lcWordDocs directory.

	loProcess  = newobject('CopyFile', 'assemble.vcx')
	loIterator = newobject('FileIterator', 'assemble.vcx')
	with loIterator
		dimension .aExclude[1]
		.aExclude[1]   = 'ZIP'
		.oProcess      = loProcess
		.cDirectory    = lcDir
		.cWriteDir     = lcWordDocs
		.cLogFile      = lcLogFile
		.cFileSkeleton = lcSkeleton
		.GetFiles()
		.Process('Copying changed Word docs...')
	endwith

* Next we'll copy Word documents that weren't edited in this version of HackFox
* from the originals directory to the lcWordDir directory.

	if lcSkeleton = '*.*'
		loProcess  = newobject('CopyOriginalFile', 'assemble.vcx')
		loIterator = newobject('FileIterator', 'assemble.vcx')
		with loIterator
			.oProcess   = loProcess
			.cDirectory = lcOriginals
			.cWriteDir  = lcWordDocs
			.cLogFile   = lcLogFile
			dimension .aExclude[1]
			.aExclude[1] = 'ZIP'
			.GetFiles()
			.Process('Copying unchanged Word docs...')
		endwith

* Eliminate duplicates. We won't worry about errors now; we'll display them all
* at the end.

		DelDupes(lcWordDocs, lcLogFile)
	endif lcSkeleton = '*.*'

* Convert the Word documents to HTML. Use the GenerateHTML process object with
* the FileIterator driver. Graphic files are just copied.

	loProcess  = newobject('GenerateHTML', 'assemble.vcx')
	loIterator = newobject('FileIterator', 'assemble.vcx')
	with loIterator
		.oProcess      = loProcess
		.cDirectory    = lcWordDocs
		.cWriteDir     = lcHTMLDir
		.cLogFile      = lcLogFile
		.cFileSkeleton = lcSkeleton
		.GetFiles()
		.Process('Converting Word docs to HTML...')
	endwith

* Copy graphic files to the target directory.

	loProcess  = newobject('CopyFile', 'assemble.vcx')
	loIterator = newobject('FileIterator', 'assemble.vcx')
	with loIterator
		.oProcess      = loProcess
		.cDirectory    = lcHTMLDir
		.cFileSkeleton = '*.gif'
		.cWriteDir     = lcCHMDir
		.cLogFile      = lcLogFile
		.GetFiles()
		.Process('Copying graphic files...')

		.cFileSkeleton = '*.jpg'
		.GetFiles()
		.Process('Copying graphic files...')
	endwith
endif not tlNoHTMLGen

* Clean up the HTML by stripping out all of Word's crap. We'll use a new
* FileIterator because we'll be processing a different directory. Fill the
* ReplaceText process object with a long list of things to clean up.

loIterator = newobject('FileIterator', 'assemble.vcx')
with loIterator
	.cDirectory    = lcHTMLDir
	.cWriteDir     = lcCHMDir
	.cFileSkeleton = juststem(lcSkeleton) + '.htm*'
	.cLogFile      = lcLogFile
	.GetFiles()
endwith
loProcess = newobject('ReplaceText', 'assemble.vcx')
with loProcess
	.AddSearchAndReplace('<html*>', '<html>')
	.AddSearchAndReplace('<body*>', '<body>')
	.AddSearchAndReplace('<link*>' + ccCRLF, '')
	.AddSearchAndReplace('<![if*>', '')
	.AddSearchAndReplace('<![endif]>', '')
	.AddSearchAndReplace('<!*-->' + ccCRLF,  '')
	.AddSearchAndReplace('<!*-->',  '')
	.AddSearchAndReplace('<style>*</style>' + ccCRLF, '')
	.AddSearchAndReplace('<p class=MsoNormal*>', '<p>')
	.AddSearchAndReplace('<p class=MsoNormal>', '<p>')
	.AddSearchAndReplace('<meta name*>' + ccCRLF, '')
	.AddSearchAndReplace('<v:shapetype*</v:shapetype>', '')
	.AddSearchAndReplace('<v:shape*</v:shape>', '')
	.AddSearchAndReplace('<o:p>', '')
	.AddSearchAndReplace('</o:p>', '')
	.AddSearchAndReplace('<b *>', '<b>')
	.AddSearchAndReplace('<i *>', '<i>')
	.AddSearchAndReplace('<span*>', '')
	.AddSearchAndReplace('</span>', '')
	.AddSearchAndReplace('<div*>', '')
	.AddSearchAndReplace('</div>', '')

* Add the style sheet and the correct title.

	.AddSearchAndReplace('<TITLE>', '<LINK REL="stylesheet" ' + ;
		'TYPE="text/css" HREF="HackFox.css">' + ccCRLF + '<TITLE>', .T.)
*** This isn't needed: Tamar is fixing these
*	.AddSearchAndReplace('<TITLE>*</TITLE>', ;
*		'<TITLE><<GetTitle(tcInputFile)>></TITLE>', .T.)

* Sometimes, emdashes, endashes, and non-breaking spaces aren't converted
* properly.

	.AddSearchAndReplace(chr(151), '&mdash;')
	.AddSearchAndReplace(chr(150), '&ndash;')
	.AddSearchAndReplace(chr(160), ' ')

* Remove table separators.

	.AddSearchAndReplace('<p class=H6>&nbsp;</p>' + ccCRLF, '')

* Strip leading <P> because they throw line spacing off.

	.AddSearchAndReplace(ccCRLF + '<p>', ccCRLF)
	.AddSearchAndReplace(ccCR   + '<p>', ccCR)

* Strip out blank lines at the end.

	.AddSearchAndReplace('</table>' + ccCRLF + ccCRLF + '&nbsp;</p>' + ;
		ccCRLF + ccCRLF + '&nbsp;</p>' + ccCRLF + ccCRLF + ccCRLF + ccCRLF + ;
		'</body>', '</table>' + ccCRLF + '<p>' + ccCRLF + '</body>')
	.AddSearchAndReplace('</table>' + ccCRLF + ccCRLF + '&nbsp;</p>' + ;
		ccCRLF + ccCRLF + ccCRLF + ccCRLF + '</body>', '</table>' + ccCRLF + ;
		'<p>' + ccCRLF + '</body>')

* Add the updates button and copyright.

***	.AddSearchAndReplace('</BODY>', '<input type="button" ' + ;
*		'value="View Updates" style="font-family: Verdana; ' + ;
*		'font-size: 9pt; font-weight: bold" ' + ;
*		'onclick="ShowUpdates">' + ccCRLF + ;
*		'<p>' + ccCRLF + ;
*		'<A HREF="copyrite.html">Copyright &copy; 2002 by Tamar E. Granor, ' + ;
*		'Ted Roche, Doug Hennig, and Della Martin. All Rights Reserved.</A>' + ;
*		ccCRLF + '</BODY>', .T.)
	.AddSearchAndReplace('</BODY>', '<p>' + ccCRLF + ;
		'<A HREF="http://www.hentzenwerke.com/catalogavailability/hackfox7errata.htm">View Updates</A><p>' + ;
		ccCRLF + ;
		'<A HREF="copyrite.html">Copyright &copy; 2002 by Tamar E. Granor, ' + ;
		'Ted Roche, Doug Hennig, and Della Martin. All Rights Reserved.</A>' + ;
		ccCRLF + '</BODY>', .T.)

* Insert the script and other pieces for displaying updates.

***	.AddSearchAndReplace('</HEAD>', '<script language="vbscript">' + ccCRLF + ;
*		'function ShowUpdates()' + ccCRLF + ;
*		'Set oVFP = createobject("HackFoxUpdate.HackFoxUpdate")' + ccCRLF + ;
*		'UpdateText = oVFP.ShowUpdates("<<juststem(tcInputFile)>>")' + ccCRLF + ;
*		'mainbody.innerHTML = UpdateText' + ccCRLF + ;
*		'end function' + ccCRLF + ;
*		'</script>' + ccCRLF + ;
*		'</head>', .T.)
*	.AddSearchAndReplace('<BODY>', '<body>' + ccCRLF + ;
*		'<div id=mainbody>', .T.)
*	.AddSearchAndReplace('</BODY>', '</div>' + ccCRLF + '</body>', .T.)
endwith

* Now do the process.

loIterator.oProcess = loProcess
loIterator.Process('Cleaning up HTML docs...')

* Ensure graphics files are linked correctly. We'll use a new FileIterator
* because we'll be processing a different directory.

loProcess  = newobject('FixImages',    'assemble.vcx')
loIterator = newobject('FileIterator', 'assemble.vcx')
with loIterator
	.oProcess      = loProcess
	.cDirectory    = lcCHMDir
	.cFileSkeleton = juststem(lcSkeleton) + '.htm*'
	.cLogFile      = lcLogFile
	.GetFiles()
	.Process('Fixing image links...')
endwith

* Fix preformatted lines.

loProcess = newobject('FixPreFormatted', 'assemble.vcx')
loIterator.oProcess = loProcess
loIterator.Process('Fixing code samples...')

* Fix tables.

loProcess = newobject('FixTables', 'assemble.vcx')
loIterator.oProcess = loProcess
loIterator.Process('Fixing tables...')

* Fix bullets.

loProcess = newobject('FixBullets', 'assemble.vcx')
loIterator.oProcess = loProcess
loIterator.Process('Fixing bullets...')

* Fix titles.

loProcess = newobject('FixTitles', 'assemble.vcx')
loIterator.oProcess = loProcess
loIterator.Process('Fixing titles...')

* Fix hyperlinks.

loProcess = newobject('FixHyperlinks', 'assemble.vcx')
loIterator.oProcess = loProcess
loIterator.Process('Fixing hyperlinks...')

* Additional cleanup. This must be done after the other processing since we
* need STYLE attributes for FixTables, for example.

loProcess = newobject('ReplaceText', 'assemble.vcx')
with loProcess
	.AddSearchAndReplace(" style='*'", '')
	.AddSearchAndReplace('&nbsp;</p>' + ccCRLF, '')
	.AddSearchAndReplace('<b>&nbsp;</b></p>' + ccCRLF, '')
	.AddSearchAndReplace('<p class=h1>&nbsp;</p>' + ccCRLF, '')
	.AddSearchAndReplace('<p>  </td>', '&nbsp;</td>')
	.AddSearchAndReplace(ccCRLF + ccCRLF, ccCRLF)
endwith
loIterator.oProcess = loProcess
loIterator.Process('Additional HTML cleanup...')

* Look for "bad" text.

loProcess = newobject('FindBadText', 'assemble.vcx')
with loProcess
	.lCaseSensitive = .T.
*** look for <P CLASSNAME other than H1 - H4, PREFORMATTED, and BLOCKQUOTE
	use REPLSTRS
	scan for ACTIVE
		.AddSearchAndReplace(VALIDDOCS, textmerge(trim(ORIGINAL)), '')
	endscan for ACTIVE
	use
endwith
loIterator.oProcess = loProcess
loIterator.Process('Looking for bad text...')

* Add links to other documents in "See Also" topics. We'll use a different
* FileIterator because now we're only processing certain HTML files, and we'll
* use the HandleSeeAlso process object.

loProcess = newobject('HandleSeeAlso', 'assemble.vcx')
loProcess.cTopicsTable = lcTopicsTable
loIterator = newobject('FileIterator', 'assemble.vcx')
with loIterator
	.oProcess      = loProcess
	.cDirectory    = lcCHMDir
	.cFileSkeleton = iif(lcSkeleton = '*.*', 's4g*.html', ;
		forceext(lcSkeleton, 'html'))
	.cLogFile      = lcLogFile
	.GetFiles()
	.Process('Creating See Also links...')
endwith

* Hyperlink keywords in tables. We're only going to process certain files
* (those with NEWALLCANDF.HYPERLINK .T.), so we'll use a new FileIterator.

loProcess = newobject('HyperlinkKeywords', 'assemble.vcx')
loProcess.cTopicsTable = lcTopicsTable
select 's4g' + padl(NGROUP, 3, '0') + '.html' ;
	from TOPICS ;
	where HYPERLINK ;
	into array laFiles ;
	group by 1
if lcSkeleton = '*.*' or ascan(laFiles, lower(forceext(lcSkeleton, 'html'))) > 0
	loIterator = newobject('FileIterator', 'assemble.vcx')
	with loIterator
		if lcSkeleton = '*.*'
			acopy(laFiles, .aFiles)
		else
			.aFiles[1] = forceext(lcSkeleton, 'html')
		endif lcSkeleton = '*.*'
		.oProcess   = loProcess
		.cDirectory = lcCHMDir
		.cLogFile   = lcLogFile
		.Process('Linking PEM/function tables...')
	endwith
endif lcSkeleton = '*.*' ...

* Do some file-specific cleanup.

* Use proper font and size
if inlist(lcSkeleton, '*.*', 's2c2')
	lcFile   = lcCHMDir + 's2c2.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, chr(13) + chr(10) + 'Always.', ;
		'<font name="Arial Black" size=7>Always.</font>')
	lcString = strtran(lcString, chr(13) + chr(10) + 'Almost Always.', ;
		'<font name="Arial Black" size=5>Almost Always.</font>')
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's2c2')

* Use proper font for symbol characters
if inlist(lcSkeleton, '*.*', 's4g050')
	lcFile   = lcCHMDir + 's4g050.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, chr(233), ;
		'<font name="Symbol" face="Symbol">' + chr(233) + '</font>')
	lcString = strtran(lcString, chr(235), ;
		'<font name="Symbol" face="Symbol">' + chr(235) + '</font>')
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's4g050')

* Hyperlink "CommandButton" to appropriate topic and unlink the first
* occurrence of Spinner
if inlist(lcSkeleton, '*.*', 's4g176')
	lcFile   = lcCHMDir + 's4g176.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, '<p>CommandButton', ;
		'<p><a href="s4g484.html">CommandButton</a>', 1)
	lcString = strtran(lcString, '<a href="s4g541.html">Spinner</a>', ;
		'Spinner', 1, 1)
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's4g176')

* Use proper font for symbol characters
if inlist(lcSkeleton, '*.*', 's4g313')
	lcFile   = lcCHMDir + 's4g313.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, chr(174), ;
		'<font name="Symbol" face="Symbol">' + chr(174) + '</font>')
	lcString = strtran(lcString, chr(175), ;
		'<font name="Symbol" face="Symbol">' + chr(175) + '</font>')
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's4g313')

* Hyperlink "Object" to appropriate topic
if inlist(lcSkeleton, '*.*', 's4g518')
	lcFile   = lcCHMDir + 's4g518.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, '<p>Object</p>', ;
		'<p><a href="s4g700.html">Object</a><p>', 1)
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's4g518')

if inlist(lcSkeleton, '*.*', 's4g591')
	lcFile   = lcCHMDir + 's4g591.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, 's4g900', 's4g475', 1)
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's4g591')

if inlist(lcSkeleton, '*.*', 's4g767')
	lcFile   = lcCHMDir + 's4g767.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, 's4g781', 's4g722')
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's4g767')

if inlist(lcSkeleton, '*.*', 's4g900')
	lcFile   = lcCHMDir + 's4g900.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, 's4g471', 's4g861')
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's4g900')

*** remove this if handle multi-level bullets properly
if inlist(lcSkeleton, '*.*', 's5c2')
	lcFile   = lcCHMDir + 's5c2.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, '<li> File name:', '<ul><li> File name:')
	lcString = strtran(lcString, '<li> If you', '</ul><li> If you')
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's5c2')

*** remove this if handle multi-level bullets properly
if inlist(lcSkeleton, '*.*', 's5c3')
	lcFile   = lcCHMDir + 's5c3.html'
	lcString = filetostr(lcFile)
	lcString = strtran(lcString, '<li> The LayoutSty.oLabel1 property', ;
		'<ul><li> The LayoutSty.oLabel1 property')
	lcString = strtran(lcString, 'can be laid out. </p>', ;
		'can be laid out. </p></ul>')
	strtofile(lcString, lcFile)
endif inlist(lcSkeleton, '*.*', 's5c3')

* Copy HTML files from Section0 (we don't want the processing that was done on
* them earlier).

if lcSkeleton = '*.*'
	loProcess  = newobject('CopyFile', 'assemble.vcx')
	loIterator = newobject('FileIterator', 'assemble.vcx')
	with loIterator
		.oProcess      = loProcess
		.cDirectory    = 'Section0\'
		.cFileSkeleton = '*.htm*'
		.cWriteDir     = lcCHMDir
		.cLogFile      = lcLogFile
		.GetFiles()
		.Process('Copying files from Section0...')
	endwith
endif lcSkeleton = '*.*'

* Now we'll check out any errors.

if file(lcLogFile)
	modify file (lcLogFile) nowait
endif file(lcLogFile)

function GetTitle(tcFileName)
local lcFileName, ;
	lcTopic, ;
	lnSelect, ;
	lcTitle
lcFileName = lower(juststem(tcFileName))
if lcFileName = 's4g'
	lcTopic  = substr(lcFileName, 4)
	lnSelect = select()
	select TOPIC from TOPICS where NGROUP = val(lcTopic) into cursor _TEMP
	if _tally > 0
		lcTitle = ''
		scan
			lcTitle = lcTitle + iif(empty(lcTitle), '', ', ') + trim(TOPIC)
		endscan
	else
		lcTitle = ''
		wait window 'GetTitle: ' + lcFileName + ' not found'
	endif _tally > 0
	if used('_TEMP')
		use in _TEMP
	endif used('_TEMP')
	select (lnSelect)
else
	select CONTENTS
	locate for FILENAME = lcFileName
	if found()
		lcTitle = trim(NAME)
	else
		lcTitle = ''
	endif found()
endif lcFileName = 's4g'
return lcTitle
