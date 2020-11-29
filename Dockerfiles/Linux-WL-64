FROM archlinux

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

RUN pacman -Sy --noconfirm git gcc cmake make python

# On first run, wolframscript can be activated like this:
# $ echo -e "$EMAIL\n$PASSWORD\n" | wolframscript
RUN curl -OL https://account.wolfram.com/download/public/wolfram-engine/desktop/LINUX && bash LINUX -- -auto -verbose && rm LINUX && install -Dm755 $(find . -type f -name wolframscript) /usr/bin

CMD ["/usr/bin/bash"]
