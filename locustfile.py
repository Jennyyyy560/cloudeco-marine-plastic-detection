# Locust Load Test - Simulates concurrent users sending images to CloudEco.

import base64
import uuid

from locust import HttpUser, task, between

# Pre-encode the test image once at startup 
with open("test_image.jpg", "rb") as f:
    IMAGE_B64 = base64.b64encode(f.read()).decode("utf-8")


class CloudEcoUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def predict(self):
        """POST to /api/predict — weighted 3x, the primary inference endpoint."""
        payload = {
            "uuid": str(uuid.uuid4()),
            "image": IMAGE_B64,
        }
        self.client.post("/api/predict", json=payload)

    @task(1)
    def annotate(self):
        """POST to /api/annotate — weighted 1x, more expensive due to image rendering."""
        payload = {
            "uuid": str(uuid.uuid4()),
            "image": IMAGE_B64,
        }
        self.client.post("/api/annotate", json=payload)