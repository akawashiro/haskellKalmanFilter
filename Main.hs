import Numeric.LinearAlgebra
import Numeric.LinearAlgebra.HMatrix
import Prelude hiding (pi)
import Data.Random
import Control.Monad
import Text.Printf

type M = Matrix Double

initX :: M
initX = (2><1) [0,0]

initP :: M
initP = (2><2) [0,0,0,0]

deltaT :: Double
deltaT = 0.01

cF = (2><2) [1,deltaT,0,1]

cG = (2><1) [deltaT^2/2,deltaT]

cH :: M
cH = (1><2) [1.0,0.0]

sigmaZ :: Double
sigmaZ = 0

sigmaA :: Double
sigmaA = 100

cR = (1><1) [sigmaZ]

cQ = (1><1) [sigmaA]

gaussianNoises :: Double -> Double -> Int -> IO [Double]
gaussianNoises mu sigma n = replicateM n . sample $ Normal mu sigma

numTest = 100

realX :: IO [M]
realX = do
  a <- gaussianNoises 0 sigmaA (numTest-1)
  return $ realX' initX a

realX' :: M -> [Double] -> [M]
realX' x [] = [x]
realX' x (n:ns) = x : realX' (cF<>x+cG<> (1><1) [n]) ns

dataset :: IO [(M,M)]
dataset = do
  xs <- realX
  ns <- gaussianNoises 0 sigmaZ numTest
  return (zip xs (map (\(x,n) -> cH<>x+(1><1) [n]) (zip xs ns)))

kalmanFilter :: [(M,M)] -> [(M,M,M)]
kalmanFilter = kalmanFilter' initX initP
kalmanFilter' x p [] = []
kalmanFilter' x p ((a,z):ds) = (x,a,z) : kalmanFilter' newX newP ds
  where preX = cF<>x
        preP = cF<>p<>tr cF+cG<>cQ<>tr cG
        e = z - cH<>preX
        s = cR + cH<>preP<>tr cH
        k = preP<>tr cH<>inv s
        newX = preX + k<>e
        newP = (i-k<>cH)<>preP
        i = (2><2) [1,0,0,1]

showResult :: [(M,M,M)] -> String
showResult = concatMap showResult' 
showResult' (x,a,z) = printf "pred pos=%.2f pred vel=%.2f,real pos=%.2f real vel=%.2f,observed pos=%.2f\n" (x!0!0) (x!1!0) (a!0!0) (a!1!0) (z!0!0)

main = do
  ds <- dataset
  putStr $ showResult $ kalmanFilter ds

