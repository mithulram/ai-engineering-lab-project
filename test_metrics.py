#!/usr/bin/env python3

from app import app

def test_metrics():
    with app.test_client() as client:
        response = client.get('/metrics')
        print(f'Status: {response.status_code}')
        print(f'Response: {response.data[:200]}')
        print(f'Content-Type: {response.headers.get("Content-Type")}')

if __name__ == "__main__":
    test_metrics()
