# build container containing consul as a "base" image
FROM centos:6
RUN \
  rpm -ivh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
  yum install -y curl wget unzip nc iputils supervisor && \
  wget https://releases.hashicorp.com/consul/0.6.3/consul_0.6.3_linux_amd64.zip -O consul.zip && \
  unzip consul.zip && \
  mv -v consul /usr/bin && \
  rm -v consul.zip && \
  useradd  -c consul\ user -Mr consul && \
  consul version

ADD supervisord.conf /etc/supervisord.conf

VOLUME /var/consul
EXPOSE 8500 8600 8400 8301 8302

CMD [ "/usr/bin/supervisord" ]  

