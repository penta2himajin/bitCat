import strformat, gnuplot


proc show*[X, Y](x_label: string = "", y_label:string = "", window: int, args: varargs[(seq[X], seq[Y], string)]) =
  cmd &"set term wxt {$window}"
  if x_label != "": cmd &"set xlabel '{x_label}' tc rgb \"white\""
  if x_label != "": cmd &"set ylabel '{y_label}' tc rgb \"white\""
  cmd "set object 1 rect behind from screen 0,0 to screen 1,1 fc rgb \"#333631\" fillstyle solid 1.0"
  cmd "set border lc rgb \"white\""
  cmd "set key tc rgb \"white\""
  cmd "set grid"

  for (x, y, title) in args:
    plot x, y, title
