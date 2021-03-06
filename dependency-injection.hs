-- {-# ghc_options -fdefer-type-errors #-}
{-# language ViewPatterns #-}
{-# language PatternSynonyms #-}
{-# language ScopedTypeVariables #-}
{-# language FlexibleInstances #-}
import Data.Dynamic
import Data.Maybe
import qualified Data.Map as Map

pattern Dyn x <- (fromDynamic -> Just x)
  where Dyn x =  toDyn x


class A a where
    applyMany :: a -> [Dynamic] -> Dynamic

instance A Dynamic where
    applyMany x [] = x
    applyMany x a = error $ show a

instance A (Integer, String) where
    applyMany x [] = Dyn x



instance A a => A (Integer -> a) where
    applyMany f (x: xs) = applyMany (f $ fromJust $ fromDynamic x) xs

instance A a => A (String -> a) where
    applyMany f (x: xs) = applyMany (f $ fromJust $ fromDynamic x) xs

instance A a => A (Dynamic -> a) where
    applyMany f (x: xs) = applyMany (f x) xs


f i s = (i, s) :: (Integer, String)

res :: Maybe (Integer, String)
res = fromDynamic $ applyMany f [Dyn (1 :: Integer), Dyn "asdf"]


-- args = [toDyn 1, toDyn "a"]
-- -- f i s = (i:: Integer,s :: String)

-- res2 :: Maybe (Integer, String)
-- res2 = fromDynamic $ applyMany f args

($>) = flip ($)
(.>) = flip (.)

type Defs = Map.Map String ([String], Dynamic)

defs :: Defs
defs =
  Map.fromList
    [ ("a", (["b"], Dyn (\(Dyn b) -> Dyn ((b :: Integer) + 1))))
    , ("b", ([], Dyn (3 :: Integer)))
    ]

-- exec = exec' .> fromDynamic

exec' :: Defs -> String -> Dynamic
exec' defs k = applyMany dynF (map (exec' defs) depNames)
  where
  (depNames, dynF) = defs Map.! k

main = do
  -- print $ (exec defs "b" :: Maybe Integer)
  print $ (exec' defs "a" $> fromDynamic :: Maybe Integer)
