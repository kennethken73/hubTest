# Ken Harvey's Makefile


# PROJECT = $(notdir $(PWD))
# longer project name for like-named projects
# in git which originate from separate directories
# -Just name (/home/sov/cpp/classB/test) -> (cpp_classB_test)
_PROJECT=$(subst /,_,$(subst $(HOME),,$(PWD)))
PROJECT=$(_PROJECT:_%=% )

CPPDIR = src/
OBJDIR = $(CPPDIR)obj/
INCDIR = include/
DEPDIR = dep/
TSTDIR = unit_tests/
TSTOBJDIR = $(TSTDIR)obj/
TSTDEPDIR = $(TSTDIR)dep/

LOGDIR = logs/
GDBLOG = gdb.cxx

INPUTDIR = $(CPPDIR)input_files/
INPUTSET := $(wildcard $(INPUTDIR))

# git
GITDIR = git/
BRANCH =
MSG = updated

# clang-format
# code style convention being used:
# choose from LLVM, Google, Chromium, Mozilla, Webkit
STYLE = Google

# ycm location
YCM_GEN_DIR = ~/.vim/bundle/YCM-Generator/

# BOOST_TEST_LOG_LEVEL
# allows command-line setting override, ie:
# 	make LL=warn run_tests
LL = -l message

EXT =.cpp
# EXT = .cxx

CC = g++
CPPFLAGS = -I$(INCDIR)
CPPFLAGS += -std=c++11
CPPFLAGS += -Wall
CPPFLAGS += -pedantic
# CPPFLAGS += -I$(DEPDIR)
CPPFLAGS += -g
# get boost back working..
CPPFLAGS += -lboost_unit_test_framework
CPPFLAGS += -DUNIT_TEST
# CPPFLAGS += -pthread

# I tried having a unit_test only flag.
# TSTFLAG = -DUNIT_TEST

EXECUTABLE=exe
TEST_EXES_=

CPPSET := $(wildcard $(CPPDIR)*$(EXT))
INCSET := $(wildcard $(INCDIR)*.h)
OBJSET := $(CPPSET:$(CPPDIR)%$(EXT)=$(OBJDIR)%.o)
DEPSET := $(OBJSET:$(OBJDIR)%.o=$(DEPDIR)%.d)

TSTSET_ := $(wildcard $(TSTDIR)*$(EXT))

# function main() -should not- be found in tstdir, but filter anyway
# TSTSET = $(filter-out $(shell grep -rl 'main()'),$(TSTSET_))
#
# don't filter main()
TSTSET = $(TSTSET_)

# TSTCPPSET is the list of /src/*.cpp files NOT including any files
# that implement main()
TSTCPPSET = $(filter-out $(shell grep -rl 'main()'),$(CPPSET))
TSTOBJSET := $(TSTSET:$(TSTDIR)%$(EXT)=$(TSTOBJDIR)%.o)
TSTARCSET := $(TSTSET:$(TSTDIR)%$(EXT)=$(TSTOBJDIR)%.a)


$(EXECUTABLE): $(OBJSET)
	$(CC) -o $(EXECUTABLE) $(OBJSET) $(CPPFLAGS)

# ( : : ) static patern rule; the $(OBJDIR) trims %-pattern match
$(OBJSET): $(OBJDIR)%.o: $(CPPDIR)%$(EXT) $(INCDIR)%.h
	$(CC) -c $< -o $@ $(CPPFLAGS);


.PHONY: all new cleanAll depAll \
	run runf clean speak \
	tar tar98 sync \
	unit_tests runTests cleanTests \
	genDeps genTestDeps initDirs \
	debug debugReport \
	val batch formattedRun \
	gitInit gitCheckout gitBranch gitMerge gitReLink \
	gitAddAll gitCommitAll gitStatus gitPush gitQuick \
	dots ycm ctags format documentation \
	submit


# I'd prefer not to do recursive make, but dep_all must be done first
all:
	make -k depAll; \
	make -k; \

# template & unit_tests fresh makes
newTests:
	make cleanAll; \
	make depAll; \
	make ; \
	make unit_tests

# template
new:
	make cleanAll; \
	make depAll; \
	make

cleanAll: clean cleanTests cleanDeps

depAll: cleanDeps genDeps genTestDeps

gitQuick:
	make gitAddAll; \
	make gitCommitAll; \
	make gitPush;

unit_tests: $(TSTARCSET)
	$(foreach file, $(TSTSET), $(CC) -o $(basename $(file)) $(TSTOBJDIR)$(basename $(notdir $(file))).a $(CPPFLAGS);)

# TSTARCSET deps are defined at bottom as result of running genTestDeps
$(TSTARCSET):
	ar rcs $@ $^


$(TSTOBJSET): $(TSTOBJDIR)%.o: $(TSTDIR)%$(EXT)
	$(CC) -c $< -o $@ $(CPPFLAGS);

