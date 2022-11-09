FROM python:3.10-alpine
LABEL maintainer="Luan Vu <luanvudev@gmail.com>"

RUN apk update \
  && apk add \
    build-base
RUN mkdir /usr/src/app
WORKDIR /usr/src/app
COPY ./requirements.txt .
RUN pip install -r requirements.txt
ENV PYTHONUNBUFFERED 1
COPY . .
EXPOSE 5000
ENTRYPOINT [ "lektor" ]