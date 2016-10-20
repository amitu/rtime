from __future__ import absolute_import, unicode_literals

from rtimeit.decorators import timeit


@timeit
def f1(call_count=0):
    while call_count:
        call_count -= 1
        f2(call_count)


@timeit
def f2(call_count=0):
    while call_count:
        call_count -= 1
        f1(call_count)


# @timeit
def test_f1():
    f1(call_count=1)
    f2(call_count=1)

if __name__ == '__main__':
    test_f1()
