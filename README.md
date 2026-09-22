# fleet-agent

feeds [rex.wf/status](https://rex.wf/status). bash on a systemd timer: every minute it reads `/proc`, posts one json sample, exits. nothing stays resident.

```sh
curl -fsSL https://raw.githubusercontent.com/rexdotsh/fleet-agent/main/install.sh \
  | sudo FLEET_HOST=media FLEET_KEY=... bash
```

needs `curl`, `openssl`, `jq`. `fleet-agent -n` prints a sample without posting. requests are signed: `hmac-sha256(key, "<ts>.<body>")`.
