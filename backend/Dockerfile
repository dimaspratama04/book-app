FROM python:3.11-slim AS builder

# install deps
RUN apt-get update && apt-get install -y \
  libpq-dev \
  python3-dev \
  default-libmysqlclient-dev \
  build-essential \
  pkg-config \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# create venv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY ./requirements.txt ./

RUN pip install --no-cache-dir --upgrade pip && \
  pip install --no-cache-dir -r requirements.txt


FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
  libpq5 \
  libmariadb3 \
  cron \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV TZ=Asia/Jakarta

ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app


COPY --from=builder /opt/venv /opt/venv

COPY . .

EXPOSE 5001

CMD ["python", "app.py"]