import pytest

pytestmark = pytest.mark.django_db


def test_sample(client):
    client.get('/')


def test_admin(admin_client):
    admin_client.get('/admin/')


def test_random(client):
    client.get('/random', follow=True)
