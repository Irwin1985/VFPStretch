# VFPStretch ![](images/prg.gif)

**VFPStretch** is a free tool for resizing any form in Visual FoxPro 9.0

**NOTE:** This library was inspired by **[Stretchy Resize Control](http://www.codemine.com/Download.htm)**

### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### Latest Release

**[VFPStretch](/README.md)** - v.1.2 (beta) - Release 2019-05-20 14:35:31

<hr>

### Examples

<pre>
 * Create the object anywhere in your main prg file.*
 * I highly recommend create a property in the _screen object.*
 
 If Type("_Screen.oVfpStretch") = "O"
	  Removeproperty(_Screen, "oVfpStretch")
 Else &&Type("_Screen.oVfpStretch") = "O"
 Endif &&Type("_Screen.oVfpStretch") = "O"
 
 SET PROCEDURE TO "VFPStretch.prg" ADDITIVE 
 =AddProperty(_Screen, "oVfpStretch", Newobject("vfpStretch",(Locfile("VfpStretch", "prg","VfpStretch Prg Class"))))
 
 *-- Now put this in your init form event.
 _Screen.oVfpstretch.Do(THISFORM)
 
</pre>
