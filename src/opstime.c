/*
 * tree operation cost measurement tool
 */

#define _GNU_SOURCE

#ifndef INCLUDE_FILE
#error "INCLUDE_FILE not defined"
#endif

#if !defined(KEY_IS_INT) && !defined(KEY_IS_BLK) && !defined(KEY_IS_STR)
#error "Must set one of KEY_IS_INT, KEY_IS_BLK, or KEY_IS_STR"
#endif

#if defined(KEY_IS_INT) && !defined(DATA_TYPE)
#error "DATA_TYPE not defined"
#endif

#ifndef ROOT_TYPE
#error "ROOT_TYPE not defined"
#endif

#ifndef NODE_TYPE
#error "NODE_TYPE not defined"
#endif

#ifndef ROOT_INIT
#error "ROOT_INIT(head) not defined"
#endif

#ifndef NODE_INIT
#error "NODE_INIT(node) not defined"
#endif

#ifndef NODE_INS
#error "NODE_INS(root, node) not defined"
#endif

#ifndef NODE_FND
#error "NODE_FND(root, key) not defined"
#endif

#ifndef NODE_DEL
#error "NODE_DEL(root, node) not defined"
#endif

#include <sys/time.h>

#include <inttypes.h>
#include <pthread.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include INCLUDE_FILE

#define XXH_NO_STREAM
#define XXH_INLINE_ALL // for XXH3
#include "../xxhash/xxhash.h"

#include "../rapidhash/rapidhash.h"

/* Some utility functions */
#if defined(__TINYC__)
#include <stdatomic.h>
#define __atomic_load_n(addr, order) __atomic_load(addr, order)
#define __atomic_store_n(addr, value, order) __atomic_store(addr, value, order)
#define __builtin_trap() abort()
#define __thread
#endif

#ifndef container_of
#define container_of(ptr, type, name) ((type *)(((char *)(ptr)) - ((long)&((type *)0)->name)))
#endif

#define RND32SEED 2463534242U
static __thread uint32_t rnd32seed = RND32SEED;
static inline uint32_t rnd32()
{
	rnd32seed ^= rnd32seed << 13;
	rnd32seed ^= rnd32seed >> 17;
	rnd32seed ^= rnd32seed << 5;
	return rnd32seed;
}

#define RND64SEED 0x9876543210abcdefull
static __thread uint64_t rnd64seed = RND64SEED;
static inline uint64_t rnd64()
{
	rnd64seed ^= rnd64seed << 13;
	rnd64seed ^= rnd64seed >>  7;
	rnd64seed ^= rnd64seed << 17;
	return rnd64seed;
}

static inline unsigned long rndl()
{
	return (sizeof(long) < sizeof(uint64_t)) ? rnd32() : rnd64();
}

/* produce a random between 0 and range+1 */
static inline unsigned int rnd32range(unsigned int range)
{
        unsigned long long res = rnd32();

        res *= (range + 1);
        return res >> 32;
}

static inline struct timeval *tv_now(struct timeval *tv)
{
        gettimeofday(tv, NULL);
        return tv;
}

static inline unsigned long tv_ms_elapsed(const struct timeval *tv1, const struct timeval *tv2)
{
        unsigned long ret;

        ret  = ((signed long)(tv2->tv_sec  - tv1->tv_sec))  * 1000;
        ret += ((signed long)(tv2->tv_usec - tv1->tv_usec)) / 1000;
        return ret;
}

static inline unsigned long long tv_us_elapsed(const struct timeval *tv1, const struct timeval *tv2)
{
        unsigned long ret;

        ret  = ((signed long)(tv2->tv_sec  - tv1->tv_sec))  * 1000000;
        ret += ((signed long)(tv2->tv_usec - tv1->tv_usec));
        return ret;
}

