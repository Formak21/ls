# Paths:
# +------------------------------------------------------+
SRCDIR := ./source
INCDIR := ./include
OUTDIR := ./output
SCRIPTDIR := ./script
EXEDIR := ./bin
# +------------------------------------------------------+

# Files:
# +------------------------------------------------------+
SCRIPTS := $(wildcard $(SCRIPTDIR)/*.sh)

SRCS := $(wildcard $(SRCDIR)/*.c)
INCS := $(wildcard $(INCDIR)/*.h)

DEPS := $(addprefix $(OUTDIR)/, $(addsuffix .d, $(basename $(notdir $(SRCS)))))
OBJS := $(addprefix $(OUTDIR)/, $(addsuffix .o, $(basename $(notdir $(SRCS)))))

EXE := $(EXEDIR)/my-ls
# +------------------------------------------------------+

# Parameters:
# +------------------------------------------------------+
CC := clang
LD := clang

ARCH := arm64

CWFLAGS := -Werror -Wall -Wextra -Wpedantic -Wshadow -Wfloat-equal -Wfloat-conversion -Wstrict-prototypes -Wvla
CIFLAGS := -I$(INCDIR) -I$(SRCDIR)
CFLAGS := -std=c99 -arch $(ARCH) -mcpu=native -march=native -mtune=native -v

LDLIBS := 
LDFLAGS := -arch $(ARCH) -v
# +------------------------------------------------------+

# Goals. Build variants:
# +------------------------------------------------------+
.PHONY : all release debug

all : release

release : CFLAGS += -O2 -DNDEBUG
release : $(EXE)

debug : CFLAGS += -g3 -DDEBUG -D_DEBUG -O0
debug : $(EXE)
# +------------------------------------------------------+s

# Goals. Utils:
# +------------------------------------------------------+
.PHONY : clean

clean :
	-rm -rf $(EXEDIR) $(OUTDIR)

cppcheck :
	cppcheck --exitcode-suppress=missingIncludeSystem --error-exitcode=1 --enable=all --platform=native --std=c99 --check-level=exhaustive $(CIFLAGS) $(INCS) $(SRCS)

clang_format :
	clang-format -style=file:.clang-format -i $(INCS) $(SRCS)

check_clang_format :
	clang-format -style=file:.clang-format -Werror --dry-run $(INCS) $(SRCS)

shellcheck :
	shellcheck --color=always --enable=all $(SCRIPTS)

shfmt :
	shfmt -ln=auto -i=4 -mn -w $(SCRIPTS)

check_build :
	make clean
	@echo "Cleaned."
	@echo "Checking release..."
	make release
	@test -f "$(EXE)" && echo "Release build successful." || (echo "Release build failed." && exit 1)
	make clean
	@echo "Cleaned."
	@echo "Checking debug..."
	make debug
	@test -f "$(EXE)" && echo "Debug build successful." || (echo "Debug build failed." && exit 1)
	make clean
	@echo "Cleaned."
# +------------------------------------------------------+


# Goals, Linking:
# +------------------------------------------------------+
$(EXE) : $(OBJS) | $(EXEDIR)
	$(LD) $(LDFLAGS) $^ $(LDLIBS) -o $@
# +------------------------------------------------------+


# Goals, Building:
# +------------------------------------------------------+
$(OUTDIR)/%.o : $(SRCDIR)/%.c $(OUTDIR)/%.d | $(OUTDIR)
	$(CC) -o $@ -I$(INCDIR) -MMD -MF $(OUTDIR)/$*.d -MT $@ -MP $(CFLAGS) $(CIFLAGS) $(CWFLAGS) -c $<
	-touch $@
# +------------------------------------------------------+

# Goals, Directories:
# +------------------------------------------------------+
$(OUTDIR) :
	-mkdir -p $@

$(EXEDIR) :
	-mkdir -p $@
# +------------------------------------------------------+

# Deps:
# +------------------------------------------------------+
$(DEPS) :

include $(wildcard $(DEPS))
# +------------------------------------------------------+