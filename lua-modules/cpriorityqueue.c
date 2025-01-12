#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct {
    double runTime;
    int id;
    // 其他字段也可放在这里，如 priority, pointers to lua references, etc.
} PQItem;

typedef struct {
    PQItem *array;  // 堆存储数组
    int size;       // 当前元素数量
    int capacity;   // 数组容量
} PriorityQueue;

//---------------------------
// 堆操作函数 (C层的私有函数)
//---------------------------

// 上浮操作
static void pq_sift_up(PriorityQueue *pq, int idx) {
    while (idx>1) {
        int parent = idx/2;
        if (pq->array[parent].runTime <= pq->array[idx].runTime)
            break;
        // swap
        PQItem tmp = pq->array[parent];
        pq->array[parent] = pq->array[idx];
        pq->array[idx] = tmp;
        idx = parent;
    }
}

// 下沉操作
static void pq_sift_down(PriorityQueue *pq, int idx) {
    int n = pq->size;
    while (1) {
        int left = idx*2;
        int right= idx*2+1;
        int smallest = idx;
        if (left<=n && pq->array[left].runTime < pq->array[smallest].runTime) {
            smallest = left;
        }
        if (right<=n && pq->array[right].runTime < pq->array[smallest].runTime) {
            smallest = right;
        }
        if (smallest==idx) break;
        // swap
        PQItem tmp = pq->array[idx];
        pq->array[idx] = pq->array[smallest];
        pq->array[smallest] = tmp;
        idx = smallest;
    }
}

//---------------------------
// PriorityQueue接口
//---------------------------
static PriorityQueue* pq_create(int cap) {
    PriorityQueue* pq = (PriorityQueue*)malloc(sizeof(PriorityQueue));
    pq->array = (PQItem*)malloc(sizeof(PQItem)*(cap+1)); // 1-based index
    pq->size = 0;
    pq->capacity = cap;
    return pq;
}

static void pq_free(PriorityQueue *pq) {
    if (!pq) return;
    if (pq->array) {
        free(pq->array);
    }
    free(pq);
}

static int pq_push(PriorityQueue *pq, double runTime, int id) {
    if (pq->size >= pq->capacity) {
        // auto expand
        int newcap = pq->capacity*2;
        PQItem *newarr = (PQItem*)realloc(pq->array, sizeof(PQItem)*(newcap+1));
        if (!newarr) return 0; // fail
        pq->array = newarr;
        pq->capacity = newcap;
    }
    pq->size++;
    int idx = pq->size;
    pq->array[idx].runTime = runTime;
    pq->array[idx].id = id;
    pq_sift_up(pq, idx);
    return 1;
}

static int pq_pop(PriorityQueue *pq, double *outVal) {
    if (pq->size==0) {
        return 0; // empty
    }
    // root
    *outVal = pq->array[1].id;
    pq->array[1] = pq->array[pq->size];
    pq->size--;
    if (pq->size>0) {
        pq_sift_down(pq, 1);
    }
    return 1;
}

static int pq_peek(PriorityQueue *pq, double *outVal) {
    if (pq->size==0) {
        return 0;
    }
    *outVal = pq->array[1].id;
    return 1;
}

//---------------------------
// Lua 接口绑定
//---------------------------

static int l_pq_create(lua_State* L) {
    int cap = luaL_optinteger(L, 1, 16);
    PriorityQueue* pq = pq_create(cap);
    // userdatum
    PriorityQueue** ud = (PriorityQueue**)lua_newuserdata(L, sizeof(PriorityQueue*));
    *ud = pq;
    // 设置 metatable
    luaL_getmetatable(L, "CPriorityQueueMT");
    lua_setmetatable(L, -2);
    return 1;
}

static int l_pq_gc(lua_State* L) {
    PriorityQueue** ud = (PriorityQueue**)luaL_checkudata(L, 1, "CPriorityQueueMT");
    if (*ud) {
        pq_free(*ud);
        *ud = NULL;
    }
    return 0;
}

static PriorityQueue* checkQueue(lua_State* L) {
    PriorityQueue** ud = (PriorityQueue**)luaL_checkudata(L, 1, "CPriorityQueueMT");
    luaL_argcheck(L, ud!=NULL && *ud!=NULL, 1, "invalid cpriorityqueue");
    return *ud;
}

static int l_pq_push(lua_State* L) {
    PriorityQueue* pq = checkQueue(L);
    double val = luaL_checknumber(L, 2);
    double id = luaL_checknumber(L, 3);
    int ret = pq_push(pq, val, id);
    lua_pushboolean(L, ret);
    return 1;
}

static int l_pq_pop(lua_State* L) {
    PriorityQueue* pq = checkQueue(L);
    double outVal;
    int ret = pq_pop(pq, &outVal);
    if (!ret) {
        return 0; // return nil
    }
    lua_pushnumber(L, outVal);
    return 1;
}

static int l_pq_peek(lua_State* L) {
    PriorityQueue* pq = checkQueue(L);
    double outVal;
    int ret = pq_peek(pq, &outVal);
    if (!ret) {
        return 0;
    }
    lua_pushnumber(L, outVal);
    return 1;
}

static int l_pq_size(lua_State* L) {
    PriorityQueue* pq = checkQueue(L);
    lua_pushinteger(L, pq->size);
    return 1;
}

//---------------------------
// 模块入口
//---------------------------
static const struct luaL_Reg pq_methods[] = {
    {"push", l_pq_push},
    {"pop",  l_pq_pop},
    {"peek", l_pq_peek},
    {"size", l_pq_size},
    {NULL, NULL}
};

static const luaL_Reg empty_funcs[] = {
   {NULL, NULL}
};

static int l_pq_init(lua_State* L) {
    // create metatable
    luaL_newmetatable(L, "CPriorityQueueMT");
    lua_pushcfunction(L, l_pq_gc);
    lua_setfield(L, -2, "__gc");
    // methods
    lua_newtable(L);
    luaL_setfuncs(L, pq_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pop(L,1);

    // module function
    lua_pushcfunction(L, l_pq_create);
    lua_setfield(L, -2, "create");

    return 1;
}

LUALIB_API int luaopen_cpriorityqueue(lua_State* L) {
    luaL_newlib(L, empty_funcs); // new table
    l_pq_init(L);
    return 1;
}
