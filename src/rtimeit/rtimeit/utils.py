from __future__ import absolute_import, unicode_literals

import time
from functools import wraps
from threading import current_thread

from structlog import wrap_logger, get_logger
from structlog.processors import JSONRenderer

logger = wrap_logger(
    get_logger(),
    processors=[
        JSONRenderer(indent=4)
    ]
)
_events = {}


class TimeIt(object):
    def __init__(self, name):
        self.name = name
        self.ms = None
        self._start_time = time.time()
        self.data = None
        self.__master = False
        self.parent_data = None

    def __call__(self, f):
        @wraps(f)
        def inner(*args, **kwargs):
            with self:
                return f(*args, **kwargs)
        return inner

    def __enter__(self):
        self.start()

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop()

    def start(self):
        self.ms = None
        self._start_time = time.time()
        self.data = {}
        self.parent_data = _events.setdefault(current_thread(), self.data)
        self.__master = self.parent_data is self.data
        if not self.__master:
            self.parent_data.setdefault('children', []).append(self.data)

        _events[current_thread()] = self.data
        return self

    def stop(self, send=True):
        if self._start_time is None:
            raise RuntimeError('TimeIt is not started')
        if self.data is None:
            raise RuntimeError('TimeIt data is not set')

        time_taken = time.time() - self._start_time
        self.ms = round(1000 * time_taken, 4)
        self.data['time'] = self.ms
        self.data['func'] = self.name
        _events[current_thread()] = self.parent_data
        if self.__master and send:
            self.send()
            # This is to make sure that another timeit invocation
            # at master level starts with fresh data
            del _events[current_thread()]

    def send(self):
        if self.ms is None:
            raise RuntimeError('TimeIt is not recorded')

        logger.info(_events[current_thread()])
        # import json
        # print(json.dumps(_events[current_thread()], indent=4))
