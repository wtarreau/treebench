CFLAGS = -O3 -W -Wall -Wdeclaration-after-statement -Wno-unused-parameter -ggdb3

CEB_DIR = ceb
CEB_SRC = $(wildcard $(CEB_DIR)/ceb*.c)
CEB_OBJ = $(CEB_SRC:%.c=%.o)
CEB_LIB = $(CEB_DIR)/libcebtree.a

OBJS = $(CEB_OBJ)

WITH_DUMP= -DCEB_ENABLE_DUMP

TEST_BIN += $(addprefix $(CEB_DIR)/,stress-32 stress-u32 stress-64 stress-u64 stress-l stress-ul stress-mb stress-umb stress-st stress-ust)
TEST_BIN += $(addprefix $(CEB_DIR)/,opstime-u32 opstime-u64 opstime-ust)

all: test

$(CEB_LIB): $(CEB_OBJ)
	$(AR) rv $@ $^

ceb/%.o: ceb/%.c ceb/cebtree-prv.h ceb/_ceb_int.c ceb/_ceb_blk.c ceb/_ceb_str.c ceb/_ceb_addr.c
	$(CC) $(CFLAGS) $(WITH_DUMP) -o $@ -c $<

test: $(TEST_BIN)

ceb/stress-ul: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebul_tree.h"' -DDATA_TYPE='unsigned long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='cebul_insert' -DNODE_DEL='cebul_delete' -DNODE_FND='cebul_lookup' -DNODE_INTREE='ceb_intree'

ceb/stress-l: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebl_tree.h"' -DDATA_TYPE='unsigned long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='cebl_insert' -DNODE_DEL='cebl_delete' -DNODE_FND='cebl_lookup' -DNODE_INTREE='ceb_intree'

ceb/stress-u32: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebu32_tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='cebu32_insert' -DNODE_DEL='cebu32_delete' -DNODE_FND='cebu32_lookup' -DNODE_INTREE='ceb_intree'

ceb/stress-32: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"ceb32_tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='ceb32_insert' -DNODE_DEL='ceb32_delete' -DNODE_FND='ceb32_lookup' -DNODE_INTREE='ceb_intree'

ceb/stress-u64: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebu64_tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='cebu64_insert' -DNODE_DEL='cebu64_delete' -DNODE_FND='cebu64_lookup' -DNODE_INTREE='ceb_intree'

ceb/stress-64: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"ceb64_tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='ceb64_insert' -DNODE_DEL='ceb64_delete' -DNODE_FND='ceb64_lookup' -DNODE_INTREE='ceb_intree'

ceb/stress-umb: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebub_tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -D'NODE_INS(r,k)=cebub_insert(r,k,sizeof(long long))' -D'NODE_DEL(r,k)=cebub_delete(r,k,sizeof(long long))' -D'NODE_FND(r,k)=cebub_lookup(r,&k,sizeof(long long))' -DNODE_INTREE='ceb_intree'

ceb/stress-mb: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebb_tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -D'NODE_INS(r,k)=cebb_insert(r,k,sizeof(long long))' -D'NODE_DEL(r,k)=cebb_delete(r,k,sizeof(long long))' -D'NODE_FND(r,k)=cebb_lookup(r,&k,sizeof(long long))' -DNODE_INTREE='ceb_intree'

ceb/stress-ust: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebus_tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='cebus_insert' -DNODE_DEL='cebus_delete' -DNODE_FND='cebus_lookup' -DNODE_INTREE='ceb_intree' -DSTORAGE_STRING=21

ceb/stress-st: src/stress.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -pthread -DINCLUDE_FILE='"cebs_tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ceb_node' -DROOT_TYPE='struct ceb_root*' -DNODE_INS='cebs_insert' -DNODE_DEL='cebs_delete' -DNODE_FND='cebs_lookup' -DNODE_INTREE='ceb_intree' -DSTORAGE_STRING=21

ceb/opstime-u32: src/opstime.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -D'INCLUDE_FILE="cebu32_tree.h"' -D'DATA_TYPE=unsigned int' -D'NODE_TYPE=struct ceb_node' -D'ROOT_TYPE=struct ceb_root*' -D'NODE_INS=cebu32_insert' -D'NODE_DEL=cebu32_delete' -D'NODE_FND=cebu32_lookup' -D'KEY_IS_INT' -D'ROOT_INIT(x)=do{}while(0)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=do{}while(0)'

ceb/opstime-u64: src/opstime.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -D'INCLUDE_FILE="cebu64_tree.h"' -D'DATA_TYPE=unsigned long long' -D'NODE_TYPE=struct ceb_node' -D'ROOT_TYPE=struct ceb_root*' -D'NODE_INS=cebu64_insert' -D'NODE_DEL=cebu64_delete' -D'NODE_FND=cebu64_lookup' -D'KEY_IS_INT' -D'ROOT_INIT(x)=do{}while(0)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=do{}while(0)'

ceb/opstime-ust: src/opstime.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -D'INCLUDE_FILE="cebus_tree.h"' -D'NODE_TYPE=struct ceb_node' -D'ROOT_TYPE=struct ceb_root*' -D'NODE_INS=cebus_insert' -D'NODE_DEL=cebus_delete' -D'NODE_FND=cebus_lookup' -D'KEY_IS_STR' -D'ROOT_INIT(x)=do{}while(0)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=do{}while(0)'

clean:
	-rm -fv $(CEB_LIB) $(OBJS) *~ *.rej core $(TEST_BIN) ${EXAMPLES}
	-rm -fv $(addprefix $(CEB_DIR)/,*~ *.rej core)

ifeq ($(wildcard .git),.git)
VERSION := $(shell [ -d .git/. ] && (git describe --tags --match 'v*' --abbrev=0 | cut -c 2-) 2>/dev/null)
SUBVERS := $(shell comms=`git log --no-merges v$(VERSION).. 2>/dev/null |grep -c ^commit `; [ $$comms -gt 0 ] && echo "-$$comms" )
endif

git-tar: .git
	git archive --format=tar --prefix="cebtree-$(VERSION)/" HEAD | gzip -9 > cebtree-$(VERSION)$(SUBVERS).tar.gz

.PHONY: examples
