from __future__ import absolute_import, unicode_literals

from rtime import utils
from rtime.decorators import timeit

from .utils import assert_similar_structure


@timeit
def f1(call_count=0):
    while call_count:
        call_count -= 1
        f2(call_count)


@timeit('func2')
def f2(call_count=0):
    while call_count:
        call_count -= 1
        f1(call_count)


def test_init():
    utils.init(name='name')
    assert_similar_structure(utils.stop(), {'name': 'name'})


def test_single_call():
    utils.init(name='name')
    f1(call_count=0)
    assert_similar_structure(utils.stop(), {
        'name': 'name',
        'stack': [
            {'name': 'tests.tests.f1', 'time_taken': 0}
        ]
    })


def test_single_call_multi_func():
    utils.init(name='name')
    f1(call_count=0)
    f2(call_count=0)
    assert_similar_structure(utils.stop(), {
        'name': 'name',
        'stack': [
            {'name': 'tests.tests.f1', 'time_taken': 0},
            {'name': 'func2', 'time_taken': 0},
        ]
    })


def test_delay_init():
    f1(call_count=0)
    utils.init(name='name')
    f2(call_count=0)
    assert_similar_structure(utils.stop(), {
        'name': 'name',
        'stack': [
            {'name': 'func2', 'time_taken': 0},
        ]
    })


def test_delay_name_set():
    f1(call_count=0)
    utils.init(name='name')
    f2(call_count=0)
    utils.set_name('new_name')
    utils.add_session_data(key='value')
    assert_similar_structure(utils.stop(), {
        'name': 'new_name',
        'key': 'value',
        'stack': [
            {'name': 'func2', 'time_taken': 0},
        ]
    })


def test_recursion():
    utils.init(name='name')
    f1(call_count=2)
    utils.set_name('new_name')
    utils.add_session_data(key='value')
    assert_similar_structure(utils.stop(), {
        'name': 'new_name',
        'key': 'value',
        'stack': [
            {
                'name': 'tests.tests.f1',
                'time_taken': 0,
                'stack': [
                    {
                        'name': 'func2',
                        'time_taken': 0,
                        'stack': [
                            {
                                'name': 'tests.tests.f1',
                                'time_taken': 0,
                            }
                        ]
                    },
                    {
                        'name': 'func2',
                        'time_taken': 0,
                    }
                ]
            },
        ],
    })


def test_recursion_multi_func():
    utils.init(name='name')
    f1(call_count=2)
    f2(call_count=2)
    utils.set_name('new_name')
    utils.add_session_data(key='value')
    assert_similar_structure(utils.stop(), {
        'name': 'new_name',
        'key': 'value',
        'stack': [
            {
                'name': 'tests.tests.f1',
                'time_taken': 0,
                'stack': [
                    {
                        'name': 'func2',
                        'time_taken': 0,
                        'stack': [
                            {
                                'name': 'tests.tests.f1',
                                'time_taken': 0,
                            }
                        ]
                    },
                    {
                        'name': 'func2',
                        'time_taken': 0,
                    }
                ]
            },
            {
                'name': 'func2',
                'time_taken': 0,
                'stack': [
                    {
                        'name': 'tests.tests.f1',
                        'time_taken': 0,
                        'stack': [
                            {
                                'name': 'func2',
                                'time_taken': 0,
                            }
                        ]
                    },
                    {
                        'name': 'tests.tests.f1',
                        'time_taken': 0,
                    }
                ]
            },
        ],
    })
