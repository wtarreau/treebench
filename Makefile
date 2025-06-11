CFLAGS = -O3 -W -Wall -Wno-unused-parameter -ggdb3 -std=c99

CEB_DIR = ceb
CEB_SRC = $(wildcard $(CEB_DIR)/ceb*.c)
CEB_OBJ = $(CEB_SRC:%.c=%.o)
CEB_LIB = $(CEB_DIR)/libcebtree.a

EB_DIR = eb
EB_SRC = $(wildcard $(EB_DIR)/eb*.c)
EB_OBJ = $(EB_SRC:%.c=%.o)
EB_LIB = $(EB_DIR)/libebtree.a

RB_DIR = rb
RB_SRC = $(wildcard $(RB_DIR)/rb*.c)
RB_OBJ = $(RB_SRC:%.c=%.o)
RB_LIB = $(RB_DIR)/librbtree.a

OBJS = $(CEB_OBJ) $(EB_OBJ) $(RB_OBJ)

WITH_DUMP= -DCEB_ENABLE_DUMP

TEST_BIN += $(addprefix $(CEB_DIR)/,stress-32 stress-u32 stress-64 stress-u64 stress-l stress-ul stress-mb stress-umb stress-st stress-ust)
TEST_BIN += $(addprefix $(EB_DIR)/,stress-32 stress-32i stress-32ge stress-32le stress-64 stress-64i stress-64ge stress-64le stress-mb stress-st)
TEST_BIN += $(addprefix $(EB_DIR)/,stress-u32 stress-u32i stress-u32ge stress-u32le stress-u64 stress-u64i stress-u64ge stress-u64le stress-umb stress-ust)
TEST_BIN += $(addprefix $(CEB_DIR)/,opstime-u32 opstime-u64 opstime-ust)
TEST_BIN += $(addprefix $(EB_DIR)/,opstime-u32 opstime-u64 opstime-ust)

all: test

$(CEB_LIB): $(CEB_OBJ)
	$(AR) rv $@ $^

$(EB_LIB): $(EB_OBJ)
	$(AR) rv $@ $^

$(RB_LIB): $(RB_OBJ)
	$(AR) rv $@ $^

ceb/%.o: ceb/%.c ceb/cebtree-prv.h ceb/_ceb_int.c ceb/_ceb_blk.c ceb/_ceb_str.c ceb/_ceb_addr.c
	$(CC) $(CFLAGS) $(WITH_DUMP) -o $@ -c $<

eb/%.o: eb/%.c eb/%.h eb/ebtree.h
	$(CC) $(CFLAGS) -o $@ -c $<

rb/%.o: rb/%.c rb/%.h
	$(CC) $(CFLAGS) -o $@ -I$(RB_DIR) -c $<

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

