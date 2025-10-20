#!/usr/bin/env bash
DNS_IP="${1:-192.168.1.10}"
DOMAIN="${2:-cloudflare.com}"
RUNS="${3:-10}"
for i in $(seq 1 "$RUNS"); do
  dig @"$DNS_IP" "$DOMAIN" +stats | awk '/Query time/{print $4" ms"}'
done
