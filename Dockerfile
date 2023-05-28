# Application runtime
FROM python:3.8 as base

RUN groupadd mygroup &&\
    useradd -G mygroup -m myuser

RUN mkdir -p /var/opt/myapp &&\
    chown -R myuser:mygroup /var/opt/myapp

WORKDIR /var/opt/myapp

RUN apt-get update
RUN apt-get install -y default-libmysqlclient-dev build-essential

USER myuser

ENV PATH=/home/myuser/.local/bin:$PATH

# Application libraries
FROM base as libraries

COPY requirements.txt requirements.txt
RUN python -m pip install --upgrade pip
RUN python -m pip install --user -r requirements.txt


# Application Service
FROM base

COPY --from=libraries /home/myuser/.local /home/myuser/.local

COPY migrations /var/opt/myapp/migrations
COPY example /var/opt/myapp/example
COPY app.py gunicorn.conf.py entrypoint.sh /var/opt/myapp/

ENTRYPOINT [ "/var/opt/myapp/entrypoint.sh" ]