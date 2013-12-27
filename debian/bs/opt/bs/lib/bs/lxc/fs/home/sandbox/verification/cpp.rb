#!/usr/bin/env ruby

def sb_exec(cmd)
  local_cmd = "su - sandbox -c \"cd /home/sandbox/verification; #{cmd} &>> log.txt\""
  rv = system(local_cmd)
  exit 1 unless rv
end

sb_exec('echo "[--build-solution--]"')
sb_exec('g++ -I/opt/local/include -c solution.cpp')

sb_exec('echo "[--build-verification--]"')
sb_exec('g++ -I/opt/local/include -c verification.cpp')

sb_exec('echo "[--build-linkage--]"')
sb_exec('g++ -o verification solution.o verification.o -lpthread')

sb_exec('echo "[--test--]"')
sb_exec('./verification')

