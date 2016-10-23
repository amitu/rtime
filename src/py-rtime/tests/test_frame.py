from __future__ import absolute_import, unicode_literals

import pytest

from rtime.datastructures import Frame

from .utils import assert_similar_structure


def test_init():
    assert_similar_structure(Frame(), {})
    assert_similar_structure(Frame(name='name'), {'name': 'name'})
    assert_similar_structure(Frame(name='name', value=1.0), {'name': 'name', 'value': 1.0})


def test_name():
    frame = Frame()
    frame.name = 'main_frame'
    assert 'main_frame' == frame.name
    assert_similar_structure(frame, {'name': 'main_frame'})

    with pytest.raises(ValueError):
        frame.name = ''


def test_stack():
    frame = Frame(name='name')
    assert_similar_structure(frame.stack, [])
    assert_similar_structure(frame, {'name': 'name', 'stack': []})


def test_push_frame():
    frame = Frame(name='main_frame')
    frame.push_frame(name='new_frame')
    assert_similar_structure(frame, {'name': 'main_frame', 'stack': [{'name': 'new_frame'}]})


def test_get_current_frame():
    frame = Frame()
    assert_similar_structure(frame.get_current_frame(), {})
    frame.push_frame(name='new_frame')
    assert_similar_structure(frame.get_current_frame(), {'name': 'new_frame'})


def test_add_frame_data():
    frame = Frame()
    frame.push_frame(name='new_frame')
    frame.add_frame_data(value=1.0)
    assert_similar_structure(frame, {'stack': [{'name': 'new_frame'}], 'value': 1.0})
