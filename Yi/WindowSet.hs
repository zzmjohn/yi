--
-- Copyright (c) 2007 Jean-Philippe Bernardy
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License as
-- published by the Free Software Foundation; either version 2 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
-- 02111-1307, USA.
--

module Yi.WindowSet where
-- FIXME: export abstractly

import Prelude hiding (elem, error)

import Yi.Debug
import Control.Monad.Trans
import Data.List as List (nub, delete)
import Data.Foldable
import Data.Traversable
import Data.Monoid
import Control.Applicative

data WindowSet a = WindowSet { before::[a], current::a, after :: [a] }
    deriving (Show)

instance Foldable WindowSet where
    foldMap f (WindowSet b c a) = getDual (foldMap (Dual . f) b) `mappend` (f c) `mappend` foldMap f a

instance Functor WindowSet where
    fmap f (WindowSet b c a) = WindowSet (fmap f b) (f c) (fmap f a)

instance Traversable WindowSet where
    traverse f (WindowSet b c a) = WindowSet <$> traverse f b <*> f c <*> traverse f a

new :: a -> WindowSet a
new w = WindowSet [] w []

-- | Add a window, focus it.
add :: Eq a => a -> WindowSet a -> WindowSet a
add w (WindowSet b c a) = WindowSet b w (c:a)

next :: WindowSet a -> a
next = current . forward

delete :: WindowSet a -> WindowSet a
delete (WindowSet [] c []) = WindowSet [] c [] -- never delete the last window
delete (WindowSet b _ (a:as)) = WindowSet b a as
delete (WindowSet (b:bs) _ []) = WindowSet bs b []

deleteOthers (WindowSet b c a) = WindowSet [] c []

forward :: WindowSet a -> WindowSet a
forward (WindowSet [] c []) = WindowSet [] c []
forward (WindowSet b c (a:as)) = WindowSet (c:b) a as
forward (WindowSet b c []) = WindowSet [] (last b) ((reverse (init b)) ++ [c])

backward :: WindowSet a -> WindowSet a
backward (WindowSet [] c []) = WindowSet [] c []
backward (WindowSet (b:bs) c a) = WindowSet bs b (c:a)
backward (WindowSet [] c a) = WindowSet (c:reverse (init a)) (last a) []

setFocus :: Eq a => a -> WindowSet a -> WindowSet a
setFocus w ws@(WindowSet b c a) 
    | c == w = ws
    | c `elem` a = setFocus w (forward ws)
    | c `elem` b = setFocus w (backward ws)
    | otherwise = error "window lost" 

modifyCurrent :: (a -> a) -> WindowSet a -> WindowSet a
modifyCurrent f (WindowSet b c a) = WindowSet b (f c) a

debug msg (WindowSet b c a) = logPutStrLn $ msg ++ ": " ++ show b ++ show c ++ show a


