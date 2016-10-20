from __future__ import absolute_import, unicode_literals

from rtimeit.decorators import timeit
from rtimeit.utils import Timer


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

    # Example 1
    timer = Timer('rtimeit.tests').init()
    test_f1()
    timer.stop()

    # Example 2
    with Timer('rtimeit.tests').init():
        test_f1()

    # Example 3
    with Timer('rtimeit.tests') as timer:
        print('Do some stuff')
        timer.init()
        test_f1()
        timer.stop()

    # Example 4
    with Timer('rtimeit.tests') as timer:
        print('Do some stuff')
        timer.init()
        test_f1()
        # timer.stop()

    # Example 5
    with Timer('rtimeit.tests') as timer:
        print('Do some stuff')
        timer.init()
        test_f1()
        timer.name = 'new_name'
        # timer.stop()

    # Example 6
    Timer('rtimeit.tests').init()
    test_f1()
    from rtimeit.utils import timer
    Timer.set_name('new_name')
    timer.stop()

    # Example 7
    # noop
    test_f1()
