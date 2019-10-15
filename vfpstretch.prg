*====================================================================
* VfpStretch Class
*====================================================================
Define Class VfpStretch As Custom

	nOriginalHeight		= 0
	nOriginalWidth		= 0
	oForm				= .Null.

	Procedure Do
		Lparameters toThisform
		With This
			.oForm = toThisform

			If Type(".oForm") != "O"
				Messagebox("You must create VfpStretch object inside a form!", 48, "Warning!")
				Return .F.
			Endif

			.oForm.MinHeight = .oForm.Height
			.oForm.MinWidth  = .oForm.Width

			.nOriginalHeight = .oForm.Height
			.nOriginalWidth  = .oForm.Width
			.SaveContainer(.oForm)

			=Bindevent(.oForm, "Resize", This, "Stretch", 1)
		EndWith
		
*====================================================================
	Procedure ResetSize
		With This.oForm
			.Height = This.nOriginalHeight
			.Width  = This.nOriginalWidth
		EndWith
		
*====================================================================
	Procedure SaveContainer
		Lparameters oContainer
		With This
			Local oThis
			.SaveOriginalSize(m.oContainer)
			For Each m.oThis In m.oContainer.Controls								
				IF m.oThis.Tag <> "NOSTRETCH"
					If !m.oThis.BaseClass == 'Custom'
						.SaveOriginalSize(m.oThis)
					Endif

					If Type("m.oThis.Anchor") = "N" And m.oThis.Anchor > 0
						m.oThis.Anchor = 0
					Endif

					Do Case
					Case m.oThis.BaseClass == 'Container'
						.SaveContainer(m.oThis)
					Case m.oThis.BaseClass == 'Pageframe'
						Local oPage
						For Each oPage In m.oThis.Pages
							.SaveContainer(m.oPage)
						Endfor
					Case m.oThis.BaseClass == 'Grid'
						Local oColumn
						For Each oColumn In m.oThis.Columns
							.SaveOriginalSize(m.oColumn)
						Endfor
					Case m.oThis.BaseClass $ 'Commandgroup,Optiongroup'
						Local oButton
						For Each oButton In m.oThis.Buttons
							.SaveOriginalSize(m.oButton)
						Endfor
					ENDCASE
				ENDIF	
			Endfor
		EndWith
		
*====================================================================
	Procedure SaveOriginalSize
		Lparameters oObject
		If Pemstatus(m.oObject, 'Width', 5)
			If !Pemstatus(m.oObject, '_nOriginalWidth', 5)
				=AddProperty(m.oObject, "_nOriginalWidth", m.oObject.Width)
			Endif

			If Pemstatus(m.oObject, 'Height', 5)
				If !Pemstatus(m.oObject, '_nOriginalHeight', 5)
					=AddProperty(m.oObject, "_nOriginalHeight", m.oObject.Height)
				Endif
				If !Pemstatus(m.oObject, '_nOriginalLeft', 5)
					=AddProperty(m.oObject, "_nOriginalLeft", m.oObject.Left)
				Endif
				If !Pemstatus(m.oObject, '_nOriginalTop', 5)
					=AddProperty(m.oObject, "_nOriginalTop", m.oObject.Top)
				Endif
			Endif
		Endif

		If Pemstatus(m.oObject, 'Fontsize', 5)
			=AddProperty(m.oObject, "_nOriginalFontsize", m.oObject.FontSize)
		Endif

		If Pemstatus(m.oObject, 'RowHeight', 5)
			=AddProperty(m.oObject, "_nOriginalRowheight", m.oObject.RowHeight)
		EndIf
		
*====================================================================
	Procedure Stretch
		Lparameters oContainer
		With This
			If Type("oContainer") != "O"
				oContainer = .oForm
			Endif

			Local oThis
			If m.oContainer.BaseClass == 'Form'
				m.oContainer.LockScreen = .T.
			Else
				.AdjustSize(m.oContainer)
			Endif

			For Each m.oThis In m.oContainer.Controls
				If !m.oThis.BaseClass == 'Custom'
					.AdjustSize(m.oThis)
				Endif
				Do Case
				Case m.oThis.BaseClass == 'Container'
					.Stretch(m.oThis)
				Case m.oThis.BaseClass == 'Pageframe'
					Local oPage
					For Each oPage In m.oThis.Pages
						.Stretch(m.oPage)
					Endfor
				Case m.oThis.BaseClass == 'Grid'
					Local oColumn
					For Each oColumn In m.oThis.Columns
						.AdjustSize(m.oColumn)
					Endfor
				Case m.oThis.BaseClass $ 'Commandgroup,Optiongroup'
					Local oButton
					For Each oButton In m.oThis.Buttons
						.AdjustSize(m.oButton)
					Endfor
				Endcase
			Endfor
			If m.oContainer.BaseClass == 'Form'
				m.oContainer.LockScreen = .F.
			Endif
		EndWith
*====================================================================

	Procedure AdjustSize
		Lparameters oObject
		Local nHeightRatio, nWidthRatio
		m.nHeightRatio 	= This.oForm.Height / This.nOriginalHeight
		m.nWidthRatio 	= This.oForm.Width / This.nOriginalWidth

		With m.oObject
			If Pemstatus(m.oObject, '_nOriginalWidth', 5)
				.Width  = ._nOriginalWidth * m.nWidthRatio
				If Pemstatus(m.oObject, '_nOriginalHeight', 5)
					.Height = ._nOriginalHeight * m.nHeightRatio
					.Top    = ._nOriginalTop * m.nHeightRatio
					.Left   = ._nOriginalLeft * m.nWidthRatio
				Endif
			Endif

			If Pemstatus(m.oObject, '_nOriginalFontsize', 5)
				.FontSize = Max(4, Round(._nOriginalFontsize * ;
					IIF(Abs(m.nHeightRatio) < Abs(m.nWidthRatio), m.nHeightRatio, m.nWidthRatio), 0))
			Endif

			If Pemstatus(m.oObject, '_nOriginalRowheight', 5)
				.RowHeight = ._nOriginalRowheight * m.nHeightRatio
			Endif

			If .BaseClass == 'Control' And Pemstatus(m.oObject, 'RepositionContents', 5)
				.RepositionContents()
			Endif
		EndWith
		
*====================================================================
Enddefine