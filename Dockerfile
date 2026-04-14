FROM archlinux/archlinux:latest

# Initialize keys, update, install base packages
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo python python-rich python-gitpython archlinux-keyring nano grub archiso

# Configure pacman/makepkg
RUN sed -i '/^#.*\(VerbosePkgLists\|ILoveCandy\)/s/^#//' /etc/pacman.conf && \
    echo -e '\n[stratos]\nSigLevel = Optional TrustAll\nServer = http://repo.stratos-linux.org/' >> /etc/pacman.conf && \
    sed -i 's/^#*GPGKEY=.*/GPGKEY="19A421C3D15C8B7C672F0FACC4B8A73AB86B9411"/' /etc/makepkg.conf && \
    sed -i 's/^#*\(PACKAGER=\).*/\1"StratOS team <stratos-linux@gmail.com>"/' /etc/makepkg.conf && \
    sed -i 's/purge debug/purge !debug/g' /etc/makepkg.conf

RUN pacman -Sy --noconfirm

#RUN curl -s "https://archlinux.org/mirrorlist/?country=IN&country=US&country=DE&country=GB&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -

RUN export TMPFILE="/tmp/ratemir" && \ 
    pacman -S rate-mirrors-bin --noconfirm && \
    touch "$TMPFILE" && \
    rate-mirrors --save="$TMPFILE" --allow-root arch --completion=1 --max-delay=43200 && \
    mv $TMPFILE /etc/pacman.d/mirrorlist

# Fetch from the updated mirrors
# RUN pacman -Sy python-vdf python-inputs python-steam --noconfirm

# Add third-party keys
RUN pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-keys \
    9AE4078033F8024D 647F28654894E3BD457199BE38DBBDC86092693E 17E90D521672C04631B1183EE78DAE0F3115E06B && \
    pacman-key --lsign-key 9AE4078033F8024D 647F28654894E3BD457199BE38DBBDC86092693E 17E90D521672C04631B1183EE78DAE0F3115E06B && \
    curl -sS https://github.com/elkowar.gpg | gpg --dearmor | pacman-key --add - && \
    pacman-key --lsign-key elkowar && \
    curl -sS https://github.com/web-flow.gpg | gpg --dearmor | pacman-key --add - && \
    pacman-key --lsign-key web-flow

# Create builder user
RUN useradd -m -s /bin/bash builder && \
   usermod -aG wheel builder && \
   echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN pacman -Sccc --noconfirm

USER builder
# Receive and trust Elii Zaretskii's keys (Stratmacs)
RUN gpg --recv 17E90D521672C04631B1183EE78DAE0F3115E06B && \
    echo -e "trust\n5\ny\nquit" | gpg --batch --command-fd 0 --edit-key 17E90D521672C04631B1183EE78DAE0F3115E06B

# WORKDIR /workspace
