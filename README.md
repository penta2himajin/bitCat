# bitCat
## setup
### make token.nim to target machine's home directory

### type the commands below
1. Install some package that needs to use this.
```
sudo apt install snap git cron -y
sudo snap install nim-lang --classic
```

2. Write this code to ShellScript file "setup.sh".
```Shell
#! /bin/sh -e

git clone https://github.com/penta2himajin/bitCat
cp token.nim bitCat/src/token.nim
cd bitCat
nimble build_project
cd ..
cp bitCat/bin/bitCat bitCat_exec
sudo rm -rf bitCat
mv bitCat_exec bitCat

crontab -l > temp
echo "* * * * * `pwd`/bitCat" >> temp
crontab -u `whoami` temp
rm temp

rm setup.sh
```

3. Granting authority to the file.
```
chmod 766 setup.sh
```

4. Execute the file.
```sh
sh setup.sh
```
