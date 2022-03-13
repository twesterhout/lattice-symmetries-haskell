#include "lattice_symmetries_haskell.h"
#include <assert.h>
#include <complex.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint64_t ls_hs_bits;

typedef struct ls_hs_nonbranching_term {
  ls_hs_scalar v;
  ls_hs_bits m;
  ls_hs_bits l;
  ls_hs_bits r;
  ls_hs_bits x;
  ls_hs_bits s;
} ls_hs_nonbranching_term;

static inline int popcount(ls_hs_bits x) { return __builtin_popcountl(x); }

// Compute term|α⟩ = coeff|β⟩
void ls_hs_apply_nonbranching_term(ls_hs_nonbranching_term const *const term,
                                   ls_hs_bits const alpha,
                                   ls_hs_bits *const beta,
                                   ls_hs_scalar *const coeff) {
  int const delta = (alpha & term->m) == term->r;
  int const sign = 1 - 2 * (popcount(alpha & term->s) % 2);
  *beta = alpha ^ term->x;
  *coeff = term->v * (delta * sign);
}

#if 0
void strided_memset(void *const restrict dest, ptrdiff_t const count,
                    ptrdiff_t const stride, void const *const restrict element,
                    ptrdiff_t const size) {
  for (ptrdiff_t i = 0; i < count; ++i) {
    // Fill one element
    memcpy(dest + i * stride * size, element, size);
  }
}
#endif

static inline void bitstring_and(int const number_words,
                                 uint64_t const *const a,
                                 uint64_t const *const b,
                                 uint64_t *restrict const out) {
  for (int i = 0; i < number_words; ++i) {
    out[i] = a[i] & b[i];
  }
}

static inline void bitstring_xor(int const number_words,
                                 uint64_t const *const a,
                                 uint64_t const *const b,
                                 uint64_t *restrict const out) {
  for (int i = 0; i < number_words; ++i) {
    out[i] = a[i] ^ b[i];
  }
}

