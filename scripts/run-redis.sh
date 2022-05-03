#!/bin/sh

# server side: install and warmup: run-redish.sh --install --warmup 
# client side: run-redis.sh --server <ip> --load --clients <c> --threads <t> --pipeline <p> --load 
set -eu


CUR_DIR=`pwd`

usage() {
  cat <<EOF
Usage: run-redis.sh [-h] 

Run the memtier benchmark for redis

Available options:

-h, --help       Print this help and exit
--install        Install (run this on server)
--copies         Redis instances default=16 (server or client side)
--warmup         Warmup (run this on server)
--bind           bind redis process to cores, default=false (server side)
--server         server ip, default=localhost (client side arg)
--load           load remote redis with memtier client (client side)
--pipeline       pipeline depth, default=25 (client side)
--clients        num clients, default=1 (client side)
--threads        num threads, default=1 (client side)
--numruns        run count, default=1 (client side)
--duration       test duration per iteration, default=30s (client side)
--tag            optional result directory tag default is none (client side)
EOF
  exit
}

INSTALL=0
WARMUP=0
COPIES=16
PORT=6379
WORKDIR="redis-memtier"
NUMACTL=0
PIPE=25
CLIENTS=1
THREADS=1
SERVER="localhost"
LOAD=0
NUMRUNS=1
DURATION=30
VERSION="6.2.1"
TAG=""
APT=1

parse_params() {


  while [ $# -gt 0 ]; do
    case "${1-}" in
    -h | --help) usage ;;
    --install)
       INSTALL=1
       ;;
    --warmup)
       WARMUP=1
       ;;
    --load)
       LOAD=1
       ;;
    --bind)
       NUMACTL=1
       ;;
    --copies)
      COPIES=${2-}
      shift
      ;;
    --pipeline)
      PIPE=${2-}
      shift
      ;;
    --clients)
      CLIENTS=${2-}
      shift
      ;;
    --threads)
      THREADS=${2-}
      shift
      ;;
    --server)
      SERVER=${2-}
      shift
      ;;
    --numruns)
      NUMRUNS=${2-}
      shift
      ;;
    --duration)
      DURATION=${2-}
      shift
      ;;
    --tag)
      TAG=${2-}
      shift
      ;;
    *) ;; # Skip unknown params
    esac
    shift
  done
}


install_redis(){
   cd "$WORKDIR"
   rm -rf "$VERSION".tar.gz

   if [ $APT -eq 1 ] ; then
      sudo apt-get update -y
      sudo apt install wget build-essential tcl-dev numactl -y
   else
      sudo yum group install "Development Tools" -y
      sudo yum install wget numactl tcl-devel -y
   fi
   wget https://github.com/redis/redis/archive/refs/tags/"$VERSION".tar.gz
   tar -xvzf "$VERSION".tar.gz
   cd redis-"$VERSION"
   make -j8

   #start
   sudo pkill -f redis-server
   sleep 5
   for i in $(seq 1 $COPIES); do
        p=$(( PORT + i - 1))
	pre=""
	if [ $NUMACTL -eq 1 ]; then
	   c=$((i - 1))
	   pre="numactl -C $c"
	fi
        sudo "$pre" ./src/redis-server --port "$p" --protected-mode no --ignore-warnings ARM64-COW-BUG --save  --io-threads 4 --maxmemory-policy noeviction &
   done
   cd "$CUR_DIR"
}

install_memtier(){
  cd "$WORKDIR"
  if [ $APT -eq 1 ]; then
      sudo apt install build-essential libevent-dev pkg-config zlib1g-dev libssl-dev autoconf automake libpcre3-dev -y   
  else
      sudo yum group install "Development Tools" -y
      sudo yum install zlib-devel pcre-devel libmemcached-devel libevent-devel openssl-devel -y	  
  fi

  git clone https://github.com/RedisLabs/memtier_benchmark
  cd memtier_benchmark
  git checkout 793d74dbc09395dfc241342d847730a6197d7c0c
  autoreconf -ivf
  ./configure
  make -j8

  cd "$CUR_DIR"
}

warmup(){
   sudo pkill -f redis-server
   sleep 5
   for i in $(seq 1 $COPIES); do
        p=$(( PORT + i - 1 ))
	pre=""
	if [ $NUMACTL -eq 1 ]; then
	   c=$((i-1))
	   pre="numactl -C $c"
	fi
	echo $pre
	#restart redis
	cmd="${pre} ./${WORKDIR}/redis-${VERSION}/src/redis-server --port ${p} --protected-mode no --ignore-warnings ARM64-COW-BUG --save  --io-threads 4 --maxmemory-policy noeviction"
	${cmd} &
	sleep 1

	#warmup redis
	cmd="./${WORKDIR}/memtier_benchmark/memtier_benchmark --protocol=redis --server localhost --port=${p} -c 1 -t 1 --pipeline 100 --data-size=32 --key-minimum=1 --key-maximum=10000000 --ratio=1:0 --requests=allkeys"
	${cmd} 
   done

}

run_client(){
   if [ ! -f ./${WORKDIR}/memtier_benchmark/memtier_benchmark ]; then
	   mkdir -p $WORKDIR
	   install_memtier
   fi
   WAIT=""
   resdir="redis_res${TAG}/redis_t${THREADS}_c${CLIENTS}_p${PIPE}"
   mkdir -p ${resdir}
   rm -rf ${resdir}/*

   for i in $(seq 1 $COPIES); do
	   p=$(( PORT + i - 1 ))
	   echo $p 
	   
	   cmd="./${WORKDIR}/memtier_benchmark/memtier_benchmark --server ${SERVER} --port ${p} --protocol redis --clients ${CLIENTS} --threads ${THREADS} --ratio 1:9 --data-size 32 --pipeline ${PIPE} --key-minimum 1 --key-maximum 10000000 --key-pattern R:R --run-count ${NUMRUNS} --test-time ${DURATION} --out-file ${resdir}/memtier_${i}.txt --print-percentile 50,90,95,99,99.9 --random-data"
           ${cmd} &
           WAIT="$WAIT""$! "
   done
   wait $WAIT
   
   #tpt="$(grep Totals ${resdir}/* | tail -1 | awk '{SUM+=$2}END{printf("%10d",SUM)}')"
   #p99="$(grep Totals ${resdir}/* | tail -1 | sort -nrk9 | head -1 | awk '{printf("%.2f",$9)}')"
   total=0
   templat=temp.lat
   for f in ${resdir}/*; do
       echo `grep Totals ${f} | awk '{print $2}'`
       tpt="$(grep Totals ${f} | tail -1 | awk '{printf("%10d",$2)}')"
       lat="$(grep Totals ${f} | tail -1 | awk '{printf("%.2f",$9)}')"
       total=$((tpt + total))
       echo $lat >> $templat
   done
   p99=$(sort -n $templat | tail -1)
   rm -rf $templat
   echo "req/sec= $total  p99lat= $p99"
}


parse_params "$@"

if [ $INSTALL -eq 1 ]; then
	rm -rf $WORKDIR
	mkdir -p $WORKDIR
	install_redis
	install_memtier
fi
if [ $WARMUP -eq 1 ]; then
	warmup
fi
if [ $LOAD -eq 1 ]; then
	run_client
fi

