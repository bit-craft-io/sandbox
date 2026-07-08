import requests
import os
import uuid

api_key = 'sk-rI4o2AdfYU7AOe3SxMbEZ7Aas6J-woPHazmk1W3Hi6g'
url = "http://localhost:7860/api/v1/run/chat"

# Request payload configuration
payload = {
    "output_type": "chat",
    "input_type": "chat",
    "input_value": "Hello, how are you?"
}
payload["session_id"] = str(uuid.uuid4())

headers = {"x-api-key": api_key}

try:
    # Send API request
    response = requests.request("POST", url, json=payload, headers=headers)
    response.raise_for_status()  # Raise exception for bad status codes

    # Print response
    print(response.text)

except requests.exceptions.RequestException as e:
    print(f"Error making API request: {e}")
except ValueError as e:
    print(f"Error parsing response: {e}")