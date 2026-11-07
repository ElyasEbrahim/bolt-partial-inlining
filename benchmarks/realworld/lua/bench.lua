-- Interpreter workload mix for the Lua VM: calls, allocation/GC, floating
-- point, strings, tables and method dispatch. Output is deterministic.
-- usage: lua bench.lua <scale>
local scale = tonumber(arg and arg[1]) or 1

local function fib(n)
  if n < 2 then return n end
  return fib(n - 1) + fib(n - 2)
end

local function binarytrees(depth)
  local function make(d)
    if d == 0 then return {} end
    d = d - 1
    return { make(d), make(d) }
  end
  local function check(t)
    if t[1] then return 1 + check(t[1]) + check(t[2]) end
    return 1
  end
  local total = 0
  for d = 4, depth, 2 do
    for _ = 1, 1 << (depth - d + 2) do total = total + check(make(d)) end
  end
  return total
end

local function nbody(steps)
  local bodies = {
    { x = 0, y = 0, z = 0, vx = 0, vy = 0, vz = 0, m = 39.47 },
    { x = 4.84, y = -1.16, z = -0.10, vx = 0.60, vy = 2.81, vz = -0.02, m = 0.037 },
    { x = 8.34, y = 4.12, z = -0.40, vx = -1.01, vy = 1.82, vz = 0.008, m = 0.011 },
    { x = 12.89, y = -15.11, z = -0.22, vx = 1.08, vy = 0.86, vz = -0.01, m = 0.0017 },
    { x = 15.37, y = -25.91, z = 0.17, vx = 0.97, vy = 0.59, vz = -0.03, m = 0.002 },
  }
  local n, dt = #bodies, 0.01
  for _ = 1, steps do
    for i = 1, n do
      local bi = bodies[i]
      for j = i + 1, n do
        local bj = bodies[j]
        local dx, dy, dz = bi.x - bj.x, bi.y - bj.y, bi.z - bj.z
        local d2 = dx * dx + dy * dy + dz * dz
        local mag = dt / (d2 * math.sqrt(d2))
        bi.vx = bi.vx - dx * bj.m * mag; bj.vx = bj.vx + dx * bi.m * mag
        bi.vy = bi.vy - dy * bj.m * mag; bj.vy = bj.vy + dy * bi.m * mag
        bi.vz = bi.vz - dz * bj.m * mag; bj.vz = bj.vz + dz * bi.m * mag
      end
    end
    for i = 1, n do
      local b = bodies[i]
      b.x, b.y, b.z = b.x + dt * b.vx, b.y + dt * b.vy, b.z + dt * b.vz
    end
  end
  return string.format("%.9f", bodies[1].x + bodies[2].y)
end

local function spectralnorm(n)
  local function A(i, j)
    local ij = i + j - 1
    return 1.0 / (ij * (ij - 1) * 0.5 + i)
  end
  local function Av(x, y, N)
    for i = 1, N do
      local a = 0
      for j = 1, N do a = a + x[j] * A(i, j) end
      y[i] = a
    end
  end
  local function Atv(x, y, N)
    for i = 1, N do
      local a = 0
      for j = 1, N do a = a + x[j] * A(j, i) end
      y[i] = a
    end
  end
  local u, v, t = {}, {}, {}
  for i = 1, n do u[i] = 1 end
  for _ = 1, 10 do
    Av(u, t, n); Atv(t, v, n); Av(v, t, n); Atv(t, u, n)
  end
  local vBv, vv = 0, 0
  for i = 1, n do vBv = vBv + u[i] * v[i]; vv = vv + v[i] * v[i] end
  return string.format("%.9f", math.sqrt(vBv / vv))
end

local function strings(n)
  local t = {}
  for i = 1, n do t[#t + 1] = string.format("%d:%s", i, tostring(i * 7)) end
  local s = table.concat(t, ",")
  local c = 0
  for w in s:gmatch("%d+") do c = c + #w end
  return c + #s + #s:upper():gsub("1", "one")
end

local function tables(n)
  local d = {}
  for i = 1, n do
    local k = "k" .. (i % 997)
    d[k] = (d[k] or 0) + i
  end
  local sum = 0
  for _, v in pairs(d) do sum = sum + v end
  local a = {}
  for i = 1, n // 10 do a[i] = (i * 7919) % 1000 end
  table.sort(a)
  return sum + a[#a // 2]
end

local function oop(n)
  local Point = {}
  Point.__index = Point
  function Point.new(x, y) return setmetatable({ x = x, y = y }, Point) end
  function Point:add(o) return Point.new(self.x + o.x, self.y + o.y) end
  function Point:len2() return self.x * self.x + self.y * self.y end
  local p, one, acc = Point.new(0, 0), Point.new(1, 2), 0
  for _ = 1, n do
    p = p:add(one)
    acc = acc + p:len2() % 7
  end
  return acc
end

print("fib", fib(23 + scale))
print("binarytrees", binarytrees(10 + scale))
print("nbody", nbody(40000 * scale))
print("spectralnorm", spectralnorm(60 * scale))
print("strings", strings(60000 * scale))
print("tables", tables(150000 * scale))
print("oop", oop(300000 * scale))
