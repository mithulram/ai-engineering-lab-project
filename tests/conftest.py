import pytest
import tempfile
import os
from app import app, db

@pytest.fixture(scope="session")
def test_app():
    fd, db_path = tempfile.mkstemp(prefix="test_db_", suffix=".sqlite")
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{db_path}"
    with app.app_context():
        db.create_all()
    yield app
    try:
        os.close(fd)
        os.remove(db_path)
    except Exception:
        pass

@pytest.fixture
def client(test_app):
    return test_app.test_client()

import subprocess
import time
import requests
import signal

@pytest.fixture(scope="session", autouse=True)
def live_server():
    import subprocess, time, requests, os, signal
    env = os.environ.copy()
    api_port = env.get('API_PORT','5001')
    proc = subprocess.Popen(['python3','app.py'], env=env)
    deadline = time.time() + 30
    while time.time() < deadline:
        try:
            r = requests.get(f"http://127.0.0.1:{api_port}/api/health", timeout=1)
            if r.status_code == 200:
                break
        except Exception:
            time.sleep(1)
    else:
        proc.terminate()
        raise RuntimeError("Live server failed to start within 30s")
    yield
    proc.send_signal(signal.SIGINT)
    proc.wait(timeout=5)
