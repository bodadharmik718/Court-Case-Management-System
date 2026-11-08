from unittest.mock import patch

import pytest

from auth.authorization import require_permission


@patch("auth.authorization.has_permission", return_value=False)
def test_permission_denied_by_default(mock_permission) -> None:
    with pytest.raises(PermissionError):
        require_permission(42, "CASE_UPDATE", case_id=11)
    mock_permission.assert_called_once()
