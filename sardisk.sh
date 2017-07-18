
myHost='my.server'

# set time to hh24:mi:ss in sar
export LC_TIME=POSIX

tmplog="sardisk${myHost}-tmp.log"
>$tmplog

# svctime rounded to ms

for sarfile in sar/20160?/sa??
do
  basefile=$(basename $sarfile)
	sar -d -f $sarfile \
		| tail -n +4 \
		| grep -v 'Average:' \
		| perl -e 'while(<>){my @s=split(/\s+/,$_); print int($s[8] + 0.5).qq{\n}}' \
		| sort -n \
		>> $tmplog
done

logFile="sardisk${myHost}.csv"

sort -n $tmplog \
	| uniq -c \
	| sort -n \
	| perl -e 'while(<>){my $line=$_;chomp $line;$line=~s/^\s+//go;print join(",",split(/\s+/,$line)),qq{\n};}' \
> $logFile

