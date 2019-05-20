Define Class VfpStretch As Custom
	nOriginalHeight		= 0
	nOriginalWidth		= 0
	oForm				= .Null.
	Procedure Do
		Lparameters toThisform

		This.oForm = toThisform

		If Type("THIS.oForm") != "O"
			Messagebox("You must create VfpStretch object inside a form!", 48, "Warning!")
			Return .F.
		Else &&TYPE("THIS.oForm") != "O"
		Endif &&TYPE("THIS.oForm") != "O"

		This.oForm.MinHeight 		= This.oForm.Height
		This.oForm.MinWidth 		= This.oForm.Width

		This.nOriginalHeight 	= This.oForm.Height
		This.nOriginalWidth 	= This.oForm.Width
		This.SaveContainer(This.oForm)
*-- Binding Resize Method
		=Bindevent(This.oForm, "Resize", This, "Stretch", 1)
	Endproc

	Procedure ResetSize
		This.oForm.Height = This.nOriginalHeight
		This.oForm.Width  = This.nOriginalWidth
	Endproc

	Procedure SaveContainer
		Lparameters oContainer

		Local oThis
		This.SaveOriginalSize(m.oContainer)
		For Each m.oThis In m.oContainer.Controls
			If !m.oThis.BaseClass == 'Custom'
				This.SaveOriginalSize(m.oThis)
			Else &&!m.oThis.BASECLASS == 'Custom'
			Endif &&!m.oThis.BASECLASS == 'Custom'

			If Type("m.oThis.Anchor") = "N" And m.oThis.Anchor > 0
				m.oThis.Anchor = 0
			Else &&TYPE("m.oThis.Anchor") = "N" AND m.oThis.ANCHOR > 0
			Endif &&TYPE("m.oThis.Anchor") = "N" AND m.oThis.ANCHOR > 0

			Do Case
			Case m.oThis.BaseClass == 'Container'
				This.SaveContainer(m.oThis)
			Case m.oThis.BaseClass == 'Pageframe'
				Local oPage
				For Each oPage In m.oThis.Pages
					This.SaveContainer(m.oPage)
				Endfor &&EACH oPage IN m.oThis.PAGES
			Case m.oThis.BaseClass == 'Grid'
				Local oColumn
				For Each oColumn In m.oThis.Columns
					This.SaveOriginalSize(m.oColumn)
				Endfor &&EACH oColumn IN m.oThis.COLUMNS
			Case m.oThis.BaseClass $ 'Commandgroup,Optiongroup'
				Local oButton
				For Each oButton In m.oThis.Buttons
					This.SaveOriginalSize(m.oButton)
				Endfor &&EACH oButton IN m.oThis.BUTTONS
			Otherwise
			Endcase
		Endfor &&EACH m.oThis IN m.oContainer.CONTROLS
	Endproc

	Procedure SaveOriginalSize
		Lparameters oObject
		If Pemstatus(m.oObject, 'Width', 5)
			If !Pemstatus(m.oObject, '_nOriginalWidth', 5)
				=AddProperty(m.oObject, "_nOriginalWidth", m.oObject.Width)
			Else &&!PEMSTATUS(m.oObject, '_nOriginalWidth', 5)
			Endif &&!PEMSTATUS(m.oObject, '_nOriginalWidth', 5)

			If Pemstatus(m.oObject, 'Height', 5)
				If !Pemstatus(m.oObject, '_nOriginalHeight', 5)
					=AddProperty(m.oObject, "_nOriginalHeight", m.oObject.Height)
				Else &&!PEMSTATUS(m.oObject, '_nOriginalHeight', 5)
				Endif &&!PEMSTATUS(m.oObject, '_nOriginalHeight', 5)
				If !Pemstatus(m.oObject, '_nOriginalLeft', 5)
					=AddProperty(m.oObject, "_nOriginalLeft", m.oObject.Left)
				Else &&!PEMSTATUS(m.oObject, '_nOriginalLeft', 5)
				Endif &&!PEMSTATUS(m.oObject, '_nOriginalLeft', 5)
				If !Pemstatus(m.oObject, '_nOriginalTop', 5)
					=AddProperty(m.oObject, "_nOriginalTop", m.oObject.Top)
				Else &&!PEMSTATUS(m.oObject, '_nOriginalTop', 5)
				Endif &&!PEMSTATUS(m.oObject, '_nOriginalTop', 5)
			Else &&PEMSTATUS(m.oObject, 'Height', 5)
			Endif &&PEMSTATUS(m.oObject, 'Height', 5)
		Else &&PEMSTATUS(m.oObject, 'Width', 5)
		Endif &&PEMSTATUS(m.oObject, 'Width', 5)

		If Pemstatus(m.oObject, 'Fontsize', 5)
			=AddProperty(m.oObject, "_nOriginalFontsize", m.oObject.FontSize)
		Else &&PEMSTATUS(m.oObject, 'Fontsize', 5)
		Endif &&PEMSTATUS(m.oObject, 'Fontsize', 5)

		If Pemstatus(m.oObject, 'RowHeight', 5)
			=AddProperty(m.oObject, "_nOriginalRowheight", m.oObject.RowHeight)
		Else &&PEMSTATUS(m.oObject, 'RowHeight', 5)
		Endif &&PEMSTATUS(m.oObject, 'RowHeight', 5)
	Endproc

	Procedure Stretch
		Lparameters oContainer
		If Type("oContainer") != "O"
			oContainer = This.oForm
		Else &&Type("oContainer") != "O"
		Endif &&Type("oContainer") != "O"

		Local oThis
		If m.oContainer.BaseClass == 'Form'
			m.oContainer.LockScreen = .T.
		Else &&m.oContainer.BASECLASS == 'Form'
			This.AdjustSize(m.oContainer)
		Endif &&m.oContainer.BASECLASS == 'Form'

		For Each m.oThis In m.oContainer.Controls
			If !m.oThis.BaseClass == 'Custom'
				This.AdjustSize(m.oThis)
			Else &&!m.oThis.BASECLASS == 'Custom'
			Endif &&!m.oThis.BASECLASS == 'Custom'
			Do Case
			Case m.oThis.BaseClass == 'Container'
				This.Stretch(m.oThis)
			Case m.oThis.BaseClass == 'Pageframe'
				Local oPage
				For Each oPage In m.oThis.Pages
					This.Stretch(m.oPage)
				Endfor &&EACH oPage IN m.oThis.PAGES
			Case m.oThis.BaseClass == 'Grid'
				Local oColumn
				For Each oColumn In m.oThis.Columns
					This.AdjustSize(m.oColumn)
				Endfor &&EACH oColumn IN m.oThis.COLUMNS
			Case m.oThis.BaseClass $ 'Commandgroup,Optiongroup'
				Local oButton
				For Each oButton In m.oThis.Buttons
					This.AdjustSize(m.oButton)
				Endfor &&EACH oButton IN m.oThis.BUTTONS
			Otherwise
			Endcase
		Endfor &&EACH m.oThis IN m.oContainer.CONTROLS
		If m.oContainer.BaseClass == 'Form'
			m.oContainer.LockScreen = .F.
		Else &&m.oContainer.BASECLASS == 'Form'
		Endif &&m.oContainer.BASECLASS == 'Form'
	Endproc

	Procedure AdjustSize
		Lparameters oObject
		Local nHeightRatio, nWidthRatio
		m.nHeightRatio 	= This.oform.Height / This.nOriginalheight
		m.nWidthRatio 	= This.oform.Width / This.nOriginalwidth

		With m.oObject
			If Pemstatus(m.oObject, '_nOriginalWidth', 5)
				.Width  = ._nOriginalWidth * m.nWidthRatio
				If Pemstatus(m.oObject, '_nOriginalHeight', 5)
					.Height = ._nOriginalHeight * m.nHeightRatio
					.Top    = ._nOriginalTop * m.nHeightRatio
					.Left   = ._nOriginalLeft * m.nWidthRatio
				Else &&PEMSTATUS(m.oObject, '_nOriginalHeight', 5)
				Endif &&PEMSTATUS(m.oObject, '_nOriginalHeight', 5)
			Else &&PEMSTATUS(m.oObject, '_nOriginalWidth', 5)
			Endif &&PEMSTATUS(m.oObject, '_nOriginalWidth', 5)

			If Pemstatus(m.oObject, '_nOriginalFontsize', 5)
				.FontSize = Max(4, Round(._nOriginalFontsize * ;
					IIF(Abs(m.nHeightRatio) < Abs(m.nWidthRatio), m.nHeightRatio, m.nWidthRatio), 0))
			Else &&PEMSTATUS(m.oObject, '_nOriginalFontsize', 5)
			Endif &&PEMSTATUS(m.oObject, '_nOriginalFontsize', 5)

			If Pemstatus(m.oObject, '_nOriginalRowheight', 5)
				.RowHeight = ._nOriginalRowheight * m.nHeightRatio
			Else &&PEMSTATUS(m.oObject, '_nOriginalRowheight', 5)
			Endif &&PEMSTATUS(m.oObject, '_nOriginalRowheight', 5)

			If .BaseClass == 'Control' And Pemstatus(m.oObject, 'RepositionContents', 5)
				.RepositionContents()
			Else &&.BASECLASS == 'Control' AND PEMSTATUS(m.oObject, 'RepositionContents', 5)
			Endif &&.BASECLASS == 'Control' AND PEMSTATUS(m.oObject, 'RepositionContents', 5)
		Endwith
	Endproc
Enddefine
