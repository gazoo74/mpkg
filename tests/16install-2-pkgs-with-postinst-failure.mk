root-y		:= a b
pkg-m		:= a b c d
a-deps		:= c
a-postinst	:= true
b-deps		:= d
b-postinst	:= false

include list-installed.mk files.mk

allfiles-y += $(user-y)
allfiles-y += $(a-1-m)
allfiles-y += $(b-1-m)
allfiles-y += $(c-1-m)
allfiles-y += $(d-1-m)
allfiles-y += /var/lib/mpkg/info/b/.configure

$(outdir)list-installed:
	@echo "Package: a" >$@
	@echo "Version: 1" >>$@
	@echo "Depends: c" >>$@
	@echo "User-Installed: yes" >>$@
	@echo "" >>$@
	@echo "Package: b" >>$@
	@echo "Version: 1" >>$@
	@echo "Depends: d" >>$@
	@echo "User-Installed: yes" >>$@
	@echo "Configure-Required: yes" >>$@
	@echo "" >>$@
	@echo "Package: c" >>$@
	@echo "Version: 1" >>$@
	@echo "" >>$@
	@echo "Package: d" >>$@
	@echo "Version: 1" >>$@
	@echo "" >>$@