eb/stress-32: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-32i: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32i_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32i_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-32ge: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32_lookup_ge(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-32le: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32_lookup_le(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-64: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-64i: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64i_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64i_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-64ge: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64_lookup_ge(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-64le: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64_lookup_le(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-mb: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"ebmbtree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ebmb_node' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=ebmb_insert(r,n,sizeof(long long))' -D'NODE_DEL(r,n)=({ ebmb_delete((n)); (n); })' -D'NODE_FND(r,k)=ebmb_lookup(r,&k,sizeof(long long))' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)'

eb/stress-st: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"ebsttree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ebmb_node' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=ebst_insert(r,n)' -D'NODE_DEL(r,n)=({ ebmb_delete((n)); (n); })' -D'NODE_FND(r,k)=ebst_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -DSTORAGE_STRING=24

eb/stress-u32: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-u32i: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32i_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32i_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-u32ge: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32_lookup_ge(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-u32le: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb32tree.h"' -DDATA_TYPE='unsigned int' -DNODE_TYPE='struct eb32_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb32_insert(r,n)' -D'NODE_DEL(r,n)=({ eb32_delete((n)); (n); })' -D'NODE_FND(r,k)=eb32_lookup_le(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-u64: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-u64i: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64i_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64i_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-u64ge: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64_lookup_ge(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-u64le: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"eb64tree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct eb64_node' -D'SET_KEY(n,k)=(n)->key=k' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=eb64_insert(r,n)' -D'NODE_DEL(r,n)=({ eb64_delete((n)); (n); })' -D'NODE_FND(r,k)=eb64_lookup_le(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-umb: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"ebmbtree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ebmb_node' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=ebmb_insert(r,n,sizeof(long long))' -D'NODE_DEL(r,n)=({ ebmb_delete((n)); (n); })' -D'NODE_FND(r,k)=ebmb_lookup(r,&k,sizeof(long long))' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)'

eb/stress-ust: src/stress.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -pthread -DINCLUDE_FILE='"ebsttree.h"' -DDATA_TYPE='unsigned long long' -DNODE_TYPE='struct ebmb_node' -DROOT_TYPE='struct eb_root' -D'NODE_INS(r,n)=ebst_insert(r,n)' -D'NODE_DEL(r,n)=({ ebmb_delete((n)); (n); })' -D'NODE_FND(r,k)=ebst_lookup(r,k)' -D'NODE_INTREE(n)=(!!(n)->node.leaf_p)' -D'INIT_ROOT(r)=(r.b[1]=(void*)1)' -DSTORAGE_STRING=24
ceb/opstime-u32: src/opstime.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -D'INCLUDE_FILE="cebu32_tree.h"' -D'DATA_TYPE=unsigned int' -D'NODE_TYPE=struct ceb_node' -D'ROOT_TYPE=struct ceb_root*' -D'NODE_INS=cebu32_insert' -D'NODE_DEL=cebu32_delete' -D'NODE_FND=cebu32_lookup' -D'KEY_IS_INT' -D'ROOT_INIT(x)=do{}while(0)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=do{}while(0)'

ceb/opstime-u64: src/opstime.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -D'INCLUDE_FILE="cebu64_tree.h"' -D'DATA_TYPE=unsigned long long' -D'NODE_TYPE=struct ceb_node' -D'ROOT_TYPE=struct ceb_root*' -D'NODE_INS=cebu64_insert' -D'NODE_DEL=cebu64_delete' -D'NODE_FND=cebu64_lookup' -D'KEY_IS_INT' -D'ROOT_INIT(x)=do{}while(0)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=do{}while(0)'

ceb/opstime-ust: src/opstime.c $(CEB_LIB)
	$(CC) $(CFLAGS) -I$(CEB_DIR) -o $@ $< -L$(CEB_DIR) -lcebtree -D'INCLUDE_FILE="cebus_tree.h"' -D'NODE_TYPE=struct ceb_node' -D'ROOT_TYPE=struct ceb_root*' -D'NODE_INS=cebus_insert' -D'NODE_DEL=cebus_delete' -D'NODE_FND=cebus_lookup' -D'KEY_IS_STR' -D'ROOT_INIT(x)=do{}while(0)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=do{}while(0)'

eb/opstime-u32: src/opstime.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -D'INCLUDE_FILE="eb32tree.h"' -D'DATA_TYPE=unsigned int' -D'NODE_TYPE=struct eb32_node' -D'ROOT_TYPE=struct eb_root' -D'NODE_INS(r,n)=eb32_insert(r,n)' -D'NODE_DEL(r,n)=eb32_delete(n)' -D'NODE_FND(r,k)=eb32_lookup(r,k)' -D'KEY_IS_INT' -D'ROOT_INIT(r)=((r)->b[1]=(void*)1)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=(n)->key=k'

eb/opstime-u64: src/opstime.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -D'INCLUDE_FILE="eb64tree.h"' -D'DATA_TYPE=unsigned long long' -D'NODE_TYPE=struct eb64_node' -D'ROOT_TYPE=struct eb_root' -D'NODE_INS(r,n)=eb64_insert(r,n)' -D'NODE_DEL(r,n)=eb64_delete(n)' -D'NODE_FND(r,k)=eb64_lookup(r,k)' -D'KEY_IS_INT' -D'ROOT_INIT(r)=((r)->b[1]=(void*)1)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=(n)->key=k'

eb/opstime-ust: src/opstime.c $(EB_LIB)
	$(CC) $(CFLAGS) -I$(EB_DIR) -o $@ $< -L$(EB_DIR) -lebtree -D'INCLUDE_FILE="ebsttree.h"' -D'NODE_TYPE=struct ebmb_node' -D'ROOT_TYPE=struct eb_root' -D'NODE_INS(r,n)=ebst_insert(r,n)' -D'NODE_DEL(r,n)=ebmb_delete(n)' -D'NODE_FND(r,k)=ebst_lookup(r,k)' -D'KEY_IS_STR' -D'ROOT_INIT(r)=((r)->b[1]=(void*)1)' -D'NODE_INIT(x)=do{}while(0)' -D'SET_KEY(n,k)=do{}while(0)'

clean:
	-rm -fv $(CEB_LIB) $(EB_LIB) $(RB_LIB) $(OBJS) *~ *.rej core $(TEST_BIN) ${EXAMPLES}
	-rm -fv $(addprefix $(CEB_DIR)/,*~ *.rej core) $(addprefix $(EB_DIR)/,*~ *.rej core) $(addprefix $(RB_DIR)/,*~ *.rej core)

ifeq ($(wildcard .git),.git)
VERSION := $(shell [ -d .git/. ] && (git describe --tags --match 'v*' --abbrev=0 | cut -c 2-) 2>/dev/null)
SUBVERS := $(shell comms=`git log --no-merges v$(VERSION).. 2>/dev/null |grep -c ^commit `; [ $$comms -gt 0 ] && echo "-$$comms" )
endif

git-tar: .git
	git archive --format=tar --prefix="cebtree-$(VERSION)/" HEAD | gzip -9 > cebtree-$(VERSION)$(SUBVERS).tar.gz

.PHONY: examples
