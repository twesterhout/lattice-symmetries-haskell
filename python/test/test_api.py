import lattice_symmetries as ls
import numpy as np


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
