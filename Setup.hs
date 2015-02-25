import Distribution.Simple
import Distribution.PackageDescription (emptyHookedBuildInfo)
import System.Process

main :: IO ()
main = defaultMainWithHooks $
        simpleUserHooks { preBuild = preBuild_handler }

preBuild_handler args build_flags =
    do putStrLn "prebuild"
       runCommand ("cd src; clang -emit-llvm runtime.c -c -o runtime.bc")
       return emptyHookedBuildInfo
