#!/bin/bash

#Limpar regras antigas
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

#Cria políticas padrões
iptables -P INPUT DROP #Diz que se o pacote não bater com nenhuma regra ele vai ser descartado
iptables -P FORWARD DROP ## Define política padrão DROP para pacotes que apenas atravessam o servidor (roteamento)
iptables -P OUTPUT ACCEPT # Permite todo o tráfego originado pelo servidor


# Loopback
iptables -A INPUT -i lo -j ACCEPT # Permite que a interface de loopback funcione

# Conexões estabelecidas
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT #Permite apenas conexões estabelecidas


#Abre as porta para os serviços
# SSH 
iptables -A INPUT -p tcp --dport 22 -j ACCEPT 

# NTP
iptables -A INPUT -p udp --dport 123 -j ACCEPT


# Webmin
iptables -A INPUT -p tcp --dport 10000 -j ACCEPT

# Observação: as regras de DNS tem a interface ens37 definida para evitar scans vindo da rede externa (internet)
# DNS
iptables -A INPUT -p udp --dport 53 -i ens37 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -i ens37 -j ACCEPT

#Regras de roteamento

# LAN → Internet
iptables -A FORWARD -i ens37 -o ens33 -j ACCEPT

# Internet → LAN (somente conexões já estabelecidas)
iptables -A FORWARD -i ens33 -o ens37 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#Habilita o servidor a fazer NAT

iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