/* Returns the pointer to the '\0' or NULL if not enough space in dst */
char *ulltoa(unsigned long long n, char *dst, ssize_t size)
{
	ssize_t i = 0;
	char *res;

	switch(n) {
	case 10000000000000000000ULL ... 18446744073709551615ULL: i++; /* fall through */
	case 1000000000000000000ULL ... 9999999999999999999ULL: i++; /* fall through */
	case 100000000000000000ULL ... 999999999999999999ULL: i++; /* fall through */
	case 10000000000000000ULL ... 99999999999999999ULL: i++; /* fall through */
	case 1000000000000000ULL ... 9999999999999999ULL: i++; /* fall through */
	case 100000000000000ULL ... 999999999999999ULL: i++; /* fall through */
	case 10000000000000ULL ... 99999999999999ULL: i++; /* fall through */
	case 1000000000000ULL ... 9999999999999ULL: i++; /* fall through */
	case 100000000000ULL ... 999999999999ULL: i++; /* fall through */
	case 10000000000ULL ... 99999999999ULL: i++; /* fall through */
	case 1000000000ULL ... 9999999999ULL: i++; /* fall through */
	case 100000000ULL ... 999999999ULL: i++; /* fall through */
	case 10000000ULL ... 99999999ULL: i++; /* fall through */
	case 1000000ULL ... 9999999ULL: i++; /* fall through */
	case 100000ULL ... 999999ULL: i++; /* fall through */
	case 10000ULL ... 99999ULL: i++; /* fall through */
	case 1000ULL ... 9999ULL: i++; /* fall through */
	case 100ULL ... 999ULL: i++; /* fall through */
	case 10ULL ... 99ULL: i++; /* fall through */
	default: break; /* single char, nothing to add */
	}

	if (i + 2 > size)
		return NULL;

	res = dst + i + 1;
	*res = '\0';
	for (; i >= 0; i--) {
		dst[i] = n % 10ULL + '0';
		n /= 10ULL;
	}
	return res;
}

/* display the message and exit with the code */
__attribute__((noreturn)) void die(int code, const char *format, ...)
{
	va_list args;

	va_start(args, format);
	vfprintf(stderr, format, args);
	va_end(args);
	exit(code);
}

#ifndef NODEBUG
#define BUG_ON(x) do {							\
		if (x) {						\
			fprintf(stderr, "BUG at %s:%d after %lu loops: %s\n", \
				__func__, __LINE__, ctx->loops, #x);	\
			__builtin_trap();				\
		}							\
	} while (0)
#else
#define BUG_ON(x) do { } while (0)
#endif

/* one item in the tree */
struct item {
	NODE_TYPE node;
#if defined(KEY_IS_STR) || defined(KEY_IS_BLK)
	char key[];
#else
	DATA_TYPE key;
#endif
};

/* one entry in the keys table */
struct entry {
	union {
		void *p;              // strdup(), calloc(), etc.
		unsigned long long i; // u64
	} key;
	size_t len;             // key length or size, used for hash calc
	size_t bucket;          // hash bucket number
	struct item *item;      // preallocated node
};

/* worker context */
struct ctx {
	ROOT_TYPE *root;        // hashed roots
	unsigned long buckets;  // number of roots
	struct entry *table;    // keys table
	unsigned long entries;  // number of keys
	/* all timing samples below (one per arg_runs) */
	unsigned long long *ins_times;
	unsigned long long *fnd_times;
	unsigned long long *del_times;
	/* total times below */
	unsigned long long ins; // total time in us for inserts
	unsigned long long fnd; // total time in us for lookups
	unsigned long long del; // total time in us for deletes
};


struct ctx ctx = { };
unsigned int nbentries = 32768;
unsigned int buckets = 1;
unsigned int arg_runs = 1;
unsigned int arg_gmode = 0;  // 0: stdin; 1: random; 2: worst case; 3: ctr (e.g. timers);
unsigned int blksize = 0;
unsigned int hmethod = 0;
unsigned int arg_avg = 0;

