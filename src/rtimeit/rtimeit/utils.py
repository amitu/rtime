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
timer = None


class Timer(object):
    def __init__(self, name):
        self.name = name
        self.ms = None
        self._start_time = time.time()
        self.data = None
        self.parent_data = None

    def __str__(self):
        return self.name

    def init(self):
        global timer
        if current_thread() in _events:
            raise RuntimeError('Timer is initialised multiple times')

        timer = self
        self.data = _events[current_thread()] = {}
        self.start()
        return self

    def __call__(self, f):
        @wraps(f)
        def inner(*args, **kwargs):
            with self:
                return f(*args, **kwargs)
        return inner

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop()

    @property
    def master(self):
        return timer is self

    def start(self):
        if current_thread() not in _events:
            return self
        self.ms = None
        self._start_time = time.time()
        self.parent_data = _events[current_thread()]
        if not self.master:
            self.data = {}
            self.parent_data.setdefault('children', []).append(self.data)

        _events[current_thread()] = self.data
        return self

    def stop(self, send=True):
        if current_thread() not in _events:
            return self
        if self._start_time is None:
            raise RuntimeError('TimeIt is not started')
        if self.data is None:
            raise RuntimeError('TimeIt data is not set')

        time_taken = time.time() - self._start_time
        self.ms = round(1000 * time_taken, 4)
        self.push_data({
            'time': self.ms,
            'func': self.name,
        })
        _events[current_thread()] = self.parent_data
        if self.master:
            self.data = _events.pop(current_thread())
            if send:
                self.send()

    def send(self):
        if self.ms is None:
            raise RuntimeError('TimeIt is not recorded')

        # logger.info(_events[current_thread()])
        import json
        print(json.dumps(self.data, indent=4))

    def push_data(self, data):
        if self.data is None:
            raise RuntimeError('Time it is not initialised')
        if not isinstance(data, dict):
            raise ValueError('data should be an instance of dict')

        self.data.update(data)

    @classmethod
    def set_main_name(cls, name):
        global timer
        if timer is None:
            raise RuntimeError('Timeit is not initialised')
        timer.name = name
