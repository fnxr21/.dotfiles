# 9Router

## How to Install

Install 9Router globally with npm:

```bash
npm install -g 9router
```

## How to Run

Start 9Router:

```bash
9router
```

The dashboard will be available at:

```text
http://localhost:20128/dashboard
```

## How to Kill 9Router

Find the process running on port `20128`:

```bash
sudo ss -ltnp 'sport = :20128'
```

Example:

```text
State    Recv-Q    Send-Q    Local Address:Port    Peer Address:Port    Process
LISTEN   0         511       0.0.0.0:20128         0.0.0.0:*            users:(("next-server (v1",pid=151938,fd=21))
```

Find the `pid`:

```text
pid=151938
```

Then kill the process:

```bash
kill 151938
```

Verify that 9Router has stopped:

```bash
sudo ss -ltnp 'sport = :20128'
```

If there is no output, 9Router is no longer running.