/* returns -1/0/1 for a<b, a==b, a>b */
static int ullongcmp(const void *_a, const void *_b)
{
	const unsigned long long a = *(unsigned long long *)_a;
	const unsigned long long b = *(unsigned long long *)_b;

	if (a < b)
		return -1;
	else if (a > b)
		return 1;
	else
		return 0;
}

void usage(const char *name, int ret)
{
	die(ret,
	    "usage: %s [-h] [-d*] [-H buckets] [-n keys] [-l blksize] [-g mode] [-m hmethod] [-r runs] (-a avg] [-s seed]\n"
	    "Generation modes for -g:\n"
	    "  0: read keys from stdin (one per line, default)\n"
	    "  1: pure 64-bit random (default)\n"
	    "  2: worst case 64-bit randoms (e.g. cache DoS)\n"
	    "  3: grouped data (counter, to mimmick timers)\n"
	    "  4: positive random increments (to mimmick sparse timers)\n"
	    "Hashing method for -m (using -H buckets):\n"
	    "  0: zero-cost ideal distribution over buckets (counter)\n"
	    "  1: hash keys using XXH3()\n"
	    "  2: hash keys using rapidhashNano()\n"
	    "Average method for -a:\n"
	    "  0: take the mean value (default)\n"
	    "  1: eliminate the quater min and max and avg over the rest\n"
	    "  2: average\n"
	    "", name);
}

