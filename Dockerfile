FROM archlinux/archlinux:latest

# Initialize keys, update, install base packages
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo archlinux-keyring pyside6 \
    nano grub archiso pipewire-jack pacman-contrib starship ripgrep \
    python-gitpython python-rich python-pyxdg python-psutil python-yaml \
    python-six python-pycryptodome python-cachetools \
    python-requests python-zstandard qt6-tools gnu-free-fonts

# Configure pacman/makepkg
RUN sed -i '/^#.*\(VerbosePkgLists\|ILoveCandy\)/s/^#//' /etc/pacman.conf && \
    echo -e '\n[stratos]\nSigLevel = Optional TrustAll\nServer = http://repo.stratos-linux.org/' >> /etc/pacman.conf && \
    sed -i 's/^#*GPGKEY=.*/GPGKEY="19A421C3D15C8B7C672F0FACC4B8A73AB86B9411"/' /etc/makepkg.conf && \
    sed -i 's/^#*\(PACKAGER=\).*/\1"StratOS team <stratos-linux@gmail.com>"/' /etc/makepkg.conf && \
    sed -i 's/purge debug/purge !debug/g' /etc/makepkg.conf

# Fetch additional packages from the StratOS repos
RUN pacman -Sy --noconfirm && \
    pacman -S python-vdf python-inputs python-steam --noconfirm

#RUN curl -s "https://archlinux.org/mirrorlist/?country=IN&country=US&country=DE&country=GB&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -

RUN export TMPFILE="/tmp/ratemir" && \ 
    pacman -S rate-mirrors-bin --noconfirm && \
    touch "$TMPFILE" && \
    rate-mirrors --save="$TMPFILE" --allow-root arch --completion=1 --max-delay=43200 && \
    mv $TMPFILE /etc/pacman.d/mirrorlist

# Fetch from the updated mirrors
RUN pacman -Syy --noconfirm

# Add third-party keys
RUN pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-keys \
    9AE4078033F8024D 647F28654894E3BD457199BE38DBBDC86092693E E78DAE0F3115E06B && \
    pacman-key --lsign-key 9AE4078033F8024D 647F28654894E3BD457199BE38DBBDC86092693E E78DAE0F3115E06B && \
    curl -sS https://github.com/elkowar.gpg | gpg --dearmor | pacman-key --add - && \
    pacman-key --lsign-key elkowar && \
    curl -sS https://github.com/web-flow.gpg | gpg --dearmor | pacman-key --add - && \
    pacman-key --lsign-key web-flow

# Receive and trust Elii Zaretskii's keys (Stratmacs)
RUN gpg --recv E78DAE0F3115E06B && \
    echo -e "trust\n5\ny\nquit" | gpg --batch --command-fd 0 --edit-key E78DAE0F3115E06B

# Create builder user
#RUN useradd -m -s /bin/bash builder && \
#    usermod -aG wheel builder && \
#    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# USER builder
# WORKDIR /workspace
