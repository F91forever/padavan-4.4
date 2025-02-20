#!/bin/sh

change_dns() {
  if [ "$(nvram get adg_redirect)" = 1 ]; then
    sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed -i '/server=127.0.0.1/d' /etc/storage/dnsmasq/dnsmasq.conf
    cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
no-resolv
server=127.0.0.1#5335
EOF
    /sbin/restart_dhcpd
    logger -t "AdGuardHome" "添加DNS转发到5335端口"
  fi
}

del_dns() {
  sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
  sed -i '/server=127.0.0.1#5335/d' /etc/storage/dnsmasq/dnsmasq.conf
  /sbin/restart_dhcpd
}

set_iptable()
{
  if [ "$(nvram get adg_redirect)" = 2 ]; then
    IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
    for IP in $IPS
    do
      iptables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
      iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
    done

    IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
    for IP in $IPS
    do
      ip6tables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
      ip6tables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
    done
      logger -t "AdGuardHome" "重定向53端口"
  fi
}

clear_iptable()
{
	OLD_PORT="5335"
	IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
	for IP in $IPS
	do
		iptables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		iptables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done

	IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
	for IP in $IPS
	do
		ip6tables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		ip6tables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done
}

getconfig(){
  adg_file="/etc/storage/AdGuardHome.yaml"
  if [ ! -f "$adg_file" ] || [ ! -s "$adg_file" ] ; then
	  cat > "$adg_file" <<-\EEE
http:
  pprof:
    port: 6060
    enabled: false
  address: 0.0.0.0:3030
  session_ttl: 720h
users:
  - name: admin
    password: $2a$10$aA3rVg6z5A10dr8o9ZpTw.RYfex.wAilzbsz3JFLtDoK5N1.j0jqu
auth_attempts: 5
block_auth_min: 15
http_proxy: ""
language: zh-cn
theme: dark
dns:
  bind_hosts:
    - 0.0.0.0
  port: 5335
  anonymize_client_ip: false
  ratelimit: 0
  ratelimit_subnet_len_ipv4: 24
  ratelimit_subnet_len_ipv6: 56
  ratelimit_whitelist: []
  refuse_any: true
  upstream_dns:
    - 127.0.0.1:6053
  upstream_dns_file: ""
  bootstrap_dns:
    - 119.29.29.29
  fallback_dns:
    - 119.29.29.29
  upstream_mode: parallel
  fastest_timeout: 1s
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts:
    - version.bind
    - id.server
    - hostname.bind
  trusted_proxies:
    - 127.0.0.0/8
    - ::1/128
  cache_size: 0
  cache_ttl_min: 0
  cache_ttl_max: 0
  cache_optimistic: false
  bogus_nxdomain: []
  aaaa_disabled: false
  enable_dnssec: false
  edns_client_subnet:
    custom_ip: ""
    enabled: false
    use_custom: false
  max_goroutines: 300
  handle_ddr: true
  ipset: []
  ipset_file: ""
  bootstrap_prefer_ipv6: false
  upstream_timeout: 10s
  private_networks: []
  use_private_ptr_resolvers: true
  local_ptr_upstreams: []
  use_dns64: false
  dns64_prefixes: []
  serve_http3: false
  use_http3_upstreams: false
  serve_plain_dns: true
  hostsfile_enabled: true
tls:
  enabled: false
  server_name: ""
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  port_dns_over_quic: 853
  port_dnscrypt: 0
  dnscrypt_config_file: ""
  allow_unencrypted_doh: false
  certificate_chain: ""
  private_key: ""
  certificate_path: ""
  private_key_path: ""
  strict_sni_check: false
querylog:
  dir_path: ""
  ignored: []
  interval: 1h
  size_memory: 1000
  enabled: true
  file_enabled: true
statistics:
  dir_path: ""
  ignored: []
  interval: 12h
  enabled: true
filters:
  - enabled: true
    url: https://raw.githubusercontent.com/BlueSkyXN/AdGuardHomeRules/master/skyrules.txt
    name: Blue
    id: 1739238283
  - enabled: true
    url: https://easylist.to/easylist/easyprivacy.txt
    name: easyprivacy
    id: 1739268640
  - enabled: true
    url: https://easylist-downloads.adblockplus.org/easylistchina.txt
    name: easylistchina
    id: 1739268641
  - enabled: true
    url: https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_11_Mobile/filter.txt
    name: mobile
    id: 1739268642
whitelist_filters:
  - enabled: true
    url: https://raw.githubusercontent.com/BlueSkyXN/AdGuardHomeRules/master/ok.txt
    name: ok
    id: 1738938865
user_rules:
  - '@@||ii.gdt.qq.com^$important'
  - '@@||sdkreport.e.qq.com^$important'
  - '@@||oth.bls.mdt.qq.com^$important'
  - '@@||tangram.e.qq.com^$important'
  - '@@||adsmind.gdtimg.com^$important'
  - '@@||pgdt.gtimg.cn^$important'
  - ""
dhcp:
  enabled: false
  interface_name: ""
  local_domain_name: lan
  dhcpv4:
    gateway_ip: ""
    subnet_mask: ""
    range_start: ""
    range_end: ""
    lease_duration: 86400
    icmp_timeout_msec: 1000
    options: []
  dhcpv6:
    range_start: ""
    lease_duration: 86400
    ra_slaac_only: false
    ra_allow_slaac: false
filtering:
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_services:
    schedule:
      time_zone: UTC
    ids: []
  protection_disabled_until: null
  safe_search:
    enabled: false
    bing: true
    duckduckgo: true
    ecosia: true
    google: true
    pixabay: true
    yandex: true
    youtube: true
  blocking_mode: default
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  rewrites: []
  safe_fs_patterns:
    - /tmp/userfilters/*
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  filters_update_interval: 24
  blocked_response_ttl: 60
  filtering_enabled: true
  parental_enabled: false
  safebrowsing_enabled: false
  protection_enabled: true
clients:
  runtime_sources:
    whois: true
    arp: true
    rdns: true
    dhcp: true
    hosts: true
  persistent: []
log:
  enabled: true
  file: ""
  max_backups: 0
  max_size: 100
  max_age: 3
  compress: false
  local_time: false
  verbose: false
os:
  group: ""
  user: ""
  rlimit_nofile: 0
schema_version: 29
EEE
	  chmod 755 "$adg_file"
  fi
}

start_adg(){
  mkdir -p /tmp/AdGuardHome
	mkdir -p /etc/storage/AdGuardHome
 	mount -o remount,size=40M /tmp
	getconfig
	change_dns
	set_iptable
	logger -t "AdGuardHome" "启动 AdGuardHome"
	eval "AdGuardHome -c $adg_file -w /tmp/AdGuardHome" &
}

stop_adg(){
  rm -rf /tmp/AdGuardHome
  logger -t "AdGuardHome" "停止 AdGuardHome"
  killall -9 AdGuardHome
  del_dns
  clear_iptable
}

case $1 in
start)
	start_adg
	;;
stop)
	stop_adg
	;;
*)
	echo "check"
	;;
esac
