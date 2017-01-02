{writeTextDir, dpi ? 96}:

writeTextDir "setdpi" ''
Xft.dpi: ${toString dpi}
*dpi: ${toString dpi}
''
