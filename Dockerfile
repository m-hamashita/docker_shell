# syntax = docker/dockerfile:1.3-labs
ARG KAGGLE_IMAGE=kaggle/python:latest

FROM $KAGGLE_IMAGE AS base

RUN <<EOF
    # fish
    apt-add-repository --yes ppa:fish-shell/release-3
    apt-get update
    apt-get install -y fish vim
    apt-get install language-pack-ja

    # neovim
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

    # bat
    curl -LJO https://github.com/sharkdp/bat/releases/download/v0.20.0/bat-musl_0.20.0_amd64.deb
    dpkg -i bat-musl_0.20.0_amd64.deb

    pip install powerline-status
    # 日本語サポート
    sudo apt-get -y install language-pack-ja
EOF

RUN <<EOF
    # dotfiles
    git clone https://github.com/m-hamashita/dotfiles
    cp -r dotfiles/.config/* ~/.config
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
    echo 'set -x TERM xterm-256color' >> /root/.config/fish/config.fish
    echo 'set -x DENO_INSTALL "/root/.deno"' >> /root/.config/fish/config.fish
    echo 'set -x PATH "$DENO_INSTALL/bin:$PATH"' >> /root/.config/fish/config.fish
    echo 'let g:python3_host_prog = "/opt/conda/bin/python3"' >> /root/.config/nvim/init/common_settings.vim
EOF

RUN <<EOF
    fish -c "fisher install oh-my-fish/theme-bobthefish"
EOF

# for jupyter notebook
RUN <<EOF
    pip install jupyter-contrib-nbextensions
    jupyter contrib nbextension install --user
    jupyter nbextensions_configurator enable --user
    mkdir -p $(jupyter --data-dir)/nbextensions
    cd $(jupyter --data-dir)/nbextensions
    git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding
    pip install jupyterthemes
    jt -t gruvboxd -vim -T -N -f meslo -nf latosans -nfs 10 -tfs 10
    jupyter nbextension enable vim_binding/vim_binding
    pip install isort
    pip install black
    jupyter nbextension enable code_prettify/isort
    jupyter nbextension install https://github.com/drillan/jupyter-black/archive/master.zip --user
    jupyter nbextension enable jupyter-black-master/jupyter-black
    jupyter nbextension enable nbdime/index
    jupyter nbextension enable codefolding/main
EOF

# for tmux
RUN <<EOF
    cp dotfiles/.jupyter/custom/custom.js ~/.jupyter/custom/custom.js
    cp dotfiles/.tmux.conf ~/.tmux.conf
    sed -e 's|source "~/.pyenv/versions/3.8.1/lib/python3.8/site-packages/powerline/bindings/tmux/powerline.conf"|source "/opt/conda/lib/python3.7/site-packages/powerline/bindings/tmux/powerline.conf"|g' ~/.tmux.conf > .tmux.tmp.conf && mv .tmux.tmp.conf ~/.tmux.conf
EOF

RUN nvim --headless -c ':silent! call dein#install()' -c ":silent! call coc#util#install()" -c ":sleep 30" -c ":qa!"

RUN COC_EXTENSIONS=$(nvim --headless +'echo g:coc_global_extensions' +'echo "\n"' +qa 2>&1 \
  | head -1 | tr -d ",[]'" | tr ' ' '\n') \
  && echo "$COC_EXTENSIONS" \
  | xargs -i sh -c 'nvim --headless +"CocInstall -sync {}" +qa 2> /dev/null && echo "{} installed"'

RUN nvim --headless +"CocInstall -sync coc-pyright" +qa
