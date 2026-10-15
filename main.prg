* main.prg - the VFPStretch sample. DO main.prg, or build sample.pjx.
* sample1.scx calls _Screen.oVfpStretch.Do(This) in its Init, and its zoom
* combo sets _Screen.CurrentZoom and calls _Screen.oVfpStretch.Zoom().
Local lcFolder
lcFolder = Justpath(Sys(16))
If !Empty(m.lcFolder)
	Cd (m.lcFolder)
Endif

Set Procedure To vfpstretch.prg Additive
If Type("_Screen.oVfpStretch") = "O"
	Removeproperty(_Screen, "oVfpStretch")
Endif
=Addproperty(_Screen, "oVfpStretch", Createobject("vfpStretch"))

Do Form sample1
Read Events

Removeproperty(_Screen, "oVfpStretch")
Return