int main(int argc, char **argv)
{
	unsigned long seed = 0;
	char *argv0 = *argv;
	int debug = 0;
	unsigned long long ctr = 0;
	unsigned int idx, run, min, max;
	unsigned long long dur_ins, dur_fnd, dur_del;
	struct timeval beg, end;

	setlinebuf(stdout);

	argv++; argc--;

	while (argc && **argv == '-') {
		if (strcmp(*argv, "-d") == 0) {
			debug++;
		}
		else if (strcmp(*argv, "-H") == 0) {
			if (--argc < 0)
				usage(argv0, 1);
			buckets = atol(*++argv);
		}
		else if (!strcmp(*argv, "-n")) {
			if (--argc < 0)
				usage(argv0, 1);
			nbentries = atol(*++argv);
		}
		else if (!strcmp(*argv, "-l")) {
			if (--argc < 0)
				usage(argv0, 1);
			blksize = atol(*++argv);
		}
		else if (strcmp(*argv, "-g") == 0) {
			if (--argc < 0)
				usage(argv0, 1);
			arg_gmode = atol(*++argv);
		}
		else if (!strcmp(*argv, "-m")) {
			if (--argc < 0)
				usage(argv0, 1);
			hmethod = atol(*++argv);
		}
		else if (!strcmp(*argv, "-r")) {
			if (--argc < 0)
				usage(argv0, 1);
			arg_runs = atol(*++argv);
		}
		else if (!strcmp(*argv, "-a")) {
			if (--argc < 0)
				usage(argv0, 1);
			arg_avg = atol(*++argv);
		}
		else if (!strcmp(*argv, "-s")) {
			if (--argc < 0)
				usage(argv0, 1);
			seed = atol(*++argv);
		}
		else if (strcmp(*argv, "-h") == 0)
			usage(argv0, 0);
		else
			usage(argv0, 1);
		argc--; argv++;
	}

	rnd32seed += seed;
	rnd64seed += seed;

	/* allocate and initialize the root heads */
	ctx.root = calloc(buckets, sizeof(*ctx.root));
	if (!ctx.root)
		die(1, "not enough memory for calloc(root)\n");

	for (idx = 0; idx < buckets; idx++) {
		ROOT_INIT(&ctx.root[idx]);
	}

	/* allocate and initialize the timing tables */
	ctx.ins_times = calloc(arg_runs, sizeof(*ctx.ins_times));
	ctx.fnd_times = calloc(arg_runs, sizeof(*ctx.fnd_times));
	ctx.del_times = calloc(arg_runs, sizeof(*ctx.del_times));
	if (!ctx.ins_times || !ctx.fnd_times || !ctx.del_times)
		die(1, "not enough memory for calloc(ins_times/fnd_times/del_times)\n");

	/* allocate and initialize the table of entries */
	ctx.table = calloc(nbentries, sizeof(*ctx.table));
	if (!ctx.table)
		die(1, "not enough memory for calloc(nbentries)\n");

	/* allocate all nodes */
	for (idx = 0; idx < nbentries; idx++) {
		ctx.table[idx].item = calloc(1, sizeof(*ctx.table[idx].item));
		if (!ctx.table[idx].item)
			die(1, "not enough memory for calloc(item)\n");
		NODE_INIT(&ctx.table[idx].item->node);
	}

	/* fill all nodes */
	for (idx = 0; idx < nbentries; idx++) {
#if defined(KEY_IS_INT)
		unsigned long long v;
		char line[100];

		switch (arg_gmode) {
		case 4:
			v = ctr;
			ctr += 1 + (rnd32() & 255);
			break;
		case 3:
			v = ctr++;
			break;
		case 2:
			v = rnd64();
			v  = (int64_t)v >> (v & 63);
			break;
		case 1:
			v = rnd64();
			break;
		default:
			/* read from stdin */
			if (fgets(line, sizeof(line), stdin) != NULL) {
				char *ret = strchr(line, '\n');
				if (ret)
					*ret = 0;
				v = atoll(line);
			} else {
				/* end reached, stop here! */
				nbentries = idx;
			}
			break;
		}

		if (idx < nbentries) {
			ctx.table[idx].bucket = idx % buckets;
			if (hmethod == 1)
				ctx.table[idx].bucket = XXH3_64bits(&v, sizeof(v)) % buckets;
			else if (hmethod == 2)
				ctx.table[idx].bucket = rapidhashNano(&v, sizeof(v)) % buckets;
			ctx.table[idx].key.i = v;

			ctx.table[idx].item = calloc(1, sizeof(*ctx.table[idx].item));
			if (!ctx.table[idx].item)
				die(1, "not enough memory for calloc(item)\n");

			ctx.table[idx].item->key = v;
			SET_KEY(&ctx.table[idx].item->node, v);
		}

#elif defined(KEY_IS_STR)

		unsigned long long v;
		char line[1024];

		switch (arg_gmode) {
		case 4:
			v = ctr;
			ctr += 1 + (rnd32() & 255);
			ulltoa(v, line, sizeof(line));
			break;
		case 3:
			v = ctr++;
			ulltoa(v, line, sizeof(line));
			break;
		case 2:
			v = rnd64();
			v  = (int64_t)v >> (v & 63);
			ulltoa(v, line, sizeof(line));
			break;
		case 1:
			v = rnd64();
			ulltoa(v, line, sizeof(line));
			break;
		default:
			/* read from stdin */
			if (fgets(line, sizeof(line), stdin) != NULL) {
				char *ret = strchr(line, '\n');
				if (ret)
					*ret = 0;
			} else {
				/* end reached, stop here! */
				nbentries = idx;
			}
			break;
		}
		if (idx < nbentries) {
			ctx.table[idx].len = strlen(line);
			ctx.table[idx].bucket = idx % buckets;
			if (hmethod == 1)
				ctx.table[idx].bucket = XXH3_64bits(line, ctx.table[idx].len) % buckets;
			else if (hmethod == 2)
				ctx.table[idx].bucket = rapidhashNano(line, ctx.table[idx].len) % buckets;
			ctx.table[idx].key.p = strdup(line);
			if (!ctx.table[idx].key.p)
				die(1, "not enough memory for strdup()\n");
			ctx.table[idx].item = calloc(1, sizeof(*ctx.table[idx].item) + ctx.table[idx].len + 1);
			if (!ctx.table[idx].item)
				die(1, "not enough memory for calloc(item)\n");

			SET_KEY(&ctx.table[idx].item->node, ctx.table[idx].item->key);
			memcpy(ctx.table[idx].item->key, ctx.table[idx].key.p, ctx.table[idx].len);
		}
#else
#error "data type not implemented yet"
#endif
	}

	if (debug)
		printf("Initialized %u entries.\n", nbentries);

	dur_ins = dur_fnd = dur_del = 0;

	for (run = 0; run < arg_runs; run++) {
		/* first, insert all nodes */
		if (debug > 1)
			printf("Run #%u... inserting\n", run);

		/* let's measure the time only on the last half, when most of
		 * the tree is already in use.
		 */
		idx = 0;
		for (; idx < nbentries / 2; idx++) {
			unsigned int bucket = ctx.table[idx].bucket;

			if (hmethod == 1) {
#if defined(KEY_IS_INT)
				bucket = XXH3_64bits(&ctx.table[idx].key.i, sizeof(ctx.table[idx].key.i)) % buckets;
#elif defined(KEY_IS_STR)
				bucket = XXH3_64bits(ctx.table[idx].key.p, ctx.table[idx].len) % buckets;
#else
#error "type not implemented yet"
#endif
			}
			else if (hmethod == 2) {
#if defined(KEY_IS_INT)
				bucket = rapidhashNano(&ctx.table[idx].key.i, sizeof(ctx.table[idx].key.i)) % buckets;
#elif defined(KEY_IS_STR)
				bucket = rapidhashNano(ctx.table[idx].key.p, ctx.table[idx].len) % buckets;
#else
#error "type not implemented yet"
#endif
			}

			if (NODE_INS(&ctx.root[bucket], &ctx.table[idx].item->node) != &ctx.table[idx].item->node) {
				if (debug)
					printf("idx %d: dup key %#llx\n", idx, (long long)ctx.table[idx].item->key);
				ctx.table[idx].item = NULL;
			}
		}

		tv_now(&beg);
		for (; idx < nbentries; idx++) {
			unsigned int bucket = ctx.table[idx].bucket;

			if (hmethod == 1) {
#if defined(KEY_IS_INT)
				bucket = XXH3_64bits(&ctx.table[idx].key.i, sizeof(ctx.table[idx].key.i)) % buckets;
#elif defined(KEY_IS_STR)
				bucket = XXH3_64bits(ctx.table[idx].key.p, ctx.table[idx].len) % buckets;
#else
#error "type not implemented yet"
#endif
			}
			else if (hmethod == 2) {
#if defined(KEY_IS_INT)
				bucket = rapidhashNano(&ctx.table[idx].key.i, sizeof(ctx.table[idx].key.i)) % buckets;
#elif defined(KEY_IS_STR)
				bucket = rapidhashNano(ctx.table[idx].key.p, ctx.table[idx].len) % buckets;
#else
#error "type not implemented yet"
#endif
			}
			if (NODE_INS(&ctx.root[bucket], &ctx.table[idx].item->node) != &ctx.table[idx].item->node) {
				if (debug)
					printf("idx %d: dup key %#llx\n", idx, (long long)ctx.table[idx].item->key);
				ctx.table[idx].item = NULL;
			}
		}
		tv_now(&end);
		ctx.ins_times[run] = tv_us_elapsed(&beg, &end);
		ctx.ins += ctx.ins_times[run];

		/* second, look up all nodes */
		if (debug > 1)
			printf("Run #%u... looking up\n", run);

		tv_now(&beg);
		for (idx = 0; idx < nbentries; idx++) {
			unsigned int bucket = ctx.table[idx].bucket;

			if (!ctx.table[idx].item)
				continue;
#if defined(KEY_IS_INT)
			if (hmethod == 1)
				bucket = XXH3_64bits(&ctx.table[idx].key.i, sizeof(ctx.table[idx].key.i)) % buckets;
			else if (hmethod == 2)
				bucket = rapidhashNano(&ctx.table[idx].key.i, sizeof(ctx.table[idx].key.i)) % buckets;
			if (NODE_FND(&ctx.root[bucket], ctx.table[idx].key.i) != &ctx.table[idx].item->node)
#elif defined(KEY_IS_STR)
			if (hmethod == 1)
				bucket = XXH3_64bits(ctx.table[idx].key.p, ctx.table[idx].len) % buckets;
			else if (hmethod == 2)
				bucket = rapidhashNano(ctx.table[idx].key.p, ctx.table[idx].len) % buckets;
			if (NODE_FND(&ctx.root[bucket], ctx.table[idx].key.p) != &ctx.table[idx].item->node)
#else
#error "type not implemented yet"
#endif
				die(1, "failed to find an inserted node\n");
		}
		tv_now(&end);
		ctx.fnd_times[run] = tv_us_elapsed(&beg, &end);
		ctx.fnd += ctx.fnd_times[run];

		/* third, delete all nodes, measure the time only on the first half */
		if (debug > 1)
			printf("Run #%u... deleting\n", run);
		idx = 0;
		tv_now(&beg);
		for (; idx < nbentries / 2; idx++) {
			if (!ctx.table[idx].item)
				continue;
			NODE_DEL(&ctx.root[ctx.table[idx].bucket], &ctx.table[idx].item->node);
		}
		tv_now(&end);

		for (; idx < nbentries; idx++) {
			if (!ctx.table[idx].item)
				continue;
			NODE_DEL(&ctx.root[ctx.table[idx].bucket], &ctx.table[idx].item->node);
		}

		ctx.del_times[run] = tv_us_elapsed(&beg, &end);
		ctx.del += ctx.del_times[run];
	}

	/* sort all times and take the center one to have a mean value */
	qsort(ctx.ins_times, arg_runs, sizeof(*ctx.ins_times), ullongcmp);
	qsort(ctx.fnd_times, arg_runs, sizeof(*ctx.fnd_times), ullongcmp);
	qsort(ctx.del_times, arg_runs, sizeof(*ctx.del_times), ullongcmp);

	if (arg_avg == 0) {
		/* take exactly the mean */
		min = arg_runs / 2; max = arg_runs / 2;
	} else if (arg_avg == 1) {
		/* eliminate 1/4 min and max and avg rest */
		min = arg_runs / 4; max = arg_runs - arg_runs / 4;
		if (arg_runs > 1 && max == arg_runs - 1)
			max--;
		if (arg_runs > 2 && min == 0)
			min++;
	} else {
		/* avg over all values */
		min = 0;
		max = arg_runs - 1;
	}

	run = 0;
	for (idx = min; idx <= max; idx++) {
		dur_ins += ctx.ins_times[idx];
		dur_fnd += ctx.fnd_times[idx];
		dur_del += ctx.del_times[idx];
		run++;
	}

	if (debug)
		printf("## dur_ins=%llu dur_find=%llu dur_del=%llu min=%u max=%u (%u runs)\n",
		       dur_ins, dur_fnd, dur_del, min, max, run);
	if (debug)
		printf("# (operation nbops msec_tot mean_nsec_per_op)*. Tree size: %u..%u\n", nbentries / 2, nbentries);

	printf("ins %u %.3f %.1f    fnd %u %.3f %.1f    del %u %.3f %.1f\n",
	       (nbentries - nbentries / 2), (double)ctx.ins / 1000.0, (double)dur_ins * 1000.0 / (run * (nbentries - nbentries / 2)),
	       (nbentries), (double)ctx.fnd / 1000.0, (double)dur_fnd * 1000.0 / (run * nbentries),
	       (nbentries / 2), (double)ctx.del / 1000.0, (double)dur_del * 1000.0 / (run * (nbentries / 2)));

	return 0;
}
