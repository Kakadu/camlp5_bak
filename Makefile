# $Id: Makefile,v 1.26 2007/07/08 18:32:04 deraugla Exp $

include config/Makefile

DIRS=odyl camlp4 meta etc top ocpp lib man
FDIRS=odyl camlp4 meta lib
OPTDIRS=ocaml_stuff lib odyl camlp4 meta compile
SHELL=/bin/sh
COLD_FILES=ocaml_src/camlp4/argl.ml ocaml_src/camlp4/ast2pt.ml ocaml_src/camlp4/ast2pt.mli ocaml_src/camlp4/mLast.mli ocaml_src/camlp4/pcaml.ml ocaml_src/camlp4/pcaml.mli ocaml_src/camlp4/quotation.ml ocaml_src/camlp4/quotation.mli ocaml_src/camlp4/reloc.ml ocaml_src/camlp4/reloc.mli ocaml_src/camlp4/spretty.ml ocaml_src/camlp4/spretty.mli ocaml_src/lib/extfun.ml ocaml_src/lib/extfun.mli ocaml_src/lib/fstream.ml ocaml_src/lib/fstream.mli ocaml_src/lib/gramext.ml ocaml_src/lib/gramext.mli ocaml_src/lib/grammar.ml ocaml_src/lib/grammar.mli ocaml_src/lib/plexer.ml ocaml_src/lib/plexer.mli ocaml_src/lib/stdpp.ml ocaml_src/lib/stdpp.mli ocaml_src/lib/token.ml ocaml_src/lib/token.mli ocaml_src/meta/pa_extend.ml ocaml_src/meta/pa_extend_m.ml ocaml_src/meta/pa_macro.ml ocaml_src/meta/pa_r.ml ocaml_src/meta/pa_rp.ml ocaml_src/meta/pr_dump.ml ocaml_src/meta/q_MLast.ml ocaml_src/odyl/odyl_main.ml ocaml_src/odyl/odyl_main.mli ocaml_src/odyl/odyl.ml
PR_O=pr_o.cmo
DIFF_OPT=

all: out

out: boot/camlp4$(EXE)
	cd ocaml_stuff; $(MAKE)
	set -e; for i in $(DIRS); do cd $$i; $(MAKE) all; cd ..; done

opt:
	cd lib; $(MAKE) opt

opt.opt:
	set -e; for i in $(OPTDIRS); do cd $$i; $(MAKE) opt; cd ..; done

ocaml_src/camlp4/ast2pt.ml:
	@echo "Please run 'configure' first"; exit 2

boot/camlp4$(EXE): $(COLD_FILES)
	cd ocaml_stuff; $(MAKE)
	$(MAKE) clean_cold library_cold compile_cold
	$(MAKE) promote_cold
	$(MAKE) clean_cold clean_hot library

clean_hot:
	cd ocaml_stuff; $(MAKE) clean
	for i in $(DIRS) compile; do (cd $$i; $(MAKE) clean); done

depend:
	cd ocaml_stuff; $(MAKE) depend
	for i in $(DIRS) compile; do (cd $$i; $(MAKE) depend); done

install:
	rm -rf "$(LIBDIR)/camlp4"
	for i in $(DIRS) compile; do (cd $$i; $(MAKE) install BINDIR="$(BINDIR)" LIBDIR="$(LIBDIR)" MANDIR="$(MANDIR)"); done

uninstall:
	rm -rf "$(LIBDIR)/camlp4"
	cd "$(BINDIR)"; rm -f *camlp4* odyl ocpp

