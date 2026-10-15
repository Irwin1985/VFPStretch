* VFPStretchTests.prg
* Test suite for VFPStretch 2.1.0
* Run from the repository folder: foxproof run --prg tests\VFPStretchTests.prg
*
* A form that is not visible does not fire Resize, so the tests call
* Stretch() themselves after changing the size of the form.

#define STRETCH_PRG 'vfpstretch.prg'

*==============================================================
* Do(): taking a form
*==============================================================
define class TestDo as Custom

    oForm = .null.
    oStretch = .null.

    procedure SetUp
        set procedure to STRETCH_PRG additive
        if type("_screen.CurrentZoom") == "N"
            _screen.CurrentZoom = 0
        endif
        this.oStretch = createobject("vfpStretch")
        this.oForm = NewTestForm()
    endproc

    procedure TearDown
        if vartype(this.oForm) == "O"
            this.oForm.Release()
        endif
        this.oForm = .null.
        this.oStretch = .null.
    endproc

    procedure Test_Do_KeepsTheSizeOfTheDesigner() HELP [Fact, Trait("Category", "Do")]
        * 2.0 shrank every form to a quarter of its size here
        this.oStretch.Do(this.oForm)
        __assert.Equal(400, this.oForm.Width, "Width after Do()")
        __assert.Equal(300, this.oForm.Height, "Height after Do()")
    endproc

    procedure Test_Do_GivesAQuarterAsMinimumSize() HELP [Fact, Trait("Category", "Do")]
        this.oStretch.Do(this.oForm)
        __assert.Equal(100, this.oForm.MinWidth, "MinWidth")
        __assert.Equal(75, this.oForm.MinHeight, "MinHeight")
    endproc

    procedure Test_Do_KeepsTheMinimumOfTheDesigner() HELP [Fact, Trait("Category", "Do")]
        this.oForm.MinWidth = 250
        this.oStretch.Do(this.oForm)
        __assert.Equal(250, this.oForm.MinWidth, "MinWidth set by the designer")
    endproc

    procedure Test_Do_ReturnsTheStretcherAndHangsItFromTheForm() HELP [Fact, Trait("Category", "Do")]
        local loStretcher
        loStretcher = this.oStretch.Do(this.oForm)
        __assert.True(vartype(loStretcher) == "O", "Do() returns the Stretcher")
        __assert.True(loStretcher == this.oForm.oVfpStretch, "ThisForm.oVfpStretch is the same object")
    endproc

    procedure Test_Do_Twice_ReturnsTheSameStretcher() HELP [Fact, Trait("Category", "Do")]
        local loFirst, loSecond
        loFirst = this.oStretch.Do(this.oForm)
        this.oForm.Width = 800
        loFirst.Stretch()
        loSecond = this.oStretch.Do(this.oForm)
        __assert.True(loFirst == loSecond, "The second Do() reuses the Stretcher")
        __assert.Equal(400, loSecond.nOriginalWidth, "The original width is still the first one")
    endproc

    procedure Test_Do_WithoutAForm_ReturnsNullAndSaysWhy() HELP [Fact, Trait("Category", "Do")]
        local loResult
        loResult = this.oStretch.Do("not a form")
        __assert.True(isnull(loResult), "Do() returns .NULL.")
        __assert.True("form" $ this.oStretch.cLastError, "cLastError explains it")
    endproc

    procedure Test_EntryPoint_DoWith() HELP [Fact, Trait("Category", "Do")]
        do (STRETCH_PRG) with this.oForm
        __assert.True(type("this.oForm.oVfpStretch") == "O", "DO vfpstretch.prg WITH ThisForm hangs a Stretcher")
    endproc

    procedure Test_Version() HELP [Fact, Trait("Category", "Do")]
        __assert.Equal("2.1.0", this.oStretch.cVersion, "cVersion")
    endproc

enddefine


