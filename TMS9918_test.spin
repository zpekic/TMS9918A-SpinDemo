{Test TMS9918 object with some graphical demo scenario}


CON
'        _clkmode = xtal1 + pll16x  'Standard clock mode * crystal frequency = 80 MHz
'        _xinfreq = 5_000_000
        '_clkmode = xtal3 + pll4x  'high speed crystal multiplied by 4 = 85.90908MHz
        '_xinfreq = 21_477_270     'V9958 crystal

OBJ
  'pst2     : "Parallax Serial Terminal"
  vdp      : "TMS9918"

PUB Main | mode, rnd, switches
  waitcnt((clkfreq * 4) + cnt) 'wait 4s before start

  if vdp.Start(@CommandBuffer, vdp#GRAPHICS1, false, true)

    'dira[9..8]~~                'output
    'frqa := %1_00000_000_00000000_000000_000_000000
    'ctra := %0_00011_110_00000000_001001_000_001000 'PLL mode /2 to pins 8 and 9

    repeat true
      'read switches and if color is TRANSPARENT (== 0) continue with demo, otherwise show solid color screen
      dira[13..10]~ 'set as input
      switches := ina[13..10]
      if (switches < 8)
        vdp.Trace(String("Switches are in COLOR (< 8) mode, displaying 8 vertical color bars for calibration "), switches)
        vdp.SetMode(vdp#MULTICOLOR)
        _colorfulBlocks(byte[@ColorPalette8][switches])
      else
        if (switches > 8)
          vdp.Trace(String("Switches are in TICK (> 8) mode, tick lines (every 8 pixels) "), switches)
          vdp.SetMode(vdp#GRAPHICS2)
          _tickLines(byte[@ColorPalette8][switches - 8])
        else
          vdp.Trace(String("Switches are in DEMO (== 8) mode, all running demos "), switches)
          repeat mode from vdp#TEXT to vdp#GRAPHICS1
                                case mode
                                  vdp#GRAPHICS1:
                                    _showCaptionScreen(String(" GRAPHICS1 demo will start in * seconds "), 5, mode)
                                    vdp.SetMode(vdp#GRAPHICS1)
                                    _spriteDemo("A", 1)
                                    _textDemo
                                  vdp#GRAPHICS2:
                                    _showCaptionScreen(String(" GRAPHICS2 demo will start in * seconds "), 5, mode)
                                    vdp.SetMode(vdp#GRAPHICS2)
                                    _xyAxis
                                    'BUGBUG: this is crashing randomly crashing on F18A (uncomment to see fun scrambled screen...)
                                    _diagonalLines
                                    _circles
                                    _boxyLines
                                    '_spriteDemo("0", 1)
                                  vdp#MULTICOLOR:
                                    _showCaptionScreen(String("MULTICOLOR demo will start in * seconds "), 5, mode)
                                    vdp.SetMode(vdp#MULTICOLOR)
                                    _xyAxis
                                    _diagonalLines
                                    _circles
                                    _boxyLines
                                    '_spriteDemo("a", 1)
                                    _colorfulBlocks(vdp#TRANSPARENT)
                                  vdp#TEXT:
                                    vdp.SetMode(vdp#TEXT)
                                    _showCaptionScreen(String("      TEXT demo will start in * seconds "), 5, mode)
                                    _textDemo
          _showCaptionScreen(String("  VDP will reset and  stop in * seconds "), 9, mode)
          vdp.Reset
    vdp.Stop

PRI _showCaptionScreen(pbCaption, delaySeconds, mode) |pbInverse
  if (delaySeconds > 9)
    delaySeconds := 9
  case vdp.CurrentDisplayMode 'if already in text mode, no need to switch modes
    vdp#GRAPHICS1, vdp#TEXT:
      vdp.Cls
    vdp#GRAPHICS2, vdp#MULTICOLOR:
      vdp.SetMode(vdp#GRAPHICS1)
  'vdp.SetColors(vdp.GoodContrastColors(mode), vdp.GoodContrastColors(mode + 8))
  vdp.SetColors(vdp#BLACK, vdp#WHITE)
  repeat while (delaySeconds)
    byte[pbCaption][30] := byte[@Digits][delaySeconds] 'obviously this will work only for values 0 to 9
    pbInverse := pbCaption
    repeat while byte[pbInverse]
      byte[pbInverse++] |= $80
    vdp.DrawText(pbCaption, 8, 11, 27, 13)
    delaySeconds--
    vdp.WaitASecond

PRI _textDemo |row, col, rnd
  vdp.SetColors(vdp.GoodContrastColors(? rnd), vdp.GoodContrastColors(? rnd))
  'vdp.SetColors(vdp#DARKGREEN, vdp#BLACK)
  repeat 12                     '24
    vdp.WriteText(@SimpleText)
    vdp.WriteText(@SimpleText)
    vdp.WriteText(@SpecialText)
  'vdp.WaitASecond
  repeat 16                     '32
    vdp.WriteText(@CursorUp)
  vdp.Cls
  vdp.SetColors(vdp.GoodContrastColors(? rnd), vdp.GoodContrastColors(? rnd))
  repeat row from 0 to 15
    vdp.FillMem(vdp.NameTable + vdp.TextColumnCount * row, 16, 16 * row, 1)
  'vdp.WaitASecond
  vdp.SetColors(vdp.GoodContrastColors(? rnd), vdp.GoodContrastColors(? rnd))
  repeat row from 0 to vdp.TextRowCount - 1
    byte[@TextBuffer][0] := byte[@Digits][row / 10]
    byte[@TextBuffer][1] := byte[@Digits][row // 10]
    vdp.DrawText(@TextBuffer, vdp.TextColumnCount - 2, row, vdp.TextColumnCount - 1, row)
  'vdp.WaitASecond
  vdp.SetColors(vdp.GoodContrastColors(? rnd), vdp.GoodContrastColors(? rnd))
  repeat col from 0 to vdp.TextColumnCount - 1
    byte[@TextBuffer][0] := byte[@Digits][col / 10]
    byte[@TextBuffer][1] := byte[@Digits][col // 10]
    vdp.DrawText(@TextBuffer, col, vdp.TextRowCount - 2, col, vdp.TextRowCount - 1)
  'vdp.WaitASecond

PRI _spriteDemo(char, waitSecs) |dx, dy, i, rnd
  vdp.SetSpriteMode(vdp#SPRITESIZE_16X16 | vdp#SPRITEMAGNIFICATION_2X)
  repeat i from 0 to 7
    vdp.GenerateSpritePatternFromChar(@SpriteTestPattern16, char + i, 32)
    vdp.SetSpritePattern(i * 4, @SpriteTestPattern16, 32)
    vdp.SetSprite(i, vdp#SPRITEMASK_SETPATTERN | vdp#SPRITEMASK_SETCOLOR | vdp#SPRITEMASK_SETX | vdp#SPRITEMASK_SETY, i * 4, vdp.SpriteHPixelCount / 2 - 16, vdp.SpriteVPixelCount / 2 - 16, 15 - i)
  'give speed vectors to sprites and let send them off autonomously
  vdp.SetSprite(0, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0,  1,  0, 0)
  vdp.SetSprite(1, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0,  1, -1, 0)
  vdp.SetSprite(2, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0,  0, -1, 0)
  vdp.SetSprite(3, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0, -1, -1, 0)
  vdp.SetSprite(4, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0, -1,  0, 0)
  vdp.SetSprite(5, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0, -1,  1, 0)
  vdp.SetSprite(6, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0,  0,  1, 0)
  vdp.SetSprite(7, vdp#SPRITEMASK_VX | vdp#SPRITEMASK_VY, 0,  1,  1, 0)
  repeat waitSecs
    vdp.WaitASecond

PRI _xyAxis
  vdp.DrawLine(vdp.GraphicsHPixelCount >> 1, 0, vdp.GraphicsHPixelCount >> 1, vdp.GraphicsVPixelCount - 1, 1)
  vdp.DrawLine(0, vdp.GraphicsVPixelCount >> 1, vdp.GraphicsHPixelCount - 1, vdp.GraphicsVPixelCount >> 1, 1)

PRI _tickLines(color) |x, y
  vdp.SetColors(vdp#BLACK, color)
  'vdp.SetColors(byte[@ColorPalette8][colorIndex], byte[@ColorPalette8i][colorIndex])
  'vdp.SetMode(vdp#GRAPHICS2)
  repeat x from 0 to 255 step 8
    vdp.DrawLine(x, 0, x, 191, 1)
    'vdp.WaitASecond
  'vdp.SetColors(color, vdp#BLACK)
  repeat y from 0 to 191 step 8
    vdp.DrawLine(0, y, 255, y, 1)
    'vdp.WaitASecond

PRI _diagonalLines |xl, yt, xr, yb
  xl := 0
  yt := 0
  xr := vdp.GraphicsHPixelCount - 1
  yb := vdp.GraphicsVPixelCount - 1
  vdp.DrawLine(xl, yt, xr, yb, 1)
  vdp.DrawLine(xr, yt, xl, yb, 1)
  vdp.WaitASecond

PRI _colorfulBlocks(color) |x, y, c
  c := 0
  repeat x from 0 to vdp.GraphicsHPixelCount - 1
    repeat y from 0 to vdp.GraphicsVPixelCount - 1
      if (color == vdp#TRANSPARENT)
        vdp.DrawPixel(x, y, x ^ y)
      else
        vdp.DrawPixel(x, y, ColorPalette8[x & 7])
        c++
  vdp.WaitASecond

PRI _boxyLines |xl, yt, xr, yb, color
  xl := 0
  yt := 0
  xr := vdp.GraphicsHPixelCount - 1
  yb := vdp.GraphicsVPixelCount - 1
  repeat color from vdp#WHITE to vdp#TRANSPARENT
    vdp.DrawLine(xl, yt, xr, yt, color)
    vdp.DrawLine(xr, yt, xr, yb, color)
    vdp.DrawLine(xr, yb, xl, yb, color)
    vdp.DrawLine(xl, yb, xl, yt, color)
    xl++
    yt++
    xr--
    yb--
  vdp.WaitASecond

PRI _circles |radius
  repeat radius from 0 to (vdp.GraphicsHPixelCount / 2) step 8
    vdp.DrawCircle(vdp.GraphicsHPixelCount / 2, vdp.GraphicsVPixelCount / 2, radius, 1)
    vdp.DrawCircle(0, 0, radius, 1)
    vdp.DrawCircle(0, vdp.GraphicsVPixelCount - 1, radius, 1)
    vdp.DrawCircle(vdp.GraphicsHPixelCount - 1 , vdp.GraphicsVPixelCount - 1, radius, 1)
    vdp.DrawCircle(vdp.GraphicsHPixelCount - 1, 0, radius, 1)
  vdp.WaitASecond


DAT
ColorPalette8    BYTE vdp#BLACK, vdp#DARKBLUE,  vdp#DARKGREEN, vdp#CYAN,    vdp#DARKRED, vdp#DARKYELLOW, vdp#MAGENTA,   vdp#WHITE
ColorPalette8i   BYTE vdp#WHITE, vdp#DARKYELLOW,vdp#MAGENTA,   vdp#DARKRED, vdp#CYAN,    vdp#DARKBLUE,   vdp#DARKGREEN, vdp#BLACK
'ColorPalette8i   BYTE vdp#BLACK, vdp#BLACK,     vdp#BLACK,     vdp#BLACK,   vdp#WHITE,  vdp#DARKBLUE,    vdp#DARKGREEN,     vdp#DARKRED
'ColorPalette8    BYTE vdp#WHITE, vdp#DARKBLUE,  vdp#DARKGREEN, vdp#DARKRED, vdp#BLACK,  vdp#BLACK,       vdp#BLACK,         vdp#BLACK
CommandBuffer    LONG 0[8]
TextBuffer       BYTE 0[8]
Digits           BYTE "0123456789"
CursorUp         BYTE vdp#MU, 0
SimpleText       BYTE "This text wraps and scrolls freely. ", 0
SpecialText      BYTE "This text has ", vdp#TB, "TAB and ", vdp#TB, "TAB as well as CR+LF", vdp#CR, vdp#LF, 0

SpriteTestPattern16 BYTE $FF, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $FF, $FF, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $FF
SpriteTestPattern08 BYTE $FF, $81, $81, $81, $81, $81, $81, $FF