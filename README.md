# Forever Internets

**Automatically reboot your modem and router when your Internet crashes.**

Forever Internets monitors your Internet connection and will restart your modem and router automatically whenever your Internet goes down.

It is intended to be a self-hosted alternative to [ResetPlug](http://resetplug.com).

## Hardware Requirements

- Two TP-Link HS105 smart plugs. HS110 is also likely compatible.
- Static IPs for each smart plug (use static DHCP).

## Software Requirements

- Ruby 2.5+
- Python 2.7

## Usage

```bash
# Install required gems
bundle install

# Run
./forever-internets --help
./forever-internets --modem-plug-ip 10.0.0.11 --router-plug-ip 10.0.0.12
```

## Docker

It is recommended to run this in a [Docker container](https://cloud.docker.com/u/cmer/repository/docker/cmer/forever-internets). See [docker-compose.yml](https://github.com/cmer/forever-internets/blob/master/docker-compose.yml).

## Credits

This uses the excellent TP-Link Python script by Lubomir Stroetmann.