initDirs:
	mkdir -p $(OBJDIR) $(DEPDIR) $(INCDIR) $(LOGDIR) \
		$(TSTOBJDIR) $(TSTDEPDIR) $(GITDIR);
	mv *$(EXT) $(CPPDIR); mv *.h $(INCDIR); mv *.d $(DEPDIR)

run:
	./$(EXECUTABLE)

runf:
	./$(EXECUTABLE) src/input_files/graphLittle | tee output

runfv:
	valgrind ./$(EXECUTABLE) src/input_files/graphLittle | tee output

runTests:
	$(eval TEST_EXES_ += $(shell find ./$(TSTDIR) -type f -executable))
	$(eval TEST_EXES = $(filter-out ./$(EXECUTABLE),$(TEST_EXES_)))
	$(foreach test, $(TEST_EXES), $(test) $(LL);)


c lean:
	rm -f $(EXECUTABLE); rm -f $(OBJDIR)*.o

cleanTests:
	$(eval TEST_EXES_ += $(shell find ./$(TSTDIR) -type f -executable))
	$(eval TEST_EXES = $(filter-out ./$(EXECUTABLE),$(TEST_EXES_)))
	$(foreach file, $(TEST_EXES), $(shell rm -i $(file)))
	rm -f $(TSTOBJDIR)*.a
	rm -f $(TSTOBJDIR)*.o

cleanDeps:
	rm -f $(DEPDIR)*.d; \
	rm -f $(TSTDEPDIR)*.d; \
	sed -i '1, /^### DEPENDENCIES GENERATED BY THIS MAKEFILE GO BELOW ###$$/!d' Makefile; \

genDeps: $(INCSET)
	rm -f tags; \
	g++ -MM $^ > $(DEPDIR)deps.d; \
	sed -i -e 's/include\//$$(INCDIR)/g' $(DEPDIR)deps.d; \
	sed -i -e '/\.o/ s/^/$$(OBJDIR)/' $(DEPDIR)deps.d; \
	cat $(DEPDIR)deps.d >> Makefile; \
	ctags -R .

genTestDeps: $(TSTSET)
	rm -f tags; \
	g++ -I$(INCDIR) -MM $^ > $(TSTDEPDIR)deps.d; \
	sed -i -e '/\.o/ s/^/$$(TSTOBJDIR)/g' $(TSTDEPDIR)deps.d; \
	sed -i -e 's/\.o/\.a/g' $(TSTDEPDIR)deps.d; \
	sed -i -e 's/unit_tests\//$$(TSTOBJDIR)/g' $(TSTDEPDIR)deps.d; \
	sed -i -e 's/include\//$$(OBJDIR)/g' $(TSTDEPDIR)deps.d; \
	sed -i -e 's/\.cpp/\.o/g' $(TSTDEPDIR)deps.d; \
	sed -i -e 's/\.h/\.o/g' $(TSTDEPDIR)deps.d; \
	cat $(TSTDEPDIR)deps.d >> Makefile; \
	ctags -R .


speak:
	echo $(PROJECT)

tar98:
	sed -i 's/^CPPFLAGS += -lboost_unit_test_framework$$/# CPPFLAGS += -lboost_unit_test_framework/' Makefile; \
	sed -i 's/^CPPFLAGS += -std=c++11$$/# CPPFLAGS += -std=c++11/' Makefile; \
	make clean; \
	tar -C .. --exclude='*/git*' --exclude='*/logs*' --exclude='*/*.sw*' -cz $(PROJECT) -f $(PROJECT).tar.gz

tar:
	sed -i 's/^CPPFLAGS += -lboost_unit_test_framework$$/# CPPFLAGS += -lboost_unit_test_framework/' Makefile; \
	make clean; \
	tar -C .. --exclude='*/git*' --exclude='*/logs*' --exclude='*/*.sw*' -cz $(PROJECT) -f $(PROJECT).tar.gz

sync:
	rsync -av --delete $(PWD) lin:/home/quest/from_sov/code/C++/Jorgensen302

ycm:
	$(YCM_GEN_DIR)config_gen.py .

ctags:
	ctags -R .

# TERM reverts back to xterm-256color on exit!
debug:
	export TERM=screen-256color; \
	date >> $(LOGDIR)$(GDBLOG); \
	cgdb $(EXECUTABLE) -ex 'set logging file $(LOGDIR)$(GDBLOG)' \
	-ex 'set logging on';

debugReport:
	echo "New report:: " >> $(LOGDIR)$(GDBLOG) && \
	date >> $(LOGDIR)$(GDBLOG); \
	gdb $(EXECUTABLE) -ex 'set logging file $(LOGDIR)$(GDBLOG)' \
	-ex 'set pagination off' \
	-ex 'set logging on' \
	-ex 'info functions' \
	-ex 'info variables' \
	-ex 'info sources' \
	-ex 'set pagination on' \
	-ex quit;

val:
	valgrind ./$(EXECUTABLE)

