FROM python:3.6-alpine
WORKDIR /app

ADD requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

CMD [ "tvnamer", "--config", "/app/config.json", "/media/dropbox/tv-series", "-m", "-d", "/media/tv-series/%(seriesname)s/Season %(seasonnumber)02d/" ]
