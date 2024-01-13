FROM hyperpaint/centos:8-base

RUN yum -y install bc nc

RUN mkdir /root/server
RUN curl -vo /root/server-installer.tar.xz -L https://www.factorio.com/get-download/1.1.101/headless/linux64

# Файлы
COPY --chown=root:root --chmod=755 ./files/ /

EXPOSE 34197/udp

# Запуск
WORKDIR /root/server
ENTRYPOINT ["/root/scripts/start.sh"]

# Готовность
HEALTHCHECK CMD ["/root/scripts/healthcheck.sh"]
