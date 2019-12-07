FROM gcr.io/kubernetes-helm/tiller:v2.14.3 as helm
FROM bitnami/kubectl:1.13.4 as kubectl
FROM velero/velero:v1.1.0 as velero
FROM ubuntu:bionic

RUN apt-get update -y && apt-get install -yqq wget curl git bash-completion

# kubectl
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl

# helm
COPY --from=helm /helm /usr/local/bin/helm

# velero
COPY --from=velero /velero /usr/local/bin/velero

# kube-ps1
RUN ( \
        set -x; cd "$(mktemp -d)" && \
        curl -sS -fsSLO -o - "https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh" && \
        mv kube-ps1.sh /etc/profile.d/99-kubeps1.sh \
    )

# stern
RUN ( \
        set -x; cd "$(mktemp -d)" && \
        curl -fsSLO "https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64" && \
        mv stern_linux_amd64 /usr/local/bin/stern && \
        chmod a+x /usr/local/bin/stern \
    )

COPY 99-k8s-extras.sh /etc/profile.d/99-k8s-extras.sh

RUN addgroup --gid 1000 cicd && adduser --shell /bin/bash --uid 1000 --gid 1000 --gecos '' --disabled-password cicd
USER cicd

# krew / kubens / kubectx (user level)
RUN ( \
        set -x; cd "$(mktemp -d)" && \
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.3.3/krew.{tar.gz,yaml}" && \
        tar zxvf krew.tar.gz && \
        ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
        --manifest=krew.yaml --archive=krew.tar.gz \
    )

# make helm ready for use
RUN helm init --client-only && \
    helm repo remove local && \
    helm repo add incubator https://storage.googleapis.com/kubernetes-charts-incubator && \
    helm repo update

RUN bash -l -c 'kubectl krew update && kubectl krew install ctx && kubectl krew install ns'
RUN echo 'source /etc/profile.d/99-k8s-extras.sh' >> /home/cicd/.bashrc

VOLUME /code
WORKDIR /code
