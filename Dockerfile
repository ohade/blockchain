## python:alpine is 3.{latest}
#FROM python:alpine
##FROM tiangolo/uwsgi-nginx-flask:python3.6-alpine3.7
#
#LABEL maintainer="Ohad Edelstein"
#
#RUN apk add build-base
##RUN pip install flask
#
#RUN mkdir -p ./src
#COPY . ./src/
#RUN pip install -r ./src/requirements.txt
#RUN chmod 777 ./src/run-server.sh
#
#EXPOSE 5000
#WORKDIR /src
#CMD ["./run-server.sh"]



FROM tiangolo/uwsgi-nginx-flask:python3.8

LABEL maintainer="Ohad Edelstein"

COPY . /app
RUN pip install -r /app/requirements.txt
