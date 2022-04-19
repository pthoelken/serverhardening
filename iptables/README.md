# Current State / Mode
* in development / not released

# How to work with "blacklister.py"?
* `sudo apt update`
* `sudo apt -y install python3 python3-setuptools python3-pip git iptables iptables-persistent`
* `sudo git clone https://github.com/pthoelken/serverhardening.git`
* `cd serverhardening/iptables`
* `sudo pip3 install -r requirements.txt`
* `sudo python3 blacklister.py`

# How to run the blacklister automatically?
* `sudo nano /etc/crontab`
* Add in end of the file your crontab for example every night at midnight:
* * `0 0 * * *   root    python3 /your/path/to/serverhardening/iptables/blacklister.py`