# syntax = docker/dockerfile:1.3-labs
ARG KAGGLE_IMAGE=kaggle/python:latest

FROM $KAGGLE_IMAGE AS base

# fish, ranger, bat, neovim
RUN <<EOF
    apt-add-repository --yes ppa:fish-shell/release-3
    apt-get update
    apt-get install -y fish vim
    apt-get install language-pack-ja

    pip install ranger-fm
    add-apt-repository --yes ppa:neovim-ppa/unstable
    apt-get update
    apt install -y neovim

    pip install pynvim
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
    sh ./installer.sh ~/.cache/dein

    apt-get install -y nodejs-dev node-gyp libssl1.0-dev
    apt-get install -y npm
    sudo npm install -y n -g
    n lts
    apt purge nodejs npm
    npm install --global yarn
    curl -fsSL https://deno.land/install.sh | sh
    curl -LJO https://github.com/sharkdp/bat/releases/download/v0.20.0/bat-musl_0.20.0_amd64.deb
    dpkg -i bat-musl_0.20.0_amd64.deb
EOF

RUN <<EOF
    git clone https://github.com/m-hamashita/dotfiles
    cp -r dotfiles/.config/* ~/.config
EOF

RUN <<EOF
    git clone https://github.com/github/copilot.vim.git \
      ~/.config/nvim/pack/github/start/copilot.vim
EOF

# config
RUN <<EOF
    echo 'fish' >> /root/.bashrc
    echo 'set -x PATH /usr/local/opt/binutils/bin $PATH' >> /root/.config/fish/config.fish
    echo 'set -x LD_LIBRARY_PATH /usr/lib64-nvidia' >> /root/.config/fish/config.fish
    echo 'set -x PYTHONDONTWRITEBYTECODE 1' >> /root/.config/fish/config.fish
    echo 'set -x TF_CPP_MIN_LOG_LEVEL 2' >> /root/.config/fish/config.fish
    echo 'set -x TERM xterm' >> /root/.config/fish/config.fish
    echo 'set -x DENO_INSTALL "/root/.deno"' >> /root/.config/fish/config.fish
    echo 'set -x PATH "$DENO_INSTALL/bin:$PATH"' >> /root/.config/fish/config.fish
EOF

RUN <<EOF
    fish -c "fisher install oh-my-fish/theme-bobthefish"
EOF
