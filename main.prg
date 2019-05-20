*!*	Set Step On
If Type("_Screen.oVfpStretch") = "O"
	Removeproperty(_Screen, "oVfpStretch")
Else &&Type("_Screen.oVfpStretch") = "O"
Endif &&Type("_Screen.oVfpStretch") = "O"

=AddProperty(_Screen, "oVfpStretch", Newobject("vfpStretch",(Locfile("VfpStretch", "prg","VfpStretch Prg Class"))))

Cd (Justpath(Sys(16)))
Do Form (Locfile("sample1", "scx","Sample Form"))
Read Events
Release _Screen.oVfpStretch
Return
