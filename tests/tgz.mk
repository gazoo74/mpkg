#
# Copyright 2016-2017 Gaël PORTAY <gael.portay@gmail.com>
#
# Licensed under the MIT license.
#

bindir		?= /usr/bin
sbindir		?= /usr/sbin
LOCALSTATEDIR	?= /var/lib/mpkg

.PHONY: all
all:

.PHONY: clean
clean:

define do_pkg_run_deps
ifneq (,$($(1)-deps))
$(foreach pkg,$($(1)-deps),$(eval $(call do_pkg_run_deps,$(pkg))))
pkg-m		+= $($(1)-deps)
endif
endef

$(foreach pkg,$(pkg-m),$(eval $(call do_pkg_run_deps,$(pkg))))
pkg-m		:= $(sort $(pkg-m))

define do_install_file =
.SILENT: $(TGZDIR)$(1)_$(2)/$(3)/$(notdir $(4))
$(TGZDIR)$(1)_$(2)/$(3)/$(notdir $(4)): $(4)
	install -D -m 755 $$< $$@

$(TGZDIR)$(1)_$(2).tgz: $(TGZDIR)$(1)_$(2)/$(3)/$(notdir $(4))
endef

define do_install_dir =
.SILENT: $(TGZDIR)$(1)_$(2)/$(3)
$(TGZDIR)$(1)_$(2)/$(3):
	install -d -m 644 $$@/

$(TGZDIR)$(1)_$(2).tgz: $(TGZDIR)$(1)_$(2)/$(3)
endef

define do_pkg_script =
ifneq (,$($(1)-$(2)-$(3)))
.SILENT: $(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/$(notdir $(3))
$(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/$(notdir $(3)): $($(1)-$(2)-$(3))
	install -D -m 755 $$< $$@

$(TGZDIR)$(1)_$(2).tgz: $(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/$(notdir $(3))
else ifneq (,$($(1)-$(3)))
.SILENT: $(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/$(notdir $(3))
$(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/$(notdir $(3)): $($(1)-$(3))
	install -D -m 755 $$< $$@

$(TGZDIR)$(1)_$(2).tgz: $(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/$(notdir $(3))
endif
endef

define do_pkg_control =
.SILENT: $(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/control
$(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/control:
	install -d $$(@D)
	echo "Package: $(1)" >$$@
	echo "Version: $(2)" >>$$@
	if [ -n "$$($(1)-$(2)-deps)" ]; then \
		echo "Depends: $$($(1)-$(2)-deps)" >>$$@; \
	elif [ -n "$$($(1)-deps)" ]; then \
		echo "Depends: $$($(1)-deps)" >>$$@; \
	fi
	echo
	cat $$@

.SILENT: $(TGZDIR)$(1)_$(2).tgz
$(TGZDIR)$(1)_$(2).tgz: $(TGZDIR)$(1)_$(2)$(LOCALSTATEDIR)/info/$(1)/control

$(foreach script,preinst postinst prerm postrm,$(eval $(call do_pkg_script,$(1),$(2),$(script))))
$(foreach dir,$(if $($(1)-$(2)-dir),$($(1)-$(2)-dir),$($(1)-dir)),$(eval $(call do_install_dir,$(1),$(2),$(dir))))
$(foreach bin,$(if $($(1)-$(2)-sbin),$($(1)-$(2)-sbin),$($(1)-sbin)),$(eval $(call do_install_file,$(1),$(2),$(sbindir),$(bin))))
$(foreach bin,$(if $($(1)-$(2)-bin),$($(1)-$(2)-bin),$($(1)-bin)),$(eval $(call do_install_file,$(1),$(2),$(bindir),$(bin))))

tgzdir-m  += $(TGZDIR)$(1)_$(2)
endef

define do_pkg =
$(foreach vers,$(if $($(1)-vers),$($(1)-vers),1),$(eval $(call do_pkg_control,$(1),$(vers))))
endef

$(foreach pkg,$(pkg-m),$(eval $(call do_pkg,$(pkg))))

tgz-m 	:= $(patsubst %,%.tgz,$(tgzdir-m))

.SILENT: $(TGZDIR)
$(TGZDIR):
	install -d $@

$(TGZDIR)%.tgz: | $(TGZDIR)
	( cd $(@D)/ && fakeroot -- mpkg-build $* )

.SILENT: $(TGZDIR)Index
$(TGZDIR)Index: $(tgz-m) | $(TGZDIR)
	( cd $(@D)/ && mpkg-make-index ) >$@

all: $(TGZDIR)Index

.PHONY: tgz_clean
tgz_clean:
	rm -Rf $(TGZDIR) $(TGZDIR)Index $(tgz-m) $(tgzdir-m)

clean: tgz_clean

