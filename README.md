# bitCat
## setup
Ubuntu
```shellscript
apt install snap git cron -y
snap install nim-lang --classic

git clone https://github.com/penta2himajin/bitCat
cd bitCat
nimble run_project
cp bin/bitCat ../bitCat_exec
cd ~
rm -rf bitCat
mv bitCat_exec bitCat

crontab -l > temp
echo "* * * * * ./bitCat" >> temp
crontab -u `whoami` temp
rm temp
```