clean::
	$(MAKE) clean_hot clean_cold
	rm -f boot/*.cm[oi] boot/camlp4*
	rm -rf boot/SAVED

scratch: clean

always:

# Normal bootstrap

bootstrap: backup promote clean_hot all compare

backup:
	mkdir boot.new
	make mv_cvs FROM=boot TO=boot.new
	mv boot boot.new/SAVED
	mv boot.new boot

restore:
	mv boot/SAVED boot.new
	make mv_cvs FROM=boot TO=boot.new
	rm -rf boot
	mv boot.new boot

promote:
	for i in $(FDIRS); do (cd $$i; $(MAKE) promote); done

compare:
	@if (for i in $(FDIRS); do \
		if (cd $$i; $(MAKE) compare 2>/dev/null); then :; \
		else exit 1; fi; \
	     done); \
	then echo "Fixpoint reached, bootstrap succeeded."; \
	else echo "Fixpoint not reached, try one more bootstrapping cycle."; \
	fi

cleanboot:
	rm -rf boot/SAVED/SAVED


# Core and core bootstrap

coreboot: backup promote clean_hot core compare

core: boot/camlp4$(EXE)
	cd ocaml_stuff; $(MAKE) all
	set -e; for i in $(FDIRS); do cd $$i; $(MAKE) all; cd ..; done

clean_core:
	for i in $(FDIRS); do (cd $$i; $(MAKE) clean); done


# Everything in one command

world:
	$(MAKE) core
	$(MAKE) coreboot all

world.opt:
	$(MAKE) core
	$(MAKE) coreboot all opt opt.opt

library:
	cd lib; $(MAKE) all promote

# Cold start using pure Objective Caml sources

library_cold:
	cd ocaml_src/lib; $(MAKE) all promote

compile_cold:
	cd ocaml_src; set -e; \
	for i in $(FDIRS); do \
	  cd $$i; $(MAKE) all; cd ..; \
	done

promote_cold:
	for i in $(FDIRS); do \
		(cd ocaml_src/$$i; $(MAKE) promote); \
	done

clean_cold:
	for i in $(FDIRS); do \
		(cd ocaml_src/$$i; $(MAKE) clean); \
	done

# Stealing some Ocaml compiler sources

steal:
	cd ocaml_stuff; $(MAKE) steal

compare_stolen:
	cd ocaml_stuff; $(MAKE) compare_stolen

# Bootstrap the sources

TXTGEN=This file has been generated by program: do not edit!

bootstrap_sources:
	rm -rf ocaml_src.new
	$(MAKE) new_sources untouch_sources promote_sources clean_sources

new_sources:
	cd etc; make $(PR_O)
	mkdir ocaml_src.new
	@-for i in $(FDIRS); do \
	  (mkdir ocaml_src.new/$$i; cd ocaml_src.new/$$i; \
	   echo ============================================; \
	   echo ocaml_src.new/$$i/Makefile; \
	   sed 's/# $$Id.*\$$/# $(TXTGEN)/' ../../$$i/Makefile | \
	   sed 's-^TOP=..$$-TOP=../..-' > Makefile; \
	   echo ============================================; \
	   echo ocaml_src.new/$$i/.depend; \
	   cp ../../$$i/.depend .); \
	 done
	@-for i in $(FDIRS); do \
	  (cd $$i; \
	   for j in *.ml*; do \
	     if [ "$$j" != "odyl_config.ml" ]; then \
	       k=$$j; \
	       opt=; \
	       if [ "$$k" = "ast2pt.ml" ]; then \
	         k=ast2pt.ml_$(OVERSION); \
	       fi; \
	       echo ============================================; \
	       echo ocaml_src.new/$$i/$$k; \
	       OTOP=$(OTOP) ../tools/conv.sh $(PR_O) $$opt $$j | \
	       sed 's/$$Id.*\$$/$(TXTGEN)/' > \
	       ../ocaml_src.new/$$i/$$k; \
	     fi; \
	   done); \
	done

compare_sources:
	cd etc; make $(PR_O)
	@-for i in $(FDIRS); do \
	  (cd ocaml_src/$$i; \
	   echo ============================================; \
	   echo ocaml_src/$$i/Makefile; \
	   sed 's/# $$Id.*\$$/# $(TXTGEN)/' ../../$$i/Makefile | \
	   sed 's-^TOP=..$$-TOP=../..-' | diff Makefile -; \
	   echo ============================================; \
	   echo ocaml_src/$$i/.depend; \
	   diff $(DIFF_OPT) . ../../$$i/.depend); \
	 done
	@-for i in $(FDIRS); do \
	  (cd $$i; \
	   for j in *.ml*; do \
	     if [ "$$j" != "odyl_config.ml" ]; then \
	       k=$$j; \
	       opt=; \
	       if [ "$$k" = "ast2pt.ml" ]; then \
	         k=ast2pt.ml_$(OVERSION); \
	       fi; \
	       echo ============================================; \
	       echo ocaml_src/$$i/$$k; \
	       OTOP=$(OTOP) ../tools/conv.sh $(PR_O) $$opt $$j | \
	       sed 's/$$Id.*\$$/$(TXTGEN)/' | \
	       diff $(DIFF_OPT) ../ocaml_src/$$i/$$k -; \
	     fi; \
	   done); \
	done

bootstrap_all_ast2pt:
	cd etc; make $(PR_O)
	@cd camlp4; \
	for i in ../ocaml_src/camlp4/ast2pt.ml_*; do \
	  echo ============================================; \
	  echo $$i; \
	  j=$$(echo $$(basename $$i) | \
	       sed -e 's/ast2pt.ml/OCAML/' -e 's/\./_/g'); \
	  k=$$(echo OCAML_$(OVERSION) | \
	       sed -e 's/ast2pt.ml/OCAML/' -e 's/\./_/g'); \
	  OTOP=$(OTOP) ../tools/conv.sh $(PR_O) -U$$k -D$$j ast2pt.ml | \
	  sed -e 's/\$$Id.*\$$/$(TXTGEN)/' > $$i -; \
	done

compare_all_ast2pt:
	cd etc; make $(PR_O)
	@cd camlp4; \
	for i in ../ocaml_src/camlp4/ast2pt.ml_*; do \
	  echo ============================================; \
	  echo $$i; \
	  j=$$(echo $$(basename $$i) | \
	       sed -e 's/ast2pt.ml/OCAML/' -e 's/\./_/g'); \
	  k=$$(echo OCAML_$(OVERSION) | \
	       sed -e 's/ast2pt.ml/OCAML/' -e 's/\./_/g'); \
	  OTOP=$(OTOP) ../tools/conv.sh $(PR_O) -U$$k -D$$j ast2pt.ml | \
	  sed -e 's/\$$Id.*\$$/$(TXTGEN)/' | diff $$i -; \
	done

untouch_sources:
	@-cd ocaml_src; \
	for i in $(FDIRS); do \
	  for j in $$i/*.ml* $$i/Makefile*; do \
	    if cmp -s $$j ../ocaml_src.new/$$j 2>/dev/null; then \
	      cp -p $$j ../ocaml_src.new/$$j; \
	    fi; \
	  done; \
	done

promote_sources:
	make mv_cvs FROM=ocaml_src TO=ocaml_src.new
	for i in $(FDIRS); do \
		make mv_cvs FROM=ocaml_src/$$i TO=ocaml_src.new/$$i; \
	done
	mv ocaml_src/tools ocaml_src.new/.
	cd ocaml_src; for i in camlp4/ast2pt.ml_*; do \
	  if [ ! -f ../ocaml_src.new/$$i ]; then \
	    mv $$i ../ocaml_src.new/$$i; \
	  fi; \
	done
	mv ocaml_src ocaml_src.new/SAVED
	mv ocaml_src.new ocaml_src

unpromote_sources:
	mv ocaml_src ocaml_src.new
	mv ocaml_src.new/SAVED ocaml_src
	mv ocaml_src.new/tools ocaml_src/.
	for i in $(FDIRS); do \
		make mv_cvs FROM=ocaml_src.new/$$i TO=ocaml_src/$$i; \
	done
	make mv_cvs FROM=ocaml_src.new TO=ocaml_src

clean_sources:
	rm -rf ocaml_src/SAVED/SAVED

printer:
	cd etc; make $(PR_O)

# Utility

mv_cvs:
	test ! -d $(FROM)/CVS || mv $(FROM)/CVS $(TO)/.
	test ! -f $(FROM)/.cvsignore || mv $(FROM)/.cvsignore $(TO)/.

.PHONY: install
