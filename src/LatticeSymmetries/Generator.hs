-- |
-- Module      : LatticeSymmetries.Generator
-- Description : Bosonic and fermionic algebra generators
-- Copyright   : (c) Tom Westerhout, 2022
-- Stability   : experimental
module LatticeSymmetries.Generator
  ( SpinIndex (..),
    SpinGeneratorType (..),
    FermionGeneratorType (..),
    Generator (..),
    HasSiteIndex (..),
    -- HasMatrixRepresentation (..),
  )
where

import Data.Bits
import qualified Data.Text as Text
import qualified Data.Vector.Generic as G
import LatticeSymmetries.BitString
import LatticeSymmetries.Dense
import LatticeSymmetries.NonbranchingTerm
import Prettyprinter (Doc, Pretty (..))
import qualified Prettyprinter as Pretty
import Prelude hiding (Product, Sum, identity, toList)

-- | Index for the spin sector.
--
-- __Note the ordering__: spin up appears before spin down.
data SpinIndex
  = -- | โ
    SpinUp
  | -- | โ
    SpinDown
  deriving stock (Show, Eq, Ord)

instance Pretty SpinIndex where
  pretty SpinUp = "โ"
  pretty SpinDown = "โ"

-- | Generators for the algebra of spin-1/2 particles.
data SpinGeneratorType
  = -- | Identity \( 1 = \begin{pmatrix} 1 & 0\\ 0 & 1\end{pmatrix} \)
    SpinIdentity
  | -- | Pauli matrix \( \sigma^z = \begin{pmatrix} 1 & 0\\ 0 & -1\end{pmatrix} \)
    SpinZ
  | -- | \( \sigma^{+} = \sigma^x + ๐\sigma^y = \begin{pmatrix} 0 & 1\\ 0 & 0 \end{pmatrix} \)
    SpinPlus
  | -- | \( \sigma^{-} = \sigma^x - ๐\sigma^y = \begin{pmatrix} 0 & 0\\ 1 & 0 \end{pmatrix} \)
    SpinMinus
  deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)

instance Pretty SpinGeneratorType where
  pretty x = case x of
    SpinIdentity -> "1"
    SpinZ -> "ฯแถป"
    SpinPlus -> "ฯโบ"
    SpinMinus -> "ฯโป"

-- | Generators for the fermionic algebra.
data FermionGeneratorType
  = -- | Identity ๐
    FermionIdentity
  | -- | Number counting operator
    FermionCount
  | -- | Creation operator \( c^\dagger \)
    FermionCreate
  | -- | Annihilation operator \( c \)
    FermionAnnihilate
  deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)

instance Pretty FermionGeneratorType where
  pretty x = case x of
    FermionIdentity -> "1"
    FermionCount -> "n"
    FermionCreate -> "cโ?"
    FermionAnnihilate -> "c"

-- | A generator (either spin or fermionic) which is not associated with an index @i@. The index
-- could be the site index or a tuple of spin and site indices.
data Generator i g = Generator !i !g
  deriving stock (Eq, Ord, Show, Generic)

class HasSiteIndex i where
  getSiteIndex :: i -> Int
  mapSiteIndex :: (Int -> Int) -> i -> i

instance HasSiteIndex Int where
  getSiteIndex = id
  mapSiteIndex f i = f i

instance HasSiteIndex (SpinIndex, Int) where
  getSiteIndex (_, i) = i
  mapSiteIndex f (ฯ, i) = (ฯ, f i)

toSubscript :: HasCallStack => Int -> Text
toSubscript n = Text.map h (show n)
  where
    h '0' = 'โ'
    h '1' = 'โ'
    h '2' = 'โ'
    h '3' = 'โ'
    h '4' = 'โ'
    h '5' = 'โ'
    h '6' = 'โ'
    h '7' = 'โ'
    h '8' = 'โ'
    h '9' = 'โ'
    h _ = error "invalid character"

instance Pretty g => Pretty (Generator Int g) where
  pretty (Generator i g) = pretty g <> pretty (toSubscript i)

instance Pretty g => Pretty (Generator (SpinIndex, Int) g) where
  pretty (Generator (ฯ, i) g) = pretty g <> pretty ฯ <> pretty (toSubscript i)

instance HasNonbranchingRepresentation (Generator Int SpinGeneratorType) where
  nonbranchingRepresentation (Generator _ SpinIdentity) =
    NonbranchingTerm 1 zeroBits zeroBits zeroBits zeroBits zeroBits
  nonbranchingRepresentation (Generator i SpinZ) =
    NonbranchingTerm (-1) zeroBits zeroBits zeroBits zeroBits (bit i)
  nonbranchingRepresentation (Generator i SpinPlus) =
    NonbranchingTerm 1 (bit i) (bit i) zeroBits (bit i) zeroBits
  nonbranchingRepresentation (Generator i SpinMinus) =
    NonbranchingTerm 1 (bit i) zeroBits (bit i) (bit i) zeroBits

instance HasNonbranchingRepresentation (Generator Int FermionGeneratorType) where
  nonbranchingRepresentation (Generator _ FermionIdentity) =
    NonbranchingTerm 1 zeroBits zeroBits zeroBits zeroBits zeroBits
  nonbranchingRepresentation (Generator i FermionCount) =
    NonbranchingTerm 1 (bit i) (bit i) (bit i) zeroBits zeroBits
  nonbranchingRepresentation (Generator i FermionCreate) =
    NonbranchingTerm 1 (bit i) (bit i) zeroBits (bit i) (BitString (bit i - 1))
  nonbranchingRepresentation (Generator i FermionAnnihilate) =
    NonbranchingTerm 1 (bit i) zeroBits (bit i) (bit i) (BitString (bit i - 1))
