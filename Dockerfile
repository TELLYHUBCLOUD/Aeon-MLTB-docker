FROM ubuntu:25.04
COPY . .
RUN bash Aeon
COPY requirements.txt .
RUN uv pip install --no-cache-dir -r requirements.txt
