# install all dependencies 
# Use Python 3.11 slim as the base image for a lightweight container
FROM python:3.11-slim AS builder
# Set the working directory inside the container
WORKDIR /code

# Install system dependencies required by OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libxcb1 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# CPU-only PyTorch
RUN pip install --no-cache-dir \
    torch==2.0.0 \
    torchvision==0.15.1 \
    --index-url https://download.pytorch.org/whl/cpu

# Copy requirements file and install remaining dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# run as non-root 
FROM python:3.11-slim
WORKDIR /code

# Install system dependencies required by OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libxcb1 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the FastAPI application source code into the container
COPY main.py /code

# Copy the pre-trained YOLO model weights into the container
COPY best.pt /code

# Create and switch to non-root user for enhanced security compliance
RUN useradd -m appuser
USER appuser

# Expose port 8000 for the FastAPI service
EXPOSE 8000

# Start the FastAPI application using Uvicorn
# --host 0.0.0.0 allows external connections from outside the container
# --port 8000 matches the exposed port above
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]