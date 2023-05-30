#!/bin/bash -e


FVER=1.73.30
FVER_=`echo "$FVER" | tr -d .`

ZLIBC=fasm-"$FVER".tar.gz
ZLINUX=fasm-"$FVER".tgz
ZDOS=fasm"$FVER_".zip
ZWIN32=fasmw"$FVER_".zip

FD=fasm-"$FVER"


# install wget, unzip, rsync


	echo .. 'get distro files'

for z in "$ZLIBC" "$ZLINUX" "$ZDOS" "$ZWIN32" ;do
	test -r "$z" && continue
	wget -q "http://flatassembler.net/$z"
#..	curl -s "http://flatassembler.net/$z" -L -o "$z"
done

	ls -lFa "$ZLIBC" "$ZLINUX" "$ZDOS" "$ZWIN32"


	echo .. 'check distro files'

HS='
9e425cb759389b1d8f9eb073b86dd3104a6c5776  fasm-1.73.30.tar.gz
cb4ab27792cfbb9312b8ba09dcacde7a1dc61cf0  fasm-1.73.30.tgz
0662962bb640132bdbf5acb553cdf1982c3b7479  fasm17330.zip
7ea8b55c736565c02cafdfc62be520b155fe8ae9  fasmw17330.zip
'

HS_="
`
for z in "$ZLIBC" "$ZLINUX" "$ZDOS" "$ZWIN32" ;do
	sha1sum "$z"
done
`
"

#..	echo "[$HS]"
#..	echo "[$HS_]"

#..diff -q <(echo "$HS") <(echo "$HS_") || exit 12
test "$HS" == "$HS_" || exit 12


#..	echo .. 'mkdir '"$FD"'/.{dos,win32,libc,linux} -p'
	echo .. 'create subdirectories for archives'

test -r "$FD" && exit 13
mkdir -p "$FD"/.{dos,win32,libc,linux}


	echo .. 'unpack archives'

tar xzC "$FD"/.libc -f "$ZLIBC"
tar xzC "$FD"/.linux -f "$ZLINUX"

unzip -q -d "$FD"/.dos "$ZDOS"
unzip -q -d "$FD"/.win32 "$ZWIN32"

du -kscx "$FD"/.[^.]*


	echo .. 'remove CR-s from *.{asm,ash,inc,txt}'

find "$FD" -type f | egrep -ie '\.(asm|ash|inc|txt)$' | while read f ;do
	c=`env <"$f" sha1sum`
	c_=`env <"$f" tr -d '\r' | sha1sum`
	[[ "$c" == "$c_" ]] && continue

	env <"$f" tr -d '\r' >"$f-" && touch -r "$f" "$f-" && mv "$f-" "$f"
done


	echo .. 'lowercase dir/file names'

find "$FD" | sort -r | while read f ;do
	d="${f%/*}"
	b="${f##*/}"
	b_=`echo "$b" | tr '[A-Z]' '[a-z]'`
	[[ "$b" == "$b_" ]] && continue

	mv "$d"/{"$b","$b_"}
done

	echo .. 'remove redundant "fasm/" directory'

for d in "$FD"/.[^.]* ;do

	test -d "$d"/fasm || continue

#..	echo "$d"
	mv "$d"/fasm{,-}
	mv "$d"/{fasm-/*,}
	rmdir "$d"/fasm-
done


	echo .. 'factor names and check for collisions'

ncs='
      2 fasm-1.73.30//fasm.exe
      2 fasm-1.73.30//fasm.txt
'

ncs_="
$(
find "$FD" -type f | while read f ;do
	b="${f##*/}"
	c=`env <"$f" sha1sum`
	f_=`echo "$f" | sed -re 's#^([^/]+/)([^/]+)(/.*)$#\1\3#g'`

	echo "$c $f_"
done | sort -k2 | uniq -c | awk '{print $4}' | sort | uniq -c | sort -k1n \
	| egrep -ve '^ +1 '
)
"

#..	echo "[$ncs]"
#..	echo "[$ncs_]"

	test "$ncs" == "$ncs_" || exit 23


	echo .. 'aggregate content'

mkdir -p "$FD"/bin/{dos,win32,libc,linux}

cp -p "$FD"/.dos/*.exe "$FD"/bin/dos/
cp -p "$FD"/.win32/*.exe "$FD"/bin/win32/
cp -p "$FD"/.libc/*.o "$FD"/bin/libc/
cp -p "$FD"/.linux/fasm{,.x64} "$FD"/bin/linux/

	find "$FD"/bin -type f | xargs ls -lFa

cp -p "$FD"/.win32/*.pdf "$FD"/
cp -p "$FD"/.libc/*.txt "$FD"/
cp -p "$FD"/.dos/fasm.txt "$FD"/fasm_dos.txt
cp -p "$FD"/.dos/fasmd.txt "$FD"/

mv "$FD"/readme.txt "$FD"/bin/libc/
mv "$FD"/license.txt "$FD"/LICENSE

#..	touch "$FD"/README.md

#..	ls -lFa "$FD"

for d in {dos,win32,libc,linux} ;do

test "$d" == "win32" && \
	rsync -aH -c "$FD"/."$d"/include "$FD"/

	rsync -aH -c "$FD"/."$d"/source "$FD"/
	rsync -aH -c "$FD"/."$d"/tools "$FD"/

	mkdir -p "$FD"/examples/"$d"
	rsync -aH -c "$FD"/."$d"/examples/* "$FD"/examples/"$d"/
done


	echo .. 'verify that aggregated content matches archives'

cfs=`find fasm-1.73.30 -path 'fasm-1.73.30/.*' -type f | xargs sha1sum | sort -k1`
cfs_=`find fasm-1.73.30 -path 'fasm-1.73.30/[^.]*' -type f | xargs sha1sum | sort -k1`

#..	echo "cfs  [$cfs]"
#..	echo "cfs_ [$cfs_]"

cs=`echo "$cfs" | awk '{print $1}' | uniq`
cs_=`echo "$cfs_" | awk '{print $1}' | uniq`

ds=`diff <(echo "$cs") <(echo "$cs_") | grep -e '^[<>]' ||:`

#..	echo "ds [$ds]"

if test -n "$ds" ;then

echo "$ds" | while read op c ;do
#..	echo "[$op] [$c]"
	echo -e "$cfs\n$cfs_" | grep -e "$c" ||:
done
	exit 28

fi


#..	echo .. 'remove '"$FD"'/.{dos,win32,libc,linux}'
	echo .. 'remove archive subdirectories'

rm -rf "$FD"/.{dos,win32,libc,linux}

du -kscx "$FD"

	echo .. 'adjust ownership for all content'

chown -R 0:0 "$FD"

	echo .. 'done'
