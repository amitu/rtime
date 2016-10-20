from functools import wraps

import six

from .utils import Timer


def timeit(func_or_name):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            with Timer(name):
                return func(*args, **kwargs)
        return wrapper

    if isinstance(func_or_name, six.string_types):
        name = func_or_name
        return decorator
    else:
        name = '.'.join((func_or_name.__module__, func_or_name.__name__))
    return decorator(func_or_name)
