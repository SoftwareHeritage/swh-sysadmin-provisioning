SWH internal infrastructure preseeding configuration
---------------------------------------------------------

``` shell
./generate_preseed.py \
    -n worker03 \
    --private-mac 52:54:00:1a:85:9e \
    --finish-url http://perso.ensta-paristech.fr/~dandrimont/finish.sh \
    --preseed-template preseed.cfg.tpl \
    --public-mac 52:54:00:be:26:34 \
    --public-ip 128.93.193.23 \
    --public-netmask 255.255.255.0 \
    --public-gateway 128.93.193.254 \
    --public-dns 193.51.196.130
```
