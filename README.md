# llvmtest
Testing the `llvm-general` lib from hackage.

The program will:
 - compile a `sum` function from LLVM-IR, expressed using the data
   types from `llvm-general-pure` and run it with `12` and `13` as
   input, printing its output.
  
 - load a bitcode version of a C file (see `runtime.c`), that
   contains a similar `sum` function -- that also does a printf --
   and run that with the same arguments.

## Run
Try:

 - first, install `llvm-config`, version 3.4 (exact)
 - then:
 
   ```
   cabal sandbox init
   cabal install
   cabal run
   ```

During `cabal install`, you may see the installation of `llvm-general` failing. 
That's most likely because some C/C++ dependencies are missing (Cabal can't track 
those, AFAIK). So you'll need to fix those in case this happens.