format:
	clang-format -style=$(STYLE) -dump-config > .clang-format

formattedRun:
	./$(EXECUTABLE) $(INPUTSET)

batch:
	./$(EXECUTABLE) $(INPUTDIR)*

# TODO: dots might not be working properly
dots:
	make -k ycm; \
	make -k ctags; \
	make -k format;

# scripts for git that preserve a working and synchronized multi-directory
# approach to c++ versioned development
# NOTE: Makefile itself needs to be git-tracked for current dependencies
gitInit:
	-mkdir git; \
	ln -f $(CPPDIR)* $(GITDIR); ln -f $(INCDIR)* $(GITDIR); \
	ln -f Makefile $(GITDIR); \
	git -C $(GITDIR) init; \
	git -C $(GITDIR) remote add origin git@github.com:kennethken73/$(PROJECT).git; \
	curl -i -H 'Authorization: token $(shell cat ~/.keys/git_token)' -d '{"name": "$(PROJECT)", "private": true}' https://api.github.com/user/repos; \
	git -C $(GITDIR) add .; \
	git -C $(GITDIR) commit -m "initial commit"; \
	git -C $(GITDIR) push -u origin master; \

egit:
	git -C $(GITDIR) remote add origin git@github.com:kennethken73/$(PROJECT).git; \
	curl -i -H 'Authorization: token $(shell cat ~/.keys/git_token)' -d '{"name": "$(PROJECT)", "private": true}' https://api.github.com/user/repos; \

gitCheckout:
	git -C $(GITDIR) checkout $(BRANCH); \
	rm $(CPPDIR)*$(EXT) $(INCDIR)*.h; \
	ln $(GITDIR)*$(EXT) $(CPPDIR); \
	ln $(GITDIR)*.h $(INCDIR); \
	make cleanAll; \
	make genDeps; \
	make; \
	ln -f Makefile $(GITDIR)Makefile; \
	make gitQuick

gitBranch:
	git -C $(GITDIR) checkout -b $(BRANCH); \
	rm $(CPPDIR)*$(EXT) $(INCDIR)*.h; \
	ln $(GITDIR)*$(EXT) $(CPPDIR); \
	ln $(GITDIR)*.h $(INCDIR); \
	make cleanAll; \
	make genDeps; \
	make; \
	ln -f Makefile $(GITDIR)Makefile; \
	git -C $(GITDIR) add .; \
	git -C $(GITDIR) commit -m "setting upstream"; \
	git -C $(GITDIR) push -u origin $(BRANCH); \

gitMerge:
	git -C $(GITDIR) merge $(BRANCH); \
	rm $(CPPDIR)*$(EXT) $(INCDIR)*.h; \
	ln $(GITDIR)*$(EXT) $(CPPDIR); \
	ln $(GITDIR)*.h $(INCDIR); \
	make cleanAll; \
	make genDeps; \
	make; \
	ln -f Makefile $(GITDIR)Makefile; \
	make gitQuick

gitAddAll:
	git -C $(GITDIR) add .; \
	git -C $(GITDIR) status

gitCommitAll:
	git -C $(GITDIR) commit -m "$(MSG)"; \
	git -C $(GITDIR) status

gitStatus:
	git -C $(GITDIR) status

gitPush:
	git -C $(GITDIR) push

gitReLink:
	ln -f $(CPPDIR)* $(GITDIR); ln -f $(INCDIR)* $(GITDIR); \
	ln -f Makefile $(GITDIR)

dox:
	doxygen Doxyfile; \
	cd documentation/latex; \
	pdflatex refman.tex; \
	pdflatex refman.tex; \
	cd ..; \
	ln -s latex/refman.pdf LaTeX.pdf; \
	zathura LaTeX.pdf&

cleanDox:
	rm -r documentation; \
	mkdir -p documentation/latex documentation/html; \
	cp ~/code/C++/snips/header.tex documentation/; \
	cp ~/code/C++/snips/mainpage.md documentation/

submit:
	make clean; \
	mkdir -p ../submit/dep ../submit/include ../submit/src/obj; \
	cp include/* ../submit/include; \
	cp -r src/* ../submit/src; \
	cp Makefile ../submit/; \
	zip -r ../submit.zip ../submit/

edots:
	touch .dir-locals.el; \
	touch .projectile



########### Notes #############
# calling 'make speak' from /git and having it still work
# make -C.. -s speak

# bobby(unlv) might not have boost library available to rebuild tests

#  'tracking' of tags file for each branch
#  NOTE: genDeps also generates tags
#  	 and is done on Branch, Merge, and Checkout,
#  	 but not on Init (as we might not yet compile)
##############################

########### TODO #############
# 1. Integrate doxygen
# 2. Integrate new program: cppcheck
# 3. set noexpandtabs in after/ftplugin/make.vim?
##############################

######### Do Not remove the next line ##################
### DEPENDENCIES GENERATED BY THIS MAKEFILE GO BELOW ###