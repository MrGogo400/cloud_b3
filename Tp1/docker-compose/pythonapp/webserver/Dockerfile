FROM alpine:latest
RUN apk add python3
RUN apk add py3-pip
EXPOSE 8888:8888
WORKDIR /pythonapp/
COPY app/ /pythonapp/
RUN pip3 install -r requirements
CMD ["python3", "app.py"]