*==============================================================
* Stretch(): scaling the controls
*==============================================================
define class TestStretch as Custom

    oForm = .null.
    oStretcher = .null.

    procedure SetUp
        set procedure to STRETCH_PRG additive
        if type("_screen.CurrentZoom") == "N"
            _screen.CurrentZoom = 0
        endif
        this.oForm = NewTestForm()
    endproc

    procedure TearDown
        if vartype(this.oForm) == "O"
            this.oForm.Release()
        endif
        this.oForm = .null.
        this.oStretcher = .null.
    endproc

    hidden procedure Start
        local loStretch
        loStretch = createobject("vfpStretch")
        this.oStretcher = loStretch.Do(this.oForm)
    endproc

    hidden procedure Resize(tnWidth, tnHeight)
        this.oForm.Width = tnWidth
        this.oForm.Height = tnHeight
        this.oStretcher.Stretch()
    endproc

    procedure Test_DoubleSize_DoublesPositionAndSize() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(800, 600)
        __assert.Equal(200, this.oForm.txtName.Left, "Left")
        __assert.Equal(400, this.oForm.txtName.Width, "Width")
        __assert.Equal(40, this.oForm.txtName.Top, "Top")
    endproc

    procedure Test_Font_FollowsTheSmallerRatio() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(1200, 600)
        __assert.Equal(18, this.oForm.txtName.FontSize, "9 pt times 2, not times 3")
    endproc

    procedure Test_Font_NeverBelowFourPoints() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(100, 75)
        __assert.True(this.oForm.txtName.FontSize >= 4, "FontSize >= 4")
    endproc

    procedure Test_ControlsInsideContainersAndPages() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(800, 600)
        __assert.Equal(60, this.oForm.cntBox.lblInside.Left, "Label inside a container")
        __assert.Equal(40, this.oForm.pgf.Page1.txtCity.Left, "TextBox inside a page")
        __assert.Equal(600, this.oForm.pgf.Width, "The page frame itself")
    endproc

    procedure Test_GridColumnsRowsAndHeader() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(800, 600)
        __assert.Equal(160, this.oForm.grd.Column1.Width, "Column width")
        __assert.Equal(40, this.oForm.grd.RowHeight, "RowHeight")
        __assert.Equal(40, this.oForm.grd.HeaderHeight, "HeaderHeight")
    endproc

    procedure Test_ListBoxColumnWidths() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(800, 600)
        __assert.Equal("120,80", this.oForm.lst.ColumnWidths, "ColumnWidths doubled")
    endproc

    procedure Test_OptionGroupButtons() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(800, 600)
        __assert.Equal(20, this.oForm.opg.Option1.Left, "Button inside the group")
    endproc

    procedure Test_NoStretchTag_LeavesTheControlAndItsChildren() HELP [Fact, Trait("Category", "Stretch")]
        this.oForm.cntBox.Tag = "NOSTRETCH"
        this.Start()
        this.Resize(800, 600)
        __assert.Equal(200, this.oForm.cntBox.Width, "The tagged container")
        __assert.Equal(30, this.oForm.cntBox.lblInside.Left, "A control inside it")
    endproc

    procedure Test_AnchorIsSwitchedOff() HELP [Fact, Trait("Category", "Stretch")]
        this.oForm.txtName.Anchor = 10
        this.Start()
        __assert.Equal(0, this.oForm.txtName.Anchor, "Anchor would fight the stretch")
    endproc

    procedure Test_ResetSize_GoesBackToTheOriginal() HELP [Fact, Trait("Category", "Stretch")]
        this.Start()
        this.Resize(800, 600)
        this.oStretcher.ResetSize()
        __assert.Equal(400, this.oForm.Width, "Form width")
        __assert.Equal(100, this.oForm.txtName.Left, "Control back in place")
    endproc

    procedure Test_ScaleColumnWidths() HELP [Fact, Trait("Category", "Stretch")]
        local loStretcher
        loStretcher = createobject("Stretcher")
        __assert.Equal("150,75,120", loStretcher.ScaleColumnWidths("100,50,80", 1.5), "Each width scaled")
    endproc

enddefine


