*==============================================================================
* VFPStretch 2.1.0
* Resizes every control of a Visual FoxPro 9 form when the form is resized,
* and opens forms at a zoom level shared by the whole application.
*
* Copyright (c) 2019-2026 Irwin Rodríguez. MIT License.
* https://github.com/Irwin1985/VFPStretch
*
* Inspired by "Stretchy Resize Control" (codemine.com).
*==============================================================================
#Define VFPSTRETCH_VERSION		"2.1.0"
#Define VFPSTRETCH_SKIP_TAG		"NOSTRETCH"
#Define VFPSTRETCH_PROPERTY		"oVfpStretch"

* Entry point: DO vfpstretch.prg WITH ThisForm
Lparameters toForm
If Pcount() > 0
	Local loStretch
	loStretch = Createobject("vfpStretch")
	loStretch.Do(m.toForm)
Endif
Return

*==============================================================================
* vfpStretch: the object the application creates. Do(oForm) makes a form
* stretchable; the form keeps its own Stretcher in ThisForm.oVfpStretch.
*==============================================================================
Define Class vfpStretch As Custom
	cVersion   = VFPSTRETCH_VERSION
	cLastError = ""

	Procedure Init
		* The zoom of every form, as a percentage: 0 is the size of the designer,
		* 100 is maximized. The application sets it, VFPStretch reads it.
		If Type("_Screen.CurrentZoom") = "U"
			=Addproperty(_Screen, "CurrentZoom", 0)
		Endif
	Endproc

	* Makes the form stretchable and returns its Stretcher (.NULL. on failure:
	* see cLastError). Calling it again on the same form returns the same one.
	Function Do(toForm)
		Local loForm, loStretcher
		This.cLastError = ""
		loForm = .Null.
		Do Case
		Case Vartype(m.toForm) == "O"
			loForm = m.toForm
		Case Type("_Screen.ActiveForm") == "O"
			loForm = _Screen.ActiveForm
		Endcase
		If Isnull(m.loForm) Or !(Lower(m.loForm.BaseClass) == "form")
			This.cLastError = "Do() needs a form, and there is no active form"
			Return .Null.
		Endif

		If Type("m.loForm." + VFPSTRETCH_PROPERTY) == "O" And !Isnull(m.loForm.oVfpStretch)
			Return m.loForm.oVfpStretch
		Endif

		loStretcher = Createobject("Stretcher")
		If !m.loStretcher.Do(m.loForm)
			This.cLastError = m.loStretcher.cLastError
			Return .Null.
		Endif
		If Pemstatus(m.loForm, VFPSTRETCH_PROPERTY, 5)
			m.loForm.oVfpStretch = m.loStretcher
		Else
			=Addproperty(m.loForm, VFPSTRETCH_PROPERTY, m.loStretcher)
		Endif
		Return m.loStretcher
	Endfunc

	* Applies a zoom to a form that Do() already took (the active form when
	* toForm is not given). Without tnPercent it reads _Screen.CurrentZoom.
	Function Zoom(tnPercent, toForm)
		Local loForm
		This.cLastError = ""
		loForm = .Null.
		Do Case
		Case Vartype(m.toForm) == "O"
			loForm = m.toForm
		Case Type("_Screen.ActiveForm") == "O"
			loForm = _Screen.ActiveForm
		Endcase
		If Isnull(m.loForm) Or Type("m.loForm." + VFPSTRETCH_PROPERTY) != "O" Or Isnull(m.loForm.oVfpStretch)
			This.cLastError = "Zoom() needs a form that Do() has taken"
			Return .F.
		Endif
		m.loForm.oVfpStretch.Zoom(m.tnPercent)
		Return .T.
	Endfunc
Enddefine

