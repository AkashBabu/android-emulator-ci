FROM ubuntu:18.04
LABEL maintainer="Christopher Bull"

# Android/SDK versions
# Customise these to your requirements
ENV VERSION_SDK_TOOLS "4333796"
ENV VERSION_COMPILE_API "29"
ENV VERSION_BUILD_TOOLS "29.0.2"

# Paths
ENV ANDROID_HOME "/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"
# Emulator snapshot
ENV AVD_NAME "myavd"
ENV SNAPSHOT_NAME "myemulator"
# Optimisations
ENV DEBIAN_FRONTEND noninteractive

# Expect requires tzdata, which requires a timezone specified
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime

RUN apt-get -qq update && \
      apt-get install -qqy --no-install-recommends \
      bridge-utils \
      bzip2 \
      curl \
      # expect: Passing commands to telnet
      expect \
      git-core \
      html2text \
      lib32gcc1 \
      lib32ncurses5 \
      lib32stdc++6 \
      lib32z1 \
      libc6-i386 \
      libqt5svg5 \
      libqt5widgets5 \
      # libvirt-bin: Virtualisation for emulator
      libvirt-bin \
      openjdk-8-jdk \
      # qemu-kvm: Hardware acceleration for emulator
      qemu-kvm \
      # telnet: Communicating with emulator
      telnet \
      # ubuntu-vm-builder: Building VM for emulator
      ubuntu-vm-builder \
      unzip \
      locales \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Configurating Java
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Downloading SDK-tools (AVDManager, SDKManager, etc)
RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-"${VERSION_SDK_TOOLS}".zip > /sdk.zip && \
    unzip -q /sdk.zip -d /sdk && \
    rm -v /sdk.zip

# Add Android licences instead of acceptance
RUN mkdir -p $ANDROID_HOME/licenses/ \
    && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
    && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license

# Download packages
RUN mkdir -p /root/.android && \
    touch /root/.android/repositories.cfg && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --update
RUN ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "build-tools;${VERSION_BUILD_TOOLS}" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "emulator" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "extras;android;m2repository" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "extras;google;m2repository" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "extras;google;google_play_services" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "platform-tools" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --verbose "platforms;android-${VERSION_COMPILE_API}"

# Download system image for compiled version (separate statement for build cache)
RUN echo y | ${ANDROID_HOME}/tools/bin/sdkmanager "system-images;android-${VERSION_COMPILE_API};google_apis;x86_64"

# Accept remaining Android licenses
# Note: Not necessary if licenses were added as files (as above), insted of
# accepting them in the CLI. Uncomment the following line if you added additional
# downloads through sdkmanager (above) that require additional licenses agreed to.
# RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses

# Create AVD
RUN mkdir ~/.android/avd  && \
    echo no | ${ANDROID_HOME}/tools/bin/avdmanager create avd -n ${AVD_NAME} -k "system-images;android-${VERSION_COMPILE_API};google_apis;x86_64"

# Copy scripts to container for running the emulator and creating a snapshot
COPY scripts/* /