*==============================================================
* Zoom and the life of the form
*==============================================================
define class TestZoom as Custom

    oForm = .null.

    procedure SetUp
        set procedure to STRETCH_PRG additive
        this.oForm = NewTestForm()
    endproc

    procedure TearDown
        if type("_screen.CurrentZoom") == "N"
            _screen.CurrentZoom = 0
        endif
        if vartype(this.oForm) == "O"
            this.oForm.Release()
        endif
        this.oForm = .null.
    endproc

    procedure Test_Zoom100_Maximizes() HELP [Fact, Trait("Category", "Zoom")]
        local loStretch
        loStretch = createobject("vfpStretch")
        _screen.CurrentZoom = 100
        loStretch.Do(this.oForm)
        __assert.Equal(2, this.oForm.WindowState, "WindowState")
    endproc

    procedure Test_Zoom50_GrowsTheForm() HELP [Fact, Trait("Category", "Zoom")]
        local loStretch, loStretcher
        loStretch = createobject("vfpStretch")
        loStretcher = loStretch.Do(this.oForm)
        loStretcher.Zoom(50)
        __assert.True(this.oForm.Width > 400, "Wider than the designer")
        __assert.True(this.oForm.Width < max(_screen.Width, 401), "Narrower than the screen")
    endproc

    procedure Test_ZoomZero_GoesBackToTheDesigner() HELP [Fact, Trait("Category", "Zoom")]
        local loStretch
        loStretch = createobject("vfpStretch")
        loStretch.Do(this.oForm)
        __assert.True(loStretch.Zoom(100, this.oForm), "Zoom(100) on a taken form")
        __assert.True(loStretch.Zoom(0, this.oForm), "Zoom(0)")
        __assert.Equal(0, this.oForm.WindowState, "WindowState")
        __assert.Equal(400, this.oForm.Width, "Width of the designer")
    endproc

    procedure Test_Zoom_OnAFormNotTaken_SaysWhy() HELP [Fact, Trait("Category", "Zoom")]
        local loStretch
        loStretch = createobject("vfpStretch")
        __assert.False(loStretch.Zoom(50, this.oForm), "Zoom() returns .F.")
        __assert.True("Do()" $ loStretch.cLastError, "cLastError explains it")
    endproc

    procedure Test_Do_WithZoomZero_LeavesAMaximizedForm() HELP [Fact, Trait("Category", "Zoom")]
        local loStretch
        this.oForm.WindowState = 2
        loStretch = createobject("vfpStretch")
        loStretch.Do(this.oForm)
        __assert.Equal(2, this.oForm.WindowState, "The designer maximized it")
    endproc

    procedure Test_FormRelease_LetsGo() HELP [Fact, Trait("Category", "Zoom")]
        local loStretch, loStretcher
        loStretch = createobject("vfpStretch")
        loStretcher = loStretch.Do(this.oForm)
        this.oForm.Release()
        this.oForm = .null.
        __assert.True(isnull(loStretcher.oForm), "The Stretcher no longer holds the form")
    endproc

enddefine


*==============================================================
* A 400 x 300 form with one control of each kind
*==============================================================
function NewTestForm
    local loForm
    loForm = createobject("Form")
    loForm.Width = 400
    loForm.Height = 300

    loForm.AddObject("txtName", "TextBox")
    with loForm.txtName
        .Left = 100
        .Top = 20
        .Width = 200
        .FontSize = 9
    endwith

    loForm.AddObject("cntBox", "Container")
    with loForm.cntBox
        .Left = 10
        .Top = 60
        .Width = 200
        .Height = 50
        .AddObject("lblInside", "Label")
        .lblInside.Left = 30
    endwith

    loForm.AddObject("pgf", "PageFrame")
    with loForm.pgf
        .PageCount = 2
        .Left = 10
        .Top = 120
        .Width = 300
        .Height = 100
        .Page1.AddObject("txtCity", "TextBox")
        .Page1.txtCity.Left = 20
    endwith

    loForm.AddObject("grd", "Grid")
    with loForm.grd
        .ColumnCount = 2
        .Left = 10
        .Top = 230
        .Width = 200
        .Height = 60
        .Column1.Width = 80
        .RowHeight = 20
        .HeaderHeight = 20
    endwith

    loForm.AddObject("lst", "ListBox")
    with loForm.lst
        .Left = 250
        .Top = 230
        .Width = 100
        .Height = 60
        .ColumnCount = 2
        .ColumnWidths = "60,40"
    endwith

    loForm.AddObject("opg", "OptionGroup")
    with loForm.opg
        .ButtonCount = 2
        .Left = 320
        .Top = 20
        .Width = 70
        .Height = 50
        .Option1.Left = 10
    endwith
    return loForm
endfunc
