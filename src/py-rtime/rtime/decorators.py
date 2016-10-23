from __future__ import absolute_import, unicode_literals

from functools import wraps

import six
import time

from . import utils


def timeit(func_or_name):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not utils.is_initialised():
                return func(*args, **kwargs)
            utils.push_frame(frame_name=name)
            start = time.time()
            try:
                return func(*args, **kwargs)
            finally:
                ms = round(1000 * (time.time() - start), 4)
                utils.add_frame_data(time_taken=ms)
                utils.pop_frame()
        return wrapper

    if isinstance(func_or_name, six.string_types):
        name = func_or_name
        return decorator
    else:
        name = '.'.join((func_or_name.__module__, func_or_name.__name__))
    return decorator(func_or_name)
