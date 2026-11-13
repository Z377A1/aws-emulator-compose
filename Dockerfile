# Based on https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-docker.html
FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal

# x86_64 (Intel/AMD) or aarch64 (Apple silicon / Arm). Set EMULATOR_ARCH in .env.
ARG EMULATOR_ARCH=x86_64

# AWS CLI v2, per https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# (zip names use the same x86_64/aarch64 suffixes as the emulator RPM).
ADD https://awscli.amazonaws.com/awscli-exe-linux-${EMULATOR_ARCH}.zip /tmp/awscliv2.zip
# ncurses provides `clear` for interactive shells (missing from the minimal image).
RUN dnf install -y unzip ncurses \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip \
    && dnf remove -y unzip && dnf clean all

ADD https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest/aws-emulator-${EMULATOR_ARCH}.rpm /tmp/aws-emulator.rpm
RUN rpm -i /tmp/aws-emulator.rpm && rm /tmp/aws-emulator.rpm \
    && mkdir -p /home/emulator/.aws/emulator/telemetry && chown -R 1000 /home/emulator

USER 1000
ENV HOME=/home/emulator
EXPOSE 9297
ENTRYPOINT ["aws-emulator", "-b", "0.0.0.0"]
