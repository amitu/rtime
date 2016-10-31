import pytest
from django.test.client import ClientHandler

from djrtime.handlers import TimeItHandler


class TestClienHandler(ClientHandler, TimeItHandler):
    pass


@pytest.fixture()
def client():
    """A Django test client instance."""
    from django.test.client import Client

    client_ = Client()
    client_.handler = TestClienHandler()
    return client_


@pytest.fixture()
def admin_client(db, admin_user):
    """A Django test client logged in as an admin user."""
    from django.test.client import Client

    client_ = Client()
    client_.handler = TestClienHandler()
    client_.login(username=admin_user.username, password='password')
    return client_
