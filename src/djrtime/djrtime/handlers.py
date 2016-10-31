from __future__ import absolute_import, unicode_literals

from django.core.handlers.wsgi import WSGIHandler
from django.db.backends.utils import CursorWrapper
from django.utils.decorators import method_decorator

from rtime.decorators import timeit

from .wrappers import (exception_wrapper, execute, request_wrapper,
                       response_wrapper, template_response_wrapper,
                       view_wrapper)


class TimeItHandler(WSGIHandler):

    def load_middleware(self):
        super(TimeItHandler, self).load_middleware()
        self._patch_middlewares()
        self._patch_cursor()

    def _patch_middlewares(self):
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

    @staticmethod
    def _patch_cursor():
        CursorWrapper._execute = CursorWrapper.execute
        CursorWrapper.execute = method_decorator(timeit('db'))(execute)
