# BUPT Net Login script

This is a simple login script for both NGW and legacy campus network.

## Getting Started

By default, the script will login then check the login status every 120 seconds, 
you can change it by editing the `CHECK_INTERVAL` in the script.

## Installation

```sh
git clone https://github.com/Henryzhao96/bupt_net_login.git
cd bupt_net_login
vim bupt_net_login.sh
```

Change `USERNAME` and `PASSWORD` to your account.
WHen using `NGW`, edit the `NGW_LINE` as well.

```sh
sudo cp bupt_net_login.sh /usr/local/bin
sudo cp bupt_net_login.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl start bupt_net_login.service && sudo systemctl enable bupt_net_login.service
```

## Contributing

Pull requests and issues are always welcome.

## TODO

- This April, Windows .Net GUI version.
