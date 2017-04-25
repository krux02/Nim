discard """
  output: ""
"""

type
  # bust as soon as I put the generics in the type, constants become 0, when assigning them to variables
  Vec*[N : static[int]] = object
    arr*: array[N, int32]

  Mat*[M,N: static[int]] = object
    arr*: array[M, Vec[N]]

proc vec2*(x,y:int32) : Vec[2] =
  result.arr = [x,y]

proc mat2*(a,b: Vec[2]): Mat[2,2] =
  result.arr = [a,b]

const a = vec2(1,2) # this one works
echo @(a.arr)
let x = a
echo @(x.arr)

const b = mat2(vec2(1, 2), vec2( 3, 4)) # this one doesn't
echo @(b.arr[0].arr), @(b.arr[1].arr)
let y = b # z is now all 0
echo @(y.arr[0].arr), @(y.arr[1].arr), " <--- Here is the problem"

# non generic versions, these do work
type
  # these types are just here to show that without generics the constants do work
  Vec2* = object
    arr*: array[2, int32]

  Mat2* = object
    arr*: array[2, Vec2]


proc vec2_b*(x,y:int32) : Vec2 =
  result.arr = [x,y]

proc mat2_b*(a,b: Vec2): Mat2 =
  result.arr = [a,b]

const c = mat2_b(vec2_b(1, 2), vec2_b( 3, 4)) # this one does work again
echo @(c.arr[0].arr), @(c.arr[1].arr)
let z = c # z is now not all 0
echo @(z.arr[0].arr), @(z.arr[1].arr)
