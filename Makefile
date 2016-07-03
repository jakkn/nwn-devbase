NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

all: Makefile.dep compile

clean:
	@rm tmp/* -f
# -rm out/*.nss out/*.ncs out/*.ndb tmp/*


srcdirs      := $(shell find src/ -type d)

corefiles    := $(wildcard ../gamedata/override/*.nss)

headers      := $(foreach d,$(srcdirs),$(wildcard $(d)/*.h))
scripts      := $(foreach d,$(srcdirs),$(wildcard $(d)/*.n))
preprocessed := $(addprefix out/,$(addsuffix .nss, $(notdir $(basename $(scripts)))))

srcyaml      := $(foreach d,$(srcdirs),$(wildcard $(d)/*.*.yml))
raw          := $(foreach f, tmp/,$(wildcard $(f)/*))
gff          := $(addprefix out/,$(notdir $(basename $(srcyaml))))
mod          := $(shell find -name *.mod)


# $(corefiles) all .nss files that are provided by NWN itself

# $(headers)   array of header files (.nh, .h) with extension
# $(scripts)   array of all script files (.n) with extension
# $(preprocessed) array of ALL script files that were preprocessed
# $(srcyaml)  .yml-encoded gff files related to scripts
# $(gff)        targets for $srcyaml
#
yml: extract dirtree converttoyml

extract: clean unpack

unpack: $(mod)
	@cd tmp && nwn-erf -x -f ../$^

dirtree: $(raw)
	@for g in $^; do \
	; done

converttoyml: $(raw)
	@for g in $^; do \
		echo nwn-gff -i $$g -o out/`basename $$g .yml` -k yaml ;\
		nwn-gff -i $$g -o out/`basename $$g .yml` -k yaml \
	; done


gff: $(srcyaml)
	@for y in $^; do \
		echo nwn-gff -i $$y -o tmp/`basename $$y` -k gff ;\
		nwn-gff -i $$y -o tmp/`basename $$y .yml` -k gff \
	; done

compile: $(preprocessed) $(objects) $(gff)

.tags: $(headers) $(scripts) $(corefiles)
	@ctags --language-force=c --totals --c-kinds=cdefgmnpstuvx --fields=fksmnSzt $(corefiles) $(scripts) $(headers) .tags