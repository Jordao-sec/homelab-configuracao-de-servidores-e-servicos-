#!/bin/bash

#Limpar regras antigas
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

#Cria políticas padrões
sudo iptables -P INPUT DROP #Diz que se o pacote não bater com nenhuma regra ele vai ser descartado
sudo iptables -P FORWARD DROP ## Define política padrão DROP para pacotes que apenas atravessam o servidor (roteamento)
sudo iptables -P OUTPUT ACCEPT # Permite todo o tráfego originado pelo servidor


# Loopback
sudo iptables -A INPUT -i lo -j ACCEPT # Permite que a interface de loopback funcione

#Ping
sudo iptables -A INPUT -i icmp -j ACCEPT

# Conexões estabelecidas
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT #Permite apenas conexões estabelecidas


#Abre as porta para os serviços
# SSH 
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# NTP
sudo iptables -A INPUT -p udp --dport 123 -m conntrack --ctstate NEW -j ACCEPT


# Webmin
sudo iptables -A INPUT -p tcp --dport 10000 -m conntrack --ctstate NEW -j ACCEPT

# Observação: as regras de DNS tem a interface ens37 definida para evitar scans vindo da rede externa (internet)
# DNS
sudo iptables -A INPUT -p udp --dport 53 -i ens37 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 53 -i ens37 -m conntrack --ctstate NEW -j ACCEPT

#Regras de roteamento

# LAN → Internet
sudo iptables -A FORWARD -i ens37 -o ens33 -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

# Internet → LAN (somente conexões já estabelecidas)
sudo iptables -A FORWARD -i ens33 -o ens37 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#Habilita o servidor a fazer NAT

sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
