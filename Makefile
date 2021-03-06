recurfind = $(shell find $(1) -name '$(2)')
HS_SOURCES = $(call recurfind, src/,[^.]*.hs)

METHOD=closure
INPUT_SIZE=10000
CORES=4

.dependencies : DEPENDENCIES
	bin/clone_dependencies.sh
	touch .dependencies

dependencies : .dependencies

cabal.sandbox.config : .dependencies
	bin/add_sources.sh

.cabal-sandbox/bin/supervisor-profile : cabal.sandbox.config distributed-process-platform-profiling.cabal $(HS_SOURCES)
	cabal install --enable-executable-profiling --enable-library-profiling
	@echo '  Ready. Now run `make leaking_examples`'
	@echo '  Then look in out/ for the profile .ps files.'

.PHONY: build
build: .cabal-sandbox/bin/supervisor-profile
.DEFAULT_GOAL := build


profile_cost_centre : .cabal-sandbox/bin/supervisor-profile
	.cabal-sandbox/bin/supervisor-profile $(METHOD) $(INPUT_SIZE) +RTS -hc -N$(CORES)
	hp2ps -c supervisor-profile.hp
	mkdir -p out
	mv supervisor-profile.ps out/supervisor-hc-$(CORES)-$(METHOD)-$(INPUT_SIZE).ps
	rm supervisor-profile.*

leaking_examples :
	make profile_cost_centre METHOD=closure CORES=1 INPUT_SIZE=3000
	# make profile_cost_centre METHOD=send CORES=1 INPUT_SIZE=3000

non_leaking_examples :
	make profile_cost_centre METHOD=closure CORES=4 INPUT_SIZE=2000
	make profile_cost_centre METHOD=send CORES=4 INPUT_SIZE=2000

