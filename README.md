# VFPStretch ![](images/prg.gif)

**VFPStretch** is a free tool for resizing any form in Visual FoxPro 9.0

**NOTE:** This library was inspired by **[Stretchy Resize Control](http://www.codemine.com/Download.htm)**

### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### Latest Release

**[VFPStretch](/README.md)** - v.2.0 - Release 2020-10-22 13:18:15

**[VFPStretch](/README.md)** - v.1.2 (beta) - Release 2019-05-20 14:35:31

<hr>

### New Features

** Zoom method ** - Automatically adjust the current form size by reading the _screen property 'CurrentZoom'. This property stores the current zoom percentage for all the forms. zero (0) means default size.

### Example

```xBase
 // Create the object anywhere in your main prg file.
 // I highly recommend create a property in the _screen object.
 
 If Type("_Screen.oVfpStretch") = "O"
   Removeproperty(_Screen, "oVfpStretch")
 Endif
 
 SET PROCEDURE TO "VFPStretch.prg" ADDITIVE 
 =AddProperty(_Screen, "oVfpStretch", Newobject("vfpStretch",(Locfile("VfpStretch", "prg","VfpStretch Prg Class"))))
 
 //Now put this in your init form event.
 _Screen.oVfpstretch.Do(THISFORM)
 
```
