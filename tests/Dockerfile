FROM python:3
RUN apt-get update
RUN apt-get install -y apt-get install -y libnss-db libdb-dev libcurl4-gnutls-dev libgnutls28-dev libldap2-dev libsasl2-dev
RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/
RUN pip install -r requirements.txt
Add .tests /code/tests
RUN chmod +x /code/tets/samba.sh
RUN /code/tets/samba.sh
ADD . /code/
RUN sudo $(which python3) $(which nsscache) -c tests/nsscache.conf --debug verify
RUN sudo $(which python3) $(which nsscache) -c tests/nsscache.conf --debug update --full

LABEL com.circleci.preserve-entrypoint=true
ENTRYPOINT code
