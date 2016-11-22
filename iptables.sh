## Réinitialisation de l'iptables

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -P OUTPUT DROP

## Log des paquets forward
iptables -A FORWARD -j LOG 

## Déclaration des variables
ipDMZ_private="192.168.0.2 192.168.0.3 192.168.0.4"
portHTTPs="80 443"

## Flux du pare-feu

# ID Flux : 19
iptables -A FORWARD -m state --state NEW -p tcp -s 31.33.73.6 -d 200.200.200.200 -o eth0 --sport 1024:65535 --dport 80 -j ACCEPT
 
## Flux du LAN vers DMZ	

# ID Flux : 10, 11, 12
for ip in $ipDMZ_private
do iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.1.99 -d $ip -i eth2 -o eth1 --sport 1024:65535 --dport 22 -j ACCEPT
done

# ID Flux : 13, 14, 15
for ip in $ipDMZ_private
do iptables -A FORWARD -m state --state NEW -p udp -s 192.168.1.99 -d $ip -i eth2 -o eth1 --sport 1024:65535 --dport 161 -j ACCEPT
done

## Flux de DMZ vers LAN

# ID Flux : 8
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.0.4 -d 192.168.1.12 -i eth1 -o eth2 --sport 25 --dport 25 -j ACCEPT

# ID Flux : 9
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.0.3 -d 192.168.1.10 -i eth1 -o eth2 --sport 1024:65535 --dport 3306 -j ACCEPT

## Flux d'Internet vers DMZ

# ID Flux : 1 + NAT
for port in $portHTTPs
do iptables -A FORWARD -m state --state NEW -p tcp -d 31.33.73.3 -i eth0 -o eth1 --sport 1024:65535 --dport $port -j ACCEPT
done
iptables -t nat -A PREROUTING -d 31.33.73.3 -j DNAT --to-destination 192.168.0.3

# ID Flux : 2 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -d 31.33.73.4 -i eth0 -o eth1 --sport 25 --dport 25 -j ACCEPT
iptables -t nat -A PREROUTING -d 31.33.73.4 -j DNAT --to-destination 192.168.0.4

# ID Flux : 3 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -d 31.33.73.2 -i eth0 -o eth1 --sport 1024:65535 --dport 53 -j ACCEPT
iptables -t nat -A PREROUTING -d 31.33.73.2 -j DNAT --to-destination 192.168.0.2

## Flux DMZ vers Internet

# ID Flux : 4 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.0.2 -d 150.150.150.150 -i eth1 -o eth0 --sport 1024:65535 --dport 53 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.0.2 -j SNAT --to-source 31.33.73.2 -d 150.150.150.150

# ID Flux : 5 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.0.2 -d 200.200.200.200 -i eth1 -o eth0 --sport 1024:65535 --dport 80 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.0.2 -j SNAT --to-source 31.33.73.2 -d 200.200.200.200

# ID Flux : 6 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.0.3 -d 200.200.200.200 -i eth1 -o eth0 --sport 1024:65535 --dport 80 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.0.3 -j SNAT --to-source 31.33.73.3 -d 200.200.200.200

# ID Flux : 7 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.0.4 -d 200.200.200.200 -i eth1 -o eth0 --sport 1024:65535 --dport 80 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.0.4 -j SNAT --to-source 31.33.73.4 -d 200.200.200.200


## Flux LAN vers Internet

# ID Flux : 16 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.1.14 -d 150.150.150.150 -i eth1 -o eth0 --sport 1024:65535 --dport 53 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.1.14 -j SNAT --to-source 31.33.73.6 -d 150.150.150.150

# ID Flux : 17 + NAT
for port in $portHTTPs
do iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.1.13 -i eth2 -o eth0 --sport 1024:65535 --dport $port -j ACCEPT
done
iptables -t nat -A POSTROUTING -s 192.168.1.13 -j SNAT --to-source 31.33.73.6

# ID Flux : 18 + NAT
iptables -A FORWARD -m state --state NEW -p tcp -s 192.168.1.12 -i eth2 -o eth0 --sport 25 --dport 25 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.1.12 -j SNAT --to-source 31.33.73.6