static inline bool bitstring_equal(int const number_words,
                                   uint64_t const *const a,
                                   uint64_t const *const b) {
  for (int i = 0; i < number_words; ++i) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

static inline int bitstring_popcount(int const number_words,
                                     uint64_t const *const restrict a) {
  int acc = 0;
  for (int i = 0; i < number_words; ++i) {
    acc += __builtin_popcountl(a[i]);
  }
  return acc;
}

void ls_hs_operator_apply_diag_kernel(ls_hs_operator const *op,
                                      ptrdiff_t const batch_size,
                                      uint64_t const *restrict const alphas,
                                      ptrdiff_t const alphas_stride,
                                      ls_hs_scalar *restrict const coeffs) {
  fprintf(stderr, "ls_hs_operator_apply_diag_kernel ...\n");
  if (op->diag_terms == NULL ||
      op->diag_terms->number_terms == 0) { // the diagonal is zero
    fprintf(stderr, "The diagonal is zero ...\n");
    memset(coeffs, 0, (size_t)batch_size * sizeof(ls_hs_scalar));
    return;
  }

  int const number_words = (op->diag_terms->number_bits + 63) / 64;
  fprintf(stderr, "number_words=%d\n", number_words);
  uint64_t *restrict const temp = malloc(number_words * sizeof(uint64_t));
  if (temp == NULL) {
    fprintf(stderr, "%s\n", "failed to allocate memory");
    abort();
  }

  ls_hs_nonbranching_terms const *restrict terms = op->diag_terms;
  ptrdiff_t const number_terms = terms->number_terms;
  for (ptrdiff_t batch_idx = 0; batch_idx < batch_size; ++batch_idx) {
    ls_hs_scalar acc = 0;
    uint64_t const *restrict const alpha = alphas + batch_idx * alphas_stride;
    for (ptrdiff_t term_idx = 0; term_idx < number_terms; ++term_idx) {
      ls_hs_scalar const v = terms->v[term_idx];
      uint64_t const *restrict const m = terms->m + term_idx * number_words;
      uint64_t const *restrict const r = terms->r + term_idx * number_words;
      uint64_t const *restrict const s = terms->s + term_idx * number_words;

      bitstring_and(number_words, alpha, m, temp);
      int const delta = bitstring_equal(number_words, temp, r);
      bitstring_and(number_words, alpha, s, temp);
      int const sign = 1 - 2 * (bitstring_popcount(number_words, temp) % 2);
      fprintf(stderr, "α=%zu, s=%zu, temp=%zu, popcount(temp)=%d, %d\n",
              alpha[0], s[0], temp[0], bitstring_popcount(number_words, temp),
              __builtin_popcountl(temp[0]));
      acc += v * (delta * sign);
      fprintf(stderr, "acc += (%f + %fi) * (%d * %d)\n", crealf(v), cimagf(v),
              delta, sign);
    }
    coeffs[batch_idx] = acc;
  }
  free(temp);
}

void ls_hs_operator_apply_off_diag_kernel(
    ls_hs_operator const *op, ptrdiff_t batch_size, uint64_t const *alphas,
    ptrdiff_t alphas_stride, uint64_t *betas, ptrdiff_t betas_stride,
    ls_hs_scalar *coeffs) {
  fprintf(stderr, "ls_hs_operator_apply_off_diag_kernel ...\n");
  if (op->off_diag_terms == NULL ||
      op->off_diag_terms->number_terms == 0) { // nothing to apply
    fprintf(stderr, "Nothing to do...\n");
    return;
  }

  int const number_words = (op->off_diag_terms->number_bits + 63) / 64;
  uint64_t *restrict const temp = malloc(number_words * sizeof(uint64_t));
  if (temp == NULL) {
    fprintf(stderr, "%s\n", "failed to allocate memory");
    abort();
  }

  ls_hs_nonbranching_terms const *restrict terms = op->off_diag_terms;
  ptrdiff_t const number_terms = terms->number_terms;
  for (ptrdiff_t batch_idx = 0; batch_idx < batch_size; ++batch_idx) {
    fprintf(stderr, "batch_idx=%zi\n", batch_idx);
    uint64_t const *restrict const alpha = alphas + batch_idx * alphas_stride;
    for (ptrdiff_t term_idx = 0; term_idx < number_terms; ++term_idx) {
      fprintf(stderr, "term_idx=%zi\n", batch_idx);
      ls_hs_scalar const v = terms->v[term_idx];
      uint64_t const *restrict const m = terms->m + term_idx * number_words;
      uint64_t const *restrict const r = terms->r + term_idx * number_words;
      uint64_t const *restrict const x = terms->x + term_idx * number_words;
      uint64_t const *restrict const s = terms->s + term_idx * number_words;
      uint64_t *restrict const beta =
          betas + (batch_idx * number_terms + term_idx) * betas_stride;

      bitstring_and(number_words, alpha, m, temp);
      int const delta = bitstring_equal(number_words, temp, r);
      bitstring_and(number_words, alpha, s, temp);
      fprintf(stderr, "α=%zu, s=%zu, temp=%zu, popcount(temp)=%d\n", alpha[0],
              s[0], temp[0], bitstring_popcount(number_words, temp));
      int const sign = 1 - 2 * (bitstring_popcount(number_words, temp) % 2);
      coeffs[batch_idx * number_terms + term_idx] = v * (delta * sign);
      bitstring_xor(number_words, alpha, x, beta);
      fprintf(stderr, "coeffs[%zi] = (%f + %fi) * (%d * %d)\n",
              batch_idx * number_terms + term_idx, crealf(v), cimagf(v), delta,
              sign);
    }
  }
  free(temp);
}

ls_hs_binomials *ls_hs_internal_malloc_binomials(int const number_bits) {
  ls_hs_binomials *p = malloc(sizeof(ls_hs_binomials));
  if (p == NULL) {
    goto fail_1;
  }
  p->dimension = number_bits + 1; // NOTE: +1 because we could have n and k
                                  // running from 0 to number_bits inclusive
  p->coefficients = malloc(p->dimension * p->dimension * sizeof(uint64_t));
  if (p->coefficients == NULL) {
    goto fail_2;
  }
  return p;

fail_2:
  free(p);
fail_1:
  return NULL;
}

void ls_hs_internal_free_binomials(ls_hs_binomials *p) {
  if (p != NULL) {
    free(p->coefficients);
  }
  free(p);
}

void ls_hs_internal_compute_binomials(ls_hs_binomials *p) {
  int const dim = p->dimension;
  uint64_t *const coeff = p->coefficients;
  int n = 0;
  int k = 0;
  coeff[n * dim + k] = 1;
  for (int k = 1; k < dim; ++k) {
    coeff[n * dim + k] = 0;
  }
  for (n = 1; n < dim; ++n) {
    coeff[n * dim + 0] = 1;
    for (k = 1; k <= n; ++k) {
      coeff[n * dim + k] =
          coeff[(n - 1) * dim + (k - 1)] + coeff[(n - 1) * dim + k];
    }
    for (; k < n; ++k) {
      coeff[n * dim + k] = 0;
    }
  }
}

uint64_t ls_hs_internal_binomial(int const n, int const k,
                                 ls_hs_binomials const *cache) {
  if (k > n) {
    return 0;
  }
  assert(0 <= n && n < cache->dimension);
  assert(0 <= k && k < cache->dimension);
  return cache->coefficients[n * cache->dimension + k];
}

static uint64_t rank_via_combinadics(uint64_t alpha,
                                     ls_hs_binomials const *cache) {
  uint64_t i = 0;
  for (int k = 1; alpha != 0; ++k) {
    int c = __builtin_ctzl(alpha);
    alpha &= alpha - 1;
    i += ls_hs_internal_binomial(c, k, cache);
  }
  return i;
}

// -- |
// -- Cindex_kernel
// --   batch_size
// --   spins
// --   spins_stride
// --   indices
// --   indices_stride
// --   private_kernel_data
// type Cindex_kernel = CPtrdiff -> Ptr Word64 -> CPtrdiff -> Ptr CPtrdiff ->
// CPtrdiff -> Ptr () -> IO ()
void ls_hs_state_index_combinadics_kernel(ptrdiff_t const batch_size,
                                          uint64_t const *spins,
                                          ptrdiff_t const spins_stride,
                                          ptrdiff_t *const restrict indices,
                                          ptrdiff_t const indices_stride,
                                          void const *private_kernel_data) {
  ls_hs_binomials const *cache = private_kernel_data;
  for (ptrdiff_t batch_idx = 0; batch_idx < batch_size; ++batch_idx) {
    indices[batch_idx * indices_stride] =
        rank_via_combinadics(spins[batch_idx * spins_stride], cache);
  }
}

void ls_hs_state_index_identity_kernel(ptrdiff_t const batch_size,
                                       uint64_t const *spins,
                                       ptrdiff_t const spins_stride,
                                       ptrdiff_t *const restrict indices,
                                       ptrdiff_t const indices_stride,
                                       void const *private_kernel_data) {
  for (ptrdiff_t batch_idx = 0; batch_idx < batch_size; ++batch_idx) {
    indices[batch_idx * indices_stride] =
        (ptrdiff_t)spins[batch_idx * spins_stride];
  }
}