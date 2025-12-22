# 1) Start from a small Python base image
FROM python:3.11-slim

# 2) Prevent Python from writing .pyc files and enable unbuffered logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 3) Set working directory inside container
WORKDIR /app

# 4) Install system dependencies (psycopg2 needs build deps sometimes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

# 5) Copy dependency file first to leverage Docker cache
# If you use requirements.txt, keep it. If you use pyproject/poetry, tell me.
COPY requirements.txt /app/requirements.txt

# 6) Install Python dependencies
RUN pip install --no-cache-dir -r /app/requirements.txt

# 7) Copy the rest of the code
COPY . /app

# 8) Expose FastAPI port
EXPOSE 8000

# 9) Run the server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
