{-# LANGUAGE RankNTypes #-}

module ForeignLibrary () where

import Control.Exception.Safe (handleAny, handleAnyDeep)
import qualified Data.Aeson
-- import Data.List.Split (chunksOf)
-- import qualified Data.Text as Text
import qualified Data.Vector.Generic as G
import Foreign.C.String (CString)
import Foreign.C.Types (CBool (..), CInt (..), CPtrdiff (..))
-- import Foreign.ForeignPtr
import Foreign.Marshal.Alloc (alloca, free, malloc)
import Foreign.Marshal.Array (newArray)
import Foreign.Marshal.Utils (fromBool)
import Foreign.Ptr (FunPtr, Ptr, nullPtr)
-- import Foreign.StablePtr
import Foreign.Storable (Storable (..))
import GHC.Exts (IsList (..))
-- import LatticeSymmetries
import LatticeSymmetries.Algebra
import LatticeSymmetries.Basis
import LatticeSymmetries.Benes
import LatticeSymmetries.BitString
import LatticeSymmetries.ComplexRational (ComplexRational, fromComplexDouble)
import LatticeSymmetries.Expr
import LatticeSymmetries.FFI
import LatticeSymmetries.Generator
import LatticeSymmetries.Group
import LatticeSymmetries.Operator
import LatticeSymmetries.Parser
import LatticeSymmetries.Utils
-- import Prettyprinter (Pretty (..))
-- import qualified Prettyprinter as Pretty
-- import Prettyprinter.Render.Text (renderStrict)
import Type.Reflection
import Prelude hiding (state, toList)

{-
foreign export ccall "ls_hs_hdf5_create_dataset_u64"
  ls_hs_hdf5_create_dataset_u64 :: CString -> CString -> CUInt -> Ptr Word64 -> IO ()

foreign export ccall "ls_hs_hdf5_create_dataset_f32"
  ls_hs_hdf5_create_dataset_f32 :: CString -> CString -> CUInt -> Ptr Word64 -> IO ()

foreign export ccall "ls_hs_hdf5_create_dataset_f64"
  ls_hs_hdf5_create_dataset_f64 :: CString -> CString -> CUInt -> Ptr Word64 -> IO ()

foreign export ccall "ls_hs_hdf5_create_dataset_c64"
  ls_hs_hdf5_create_dataset_c64 :: CString -> CString -> CUInt -> Ptr Word64 -> IO ()

foreign export ccall "ls_hs_hdf5_create_dataset_c128"
  ls_hs_hdf5_create_dataset_c128 :: CString -> CString -> CUInt -> Ptr Word64 -> IO ()

foreign export ccall "ls_hs_hdf5_write_chunk_u64"
  ls_hs_hdf5_write_chunk_u64 :: CString -> CString -> CUInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

foreign export ccall "ls_hs_hdf5_write_chunk_f64"
  ls_hs_hdf5_write_chunk_f64 :: CString -> CString -> CUInt -> Ptr Word64 -> Ptr Word64 -> Ptr Double -> IO ()

foreign export ccall "ls_hs_hdf5_read_chunk_u64"
  ls_hs_hdf5_read_chunk_u64 :: CString -> CString -> CUInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

foreign export ccall "ls_hs_hdf5_read_chunk_f64"
  ls_hs_hdf5_read_chunk_f64 :: CString -> CString -> CUInt -> Ptr Word64 -> Ptr Word64 -> Ptr Double -> IO ()

foreign export ccall "ls_hs_hdf5_get_dataset_rank"
  ls_hs_hdf5_get_dataset_rank :: CString -> CString -> IO CUInt

foreign export ccall "ls_hs_hdf5_get_dataset_shape"
  ls_hs_hdf5_get_dataset_shape :: CString -> CString -> Ptr Word64 -> IO ()
-}

-- foreign export ccall "ls_hs_basis_and_hamiltonian_from_yaml"
--   ls_hs_basis_and_hamiltonian_from_yaml :: CString -> Ptr Types.SpinBasisWrapper -> Ptr Types.OperatorWrapper -> IO ()

-- foreign export ccall "ls_hs_destroy_spin_basis"
--   ls_hs_destroy_spin_basis :: Ptr Types.SpinBasisWrapper -> IO ()

-- foreign export ccall "ls_hs_destroy_operator"
--   ls_hs_destroy_operator :: Ptr Types.OperatorWrapper -> IO ()

-- foreign export ccall "ls_hs_create_basis"
--   ls_hs_create_basis :: Cparticle_type -> CInt -> CInt -> CInt -> IO (Ptr Cbasis)

-- ls_hs_permutation_group * ls_hs_symmetries_from_json (const char * json_string)
-- void ls_hs_destroy_symmetries (ls_hs_permutation_group *)

-- {{{ Symmetry

foreign export ccall "ls_hs_symmetry_from_json"
  ls_hs_symmetry_from_json :: CString -> IO (Ptr Csymmetry)

ls_hs_symmetry_from_json cStr =
  handleAny (propagateErrorToC nullPtr) $
    newCsymmetry =<< decodeCString cStr

foreign export ccall "ls_hs_destroy_symmetry"
  ls_hs_destroy_symmetry :: Ptr Csymmetry -> IO ()

ls_hs_destroy_symmetry = destroyCsymmetry

foreign export ccall "ls_hs_symmetry_sector"
  ls_hs_symmetry_sector :: Ptr Csymmetry -> IO CInt

ls_hs_symmetry_sector = flip withCsymmetry (pure . fromIntegral . symmetrySector)

foreign export ccall "ls_hs_symmetry_phase"
  ls_hs_symmetry_phase :: Ptr Csymmetry -> IO Double

ls_hs_symmetry_phase = flip withCsymmetry (pure . realToFrac . symmetryPhase)

foreign export ccall "ls_hs_symmetry_length"
  ls_hs_symmetry_length :: Ptr Csymmetry -> IO CInt

ls_hs_symmetry_length =
  flip withCsymmetry $
    pure . fromIntegral . permutationLength . symmetryPermutation

foreign export ccall "ls_hs_symmetry_permutation"
  ls_hs_symmetry_permutation :: Ptr Csymmetry -> IO (Ptr CInt)

ls_hs_symmetry_permutation =
  flip withCsymmetry $
    newArray . fmap fromIntegral . toList . symmetryPermutation

foreign export ccall "ls_hs_destroy_permutation"
  ls_hs_destroy_permutation :: Ptr CInt -> IO ()

ls_hs_destroy_permutation = free

-- }}}

-- {{{ Symmetries

foreign export ccall "ls_hs_symmetries_from_json"
  ls_hs_symmetries_from_json :: CString -> IO (Ptr Csymmetries)

ls_hs_symmetries_from_json cStr =
  handleAny (propagateErrorToC nullPtr) $
    newCsymmetries =<< decodeCString cStr

foreign export ccall "ls_hs_destroy_symmetries"
  ls_hs_destroy_symmetries :: Ptr Csymmetries -> IO ()

ls_hs_destroy_symmetries = destroyCsymmetries

-- }}}

-- {{{ Basis

foreign export ccall "ls_hs_clone_basis"
  ls_hs_clone_basis :: Ptr Cbasis -> IO (Ptr Cbasis)

ls_hs_clone_basis = cloneCbasis

foreign export ccall "ls_hs_destroy_basis"
  destroyCbasis :: Ptr Cbasis -> IO ()

foreign export ccall "ls_hs_basis_to_json"
  ls_hs_basis_to_json :: Ptr Cbasis -> IO CString

ls_hs_basis_to_json cBasis = do
  logDebug' $ "ls_hs_basis_to_json " <> show cBasis
  withCbasis cBasis $ \basis -> do
    newCString $ toStrict (Data.Aeson.encode basis)

foreign export ccall "ls_hs_basis_from_json"
  ls_hs_basis_from_json :: CString -> IO (Ptr Cbasis)

ls_hs_basis_from_json cStr = handleAny (propagateErrorToC nullPtr) $ do
  logDebug' $ "ls_hs_basis_from_json ..."
  foldSomeBasis newCbasis =<< decodeCString cStr

foreign export ccall "ls_hs_destroy_string"
  ls_hs_destroy_string :: CString -> IO ()

ls_hs_destroy_string = free

foreign export ccall "ls_hs_min_state_estimate"
  ls_hs_min_state_estimate :: Ptr Cbasis -> IO Word64

ls_hs_min_state_estimate p =
  withCbasis p $ \someBasis ->
    withSomeBasis someBasis $ \basis ->
      let (BasisState n (BitString x)) = minStateEstimate basis
       in if n > 64
            then throwC 0 "minimal state is not representable as a 64-bit integer"
            else pure $ fromIntegral x

foreign export ccall "ls_hs_max_state_estimate"
  ls_hs_max_state_estimate :: Ptr Cbasis -> IO Word64

ls_hs_max_state_estimate p =
  withCbasis p $ \someBasis ->
    withSomeBasis someBasis $ \basis ->
      let (BasisState n (BitString x)) = maxStateEstimate basis
       in if n > 64
            then throwC (-1) "maximal state is not representable as a 64-bit integer"
            else pure $ fromIntegral x

foreign export ccall "ls_hs_basis_has_fixed_hamming_weight"
  ls_hs_basis_has_fixed_hamming_weight :: Ptr Cbasis -> IO CBool

ls_hs_basis_has_fixed_hamming_weight basis =
  fromBool <$> withCbasis basis (foldSomeBasis (pure . hasFixedHammingWeight))

foreign export ccall "ls_hs_basis_has_spin_inversion_symmetry"
  ls_hs_basis_has_spin_inversion_symmetry :: Ptr Cbasis -> IO CBool

ls_hs_basis_has_spin_inversion_symmetry basis =
  fromBool <$> withCbasis basis (foldSomeBasis (pure . hasSpinInversionSymmetry))

foreign export ccall "ls_hs_basis_has_permutation_symmetries"
  ls_hs_basis_has_permutation_symmetries :: Ptr Cbasis -> IO CBool

ls_hs_basis_has_permutation_symmetries basis =
  fromBool <$> withCbasis basis (foldSomeBasis (pure . hasPermutationSymmetries))

foreign export ccall "ls_hs_basis_requires_projection"
  ls_hs_basis_requires_projection :: Ptr Cbasis -> IO CBool

ls_hs_basis_requires_projection basis =
  fromBool <$> withCbasis basis (foldSomeBasis (pure . requiresProjection))

foreign import ccall safe "ls_hs_build_representatives"
  ls_hs_build_representatives :: Ptr Cbasis -> Word64 -> Word64 -> IO ()

foreign export ccall "ls_hs_basis_build"
  ls_hs_basis_build :: Ptr Cbasis -> IO ()

ls_hs_basis_build p = do
  withCbasis p $ \someBasis ->
    withSomeBasis someBasis $ \basis ->
      if getNumberBits basis <= 64
        then do
          let (BasisState _ (BitString lower)) = minStateEstimate basis
              (BasisState _ (BitString upper)) = maxStateEstimate basis
          ls_hs_build_representatives p (fromIntegral lower) (fromIntegral upper)
        else throwC () "too many bits"

foreign export ccall "ls_hs_basis_is_built"
  ls_hs_basis_is_built :: Ptr Cbasis -> IO CBool

ls_hs_basis_is_built =
  pure . fromBool . (/= nullPtr) . external_array_elts . cbasis_representatives <=< peek

foreign export ccall "ls_hs_basis_number_words"
  ls_hs_basis_number_words :: Ptr Cbasis -> IO CInt

ls_hs_basis_number_words basisPtr =
  fromIntegral <$> withCbasis basisPtr (foldSomeBasis (pure . getNumberWords))

foreign export ccall "ls_hs_basis_state_to_string"
  ls_hs_basis_state_to_string :: Ptr Cbasis -> Ptr Word64 -> IO CString

ls_hs_basis_state_to_string basisPtr statePtr =
  withCbasis basisPtr $ \someBasis ->
    withSomeBasis someBasis $ \(basis :: Basis t) -> do
      let numberBits = getNumberBits basis
          numberWords = getNumberWords basis
      state <- BasisState @t numberBits <$> readBitString numberWords statePtr
      newCString . encodeUtf8 . toPrettyText $ state

foreign export ccall "ls_hs_fixed_hamming_state_to_index"
  ls_hs_fixed_hamming_state_to_index :: Word64 -> CPtrdiff

ls_hs_fixed_hamming_state_to_index = fromIntegral . fixedHammingStateToIndex

foreign export ccall "ls_hs_fixed_hamming_index_to_state"
  ls_hs_fixed_hamming_index_to_state :: CPtrdiff -> CInt -> Word64

ls_hs_fixed_hamming_index_to_state index hammingWeight =
  fixedHammingIndexToState (fromIntegral hammingWeight) (fromIntegral index)

-- }}}

-- {{{ Expr

foreign export ccall "ls_hs_expr_to_json"
  ls_hs_expr_to_json :: Ptr Cexpr -> IO CString

ls_hs_expr_to_json cExpr =
  withCexpr cExpr $ \expr -> do
    newCString $ toStrict (Data.Aeson.encode expr)

foreign export ccall "ls_hs_expr_from_json"
  ls_hs_expr_from_json :: CString -> IO (Ptr Cexpr)

ls_hs_expr_from_json cStr = handleAny (propagateErrorToC nullPtr) $ do
  !expr <- decodeCString cStr
  newCexpr expr

foreign export ccall "ls_hs_destroy_expr"
  ls_hs_destroy_expr :: Ptr Cexpr -> IO ()

ls_hs_destroy_expr = destroyCexpr

foreign export ccall "ls_hs_expr_to_string"
  ls_hs_expr_to_string :: Ptr Cexpr -> IO CString

ls_hs_expr_to_string p =
  handleAnyDeep (propagateErrorToC nullPtr) $
    withCexpr p $
      newCString . encodeUtf8 . toPrettyText

foreign export ccall "ls_hs_expr_plus"
  ls_hs_expr_plus :: Ptr Cexpr -> Ptr Cexpr -> IO (Ptr Cexpr)

ls_hs_expr_plus a b = handleAnyDeep (propagateErrorToC nullPtr) $ withCexpr2 a b (+) >>= newCexpr

foreign export ccall "ls_hs_expr_minus"
  ls_hs_expr_minus :: Ptr Cexpr -> Ptr Cexpr -> IO (Ptr Cexpr)

ls_hs_expr_minus a b = handleAnyDeep (propagateErrorToC nullPtr) $ withCexpr2 a b (-) >>= newCexpr

foreign export ccall "ls_hs_expr_times"
  ls_hs_expr_times :: Ptr Cexpr -> Ptr Cexpr -> IO (Ptr Cexpr)

ls_hs_expr_times a b = handleAnyDeep (propagateErrorToC nullPtr) $ withCexpr2 a b (*) >>= newCexpr

foreign export ccall "ls_hs_expr_scale"
  ls_hs_expr_scale :: Ptr Cscalar -> Ptr Cexpr -> IO (Ptr Cexpr)

ls_hs_expr_scale c_z c_a =
  handleAnyDeep (propagateErrorToC nullPtr) $
    withCexpr c_a $ \a -> do
      z <- fromComplexDouble <$> peek c_z
      newCexpr $ scale (z :: ComplexRational) a

foreign export ccall "ls_hs_replace_indices"
  ls_hs_replace_indices :: Ptr Cexpr -> FunPtr Creplace_index -> IO (Ptr Cexpr)

ls_hs_replace_indices exprPtr fPtr =
  handleAnyDeep (propagateErrorToC nullPtr) $
    withCexpr exprPtr $ \expr -> do
      let f :: Int -> Int -> IO (Int, Int)
          f !s !i =
            alloca $ \spinPtr ->
              alloca $ \sitePtr -> do
                mkCreplace_index fPtr (fromIntegral s) (fromIntegral i) spinPtr sitePtr
                (,)
                  <$> (fromIntegral <$> peek spinPtr)
                  <*> (fromIntegral <$> peek sitePtr)
      newCexpr =<< case expr of
        SomeExpr SpinTag terms ->
          SomeExpr SpinTag . simplifyExpr <$> mapIndicesM (\i -> snd <$> f 0 i) terms
        SomeExpr SpinlessFermionTag terms ->
          SomeExpr SpinlessFermionTag . simplifyExpr <$> mapIndicesM (\i -> snd <$> f 0 i) terms
        SomeExpr SpinfulFermionTag terms ->
          let f' (s, i) = do
                (s', i') <- f (fromEnum s) i
                pure (toEnum s', i')
           in SomeExpr SpinfulFermionTag . simplifyExpr <$> mapIndicesM f' terms

foreign export ccall "ls_hs_expr_equal"
  ls_hs_expr_equal :: Ptr Cexpr -> Ptr Cexpr -> IO CBool

ls_hs_expr_equal aPtr bPtr =
  withCexpr aPtr $ \a ->
    withCexpr bPtr $ \b ->
      pure $ fromBool (a == b)

foreign export ccall "ls_hs_expr_adjoint"
  ls_hs_expr_adjoint :: Ptr Cexpr -> IO (Ptr Cexpr)

ls_hs_expr_adjoint = flip withCexpr $ \(SomeExpr tag expr) ->
  newCexpr $ SomeExpr tag (conjugateExpr expr)

foreign export ccall "ls_hs_expr_is_hermitian"
  ls_hs_expr_is_hermitian :: Ptr Cexpr -> IO CBool

ls_hs_expr_is_hermitian = flip withCexpr $ foldSomeExpr (pure . fromBool . isHermitianExpr)

foreign export ccall "ls_hs_expr_is_real"
  ls_hs_expr_is_real :: Ptr Cexpr -> IO CBool

ls_hs_expr_is_real = flip withCexpr $ foldSomeExpr (pure . fromBool . isRealExpr)

foreign export ccall "ls_hs_expr_is_identity"
  ls_hs_expr_is_identity :: Ptr Cexpr -> IO CBool

ls_hs_expr_is_identity = flip withCexpr $ foldSomeExpr (pure . fromBool . isIdentityExpr)

-- }}}

-- {{{ Operator

foreign export ccall "ls_hs_create_operator"
  ls_hs_create_operator :: Ptr Cbasis -> Ptr Cexpr -> IO (Ptr Coperator)

ls_hs_create_operator :: Ptr Cbasis -> Ptr Cexpr -> IO (Ptr Coperator)
ls_hs_create_operator basisPtr exprPtr =
  handleAny (propagateErrorToC nullPtr) $ do
    logDebug' $ "ls_hs_create_operator " <> show basisPtr <> ", " <> show exprPtr
    withCbasis basisPtr $ \someBasis ->
      withSomeBasis someBasis $ \basis ->
        withCexpr exprPtr $ \someExpr ->
          withSomeExpr someExpr $ \expr ->
            case matchParticleType2 basis expr of
              Just HRefl -> newCoperator (Just basisPtr) (mkOperator basis expr)
              Nothing -> error "basis and expression have different particle types"

foreign export ccall "ls_hs_clone_operator"
  ls_hs_clone_operator :: Ptr Coperator -> IO (Ptr Coperator)

ls_hs_clone_operator = cloneCoperator

foreign export ccall "ls_hs_destroy_operator"
  destroyCoperator :: Ptr Coperator -> IO ()

foreign export ccall "ls_hs_operator_max_number_off_diag"
  ls_hs_operator_max_number_off_diag :: Ptr Coperator -> IO CInt

ls_hs_operator_max_number_off_diag opPtr =
  fmap fromIntegral $
    withCoperator opPtr $ \someOp ->
      withSomeOperator someOp $ \op ->
        pure $ maxNumberOffDiag op

foreign export ccall "ls_hs_operator_get_expr"
  ls_hs_operator_get_expr :: Ptr Coperator -> IO (Ptr Cexpr)

ls_hs_operator_get_expr opPtr =
  withCoperator opPtr $ \someOp ->
    withSomeOperator someOp $ \op ->
      newCexpr $
        SomeExpr
          (getParticleTag . opBasis $ op)
          (opTerms op)

foreign export ccall "ls_hs_operator_get_basis"
  ls_hs_operator_get_basis :: Ptr Coperator -> IO (Ptr Cbasis)

ls_hs_operator_get_basis = ls_hs_clone_basis . coperator_basis <=< peek

-- foreign export ccall "ls_hs_load_hamiltonian_from_yaml"
--   ls_hs_load_hamiltonian_from_yaml :: CString -> IO (Ptr Coperator)
--
-- ls_hs_load_hamiltonian_from_yaml cFilename =
--   foldSomeOperator borrowCoperator =<< hamiltonianFromYAML =<< peekUtf8 cFilename

-- foreign import ccall "ls_hs_destroy_basis_v2"
--   ls_hs_destroy_basis_v2 :: Ptr Cbasis -> IO ()

-- foreign import ccall "ls_hs_destroy_operator_v2"
--   ls_hs_destroy_operator_v2 :: Ptr Coperator -> IO ()

toCyaml_config :: ConfigSpec -> IO (Ptr Cyaml_config)
toCyaml_config (ConfigSpec basis maybeHamiltonian observables) = do
  p <- malloc
  -- print basis
  basisPtr <- withSomeBasis basis newCbasis
  -- withSomeBasis basis $ \b ->
  --   withForeignPtr (basisContents b) $ \ptr -> do
  --     _ <- basisIncRefCount ptr
  --     pure ptr
  -- print "1)"
  -- borrowCbasis
  hamiltonianPtr <- case maybeHamiltonian of
    Just h -> withSomeOperator h (newCoperator (Just basisPtr))
    Nothing -> pure nullPtr
  -- print "2)"
  observablesPtr <-
    (newArray =<<) $
      G.toList <$> G.mapM (foldSomeOperator (newCoperator (Just basisPtr))) observables
  -- print "3)"
  poke p $
    Cyaml_config basisPtr hamiltonianPtr (fromIntegral (G.length observables)) observablesPtr
  pure p

foreign export ccall "ls_hs_load_yaml_config"
  ls_hs_load_yaml_config :: CString -> IO (Ptr Cyaml_config)

ls_hs_load_yaml_config cFilename =
  toCyaml_config =<< configFromYAML =<< peekUtf8 cFilename

foreign export ccall "ls_hs_destroy_yaml_config"
  ls_hs_destroy_yaml_config :: Ptr Cyaml_config -> IO ()

ls_hs_destroy_yaml_config p
  | p == nullPtr = pure ()
  | otherwise = do
      logDebug' "ls_hs_destroy_yaml_config ..."
      (Cyaml_config basisPtr hamiltonianPtr numberObservables observablesPtr) <- peek p
      -- logDebug' "ls_hs_destroy_yaml_config 1) ..."
      forM_ [0 .. fromIntegral numberObservables - 1] $ \i ->
        destroyCoperator =<< peekElemOff observablesPtr i
      -- logDebug' "ls_hs_destroy_yaml_config 2) ..."
      when (observablesPtr /= nullPtr) $ free observablesPtr
      -- logDebug' "ls_hs_destroy_yaml_config 3) ..."
      when (hamiltonianPtr /= nullPtr) $ destroyCoperator hamiltonianPtr
      -- logDebug' "ls_hs_destroy_yaml_config 4) ..."
      destroyCbasis basisPtr
      -- logDebug' "ls_hs_destroy_yaml_config 5) ..."
      free p
      logDebug' "ls_hs_destroy_yaml_config done!"

-- ls_hs_operator_pretty_terms :: Ptr Coperator -> IO CString
-- ls_hs_operator_pretty_terms p =
--   withReconstructedOperator p $ \op ->
--     newCString
--       . encodeUtf8
--       . renderStrict
--       . Pretty.layoutPretty (Pretty.LayoutOptions Pretty.Unbounded)
--       . pretty
--       $ opTerms (opHeader op)

-- foreign export ccall "ls_hs_operator_pretty_terms"
--   ls_hs_operator_pretty_terms :: Ptr Coperator -> IO CString

-- foreign export ccall "ls_hs_fatal_error"
--   ls_hs_fatal_error :: CString -> CString -> IO ()
