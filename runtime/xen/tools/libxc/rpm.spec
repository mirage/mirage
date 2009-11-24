Summary: Xen control interface library
Name: xen-internal-library
Version: 1.2
Release: 1
License: Xen
Group: Xen
BuildRoot: %{staging}
%description
Library to make it easier to access the Xen control interfaces.

%pre
%preun
%install
install -m 0755 -d $RPM_BUILD_ROOT/lib
install -m 0755 libxc.a $RPM_BUILD_ROOT/lib/libxc.a
install -m 0755 libxc.so $RPM_BUILD_ROOT/lib/libxc.so
install -m 0755 -d $RPM_BUILD_ROOT/include
install -m 0644 xc.h $RPM_BUILD_ROOT/include/xc.h
%clean
%post
%postun
%files
%defattr(-,root,root)
%dir /lib
/lib/libxc.a
/lib/libxc.so
%dir /include
/include/xc.h
