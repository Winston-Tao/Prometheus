# Makefile for building Lua C modules on macOS (Clang)
# Adjust paths and module names as needed.

# 1) 编译器 & Flags
CC         = clang
CFLAGS     = -O2 -fPIC -Wall
LDFLAGS    = -shared -undefined dynamic_lookup

# 2) Lua 头文件包含路径 (示例: ../lua)
#    若 Skynet 里 Lua 在 3rd/lua/lua-5.4.4/src 等，就相应改一下
INCLUDES   = -I ../lua

# 3) 目标名称、源文件
TARGET     = cpriorityqueue.so
SOURCES    = cpriorityqueue.c

# 如果你有更多模块，可定义多组 TARGET/SOURCES
# e.g. TARGET2=somemodule.so, SOURCES2=somemodule.c

# 4) 默认规则: 编译 .so
all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) $(INCLUDES) $(LDFLAGS) -o $@ $^

# 如果有更多模块:
# $(TARGET2): $(SOURCES2)
# 	$(CC) $(CFLAGS) $(INCLUDES) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)
	# rm -f $(TARGET2) ...
