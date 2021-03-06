FROM debian:stretch

LABEL maintainer="Fabrice Jammes <fabrice.jammes@clermont.in2p3.fr>, Benjamin Roziere <benjamin.roziere@clermont.in2p3.fr>"

RUN apt-get -y update && \
    apt-get -y install apt-utils && \
    apt-get -y upgrade && \
    apt-get -y clean

RUN apt-get -y install curl bash-completion git \
    gnupg jq lsb-release mariadb-client \
    openssh-client parallel \
    python3 python3-yaml unzip vim wget && \
    ln -s /usr/bin/python3 /usr/bin/python

# Install Google cloud SDK
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key add - && \
    apt-get -y update && apt-get -y install google-cloud-sdk

# Install kubectl
ENV KUBECTL_VERSION 1.11.0
RUN wget -O /usr/local/bin/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install kubectl aliases
RUN wget -O $HOME/.kubectl_aliases \
    https://rawgit.com/ahmetb/kubectl-alias/master/.kubectl_aliases

# Install terraform
RUN wget -O /tmp/terraform.zip \
    https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/terraform

ENV QSERV_INSTALL_DIR /opt/qserv
ENV PATH="${QSERV_INSTALL_DIR}/bin:${PATH}"
ENV CLUSTER_CONFIG_DIR /qserv-deploy/config
ENV KUBECONFIG "$CLUSTER_CONFIG_DIR"/kubeconfig

WORKDIR /qserv-deploy

# Install kubectl completion
# setup autocomplete in bash, bash-completion package should be installed first.
RUN mkdir .bash && kubectl completion bash > .bash/kubectl.completion

# setup autocomplete in zsh
RUN mkdir .zsh && kubectl completion bash > .zsh/kubectl.completion

COPY rootfs /

RUN ln -s /opt/qserv/k8s/sysadmin /qserv-deploy/sysadmin && \
    ln -s /opt/qserv/k8s/kubectl /qserv-deploy/kubectl
