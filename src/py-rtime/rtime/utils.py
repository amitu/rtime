from __future__ import absolute_import, unicode_literals

from functools import wraps
from threading import local

from structlog import wrap_logger, get_logger
from structlog.processors import JSONRenderer

from rtime.datastructures import Frame

logger = wrap_logger(
    get_logger(),
    processors=[
        JSONRenderer(indent=4)
    ]
)
_timer = local()


def is_initialised():
    return hasattr(_timer, 'main_frame')


def _reset():
    global _timer
    _timer = local()


def _raise_if_not_initialised(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if not is_initialised():  # pragma: no cover
            raise RuntimeError('Timeit is not initialised')
        return f(*args, **kwargs)
    return wrapper


def _raise_if_initialised(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if is_initialised():  # pragma: no cover
            raise RuntimeError('Timeit is already initialised')
        return f(*args, **kwargs)
    return wrapper


@_raise_if_initialised
def init(name=None, **kwargs):
    _timer.current_frame = _timer.main_frame = Frame(name=name, **kwargs)
    _timer.__frames = ()


@_raise_if_not_initialised
def set_name(name):
    _timer.main_frame.name = name


@_raise_if_not_initialised
def add_session_data(**kwargs):
    _timer.main_frame.add_frame_data(**kwargs)


@_raise_if_not_initialised
def push_frame(frame_name):
    _timer.current_frame.push_frame(name=frame_name)
    _timer.current_frame = _timer.current_frame.get_current_frame()
    _timer.__frames += (_timer.current_frame,)


@_raise_if_not_initialised
def add_frame_data(**kwargs):
    _timer.current_frame.add_frame_data(**kwargs)


@_raise_if_not_initialised
def stack_frame(name):
    """Don't know"""


@_raise_if_not_initialised
def pop_frame():
    if not _timer.__frames:
        raise RuntimeError('No frame to pop')
    _timer.__frames = _timer.__frames[:-1]
    _timer.current_frame = _timer.__frames[-1] if _timer.__frames else _timer.main_frame


@_raise_if_not_initialised
def stop(send=True, **kwargs):
    if len(_timer.__frames):
        raise RuntimeError('Can only stop from main frame')
    _timer.main_frame.add_frame_data(**kwargs)
    data = _timer.main_frame
    _reset()
    return data


# init(name=None, **kw)
#
# init("generate_chat_report", paid=True)
# {
#     "name": "generate_chat_report",
#     "paid": True,
#     "current": []
# }
#
# add_session_data(**kw)
#
# add_session_data(number_of_leads=20)
# {
#     "name": "generate_chat_report",
#     "paid": True,
#     "number_of_leads": 20
# }
#
#
# add_frame_data(**kw)
#
# add_frame_data(number_of_sales=2)
# {
#     "name": "generate_chat_report",
#     "paid": True,
#     "number_of_leads": 20,
#     "number_of_sales": 2,
#     "current": [],
#
# }
#
# set_name(name)
#
#
# stack_frame(name)
#
# stack_frame("do_heavy_computation")
# {
#     "name": "generate_chat_report",
#     "paid": True,
#     "number_of_leads": 20,
#     "number_of_sales": 2,
#     "do_heavy_computation": [{}]
#     "current": [[{}]]
# }
#
# add_frame_data(x=2)
#
# {
#     "name": "generate_chat_report",
#     "paid": True,
#     "number_of_leads": 20,
#     "number_of_sales": 2,
#     "do_heavy_computation": {"x": 2}
#     "current": [{"x": 2}]
# }
#
# push_frame("do_heavy_child")
# {
#     "name": "generate_chat_report",
#     "paid": True,
#     "number_of_leads": 20,
#     "number_of_sales": 2,
#     "do_heavy_computation": {"x": 2, "do_heavy_child": {}}
#     "current": [{"x": 2, "do_heavy_child": {}}, {}]
# }
#
# pop_frame()
# pop_frame()
# {
#     "name": "generate_chat_report",
#     "paid": True,
#     "number_of_leads": 20,
#     "number_of_sales": 2,
#     "do_heavy_computation": {"x": 2, "do_heavy_child": {}}
#     "current": []
# }
#
# data = stop(send=True, **kw)
