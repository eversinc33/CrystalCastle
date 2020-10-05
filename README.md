<pre>
     ▄▄· ▄▄▄   ▄· ▄▌.▄▄ · ▄▄▄▄▄ ▄▄▄· ▄▄▌   ▄▄·  ▄▄▄· .▄▄ · ▄▄▄▄▄▄▄▌  ▄▄▄ .
    ▐█ ▌▪▀▄ █·▐█▪██▌▐█ ▀. •██  ▐█ ▀█ ██•  ▐█ ▌▪▐█ ▀█ ▐█ ▀. •██  ██•  ▀▄.▀·
    ██ ▄▄▐▀▀▄ ▐█▌▐█▪▄▀▀▀█▄ ▐█.▪▄█▀▀█ ██▪  ██ ▄▄▄█▀▀█ ▄▀▀▀█▄ ▐█.▪██▪  ▐▀▀▪▄
    ▐███▌▐█•█▌ ▐█▀·.▐█▄▪▐█ ▐█▌·▐█ ▪▐▌▐█▌▐▌▐███▌▐█ ▪▐▌▐█▄▪▐█ ▐█▌·▐█▌▐▌▐█▄▄▌
    ·▀▀▀ .▀  ▀  ▀ •  ▀▀▀▀  ▀▀▀  ▀  ▀ .▀▀▀ ·▀▀▀  ▀  ▀  ▀▀▀▀  ▀▀▀ .▀▀▀  ▀▀▀ 

Welcome traveler, to the Crystal Castle, where thy sight shall always be clear...

</pre>

### About

<i>CrystalCastle</i> is a security scanner, that automatically scans hosts for open ports, enumerates the running services and checks for various vulnerabilities, enabling you to have an overview about your network and possible security risks (or make your life easier in hacking challenges such as [HackTheBox](https://hackthebox.eu), by automating the stuff you usually do manually).

This is a work in progress so expect some changes to come.

![Usage](docs/cc.gif)

### Configure

Configuration is done via `worker/config.yml` to set target hosts and scan options and optionally `.db.env` to set database and login credentials. Edit `worker/cronjob` if you want <i>CrystalCastle</i> to run in regular intervals. 

### Run

On your server, run 
```bash
git clone https://github.com/fumamatar/CrystalCastle.git
sudo docker-compose build && sudo docker-compose up
```

Then log in at `SERVER-IP:9292` as (by default) crystal:crystal, start your first scan & wait for the hosts to show up.

### Contribute

If you find a bug, please open an issue (and include the latest logs from `/logs`) and create a pull request if you manage to fix it yourself.
