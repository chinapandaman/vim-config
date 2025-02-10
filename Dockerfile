FROM python:3.12-slim

RUN apt-get update && \
apt-get install -y vim git nodejs npm curl silversearcher-ag universal-ctags && \
npm install -g n && \
n latest && \
pip install pylint pudb

WORKDIR /vim-config
COPY . .
RUN chmod +x /vim-config/entrypoint.sh && \
bash setup.sh

WORKDIR /workspace
ENTRYPOINT ["/vim-config/entrypoint.sh"]
