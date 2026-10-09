import socket, re

from skyfield.api import load, EarthSatellite, wgs84
from datetime import timedelta

HOST, PORT = "154.57.164.82", 30133
ts = load.timescale()

def compute_get_sat_location(l1, l2, lat, long):
    sat = EarthSatellite(l1, l2, "SAT", ts)
    station = wgs84.latlon(lat, long)
    now = ts.now()
    end = ts.from_datetime(now.utc_datetime()+ timedelta(hours=24))

    times, events = sat.find_events(station, now, end, altitude_degrees=30.0)
    out, i = [], 0
    while i < len(events) - 2:
        if events[i]  == 0 and events[i + 1] == 1 and events[i + 2] == 2:
            out.append(times[i].utc_strftime("%Y-%m-%dT%H:%M:%SZ"))
            out.append(times[i + 2].utc_strftime("%Y-%m-%dT%H:%M:%SZ"))
        i += 1
    return " ".join(out)

s = socket.create_connection((HOST, PORT), timeout=30)
buf = b""

def recv_payload(marker):
    global buf
    while marker.encode() not in buf:
        buf += s.recv(4096)
    idx = buf.index(marker.encode()) + len(marker.encode())

    data, buf = buf[:idx], buf[idx:]
    return data


while True:
    data = s.recv(4096).decode()
    print(data)

    if "HTB{" in data:
        flag = re.search(r"HTB{.*}", data).group(0)
        print("FLAG:", flag)
        break

    if "Challenge Sat" in data:
        # flujo normal
        lines = data.splitlines()
        l1 = next(l.strip() for l in lines if l.strip().startswith("1 "))
        l2 = next(l.strip() for l in lines if l.strip().startswith("2 "))
        m = re.search(r"\(Lat,Long\):\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)", data)
        ans = compute_get_sat_location(l1, l2, float(m.group(1)), float(m.group(2)))
        s.sendall((ans + '\r\n').encode())
    else:
        # si no hay más challenges y tampoco flag, salir
        break
