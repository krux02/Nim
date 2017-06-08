proc tupleExtract(): bool =
  let (_, _, a) = (1, 2, 3)
  let (_, _, b) = (1, 2, 3)
  result = (a == b)

assert tupleExtract() 

static:
  assert tupleExtract()


