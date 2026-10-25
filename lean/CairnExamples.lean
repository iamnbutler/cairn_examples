import Counter
import Counter.Proofs
import Counter.Tests
import Basics
import Basics.Proofs
import Basics.Tests
import Basics.Mutant
import Todo
import Todo.Proofs
import Todo.Tests
import Clock
import Clock.Proofs
import Clock.Tests
import Tray
import Tray.Proofs
import Gallery
import Gallery.Proofs
import Gallery.Tests

/-! Every app and its proofs: what the ledger, the axiom audit and the kernel replay read. Not
linked into any host binary (each app has its own library, see lakefile.lean). -/
