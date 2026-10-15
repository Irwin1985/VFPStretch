# VFPStretch

Resizes every control of a Visual FoxPro 9 form when the form is resized: position, size,
font, grid rows and list columns grow and shrink with the window. It can also open every
form of an application at a zoom level the user chooses once. One `.prg`, no dependencies,
and the form does not have to change.

## Install

```
foxpack add vfpstretch
```

```foxpro
SET PROCEDURE TO vfpstretch.prg ADDITIVE
```

Without FoxPack, copy `vfpstretch.prg` into your project.

## Example

In the `Init` of a form:

```foxpro
DO vfpstretch.prg WITH ThisForm
```

Or once for the whole application, in your main program:

```foxpro
SET PROCEDURE TO vfpstretch.prg ADDITIVE
=ADDPROPERTY(_Screen, "oVfpStretch", CREATEOBJECT("vfpStretch"))
```

and in the `Init` of every form:

```foxpro
_Screen.oVfpStretch.Do(ThisForm)
```

Drag the border of the form: every control follows.

## API

### vfpStretch.Do(oForm)

Makes the form stretchable. It saves the size, position and font of every control as they
are now, and from then on scales them each time the form fires `Resize`. Returns the
`Stretcher` that does the work, also kept in `oForm.oVfpStretch`; returns `.NULL.` when it
could not, and `cLastError` says why. Calling it again on the same form returns the same
`Stretcher`. Without `oForm` it takes `_Screen.ActiveForm`.

```foxpro
LOCAL loStretch, loStretcher
loStretch = CREATEOBJECT("vfpStretch")
loStretcher = loStretch.Do(ThisForm)
IF ISNULL(loStretcher)
	? loStretch.cLastError
ENDIF
```

If the form has no `MinWidth` or `MinHeight` of its own, `Do()` gives it a quarter of its size.

### vfpStretch.Zoom([nPercent], [oForm])

Sizes a form that `Do()` already took. `nPercent` is `0` for the size of the designer,
`1` to `99` to grow the form that much of the way to the size of the screen, and `100` to
maximize it. Without `nPercent` it reads `_Screen.CurrentZoom`; without `oForm` it takes the
active form. Returns `.T.`, or `.F.` with the reason in `cLastError`.

```foxpro
_Screen.CurrentZoom = 50
_Screen.oVfpStretch.Zoom()
```

### _Screen.CurrentZoom

The zoom of the whole application, from `0` to `100`. Creating a `vfpStretch` adds it with
`0`. Every form that `Do()` takes afterwards opens at this zoom, so the user chooses it once.

### Stretcher

The object `Do()` returns, one per form.

| Member | What it does |
|---|---|
| `Stretch()` | Scales the controls to the size the form has now. `Resize` calls it |
| `ResetSize()` | Gives the form the size it had when `Do()` took it |
| `Zoom([nPercent])` | As `vfpStretch.Zoom()`, on its own form |
| `nOriginalWidth`, `nOriginalHeight` | The size of the form when `Do()` took it |
| `cLastError` | The last control that refused a value, or `""` |

### Leaving a control alone

Put `NOSTRETCH` in its `Tag`. The control, and everything inside it if it is a container,
keeps its size and position.

### Members

| Member | What it is |
|---|---|
| `vfpStretch.cVersion` | `"2.1.0"` |
| `vfpStretch.cLastError` | Why the last `Do()` or `Zoom()` failed, or `""` |

## What it scales

| Control | What changes |
|---|---|
| Every control | `Left`, `Top`, `Width`, `Height` |
| Controls with a font | `FontSize`, by the smaller of the two ratios, and never below 4 points |
| Container, Page | The controls inside, at any depth |
| Grid | The columns, `RowHeight` and `HeaderHeight` |
| CommandGroup, OptionGroup | Each button |
| ListBox | `ColumnWidths` |

## Pitfalls

- **Call `Do()` when the form has its final layout.** It saves what it sees: a control added
  afterwards with `AddObject` is not scaled. Call `Do()` at the end of `Init`.
- **`Anchor` is switched off.** `Do()` sets `Anchor` to `0` on the controls it scales,
  because the two would move the same control. Use `NOSTRETCH` on a control that must keep
  its anchor.
- **A form that is not visible does not fire `Resize`.** Changing its size in code before
  `Show()` does not scale anything: call `oForm.oVfpStretch.Stretch()` yourself.
- **Your own `Resize` code runs before VFPStretch.** There the controls still have their old
  size; if your code needs the new one, call `ThisForm.oVfpStretch.Stretch()` first.
- **A control can refuse a value.** A `ComboBox` keeps the height its font needs, for
  example. The other properties are still applied, and `Stretcher.cLastError` names it.

## Sample

`sample.pjx` builds a sample application: `DO main.prg` in the repository folder runs it,
with a zoom combo and a container tagged `NOSTRETCH`.

## Tests

From the repository folder:

```
foxproof run --prg tests\VFPStretchTests.prg
```

## History

- **2.1.0** (2026-10-15). `Do()` no longer shrinks the form to a quarter of its size (since
  2024-07-19 it did, on every form). It keeps the `MinWidth` and `MinHeight` of the
  designer, does not show a message box (it returns `.NULL.` and fills `cLastError`), returns
  the `Stretcher`, and reuses it when called twice on a form. New `vfpStretch.Zoom()`, which
  the sample already called. Scales `HeaderHeight` of a grid. A control that refuses a value
  no longer stops the others. The form is released when it closes. Tests in FoxProof,
  package for FoxPack, MIT license.
- **2.0** (2020-10-22). Zoom with `_Screen.CurrentZoom`.
- **1.2** (2019-05-20). First public version.

Inspired by [Stretchy Resize Control](http://www.codemine.com/Download.htm).

## License

MIT. See [LICENSE](LICENSE).