*==============================================================================
* Stretcher: remembers the original size, position and font of every control
* of one form, and scales them each time the form is resized.
*==============================================================================
Define Class Stretcher As Custom
	nOriginalHeight = 0
	nOriginalWidth  = 0
	oForm           = .Null.
	cLastError      = ""

	* Saves the form as it is now and starts following its Resize. .T. when done.
	Function Do(toForm)
		Local loEx
		This.cLastError = ""
		If Vartype(m.toForm) != "O" Or !(Lower(m.toForm.BaseClass) == "form")
			This.cLastError = "Do() needs a form"
			Return .F.
		Endif
		Try
			This.oForm = m.toForm
			With This.oForm
				* The form may shrink to a quarter of its size, unless the
				* designer already gave it a minimum.
				If .MinHeight <= 0
					.MinHeight = Int(.Height / 4)
				Endif
				If .MinWidth <= 0
					.MinWidth = Int(.Width / 4)
				Endif
				This.nOriginalHeight = .Height
				This.nOriginalWidth  = .Width
			Endwith
			This.SaveContainer(This.oForm)
			=Bindevent(This.oForm, "Resize", This, "OnFormResize", 1)
			=Bindevent(This.oForm, "Destroy", This, "OnFormDestroy", 1)
			* zoom 0 is the form as the designer left it, maximized or not
			If Type("_Screen.CurrentZoom") == "N" And _Screen.CurrentZoom > 0
				This.Zoom()
			Endif
		Catch To loEx
			This.cLastError = "Do(): " + m.loEx.Message
		Endtry
		Return Empty(This.cLastError)
	Endfunc

	* Gives the form back the size it had when Do() was called.
	Procedure ResetSize
		If Vartype(This.oForm) == "O"
			With This.oForm
				.Height = This.nOriginalHeight
				.Width  = This.nOriginalWidth
			Endwith
			This.Stretch()
		Endif
	Endproc

	Procedure OnFormResize
		This.Stretch()
	Endproc

	* The form is going away: let go of it, so that nothing keeps it alive.
	Procedure OnFormDestroy
		If Vartype(This.oForm) == "O"
			=Unbindevents(This.oForm, "Resize", This, "OnFormResize")
			=Unbindevents(This.oForm, "Destroy", This, "OnFormDestroy")
		Endif
		This.oForm = .Null.
	Endproc

	*--------------------------------------------------------------------------
	* Saving the original geometry
	*--------------------------------------------------------------------------
	Procedure SaveContainer(toContainer)
		Local loControl, loPage, loColumn, loButton
		This.SaveOriginalSize(m.toContainer)
		For Each loControl In m.toContainer.Controls
			If This.IsSkipped(m.loControl)
				Loop
			Endif
			If !(m.loControl.BaseClass == "Custom")
				This.SaveOriginalSize(m.loControl)
			Endif

			* Anchor moves the control on its own: the two would fight.
			If Type("m.loControl.Anchor") == "N" And m.loControl.Anchor > 0
				m.loControl.Anchor = 0
			Endif

			Do Case
			Case m.loControl.BaseClass == "Container"
				This.SaveContainer(m.loControl)
			Case m.loControl.BaseClass == "Pageframe"
				For Each loPage In m.loControl.Pages
					This.SaveContainer(m.loPage)
				Endfor
			Case m.loControl.BaseClass == "Grid"
				For Each loColumn In m.loControl.Columns
					This.SaveOriginalSize(m.loColumn)
				Endfor
			Case Inlist(m.loControl.BaseClass, "Commandgroup", "Optiongroup")
				For Each loButton In m.loControl.Buttons
					This.SaveOriginalSize(m.loButton)
				Endfor
			Endcase
		Endfor
	Endproc

	* Tag "NOSTRETCH" leaves a control, and everything inside it, as it is.
	Function IsSkipped(toControl)
		Return Pemstatus(m.toControl, "Tag", 5) And Vartype(m.toControl.Tag) == "C" ;
			And VFPSTRETCH_SKIP_TAG $ Upper(m.toControl.Tag)
	Endfunc

	* Each value is saved once: calling Do() again does not take a scaled size
	* for the original one.
	Procedure SaveOriginalSize(toObject)
		* A page takes its size from the page frame: only its font scales.
		If !(m.toObject.BaseClass == "Page") And Pemstatus(m.toObject, "Width", 5)
			This.SaveValue(m.toObject, "_nOriginalWidth", m.toObject.Width)
			If Pemstatus(m.toObject, "Height", 5)
				This.SaveValue(m.toObject, "_nOriginalHeight", m.toObject.Height)
				This.SaveValue(m.toObject, "_nOriginalLeft", m.toObject.Left)
				This.SaveValue(m.toObject, "_nOriginalTop", m.toObject.Top)
			Endif
		Endif
		If Pemstatus(m.toObject, "FontSize", 5)
			This.SaveValue(m.toObject, "_nOriginalFontsize", m.toObject.FontSize)
		Endif
		If Pemstatus(m.toObject, "RowHeight", 5)
			This.SaveValue(m.toObject, "_nOriginalRowheight", m.toObject.RowHeight)
		Endif
		If m.toObject.BaseClass == "Grid"
			This.SaveValue(m.toObject, "_nOriginalHeaderHeight", m.toObject.HeaderHeight)
		Endif
		If m.toObject.BaseClass == "Listbox" And !Empty(m.toObject.ColumnWidths)
			This.SaveValue(m.toObject, "_nOriginalColumnWidths", m.toObject.ColumnWidths)
		Endif
	Endproc

	Procedure SaveValue(toObject, tcProperty, tvValue)
		If !Pemstatus(m.toObject, m.tcProperty, 5)
			=Addproperty(m.toObject, m.tcProperty, m.tvValue)
		Endif
	Endproc

	*--------------------------------------------------------------------------
	* Scaling
	*--------------------------------------------------------------------------
	Procedure Stretch(toContainer)
		Local loContainer, loControl, loPage, loColumn, loButton, llLocked, loEx
		If Vartype(This.oForm) != "O" Or This.nOriginalWidth <= 0 Or This.nOriginalHeight <= 0
			Return
		Endif
		loContainer = Iif(Vartype(m.toContainer) == "O", m.toContainer, This.oForm)

		If m.loContainer.BaseClass == "Form"
			llLocked = m.loContainer.LockScreen
			m.loContainer.LockScreen = .T.
		Else
			This.AdjustSize(m.loContainer)
		Endif

		Try
			For Each loControl In m.loContainer.Controls
				If !(m.loControl.BaseClass == "Custom")
					This.AdjustSize(m.loControl)
				Endif
				Do Case
				Case m.loControl.BaseClass == "Container"
					This.Stretch(m.loControl)
				Case m.loControl.BaseClass == "Pageframe"
					For Each loPage In m.loControl.Pages
						This.Stretch(m.loPage)
					Endfor
				Case m.loControl.BaseClass == "Grid"
					For Each loColumn In m.loControl.Columns
						This.AdjustSize(m.loColumn)
					Endfor
				Case Inlist(m.loControl.BaseClass, "Commandgroup", "Optiongroup")
					For Each loButton In m.loControl.Buttons
						This.AdjustSize(m.loButton)
					Endfor
				Endcase
			Endfor
		Catch To loEx
			This.cLastError = "Stretch(): " + m.loEx.Message
		Finally
			If m.loContainer.BaseClass == "Form"
				m.loContainer.LockScreen = m.llLocked
			Endif
		Endtry
	Endproc

	* Scales one control from its saved geometry. A control that refuses a
	* value (a read-only property, a size out of range) keeps the rest.
	Procedure AdjustSize(toObject)
		Local lnHeightRatio, lnWidthRatio, lnFontRatio, loEx
		lnHeightRatio = This.oForm.Height / This.nOriginalHeight
		lnWidthRatio  = This.oForm.Width / This.nOriginalWidth
		lnFontRatio   = Min(m.lnHeightRatio, m.lnWidthRatio)

		Try
			With m.toObject
				If Pemstatus(m.toObject, "_nOriginalWidth", 5)
					.Width = ._nOriginalWidth * m.lnWidthRatio
					If Pemstatus(m.toObject, "_nOriginalHeight", 5)
						.Height = ._nOriginalHeight * m.lnHeightRatio
						.Top    = ._nOriginalTop * m.lnHeightRatio
						.Left   = ._nOriginalLeft * m.lnWidthRatio
					Endif
				Endif
				If Pemstatus(m.toObject, "_nOriginalFontsize", 5)
					.FontSize = Max(4, Round(._nOriginalFontsize * m.lnFontRatio, 0))
				Endif
				If Pemstatus(m.toObject, "_nOriginalRowheight", 5)
					.RowHeight = ._nOriginalRowheight * m.lnHeightRatio
				Endif
				If Pemstatus(m.toObject, "_nOriginalHeaderHeight", 5)
					.HeaderHeight = ._nOriginalHeaderHeight * m.lnHeightRatio
				Endif
				If .BaseClass == "Control" And Pemstatus(m.toObject, "RepositionContents", 5)
					.RepositionContents()
				Endif
				If .BaseClass == "Listbox" And Pemstatus(m.toObject, "_nOriginalColumnWidths", 5)
					.ColumnWidths = This.ScaleColumnWidths(._nOriginalColumnWidths, m.lnWidthRatio)
				Endif
			Endwith
		Catch To loEx
			This.cLastError = "AdjustSize(" + m.toObject.Name + "): " + m.loEx.Message
		Endtry
	Endproc

	* "100,50,80" scaled by 1.5 is "150,75,120".
	Function ScaleColumnWidths(tcWidths, tnRatio)
		Local lcWidths, lnIndex
		lcWidths = ""
		For lnIndex = 1 To Getwordcount(m.tcWidths, ",")
			lcWidths = m.lcWidths + Iif(Empty(m.lcWidths), "", ",") + ;
				Transform(Int(Val(Getwordnum(m.tcWidths, m.lnIndex, ",")) * m.tnRatio))
		Endfor
		Return m.lcWidths
	Endfunc

	*--------------------------------------------------------------------------
	* Zoom
	*--------------------------------------------------------------------------
	* Sizes the form at the zoom of the application (_Screen.CurrentZoom), or
	* at tnPercent: 0 is the size of the designer, 1 to 99 grows the form that
	* much of the way to the size of the screen, 100 maximizes it.
	Procedure Zoom(tnPercent)
		Local lnPercent, lnMaxWidth, lnMaxHeight
		If Vartype(This.oForm) != "O"
			Return
		Endif
		Do Case
		Case Vartype(m.tnPercent) == "N"
			lnPercent = m.tnPercent
		Case Type("_Screen.CurrentZoom") == "N"
			lnPercent = _Screen.CurrentZoom
		Otherwise
			lnPercent = 0
		Endcase
		lnPercent = Max(0, Min(100, m.lnPercent))

		With This.oForm
			Do Case
			Case m.lnPercent = 100
				.WindowState = 2
			Case m.lnPercent = 0
				.WindowState = 0
				This.ResetSize()
			Otherwise
				.WindowState = 0
				If .ShowWindow = 2
					lnMaxWidth  = Sysmetric(1)
					lnMaxHeight = Sysmetric(2) - 40
				Else
					lnMaxWidth  = _Screen.Width
					lnMaxHeight = _Screen.Height - 25
				Endif
				.Width  = This.nOriginalWidth + Int(Max(0, m.lnMaxWidth - This.nOriginalWidth) * m.lnPercent / 100)
				.Height = This.nOriginalHeight + Int(Max(0, m.lnMaxHeight - This.nOriginalHeight) * m.lnPercent / 100)
				.AutoCenter = .T.
			Endcase
		Endwith
	Endproc
Enddefine
