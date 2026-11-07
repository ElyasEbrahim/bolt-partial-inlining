"""Interpreter workload mix for CPython: calls, objects, dicts, strings,
regular expressions, JSON, sorting, generators and floating point.
Output is deterministic. usage: python bench.py <scale>"""
import json
import re
import sys

scale = int(sys.argv[1]) if len(sys.argv) > 1 else 1


def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)


class Task:
    __slots__ = ("prio", "work", "done")

    def __init__(self, prio, work):
        self.prio, self.work, self.done = prio, work, 0

    def step(self):
        if self.work <= 0:
            return False
        self.work -= 1
        self.done += self.prio
        return True


def scheduler(n):
    tasks = [Task(i % 7 + 1, (i * 37) % 101 + 1) for i in range(200)]
    total, rounds = 0, 0
    while rounds < n:
        progressed = False
        for t in tasks:
            progressed |= t.step()
        if not progressed:
            for i, t in enumerate(tasks):
                t.work = (i * 13 + rounds) % 50 + 1
        total += sum(t.done for t in tasks) % 1000003
        rounds += 1
    return total


def dicts_and_strings(n):
    counts = {}
    words = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta"]
    for i in range(n):
        w = words[i % 7] + str(i % 113)
        counts[w] = counts.get(w, 0) + 1
    s = ",".join(f"{k}={v}" for k, v in sorted(counts.items()))
    return len(s), sum(counts.values())


def regex(n):
    text = " ".join(f"user{i}@example{i % 17}.com id={i * 31}" for i in range(n))
    emails = re.findall(r"[a-z0-9]+@[a-z0-9]+\.com", text)
    ids = sum(int(m.group(1)) for m in re.finditer(r"id=(\d+)", text))
    return len(emails), ids


def json_roundtrip(n):
    data = [{"id": i, "name": f"item{i}", "tags": ["a", "b", str(i % 9)],
             "price": i * 1.25, "ok": i % 3 == 0} for i in range(n)]
    s = json.dumps(data, sort_keys=True)
    back = json.loads(s)
    return len(s), sum(d["id"] for d in back if d["ok"])


def generators(n):
    def gen(k):
        for i in range(k):
            if i % 3:
                yield i * i
    return sum(x % 1009 for x in gen(n))


def nbody(steps):
    bodies = [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 39.47],
              [4.84, -1.16, -0.10, 0.60, 2.81, -0.02, 0.037],
              [8.34, 4.12, -0.40, -1.01, 1.82, 0.008, 0.011],
              [12.89, -15.11, -0.22, 1.08, 0.86, -0.01, 0.0017],
              [15.37, -25.91, 0.17, 0.97, 0.59, -0.03, 0.002]]
    dt = 0.01
    pairs = [(bodies[i], bodies[j]) for i in range(5) for j in range(i + 1, 5)]
    for _ in range(steps):
        for bi, bj in pairs:
            dx, dy, dz = bi[0] - bj[0], bi[1] - bj[1], bi[2] - bj[2]
            d2 = dx * dx + dy * dy + dz * dz
            mag = dt / (d2 * d2 ** 0.5)
            bi[3] -= dx * bj[6] * mag; bj[3] += dx * bi[6] * mag
            bi[4] -= dy * bj[6] * mag; bj[4] += dy * bi[6] * mag
            bi[5] -= dz * bj[6] * mag; bj[5] += dz * bi[6] * mag
        for b in bodies:
            b[0] += dt * b[3]; b[1] += dt * b[4]; b[2] += dt * b[5]
    return f"{bodies[0][0] + bodies[1][1]:.9f}"


print("fib", fib(21 + scale))
print("scheduler", scheduler(3000 * scale))
print("dicts", dicts_and_strings(120000 * scale))
print("regex", regex(12000 * scale))
print("json", json_roundtrip(8000 * scale))
print("generators", generators(300000 * scale))
print("nbody", nbody(12000 * scale))
