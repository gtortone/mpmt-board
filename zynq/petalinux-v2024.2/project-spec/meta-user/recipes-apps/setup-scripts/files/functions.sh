
flash() {
   local filename=$1
   local part=$2
   echo "I: flashing $filename to $part"
   flashcp -v -A $filename $part
   return $?
}

download() {
   local protocol=$1
   local host=$2
   local port=$3
   local dir=$4
   local src_filename=$5
   local dst_filename=$6
   local res=255

   echo -n "I: try to get $filename from $protocol://$host:$dir"
   if [ "$protocol" = "tftp" ]; then
      local cmd=(atftp --option "blksize 1428" --option "windowsize 4" -g -r $dir/$src_filename -l $dst_filename $host)
      res=`"${cmd[@]}" 2>/dev/null; echo $?`
   elif [ "$protocol" = "http" ]; then
      local cmd="wget -O $dst_filename http://$host:$port/$dir/$src_filename"
      res=`$cmd 2>/dev/null; echo $?`
   fi
   return $res
}

#
# global exports
# protocol, host, home, port, mpmttype, macaddr
#
set_cmdline_environment() {
   protocol=$1

   if [ "$protocol" = "tftp" ]; then
      eval $(cat /proc/cmdline | grep -o '\btftphost=[^ ]*')
      eval $(cat /proc/cmdline | grep -o '\btftphome=[^ ]*')
      if [[ -z "$tftphost" ]] || [[ -z "$tftphome" ]]; then
         echo "E: set tftphost and tftphome in /proc/cmdline"
         exit
      fi
      host=$tftphost
      home=$tftphome
      port=69
   elif [ "$protocol" = "http" ]; then
      eval $(cat /proc/cmdline | grep -o '\bhttphost=[^ ]*')
      eval $(cat /proc/cmdline | grep -o '\bhttphome=[^ ]*')
      eval $(cat /proc/cmdline | grep -o '\bhttpport=[^ ]*')
      if [[ -z "$httphost" ]] || [[ -z "$httphome" ]] || [[ -z "$httpport" ]]; then
         echo "E: set httphost, httphome and httpport in /proc/cmdline"
         exit
      fi
      host=$httphost
      home=$httphome
      port=$httpport
   else
      echo "E: set protocol type [http | tftp] as first argument"
      exit
   fi
   
   eval $(cat /proc/cmdline | grep -o '\bmpmttype=[^ ]*')
   if [[ -z "$mpmttype" ]]; then
      mpmttype=`fw_printenv -n mpmttype`
   fi
   macaddr=`cat /sys/class/net/eth0/address | sed s/:/-/g`
}

#
# global exports
# host, home, port, mpmttype, macaddr
#
set_cfgfile_environment() {
   local protocol=$1
   local cfgfile=$2

   mpmttype=`fw_printenv -n mpmttype`
   macaddr=`cat /sys/class/net/eth0/address | sed s/:/-/g`

   if [ ! -f $cfgfile ]; then
      echo "E: $cfgfile file not found"
      exit 1
   fi

   while IFS= read -r line; do
      [[ $line =~ ^#.* ]] && continue
      eval $line
   done < $cfgfile

   if [ "$protocol" = "tftp" ]; then
      if [[ -z "$tftphost" ]] || [[ -z "$tftphome" ]]; then
         echo "E: set tftphost and tftphome in config file"
         exit 1
      fi
      host=$tftphost
      home=$tftphome
      port=69
   elif [ "$protocol" = "http" ]; then
      if [[ -z "$httphost" ]] || [[ -z "$httphome" ]] || [[ -z "$httpport" ]]; then
         echo "E: set httphost, httphome and httpport in config file"
         exit 1
      fi
      host=$httphost
      home=$httphome
      port=$httpport
   fi
}

prepare_file() {
   local src_filename=$1
   local dst_filename=$2
   
   local dirlist[0]=$home/$macaddr
   if [[ -n "$mpmttype" ]]; then
      local dirlist[1]=$home/default/$mpmttype
   fi
   local dirlist[2]=$home/default
   local dirlist[3]=$home

   for dir in "${dirlist[@]}"; do
      download $protocol $host $port $dir $src_filename $dst_filename
      if [ "$?" -eq "0" ]; then
         echo " [ OK ] "
         return 0
      else
         echo " [ NOT FOUND ] "
      fi
   done
   
   return 1  
}
