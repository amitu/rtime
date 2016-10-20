from __future__ import absolute_import, unicode_literals

from django.core.handlers.wsgi import WSGIHandler
from django.db.backends.utils import CursorWrapper

from .wrappers import (exception_wrapper, request_wrapper, response_wrapper,
                       template_response_wrapper, view_wrapper, execute)


class TimeItHandler(WSGIHandler):
    def __init__(self, *args, **kwargs):
        super(TimeItHandler, self).__init__(*args, **kwargs)
        CursorWrapper._execute = CursorWrapper.execute
        CursorWrapper.execute = execute

    def load_middleware(self):
        super(TimeItHandler, self).load_middleware()

        for i, m in enumerate(self._request_middleware):
            self._request_middleware[i] = request_wrapper(m)

        for i, m in enumerate(self._view_middleware):
            self._view_middleware[i] = view_wrapper(m)

        for i, m in enumerate(self._template_response_middleware):
            self._template_response_middleware[i] = template_response_wrapper(m)

        for i, m in enumerate(self._response_middleware):
            self._response_middleware[i] = response_wrapper(m)

        for i, m in enumerate(self._exception_middleware):
            self._exception_middleware[i] = exception_wrapper(m)
