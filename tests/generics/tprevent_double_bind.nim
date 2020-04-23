discard """
  errormsg: "type mismatch: got <TT[seq[string]], proc (v: int){.gcsafe, locks: 0.}>"
  line: 20
"""

# bug #6732
import typetraits

type
  TT[T] = ref object of RootObj
    val: T
  CB[T] = proc (v: T)

proc testGeneric[T](val: TT[T], cb: CB[T]) =
  echo typeof(val).name
  echo $val.val

var tt = new(TT[seq[string]])
echo typeof(tt).name
tt.testGeneric( proc (v: int) =
    echo $v )
