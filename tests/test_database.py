from unittest.mock import Mock, patch

import psycopg
import pytest

from database.connection import get_connection, health_check


def test_health_check_uses_database_connection() -> None:
    fake = Mock()
    fake.__enter__ = Mock(return_value=fake)
    fake.__exit__ = Mock(return_value=False)
    with patch("database.connection.psycopg.connect", return_value=fake):
        healthy, message = health_check()
    assert healthy is True
    assert "healthy" in message
    fake.execute.assert_called_once_with("SELECT 1")


def test_health_check_handles_connection_failure() -> None:
    with patch("database.connection.psycopg.connect", side_effect=psycopg.OperationalError("offline")):
        healthy, message = health_check()
    assert healthy is False
    assert "unavailable" in message
    assert "offline" not in message


def test_transaction_context_rolls_back_on_error() -> None:
    fake = Mock()
    fake.__enter__ = Mock(return_value=fake)
    fake.__exit__ = Mock(return_value=False)
    with patch("database.connection.psycopg.connect", return_value=fake):
        with pytest.raises(RuntimeError):
            with get_connection():
                raise RuntimeError("operation failed")
    fake.__exit__.assert_called_once()
    assert fake.__exit__.call_args.args[0] is RuntimeError
