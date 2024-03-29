import lattice_symmetries as ls
import numpy as np
import scipy.sparse.linalg


def test_symmetry():
    a = ls.Symmetry([0, 1, 2], sector=0)
    assert a.sector == 0
    assert len(a) == 3
    assert a.permutation.tolist() == [0, 1, 2]
    b = ls.Symmetry(a._payload, None)
    assert b.sector == 0
    assert len(b) == 3
    assert b.permutation.tolist() == [0, 1, 2]
    del b
    del a

def test_symmetries():
    a = ls.Symmetry([1, 2, 3, 0], sector=0)
    b = ls.Symmetry([3, 2, 1, 0], sector=0)
    c = ls.Symmetries([a, b])

def test_index():
    basis = ls.SpinBasis(4)
    basis.build()
    assert np.array_equal(basis.index(basis.states), basis.states)
    assert np.array_equal(basis.index(basis.states[2]), 2)

def test_kagome_symmetries():
    expr = ls.Expr("1.0 × σᶻ₀ σᶻ₁ + 1.0 × σᶻ₀ σᶻ₃ + 1.0 × σᶻ₀ σᶻ₈ + 1.0 × σᶻ₀ σᶻ₁₀ + 2.0 × σ⁺₀ σ⁻₁ + 2.0 × σ⁺₀ σ⁻₃ + 2.0 × σ⁺₀ σ⁻₈ + 2.0 × σ⁺₀ σ⁻₁₀ + 2.0 × σ⁻₀ σ⁺₁ + 2.0 × σ⁻₀ σ⁺₃ + 2.0 × σ⁻₀ σ⁺₈ + 2.0 × σ⁻₀ σ⁺₁₀ + 1.0 × σᶻ₁ σᶻ₂ + 0.8 × σᶻ₁ σᶻ₃ + 0.8 × σᶻ₁ σᶻ₉ + 2.0 × σ⁺₁ σ⁻₂ + 1.6 × σ⁺₁ σ⁻₃ + 1.6 × σ⁺₁ σ⁻₉ + 2.0 × σ⁻₁ σ⁺₂ + 1.6 × σ⁻₁ σ⁺₃ + 1.6 × σ⁻₁ σ⁺₉ + 1.0 × σᶻ₂ σᶻ₄ + 1.0 × σᶻ₂ σᶻ₉ + 1.0 × σᶻ₂ σᶻ₁₀ + 2.0 × σ⁺₂ σ⁻₄ + 2.0 × σ⁺₂ σ⁻₉ + 2.0 × σ⁺₂ σ⁻₁₀ + 2.0 × σ⁻₂ σ⁺₄ + 2.0 × σ⁻₂ σ⁺₉ + 2.0 × σ⁻₂ σ⁺₁₀ + 1.0 × σᶻ₃ σᶻ₅ + 0.8 × σᶻ₃ σᶻ₁₁ + 2.0 × σ⁺₃ σ⁻₅ + 1.6 × σ⁺₃ σ⁻₁₁ + 2.0 × σ⁻₃ σ⁺₅ + 1.6 × σ⁻₃ σ⁺₁₁ + 0.8 × σᶻ₄ σᶻ₆ + 1.0 × σᶻ₄ σᶻ₇ + 0.8 × σᶻ₄ σᶻ₁₀ + 1.6 × σ⁺₄ σ⁻₆ + 2.0 × σ⁺₄ σ⁻₇ + 1.6 × σ⁺₄ σ⁻₁₀ + 1.6 × σ⁻₄ σ⁺₆ + 2.0 × σ⁻₄ σ⁺₇ + 1.6 × σ⁻₄ σ⁺₁₀ + 1.0 × σᶻ₅ σᶻ₆ + 1.0 × σᶻ₅ σᶻ₈ + 1.0 × σᶻ₅ σᶻ₁₁ + 2.0 × σ⁺₅ σ⁻₆ + 2.0 × σ⁺₅ σ⁻₈ + 2.0 × σ⁺₅ σ⁻₁₁ + 2.0 × σ⁻₅ σ⁺₆ + 2.0 × σ⁻₅ σ⁺₈ + 2.0 × σ⁻₅ σ⁺₁₁ + 1.0 × σᶻ₆ σᶻ₇ + 0.8 × σᶻ₆ σᶻ₈ + 2.0 × σ⁺₆ σ⁻₇ + 1.6 × σ⁺₆ σ⁻₈ + 2.0 × σ⁻₆ σ⁺₇ + 1.6 × σ⁻₆ σ⁺₈ + 1.0 × σᶻ₇ σᶻ₉ + 1.0 × σᶻ₇ σᶻ₁₁ + 2.0 × σ⁺₇ σ⁻₉ + 2.0 × σ⁺₇ σ⁻₁₁ + 2.0 × σ⁻₇ σ⁺₉ + 2.0 × σ⁻₇ σ⁺₁₁ + 0.8 × σᶻ₈ σᶻ₁₀ + 1.6 × σ⁺₈ σ⁻₁₀ + 1.6 × σ⁻₈ σ⁺₁₀ + 0.8 × σᶻ₉ σᶻ₁₁ + 1.6 × σ⁺₉ σ⁻₁₁ + 1.6 × σ⁻₉ σ⁺₁₁")
    # top_shift = ls.Symmetry([5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 11, 10], sector=0)
    right_shift = ls.Symmetry([2, 10, 0, 4, 3, 7, 11, 5, 9, 8, 1, 6], sector=1)
    assert expr == expr.replace_indices(dict(zip(range(12), right_shift.permutation)))
    symmetries = ls.Symmetries([right_shift])
    basis = ls.SpinBasis(symmetries=symmetries, number_spins=12, hamming_weight=6, spin_inversion=None)
    basis.build()
    print(basis.states)
    print(basis.state_info(basis.states))
    hamiltonian = ls.Operator(basis, expr)
    energy, state = scipy.sparse.linalg.eigsh(hamiltonian, k=1, which="SA")