#!/bin/bash

# u64 timers

for tree in rb eb ceb; do
  for i in {9..20}; do
    l=$((1048576>>i)); [ $l -ge 10 ] || l=10
    echo -n "tmr/1:$tree $i "; taskset -c 0 ./$tree/opstime-u64 -n $((1<<i)) -r $l -g 4;
  done
done

# u64 hashes / rnd

for hash in 1:0 256:1 65536:1; do
  for tree in rb eb ceb; do
    for i in {9..20}; do
      l=$((1048576>>i)); [ $l -ge 10 ] || l=10
      echo -n "u64/${hash%:*}:$tree $i "; taskset -c 0 ./$tree/opstime-u64 -n $((1<<i)) -r $l -H ${hash%:*} -m ${hash#*:} -g 1;
    done
  done
done

# small strings

for hash in 1:0 256:1 65536:1; do
  for tree in rb eb ceb; do
    for i in {9..20}; do
      l=$((1048576>>i)); [ $l -ge 10 ] || l=10
      echo -n "ust/${hash%:*}:$tree $i "; taskset -c 0 ./$tree/opstime-ust -n $((1<<i)) -r $l -H ${hash%:*} -m ${hash#*:} -g 1;
    done
  done
done

# ip client

for hash in 1:0 256:1 65536:1; do
  for tree in rb eb ceb; do
    for i in {9..20}; do
      l=$((1048576>>i)); [ $l -ge 10 ] || l=10
      echo -n "ipv4/${hash%:*}:$tree $i "; taskset -c 0 ./$tree/opstime-u32 -n $((1<<i)) -r $l -H ${hash%:*} -m ${hash#*:} < source-ipv4-u32-rndorder.txt;
    done
  done
done

# UA

for hash in 1:0 256:1 65536:1; do
  for tree in rb eb ceb; do
    for i in {9..16}; do
      l=$((1048576>>i)); [ $l -ge 10 ] || l=10
      echo -n "ua/${hash%:*}:$tree $i "; taskset -c 0 ./$tree/opstime-ust -n $((1<<i)) -r $l -H ${hash%:*} -m ${hash#*:} < ua-dedup-rndorder.txt;
    done
  done
done

