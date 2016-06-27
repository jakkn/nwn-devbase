NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

all: Makefile.dep compile

clean:
	-rm out/*.nss out/*.ncs out/*.ndb


subdirs := $(shell find . -type d)

corefiles := $(wildcard ../gamedata/override/*.nss)

headers := $(foreach d,$(subdirs),$(wildcard $(d)/*.h))
scripts := $(foreach d,$(subdirs),$(wildcard $(d)/*.n))
preprocessed := $(addprefix out/,$(addsuffix .nss, $(notdir $(basename $(scripts)))))

resources := $(foreach d,$(subdirs),$(wildcard $(d)/*.*.yml))
gff       := $(addprefix out/,$(notdir $(basename $(resources))))
mod       := $(shell find . -name *.mod)


# $(corefiles) all .nss files that are provided by NWN itself

# $(headers)   array of header files (.nh, .h) with extension
# $(scripts)   array of all script files (.n) with extension
# $(preprocessed) array of ALL script files that were preprocessed
# $(resources)  .yml-encoded gff files related to scripts
# $(gff)        targets for $resources
#

extract: $(mod)
	@cd scripts && ./unpack.sh ../$^


gff: $(resources)
	@for g in $^; do \
		echo nwn-gff -i $$g -o out/`basename $$g .yml` ;\
		nwn-gff -i $$g -o out/`basename $$g .yml` \
	; done

compile: $(preprocessed) $(objects) $(gff)

.tags: $(headers) $(scripts) $(corefiles)
	@ctags --language-force=c --totals --c-kinds=cdefgmnpstuvx --fields=fksmnSzt $(corefiles) $(scripts) $(headers) .tags