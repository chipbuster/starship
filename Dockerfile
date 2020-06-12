FROM rust:buster

# Create /src as root
RUN mkdir /src && chmod -R a+w /src

# Install a small set of common dependencies. We're not automated testing against
# these, so we don't care about frozen versions
RUN apt-get update && apt-get install --yes nodejs npm ruby-full\
  python3 php git sudo bash fish zsh curl apt-transport-https vim

RUN curl -L https://github.com/nushell/nushell/releases/download/0.15.0/nu_0_15_0_linux.tar.gz | tar xzf - -C /usr/bin
RUN curl -L https://github.com/redox-os/ion/releases/download/1.0.5/linux-amd64-musl.tar.xz | tar xJf - -C /usr/bin

# Install .NET Core and Powershell Core 7--slightly more convoluted
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt-get update && apt-get install --yes dotnet-sdk-3.1 powershell

# Install hyperfine and ripgrep for easier searching/benchmarking
RUN wget https://github.com/sharkdp/hyperfine/releases/download/v1.10.0/hyperfine_1.10.0_amd64.deb
RUN wget https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb
RUN dpkg -i hyperfine_1.10.0_amd64.deb
RUN dpkg -i ripgrep_12.1.1_amd64.deb

# Create non-root user
RUN useradd -ms /bin/bash nonroot
USER nonroot

# Create blank project
RUN USER=nonroot cargo new --bin /src/starship
WORKDIR /src/starship

# Copy the whole project
COPY . .

RUN cargo build
RUN cargo build --release

USER root

RUN mv /src/starship/target/debug/starship /usr/bin/starship-debug
RUN mv /src/starship/target/release/starship /usr/bin/starship-release
RUN ln -s /usr/bin/starship-debug /usr/bin/starship

USER nonroot
