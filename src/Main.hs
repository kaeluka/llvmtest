module Main where

import LLVM.General.AST
import LLVM.General.AST.Attribute
import LLVM.General.AST.Linkage
import LLVM.General.AST.Visibility
import LLVM.General.AST.CallingConvention
import LLVM.General.PrettyPrint
import LLVM.General.Context
import LLVM.General.Module
import Control.Monad.Trans.Except
import LLVM.General.ExecutionEngine
import Foreign.Ptr
import Foreign.C.Types
import System.Directory

foreign import ccall "dynamic"
  mkFun :: FunPtr (CInt -> CInt -> IO CInt) -> (CInt -> CInt -> IO CInt)

main :: IO ()
main = do putStrLn "hello"
          test
          test'
          return ()

-- LOAD OBJ FILE AND RUN IT -----------------------------------------
test' =
  do putStrLn "== test' =========="
     withContext $ \ctx ->
      withJIT ctx 2 $ \jit -> do
       modethr <-
        runExceptT $
        withModuleFromBitcode
          ctx
          (File "./src/runtime.bc")
          (\modul -> do
          runSumFunc ctx jit modul)
       either
        (\msg -> putStrLn $ "ERR:"++msg)
        (const $ return ())
        modethr

runSumFunc ctx jit compiledModul =
  do withModuleInEngine jit compiledModul $ \exemdl -> do
       mf <- getFunction exemdl (Name "sum")
       maybe (putStrLn "GOT NO FUNCTION")
             (\ f -> do let f' = mkFun
                                  (castFunPtr f ::
                                    FunPtr (CInt -> CInt -> IO CInt))
                        res <- f' (CInt 12) (CInt 13)
                        print res)
             mf

-- COMPILE AST AND RUN IT -------------------------------------------

test =
  withContext (\ctx ->
   withJIT ctx 2 (\jit -> do
    runExceptT (
     withModuleFromAST ctx sumModule (\ compiled -> do
      llvmir <- moduleLLVMAssembly compiled
      putStrLn "=============="
      putStrLn llvmir
      withModuleInEngine jit compiled (\exemdl -> do
       mf <- getFunction exemdl (Name "sum")
       case mf of
         Just f ->
          do putStrLn "got one"
             let f' = mkFun (castFunPtr f :: FunPtr (CInt -> CInt -> IO CInt))
             putStrLn "cast"
             res <- f' (CInt 12) (CInt 13)
             print res
         Nothing -> putStrLn "got NO FUNCTION"))) >> return ()))

sumModule = Module { moduleName = "sumModule"
                   , moduleDataLayout = Nothing
                   , moduleTargetTriple = Nothing
                   , moduleDefinitions = [GlobalDefinition sumFunc]}

sumFunc = Function
            Private
            Default
            C
            [NoCapture]
            (IntegerType 64)
            (Name "sum")
            ([Parameter (IntegerType 64) (Name "x") []
             ,Parameter (IntegerType 64) (Name "y") []],False)
            []
            Nothing
            0
            Nothing
            [basicBlock]
 where
   basicBlock = BasicBlock
                  (Name "sum_entry")
                  [Name "addition" := Add { nuw=False
                                          , nsw=False
                                          , operand0=LocalReference (IntegerType 64) (Name "x")
                                          , operand1=LocalReference (IntegerType 64) (Name "y")
                                          , metadata = [] } ]
                  (Do $ Ret (Just (LocalReference (IntegerType 64) (Name "addition"))) [])
